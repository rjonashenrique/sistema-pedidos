/* Supabase Auth + dados do cliente. A chave publicada pode ficar no navegador;
   nunca coloque service_role/secret key neste arquivo ou em config/loja.js. */
(function () {
  'use strict';
  var cfg = (window.LOJA && window.LOJA.supabase) || {};
  var api = window.supabase;
  var client = null;
  if (api && cfg.enabled && cfg.url && cfg.publishableKey) {
    client = api.createClient(cfg.url, cfg.publishableKey, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
    });
  }

  function pronto() { return !!client; }
  function getClient() { return client; }
  async function session() {
    if (!client) return null;
    var r = await client.auth.getSession();
    return r.data && r.data.session ? r.data.session : null;
  }
  async function user() {
    if (!client) return null;
    var r = await client.auth.getUser();
    return r.data && r.data.user ? r.data.user : null;
  }
  async function signIn(email, password) {
    if (!client) throw new Error('Supabase ainda não foi configurado para esta loja.');
    var r = await client.auth.signInWithPassword({ email: email, password: password });
    if (r.error) throw r.error;
    return r.data;
  }
  async function signUp(email, password, data) {
    if (!client) throw new Error('Supabase ainda não foi configurado para esta loja.');
    var r = await client.auth.signUp({
      email: email,
      password: password,
      options: { data: data || {}, emailRedirectTo: location.href.split('#')[0] }
    });
    if (r.error) throw r.error;
    return r.data;
  }
  async function reset(email) {
    if (!client) throw new Error('Supabase ainda não foi configurado para esta loja.');
    var r = await client.auth.resetPasswordForEmail(email, { redirectTo: location.href.split('#')[0] });
    if (r.error) throw r.error;
  }
  async function signOut() {
    if (!client) return;
    var r = await client.auth.signOut();
    if (r.error) throw r.error;
  }
  async function profile() {
    var u = await user();
    if (!u || !client) return null;
    var r = await client.from('profiles').select('id,full_name,phone').eq('id', u.id).maybeSingle();
    if (r.error) throw r.error;
    return Object.assign({ id: u.id, email: u.email || '' }, r.data || {});
  }
  async function updateProfile(values) {
    var u = await user();
    if (!u || !client) throw new Error('Você precisa entrar na sua conta.');
    var r = await client.from('profiles').update({ full_name: values.full_name || null, phone: values.phone || null }).eq('id', u.id).select('id,full_name,phone').single();
    if (r.error) throw r.error;
    return Object.assign({ id: u.id, email: u.email || '' }, r.data);
  }
  async function addresses() {
    var r = await client.from('customer_addresses').select('*').order('is_default', { ascending: false }).order('created_at', { ascending: false });
    if (r.error) throw r.error;
    return r.data || [];
  }
  async function deleteAddress(id) {
    var r = await client.from('customer_addresses').delete().eq('id', id);
    if (r.error) throw r.error;
  }
  async function setDefaultAddress(id) {
    var u = await user();
    if (!u) throw new Error('Você precisa entrar na sua conta.');
    var clear = await client.from('customer_addresses').update({ is_default: false }).eq('user_id', u.id);
    if (clear.error) throw clear.error;
    var r = await client.from('customer_addresses').update({ is_default: true }).eq('id', id).eq('user_id', u.id);
    if (r.error) throw r.error;
  }
  async function updatePassword(password) {
    if (!client) throw new Error('Supabase ainda não foi configurado para esta loja.');
    var r = await client.auth.updateUser({ password: password });
    if (r.error) throw r.error;
  }
  async function orderItems(orderId) {
    var r = await client.from('order_items').select('id,product_id,product_name,quantity,unit_price,line_total,selections,observation').eq('order_id', orderId).order('created_at', { ascending: true });
    if (r.error) throw r.error;
    return r.data || [];
  }
  async function saveAddress(a) {
    var u = await user();
    if (!u) throw new Error('Você precisa entrar na sua conta.');
    var payload = {
      user_id: u.id,
      label: a.label || 'Principal',
      address_line: a.address_line || '',
      is_default: !!a.is_default
    };
    if (payload.is_default) await client.from('customer_addresses').update({ is_default: false }).eq('user_id', (await user()).id);
    var r = await client.from('customer_addresses').insert(payload).select('*').single();
    if (r.error) throw r.error;
    return r.data;
  }
  async function orders(limit) {
    var r = await client.from('orders').select('id,order_number,status,order_type,customer_name,delivery_address,payment_method,subtotal,delivery_fee,discount,total,notes,created_at').order('created_at', { ascending: false }).limit(limit || 20);
    if (r.error) throw r.error;
    return r.data || [];
  }
  async function createOrder(c, store) {
    var u = await user();
    if (!u || !client) return null;
    var orderNumber = String(Date.now()).slice(-8);
    var pr = await profile();
    var couponCode = null;
    if (c.cp && window.LOJA.cupons) { Object.keys(window.LOJA.cupons).some(function (k) { if (window.LOJA.cupons[k] && window.LOJA.cupons[k].tipo === c.cp.tipo && +window.LOJA.cupons[k].valor === +c.cp.valor) { couponCode = k; return true; } return false; }); }
    var payload = {
      user_id: u.id,
      store_slug: store.slug || null,
      order_number: orderNumber,
      status: 'whatsapp_pending',
      order_type: c.entrega ? 'delivery' : 'pickup',
      customer_name: c.f.nome.trim(),
      customer_phone: (c.f && c.f.telefone ? c.f.telefone : (pr && pr.phone ? pr.phone : '')),
      delivery_address: c.entrega ? c.f.endereco.trim() : null,
      payment_method: c.f.pagamento,
      subtotal: c.subtotal,
      delivery_fee: c.taxa,
      discount: c.desconto,
      total: c.total,
      coupon_code: couponCode,
      notes: c.f.obs.trim() || null,
      scheduled_for: c.st.aberto ? null : new Date().toISOString()
    };
    var r = await client.from('orders').insert(payload).select('id,order_number').single();
    if (r.error) throw r.error;
    var rows = c.itens.map(function (i) {
      return { order_id: r.data.id, product_id: i.p.id, product_name: i.p.nome, quantity: i.l.qty, unit_price: i.unitP, line_total: i.total, selections: i.l.sel || {}, observation: i.l.obs || null };
    });
    var ir = await client.from('order_items').insert(rows);
    if (ir.error) throw ir.error;
    return r.data;
  }
  function subscribeOrder(orderId, callback) {
    if (!client || !orderId) return function () {};
    var channel = client.channel('cliente-pedido-' + orderId)
      .on('postgres_changes', { event: 'UPDATE', schema: 'public', table: 'orders', filter: 'id=eq.' + orderId }, function (payload) {
        if (callback) callback(payload.new);
      }).subscribe();
    return function () { try { client.removeChannel(channel); } catch (e) {} };
  }
  function onAuth(callback) {
    if (!client) return function () {};
    var sub = client.auth.onAuthStateChange(function (event, sessionValue) { callback(event, sessionValue); });
    return function () { if (sub.data && sub.data.subscription) sub.data.subscription.unsubscribe(); };
  }
  window.AppSupabase = { pronto: pronto, getClient: getClient, session: session, user: user, signIn: signIn, signUp: signUp, reset: reset, signOut: signOut, profile: profile, updateProfile: updateProfile, updatePassword: updatePassword, addresses: addresses, saveAddress: saveAddress, deleteAddress: deleteAddress, setDefaultAddress: setDefaultAddress, orders: orders, orderItems: orderItems, createOrder: createOrder, subscribeOrder: subscribeOrder, onAuth: onAuth };
})();
