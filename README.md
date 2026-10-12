# Pedidos Pro — pacote ZIP completo

Solução multi-loja com áreas separadas para cliente, dono/operador, cozinha, entregas e administração central privada, usando o projeto Supabase existente.

## Pastas
- `pedidos-pro-completo/public/client/` — cliente.
- `pedidos-pro-completo/public/owner/` — dono/operador.
- `pedidos-pro-completo/public/kitchen/` — cozinha.
- `pedidos-pro-completo/public/delivery/` — entregador.
- `pedidos-pro-completo/private-central-admin/` — administração central privada.
- `pedidos-pro-completo/supabase/` — histórico e migrações SQL.
- `pedidos-pro-completo/docs/` — implantação e testes.

Leia primeiro `pedidos-pro-completo/docs/ARQUITETURA-E-IMPLANTACAO.md`, `pedidos-pro-completo/docs/ROADMAP-PROFISSIONAL-AVANCADO.md` e `pedidos-pro-completo/supabase/README-MIGRACOES.md`. O roadmap separa o que já existe do que ainda precisa ser implementado.

**Segredos:** os arquivos de configuração incluem somente URL do projeto e chave publishable. Nunca coloque `service_role` em frontend. O pacote não inclui senhas, tokens privados ou dump de dados de clientes.

**Status:** pacote de implementação avançada, não certificado para produção. O checkout ainda precisa de validação transacional no servidor. A migração de entregas está incluída para revisão e aplicação separada; este ZIP não afirma que ela foi aplicada no Supabase.

## Atualização profissional de 11/10/2026
O banco Supabase Central já recebeu a migração aditiva de módulos profissionais: atribuição de entregadores e base de dados para cupons, favoritos, fidelidade e auditoria. Veja `docs/ROADMAP-PROFISSIONAL-AVANCADO.md`. Os módulos que dependem de lógica de servidor e interface ainda precisam de integração e testes antes de produção; não considere cupons ou fidelidade ativos apenas pela existência das tabelas.
