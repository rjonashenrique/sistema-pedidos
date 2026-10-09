(function () {
  'use strict';

  var cfg = (window.LOJA && window.LOJA.supabase) || {};
  var client = window.supabase && cfg.enabled && cfg.url && cfg.publishableKey
    ? window.supabase.createClient(cfg.url, cfg.publishableKey, {
        auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
      })
    : null;

  var app = document.getElementById('app');

  function esc(v) {
    return String(v == null ? '' : v).replace(/[&<>'"]/g, function (c) {
      return {'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c];
    });
  }

  function errorBox(title, detail, actions) {
    app.innerHTML =
      '<div class="wrap">' +
        '<section class="panel">' +
          '<div class="error">' +
            '<h2>' + esc(title) + '</h2>' +
            '<p>' + esc(detail) + '</p>' +
            (actions || '') +
          '</div>' +
        '</section>' +
      '</div>';
  }

  // O link de cadastro usa caminho absoluto para funcionar mesmo quando
  // o painel é aberto por URLs com/sem barra final no Netlify.
  document.addEventListener('click', function (event) {
    var link = event.target && event.target.closest ? event.target.closest('.js-go-cadastro') : null;
    if (!link) return;
    event.preventDefault();
    window.location.assign('/cadastro/');
  });

  async function getContext() {
    // 1) Caminho principal: RPC SECURITY DEFINER.
    // Evita que uma alteração de RLS/View esconda uma empresa já criada.
    var rpc = await client.rpc('get_my_business_context');
    if (!rpc.error) return rpc.data || [];

    // 2) Compatibilidade com bancos que ainda possuem somente a VIEW 2.1.
    var view = await client.from('my_business_context').select('*');
    if (!view.error) return view.data || [];

    var msg = (rpc.error && rpc.error.message) || (view.error && view.error.message) || '';
    var code = (rpc.error && rpc.error.code) || (view.error && view.error.code) || '';
    var e = new Error(msg || 'Não foi possível carregar o contexto da empresa.');
    e.code = code;
    throw e;
  }

  async function run() {
    if (!client) {
      errorBox('Supabase não configurado', 'Verifique config/loja.js e use somente a Publishable Key.');
      return;
    }

    var session = await client.auth.getSession();
    if (!session.data || !session.data.session) {
      location.href = '../entrar/';
      return;
    }

    var context;
    try {
      context = await getContext();
    } catch (err) {
      var m = String(err.message || '');
      if (/does not exist|PGRST202|function .*get_my_business_context/i.test(m)) {
        errorBox(
          'Banco ainda não atualizado',
          'Execute no Supabase o arquivo supabase/saas-v2-onboarding.sql desta versão. Depois recarregue esta página.',
          '<p><a class="btn" href="/cadastro/" class="js-go-cadastro">Ir para criação da hamburgueria</a></p>'
        );
      } else {
        errorBox('Não foi possível carregar sua empresa', m, '<p><a class="btn" href="../">Voltar</a></p>');
      }
      return;
    }

    var rows = Array.isArray(context) ? context : [];
    if (!rows.length) {
      errorBox(
        'Sua conta ainda não possui uma empresa',
        'A conta está autenticada, mas não existe uma organização ativa vinculada a ela. Crie sua hamburgueria para liberar o painel.',
        '<p><a class="btn" href="/cadastro/" class="js-go-cadastro">🏪 Criar minha hamburgueria</a></p>'
      );
      return;
    }

    var c = rows[0];

    // Reparo automático idempotente: guarda o erro real para não mascarar
    // problemas de permissões, RPC ausente ou vínculo com papel incorreto.
    var repairError = null;
    if (!c.store_id) {
      var repair = await client.rpc('repair_my_company', { p_store_name: c.organization_name });
      if (repair.error) {
        repairError = repair.error.message || repair.error.details || 'A função de reparo não pôde ser executada.';
      } else {
        var repaired = await getContext();
        if (repaired.length) c = repaired[0];
      }
    }

    if (!c.store_id) {
      var detail = 'O vínculo da empresa existe, mas não há uma loja associada. Nenhum dado foi apagado.';
      if (repairError) detail += ' Diagnóstico do Supabase: ' + repairError + '. Abra o arquivo supabase/DIAGNOSTICO-BURGER26.sql e siga as instruções antes de alterar os dados.';
      else detail += ' A função de reparo não retornou uma loja. Confira supabase/saas-v2-onboarding.sql e o resultado do diagnóstico.';
      errorBox('Empresa encontrada, mas a loja está incompleta', detail, '<p><a class="btn" href="/painel/?retry=1">Tentar novamente</a></p>');
      return;
    }

    var orders = await client
      .from('orders_v2')
      .select('id,total,status,created_at', { count: 'exact', head: false })
      .eq('store_id', c.store_id)
      .order('created_at', { ascending: false })
      .limit(8);

    var count = orders.error ? 0 : (orders.count || 0);
    var total = orders.error ? 0 : (orders.data || []).reduce(function (a, x) {
      return a + Number(x.total || 0);
    }, 0);

    app.innerHTML =
      '<div class="wrap">' +
        '<header class="top">' +
          '<div class="brand">' +
            '<div class="logo">SP</div>' +
            '<div><b>Sistema de Pedidos</b><small>' + esc(c.organization_name) + '</small></div>' +
          '</div>' +
          '<button id="out" class="btn">Sair</button>' +
        '</header>' +
        '<section class="hero">' +
          '<h1>' + esc(c.store_name || c.organization_name) + '</h1>' +
          '<p>Você é o proprietário desta empresa. Este é o centro de controle do seu negócio.</p>' +
        '</section>' +
        '<section class="grid">' +
          '<div class="metric"><span>Status</span><strong>' + esc(c.organization_status) + '</strong></div>' +
          '<div class="metric"><span>Plano</span><strong>' + esc(c.plan_code || '—') + '</strong></div>' +
          '<div class="metric"><span>Pedidos recentes</span><strong>' + count + '</strong></div>' +
          '<div class="metric"><span>Faturamento consultado</span><strong>R$ ' + total.toFixed(2).replace('.', ',') + '</strong></div>' +
        '</section>' +
        '<div class="layout">' +
          '<section class="panel">' +
            '<h2>Administrar minha hamburgueria</h2>' +
            '<div class="actions">' +
              '<a href="../admin/admin.html">🍔 Cardápio e operação</a>' +
              '<a href="../">🛒 Ver cardápio público</a>' +
              '<a href="../aparencia/">🎨 Aparência e identidade visual</a><a href="../cadastro/">🏪 Configurar empresa</a>' +
            '</div>' +
          '</section>' +
          '<aside class="panel">' +
            '<h2>Próximos passos</h2>' +
            '<p class="notice">Cadastre produtos, configure WhatsApp, defina horários e personalize a aparência da sua loja.</p>' +
          '</aside>' +
        '</div>' +
      '</div>';

    document.getElementById('out').onclick = async function () {
      await client.auth.signOut();
      location.href = '../entrar/';
    };
  }

  run().catch(function (err) {
    errorBox('Erro inesperado', err.message || 'Tente novamente.');
  });
})();