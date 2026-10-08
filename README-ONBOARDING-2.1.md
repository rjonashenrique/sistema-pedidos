# Sistema de Pedidos — SaaS 2.1 Self-Service

## Modelo de negócio
O cliente não depende do administrador da plataforma para criar sua hamburgueria. Ele:

1. cria a própria conta;
2. cria a própria empresa;
3. escolhe o plano;
4. vira `OWNER` daquela organização;
5. acessa o painel da própria empresa;
6. administra a operação sem enxergar outros tenants.

O proprietário da plataforma continua com um painel separado (`/super-admin/`) para administrar o SaaS, planos, assinaturas e organizações.

## Fluxo
`/cadastro/` → conta → empresa → loja → assinatura de teste → `/painel/`.

## Banco
Execute primeiro `supabase/saas-v2-schema.sql` e depois `supabase/saas-v2-onboarding.sql` no SQL Editor do Supabase.

A criação da empresa usa `create_owner_company(...)` como função `SECURITY DEFINER`. Isso evita colocar `service_role` no frontend e mantém o bootstrap transacional no banco.

## Segurança
- autorização por `organization_members`;
- tenant isolation via RLS;
- o usuário recebe `OWNER` somente pela função de onboarding;
- o navegador nunca recebe `service_role`;
- o token secreto do Mercado Pago continua somente no backend/Edge Function;
- não use `user_metadata` para decidir permissões administrativas.

## Importante
Esta atualização cria o fluxo self-service e o contexto multiempresa. O painel administrativo V10.1 existente ainda contém partes do fluxo legado e não deve ser considerado, sozinho, a implementação final de todas as permissões RBAC do SaaS 2.0. A próxima etapa é migrar cada tela de operação para `organization_id/store_id` e aplicar a matriz de permissões no RLS.
