-- V10 SaaS — PÓS-CHECAGEM SOMENTE LEITURA
-- Execute depois da migração. Não altera dados.

select table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in ('saas_stores','saas_store_members','saas_products','saas_subscriptions','saas_platform_admins')
order by table_name;

select c.relname as table_name, c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('saas_stores','saas_store_members','saas_products','saas_subscriptions','saas_platform_admins')
order by c.relname;

select slug, name, status, owner_user_id, created_at
from public.saas_stores
where slug = 'brasa-burger';

select s.slug, m.role, m.user_id
from public.saas_stores s
left join public.saas_store_members m on m.store_id = s.id
where s.slug = 'brasa-burger';

select s.slug, sub.plan_code, sub.status, sub.trial_ends_at
from public.saas_stores s
left join public.saas_subscriptions sub on sub.store_id = s.id
where s.slug = 'brasa-burger';

-- As tabelas legadas devem continuar existindo. Compare as contagens com o PRECHECK.
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_type = 'BASE TABLE'
  and table_name in ('orders','order_items','profiles','store_admins')
order by table_name;
