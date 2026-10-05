# Sistema de Pedidos — Admin Gerador V3

Sistema profissional e configurável de cardápio digital + pedidos pelo WhatsApp, com painel administrativo multi-loja, contas de clientes e Central de Pedidos/Clientes integrada ao Supabase.

## Arquitetura

- **Cliente:** HTML + CSS + JavaScript puro.
- **Configuração:** `config/loja.js`.
- **Conta do cliente:** Supabase Auth + Database.
- **Central administrativa:** IndexedDB para cadastro das lojas + Supabase Auth/RLS para operação.
- **Pedidos:** WhatsApp + histórico opcional no Supabase.
- **PWA:** `manifest.webmanifest` + `sw.js` para cache básico do aplicativo.
- **Exportação:** o Admin gera um ZIP somente com os arquivos necessários para o cliente.

## Estrutura principal

```text
index.html
manifest.webmanifest
sw.js
config/loja.js
css/app.css
js/app.js
js/supabase.js
assets/
admin/
  admin.html
  admin.css
  admin.js
  central.js
  app-files.js
supabase/
  schema.sql
  admin-central.sql
scripts/
  admin-bundle.js
  meta.js
  meta-tags.js
```

A pasta `design/` contém apenas materiais de referência. Ela não é usada pelo site publicado e não entra no ZIP de cliente.

## Configuração da loja

Edite somente `config/loja.js` quando quiser configurar uma loja diretamente.

Campos principais:

- identidade, slug, logo e favicon
- WhatsApp e endereço
- cores e layout
- horários por dia, inclusive madrugada
- fechamento manual
- entrega/retirada, taxas e pedido mínimo
- formas de pagamento
- cupons
- banner e SEO
- Meta Pixel / Google Analytics opcionais
- Supabase Auth/Database
- grupos de opções
- produtos e combos

### Supabase no cliente

Use somente a **Publishable key** (`sb_publishable_...`) no navegador. Nunca coloque `service_role` ou secret key em `config/loja.js`.

```js
supabase: {
  enabled: true,
  url: "https://SEU-PROJETO.supabase.co",
  publishableKey: "sb_publishable_..."
}
```

## Banco Supabase

Execute `supabase/schema.sql` no projeto Supabase da loja.

O schema inclui:

- `profiles`
- `customer_addresses`
- `orders`
- `order_items`
- `store_admins`
- RLS para clientes
- RLS por loja para administradores
- validação de status e valores monetários
- atualização automática de `updated_at`
- Realtime para `orders`
- índices principais

Depois, rode os **Security Advisors** do Supabase e corrija qualquer aviso específico do projeto.

### Primeiro administrador

1. Crie a conta em **Authentication > Users** ou pelo cadastro da Central.
2. Confirme o e-mail se a política do projeto exigir.
3. Execute `supabase/admin-central.sql` substituindo o e-mail e o slug da loja.
4. Entre na Central.

O cadastro não concede privilégio administrativo automaticamente.

## Central administrativa

Abra:

```text
http://localhost:5500/admin/admin.html
```

Módulos:

- 🏪 Lojas
- 🛒 Pedidos
- 👥 Clientes
- Login/cadastro administrativo
- recuperação de senha
- filtros e busca
- detalhes do pedido
- alteração de status
- atualização em tempo real quando o Realtime estiver habilitado
- atualização automática de fallback
- exportação individual da loja
- duplicação, importação e backup

O acesso aos pedidos é controlado por `store_admins` + RLS. O navegador nunca recebe `service_role`.

## Conta do cliente

Na loja publicada:

- cadastro
- login
- logout
- recuperação de senha
- perfil
- telefone/WhatsApp
- endereços salvos
- histórico dos pedidos
- associação do pedido ao usuário autenticado

## Pedidos

Fluxos suportados:

- carrinho
- checkout
- entrega ou retirada
- pedido mínimo
- taxa de entrega
- cupom percentual/fixo
- pagamento
- troco com máscara monetária
- horário aberto/fechado
- pedido agendado quando fechado manualmente
- mensagem estruturada para WhatsApp
- gravação opcional no histórico do cliente
- status operacional na Central

Status previstos:

`whatsapp_pending`, `received`, `confirmed`, `preparing`, `ready`, `out_for_delivery`, `completed`, `cancelled`.

## PWA

O cliente exportado recebe:

- `manifest.webmanifest`
- `sw.js`
- ícones PWA

O Service Worker faz cache básico dos arquivos locais. Dados do Supabase continuam dependendo de rede.

## Rodar localmente

Na raiz do projeto:

```powershell
python -m http.server 5500
```

Depois:

```text
http://localhost:5500/
http://localhost:5500/admin/admin.html
```

Também existem:

- `iniciar-servidor.bat`
- `iniciar-servidor.command`

## Exportar uma loja

1. Abra o Admin.
2. Entre em **🏪 Lojas**.
3. Crie ou selecione uma loja.
4. Configure produtos, horários, pagamentos, SEO e Supabase.
5. Corrija as pendências da validação.
6. Use **Exportar ZIP**.
7. Publique o ZIP/pasta gerado no Vercel ou outro host estático.

O ZIP do cliente não inclui o painel administrativo, `design/`, SQL ou ferramentas internas.


## Segurança

- Publishable/anon key somente no cliente.
- `service_role` não é usado no front-end.
- RLS habilitado nas tabelas expostas.
- Pedidos do cliente limitados ao próprio usuário.
- Pedidos da Central limitados às lojas presentes em `store_admins`.
- Cadastro administrativo não concede acesso sozinho.
- Dados de autorização não dependem de `user_metadata` para RLS.

## Checklist V3

- [x] JavaScript puro no cliente
- [x] Supabase Auth
- [x] Cadastro/login cliente
- [x] Cadastro/login administrativo
- [x] Recuperação de senha
- [x] Multi-loja no Admin
- [x] Central de Pedidos
- [x] Central de Clientes
- [x] RLS por usuário e loja
- [x] Realtime de pedidos
- [x] PWA básico
- [x] Exportação cliente-only
- [x] SEO configurável
- [x] Meta Pixel opcional
- [x] Google Analytics opcional
- [x] Combos e grupos
- [x] Horários com virada de madrugada
- [x] Fechamento manual
- [x] Cupons
- [x] Máscara de troco
- [x] Backup/importação do Admin
- [x] Validação de sintaxe

## Observação sobre credenciais

A configuração presente neste pacote usa uma Publishable key pública do Supabase. Isso é apropriado para um front-end Supabase, desde que as políticas RLS estejam corretas. Não compartilhe ou coloque uma `service_role`/secret key neste projeto.


## V5 — Cliente Avançado

A experiência do cliente foi evoluída para uma jornada de delivery mais próxima de aplicativo: favoritos, navegação inferior, conta, endereços, histórico e **acompanhamento visual do pedido**.

### Acompanhamento em tempo real
Quando o cliente está autenticado e o pedido foi salvo no Supabase, a tela de pedido acompanha alterações de status via Realtime. O cliente pode visualizar a linha do tempo:

`Recebido → Confirmado → Preparando → Pronto → Saiu para entrega → Concluído`

Para retirada, a etapa de entrega não é exibida. Cancelamentos aparecem como estado final.


## V6 — Cliente Pro

Atualização focada na experiência do consumidor:
- produtos vistos recentemente;
- compartilhamento do cardápio usando Web Share API com fallback para copiar link;
- convite de instalação do PWA quando o navegador disponibilizar o prompt;
- navegação e conta do cliente preservadas;
- favoritos, histórico e rastreamento Supabase preservados.

Os dados de vistos recentemente e favoritos são locais no navegador. Pedidos, conta, endereços e rastreamento continuam dependentes do Supabase configurado para a loja.


## V7 — Vercel + domínio próprio

O cliente está preparado para publicação estática na Vercel. O `vercel.json` não usa build command nem depende de scripts internos, então o ZIP exportado pelo Admin pode ser publicado diretamente.

### Publicação Vercel
- Framework Preset: Other
- Build Command: vazio
- Output Directory: `.`
- Install Command: vazio
- `index.html` deve ficar na raiz publicada.

### Atalho do painel
A rota `/admin` é reescrita para `/admin/admin.html`. A rota completa continua funcionando normalmente.

### Domínio próprio
Para cada loja, publique o ZIP exportado e conecte o domínio em **Vercel → Project → Settings → Domains**. Exemplos:
- `brasaburger.com.br`
- `www.brasaburger.com.br`

Depois de apontar o DNS para a Vercel, atualize no Admin o campo **URL do site** para o domínio definitivo e exporte novamente para que canonical, Open Graph, compartilhamento e QR Code usem o endereço correto.

### Arquitetura multi-loja
O Admin continua sendo o gerenciador central de várias lojas. Cada exportação é independente e pode usar seu próprio domínio e seu próprio projeto Supabase. Isso evita compartilhar dados de clientes entre lojas e mantém o isolamento por projeto/RLS.

### Importante
Domínio personalizado é configurado na Vercel/DNS; não é necessário criar uma API ou servidor para isso. A `publishableKey` do Supabase continua sendo a única chave permitida no frontend.


## V7.1 — estrutura de configuração

O arquivo **`config/loja.js` é obrigatório** e fica na raiz do projeto em `config/loja.js`.

Estrutura mínima:

```text
index.html
config/
  loja.js
css/
js/
assets/
admin/
supabase/
vercel.json
manifest.webmanifest
sw.js
```

No GitHub, confirme com `git status` e `git ls-files config/loja.js`. Se o segundo comando não retornar `config/loja.js`, execute `git add config/loja.js` antes do commit.

Para Vercel, a URL padrão configurada para a loja é `https://{slug}.vercel.app`; se houver domínio próprio, preencha `seo.url` no `config/loja.js`.


## V8 — Sistema completo, segurança e operação

A V8 consolida cliente, conta, pedidos, Admin Gerador e Central em uma base única.

- Criação de pedidos autenticados com RPC transacional (`create_customer_order`), evitando pedido salvo sem seus itens quando a migração V8 estiver aplicada.
- RLS reforçado: o cliente não precisa de permissão para editar pedidos depois da criação.
- Índices adicionais para operação por loja, status e cliente.
- Validação e mensagens de conta mais amigáveis, sem exibir detalhes técnicos do Supabase ao cliente.
- Indicador de conexão offline no cardápio.
- Service Worker atualizado para a geração V8, evitando cache antigo após nova publicação.
- Área do Cliente, rastreamento, favoritos, pedidos, endereços, perfil e segurança preservados.
- Admin Gerador + Central multi-lojas, Realtime, filtros, métricas e exportação CSV preservados.

### Migração Supabase V8

Execute o arquivo `supabase/schema.sql` no projeto Supabase da loja. A seção V8 é idempotente para a estrutura criada pelo sistema. Depois da migração, o cliente passa a usar a função transacional para registrar pedido + itens.

## V7.3 — Vercel + Netlify (sem marca d’água)

Esta versão é compatível com **Vercel e Netlify**. As duas plataformas são apenas opções de hospedagem: o cliente final não recebe badge, marca d’água ou branding visual de nenhuma delas.

### Vercel
- `vercel.json` incluído.
- `/admin` direciona para `/admin/admin.html`.
- PWA e Service Worker com cache-control adequado.

### Netlify
- `netlify.toml` incluído.
- Publicação estática com `publish = "."`.
- `/admin` direciona para `/admin/admin.html`.
- Service Worker sem cache e manifest com MIME correto.

### Exportação por loja
O Admin Gerador inclui no ZIP da loja: `config/loja.js`, `vercel.json` e `netlify.toml`, além dos arquivos do cliente. Assim, o mesmo ZIP pode ser publicado em qualquer uma das duas plataformas sem editar o código.

### Branding
Não existe badge, rodapé, watermark ou anúncio de Vercel/Netlify no frontend. O domínio mostrado ao cliente é definido pelo campo `seo.url`/URL da loja.

## Importante — badge "Powered by Netlify"

Se a loja for publicada na Netlify e aparecer um selo **Powered by Netlify** no canto inferior direito, isso **não vem do código deste projeto**. A Netlify injeta esse badge no servidor para determinados projetos/planos. Para uma loja de cliente, desative no painel da Netlify em **Project configuration → General → Powered by Netlify badge**. A alteração passa a valer no próximo acesso, sem precisar alterar ou reenviar o código.

O projeto continua compatível com Netlify e Vercel e não adiciona nenhum badge próprio.

## Central de Operações — versão avançada

A Central do Admin Gerador foi atualizada com:

- Visão geral operacional por loja.
- Indicadores de pedidos, faturamento, pedidos em aberto e clientes.
- Filtros de período: hoje, 7 dias, 30 dias e todo o período.
- Pedidos em tempo real via Supabase Realtime, quando habilitado.
- Fallback de atualização automática a cada 60 segundos.
- Busca por pedido, cliente, telefone, endereço e pagamento.
- Filtros por status.
- Detalhamento do pedido e itens.
- Atualização do status do pedido com RLS.
- Base de clientes derivada dos pedidos.
- Exportação CSV da operação.
- Indicador de saúde da conexão da loja.
- Login, cadastro, recuperação de senha e logout administrativos.
- Multi-lojas com troca de loja no próprio painel.

A Central continua sem `service_role` no navegador. O acesso depende de Supabase Auth + `public.store_admins` + políticas RLS.

## Área do Cliente — conta atualizada
- edição de nome, WhatsApp e e-mail;
- troca de senha;
- confirmação de e-mail quando o Supabase exigir;
- máscara de WhatsApp no formulário;
- resumo de pedidos, gastos e endereços;
- atualização manual da conta e logout seguro.


## V8.1 — Área Dev

A Central recebeu uma área **🧑‍💻 Dev** para diagnóstico seguro do ambiente. Ela mostra versão, configuração da loja, estado do Supabase, PWA, IndexedDB e compatibilidade de deploy sem exibir chaves privadas ou `service_role`. Também permite copiar um diagnóstico sanitizado para suporte técnico.
