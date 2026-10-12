# Pedidos Pro — Roadmap Profissional Avançado

Este documento define as próximas evoluções do produto sem afirmar que recursos ainda planejados já estão implementados. O projeto Supabase existente (`pdvmvyzykuwdjmosmqrb`) e o plano Free devem ser mantidos. Não criar projeto novo nem ativar serviços pagos sem autorização expressa.

## 1. Áreas do produto

### Cliente
- Cardápio responsivo com categorias, busca e disponibilidade.
- Variações, adicionais, observações e combos.
- Carrinho persistente com resumo transparente de subtotal, entrega, descontos e total.
- Checkout com validação no servidor; endereço salvo com consentimento.
- Escolha entre entrega e retirada, quando habilitadas pela loja.
- Histórico, detalhe e repetição de pedidos; favoritos.
- Cupons e fidelidade somente após regras antifraude e validação server-side.
- Instalação PWA; avisos push como fase opcional, sujeitos à compatibilidade e aos limites gratuitos.

### Dono e equipe
- Dashboard com pedidos, vendas confirmadas, ticket médio e produtos populares.
- Catálogo: categorias, imagens, variações, adicionais, disponibilidade e estoque.
- Configuração da loja: nome, slug, contato, endereço, horários, feriados, taxa, pedido mínimo, entrega/retirada e pausa.
- Gestão de funcionários com papéis separados e menor privilégio.
- Relatórios por período e exportação CSV.
- Cupons, combos, promoções e fidelidade após o checkout seguro.
- Fechamento de caixa e conciliação somente com definição clara de estados de pagamento.

### Cozinha
- Fila de pedidos recebidos, confirmados, em preparo e prontos.
- Tempo decorrido, observações, prioridade e sinalização visual de atraso.
- Histórico de alterações de status e prevenção de transições inválidas.
- Impressão de comandas como integração futura opcional.

### Entregas
- Atribuição de pedidos a entregadores autorizados.
- Lista de entregas atribuídas, contato/endereço estritamente necessário e status.
- Registro de retirada, saída e conclusão; histórico e horário.
- Comprovante de entrega e mapa/rota como fase opcional, dependendo de privacidade, segurança e custos.
- Um entregador nunca deve listar pedidos não atribuídos a ele.

### Administração central
- Criar, editar, suspender e reativar lojas.
- Vincular membros a lojas e controlar papéis.
- Visão de saúde operacional e auditoria de ações administrativas.
- Planos/limites comerciais como configuração interna; não integrar cobrança recorrente antes de especificar regras e provedor.
- Painel central isolado da hospedagem pública das lojas; verificar autorização no banco, não apenas esconder URL.

## 2. Prioridades obrigatórias

### P0 — Segurança antes de pedidos reais
1. Implementar checkout transacional no servidor/Edge Function.
2. Recalcular preço, adicionais, desconto, taxa, pedido mínimo e total a partir do catálogo do banco.
3. Confirmar disponibilidade e estoque no servidor; impedir compra de item indisponível.
4. Garantir isolamento multi-tenant com RLS para todas as tabelas e operações.
5. Validar transições de status e restringir campos alteráveis por cada papel.
6. Criar idempotência para impedir pedido duplicado por clique/reenvio.
7. Não registrar segredos ou dados pessoais desnecessários em logs.
8. Resolver os alertas do Security Advisor, incluindo tabelas legadas, depois de identificar se ainda são usadas.
9. Configurar Auth: URLs de redirecionamento, política de senha e proteção contra senhas comprometidas quando disponível no plano.
10. Definir rotina de backup/exportação e procedimento de restauração.

### P1 — Operação essencial
1. Aplicar e validar a migração de atribuições de entrega após revisão.
2. Implementar atribuição de entregador no painel autorizado.
3. Completar estados do pedido e histórico de eventos.
4. Testar cliente, dono, cozinha e entregador com contas distintas.
5. Criar tratamento consistente de carregamento, erro, vazio, sessão expirada e perda de conexão.

### P2 — Crescimento comercial
1. Cupons e combos com regras validadas no servidor.
2. Favoritos e repetir pedido.
3. Relatórios e exportação.
4. Mensagens pré-preenchidas para WhatsApp e links por loja.
5. Fidelidade com saldo calculado no servidor e proteção contra abuso.

### P3 — Extras opcionais
1. PWA e notificações compatíveis.
2. Impressão térmica.
3. Integração oficial de WhatsApp automatizado.
4. Gateway de pagamento e webhooks verificados.
5. Mapas e rotas.

Cada extra deve ser avaliado quanto a preço, limites, privacidade e manutenção antes de ser ativado.

## 3. Critérios de aceite por lançamento

- Um usuário sem vínculo não acessa dados da loja.
- Usuários da Loja A não leem nem alteram dados da Loja B.
- Cliente não altera status, valor, taxa ou propriedade de pedidos pelo navegador.
- Reenvio do checkout não cria pedido duplicado.
- Pedido não fica parcialmente gravado quando uma etapa falha.
- Produtos indisponíveis e lojas suspensas não aceitam pedidos.
- O entregador vê somente entregas atribuídas a ele.
- Ações críticas de administrador ficam registradas.
- Erros são exibidos sem expor SQL, tokens ou informações privadas.
- Todas as telas são testadas em Android e desktop.
- O Security Advisor é revisado depois das mudanças de banco.

## 4. Regras de arquitetura

- Banco central compartilhado com isolamento por `store_id` e RLS.
- A chave publicável pode estar no frontend; `service_role` nunca.
- Operações privilegiadas e validação de preço ficam no servidor.
- Administração central fora das pastas públicas dos clientes.
- Migrações versionadas, revisadas e aplicadas separadamente.
- Nenhuma migração destrutiva sem backup e confirmação explícita.
- Sem dependência obrigatória de serviços pagos para o fluxo básico.

## 5. Estado conhecido deste pacote

Implementação existente no pacote: interface do cliente, painel de dono, painel de cozinha, painel de entregas, administração central privada, documentação e migrações de referência.

Pendências conhecidas: checkout seguro/transacional; revisão e aplicação da migração de entregas; fluxo visual para atribuir entregadores; estoque avançado, cupons, fidelidade, gateway de pagamento, impressão térmica, notificações push e integração oficial de WhatsApp. Estes itens são planejamento, não funcionalidades prontas.

## Atualização do banco — 11/10/2026

A migração `20261011_professional_modules_foundation` foi aplicada ao projeto Supabase Central existente. Ela adiciona os papéis `kitchen` e `delivery`, atribuições de entregas com RLS, tabelas-base para cupons, favoritos, pontos de fidelidade e auditoria. A migração é aditiva e não apaga dados existentes.

**Limite importante:** criar as tabelas não equivale a concluir toda a funcionalidade. O checkout seguro existente valida produtos, preços, taxa e pedido mínimo no servidor, mas ainda não aplica cupons nem credita pontos automaticamente. As telas precisam ser conectadas e testadas com as novas tabelas antes de anunciar esses recursos como ativos. A atribuição de entregadores também exige uma ação administrativa autenticada.
