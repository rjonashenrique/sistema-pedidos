# Plano de retorno — V10 SaaS

## Regra principal
A migração V10 é aditiva e o frontend V9.x deve ser preservado como artefato de retorno. Não execute `DROP TABLE`, não apague dados legados e não substitua as tabelas `orders`, `order_items`, `profiles` ou `store_admins`.

## Se o frontend V10 falhar
1. Volte o deploy do site para o último artefato V9.x conhecido como funcional (Netlify/Vercel).
2. Não execute SQL de remoção para tentar corrigir o frontend.
3. Os objetos `saas_*` podem permanecer no banco sem serem usados pelo site V9.x; a migração não deve exigir que o frontend antigo os consulte.
4. Investigue os logs do navegador e do Supabase; corrija em homologação antes de publicar novamente.

## Se a migração SQL falhar
1. Não repita blocos isolados às cegas nem apague tabelas.
2. Salve a mensagem de erro e identifique qual comando falhou.
3. Como a migração pode ter concluído comandos anteriores dentro de uma transação ou não, confira o estado real usando `V10-POSTCHECK.sql` e o Table Editor.
4. Restaure backup somente com procedimento controlado e se houver alteração de dados confirmada. Restauração de banco pode sobrescrever alterações posteriores; peça ajuda técnica antes disso.

## Dados da Brasa Burger
- A migração não copia nem altera o histórico antigo de pedidos.
- A Brasa Burger só será vinculada à V10 se o usuário proprietário esperado existir no Auth, ou após vínculo manual confirmado.
- Produtos legados não são copiados automaticamente, pois o esquema real pode variar. A vitrine V10 mantém fallback para o cardápio estático enquanto não há produtos em `saas_products`.
- Não considere o histórico migrado até realizar reconciliação e comparar contagens e amostras autorizadas.
