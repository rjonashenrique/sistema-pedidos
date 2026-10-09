# AdmDev — correção de autorização

1. Confirme que `rojonas71@gmail.com` existe em Supabase Authentication > Users.
2. No SQL Editor do projeto correto, execute `supabase/admdev-super-admin.sql`.
3. O script idempotente atualiza `platform_admins` e vincula o usuário à organização técnica `jonashdev-admdev` em `organization_members` com `SUPER_ADMIN`.
4. Confira as colunas `platform_role`, `active`, `organization_role` e `member_status` no resultado final.
5. Publique o conteúdo do ZIP no Netlify e teste `/super-admin/`.

O script pressupõe que `supabase/saas-v2-schema.sql` já foi aplicado e que as tabelas `organizations`, `organization_members` e `platform_admins` existem. Não armazene `service_role` no navegador. A organização técnica é uma organização real no banco e pode aparecer na listagem global.
