-- V10 SaaS Multi-Loja — MIGRAÇÃO ADITIVA E NÃO DESTRUTIVA
-- Execute no SQL Editor do projeto Supabase central APÓS backup/exportação.
-- Não remove nem altera orders, order_items, profiles ou a configuração atual da Brasa Burger.
-- A chave service_role nunca deve ir para o navegador.

create extension if not exists pgcrypto;

create table if not exists public.saas_stores (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(trim(name)) between 2 and 80),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) between 3 and 48),
  status text not null default 'active' check (status in ('active','pending','suspended','archived')),
  owner_user_id uuid not null references auth.users(id) on delete restrict,
  whatsapp text not null default '',
  address text not null default '',
  description text not null default '',
  logo_url text not null default '',
  settings jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.saas_store_members (
  store_id uuid not null references public.saas_stores(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'owner' check (role in ('owner','manager','operator')),
  created_at timestamptz not null default now(),
  primary key (store_id,user_id)
);

create table if not exists public.saas_products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.saas_stores(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 120),
  description text not null default '',
  category text not null default 'Cardápio',
  price numeric(12,2) not null check (price >= 0),
  image_url text not null default '',
  available boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.saas_subscriptions (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null unique references public.saas_stores(id) on delete cascade,
  plan_code text not null default 'starter' check (plan_code in ('starter','pro','business')),
  status text not null default 'trial' check (status in ('trial','active','past_due','cancelled','expired')),
  trial_ends_at timestamptz not null default (now() + interval '7 days'),
  current_period_end timestamptz,
  provider text,
  provider_subscription_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.saas_platform_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index if not exists saas_stores_owner_idx on public.saas_stores(owner_user_id);
create index if not exists saas_members_user_idx on public.saas_store_members(user_id,store_id);
create index if not exists saas_products_store_idx on public.saas_products(store_id,available,sort_order);
create index if not exists saas_subscriptions_status_idx on public.saas_subscriptions(status);

create or replace function public.saas_is_member(p_store_id uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp
as $$ select exists (select 1 from public.saas_store_members m where m.store_id=p_store_id and m.user_id=(select auth.uid())) $$;

create or replace function public.saas_is_owner(p_store_id uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp
as $$ select exists (select 1 from public.saas_store_members m where m.store_id=p_store_id and m.user_id=(select auth.uid()) and m.role='owner') $$;

create or replace function public.saas_is_platform_admin()
returns boolean language sql stable security definer set search_path = public, pg_temp
as $$ select exists (select 1 from public.saas_platform_admins a where a.user_id=(select auth.uid())) $$;

revoke all on function public.saas_is_member(uuid) from public, anon;
revoke all on function public.saas_is_owner(uuid) from public, anon;
revoke all on function public.saas_is_platform_admin() from public, anon;
grant execute on function public.saas_is_member(uuid) to authenticated;
grant execute on function public.saas_is_owner(uuid) to authenticated;
grant execute on function public.saas_is_platform_admin() to authenticated;

-- Cadastro transacional: cria a loja, associa o usuário e abre o período de teste.
create or replace function public.saas_create_store(
  p_name text, p_slug text, p_whatsapp text default '', p_address text default '', p_description text default ''
) returns public.saas_stores
language plpgsql security definer set search_path = public, auth, pg_temp
as $$
declare v_store public.saas_stores; v_uid uuid := auth.uid(); v_slug text := lower(trim(coalesce(p_slug,'')));
begin
  if v_uid is null then raise exception 'Faça login para criar uma loja.' using errcode='28000'; end if;
  if trim(coalesce(p_name,'')) !~ '.{2,80}' then raise exception 'Informe um nome de loja entre 2 e 80 caracteres.'; end if;
  if v_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' or char_length(v_slug) not between 3 and 48 then raise exception 'O link deve ter 3 a 48 caracteres: letras minúsculas, números e hífen.'; end if;
  if v_slug in ('admin','dev','dono','plataforma','loja','api','assets','config','supabase') then raise exception 'Este endereço é reservado. Escolha outro.'; end if;
  insert into public.saas_stores(name,slug,owner_user_id,whatsapp,address,description,status)
  values (trim(p_name),v_slug,v_uid,regexp_replace(coalesce(p_whatsapp,''),'[^0-9]','','g'),trim(coalesce(p_address,'')),trim(coalesce(p_description,'')),'active')
  returning * into v_store;
  insert into public.saas_store_members(store_id,user_id,role) values(v_store.id,v_uid,'owner');
  insert into public.saas_subscriptions(store_id,plan_code,status,trial_ends_at) values(v_store.id,'starter','trial',now()+interval '7 days');
  return v_store;
end; $$;
revoke all on function public.saas_create_store(text,text,text,text,text) from public, anon;
grant execute on function public.saas_create_store(text,text,text,text,text) to authenticated;

alter table public.saas_stores enable row level security;
alter table public.saas_store_members enable row level security;
alter table public.saas_products enable row level security;
alter table public.saas_subscriptions enable row level security;
alter table public.saas_platform_admins enable row level security;

grant select on public.saas_stores to anon, authenticated;
grant insert, update on public.saas_stores to authenticated;
grant select, insert, update, delete on public.saas_store_members to authenticated;
grant select, insert, update, delete on public.saas_products to authenticated;
grant select on public.saas_subscriptions to authenticated;
grant select on public.saas_platform_admins to authenticated;

drop policy if exists saas_stores_public_active on public.saas_stores;
create policy saas_stores_public_active on public.saas_stores for select to anon, authenticated using (status='active');
drop policy if exists saas_stores_member_select on public.saas_stores;
create policy saas_stores_member_select on public.saas_stores for select to authenticated using (public.saas_is_member(id) or public.saas_is_platform_admin());
drop policy if exists saas_stores_owner_update on public.saas_stores;
create policy saas_stores_owner_update on public.saas_stores for update to authenticated using (public.saas_is_owner(id) or public.saas_is_platform_admin()) with check ((public.saas_is_owner(id) and owner_user_id=(select auth.uid())) or public.saas_is_platform_admin());
drop policy if exists saas_stores_admin_all on public.saas_stores;
create policy saas_stores_admin_all on public.saas_stores for all to authenticated using (public.saas_is_platform_admin()) with check (public.saas_is_platform_admin());

drop policy if exists saas_members_read_self_or_owner on public.saas_store_members;
create policy saas_members_read_self_or_owner on public.saas_store_members for select to authenticated using (user_id=(select auth.uid()) or public.saas_is_owner(store_id) or public.saas_is_platform_admin());
-- Memberships are created only by saas_create_store or a future trusted admin flow.
drop policy if exists saas_members_admin_manage on public.saas_store_members;
create policy saas_members_admin_manage on public.saas_store_members for all to authenticated using (public.saas_is_platform_admin()) with check (public.saas_is_platform_admin());

drop policy if exists saas_products_public_read on public.saas_products;
create policy saas_products_public_read on public.saas_products for select to anon, authenticated using (available=true and exists(select 1 from public.saas_stores s where s.id=store_id and s.status='active'));
drop policy if exists saas_products_member_read on public.saas_products;
create policy saas_products_member_read on public.saas_products for select to authenticated using (public.saas_is_member(store_id) or public.saas_is_platform_admin());
drop policy if exists saas_products_member_insert on public.saas_products;
create policy saas_products_member_insert on public.saas_products for insert to authenticated with check (public.saas_is_member(store_id) or public.saas_is_platform_admin());
drop policy if exists saas_products_member_update on public.saas_products;
create policy saas_products_member_update on public.saas_products for update to authenticated using (public.saas_is_member(store_id) or public.saas_is_platform_admin()) with check (public.saas_is_member(store_id) or public.saas_is_platform_admin());
drop policy if exists saas_products_member_delete on public.saas_products;
create policy saas_products_member_delete on public.saas_products for delete to authenticated using (public.saas_is_owner(store_id) or public.saas_is_platform_admin());

drop policy if exists saas_subscriptions_member_read on public.saas_subscriptions;
create policy saas_subscriptions_member_read on public.saas_subscriptions for select to authenticated using (public.saas_is_member(store_id) or public.saas_is_platform_admin());
drop policy if exists saas_subscriptions_admin_manage on public.saas_subscriptions;
create policy saas_subscriptions_admin_manage on public.saas_subscriptions for all to authenticated using (public.saas_is_platform_admin()) with check (public.saas_is_platform_admin());
drop policy if exists saas_platform_admins_self_read on public.saas_platform_admins;
create policy saas_platform_admins_self_read on public.saas_platform_admins for select to authenticated using (user_id=(select auth.uid()));

-- Atualização de timestamp apenas nas novas tabelas.
create or replace function public.saas_touch_updated_at() returns trigger language plpgsql set search_path=public,pg_temp as $$ begin new.updated_at=now(); return new; end; $$;
revoke all on function public.saas_touch_updated_at() from public, anon, authenticated;
drop trigger if exists saas_stores_touch on public.saas_stores;
create trigger saas_stores_touch before update on public.saas_stores for each row execute function public.saas_touch_updated_at();
drop trigger if exists saas_products_touch on public.saas_products;
create trigger saas_products_touch before update on public.saas_products for each row execute function public.saas_touch_updated_at();
drop trigger if exists saas_subscriptions_touch on public.saas_subscriptions;
create trigger saas_subscriptions_touch before update on public.saas_subscriptions for each row execute function public.saas_touch_updated_at();

-- Migração de compatibilidade: registra a Brasa Burger sem apagar/reescrever pedidos antigos.
-- O usuário proprietário é vinculado manualmente depois do backup, com o passo indicado em MIGRACAO-V10.md.
insert into public.saas_stores(name,slug,owner_user_id,whatsapp,address,description,status,settings)
select 'Brasa Burger','brasa-burger',u.id,'5511999999999','Rua das Palmeiras, 120 - Centro','Burgers artesanais, combos e porções.','active',
       '{"legacy":true,"legacy_store_slug":"brasa-burger","delivery_fee":6.9,"minimum_order":25,"currency":"BRL"}'::jsonb
from auth.users u where lower(u.email)='rojonas71@gmail.com'
  and not exists(select 1 from public.saas_stores s where s.slug='brasa-burger')
order by u.created_at asc limit 1;
-- Caso o e-mail ainda não exista no Auth, a loja Brasa não é inserida automaticamente para evitar owner_user_id fictício.

-- Vincula o usuário que já existe como dono da Brasa Burger e cria assinatura de teste,
-- sem modificar pedidos, produtos legados ou credenciais da loja.
insert into public.saas_store_members(store_id,user_id,role)
select s.id,s.owner_user_id,'owner' from public.saas_stores s
where s.slug='brasa-burger' and s.owner_user_id is not null
on conflict (store_id,user_id) do nothing;
insert into public.saas_subscriptions(store_id,plan_code,status,trial_ends_at)
select s.id,'starter','trial',now()+interval '7 days' from public.saas_stores s
where s.slug='brasa-burger'
on conflict (store_id) do nothing;
