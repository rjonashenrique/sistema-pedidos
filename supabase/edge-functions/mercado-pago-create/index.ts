// Edge Function — Mercado Pago — criação segura de pagamento.
// Configure MP_ACCESS_TOKEN no ambiente da Edge Function, nunca no frontend.
// Esta função é um template de produção: valide o pedido no banco antes de criar a cobrança.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
serve(async (req) => {
  if(req.method !== 'POST') return new Response('Method Not Allowed',{status:405});
  const token=Deno.env.get('MP_ACCESS_TOKEN');
  if(!token) return new Response(JSON.stringify({error:'Pagamento não configurado'}),{status:503,headers:{'content-type':'application/json'}});
  const body=await req.json();
  // TODO: buscar o pedido pelo ID usando cliente Supabase server-side,
  // conferir store_id, total e usuário; só então chamar o Mercado Pago.
  return new Response(JSON.stringify({ok:false,message:'Configure a validação do pedido e o endpoint Mercado Pago antes de produção.'}),{status:501,headers:{'content-type':'application/json'}});
});
