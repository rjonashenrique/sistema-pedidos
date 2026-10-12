-- Migration aditiva aplicada ao projeto Supabase Central existente.
-- Não remove dados. Roles e tabelas para entregas, cupons, favoritos, fidelidade e auditoria.
create or replace function private.pedidos_pro_has_store_role(p_store_id uuid, p_roles text[])
returns boolean language sql stable security definer set search_path = '' as $$
  select exists (
    select 1 from public.pedidos_pro_store_members m
    where m.store_id = p_store_id and m.user_id = (select auth.uid()) and m.role = any(p_roles)
  );
$$;
revoke all on function private.pedidos_pro_has_store_role(uuid,text[]) from public;
grant execute on function private.pedidos_pro_has_store_role(uuid,text[]) to authenticated;

alter table public.pedidos_pro_store_members drop constraint if exists pedidos_pro_store_members_role_check;
alter table public.pedidos_pro_store_members add constraint pedidos_pro_store_members_role_check
  check (role = any (array['owner','operator','kitchen','delivery']::text[]));

create table if not exists public.pedidos_pro_delivery_assignments (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.pedidos_pro_stores(id) on delete cascade,
  order_id uuid not null references public.pedidos_pro_orders(id) on delete cascade,
  delivery_user_id uuid not null references auth.users(id) on delete restrict,
  status text not null default 'assigned' check (status = any (array['assigned','picked_up','delivered','cancelled']::text[])),
  assigned_by uuid references auth.users(id) on delete set null,
  assigned_at timestamptz not null default now(), picked_up_at timestamptz, delivered_at timestamptz, notes text,
  constraint pedidos_pro_delivery_assignments_order_unique unique(order_id)
);
create index if not exists pedidos_pro_delivery_user_status_idx on public.pedidos_pro_delivery_assignments(delivery_user_id,status,assigned_at desc);
create index if not exists pedidos_pro_delivery_store_status_idx on public.pedidos_pro_delivery_assignments(store_id,status,assigned_at desc);
alter table public.pedidos_pro_delivery_assignments enable row level security;
drop policy if exists "delivery staff read own assignments" on public.pedidos_pro_delivery_assignments;
create policy "delivery staff read own assignments" on public.pedidos_pro_delivery_assignments for select to authenticated using (delivery_user_id = (select auth.uid()));
drop policy if exists "store managers manage assignments" on public.pedidos_pro_delivery_assignments;
create policy "store managers manage assignments" on public.pedidos_pro_delivery_assignments for all to authenticated
  using (private.pedidos_pro_has_store_role(store_id,array['owner','operator']))
  with check (private.pedidos_pro_has_store_role(store_id,array['owner','operator']));
drop policy if exists "delivery staff update own assignment status" on public.pedidos_pro_delivery_assignments;
create policy "delivery staff update own assignment status" on public.pedidos_pro_delivery_assignments for update to authenticated
  using (delivery_user_id = (select auth.uid()) and status in ('assigned','picked_up'))
  with check (delivery_user_id = (select auth.uid()) and status in ('assigned','picked_up','delivered'));
drop policy if exists "assigned delivery staff read assigned orders" on public.pedidos_pro_orders;
create policy "assigned delivery staff read assigned orders" on public.pedidos_pro_orders for select to authenticated using (exists (
  select 1 from public.pedidos_pro_delivery_assignments a where a.order_id = pedidos_pro_orders.id and a.delivery_user_id = (select auth.uid()) and a.status <> 'cancelled'
));
drop policy if exists "assigned delivery staff read assigned order items" on public.pedidos_pro_order_items;
create policy "assigned delivery staff read assigned order items" on public.pedidos_pro_order_items for select to authenticated using (exists (
  select 1 from public.pedidos_pro_orders o join public.pedidos_pro_delivery_assignments a on a.order_id=o.id
  where o.id=pedidos_pro_order_items.order_id and a.delivery_user_id=(select auth.uid()) and a.status <> 'cancelled'
));

create table if not exists public.pedidos_pro_coupons (
  id uuid primary key default gen_random_uuid(), store_id uuid not null references public.pedidos_pro_stores(id) on delete cascade,
  code text not null, discount_type text not null check (discount_type in ('percentage','fixed')),
  discount_value numeric(10,2) not null check (discount_value > 0), minimum_subtotal numeric(10,2) not null default 0 check (minimum_subtotal >= 0),
  max_discount numeric(10,2), usage_limit integer, usage_count integer not null default 0 check (usage_count >= 0),
  starts_at timestamptz, expires_at timestamptz, is_active boolean not null default true, created_at timestamptz not null default now(),
  unique(store_id,code), check (max_discount is null or max_discount >= 0), check (usage_limit is null or usage_limit > 0)
);
create index if not exists pedidos_pro_coupons_store_active_idx on public.pedidos_pro_coupons(store_id,is_active,code);
alter table public.pedidos_pro_coupons enable row level security;
drop policy if exists "store members manage coupons" on public.pedidos_pro_coupons;
create policy "store members manage coupons" on public.pedidos_pro_coupons for all to authenticated
  using (private.pedidos_pro_is_store_member(store_id)) with check (private.pedidos_pro_is_store_member(store_id));

create table if not exists public.pedidos_pro_customer_favorites (
  id uuid primary key default gen_random_uuid(), customer_id uuid not null references auth.users(id) on delete cascade,
  store_id uuid not null references public.pedidos_pro_stores(id) on delete cascade,
  product_id uuid not null references public.pedidos_pro_store_products(id) on delete cascade,
  created_at timestamptz not null default now(), unique(customer_id,store_id,product_id)
);
alter table public.pedidos_pro_customer_favorites enable row level security;
drop policy if exists "customers manage own favorites" on public.pedidos_pro_customer_favorites;
create policy "customers manage own favorites" on public.pedidos_pro_customer_favorites for all to authenticated
  using (customer_id = (select auth.uid())) with check (customer_id = (select auth.uid()));

create table if not exists public.pedidos_pro_loyalty_ledger (
  id uuid primary key default gen_random_uuid(), store_id uuid not null references public.pedidos_pro_stores(id) on delete cascade,
  customer_id uuid not null references auth.users(id) on delete cascade, order_id uuid references public.pedidos_pro_orders(id) on delete set null,
  points integer not null, reason text not null, created_at timestamptz not null default now()
);
create index if not exists pedidos_pro_loyalty_customer_idx on public.pedidos_pro_loyalty_ledger(store_id,customer_id,created_at desc);
alter table public.pedidos_pro_loyalty_ledger enable row level security;
drop policy if exists "customers read own loyalty points" on public.pedidos_pro_loyalty_ledger;
create policy "customers read own loyalty points" on public.pedidos_pro_loyalty_ledger for select to authenticated using (customer_id = (select auth.uid()));
drop policy if exists "store members read loyalty ledger" on public.pedidos_pro_loyalty_ledger;
create policy "store members read loyalty ledger" on public.pedidos_pro_loyalty_ledger for select to authenticated using (private.pedidos_pro_is_store_member(store_id));

create table if not exists public.pedidos_pro_audit_log (
  id bigint generated always as identity primary key, store_id uuid references public.pedidos_pro_stores(id) on delete set null,
  actor_user_id uuid references auth.users(id) on delete set null, action text not null, entity_type text not null,
  entity_id text, details jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create index if not exists pedidos_pro_audit_store_created_idx on public.pedidos_pro_audit_log(store_id,created_at desc);
alter table public.pedidos_pro_audit_log enable row level security;
drop policy if exists "store managers read audit log" on public.pedidos_pro_audit_log;
create policy "store managers read audit log" on public.pedidos_pro_audit_log for select to authenticated using (
  (store_id is not null and private.pedidos_pro_has_store_role(store_id,array['owner','operator'])) or private.pedidos_pro_is_developer_admin()
);
revoke all on public.pedidos_pro_audit_log from anon, authenticated;
grant select on public.pedidos_pro_audit_log to authenticated;
