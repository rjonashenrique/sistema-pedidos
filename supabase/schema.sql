-- Brasa Burger / Sistema de Pedidos
-- Execute no SQL Editor do projeto Supabase.
-- Não use service_role no navegador.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.customer_addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null default 'Principal',
  address_line text not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  store_slug text not null,
  order_number text not null,
  status text not null default 'whatsapp_pending',
  order_type text not null check (order_type in ('delivery','pickup')),
  customer_name text not null,
  customer_phone text,
  delivery_address text,
  payment_method text not null,
  subtotal numeric(12,2) not null default 0,
  delivery_fee numeric(12,2) not null default 0,
  discount numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0,
  coupon_code text,
  notes text,
  scheduled_for timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id text not null,
  product_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12,2) not null default 0,
  line_total numeric(12,2) not null default 0,
  selections jsonb not null default '{}'::jsonb,
  observation text,
  created_at timestamptz not null default now()
);

create index if not exists customer_addresses_user_idx on public.customer_addresses(user_id);
create index if not exists orders_user_created_idx on public.orders(user_id, created_at desc);
create index if not exists orders_store_created_idx on public.orders(store_slug, created_at desc);
create index if not exists order_items_order_idx on public.order_items(order_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (new.id, nullif(new.raw_user_meta_data ->> 'full_name',''), nullif(new.raw_user_meta_data ->> 'phone',''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

revoke all on function public.handle_new_user() from public, anon, authenticated;

alter table public.profiles enable row level security;
alter table public.customer_addresses enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles for select to authenticated using ((select auth.uid()) = id);
drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

drop policy if exists "addresses_select_own" on public.customer_addresses;
create policy "addresses_select_own" on public.customer_addresses for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "addresses_insert_own" on public.customer_addresses;
create policy "addresses_insert_own" on public.customer_addresses for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "addresses_update_own" on public.customer_addresses;
create policy "addresses_update_own" on public.customer_addresses for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
drop policy if exists "addresses_delete_own" on public.customer_addresses;
create policy "addresses_delete_own" on public.customer_addresses for delete to authenticated using ((select auth.uid()) = user_id);

drop policy if exists "orders_select_own" on public.orders;
create policy "orders_select_own" on public.orders for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "orders_insert_own" on public.orders;
create policy "orders_insert_own" on public.orders for insert to authenticated with check ((select auth.uid()) = user_id);
drop policy if exists "orders_update_own" on public.orders;
create policy "orders_update_own" on public.orders for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

drop policy if exists "order_items_select_own" on public.order_items;
create policy "order_items_select_own" on public.order_items for select to authenticated using (exists (select 1 from public.orders o where o.id = order_items.order_id and o.user_id = (select auth.uid())));
drop policy if exists "order_items_insert_own" on public.order_items;
create policy "order_items_insert_own" on public.order_items for insert to authenticated with check (exists (select 1 from public.orders o where o.id = order_items.order_id and o.user_id = (select auth.uid())));

-- O Data API pode exigir grants explícitos em projetos novos.
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.customer_addresses to authenticated;
grant select, insert, update on public.orders to authenticated;
grant select, insert on public.order_items to authenticated;

-- ==============================================================
-- Central administrativa multi-loja
-- Execute esta parte somente no projeto Supabase da loja.
-- A central nunca usa service_role no navegador.

create table if not exists public.store_admins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  store_slug text not null,
  role text not null default 'owner' check (role in ('owner','manager','operator')),
  created_at timestamptz not null default now(),
  unique (user_id, store_slug)
);

create index if not exists store_admins_user_store_idx on public.store_admins(user_id, store_slug);
create index if not exists store_admins_store_idx on public.store_admins(store_slug);

alter table public.store_admins enable row level security;
grant select on public.store_admins to authenticated;

drop policy if exists "store_admins_select_own" on public.store_admins;
create policy "store_admins_select_own"
on public.store_admins for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "orders_select_store_admin" on public.orders;
create policy "orders_select_store_admin"
on public.orders for select to authenticated
using (
  exists (
    select 1 from public.store_admins sa
    where sa.user_id = (select auth.uid())
      and sa.store_slug = orders.store_slug
  )
);

drop policy if exists "orders_update_store_admin" on public.orders;
create policy "orders_update_store_admin"
on public.orders for update to authenticated
using (
  exists (
    select 1 from public.store_admins sa
    where sa.user_id = (select auth.uid())
      and sa.store_slug = orders.store_slug
      and sa.role in ('owner','manager','operator')
  )
)
with check (
  exists (
    select 1 from public.store_admins sa
    where sa.user_id = (select auth.uid())
      and sa.store_slug = orders.store_slug
      and sa.role in ('owner','manager','operator')
  )
);

drop policy if exists "order_items_select_store_admin" on public.order_items;
create policy "order_items_select_store_admin"
on public.order_items for select to authenticated
using (
  exists (
    select 1
    from public.orders o
    join public.store_admins sa on sa.store_slug = o.store_slug
    where o.id = order_items.order_id
      and sa.user_id = (select auth.uid())
  )
);

-- Recomendação: depois de aplicar a alteração, rode os Security Advisors.

-- V3: integridade, auditoria e atualização automática
alter table public.orders drop constraint if exists orders_status_check;
alter table public.orders add constraint orders_status_check check (status in (
  'whatsapp_pending','received','confirmed','preparing','ready','out_for_delivery','completed','cancelled'
));
alter table public.orders drop constraint if exists orders_total_nonnegative;
alter table public.orders add constraint orders_total_nonnegative check (subtotal >= 0 and delivery_fee >= 0 and discount >= 0 and total >= 0);
alter table public.order_items drop constraint if exists order_items_money_nonnegative;
alter table public.order_items add constraint order_items_money_nonnegative check (unit_price >= 0 and line_total >= 0);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists orders_touch_updated_at on public.orders;
create trigger orders_touch_updated_at before update on public.orders
for each row execute function public.touch_updated_at();

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at before update on public.profiles
for each row execute function public.touch_updated_at();

revoke all on function public.touch_updated_at() from public, anon, authenticated;

-- Realtime somente para a operação de pedidos.
do $$
begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='orders') then
    alter publication supabase_realtime add table public.orders;
  end if;
end $$;
