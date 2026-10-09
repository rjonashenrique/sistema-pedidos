# V10 SaaS — migração segura e ativação

## Antes de começar

1. **Não substitua a V9.2 em produção ainda.** Mantenha o site atual e o Supabase antigo operando.
2. No projeto Supabase que será o central, faça backup/exportação do banco e registre a URL e a publishable key atuais.
3. Confirme que o projeto central escolhido é o projeto correto e que você tem acesso de administrador.
4. Teste primeiro em um projeto de desenvolvimento ou branch, se disponível. O arquivo `supabase/migrations/V10_saas_multiloja.sql` é aditivo: cria tabelas `saas_*` e funções próprias; não apaga `orders`, `order_items`, `profiles`, `store_admins` nem tabelas antigas.

## Ativação do banco

1. Abra o SQL Editor do projeto central e revise o arquivo `supabase/migrations/V10_saas_multiloja.sql`.
2. Execute a migração somente depois de confirmar o backup.
3. Se o usuário `rojonas71@gmail.com` existir em **Authentication → Users**, a migração tentará registrar a Brasa Burger com esse usuário como proprietário. Se não existir, a migração não inventa um usuário nem cria um proprietário fictício; faça o vínculo manualmente depois.
4. Confira em Table Editor: `saas_stores`, `saas_store_members`, `saas_products`, `saas_subscriptions` e `saas_platform_admins`.
5. Em Authentication, crie/entre com a conta do proprietário e teste o cadastro de uma loja de teste. Não use um slug real de cliente no teste.
6. Para liberar a área de administração da plataforma, depois que sua conta estiver confirmada, localize seu UUID em Authentication → Users e execute no SQL Editor substituindo `UUID-DA-SUA-CONTA`:

```sql
insert into public.saas_platform_admins(user_id)
values ('UUID-DA-SUA-CONTA'::uuid)
on conflict (user_id) do nothing;
```

Apenas o usuário incluído nessa tabela verá a visão administrativa. Não crie um formulário público para inserir administradores.

## Configuração do frontend

- `config/saas.js` aponta para o Supabase central e usa somente a chave publishable/anon pública.
- Nunca cole `service_role`, secret key ou senha de banco em HTML/JavaScript.
- A plataforma está em `/plataforma/`; a vitrine pública por slug está em `/loja/?slug=nome-da-loja`.
- A vitrine consulta `saas_stores` e `saas_products`. Produtos de cada loja ficam vinculados por `store_id` e protegidos por RLS.
- A Brasa Burger tem fallback temporário para o cardápio estático atual caso não haja produtos migrados para `saas_products`. Isso mantém o cardápio antigo visível enquanto a migração do cardápio é planejada.

## Testes antes de substituir o site

- Criar conta nova, confirmar e-mail se exigido, entrar e sair.
- Criar uma loja e confirmar que aparecem uma linha em `saas_stores`, outra em `saas_store_members` com papel `owner` e uma assinatura `trial`.
- Criar duas lojas com usuários diferentes. Cada usuário deve ver somente as próprias lojas no painel.
- Cadastrar produto na loja A e confirmar que a conta da loja B não consegue listar, alterar nem excluir esse produto.
- Abrir `/loja/?slug=slug-da-loja` em janela anônima e verificar que somente lojas ativas e produtos disponíveis são públicos.
- Testar slug duplicado, slug inválido, e-mail não confirmado, falha de rede e celular.
- Verificar Supabase Security Advisor após a migração e revisar as políticas RLS.
- Testar os pedidos da Brasa Burger, histórico antigo e painel V9.2 sem alterar as tabelas antigas.

## Limites desta versão

- O cadastro, autenticação, criação de loja, gestão básica de dados e produtos usam o Supabase quando a migração estiver aplicada.
- O fluxo de pedido da vitrine gera uma mensagem de WhatsApp; não grava ainda pedidos SaaS em uma tabela nova de pedidos multi-loja.
- Assinaturas e período de teste são registros internos. Cobrança recorrente real, webhooks, bloqueio automático por inadimplência, uploads de imagem, cupons, frete por região, adicionais e pedidos em tempo real precisam de implementação e teste separados antes de vender como recursos prontos.
- O registro da Brasa Burger na nova tabela não migra nem apaga o histórico de pedidos legado. A reconciliação de dados é uma etapa separada.

## Procedimento reforçado para o mesmo Supabase da Brasa Burger

1. Execute `supabase/V10-PRECHECK.sql` no projeto atual e guarde os resultados. Ele é somente leitura.
2. Faça exportação/backup antes de qualquer alteração e confirme que consegue localizar o backup.
3. Revise e execute `supabase/migrations/V10_saas_multiloja.sql` no SQL Editor do mesmo projeto. A migração é aditiva; não executa cópia automática do histórico legado.
4. Execute `supabase/V10-POSTCHECK.sql` e confirme que as tabelas novas têm RLS habilitado, que `brasa-burger` está vinculada ao proprietário correto e que as tabelas antigas continuam existindo.
5. Faça os testes de isolamento com duas contas diferentes antes de cadastrar clientes reais.
6. Se algo falhar, siga `supabase/V10-PLANO-RETORNO.md`: reverta o frontend primeiro e não apague tabelas `saas_*` como tentativa de correção.
7. Publique a V10 apenas depois dos testes. Mantenha o ZIP V9.x e o deploy anterior disponíveis até concluir a validação.
