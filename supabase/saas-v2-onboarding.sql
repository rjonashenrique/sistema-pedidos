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

  insert into public.store_appearance(store_id)
  values(v_store_row.id)
  on conflict(store_id) do nothing;

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


-- ============================================================
-- SAAS 2.2 — CORREÇÃO DO CONTEXTO DO PROPRIETÁRIO
-- Esta versão adiciona uma leitura segura por RPC para o painel.
-- Ela não depende de uma VIEW sujeita a mudanças de RLS.
-- ============================================================

create or replace function public.get_my_business_context()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_result jsonb;
begin
  if v_user is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select jsonb_agg(
    jsonb_build_object(
      'user_id', m.user_id,
      'organization_id', o.id,
      'organization_name', o.name,
      'organization_slug', o.slug,
      'organization_status', o.status,
      'plan_id', o.plan_id,
      'plan_code', p.code,
      'plan_name', p.name,
      'store_id', s.id,
      'store_name', s.name,
      'store_slug', s.slug,
      'store_status', s.status,
      'whatsapp', s.whatsapp,
      'phone', s.phone,
      'logo_url', s.logo_url,
      'cover_url', s.cover_url
    )
    order by o.created_at asc, s.created_at asc
  )
  into v_result
  from public.organization_members m
  join public.organizations o on o.id = m.organization_id
  left join public.plans p on p.id = o.plan_id
  left join lateral (
    select *
    from public.stores sx
    where sx.organization_id = o.id
    order by sx.created_at asc
    limit 1
  ) s on true
  where m.user_id = v_user
    and m.status = 'ACTIVE'
    and o.status in ('TRIAL','ATIVA','SUSPENSA');

  return coalesce(v_result, '[]'::jsonb);
end;
$$;

revoke all on function public.get_my_business_context() from public, anon;
grant execute on function public.get_my_business_context() to authenticated;

-- Permite que o OWNER leia seu próprio registro mesmo quando o restante
-- da operação ainda estiver sendo migrado para o RBAC final.
drop policy if exists members_access on public.organization_members;
create policy members_access on public.organization_members
for all
using (
  public.is_super_admin()
  or user_id = auth.uid()
  or public.is_org_member(organization_id)
)
with check (
  public.is_super_admin()
  or public.is_org_member(organization_id)
);

-- Função para verificar o onboarding sem expor tabelas diretamente.
create or replace function public.get_my_onboarding_status()
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_has_company boolean;
  v_count integer;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;

  select count(*) into v_count
  from public.organization_members
  where user_id = v_user
    and status = 'ACTIVE';

  v_has_company := v_count > 0;

  return jsonb_build_object(
    'has_company', v_has_company,
    'company_count', v_count
  );
end;
$$;

revoke all on function public.get_my_onboarding_status() from public, anon;
grant execute on function public.get_my_onboarding_status() to authenticated;



-- ============================================================
-- APARÊNCIA 2.0 — identidade visual por loja
-- ============================================================

create table if not exists public.store_appearance (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null unique references public.stores(id) on delete cascade,
  logo_url text,
  favicon_url text,
  cover_url text,
  primary_color text not null default '#E8590C',
  secondary_color text not null default '#1C1917',
  light_background text not null default '#FFFFFF',
  light_surface text not null default '#F8FAFC',
  light_card text not null default '#FFFFFF',
  light_text text not null default '#111827',
  light_text_muted text not null default '#64748B',
  light_border text not null default '#E5E7EB',
  dark_background text not null default '#0B0B0C',
  dark_surface text not null default '#171719',
  dark_card text not null default '#1F1F22',
  dark_text text not null default '#FFFFFF',
  dark_text_muted text not null default '#A1A1AA',
  dark_border text not null default '#303035',
  theme text not null default 'system' check(theme in ('light','dark','system')),
  button_style text not null default 'rounded' check(button_style in ('square','rounded','pill')),
  button_variant text not null default 'solid' check(button_variant in ('solid','outline','gradient')),
  border_radius integer not null default 14 check(border_radius between 0 and 32),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.store_appearance enable row level security;

drop policy if exists store_appearance_access on public.store_appearance;
create policy store_appearance_access on public.store_appearance
for all
using (public.is_store_member(store_id))
with check (public.is_store_member(store_id));

grant select, insert, update, delete on public.store_appearance to authenticated;

-- Toda loja criada pelo onboarding recebe aparência padrão.
insert into public.store_appearance(store_id)
select s.id
from public.stores s
where not exists (
  select 1 from public.store_appearance a where a.store_id=s.id
);

-- Endpoint público somente leitura: o visitante conhece a aparência da loja,
-- mas não recebe qualquer permissão de escrita.
create or replace function public.get_public_store_appearance(p_slug text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'store_id', s.id,
    'store_slug', s.slug,
    'store_name', s.name,
    'logo_url', a.logo_url,
    'favicon_url', a.favicon_url,
    'cover_url', a.cover_url,
    'primary_color', a.primary_color,
    'secondary_color', a.secondary_color,
    'light_background', a.light_background,
    'light_surface', a.light_surface,
    'light_card', a.light_card,
    'light_text', a.light_text,
    'light_text_muted', a.light_text_muted,
    'light_border', a.light_border,
    'dark_background', a.dark_background,
    'dark_surface', a.dark_surface,
    'dark_card', a.dark_card,
    'dark_text', a.dark_text,
    'dark_text_muted', a.dark_text_muted,
    'dark_border', a.dark_border,
    'theme', a.theme,
    'button_style', a.button_style,
    'button_variant', a.button_variant,
    'border_radius', a.border_radius
  )
  from public.stores s
  left join public.store_appearance a on a.store_id=s.id
  where s.slug=lower(trim(p_slug))
    and s.status in ('ATIVA','TRIAL')
  limit 1;
$$;

revoke all on function public.get_public_store_appearance(text) from public, authenticated;
grant execute on function public.get_public_store_appearance(text) to anon, authenticated;

-- Bucket público para logo/banner/capa.
insert into storage.buckets (id, name, public)
values ('store-assets', 'store-assets', true)
on conflict (id) do update set public=true;

drop policy if exists store_assets_insert on storage.objects;
create policy store_assets_insert on storage.objects
for insert to authenticated
with check (
  bucket_id='store-assets'
  and name ~ '^[0-9a-fA-F-]{36}/'
  and public.is_store_member((split_part(name,'/',1))::uuid)
);

drop policy if exists store_assets_update on storage.objects;
create policy store_assets_update on storage.objects
for update to authenticated
using (
  bucket_id='store-assets'
  and name ~ '^[0-9a-fA-F-]{36}/'
  and public.is_store_member((split_part(name,'/',1))::uuid)
)
with check (
  bucket_id='store-assets'
  and name ~ '^[0-9a-fA-F-]{36}/'
  and public.is_store_member((split_part(name,'/',1))::uuid)
);

drop policy if exists store_assets_delete on storage.objects;
create policy store_assets_delete on storage.objects
for delete to authenticated
using (
  bucket_id='store-assets'
  and name ~ '^[0-9a-fA-F-]{36}/'
  and public.is_store_member((split_part(name,'/',1))::uuid)
);



-- Reparo seguro para registros incompletos criados por versões anteriores.
-- Nunca cria uma segunda organização para o mesmo OWNER.
create or replace function public.repair_my_company(p_store_name text default null)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare
  v_user uuid := auth.uid();
  v_org organizations%rowtype;
  v_store stores%rowtype;
  v_name text;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;

  select o.* into v_org
  from public.organization_members m
  join public.organizations o on o.id=m.organization_id
  where m.user_id=v_user
    and m.role='OWNER'
    and m.status='ACTIVE'
  order by o.created_at asc
  limit 1;

  if not found then
    raise exception 'NO_COMPANY_TO_REPAIR';
  end if;

  select * into v_store
  from public.stores
  where organization_id=v_org.id
  order by created_at asc
  limit 1;

  if not found then
    v_name := nullif(trim(coalesce(p_store_name, v_org.name)), '');
    insert into public.stores(organization_id,name,slug,address,status)
    values(v_org.id,v_name,v_org.slug,'{}'::jsonb,case when v_org.status='TRIAL' then 'TRIAL' else 'ATIVA' end)
    returning * into v_store;

    insert into public.store_settings(store_id,settings)
    values(v_store.id,jsonb_build_object('currency','BRL','timezone','America/Sao_Paulo','order_channel','WHATSAPP','onboarding_completed',true))
    on conflict(store_id) do nothing;

    insert into public.store_appearance(store_id)
    values(v_store.id)
    on conflict(store_id) do nothing;

    insert into public.audit_logs(organization_id,store_id,user_id,action,resource,resource_id,metadata)
    values(v_org.id,v_store.id,v_user,'organization.repaired','organization',v_org.id::text,jsonb_build_object('source','saas_2_2_repair'));
  end if;

  return public.get_my_business_context()->0;
end;
$$;

revoke all on function public.repair_my_company(text) from public, anon;
grant execute on function public.repair_my_company(text) to authenticated;

