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

## V8.4 — Operação Profissional
- Dashboard executivo com ticket médio, taxa de conclusão e clientes identificados.
- Desempenho de faturamento por dia e clientes de maior valor.
- Indicador da última sincronização com Supabase.
- Central responsiva para desktop e mobile.
- Sem Área Dev na interface administrativa.


## V8.5 — Área do Dev e acesso à conta

- Adicionada a seção **Área do Dev** à navegação da Central, com diagnóstico operacional básico, estado de conexão, loja ativa, host, Supabase, sessão e Realtime.
- Adicionado resumo técnico seguro para copiar, sem exibir chaves ou dados de clientes.
- O cabeçalho da loja apresenta o botão **Entrar na sua conta** de forma explícita.
- A Área do Dev é uma ferramenta de suporte; não substitui as políticas RLS nem a validação de permissões no Supabase.

## V8.6 — Área do Dono

A Central inclui a seção **👑 Área do Dono**, com visão executiva da loja, métricas de pedidos, valor bruto, pedidos não cancelados, ticket médio, cancelamentos, pedidos em andamento e ações rápidas para Pedidos/Clientes/CSV.

O acesso visual é condicionado ao papel `owner` da tabela `public.store_admins` para o usuário autenticado e o `store_slug` selecionado. Para vincular um proprietário, use a instrução em `supabase/admin-central.sql` e mantenha a política RLS ativa. Os valores são indicadores operacionais baseados nos pedidos carregados (até 1.000); não representam lucro líquido, pois não descontam custos, taxas e despesas.

## V8.7 — links privados individuais por loja

- A Central aceita `admin/admin.html?loja=SLUG` e fixa a loja escolhida pelo link.
- A Área do Dono mostra o link individual e permite copiá-lo.
- O login usa Supabase Auth; a conta precisa estar vinculada ao slug em `public.store_admins`.
- Contas sem vínculo são bloqueadas antes de carregar pedidos/clientes.
- O navegador não pode criar ou editar vínculos administrativos; somente um administrador do banco deve provisioná-los.
- O arquivo `supabase/seguranca-links-privados.sql` endurece grants e políticas para evitar INSERT direto e restringe UPDATE de pedidos a `status` e `updated_at`.

### Ativação obrigatória no Supabase

1. Faça backup do banco.
2. Se ainda não aplicou o esquema inicial, execute primeiro `supabase/schema.sql`.
3. Execute `supabase/seguranca-links-privados.sql` no SQL Editor do projeto correto.
4. Crie/confirme a conta de cada proprietário em **Authentication → Users**.
5. Execute o exemplo de vínculo no final do SQL, usando o e-mail e o `store_slug` corretos para cada dono.
6. Entregue o link `https://SEU-DOMINIO/admin/admin.html?loja=SLUG` ao proprietário.
7. Teste com duas contas diferentes e confirme que uma não consegue abrir a loja da outra.

**Importante:** o link não é uma senha e não substitui o RLS. O slug identifica a loja; a sessão autenticada e a linha em `store_admins` determinam a autorização. O SQL incluído no ZIP precisa ser aplicado ao projeto Supabase antes de considerar a proteção ativa no banco.

## V8.8 — Área do Desenvolvedor privada em `/dev/`

- Rota dedicada `/dev/` com página própria e `noindex/nofollow`.
- Login por Supabase Auth, com e-mail autorizado `rojonas71@gmail.com` pré-preenchido.
- A Área do Desenvolvedor não carrega pedidos nem dados de clientes e não depende do papel `owner` da loja.
- A rota separa o diagnóstico técnico da Central operacional dos proprietários.
- A área não oferece cadastro; a recuperação de senha usa o fluxo de Supabase Auth.
- O código não contém `service_role` nem concede privilégios no banco. O e-mail permitido é uma barreira de interface para esta página de diagnóstico, não substitui RLS nem deve ser usado como autorização para operações privilegiadas no backend.
- Netlify redireciona `/dev` para `/dev/`; Vercel usa o diretório `dev/index.html` e o redirecionamento canônico.

Link após publicar: `https://SEU-DOMINIO/dev/`.

## V8.9 — Rota dedicada `/dev/admin/admin.html`

- Página da Área do Desenvolvedor disponível em `dev/admin/admin.html`.
- A Central reconhece esse caminho como modo Dev e mantém o login restrito ao e-mail autorizado `rojonas71@gmail.com`.
- Os caminhos relativos de CSS, configuração da loja e script central foram ajustados para a página aninhada.
- Netlify e Vercel incluem rota curta `/dev/admin` para a página dedicada.
- A restrição por e-mail no frontend não substitui autorização server-side/RLS para operações privilegiadas.


## V9.0 — Área do Dono com link dedicado por loja

- Criada a rota privada `/dono/`, separada da Central e da Área Dev.
- Links individuais no formato `https://SEU-DOMINIO/dono/?loja=SLUG`.
- O cartão “Link privado do proprietário” agora sempre gera o endereço `/dono/` com o slug da loja atual.
- A página dedicada exige slug no link, autenticação Supabase Auth e papel `owner` em `public.store_admins` para aquele `store_slug`.
- A Área do Dono não oferece cadastro; recuperação de senha continua disponível.
- Netlify/Vercel configurados para a rota `/dono/`.
- A URL não é um mecanismo de autorização: manter RLS ativo e criar os vínculos de cada dono pelo processo administrativo seguro.

Link de exemplo após publicar: `https://SEU-DOMINIO/dono/?loja=brasa-burger`.

## V9.1 — Área do Desenvolvedor multi-lojas

- A Área Dev lista as lojas cadastradas no IndexedDB do navegador atual e inclui a configuração pública carregada em `config/loja.js`.
- O botão **Testar todas** valida campos básicos de cada cadastro e tenta consultar o endpoint de saúde do Supabase Auth.
- O botão **Como corrigir** explica os problemas detectados e os próximos passos recomendados.
- O diagnóstico não consulta pedidos nem clientes, não concede privilégios no banco e não substitui a verificação de `public.store_admins` e RLS.
- **Importante:** o catálogo é local ao navegador/domínio. Para aparecerem na lista, as lojas precisam estar cadastradas/importadas nesse navegador. A versão não descobre automaticamente lojas que estejam apenas em outro dispositivo ou em outro projeto Supabase.
- Para publicar, envie os arquivos atualizados ao repositório/hosting e publique manualmente. Nenhuma publicação ou alteração no Supabase é feita automaticamente por este ZIP.


## V9.2 — Configuração individual por proprietário

- `config/lojas.js` é o catálogo publicado das lojas que podem usar links individuais.
- Cada entrada define `nome`, `slug` e seu próprio bloco `supabase` (URL + Publishable key pública). Assim, lojas podem usar projetos Supabase diferentes.
- O link individual tem o formato `https://SEU-DOMINIO/dono/?loja=SLUG`. A Área Dev agora tem o botão **Copiar link do dono** por loja.
- O sistema não inventa mais uma loja copiando a configuração da Brasa Burger quando recebe um slug desconhecido. Slugs ausentes do catálogo exibem uma mensagem clara.
- Para adicionar uma loja: edite o exemplo em `config/lojas.js`, informe nome, slug único, URL e Publishable key pública; publique os arquivos; execute os SQLs necessários no projeto Supabase daquela loja e vincule o e-mail do proprietário ao slug correto em `public.store_admins`.
- O link não autoriza acesso sozinho: o login, papel `owner` e as políticas RLS continuam obrigatórios. Nunca use `service_role` no frontend.
- A configuração do catálogo é estática e pública; não é um cadastro global sincronizado por banco. Adicionar uma entrada exige republicar o site.

## V10 — Plataforma SaaS central multi-loja (migração planejada)

A V10 adiciona `/plataforma/` para criar conta, entrar, criar loja, editar dados, cadastrar produtos e copiar links públicos em `/loja/?slug=...`. O catálogo é armazenado no Supabase central, com `store_id` e RLS por associação do usuário. A Brasa Burger permanece configurada no legado; a migração para `saas_stores` é aditiva e está documentada em `MIGRACAO-V10.md`.

**Antes de substituir a V9.2:** faça backup, aplique `supabase/migrations/V10_saas_multiloja.sql` no projeto correto, configure o administrador da plataforma e execute os testes descritos no guia. Não há cobrança recorrente real integrada nesta versão; a tabela de assinaturas representa o estado interno/trial, não uma cobrança confirmada.

## V10.3 — criação administrativa de lojas para proprietários
A rota `/dev/` agora é um painel de administração SaaS: mostra as lojas e permite ao Dev criar uma loja, associando-a ao e-mail de uma conta que já existe no Supabase Auth. O proprietário precisa primeiro se cadastrar em `/plataforma/` e confirmar seu e-mail. O painel não cria senhas nem utiliza `service_role` no navegador.

Antes de usar a função de criação administrativa:
1. Faça backup do banco e execute primeiro a migração V10 original, caso ainda não tenha sido aplicada.
2. Cadastre a conta do desenvolvedor em `public.saas_platform_admins` usando o UUID correto de `auth.users`.
3. Execute `supabase/migrations/V10_3_dev_create_store_for_owner.sql` no SQL Editor do mesmo projeto Supabase central.
4. Cadastre o proprietário em `/plataforma/`, confirme o e-mail e só então crie a loja em `/dev/`.
5. Teste com duas contas e confirme que a RLS impede acesso cruzado antes de publicar para clientes.

A função cria a loja, associação `owner` e assinatura de teste de 7 dias em uma única transação. Ela não migra nem exclui os pedidos legados da Brasa Burger. Não execute em produção sem backup e validação da migração V10.

### Prévia de link por slug (V10.4)
Na Área Dev, o campo do slug sugere um endereço a partir do nome da loja e mostra a prévia `https://{slug}.netlify.app`. Esse formato é uma convenção de URL: cada subdomínio precisa existir/ser configurado na Netlify e a aplicação deve identificar a loja pelo hostname. Até isso estar configurado, use o link alternativo do domínio principal com `?slug=`.

## V10.5 — Assistente de configuração da loja
Acesse `/configuracao/?store=UUID` pelo atalho “Configurar loja · 12 etapas” no painel da plataforma. Veja `INSTALACAO-CONFIGURACAO-V10.5.md` e revise a migração aditiva `supabase/migrations/V10_5_store_configuration_wizard.sql` antes de executá-la. Não substitui a migração V10 nem altera pedidos antigos. Categorias, horários, grupos de opções, combos e cupons são salvos no JSONB; a aplicação dessas regras no checkout público requer integração adicional.
