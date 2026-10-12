-- Revise antes de executar. Migração aditiva; não apaga dados.
create schema if not exists private;
create table if not exists public.pedidos_pro_store_settings (
  store_id uuid primary key references public.pedidos_pro_stores(id) on delete cascade,
  whatsapp text not null default '', phone text not null default '', address text not null default '',
  opening_hours jsonb not null default '{}'::jsonb,
  delivery_fee numeric(10,2) not null default 0 check (delivery_fee >= 0),
  minimum_order numeric(10,2) not null default 0 check (minimum_order >= 0),
  accepts_delivery boolean not null default true, accepts_pickup boolean not null default true,
  updated_at timestamptz not null default now()
);
create table if not exists public.pedidos_pro_store_products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.pedidos_pro_stores(id) on delete cascade,
  name text not null, description text not null default '', category text not null default 'Geral',
  price numeric(10,2) not null check (price >= 0), image_url text not null default '',
  is_available boolean not null default true, sort_order integer not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create index if not exists pedidos_pro_store_products_store_idx on public.pedidos_pro_store_products(store_id,is_available,sort_order);
alter table public.pedidos_pro_store_settings enable row level security;
alter table public.pedidos_pro_store_products enable row level security;
drop policy if exists "active store settings are public" on public.pedidos_pro_store_settings;
create policy "active store settings are public" on public.pedidos_pro_store_settings for select to anon,authenticated using (exists(select 1 from public.pedidos_pro_stores s where s.id=store_id and s.status='active'));
drop policy if exists "members manage own store settings" on public.pedidos_pro_store_settings;
create policy "members manage own store settings" on public.pedidos_pro_store_settings for all to authenticated using (private.pedidos_pro_is_store_member(store_id)) with check (private.pedidos_pro_is_store_member(store_id));
drop policy if exists "available products are public for active stores" on public.pedidos_pro_store_products;
create policy "available products are public for active stores" on public.pedidos_pro_store_products for select to anon,authenticated using ((is_available=true and exists(select 1 from public.pedidos_pro_stores s where s.id=store_id and s.status='active')) or private.pedidos_pro_is_store_member(store_id));
drop policy if exists "members manage own store products" on public.pedidos_pro_store_products;
create policy "members manage own store products" on public.pedidos_pro_store_products for all to authenticated using (private.pedidos_pro_is_store_member(store_id)) with check (private.pedidos_pro_is_store_member(store_id));
grant select on public.pedidos_pro_store_settings,public.pedidos_pro_store_products to anon,authenticated;
grant insert,update,delete on public.pedidos_pro_store_settings,public.pedidos_pro_store_products to authenticated;
