-- V10.3: permite ao administrador autorizado criar uma loja e vinculá-la
-- a uma conta Auth existente, sem criar senhas nem expor service_role.
-- Pré-requisito: executar V10_saas_multiloja.sql e cadastrar o Dev em saas_platform_admins.
create or replace function public.saas_admin_create_store(
  p_name text,
  p_slug text,
  p_owner_email text,
  p_whatsapp text default '',
  p_address text default '',
  p_description text default ''
) returns public.saas_stores
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_owner uuid;
  v_store public.saas_stores;
  v_slug text := lower(trim(coalesce(p_slug,'')));
  v_email text := lower(trim(coalesce(p_owner_email,'')));
begin
  if v_actor is null then raise exception 'Faça login como administrador.' using errcode='28000'; end if;
  if not exists(select 1 from public.saas_platform_admins a where a.user_id=v_actor) then
    raise exception 'Apenas o administrador autorizado pode criar lojas.' using errcode='42501';
  end if;
  if trim(coalesce(p_name,'')) !~ '.{2,80}' then raise exception 'Nome da loja inválido (2 a 80 caracteres).'; end if;
  if v_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' or char_length(v_slug) not between 3 and 48 then
    raise exception 'Slug inválido. Use 3 a 48 caracteres: letras minúsculas, números e hífens.';
  end if;
  if v_slug in ('admin','dev','dono','plataforma','loja','api','assets','config','supabase') then raise exception 'Este slug é reservado.'; end if;
  if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' then raise exception 'Informe um e-mail válido para o proprietário.'; end if;
  select u.id into v_owner from auth.users u where lower(u.email)=v_email order by u.created_at asc limit 1;
  if v_owner is null then raise exception 'Não existe conta com esse e-mail. Peça ao proprietário que se cadastre e confirme o e-mail na Plataforma antes de vinculá-lo.'; end if;
  insert into public.saas_stores(name,slug,status,owner_user_id,whatsapp,address,description,settings)
  values(trim(p_name),v_slug,'active',v_owner,regexp_replace(coalesce(p_whatsapp,''),'[^0-9]','','g'),trim(coalesce(p_address,'')),trim(coalesce(p_description,'')),'{"created_by":"dev_admin","onboarding":"admin_created"}'::jsonb)
  returning * into v_store;
  insert into public.saas_store_members(store_id,user_id,role) values(v_store.id,v_owner,'owner');
  insert into public.saas_subscriptions(store_id,plan_code,status,trial_ends_at) values(v_store.id,'starter','trial',now()+interval '7 days');
  return v_store;
exception when unique_violation then
  raise exception 'Este slug já está cadastrado. Escolha outro link para a loja.';
end;
$$;
revoke all on function public.saas_admin_create_store(text,text,text,text,text,text) from public, anon;
grant execute on function public.saas_admin_create_store(text,text,text,text,text,text) to authenticated;
