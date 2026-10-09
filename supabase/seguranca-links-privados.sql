-- V8.7 — links privados por loja + endurecimento de permissões
-- Execute no SQL Editor do projeto Supabase usando uma conta administrativa.
-- Nunca coloque a service_role no frontend. Esta migração não cria vínculo de dono automaticamente.

begin;

-- O vínculo entre usuário e loja só pode ser criado por um administrador do banco.
alter table public.store_admins enable row level security;
revoke all on table public.store_admins from anon, authenticated;
grant select on table public.store_admins to authenticated;
drop policy if exists "store_admins_select_own" on public.store_admins;
create policy "store_admins_select_own"
  on public.store_admins for select to authenticated
  using ((select auth.uid()) = user_id);

-- Clientes consultam os próprios pedidos; gestores só consultam pedidos das lojas vinculadas.
-- A política orders_select_store_admin deve existir no schema.sql V8.6.
alter table public.orders enable row level security;
drop policy if exists "orders_insert_own" on public.orders;
drop policy if exists "orders_update_own" on public.orders;
revoke all on table public.orders from anon, authenticated;
grant select on table public.orders to authenticated;
-- A Central só precisa atualizar status e updated_at; impede alterar valor, user_id ou store_slug.
grant update (status, updated_at) on table public.orders to authenticated;

-- Inserção de pedido e itens ocorre pela RPC transacional create_customer_order, não por INSERT direto.
alter table public.order_items enable row level security;
drop policy if exists "order_items_insert_own" on public.order_items;
revoke all on table public.order_items from anon, authenticated;
grant select on table public.order_items to authenticated;

-- Garantir que a RPC só seja chamada por usuários autenticados.
revoke all on function public.create_customer_order(jsonb) from public, anon;
grant execute on function public.create_customer_order(jsonb) to authenticated;

commit;

-- =============================================================
-- VINCULAR O DONO A UMA LOJA (rode separadamente, após criar a conta)
-- 1. No Supabase Dashboard > Authentication > Users, crie/confirme o usuário.
-- 2. Substitua o e-mail e o slug abaixo e execute este bloco no SQL Editor.
-- 3. Nunca exponha uma rota pública que permita ao usuário inserir seu próprio vínculo.
--
-- insert into public.store_admins (user_id, store_slug, role)
-- select id, 'brasa-burger', 'owner'
-- from auth.users
-- where lower(email) = lower('dono@exemplo.com')
-- on conflict (user_id, store_slug) do update set role = excluded.role;
--
-- Verifique o vínculo:
-- select u.email, sa.store_slug, sa.role
-- from public.store_admins sa join auth.users u on u.id = sa.user_id
-- where lower(u.email) = lower('dono@exemplo.com');
-- =============================================================

-- TESTE MANUAL DE ISOLAMENTO
-- A) Dono A vinculado a 'brasa-burger' só deve ver pedidos desse slug na Central.
-- B) Dono B vinculado a 'loja-do-joao' só deve ver pedidos desse slug.
-- C) Abra o link de A autenticado como B: a interface deve negar acesso e nenhuma linha de A deve ser retornada.
-- D) Altere ?loja=brasa-burger para ?loja=loja-do-joao: o banco deve continuar bloqueando lojas não vinculadas.
-- E) Como usuário autenticado comum, tente inserir/alterar diretamente orders e order_items: INSERT deve ser negado;
--    UPDATE de orders só pode modificar status/updated_at e somente se houver vínculo autorizado à loja.
