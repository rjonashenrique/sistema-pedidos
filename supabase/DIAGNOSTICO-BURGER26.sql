-- DIAGNÓSTICO SEGURO — BURGER26 / MIGRATION 2.2
-- Execute no Supabase SQL Editor (role postgres/admin).
-- Este arquivo é somente leitura: NÃO altera, exclui nem recria dados.

-- 1) Verifica se as funções da migration existem.
select n.nspname as schema_name, p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('get_my_business_context', 'repair_my_company')
order by p.proname;

-- 2) Lista organizações e lojas. Use para identificar a organização da Burger26.
select o.id as organization_id, o.name as organization_name,
       o.slug as organization_slug, o.status as organization_status,
       m.user_id, m.role as member_role, m.status as member_status,
       s.id as store_id, s.name as store_name, s.slug as store_slug,
       s.status as store_status
from public.organizations o
left join public.organization_members m on m.organization_id = o.id
left join public.stores s on s.organization_id = o.id
where o.name ilike '%burger26%'
   or o.slug ilike '%burger26%'
   or s.name ilike '%burger26%'
   or s.slug ilike '%burger26%'
order by o.created_at, s.created_at;

-- 3) Se a busca por nome/slug não encontrar a loja, liste vínculos sem loja.
select o.id as organization_id, o.name as organization_name,
       o.slug, o.status, m.user_id, m.role, m.status as member_status
from public.organizations o
join public.organization_members m on m.organization_id = o.id
left join public.stores s on s.organization_id = o.id
where s.id is null
order by o.created_at;

-- Envie os resultados das três consultas para analisar a causa exata.
-- Não execute INSERT/DELETE/UPDATE manualmente antes de identificar o registro correto.
