import http from 'node:http';

const port=Number(process.env.CSIM_IFRAME_PORT||18781);
// This page deliberately uses a different origin from Superset. It embeds the
// real application without rewriting responses, injecting links, or bypassing
// frame/session policy. Only the local regression harness is served here.
const html=`<!doctype html><html lang="en"><meta charset="utf-8"><title>CSiM iframe regression host</title>
<style>body{margin:0;font:16px system-ui;background:#f1f4f6}header{padding:16px 24px;background:#fff;border-bottom:1px solid #ccd4dc}iframe{display:block;width:calc(100% - 32px);height:calc(100vh - 96px);margin:16px;border:1px solid #8b99a6;background:white}</style>
<header>CSiM embedded dashboard — navigation regression</header><iframe title="CSiM dashboard" name="csim-dashboard"></iframe>
<script>
const value=new URL(location.href).searchParams.get('dashboard');
if(value){const target=new URL(value);if(['http:','https:'].includes(target.protocol))document.querySelector('iframe').src=target.href;}
</script></html>`;
http.createServer((request,response)=>{
  response.writeHead(200,{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store'});
  response.end(html);
}).listen(port,'127.0.0.1');
