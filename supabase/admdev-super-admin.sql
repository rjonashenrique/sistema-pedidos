-- AdmDev / Super Admin da plataforma Jonash.dev
-- Execute no SQL Editor do projeto Supabase correto, depois de criar/confirmar
-- rojonas71@gmail.com em Authentication > Users. Seguro para reexecutar.
-- Esta migration NÃO cria uma senha nem confirma o e-mail no Auth.

create table if not exists public.platform_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'SUPER_ADMIN' check (role in ('SUPER_ADMIN')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.platform_admins enable row level security;

drop policy if exists platform_admins_read_self on public.platform_admins;
create policy platform_admins_read_self
  on public.platform_admins for select to authenticated
  using (user_id = (select auth.uid()));

-- Grants only the exact, existing Auth user. Run this migration as database owner.
do $$
declare v_user_id uuid;
begin
  select id into v_user_id
  from auth.users
  where lower(email) = lower('rojonas71@gmail.com')
  limit 1;

  if v_user_id is null then
    raise exception 'AdmDev não foi criado no Supabase Auth. Crie/confirme rojonas71@gmail.com em Authentication > Users e execute novamente.';
  end if;

  insert into public.platform_admins (user_id, role, active)
  values (v_user_id, 'SUPER_ADMIN', true)
  on conflict (user_id) do update
    set role = excluded.role, active = true, updated_at = now();

  -- Compatibilidade com o painel legado, que ainda verifica organization_members.
  -- Cria uma organização técnica de administração somente se ainda não existir.
  insert into public.organizations (name, slug, status)
  values ('Jonash.dev - Administração da Plataforma', 'jonashdev-admdev', 'ATIVA')
  on conflict (slug) do nothing;

  insert into public.organization_members (organization_id, user_id, role, status)
  select o.id, v_user_id, 'SUPER_ADMIN', 'ACTIVE'
  from public.organizations o
  where o.slug = 'jonashdev-admdev'
  on conflict (organization_id, user_id) do update
    set role = 'SUPER_ADMIN', status = 'ACTIVE';
end $$;

-- Verifique as duas autorizações:
select u.email, a.role as platform_role, a.active,
       m.role as organization_role, m.status as member_status,
       o.name as organization_name, a.created_at
from public.platform_admins a
join auth.users u on u.id = a.user_id
left join public.organization_members m on m.user_id = a.user_id
left join public.organizations o on o.id = m.organization_id
where lower(u.email) = lower('rojonas71@gmail.com');
