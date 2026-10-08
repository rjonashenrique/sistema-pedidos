-- ============================================================
-- SAAS 2.1 — ONBOARDING SELF-SERVICE DO CLIENTE
-- O próprio dono cria a empresa/loja após criar a conta.
-- A função é SECURITY DEFINER para realizar o bootstrap com
-- consistência, sem expor service_role no navegador.
-- ============================================================

create or replace function public.slugify_company(p_value text)
returns text
language plpgsql
immutable
as $$
declare
  v text;
begin
  v := lower(trim(coalesce(p_value,'')));
  v := translate(v, 'áàãâäéèêëíìîïóòõôöúùûüçñ', 'aaaaaeeeeiiiiooooouuuucn');
  v := regexp_replace(v, '[^a-z0-9]+', '-', 'g');
  v := regexp_replace(v, '(^-+|-+$)', '', 'g');
  if v = '' then v := 'empresa'; end if;
  return left(v, 60);
end;
$$;

revoke all on function public.slugify_company(text) from public;
grant execute on function public.slugify_company(text) to authenticated;

create or replace function public.create_owner_company(
  p_company_name text,
  p_store_name text default null,
  p_phone text default null,
  p_whatsapp text default null,
  p_email text default null,
  p_plan_code text default 'PRO',
  p_address jsonb default '{}'::jsonb,
  p_hours jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_email text;
  v_company text;
  v_store text;
  v_slug text;
  v_base_slug text;
  v_suffix integer := 0;
  v_plan plans%rowtype;
  v_org organizations%rowtype;
  v_store_row stores%rowtype;
  v_subscription subscriptions%rowtype;
  v_day jsonb;
begin
  if v_user is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  v_company := nullif(trim(p_company_name), '');
  v_store := nullif(trim(coalesce(p_store_name, p_company_name)), '');
  v_email := lower(nullif(trim(coalesce(p_email, '')), ''));

  if v_company is null then raise exception 'COMPANY_NAME_REQUIRED'; end if;
  if length(v_company) < 2 then raise exception 'COMPANY_NAME_TOO_SHORT'; end if;

  select * into v_plan from public.plans where code = upper(coalesce(p_plan_code,'PRO')) and active = true limit 1;
  if not found then
    select * into v_plan from public.plans where code = 'PRO' and active = true limit 1;
  end if;
  if not found then raise exception 'PLAN_NOT_FOUND'; end if;

  -- Se o usuário já possui uma empresa ativa, não duplica acidentalmente o tenant.
  if exists (
    select 1 from public.organization_members m
    join public.organizations o on o.id = m.organization_id
    where m.user_id = v_user and m.role = 'OWNER' and m.status = 'ACTIVE'
      and o.status in ('TRIAL','ATIVA')
  ) then
    raise exception 'OWNER_ALREADY_HAS_COMPANY';
  end if;

  v_base_slug := public.slugify_company(v_company);
  v_slug := v_base_slug;
  while exists (select 1 from public.organizations where slug = v_slug) loop
    v_suffix := v_suffix + 1;
    v_slug := left(v_base_slug, 52) || '-' || v_suffix::text;
  end loop;

  insert into public.organizations(name, slug, status, plan_id)
  values(v_company, v_slug, 'TRIAL', v_plan.id)
  returning * into v_org;

  insert into public.profiles(id, full_name, email, phone)
  values(v_user, nullif(trim(coalesce((select raw_user_meta_data->>'full_name' from auth.users where id=v_user), '')), ''), v_email, nullif(trim(coalesce(p_phone,'')), ''))
  on conflict(id) do update set
    email = coalesce(excluded.email, public.profiles.email),
    phone = coalesce(excluded.phone, public.profiles.phone),
    updated_at = now();

  insert into public.organization_members(organization_id,user_id,role,status)
  values(v_org.id,v_user,'OWNER','ACTIVE');

  insert into public.stores(organization_id,name,slug,phone,whatsapp,address,status)
  values(v_org.id,v_store,v_org.slug,nullif(trim(coalesce(p_phone,'')),''),nullif(trim(coalesce(p_whatsapp,'')),''),coalesce(p_address,'{}'::jsonb),'TRIAL')
  returning * into v_store_row;

  insert into public.store_settings(store_id,settings)
  values(v_store_row.id, jsonb_build_object('currency','BRL','timezone','America/Sao_Paulo','order_channel','WHATSAPP','onboarding_completed',true));

  -- Horários padrão: todos os dias 18:00–23:00. O dono pode ajustar depois.
  insert into public.business_hours(store_id,weekday,open_time,close_time,closed)
  values
    (v_store_row.id,0,'18:00','23:00',false),
    (v_store_row.id,1,'18:00','23:00',false),
    (v_store_row.id,2,'18:00','23:00',false),
    (v_store_row.id,3,'18:00','23:00',false),
    (v_store_row.id,4,'18:00','23:00',false),
    (v_store_row.id,5,'18:00','23:00',false),
    (v_store_row.id,6,'18:00','23:00',false)
  on conflict(store_id,weekday) do nothing;

  if jsonb_typeof(coalesce(p_hours,'[]'::jsonb)) = 'array' then
    for v_day in select * from jsonb_array_elements(p_hours) loop
      if (v_day->>'weekday') is not null then
        update public.business_hours
          set open_time = nullif(v_day->>'open_time','')::time,
              close_time = nullif(v_day->>'close_time','')::time,
              closed = coalesce((v_day->>'closed')::boolean,false)
        where store_id = v_store_row.id and weekday = (v_day->>'weekday')::smallint;
      end if;
    end loop;
  end if;

  insert into public.subscriptions(organization_id,plan_id,status,trial_ends_at)
  values(v_org.id,v_plan.id,'TRIALING',now() + interval '7 days')
  returning * into v_subscription;

  insert into public.audit_logs(organization_id,store_id,user_id,action,resource,resource_id,metadata)
  values(v_org.id,v_store_row.id,v_user,'organization.created','organization',v_org.id::text,jsonb_build_object('plan',v_plan.code,'source','self_service'));

  return jsonb_build_object(
    'organization_id', v_org.id,
    'organization_name', v_org.name,
    'organization_slug', v_org.slug,
    'store_id', v_store_row.id,
    'store_name', v_store_row.name,
    'store_slug', v_store_row.slug,
    'plan_code', v_plan.code,
    'trial_ends_at', v_subscription.trial_ends_at
  );
exception
  when unique_violation then
    raise exception 'COMPANY_CREATION_CONFLICT';
end;
$$;

revoke all on function public.create_owner_company(text,text,text,text,text,text,jsonb,jsonb) from public, anon;
grant execute on function public.create_owner_company(text,text,text,text,text,text,jsonb,jsonb) to authenticated;

-- Leitura do próprio contexto para o painel do dono.
create or replace view public.my_business_context as
select
  m.user_id,
  o.id as organization_id,
  o.name as organization_name,
  o.slug as organization_slug,
  o.status as organization_status,
  o.plan_id,
  p.code as plan_code,
  p.name as plan_name,
  s.id as store_id,
  s.name as store_name,
  s.slug as store_slug,
  s.status as store_status,
  s.whatsapp,
  s.phone
from public.organization_members m
join public.organizations o on o.id=m.organization_id
left join public.plans p on p.id=o.plan_id
left join public.stores s on s.organization_id=o.id
where m.user_id=auth.uid() and m.status='ACTIVE';

grant select on public.my_business_context to authenticated;
