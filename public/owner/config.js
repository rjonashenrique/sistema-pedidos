/* Configure por loja. Nunca coloque service_role neste arquivo. */
window.PEDIDOS_PRO_CONFIG = {
  supabaseUrl: "https://pdvmvyzykuwdjmosmqrb.supabase.co",
  supabasePublishableKey: "sb_publishable_5LM0zW7sMpxdnJwYRXwJ2g_-zQHjmrk",
  // Preencha o slug da loja cadastrada no Pedidos Pro Central.
  storeSlug: "minha-loja",
  // Número com DDI/DDD, somente dígitos. Ex.: 5517999999999
  whatsapp: "",
  // Produtos de exemplo: substitua pelos itens reais da loja.
  products: [
    {id:"classic",category:"Hambúrgueres",name:"Classic Burger",description:"Pão brioche, hambúrguer artesanal, queijo e molho da casa.",price:24.90,emoji:"🍔"},
    {id:"bacon",category:"Hambúrgueres",name:"Bacon Burger",description:"Hambúrguer artesanal, queijo cheddar e bacon crocante.",price:29.90,emoji:"🥓"},
    {id:"fries",category:"Acompanhamentos",name:"Batata frita",description:"Porção crocante para acompanhar.",price:12.00,emoji:"🍟"},
    {id:"soda",category:"Bebidas",name:"Refrigerante lata",description:"Lata 350 ml.",price:6.00,emoji:"🥤"}
  ],
  deliveryFee: 0
};