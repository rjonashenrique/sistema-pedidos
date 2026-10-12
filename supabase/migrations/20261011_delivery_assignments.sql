-- Pedidos Pro Central: módulo de entregas (migração aditiva; não apaga dados).
-- Revisar e aplicar somente no projeto existente pdvmvyzykuwdjmosmqrb.

create table if not exists public.pedidos_pro_delivery_assignments (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.pedidos_pro_stores(id) on delete cascade,
  order_id uuid not null unique references public.pedidos_pro_orders(id) on delete cascade,
  driver_user_id uuid not null references auth.users(id) on delete restrict,
  assigned_by uuid not null default auth.uid() references auth.users(id) on delete restrict,
  status text not null default 'assigned' check (status in ('assigned','picked_up','delivered','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists pedidos_pro_delivery_driver_status_idx
  on public.pedidos_pro_delivery_assignments(driver_user_id,status,created_at desc);
create index if not exists pedidos_pro_delivery_store_idx
  on public.pedidos_pro_delivery_assignments(store_id,created_at desc);

alter table public.pedidos_pro_delivery_assignments enable row level security;

-- Donos/operadores só podem consultar e administrar entregas da própria loja.
drop policy if exists "store members manage delivery assignments" on public.pedidos_pro_delivery_assignments;
create policy "store members manage delivery assignments"
  on public.pedidos_pro_delivery_assignments
  for all to authenticated
  using (private.pedidos_pro_is_store_member(store_id))
  with check (private.pedidos_pro_is_store_member(store_id));

-- O entregador vê somente as atribuições ligadas ao seu usuário e pode atualizar seu status.
drop policy if exists "drivers read own assignments" on public.pedidos_pro_delivery_assignments;
create policy "drivers read own assignments"
  on public.pedidos_pro_delivery_assignments
  for select to authenticated
  using (driver_user_id = (select auth.uid()));
drop policy if exists "drivers update own assignments" on public.pedidos_pro_delivery_assignments;
create policy "drivers update own assignments"
  on public.pedidos_pro_delivery_assignments
  for update to authenticated
  using (driver_user_id = (select auth.uid()))
  with check (driver_user_id = (select auth.uid()));

grant select, insert, update, delete on public.pedidos_pro_delivery_assignments to authenticated;

-- Permite que o entregador leia apenas o pedido que foi atribuído a ele.
drop policy if exists "assigned drivers read assigned orders" on public.pedidos_pro_orders;
create policy "assigned drivers read assigned orders"
  on public.pedidos_pro_orders
  for select to authenticated
  using (exists (
    select 1 from public.pedidos_pro_delivery_assignments d
    where d.order_id = pedidos_pro_orders.id
      and d.driver_user_id = (select auth.uid())
      and d.store_id = pedidos_pro_orders.store_id
  ));

-- Itens visíveis ao entregador somente quando pertencem a um pedido atribuído a ele.
drop policy if exists "assigned drivers read assigned order items" on public.pedidos_pro_order_items;
create policy "assigned drivers read assigned order items"
  on public.pedidos_pro_order_items
  for select to authenticated
  using (exists (
    select 1 from public.pedidos_pro_delivery_assignments d
    where d.order_id = pedidos_pro_order_items.order_id
      and d.driver_user_id = (select auth.uid())
  ));
