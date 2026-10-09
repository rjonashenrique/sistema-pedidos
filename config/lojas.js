/* Catálogo público de configurações por loja — usado pela Área Dev e pelos links /dono/.
   Cadastre cada loja neste arquivo antes de entregar seu link individual.
   Use somente a Publishable/anon key pública; nunca coloque service_role/secret key aqui.
   Cada loja pode usar um projeto Supabase diferente.
*/
(function () {
  'use strict';
  var atual = window.LOJA;
  window.LOJAS = [
    { nome: atual.nome, slug: atual.slug, supabase: atual.supabase }

    /* EXEMPLO PARA ADICIONAR OUTRA LOJA (remova os comentários e ajuste os dados):
    ,{
      nome: 'Hamburgueria Exemplo',
      slug: 'hamburgueria-exemplo',
      supabase: {
        enabled: true,
        url: 'https://SEU-PROJETO.supabase.co',
        publishableKey: 'sb_publishable_SUA_CHAVE_PUBLICA'
      }
    }
    */
  ];
})();
