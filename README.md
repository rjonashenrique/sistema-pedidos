# Cardápio com pedido pelo WhatsApp

Site estático, sem banco de dados e sem instalação. O cliente monta o pedido e ele chega pronto no WhatsApp da loja.

## Admin: cadastrar e exportar cada loja (jeito recomendado)

O admin é uma ferramenta só sua. Roda no seu computador (nada vai para a internet), sem login, e guarda tudo no navegador.

**Abrir:** inicie o servidor local (abaixo) e acesse **http://localhost:5500/admin/admin.html** no **Google Chrome**. Precisa de internet só para as bibliotecas de ZIP e QR Code.

### Servidor local (porta 5500)

Na raiz do projeto, abra o Terminal/PowerShell e rode exatamente:

```bash
python -m http.server 5500
```

- **App:** http://localhost:5500/
- **Admin:** http://localhost:5500/admin/admin.html
- Para desligar: `Ctrl+C`.
- Use sempre `http://localhost:5500`; IndexedDB fica associado ao endereço e à porta.
- O admin precisa de internet para carregar JSZip e QR Code pelo cdnjs. O site exportado não depende dessas bibliotecas.


**Cadastrar um cliente**
- **Nova loja** começa do zero. **Duplicar** copia uma loja pronta: é só trocar nome, logo, cores e WhatsApp.
- **Importar loja.js** traz uma loja que já existe. Escolha a pasta do site para vir junto com as fotos.
- Preencha as seções do menu à esquerda. Tudo salva sozinho, e o celular à direita mostra o cardápio real enquanto você edita. Use "Aberta"/"Fechada" para ver os dois estados.
- As fotos são reduzidas e convertidas para WebP na hora. A imagem de compartilhamento sai em JPG 1200x630.

**Exportar e publicar**
1. Clique em **Revisar e exportar**. Erros (em vermelho) bloqueiam; avisos (em amarelo) só alertam.
2. **Exportar site** baixa `nome-do-link.zip`, já com as meta tags gravadas. Não precisa rodar nenhum comando.
3. Descompacte e arraste a pasta em **app.netlify.com/drop**.
4. No Netlify, em **Site configuration → Change site name**, use o nome que o admin mostra na tela. Se estiver ocupado, troque na seção **Link** e exporte de novo.
5. Baixe o **QR Code** em PNG para balcão, embalagem e Instagram.

**Backup:** os dados ficam só neste navegador. Clique em **Exportar backup** de vez em quando (o admin avisa depois de 7 dias sem backup). O arquivo `.json` vai para a pasta **Downloads**; guarde uma cópia no Google Drive ou num pendrive. **Importar backup** restaura tudo, com imagens, em qualquer computador.

> Se você mudar o app (`index.html`, `css/` ou `js/`), rode `node scripts/admin-bundle.js` para o admin usar a versão nova.

## Sem o admin: editando à mão

### Nova hamburgueria em 3 passos

**1. Duplique a pasta** do projeto e dê o nome do cliente.

**2. Edite só o `config/loja.js`.** Tudo que muda de uma loja para outra está nele, com comentários:

| O que | Campo |
|---|---|
| Nome, nome do link, endereço, WhatsApp (só dígitos, com 55 + DDD) | `nome`, `slug`, `endereco`, `whatsapp` |
| Logo e ícone da aba | `logo`, `favicon` (vazio = iniciais na cor da marca) |
| Cores | `cores.principal`, `cores.secundaria` (tom escuro), `cores.escuro` |
| Visual | `layout` (`"lista"` ou `"grade"`), `mostrarBanner`, `banner` |
| Horário por dia | `horarios` — ex.: `sex: ["18:00-01:00"]`. `[]` = fechado. Pode ter mais de um turno: `["11:00-14:00", "18:00-23:00"]` |
| Fechar num feriado ou imprevisto | `fechadoManual: true` (os pedidos viram agendados). Volte para `false` depois |
| Entrega | `tempoEntrega`, `tempoRetirada`, `taxaEntrega`, `pedidoMinimo` |
| Pagamento e cupons | `pagamentos`, `cupons` |
| Cardápio | `produtos` e `grupos` (ponto da carne, adicionais, remover, sabores…) |
| Combos | produto com `tipo: "combo"` e `itens` — o preço cheio riscado é calculado sozinho |
| Prévia do link no WhatsApp/Instagram (título, descrição, imagem) | `seo`. O endereço do site vem de `seo.url` ou, se vazio, do `urlPadrao` (`https://{slug}.netlify.app`) |
| Rastreamento opcional | `tracking.metaPixel`, `tracking.googleAnalytics` — vazios = não carregam nada |

**3. Troque as imagens** em `assets/`:

- `assets/produtos/` — fotos dos produtos, de preferência **quadradas, em WebP, com cerca de 720px**
- `assets/banner.webp` — banner da home (cerca de 960×320)
- `assets/compartilhar.jpg` — prévia do link no WhatsApp/Instagram, **1200×630 em JPG**
- logo (opcional): coloque em `assets/` e aponte em `logo`

> ⚠️ **As imagens atuais são de demonstração** (banco de imagens gratuito). Troque sempre pelas fotos reais da hamburgueria antes de publicar.

Para converter uma foto para WebP: `cwebp -q 70 -resize 720 0 foto.jpg -o assets/produtos/nome.webp`, ou use o site squoosh.app.

### Publicar no Netlify Drop

1. **Mudou nome, descrição, imagem de compartilhamento ou endereço na config?** Rode `node scripts/meta.js` na pasta do projeto. Isso grava essas informações no `index.html`, que é de onde o WhatsApp lê a prévia do link (o Netlify Drop não roda esse passo sozinho).
2. Crie uma pasta nova só com o que vai para o ar: `index.html`, `css/`, `js/`, `config/` e `assets/`. As pastas `design/` e `scripts/` e os outros arquivos ficam de fora.
3. Abra **app.netlify.com/drop**, entre na sua conta e arraste essa pasta.
4. O Netlify cria um endereço aleatório. Vá em **Site configuration → Change site name** e use o mesmo `slug` da config (ex.: `brasa-burger`), para o site ficar em `https://brasa-burger.netlify.app`, o endereço que está gravado nas meta tags.
5. Para atualizar depois: no painel do site, aba **Deploys**, arraste a pasta de novo.

**Testar a prévia do link:** cole o endereço em **developers.facebook.com/tools/debug** e clique em "Scrape Again" (confere a imagem e o título, e renova o cache de WhatsApp e Instagram). Depois mande o link numa conversa do WhatsApp. O WhatsApp guarda a prévia em cache; para ver uma versão nova, envie com `?v=2` no final.

**Para testar no computador:** inicie o servidor local (veja "Servidor local" acima) e abra `http://localhost:5500`.

## Estrutura

```
index.html        página
iniciar-servidor.command   dois cliques = servidor local na porta 5500
config/loja.js    ← único arquivo a editar por cliente (ou o admin gera)
assets/           imagens
css/ js/          app (não precisa mexer)
admin/            admin gerador (nunca vai para o site do cliente)
scripts/          meta tags e cópia do app para o admin (nunca vai para o site)
design/           arquivos originais do Claude Design (só referência, o site não usa)
```

## Conta do cliente — Supabase Auth

O cardápio agora pode oferecer **Entrar na sua conta** e **Cadastre-se** diretamente no site.

Recursos incluídos:

- cadastro com nome, WhatsApp, e-mail e senha;
- login por e-mail e senha;
- recuperação de senha por e-mail;
- sessão persistente no navegador;
- perfil do cliente;
- endereços salvos;
- histórico dos pedidos enviados pelo cardápio;
- RLS para cada cliente acessar somente os próprios dados.

### 1. Criar/configurar o Supabase

Crie um projeto no Supabase e abra **SQL Editor → New Query**.

Execute todo o arquivo:

```text
supabase/schema.sql
```

O SQL cria `profiles`, `customer_addresses`, `orders` e `order_items`, o trigger de perfil e as políticas RLS.

### 2. Configurar a loja

No `config/loja.js`, preencha somente a URL pública e a **Publishable key / anon key**:

```js
supabase: {
  enabled: true,
  url: "https://SEU-PROJETO.supabase.co",
  publishableKey: "sb_publishable_..."
}
```

**Nunca coloque `service_role` ou uma secret key no navegador.**

### 3. Confirmar e-mails

Se o projeto exigir confirmação de e-mail, o cliente receberá o link configurado pelo Supabase. Cadastros com confirmação obrigatória só poderão entrar depois da confirmação.

### 4. Admin Generator

A seção **Compartilhamento → Conta do cliente · Supabase Auth** permite salvar essas três configurações e exportá-las no `config/loja.js` do cliente.

O arquivo `supabase/schema.sql` fica no projeto de desenvolvimento e **não é incluído no ZIP público do cliente**.

### 5. Pedido + histórico

O cliente continua podendo enviar o pedido pelo WhatsApp. Quando estiver autenticado, o pedido também é salvo em `orders` e seus itens em `order_items`, ficando disponível em **Minha conta → Meus pedidos**.

## Central de Pedidos e Clientes

O Admin Gerador agora possui uma **Central** opcional para operação das lojas conectadas ao Supabase:

- **Pedidos:** busca, filtro por status, métricas, detalhe, itens e atualização de status.
- **Clientes:** consolidação dos clientes a partir dos pedidos da loja, com quantidade de pedidos, total e último pedido.
- **Multi-loja:** selecione a loja no próprio painel; cada consulta usa o projeto Supabase configurado naquela loja.
- **Segurança:** a central usa somente a Publishable key e Supabase Auth. Não coloque `service_role` no navegador.
- **RLS:** o acesso administrativo é controlado pela tabela `public.store_admins`.

### Ativar a Central

1. Na loja, mantenha **Supabase ativo** em `config/loja.js`.
2. Execute `supabase/schema.sql` no projeto Supabase da loja.
3. Crie uma conta administrativa em **Authentication → Users**.
4. Ajuste e execute `supabase/admin-central.sql`, trocando `SEU_EMAIL` e o slug da loja.
5. Abra `admin/admin.html`, clique em **🛒 Pedidos** ou **👥 Clientes** e entre com essa conta.

A Central é administrativa e **não é incluída no ZIP público exportado para o cliente**.

## Cadastro administrativo da Central

A Central agora possui **Entrar** e **Criar cadastro**.

O cadastro usa Supabase Auth (`signUp`) e grava apenas o nome como `user_metadata`. Ele **não cria automaticamente** uma permissão em `public.store_admins`.

Após confirmar o e-mail, um responsável deve vincular o usuário à loja:

```sql
insert into public.store_admins (user_id, store_slug, role)
select id, 'brasa-burger', 'owner'
from auth.users
where email = 'SEU_EMAIL'
on conflict (user_id, store_slug) do update
set role = excluded.role;
```

Troque `brasa-burger` pelo slug da loja. O painel usa RLS para permitir somente os pedidos da loja autorizada.
