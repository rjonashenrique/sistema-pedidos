# Checklist de validação

## Autenticação e perfis
- [ ] Cliente consegue criar conta, entrar, sair e consultar apenas seus próprios pedidos.
- [ ] Dono sem vínculo não consegue abrir o painel de nenhuma loja.
- [ ] Dono da Loja A não consegue consultar produtos, configurações, pedidos ou equipe da Loja B.
- [ ] Operador recebe somente as permissões que foram definidas para seu papel.
- [ ] Administrador central é conferido pela tabela `pedidos_pro_developer_admins`; usuário comum não acessa a área privada.
- [ ] Entregador consulta somente as atribuições feitas ao seu UUID Auth.

## Pedido
- [ ] Loja suspensa não aceita novos pedidos.
- [ ] Produto indisponível não pode ser comprado.
- [ ] Preço, adicionais, taxa, desconto, pedido mínimo e total são recalculados no servidor antes da confirmação.
- [ ] Falha ao gravar itens não deixa pedido incompleto (usar transação/Edge Function).
- [ ] Transições de status inválidas são recusadas e registradas.
- [ ] Dados de endereço e telefone só são acessíveis aos papéis necessários.

## Operação
- [ ] Testar desktop, Android e telas pequenas.
- [ ] Testar internet lenta, falha de rede e sessão expirada.
- [ ] Conferir links HTTPS, URLs de Auth e redirecionamento.
- [ ] Conferir backups e procedimento de restauração.
- [ ] Revisar o Supabase Security Advisor depois de cada migração.
- [ ] Não publicar `private-central-admin/` no diretório público.

## Testes adicionais dos módulos profissionais
- [ ] Confirmar que usuário com papel `delivery` só vê pedidos atribuídos a ele.
- [ ] Confirmar que somente `owner`/`operator` atribuem entregas.
- [ ] Confirmar que usuários comuns não conseguem inserir ou alterar cupons e pontos.
- [ ] Validar regras de cupom no servidor antes de habilitar descontos no checkout.
- [ ] Creditar pontos apenas após status de pedido considerado elegível e impedir duplicidade.
- [ ] Gravar auditoria por operações confiáveis no servidor; clientes não podem inserir logs arbitrários.
