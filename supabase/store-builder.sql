-- Jonash.dev Store Builder — execute uma única vez no SQL Editor do projeto Supabase da plataforma.
-- Use apenas a publishable/anon key no navegador. Nunca exponha service_role.
create extension if not exists pgcrypto;

create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 90),
  slug text not null unique check (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$' and char_length(slug) <= 48),
  whatsapp text not null check (whatsapp ~ '^[0-9]{12,13}$'),
  address text,
  description text,
  logo_url text,
  banner_url text,
  status text not null default 'pending' check (status in ('pending','published','rejected','suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.store_products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 100),
  description text,
  category text not null default 'Cardápio',
  price numeric(10,2) not null check (price > 0 and price <= 99999),
  image_url text,
  is_available boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists stores_owner_created_idx on public.stores(owner_id, created_at desc);
create index if not exists store_products_store_created_idx on public.store_products(store_id, created_at desc);
create index if not exists store_products_available_idx on public.store_products(store_id, is_available);

alter table public.stores enable row level security;
alter table public.store_products enable row level security;

-- Remova políticas anteriores com os mesmos nomes para permitir reexecução da migração.
drop policy if exists stores_public_published_select on public.stores;
drop policy if exists stores_owner_select on public.stores;
drop policy if exists stores_owner_insert_pending on public.stores;
drop policy if exists stores_owner_update on public.stores;
drop policy if exists products_public_published_select on public.store_products;
drop policy if exists products_owner_select on public.store_products;
drop policy if exists products_owner_insert on public.store_products;
drop policy if exists products_owner_update on public.store_products;
drop policy if exists products_owner_delete on public.store_products;

create policy stores_public_published_select on public.stores
  for select to anon, authenticated using (status = 'published');
create policy stores_owner_select on public.stores
  for select to authenticated using (owner_id = (select auth.uid()));
create policy stores_owner_insert_pending on public.stores
  for insert to authenticated with check (owner_id = (select auth.uid()) and status = 'pending');
create policy stores_owner_update on public.stores
  for update to authenticated using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy products_public_published_select on public.store_products
  for select to anon, authenticated using (
    is_available = true and exists (
      select 1 from public.stores s where s.id = store_products.store_id and s.status = 'published'
    )
  );
create policy products_owner_select on public.store_products
  for select to authenticated using (exists (
    select 1 from public.stores s where s.id = store_products.store_id and s.owner_id = (select auth.uid())
  ));
create policy products_owner_insert on public.store_products
  for insert to authenticated with check (exists (
    select 1 from public.stores s where s.id = store_products.store_id and s.owner_id = (select auth.uid())
  ));
create policy products_owner_update on public.store_products
  for update to authenticated using (exists (
    select 1 from public.stores s where s.id = store_products.store_id and s.owner_id = (select auth.uid())
  )) with check (exists (
    select 1 from public.stores s where s.id = store_products.store_id and s.owner_id = (select auth.uid())
  ));
create policy products_owner_delete on public.store_products
  for delete to authenticated using (exists (
    select 1 from public.stores s where s.id = store_products.store_id and s.owner_id = (select auth.uid())
  ));

-- Grants mínimos. A coluna status não é atualizável pelo proprietário via Data API.
grant select on public.stores to anon, authenticated;
grant insert (owner_id,name,slug,whatsapp,address,description,logo_url,banner_url,status) on public.stores to authenticated;
grant update (name,slug,whatsapp,address,description,logo_url,banner_url) on public.stores to authenticated;
grant select on public.store_products to anon, authenticated;
grant insert (store_id,name,description,category,price,image_url,is_available) on public.store_products to authenticated;
grant update (name,description,category,price,image_url,is_available) on public.store_products to authenticated;
grant delete on public.store_products to authenticated;

-- Trigger updated_at
create or replace function public.store_builder_touch_updated_at()
returns trigger language plpgsql set search_path = public, pg_temp as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists stores_touch_updated_at on public.stores;
create trigger stores_touch_updated_at before update on public.stores for each row execute function public.store_builder_touch_updated_at();
drop trigger if exists store_products_touch_updated_at on public.store_products;
create trigger store_products_touch_updated_at before update on public.store_products for each row execute function public.store_builder_touch_updated_at();
revoke all on function public.store_builder_touch_updated_at() from public, anon, authenticated;

-- APROVAÇÃO MANUAL: revise os dados e execute como administrador no SQL Editor.
-- update public.stores set status='published' where slug='slug-da-loja';
-- Para rejeitar/suspender, use status='rejected' ou status='suspended'.
