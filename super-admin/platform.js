window.PLATFORM = {
  name: "Sistema de Pedidos WhatsApp",
  version: "2.0.0",
  contact: "rojonas71@gmail.com",
  supabase: {
    url: window.LOJA?.supabase?.url || "",
    publishableKey: window.LOJA?.supabase?.publishableKey || ""
  }
};
