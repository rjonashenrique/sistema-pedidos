# Esquema de banco incluído no pacote

O banco de dados ativo fica no projeto Supabase existente `pdvmvyzykuwdjmosmqrb`; o ZIP não contém exportação de dados reais nem credenciais privadas.

## Tabelas existentes confirmadas na inspeção
- `pedidos_pro_stores` — lojas, slug e status.
- `pedidos_pro_developer_admins` — autorização do administrador central.
- `pedidos_pro_store_members` — vínculo entre usuário Auth e loja.
- `pedidos_pro_store_settings` — WhatsApp, telefone, endereço, taxa, mínimo, entrega e retirada.
- `pedidos_pro_store_products` — catálogo por loja.
- `pedidos_pro_customer_profiles` — perfil do cliente.
- `pedidos_pro_orders` — pedidos e status.
- `pedidos_pro_order_items` — itens do pedido.

## Script novo para entregas
`migrations/20261011_delivery_assignments.sql` cria `pedidos_pro_delivery_assignments` e políticas RLS para atribuições de entrega. Esse script está incluído para revisão e aplicação separada; não foi aplicado automaticamente ao preparar o ZIP.

## Referência de catálogo
`migrations/20261011_catalog_settings_reference.sql` é uma cópia de referência da migração de catálogo/configurações já aplicada anteriormente. Não rode migrações de referência às cegas em produção. Inspecione o estado atual, exporte/backup antes e revise o SQL.

## Sem dump de dados
Este pacote não contém dump completo do banco, dados pessoais de clientes, senha do banco ou chave `service_role`. Para backup real, use as opções oficiais de exportação/backup do Supabase no projeto ativo.
