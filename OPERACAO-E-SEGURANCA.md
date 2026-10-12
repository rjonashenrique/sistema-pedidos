# Operação e segurança — Pedidos Pro

## Checklist de primeira instalação
- [ ] Confirmar domínio HTTPS e URLs permitidas no Supabase Auth.
- [ ] Confirmar o UUID da conta do desenvolvedor em `pedidos_pro_developer_admins`.
- [ ] Criar uma loja ativa na administração central.
- [ ] Criar/vincular a conta Auth do dono por UUID; não aceitar UUID enviado por formulário público.
- [ ] Confirmar vínculo em `pedidos_pro_store_members` com papel `owner`.
- [ ] Testar login do dono, catálogo, configuração e mudança de status.
- [ ] Testar cliente A e cliente B, e duas lojas diferentes, para assegurar que não há leitura cruzada.
- [ ] Testar loja suspensa: catálogo público não deve mostrar seus dados.
- [ ] Confirmar que o pacote público não contém a pasta `private-central-admin` nem chaves secretas.
- [ ] Rever os avisos do Supabase Security Advisor antes do lançamento.

## Limitações conhecidas nesta versão
1. O checkout cria o pedido e depois os itens; se a segunda operação falhar, pode sobrar pedido sem itens.
2. Preços e total recebidos do navegador ainda precisam ser recalculados no servidor a partir de `pedidos_pro_store_products`.
3. O painel de relatórios mostra os pedidos recentes carregados (limite da consulta), não é um relatório contábil completo.
4. CSV exporta somente os pedidos carregados na sessão do painel.
5. O WhatsApp abre uma conversa; o usuário precisa confirmar o envio. Não é integração oficial automatizada.
6. Imagens são URLs informadas pelo dono; não há upload de arquivo integrado.
7. Não há integração de cartão/PIX, emissão fiscal, impressão térmica, notificações push nem controle de estoque por quantidade.

## Alertas conhecidos no projeto Supabase
A última consulta do Security Advisor ainda reportou as tabelas antigas `public.pedidos_stores` e `public.pedidos_store_licenses` com RLS habilitada e sem políticas. Também reportou a proteção de senha comprometida do Auth desativada. Essas tabelas legadas precisam ser inspecionadas e endurecidas sem quebrar integrações antigas; a opção de proteção contra senhas comprometidas deve ser habilitada no painel Auth, conforme política do projeto.

Referência Supabase para proteção de senha: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection
Referência RLS: https://supabase.com/docs/guides/database/postgres/row-level-security

## Nunca fazer
- Não colocar `service_role` em `config.js`, HTML, repositório ou ZIP público.
- Não permitir que donos criem o próprio vínculo ou se promovam a administrador.
- Não confiar em preços/totais enviados pelo navegador.
- Não publicar o painel central no mesmo diretório público do cardápio.
