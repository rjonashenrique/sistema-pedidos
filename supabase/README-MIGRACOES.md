# Registro Supabase — Pedidos Pro Central

Projeto existente: `pdvmvyzykuwdjmosmqrb` · Região `sa-east-1` · Plano Free.

## Estrutura utilizada
- `pedidos_pro_stores`: cadastro/slug/status das lojas.
- `pedidos_pro_developer_admins`: autorização do administrador central.
- `pedidos_pro_store_members`: vínculo de usuário Auth com loja e papel (`owner`/`operator`).
- `pedidos_pro_store_settings`: WhatsApp, endereço, taxa, mínimo e modos de atendimento.
- `pedidos_pro_store_products`: catálogo por loja.
- `pedidos_pro_orders` e `pedidos_pro_order_items`: pedidos e itens.
- `pedidos_pro_customer_profiles`: perfil do cliente.

## Alterações já aplicadas nesta conversa
1. Tabelas de clientes/pedidos/itens e políticas RLS multi-loja.
2. Restrição de atualização do pedido para status (permissões por coluna).
3. Helper de membership movido para schema `private`.
4. Tabelas de produtos e configurações da loja com RLS e políticas de acesso.
5. Função auxiliar de autorização de administrador e políticas para administração central/vínculos.
6. Política para o usuário autenticado ler a própria autorização de administrador.

## Validação e pendências
- As migrações retornaram sucesso na ferramenta Supabase.
- O Security Advisor ainda indicou duas tabelas legadas sem políticas: `pedidos_stores` e `pedidos_store_licenses`.
- O Auth reportou a proteção de senhas comprometidas desativada.
- A verificação realizada confirmou políticas presentes nas tabelas novas; isso não substitui testes de integração com usuários reais.
- Não foi criado dump/backup completo. Antes de novas alterações sensíveis, fazer backup/exportação apropriada.

Não rode novamente scripts destrutivos sobre produção sem inspecionar o schema atual e criar backup. Nunca exponha `service_role` no navegador.
