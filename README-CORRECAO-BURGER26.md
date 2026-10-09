# Correção de diagnóstico — Burger26

Esta atualização melhora a mensagem de erro do painel: quando o reparo automático falha, a tela agora exibe o erro real retornado pelo Supabase em vez de apenas repetir que a migration 2.2 precisa ser executada.

## Aplicação
1. Faça backup/exportação do banco antes de qualquer alteração.
2. Publique os arquivos desta pasta no Netlify, substituindo os arquivos da versão anterior.
3. Abra `supabase/DIAGNOSTICO-BURGER26.sql` no SQL Editor do Supabase e execute as consultas de leitura.
4. Confira o erro real exibido no painel e compare com os resultados SQL.
5. Não execute novamente scripts que recriem organização/loja nem apague registros. A correção definitiva depende de identificar o vínculo exato.

O SQL de diagnóstico é somente leitura. Este ZIP não altera o banco remoto nem publica automaticamente no Netlify.
