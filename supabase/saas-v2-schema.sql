-- ============================================================
-- SISTEMA DE PEDIDOS WHATSAPP 2.0 — SAAS MULTI-TENANT
-- PostgreSQL / Supabase
-- Execute após validar o schema atual. Esta migration cria a camada SaaS.
-- Nunca coloque service_role ou secrets no frontend.
-- ============================================================

create extension if not exists pgcrypto;

create table if not exists public.plans (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  name text not null,
  price_cents integer not null default 0 check (price_cents >= 0),
  max_stores integer,
  max_products integer,
  max_users integer,
  max_orders integer,
  max_storage_mb integer,
  features jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  logo_url text,
  status text not null default 'TRIAL' check (status in ('ATIVA','TRIAL','SUSPENSA','CANCELADA')),
  plan_id uuid references public.plans(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  phone text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organization_members (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('SUPER_ADMIN','OWNER','ADMIN','MANAGER','KITCHEN','ATTENDANT','DELIVERY')),
  status text not null default 'ACTIVE' check (status in ('ACTIVE','INVITED','SUSPENDED')),
  created_at timestamptz not null default now(),
  unique (organization_id,user_id)
);

create table if not exists public.stores (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  slug text not null,
  logo_url text,
  cover_url text,
  description text,
  phone text,
  whatsapp text,
  instagram text,
  address jsonb not null default '{}'::jsonb,
  status text not null default 'ATIVA' check (status in ('ATIVA','TRIAL','SUSPENSA','CANCELADA')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id,slug)
);

create table if not exists public.store_settings (
  store_id uuid primary key references public.stores(id) on delete cascade,
  settings jsonb not null default '{}'::jsonb,
  feature_flags jsonb not null default '{"pix_enabled":true,"mercado_pago_enabled":false,"kitchen_enabled":true,"whatsapp_enabled":true,"analytics_enabled":false,"coupons_enabled":true,"delivery_enabled":true,"tables_enabled":false}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.business_hours (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  weekday smallint not null check (weekday between 0 and 6),
  open_time time,
  close_time time,
  closed boolean not null default false,
  manual_closed boolean not null default false,
  unique(store_id,weekday)
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null,
  sort_order integer not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  category_id uuid references public.categories(id) on delete set null,
  name text not null,
  description text,
  price_cents integer not null check(price_cents >= 0),
  promotional_price_cents integer check(promotional_price_cents is null or promotional_price_cents >= 0),
  image_url text,
  available boolean not null default true,
  featured boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.option_groups (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null,
  selection_type text not null default 'single' check(selection_type in ('single','multiple')),
  required boolean not null default false,
  min_items integer not null default 0 check(min_items >= 0),
  max_items integer check(max_items is null or max_items >= min_items),
  sort_order integer not null default 0
);

create table if not exists public.options (
  id uuid primary key default gen_random_uuid(),
  option_group_id uuid not null references public.option_groups(id) on delete cascade,
  name text not null,
  price_cents integer not null default 0 check(price_cents >= 0),
  available boolean not null default true,
  sort_order integer not null default 0
);

create table if not exists public.combos (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null,
  description text,
  original_price_cents integer not null check(original_price_cents >= 0),
  price_cents integer not null check(price_cents >= 0),
  image_url text,
  available boolean not null default true,
  sort_order integer not null default 0
);

create table if not exists public.combo_items (
  id uuid primary key default gen_random_uuid(),
  combo_id uuid not null references public.combos(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete restrict,
  quantity integer not null default 1 check(quantity > 0)
);

create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  code text not null,
  discount_type text not null check(discount_type in ('percentual','fixo')),
  value numeric(12,2) not null check(value >= 0),
  minimum_order numeric(12,2) not null default 0 check(minimum_order >= 0),
  starts_at timestamptz,
  expires_at timestamptz,
  active boolean not null default true,
  usage_limit integer,
  usage_count integer not null default 0,
  unique(store_id,code)
);

create table if not exists public.customers (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  name text not null,
  phone text,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.delivery_addresses (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  label text,
  address jsonb not null default '{}'::jsonb,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.orders_v2 (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete restrict,
  customer_id uuid references public.customers(id) on delete set null,
  order_number text not null,
  status text not null default 'NOVO' check(status in ('NOVO','CONFIRMADO','EM_PREPARACAO','PRONTO','SAIU_PARA_ENTREGA','ENTREGUE','CANCELADO')),
  order_type text not null check(order_type in ('DELIVERY','PICKUP')),
  payment_method text not null,
  payment_status text not null default 'PENDING' check(payment_status in ('PENDING','PAID','EXPIRED','CANCELLED','FAILED')),
  subtotal numeric(12,2) not null default 0 check(subtotal >= 0),
  discount numeric(12,2) not null default 0 check(discount >= 0),
  delivery_fee numeric(12,2) not null default 0 check(delivery_fee >= 0),
  total numeric(12,2) not null default 0 check(total >= 0),
  notes text,
  scheduled_for timestamptz,
  table_number text,
  whatsapp_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(store_id,order_number)
);

create table if not exists public.order_items_v2 (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders_v2(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  combo_id uuid references public.combos(id) on delete set null,
  name_snapshot text not null,
  quantity integer not null check(quantity > 0),
  unit_price numeric(12,2) not null check(unit_price >= 0),
  line_total numeric(12,2) not null check(line_total >= 0),
  notes text
);

create table if not exists public.order_item_options_v2 (
  id uuid primary key default gen_random_uuid(),
  order_item_id uuid not null references public.order_items_v2(id) on delete cascade,
  option_id uuid references public.options(id) on delete set null,
  name_snapshot text not null,
  price numeric(12,2) not null default 0 check(price >= 0)
);

create table if not exists public.order_status_history_v2 (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders_v2(id) on delete cascade,
  status text not null,
  changed_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.payments_v2 (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders_v2(id) on delete cascade,
  provider text not null,
  provider_payment_id text,
  amount numeric(12,2) not null check(amount >= 0),
  status text not null default 'PENDING' check(status in ('PENDING','PAID','EXPIRED','CANCELLED','FAILED')),
  raw_status text,
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.notifications_v2 (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade,
  store_id uuid references public.stores(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  type text not null,
  title text not null,
  body text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  plan_id uuid references public.plans(id) on delete set null,
  status text not null default 'TRIALING' check(status in ('ACTIVE','TRIALING','PAST_DUE','CANCELED')),
  starts_at timestamptz not null default now(),
  renews_at timestamptz,
  trial_ends_at timestamptz,
  canceled_at timestamptz,
  external_subscription_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.invoices (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  subscription_id uuid references public.subscriptions(id) on delete set null,
  amount numeric(12,2) not null check(amount >= 0),
  status text not null default 'PENDING',
  due_at timestamptz,
  paid_at timestamptz,
  external_id text,
  created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete cascade,
  store_id uuid references public.stores(id) on delete set null,
  user_id uuid references auth.users(id) on delete set null,
  action text not null,
  resource text,
  resource_id text,
  ip_address inet,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists organization_members_user_idx on public.organization_members(user_id);
create index if not exists organization_members_org_idx on public.organization_members(organization_id);
create index if not exists stores_org_idx on public.stores(organization_id);
create index if not exists products_store_idx on public.products(store_id,available,sort_order);
create index if not exists orders_v2_store_status_idx on public.orders_v2(store_id,status,created_at desc);
create index if not exists orders_v2_customer_idx on public.orders_v2(customer_id,created_at desc);
create index if not exists notifications_user_idx on public.notifications_v2(user_id,created_at desc);
create index if not exists audit_logs_org_idx on public.audit_logs(organization_id,created_at desc);

insert into public.plans(code,name,price_cents,max_stores,max_products,max_users,features)
values
('STARTER','Starter',4900,1,100,3,'{"pix_enabled":true,"kitchen_enabled":true,"whatsapp_enabled":true,"coupons_enabled":true}'::jsonb),
('PRO','Pro',9700,3,500,10,'{"pix_enabled":true,"mercado_pago_enabled":true,"kitchen_enabled":true,"whatsapp_enabled":true,"analytics_enabled":true,"coupons_enabled":true,"delivery_enabled":true}'::jsonb),
('PREMIUM','Premium',19700,null,null,null,'{"pix_enabled":true,"mercado_pago_enabled":true,"kitchen_enabled":true,"whatsapp_enabled":true,"analytics_enabled":true,"coupons_enabled":true,"delivery_enabled":true,"tables_enabled":true}'::jsonb)
on conflict(code) do nothing;

create or replace function public.is_super_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.organization_members m where m.user_id=auth.uid() and m.role='SUPER_ADMIN' and m.status='ACTIVE');
$$;

create or replace function public.is_org_member(p_org uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select public.is_super_admin() or exists(select 1 from public.organization_members m where m.organization_id=p_org and m.user_id=auth.uid() and m.status='ACTIVE');
$$;

create or replace function public.is_store_member(p_store uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select public.is_super_admin() or exists(select 1 from public.organization_members m join public.stores s on s.organization_id=m.organization_id where s.id=p_store and m.user_id=auth.uid() and m.status='ACTIVE');
$$;

alter table public.plans enable row level security;
alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.organization_members enable row level security;
alter table public.stores enable row level security;
alter table public.store_settings enable row level security;
alter table public.business_hours enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.option_groups enable row level security;
alter table public.options enable row level security;
alter table public.combos enable row level security;
alter table public.combo_items enable row level security;
alter table public.coupons enable row level security;
alter table public.customers enable row level security;
alter table public.delivery_addresses enable row level security;
alter table public.orders_v2 enable row level security;
alter table public.order_items_v2 enable row level security;
alter table public.order_item_options_v2 enable row level security;
alter table public.order_status_history_v2 enable row level security;
alter table public.payments_v2 enable row level security;
alter table public.notifications_v2 enable row level security;
alter table public.subscriptions enable row level security;
alter table public.invoices enable row level security;
alter table public.audit_logs enable row level security;

-- Policies administrativas: SUPER_ADMIN ou membro da organização/loja.
create policy plans_read_public on public.plans for select using (active=true or public.is_super_admin());
create policy org_superadmin_or_member on public.organizations for all using (public.is_super_admin() or exists(select 1 from public.organization_members m where m.organization_id=id and m.user_id=auth.uid())) with check(public.is_super_admin() or exists(select 1 from public.organization_members m where m.organization_id=id and m.user_id=auth.uid()));
create policy profiles_self_or_super on public.profiles for all using (id=auth.uid() or public.is_super_admin()) with check(id=auth.uid() or public.is_super_admin());
create policy members_access on public.organization_members for all using (public.is_super_admin() or user_id=auth.uid() or public.is_org_member(organization_id)) with check(public.is_super_admin() or public.is_org_member(organization_id));

-- Tabelas por loja.
create policy stores_access on public.stores for all using(public.is_store_member(id)) with check(public.is_store_member(id));
create policy store_settings_access on public.store_settings for all using(public.is_store_member(store_id)) with check(public.is_store_member(store_id));
create policy hours_access on public.business_hours for all using(public.is_store_member(store_id)) with check(public.is_store_member(store_id));
create policy categories_access on public.categories for all using(public.is_store_member(store_id)) with check(public.is_store_member(store_id));
create policy products_access on public.products for all using(public.is_store_member(store_id)) with check(public.is_store_member(store_id));
create policy groups_access on public.option_groups for all using(public.is_store_member(store_id)) with check(public.is_store_member(store_id));
create policy options_access on public.options for all using(exists(select 1 from public.option_groups g where g.id=option_group_id and public.is_store_member(g.store_id))) with check(exists(select 1 from public.option_groups g where g.id=option_group_id and public.is_store_member(g.store_id)));
create policy combos_access on public.combos for all using(public.is_store_member(store_id)) with check(public.is_store_member(store_id));
create policy combo_items_access on public.combo_items for all using(exists(select 1 from public.combos c where c.id=combo_id and public.is_store_member(c.store_id))) with check(exists(select 1 from public.combos c where c.id=combo_id and public.is_store_member(c.store_id)));
create policy coupons_access on public.coupons for all using(public.is_store_member(store_id)) with check(public.is_store_member(store_id));
create policy customers_access on public.customers for all using(public.is_store_member(store_id)) with check(public.is_store_member(store_id));
create policy addresses_access on public.delivery_addresses for all using(exists(select 1 from public.customers c where c.id=customer_id and public.is_store_member(c.store_id))) with check(exists(select 1 from public.customers c where c.id=customer_id and public.is_store_member(c.store_id)));
create policy orders_access on public.orders_v2 for all using(public.is_store_member(store_id)) with check(public.is_store_member(store_id));
create policy order_items_access on public.order_items_v2 for all using(exists(select 1 from public.orders_v2 o where o.id=order_id and public.is_store_member(o.store_id))) with check(exists(select 1 from public.orders_v2 o where o.id=order_id and public.is_store_member(o.store_id)));
create policy order_item_options_access on public.order_item_options_v2 for all using(exists(select 1 from public.order_items_v2 i join public.orders_v2 o on o.id=i.order_id where i.id=order_item_id and public.is_store_member(o.store_id))) with check(exists(select 1 from public.order_items_v2 i join public.orders_v2 o on o.id=i.order_id where i.id=order_item_id and public.is_store_member(o.store_id)));
create policy order_history_access on public.order_status_history_v2 for all using(exists(select 1 from public.orders_v2 o where o.id=order_id and public.is_store_member(o.store_id))) with check(exists(select 1 from public.orders_v2 o where o.id=order_id and public.is_store_member(o.store_id)));
create policy payments_access on public.payments_v2 for all using(exists(select 1 from public.orders_v2 o where o.id=order_id and public.is_store_member(o.store_id))) with check(exists(select 1 from public.orders_v2 o where o.id=order_id and public.is_store_member(o.store_id)));
create policy notifications_access on public.notifications_v2 for all using(public.is_super_admin() or user_id=auth.uid() or (store_id is not null and public.is_store_member(store_id))) with check(public.is_super_admin() or user_id=auth.uid() or (store_id is not null and public.is_store_member(store_id)));
create policy subscriptions_access on public.subscriptions for all using(public.is_super_admin() or public.is_org_member(organization_id)) with check(public.is_super_admin() or public.is_org_member(organization_id));
create policy invoices_access on public.invoices for all using(public.is_super_admin() or public.is_org_member(organization_id)) with check(public.is_super_admin() or public.is_org_member(organization_id));
create policy audit_access on public.audit_logs for select using(public.is_super_admin() or public.is_org_member(organization_id));

-- Realtime para operação.
do $$ begin
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='orders_v2') then alter publication supabase_realtime add table public.orders_v2; end if;
 if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='notifications_v2') then alter publication supabase_realtime add table public.notifications_v2; end if;
end $$;

-- Grants básicos para Data API. RLS continua sendo a barreira de segurança.
grant select on public.plans to anon,authenticated;
grant select,insert,update,delete on all tables in schema public to authenticated;
revoke all on function public.is_super_admin() from public,anon,authenticated;
revoke all on function public.is_org_member(uuid) from public,anon,authenticated;
revoke all on function public.is_store_member(uuid) from public,anon,authenticated;
grant execute on function public.is_super_admin() to authenticated;
grant execute on function public.is_org_member(uuid) to authenticated;
grant execute on function public.is_store_member(uuid) to authenticated;
