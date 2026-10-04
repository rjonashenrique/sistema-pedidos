-- Central Administrativa Multi-Loja
-- Execute depois de criar public.store_admins.
-- 1) Crie o usuário administrativo em Authentication > Users.
-- 2) Troque SEU_EMAIL e o slug da loja abaixo.
-- 3) Repita para cada loja/administrador.

insert into public.store_admins (user_id, store_slug, role)
select id, 'brasa-burger', 'owner'
from auth.users
where email = 'SEU_EMAIL'
on conflict (user_id, store_slug) do update
set role = excluded.role;

-- Verificação:
select sa.store_slug, sa.role, u.email
from public.store_admins sa
join auth.users u on u.id = sa.user_id
order by sa.store_slug, u.email;
