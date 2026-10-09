# V10 SaaS — alterações

- Nova área de autenticação e criação de conta em `plataforma/`.
- Cadastro de loja pelo próprio aplicativo via RPC transacional `saas_create_store`.
- Painel básico do proprietário: lojas, edição de dados, cadastro/exclusão de produtos e link público.
- Vitrine pública genérica por slug em `loja/`, com carrinho local e finalização via WhatsApp.
- Esquema multi-loja aditivo com tabelas próprias `saas_*`, membership por usuário, planos/trial e RLS.
- Registro legado da Brasa Burger sem exclusão ou reescrita de tabelas antigas; fallback temporário para o cardápio estático existente.
- Guia de migração, checklist de testes e limites explicitados.

## Ainda não implementado/confirmado

- Migração real aplicada ao Supabase de produção.
- Migração de todos os produtos/pedidos históricos para tabelas SaaS novas.
- Gateway de pagamentos, cobrança recorrente e webhooks.
- Pedidos salvos na base SaaS e acompanhamento Realtime.
- Uploads Storage, domínios customizados e fluxos de convite de equipe.
- Teste E2E de navegador/produção.

## V10.1 — preparação de migração segura no projeto atual
- Incluídos SQLs de pré-checagem e pós-checagem somente leitura.
- Incluído plano de retorno que prioriza rollback do frontend sem apagar tabelas ou pedidos.
- Documentado que pedidos históricos e produtos legados não são migrados automaticamente.
- Reforçada a sequência de backup, validação RLS, teste de isolamento e publicação gradual.


## V10.2 — WhatsApp comercial e checkout avançado
- Checkout público aprimorado com entrega ou retirada, endereço, pagamento, telefone opcional, observações e troco.
- Mensagem do WhatsApp inclui produtos, subtotal, taxa e total.
- Configurações comerciais editáveis no painel do dono: taxa, mínimo, meios de pagamento e prazo estimado.
- Reutiliza o esquema V10 existente; sem migração destrutiva adicional.
- Limitação explícita: abre o WhatsApp para o cliente confirmar o envio; não automatiza mensagens ou pagamentos.
