"""Exercise redirect paths and encoded login returns against a local Caddy."""
from pathlib import Path
import subprocess
import time
import re
import http.client
import urllib.request
import urllib.parse

ROOT=Path(__file__).resolve().parents[1]
(ROOT/'output').mkdir(exist_ok=True)
subprocess.run(['python3',str(ROOT/'deploy/render_caddy.py'),str(ROOT/'deploy/fixtures/Caddyfile'),str(ROOT/'output/Caddyfile-redirects'),'--redirects'],check=True)
first=(ROOT/'output/Caddyfile-redirects').read_bytes()
subprocess.run(['python3',str(ROOT/'deploy/render_caddy.py'),str(ROOT/'output/Caddyfile-redirects'),str(ROOT/'output/Caddyfile-redirects'),'--redirects'],check=True)
assert first==(ROOT/'output/Caddyfile-redirects').read_bytes(),'Route rendering must be idempotent'
source=(ROOT/'output/Caddyfile-redirects').read_text().replace('admin off','admin off\n\tauto_https off')
for host in ['dashboard.csim.uwdigi.org','preview.csim.uwdigi.org','design.csim.uwdigi.org','csim.uwdigi.org']:
 source=re.sub(r'(?m)^'+re.escape(host)+r' \{','http://'+host+' {',source)
(ROOT/'output/Caddyfile-http').write_text(source)
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs):return None
opener=urllib.request.build_opener(NoRedirect)
container='csim-proxy-check'
subprocess.run(['docker','run','--rm','-d','--name',container,'-p','127.0.0.1:18781:80','-v',str(ROOT/'output')+':/check:ro','caddy:2.11.4','caddy','run','--config','/check/Caddyfile-http','--adapter','caddyfile'],check=True,stdout=subprocess.DEVNULL)
try:
 for attempt in range(30):
  try:
   urllib.request.urlopen('http://127.0.0.1:18781/ready',timeout=1)
   break
  except urllib.error.HTTPError:break
  except (urllib.error.URLError,http.client.RemoteDisconnected,TimeoutError):time.sleep(0.1)
 cases=[
 ('/superset/superset/dashboard/2/','dashboard.csim.uwdigi.org','/superset/dashboard/csim-individual-corrected/'),
 ('/superset/superset/dashboard/1/','dashboard.csim.uwdigi.org','/superset/dashboard/csim-filter-examples/'),
 ('/superset/design/','design.csim.uwdigi.org','/'),
 ('/superset/design/evidence/','design.csim.uwdigi.org','/evidence/'),
 ('/superset/superset/dashboard/csim-full-synthetic/?native_filters_key=example','dashboard.csim.uwdigi.org','/superset/dashboard/csim-individual-corrected/?native_filters_key=example'),
 ('/superset-preview/superset/dashboard/hourly-reporting-preview/','preview.csim.uwdigi.org','/superset/dashboard/hourly-reporting-preview/'),
 ('/superset/login/?next=%2Fsuperset%2Fsuperset%2Fdashboard%2Fcsim-full-synthetic%2F','dashboard.csim.uwdigi.org','/login/?next=/superset/dashboard/csim-individual-corrected/'),
 ('/superset-preview/login/?next=%2Fsuperset-preview%2Fsuperset%2Fdashboard%2Fcsim-full-synthetic%2F','preview.csim.uwdigi.org','/login/?next=/superset/dashboard/csim-individual-preview/'),
 ]
 for path,host,expected in cases:
  request=urllib.request.Request('http://127.0.0.1:18781'+path,headers={'Host':'catalyst.openelis-global.org'})
  try:opener.open(request,timeout=10)
  except urllib.error.HTTPError as response:
   assert response.code==308,(path,response.code)
   actual=urllib.parse.unquote(response.headers['Location'])
   assert actual=='https://'+host+expected,(path,actual,expected)
  else:raise AssertionError('Expected a redirect: '+path)
 print('Eight legacy path and encoded login-return cases passed.')
finally:subprocess.run(['docker','stop',container],check=False,stdout=subprocess.DEVNULL)
