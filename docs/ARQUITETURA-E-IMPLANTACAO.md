# Pedidos Pro — pacote completo

## Estrutura
- `public/client/`: cardápio e experiência do cliente.
- `public/owner/`: painel do dono/operador.
- `public/kitchen/`: quadro da cozinha.
- `public/delivery/`: área do entregador.
- `private-central-admin/`: administração central; manter fora do site público e fora dos ZIPs entregues aos lojistas.
- `supabase/migrations/`: migração adicional de entregas e referência da migração de catálogo.
- `docs/`: checklists de configuração, validação e operação.

## Projeto Supabase
Projeto existente: `Pedidos Pro Central` (`pdvmvyzykuwdjmosmqrb`), região São Paulo (`sa-east-1`). O pacote não cria outro projeto e não solicita upgrade de plano.

A chave `sb_publishable_...` presente nos `config.js` é uma chave publicável, destinada ao navegador. Nunca adicione `service_role`, senha de banco, token de acesso pessoal ou segredo de Edge Function aos arquivos públicos.

## Ordem sugerida
1. Faça exportação/backup do banco antes de novas alterações sensíveis.
2. Confirme no Supabase que as migrações de pedidos, RLS, produtos e configurações listadas em `supabase/README-MIGRACOES.md` já existem.
3. Revise `supabase/migrations/20261011_delivery_assignments.sql` e aplique-a no projeto existente para ativar a tabela de atribuições de entrega e as políticas de leitura relacionadas.
4. Publique `public/client`, `public/owner`, `public/kitchen` e `public/delivery` em HTTPS. Configure cada `config.js` com a URL e a chave publicável do projeto correto.
5. Publique a administração central em host privado/restrito, nunca dentro da pasta pública.
6. Configure URLs de redirecionamento no Supabase Auth e crie contas de teste separadas para cliente, dono, cozinha e entregador.
7. Vincule dono/operadores em `pedidos_pro_store_members`. Para o entregador, crie a atribuição em `pedidos_pro_delivery_assignments` com o UUID do usuário Auth e o pedido/loja correspondentes.
8. Faça os testes descritos em `docs/TESTES-ANTES-DE-PRODUCAO.md`.

## Limitações conhecidas
- A tela de entregas consome `pedidos_pro_delivery_assignments`; não aparecerão entregas até que a migração seja aplicada e atribuições sejam criadas.
- O painel central permite cadastro de loja e vínculo de equipe; os vínculos são feitos pelo UUID Auth e exigem que o usuário já exista.
- O checkout da área do cliente grava pedido e itens em operações separadas e recebe valores do navegador. Antes de aceitar pedidos reais em escala, implemente checkout transacional no servidor/Edge Function que consulte o catálogo oficial e recalcule preços, descontos, taxa, pedido mínimo e estoque.
- Não estão implementados gateway de pagamento, impressão térmica, upload próprio de imagens, push notifications nem cálculo de rota por mapa.
- A migração de entregas é fornecida no pacote, mas não foi aplicada automaticamente por este empacotamento.

## Segurança pendente conhecida
O último Security Advisor consultado ainda sinalizou as tabelas legadas `public.pedidos_stores` e `public.pedidos_store_licenses` com RLS sem políticas, e a proteção contra senhas comprometidas do Auth desativada. Revisar o uso dessas tabelas antigas e corrigir as políticas antes de produção; habilitar a proteção no painel de Auth. Não aplicar políticas genéricas sem entender se as tabelas legadas ainda são utilizadas.
