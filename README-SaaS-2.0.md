# Sistema de Pedidos WhatsApp 2.0 — Advanced SaaS

Esta versão usa o projeto V10.1 enviado como base e adiciona a camada **SaaS Multiempresa** sem remover o cliente público, Admin Gerador, Central, KDS/entregadores e PWA existentes.

## O que foi adicionado

- arquitetura `organizations` → `stores` → `organization_members`;
- papéis SUPER_ADMIN, OWNER, ADMIN, MANAGER, KITCHEN, ATTENDANT e DELIVERY;
- planos Starter, Pro e Premium configuráveis;
- assinaturas, faturas e limites;
- feature flags por loja;
- tabelas V2 de produtos, adicionais, combos, clientes, pedidos e pagamentos;
- RLS orientado a organização/loja;
- índices multi-tenant;
- Realtime para pedidos e notificações;
- auditoria;
- estrutura de Super Admin em `/super-admin/`;
- templates de Edge Functions para Mercado Pago e webhook;
- documentação de segurança.

## Importante

A migration `supabase/saas-v2-schema.sql` **não é executada automaticamente**. Execute-a no SQL Editor do projeto Supabase depois de revisar as políticas e adaptar eventuais tabelas já existentes.

O Mercado Pago também não é marcado como funcionando apenas porque os arquivos existem. Antes de produção, configure `MP_ACCESS_TOKEN` como secret da Edge Function e implemente/valide a consulta server-side do pagamento e a assinatura do webhook.

## Super Admin

Abra `/super-admin/` depois de publicar o projeto. O usuário precisa estar autenticado e possuir uma linha em `organization_members` com `role = 'SUPER_ADMIN'` e `status = 'ACTIVE'`.

Não atribua esse papel por `user_metadata` e não coloque `service_role` no navegador.

## Variáveis públicas

Somente:

```env
VITE_SUPABASE_URL=
VITE_SUPABASE_PUBLISHABLE_KEY=
```

No projeto estático atual, a configuração continua em `config/loja.js`. Para a camada SaaS, a mesma URL/chave pública pode ser reutilizada pelo `super-admin/platform.js`.

## Secrets server-side

Nunca publique:

- `service_role`;
- Mercado Pago Access Token;
- webhook secrets;
- outras credenciais privadas.

Esses valores devem permanecer nas secrets das Edge Functions.

## Compatibilidade

O cliente público V10.1 continua em HTML/CSS/JavaScript e pode ser publicado em Vercel ou Netlify. A camada SaaS 2.0 é incremental e pode evoluir para React/TypeScript sem exigir a remoção imediata do storefront atual.

## Próxima etapa recomendada

1. Executar e revisar `supabase/saas-v2-schema.sql`.
2. Criar o primeiro SUPER_ADMIN de forma controlada.
3. Migrar uma loja de demonstração para `organizations/stores`.
4. Migrar pedidos novos para `orders_v2`.
5. Conectar o checkout ao fluxo transacional V2.
6. Implementar Edge Functions reais do Mercado Pago.
7. Testar RLS com duas organizações e dois usuários.
8. Só então migrar todas as lojas existentes.
