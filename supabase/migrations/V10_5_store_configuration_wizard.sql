-- V10.5 — configuração guiada da loja (migração aditiva)
-- Faça backup/exportação antes de executar. Não apaga nem reescreve pedidos antigos.
-- O assistente armazena campos de funcionamento, aparência, pagamentos, categorias,
-- grupos de opções, combos e cupons no JSONB saas_stores.settings existente.
-- Produtos continuam em saas_products, com store_id e políticas RLS existentes.

DO $$
BEGIN
  IF to_regclass('public.saas_stores') IS NULL THEN
    RAISE EXCEPTION 'A tabela public.saas_stores não existe. Execute primeiro a migração SaaS V10 após revisar o estado atual.';
  END IF;
  IF to_regclass('public.saas_products') IS NULL THEN
    RAISE EXCEPTION 'A tabela public.saas_products não existe. Não é seguro continuar sem revisar a migração SaaS V10.';
  END IF;
END $$;

ALTER TABLE public.saas_stores
  ADD COLUMN IF NOT EXISTS settings jsonb NOT NULL DEFAULT '{}'::jsonb;
ALTER TABLE public.saas_stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saas_products ENABLE ROW LEVEL SECURITY;
CREATE INDEX IF NOT EXISTS saas_stores_settings_gin_idx
  ON public.saas_stores USING gin (settings jsonb_path_ops);
CREATE INDEX IF NOT EXISTS saas_products_store_category_idx
  ON public.saas_products (store_id, category, sort_order);

-- Confirme as políticas de owner/member já definidas em V10. Esta migração não
-- cria políticas permissivas novas e não desabilita políticas existentes.
NOTIFY pgrst, 'reload schema';
