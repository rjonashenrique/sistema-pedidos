# V10.5 — Assistente profissional de configuração da loja

## O que foi adicionado
- Rota `/configuracao/?store=UUID` com 12 etapas: dados, link, aparência, funcionamento, entrega/retirada, pagamentos, categorias, produtos, grupos de opções, combos, cupons e compartilhamento/revisão.
- Salvamento dos campos da loja em `saas_stores.settings` (JSONB), mantendo produtos em `saas_products`.
- Controles para ativar/desativar produtos, adicionar produtos, validar campos, pré-visualizar link, copiar link, gerar QR Code e exportar configuração JSON.
- Atalho “Configurar loja · 12 etapas” nos cartões da plataforma.
- Migração aditiva `supabase/migrations/V10_5_store_configuration_wizard.sql`.

## Instalação segura
1. Faça backup/exportação do banco atual e preserve a pasta/cópia da versão em produção.
2. Confirme que a migração SaaS V10 já foi aplicada e que `public.saas_stores` e `public.saas_products` existem. Se não existirem, **não execute V10.5 isoladamente**; primeiro diagnostique a migração V10 e o estado atual.
3. No Supabase SQL Editor do projeto correto, revise e execute `supabase/migrations/V10_5_store_configuration_wizard.sql`.
4. Confirme que RLS continua habilitada e que as políticas de proprietário/membro da migração V10 estão ativas. Não use `service_role` no navegador.
5. Publique os arquivos estáticos do ZIP mantendo a estrutura de pastas. `config/saas.js` deve conter somente a URL do projeto e a chave publishable/anon pública.
6. Entre em `/plataforma/`, autentique-se, abra o cartão da loja e clique em “Configurar loja · 12 etapas”.
7. Teste com uma conta proprietária e, separadamente, com uma conta que não pertença à loja. A segunda não deve conseguir ler nem alterar os dados privados.

## Compatibilidade e limites importantes
- Não remove, migra nem modifica registros de pedidos antigos.
- Categorias, horários, opções, combos e cupons são guardados em `settings` como configuração; este pacote não altera automaticamente o renderizador público do cardápio para aplicar todas essas regras. A integração visual dessas estruturas no checkout público é uma etapa adicional.
- O QR Code é carregado do serviço externo `api.qrserver.com`, usando apenas a URL pública do cardápio.
- O link gerado é do domínio atual (`/loja/?slug=...`). Subdomínios `slug.dominio` requerem DNS e roteamento explícitos na hospedagem.
- Não execute migrações de novo às cegas se a instalação anterior estiver parcialmente aplicada. Verifique as tabelas e políticas primeiro.

## Verificações recomendadas após instalar
- Criar e salvar configuração de uma loja de teste.
- Confirmar que as alterações permanecem após sair e entrar novamente.
- Tentar acessar o UUID da loja com outro usuário e confirmar bloqueio por RLS.
- Confirmar que pedidos anteriores permanecem no banco.
- Abrir o link público e verificar produtos e WhatsApp; recursos de opções/combos/cupons só estarão operacionais no público quando integrados ao checkout.
