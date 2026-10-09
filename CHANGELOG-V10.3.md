# V10.3 — Área Dev cria loja para o dono

- Novo painel SaaS em `/dev/` com login, verificação de `saas_platform_admins`, listagem de lojas e indicadores.
- Formulário Dev para criar loja e vinculá-la a uma conta Supabase Auth existente pelo e-mail.
- Criação transacional da loja, membro `owner` e assinatura trial de 7 dias via RPC `saas_admin_create_store`.
- A rota antiga de diagnóstico foi preservada em `dev/diagnostico.html`.
- Migração adicional: `supabase/migrations/V10_3_dev_create_store_for_owner.sql`.
- Sem chave `service_role` no cliente; não cria senhas de terceiros.
- Requer aplicar migração V10 e depois V10.3, cadastrar a conta Dev em `saas_platform_admins` e testar RLS.

## Complemento V10.4 — prévia automática de URL por slug
- Sugere o slug a partir do nome da loja, permitindo edição manual.
- Exibe a URL no formato `https://{slug}.netlify.app` em tempo real.
- Mantém o link de cardápio no domínio atual como alternativa compatível com a configuração existente.
- Informa que o subdomínio Netlify exige provisionamento/configuração do site e resolução do tenant por hostname; a geração do texto não cria automaticamente um site na Netlify.
