# Pedidos Pro — frontend público

Frontend estático em HTML, CSS e JavaScript puro. A pasta pública não inclui o gerador/admin.

## Configuração
1. Edite `config.js`:
   - `storeSlug`: deve corresponder a `pedidos_pro_stores.store_slug` no Supabase Central.
   - `whatsapp`: DDI + DDD + número, somente dígitos (ex.: `5517999999999`).
   - `products`: substitua os exemplos pelos produtos reais e preços.
   - `deliveryFee`: taxa da loja.
2. A URL Supabase e a publishable key estão preenchidas. A chave publicável pode estar no navegador; a segurança depende de RLS. **Nunca** adicione `service_role` ou segredo administrativo ao frontend.
3. No Supabase Auth, configure os URLs permitidos para o domínio de publicação. O cadastro pode exigir confirmação de e-mail.
4. Publique a pasta como site estático HTTPS (Netlify, GitHub Pages ou host equivalente).

## Como funciona
- Login/cadastro com Supabase Auth.
- Histórico e status consultados em `pedidos_pro_orders`.
- Pedido e itens são gravados antes de abrir `wa.me`.
- O WhatsApp abre com o resumo para o cliente confirmar o envio. O navegador não consegue confirmar que a mensagem foi enviada.
- `?loja=slug-da-loja` permite indicar uma loja sem editar `storeSlug`.

## Importante: estágio atual
Este pacote é um frontend inicial integrado às tabelas criadas. Os produtos ainda são exemplos locais e devem ser substituídos. A criação do pedido e dos itens usa duas operações, portanto para uso em produção recomenda-se uma Edge Function transacional que valide catálogo, preços, taxa e totais no servidor. O painel de loja/operadores, atribuição segura de membros, notificações Realtime e testes de isolamento entre contas ainda precisam ser concluídos antes de produção.

## Publicação sem admin
Publique apenas os arquivos desta pasta. Não copie a pasta `admin/` nem o ZIP do gerador para o diretório público.
