(function(){
'use strict';
var cfg=(window.LOJA&&window.LOJA.supabase)||{}, client=window.supabase&&cfg.enabled&&cfg.url&&cfg.publishableKey?window.supabase.createClient(cfg.url,cfg.publishableKey,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}}):null;
var app=document.getElementById('app'), context=null, appearance=null;

function esc(v){return String(v==null?'':v).replace(/[&<>'"]/g,function(c){return {'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#39;','"':'&quot;'}[c]})}
function err(t){app.innerHTML='<div class="wrap"><div class="error"><b>'+esc(t)+'</b><p><a href="../painel/">Voltar ao painel</a></p></div></div>'}
async function getContext(){
  var r=await client.rpc('get_my_business_context');
  if(r.error) throw r.error;
  var rows=Array.isArray(r.data)?r.data:[];
  if(!rows.length) throw new Error('Sua conta ainda não possui uma empresa.');
  return rows[0];
}
function value(k,d){return appearance&&appearance[k]!=null?appearance[k]:d}
function colorField(name,label,def){
 return '<div class="field"><label>'+label+'</label><div class="color"><input id="'+name+'" type="color" value="'+esc(value(name,def))+'"><input data-color-text="'+name+'" value="'+esc(value(name,def))+'" maxlength="7"></div></div>';
}
function render(){
 var a=appearance||{};
 app.innerHTML='<div class="wrap">'+
 '<div class="top"><div><a href="../painel/">← Voltar ao painel</a><h1>Aparência</h1><p>Personalize a identidade visual da sua hamburgueria.</p></div></div>'+
 '<div class="grid"><section class="card">'+
 '<div class="section"><h2>Identidade visual</h2><p>Logo, favicon e capa da loja.</p>'+
 '<div class="field"><label>Logo</label><input id="logoFile" type="file" accept="image/png,image/jpeg,image/webp,image/svg+xml"></div>'+
 '<div class="field"><label>Favicon</label><input id="faviconFile" type="file" accept="image/png,image/jpeg,image/webp,image/x-icon"></div>'+
 '<div class="field"><label>Capa / banner principal</label><input id="coverFile" type="file" accept="image/png,image/jpeg,image/webp"></div></div>'+
 '<div class="section"><h2>Cores</h2><div class="row">'+
 colorField('primary_color','Cor principal','#E8590C')+colorField('secondary_color','Cor secundária','#1C1917')+
 '</div><h3>Tema claro</h3><div class="row">'+
 colorField('light_background','Fundo','#FFFFFF')+colorField('light_surface','Superfície','#F8FAFC')+
 colorField('light_card','Cards','#FFFFFF')+colorField('light_text','Texto','#111827')+
 '</div><h3>Tema escuro</h3><div class="row">'+
 colorField('dark_background','Fundo','#0B0B0C')+colorField('dark_surface','Superfície','#171719')+
 colorField('dark_card','Cards','#1F1F22')+colorField('dark_text','Texto','#FFFFFF')+
 '</div></div>'+
 '<div class="section"><h2>Tema e botões</h2><div class="row">'+
 '<div class="field"><label>Tema padrão</label><select id="theme"><option value="system">Automático</option><option value="light">Claro</option><option value="dark">Escuro</option></select></div>'+
 '<div class="field"><label>Formato do botão</label><select id="button_style"><option value="square">Quadrado</option><option value="rounded">Arredondado</option><option value="pill">Pill</option></select></div>'+
 '<div class="field"><label>Estilo do botão</label><select id="button_variant"><option value="solid">Sólido</option><option value="outline">Outline</option><option value="gradient">Gradiente</option></select></div>'+
 '<div class="field"><label>Raio das bordas</label><input id="border_radius" type="number" min="0" max="32" value="'+esc(value('border_radius',14))+'"></div>'+
 '</div></div>'+
 '<div class="section"><div class="actions"><button id="save" class="btn">Salvar alterações</button><button id="reset" class="btn secondary">Restaurar padrão</button></div><p id="status"></p></div>'+
 '</section><aside class="card preview"><h2>Pré-visualização</h2><p>Exemplo do cardápio público.</p><div id="phone" class="phone"><div id="cover" class="cover"></div><div class="brand"><div id="logoPreview"></div><b>'+esc(context.store_name||context.organization_name)+'</b><span>Cardápio online</span></div><div class="chips"><span class="chip">Hambúrgueres</span><span class="chip">Combos</span><span class="chip">Bebidas</span></div><div class="product"><div><b>X-Bacon</b><br><small>Hambúrguer artesanal</small><br><strong id="price">R$ 29,90</strong></div><button id="addPreview">ADICIONAR</button></div></div></aside></div></div>';
 document.getElementById('theme').value=value('theme','system');
 document.getElementById('button_style').value=value('button_style','rounded');
 document.getElementById('button_variant').value=value('button_variant','solid');
 bindColors(); applyPreview(); bindUpload('logoFile','logo_url'); bindUpload('faviconFile','favicon_url'); bindUpload('coverFile','cover_url');
 document.getElementById('save').onclick=save; document.getElementById('reset').onclick=reset;
}
function bindColors(){
 document.querySelectorAll('input[type=color]').forEach(function(c){c.oninput=function(){var t=document.querySelector('[data-color-text="'+c.id+'"]');if(t)t.value=c.value;applyPreview()}})
 document.querySelectorAll('[data-color-text]').forEach(function(t){t.oninput=function(){var c=document.getElementById(t.getAttribute('data-color-text'));if(/^#[0-9a-fA-F]{6}$/.test(t.value))c.value=t.value;applyPreview()}})
}
function read(){var keys=['primary_color','secondary_color','light_background','light_surface','light_card','light_text','dark_background','dark_surface','dark_card','dark_text'];var a={};keys.forEach(function(k){a[k]=document.getElementById(k).value});a.theme=document.getElementById('theme').value;a.button_style=document.getElementById('button_style').value;a.button_variant=document.getElementById('button_variant').value;a.border_radius=Math.max(0,Math.min(32,Number(document.getElementById('border_radius').value)||14));a.store_id=context.store_id;return a}
function applyPreview(){
 var a=read(), dark=a.theme==='dark'||(a.theme==='system'&&window.matchMedia&&window.matchMedia('(prefers-color-scheme: dark)').matches);
 var bg=dark?a.dark_background:a.light_background, surface=dark?a.dark_surface:a.light_surface, card=dark?a.dark_card:a.light_card, text=dark?a.dark_text:a.light_text;
 var phone=document.getElementById('phone'); if(!phone)return;
 phone.style.background=bg; phone.style.color=text;
 document.getElementById('cover').style.backgroundImage=appearance&&appearance.cover_url?'url("'+appearance.cover_url+'")':'none';
 var lp=document.getElementById('logoPreview'); lp.innerHTML=appearance&&appearance.logo_url?'<img src="'+esc(appearance.logo_url)+'" alt="Logo">':'<div style="width:76px;height:76px;border-radius:20px;background:'+a.primary_color+';color:#fff;margin:-38px auto 0;display:grid;place-items:center;font-weight:900;font-size:24px">🍔</div>';
 var b=document.getElementById('addPreview'); b.style.background=a.button_variant==='outline'?'transparent':a.primary_color;b.style.color=a.button_variant==='outline'?a.primary_color:'#fff';b.style.border=a.button_variant==='outline'?'2px solid '+a.primary_color:'0';b.style.borderRadius=(a.button_style==='pill'?999:a.button_style==='square'?4:a.border_radius)+'px';
 document.querySelector('.brand').style.background=surface; document.querySelectorAll('.chip').forEach(function(x){x.style.background=a.secondary_color;x.style.color='#fff'});
 document.getElementById('price').style.color=a.primary_color;
}
async function upload(file,key){
 if(!file)return;
 var ext=(file.name.split('.').pop()||'bin').toLowerCase().replace(/[^a-z0-9]/g,'');var path=context.store_id+'/'+key+'-'+Date.now()+'.'+ext;
 var r=await client.storage.from('store-assets').upload(path,file,{upsert:true,contentType:file.type});
 if(r.error)throw r.error;
 var pub=client.storage.from('store-assets').getPublicUrl(path);
 appearance[key]=pub.data.publicUrl;
}
function bindUpload(id,key){var el=document.getElementById(id);el.onchange=async function(){var s=document.getElementById('status');try{await upload(el.files[0],key);s.className='success';s.textContent='Imagem carregada. Clique em Salvar alterações.';render()}catch(e){s.className='error';s.textContent='Não foi possível enviar a imagem: '+e.message}}}
async function save(){
 var s=document.getElementById('status');var b=document.getElementById('save');b.disabled=true;
 try{var a=read();var r=await client.from('store_appearance').upsert(a,{onConflict:'store_id'}).select('*').single();if(r.error)throw r.error;appearance=r.data;s.className='success';s.textContent='Alterações salvas com sucesso!';applyPreview()}catch(e){s.className='error';s.textContent='Erro ao salvar: '+e.message}finally{b.disabled=false}
}
async function reset(){if(!confirm('Restaurar a aparência padrão desta loja?'))return;appearance={store_id:context.store_id};render();await save()}
async function run(){
 if(!client){err('Supabase não configurado.');return}
 var s=await client.auth.getSession();if(!s.data||!s.data.session){location.href='../entrar/';return}
 try{context=await getContext();var r=await client.from('store_appearance').select('*').eq('store_id',context.store_id).maybeSingle();if(r.error)throw r.error;appearance=r.data||{store_id:context.store_id};render()}catch(e){err(e.message||'Não foi possível carregar a aparência.')}
}
run();
})();