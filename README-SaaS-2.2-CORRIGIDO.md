# Sistema de Pedidos — SaaS 2.2 Corrigido

## Correções principais

Esta versão corrige o fluxo em que o painel dizia:

> Sua conta ainda não possui uma empresa.

mesmo quando o contexto de onboarding estava incompleto ou a VIEW antiga não conseguia retornar os dados.

### Novo fluxo seguro

`Cadastro → Auth → create_owner_company() → organization → OWNER → store → settings → appearance → painel`

### Leitura do painel

O painel agora usa:

- `get_my_business_context()` — RPC `SECURITY DEFINER`;
- fallback para `my_business_context` para compatibilidade;
- `repair_my_company()` para registros antigos que possuem organização/OWNER, mas ficaram sem `store`.

### Aparência 2.0

Incluído:

- logo;
- favicon;
- capa;
- cores;
- tema claro/escuro/automático;
- estilo dos botões;
- pré-visualização;
- Supabase Storage `store-assets`;
- tabela `store_appearance`;
- endpoint público de aparência por slug.

## IMPORTANTE — Supabase

No projeto correto, execute **uma vez**:

1. `supabase/saas-v2-schema.sql`
2. `supabase/saas-v2-onboarding.sql`

Se o banco já possui a versão anterior, o arquivo usa `CREATE OR REPLACE` para as funções e cria a camada nova de aparência. Antes de produção, faça backup e revise migrations em um ambiente de staging.

O navegador usa somente a Publishable/anon key. Nunca coloque `service_role` ou Access Token do Mercado Pago no frontend.

## URLs

- `/cadastro/`
- `/entrar/`
- `/painel/`
- `/aparencia/`

## O que ainda depende do ambiente

A aplicação não consegue executar uma migration no seu projeto Supabase automaticamente a partir de um ZIP. Portanto, a atualização do banco precisa ser aplicada no SQL Editor do projeto Supabase que está em `config/loja.js`.

Depois da migration:

`Cadastro → Criar minha hamburgueria → Abrir meu painel`

deve funcionar com o OWNER vinculado ao tenant.
