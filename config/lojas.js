/* V9.3 — o cadastro de novas lojas é feito pelo aplicativo em /criar-loja/.
   O banco Supabase compartilhado armazena cada loja e separa os dados via RLS.
   Este arquivo mantém compatibilidade com a loja principal/área Dev antiga.
   Nunca coloque service_role ou secret key no frontend. */
(function () {
  'use strict';
  var atual = window.LOJA;
  window.LOJAS = [{ nome: atual.nome, slug: atual.slug, supabase: atual.supabase }];
})();
