"""Record only asserted dashboard workflows, then caption and validate the films."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('target',choices=['main','examples','preview','months','september'])
p.add_argument('--base-url')
p.add_argument('--output',type=Path)
a=p.parse_args()
profile='preview' if a.target in ('preview','months') else 'corrected'
ids=['08'] if a.target=='september' else ['07'] if a.target=='months' else ['01','05'] if a.target=='main' else ['05'] if a.target=='preview' else ['02','03','04','06']
now=dt.datetime.now(dt.timezone.utc).isoformat()
run=(a.output or ROOT/'output'/'recordings'/a.target).resolve()
run.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,CSIM_PROFILE=profile,CSIM_RECORD='1',CSIM_OUTPUT=str(run))
if a.base_url:env['CSIM_BASE_URL']=a.base_url
if a.target=='months':env.update(CSIM_DATA_PROFILE='edge-cases',CSIM_DASHBOARD_SLUG='csim-month-examples')
if a.target=='september':env.update(CSIM_DATA_PROFILE='edge-cases',CSIM_DASHBOARD_SLUG='csim-reconciled-examples')
if a.target=='examples':env.update(CSIM_DATA_PROFILE='edge-cases',CSIM_DASHBOARD_SLUG='csim-filter-examples')
viewer=json.loads((ROOT/'output'/f'{profile}-viewer.json').read_text())
env.update(CSIM_USERNAME=viewer['username'],CSIM_PASSWORD=viewer['password'])
revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
data=ROOT/'data'/('edge-cases.sql' if a.target in ('examples','months','september') else 'v1_schema_dump.sql')
provenance={'timestamp':now,'revision':revision,'target':a.target,'profile':profile,'baseURL':a.base_url or 'local verification','dataSha256':hashlib.sha256(data.read_bytes()).hexdigest()}
(run/'provenance.json').write_text(json.dumps(provenance,indent=2))
(run/'workflow-guide.json').write_bytes((ROOT/'e2e/workflow-guide.json').read_bytes())
(run/'publication.json').write_text(json.dumps({'workflowIds':ids}))
subprocess.run(['npx','playwright','test','-c','month-controls.config.mjs' if a.target=='months' else 'acceptance.config.mjs','--grep',r'\b('+'|'.join(ids)+') '],cwd=ROOT/'e2e',env=env,check=True)
subprocess.run([sys.executable,str(ROOT/'e2e/video/render.py'),str(run)],cwd=ROOT,check=True)
print('Films and encoded-frame validation:',run/'films')
