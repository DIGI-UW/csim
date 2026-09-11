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
targets={
    'main': ('corrected', ['01','05'], None, False),
    'examples': ('corrected', ['02','03','04','06'], 'csim-filter-examples', True),
    'preview': ('preview', ['05'], None, False),
    'months': ('preview', ['07'], 'csim-month-examples', True),
    'september': ('corrected', ['08'], 'csim-reconciled-examples', True),
    'september-months': ('corrected', ['02','07','09'], 'csim-individual-reconciled-months', False),
    'september-months-examples': ('corrected', ['03','06','07'], 'csim-reconciled-months-examples', True),
    'official-months': ('standard', ['11'], 'csim-standard-month-selectors-examples', True),
    'official': ('standard', ['04','10'], 'csim-individual-standard-sortable', False),
    'official-examples': ('standard', ['03','04','10'], 'csim-standard-sortable-examples', True),
}
p.add_argument('target',choices=targets)
p.add_argument('--base-url')
p.add_argument('--output',type=Path)
p.add_argument('--access-file',type=Path,help='Matching viewer credentials; never copied into evidence')
p.add_argument('--runtime-revision',help='Deployed application revision, separately from test revision')
p.add_argument('--assets-revision',help='Deployed dashboard definition revision')
p.add_argument('--runtime-image-id',help='Verified deployed image digest')
a=p.parse_args()
profile,ids,slug,fixture=targets[a.target]
now=dt.datetime.now(dt.timezone.utc).isoformat()
run=(a.output or ROOT/'output'/'recordings'/a.target).resolve()
run.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,CSIM_PROFILE=profile,CSIM_RECORD='1',CSIM_OUTPUT=str(run))
if a.base_url:env['CSIM_BASE_URL']=a.base_url
if slug:env['CSIM_DASHBOARD_SLUG']=slug
if a.target=='official-months':env['CSIM_NATIVE_MONTHS']='1'
env['CSIM_DATA_PROFILE']='edge-cases' if fixture else 'supplied-demo'
env['CSIM_SIMPLE_CONTROLS']='1' if a.target=='months' or a.target.startswith('september-months') else '0'
viewer=json.loads((a.access_file or ROOT/'output'/f'{profile}-viewer.json').read_text())
env.update(CSIM_USERNAME=viewer['username'],CSIM_PASSWORD=viewer['password'])
revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
data=ROOT/'data'/('edge-cases.sql' if fixture else 'v1_schema_dump.sql')
provenance={'timestamp':now,'revision':revision,'target':a.target,'profile':profile,'baseURL':a.base_url or 'local verification','dataSha256':hashlib.sha256(data.read_bytes()).hexdigest()}
provenance.update(dashboardSlug=slug,runtimeRevision=a.runtime_revision,assetsRevision=a.assets_revision,runtimeImageId=a.runtime_image_id)
(run/'provenance.json').write_text(json.dumps(provenance,indent=2))
(run/'workflow-guide.json').write_bytes((ROOT/'e2e/workflow-guide.json').read_bytes())
(run/'publication.json').write_text(json.dumps({'workflowIds':ids}))
subprocess.run(['npx','playwright','test','-c','month-controls.config.mjs' if a.target=='months' else 'acceptance.config.mjs','--grep',r'\b('+'|'.join(ids)+') '],cwd=ROOT/'e2e',env=env,check=True)
subprocess.run([sys.executable,str(ROOT/'e2e/video/render.py'),str(run)],cwd=ROOT,check=True)
print('Films and encoded-frame validation:',run/'films')
