// Edge Function — webhook Mercado Pago.
// Nunca confie no status enviado pelo navegador. Valide assinatura/identificador,
// consulte o pagamento no provedor e só então atualize payments_v2/orders_v2.
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
serve(async (req)=>{ if(req.method!=='POST') return new Response('Method Not Allowed',{status:405}); const payload=await req.json(); console.log('Webhook recebido', {type:payload?.type,id:payload?.data?.id}); return new Response(JSON.stringify({received:true}),{headers:{'content-type':'application/json'}}); });
