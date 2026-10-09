-- V10 SaaS — PRÉ-CHECAGEM SOMENTE LEITURA
-- Execute no mesmo projeto Supabase da Brasa Burger ANTES da migração.
-- Este arquivo não cria, altera nem apaga dados.

select current_database() as database_name, now() as checked_at;

select
  to_regclass('public.orders') as legacy_orders_table,
  to_regclass('public.order_items') as legacy_order_items_table,
  to_regclass('public.profiles') as legacy_profiles_table,
  to_regclass('public.store_admins') as legacy_store_admins_table,
  to_regclass('public.saas_stores') as v10_stores_already_exist,
  to_regclass('public.saas_products') as v10_products_already_exist;

select id, email, email_confirmed_at, created_at
from auth.users
where lower(email) = lower('rojonas71@gmail.com');

-- Inventário de tabelas legadas: nomes e contagens, sem expor conteúdo dos pedidos.
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_type = 'BASE TABLE'
  and table_name in ('orders','order_items','profiles','store_admins')
order by table_name;
