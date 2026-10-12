# Como distribuir o Pedidos Pro

## ZIP de desenvolvimento (este arquivo)
Contém as áreas públicas, a administração privada, documentação e SQL de referência.

## ZIP para o lojista
Distribua somente a área do cliente e, quando necessário, o painel do dono/operador. Não envie `private-central-admin/`, scripts de administração central ou informações internas.

## Hospedagem
- Cliente: publicar `public/client/` em HTTPS.
- Dono: publicar `public/owner/` em HTTPS; pode usar domínio separado.
- Cozinha: publicar `public/kitchen/` em HTTPS.
- Entregador: publicar `public/delivery/` em HTTPS.
- Administração central: host privado/restrito, autenticação e autorização; nunca publicar no mesmo diretório público.

As quatro interfaces públicas usam a chave publishable do projeto e dependem de políticas RLS. Chave publishable não substitui políticas de segurança.
