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
7. Publique o ZIP/pasta gerado no Netlify, Vercel ou outro host estático.

O ZIP do cliente não inclui o painel administrativo, `design/`, SQL ou ferramentas internas.

## Publicação no Netlify

O `netlify.toml` já está preparado para publicação estática. A pasta publicada precisa conter `index.html` na raiz.

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

### Publicação Netlify
O `index.html` está na raiz do projeto. Para deploy manual, envie **o conteúdo desta pasta**, não uma pasta pai adicional. Como é um site estático, não há build command.

- Publish directory: `.`
- Build command: vazio
- Página cliente: `/`
- Painel: `/admin/admin.html`

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
