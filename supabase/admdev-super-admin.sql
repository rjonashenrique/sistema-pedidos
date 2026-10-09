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
end $$;

-- Verifique a autorização sem expor credenciais:
select u.email, a.role, a.active, a.created_at
from public.platform_admins a
join auth.users u on u.id = a.user_id
where lower(u.email) = lower('rojonas71@gmail.com');
