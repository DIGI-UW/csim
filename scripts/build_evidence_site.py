"""Assemble the overview and reviewed dashboard evidence for one Git release."""
import argparse
import datetime as dt
import hashlib
import html
import json
from pathlib import Path
import shutil
import subprocess
from screenshot_gallery import build_gallery

ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--access-dir',type=Path,default=ROOT/'output')
p.add_argument('--deployment-manifest',type=Path)
p.add_argument('--screenshot-review',type=Path,required=True)
a=p.parse_args()
revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
output=ROOT/'output/public-release'/revision
output.mkdir(parents=True,exist_ok=True)
shutil.copy2(ROOT/'design/index.html',output/'index.html')
for name,target in [('corrected','access.json'),('preview','preview-access.json')]:
    shutil.copy2(a.access_dir/f'{name}-viewer.json',output/target)
release={'revision':revision,'date':dt.datetime.now(dt.timezone.utc).date().isoformat(),
    'main':'Superset 6.1.0 + versioned CSiM formatter','snapshot':'e22ce197866ded732e4990063ae74697d89d383a + CSiM formatter, inclusive month controls and vertical-filter clear fix',
    'demoSha256':hashlib.sha256((ROOT/'data/v1_schema_dump.sql').read_bytes()).hexdigest(),
    'fixtureSha256':hashlib.sha256((ROOT/'data/edge-cases.sql').read_bytes()).hexdigest()}
if a.deployment_manifest:release['deployments']=json.loads(a.deployment_manifest.read_text())
(output/'release.json').write_text(json.dumps(release,indent=2))
definitions=output/'definitions';definitions.mkdir(exist_ok=True)
shutil.copy2(ROOT/'output/corrected-dashboard.zip',definitions/'csim-individual-corrected.zip')
evidence=output/'evidence';evidence.mkdir(exist_ok=True)
build_gallery(ROOT,evidence/'screenshots',a.screenshot_review,revision)
guide=json.loads((ROOT/'e2e/workflow-guide.json').read_text())
anchors={'01':'native-import','02':'time-grouping','03':'missing-periods','04':'clear-filters','05':'dashboard-time-units','06':'multiple-series','07':'inclusive-months'}
nav=[];cards=[];published=[]
for target in ['main','examples','preview','months']:
    run=ROOT/'output/recordings'/target
    provenance=json.loads((run/'provenance.json').read_text())
    # Documentation and deployment-test updates need not invalidate unchanged
    # dashboard footage. Verify the recorded runtime and browser contract exactly.
    paths=['dashboard','data','patches','Dockerfile','Dockerfile.formatter','Dockerfile.month-controls','superset_config.py','compose.yaml','e2e/acceptance','e2e/acceptance.config.mjs','e2e/workflow-guide.json','e2e/video']
    # Workflow 07 runs only for the months target. Changes to that test cannot
    # change the other recorded workflows; shared helpers and runtime still must match.
    if target != 'months':paths.append(':(exclude)e2e/acceptance/month-controls.spec.mjs')
    subprocess.run(['git','diff','--exit-code',provenance['revision'],revision,'--',*paths],cwd=ROOT,check=True,stdout=subprocess.DEVNULL)
    manifest=json.loads((run/'films/manifest.json').read_text())
    reviewed=json.loads((run/'reviewed-frames.json').read_text())
    for number,item in manifest['workflows'].items():
        if number not in reviewed['workflowIds']:raise ValueError('Frames not visually reviewed: '+target+' '+number)
        key=target+'-'+number;anchor=anchors[number]+('-preview' if target=='preview' else '')
        destination=evidence/key;destination.mkdir(exist_ok=True)
        for field,name in [('file','workflow.mp4'),('captions','captions.vtt')]:shutil.copy2(item[field],destination/name)
        checkpoints=[c for c in item['checkpoints'] if c.get('assertedScreenshot')]
        if not checkpoints:raise ValueError('No asserted chart screenshot: '+key)
        shutil.copy2(checkpoints[0]['assertedScreenshot'],destination/'screenshot.png')
        for index,sheet in enumerate(item['contactSheets']):shutil.copy2(sheet,destination/f'frames-{index+1}.jpg')
        (destination/'validation.json').write_text(json.dumps({'framesChecked':item['framesChecked'],'maxPixelDifference':item['maxPixelDifference'],'durationSeconds':item['durationSeconds'],'visuallyReviewed':True,'revision':revision},indent=2))
        label=guide[number]['label']+(' — snapshot' if target=='preview' else ' — main' if number=='05' else '')
        url='https://'+('preview' if target in ('preview','months') else 'dashboard')+'.csim.uwdigi.org/superset/dashboard/'+('csim-month-examples' if target=='months' else 'csim-filter-examples' if target=='examples' else 'csim-individual-preview' if target=='preview' else 'csim-individual-corrected')+'/'
        if target in ('examples','months'):
            full_url=('https://preview.csim.uwdigi.org/dashboard/csim-individual-simple/' if target=='months' else 'https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-corrected/')
            dashboard_actions=f'<a href="{url}">Repeat with the known test records ↗</a><a href="{full_url}">Open this version with the supplied CSiM data ↗</a>'
            context='This recording uses the full dashboard with known test records, so its numerical examples can be repeated.'
        else:
            dashboard_actions=f'<a href="{url}">Open the full CSiM dashboard shown here ↗</a>'
            context='This recording uses the full dashboard with the supplied CSiM demo data.'
        nav.append(f'<a href="#{anchor}">{html.escape(label)}</a>')
        extra='<span id="date-range"></span>' if number=='03' else ''
        cards.append(f'''<article id="{anchor}">{extra}<p class="eyebrow">{target.capitalize()} · Dashboard workflow</p><h2>{html.escape(label)}</h2><p>{html.escape(guide[number]['try'])}</p><p><strong>Expected result:</strong> {html.escape(guide[number]['expected'])}</p><p>{context}</p><video controls preload="none" poster="{key}/screenshot.png"><source src="{key}/workflow.mp4" type="video/mp4"><track kind="captions" src="{key}/captions.vtt" srclang="en" label="English"></video><p class="actions">{dashboard_actions}<a href="{key}/screenshot.png">Screenshot</a><a href="{key}/frames-1.jpg">Video frames</a><a href="{key}/validation.json">Validation details</a></p></article>''')
        published.append({'workflow':key,'title':label,'anchor':anchor,'dashboard':url,'framesChecked':item['framesChecked'],'recordedRevision':provenance['revision']})
# Import reports describe native behavior separately from helper-assisted behavior.
checks=evidence/'checks';checks.mkdir(exist_ok=True)
for profile in ['corrected','preview']:
    shutil.copy2(ROOT/'output'/f'{profile}-import-verification.json',checks/f'{profile}-import.json')
    shutil.copy2(ROOT/'output'/f'{profile}-receipt.json',checks/f'{profile}-receipt.json')
body='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CSiM dashboard workflow evidence</title><style>
*{box-sizing:border-box}body{margin:0;background:#f5f7f4;color:#253c3b;font:17px/1.6 system-ui,sans-serif}header,main{max-width:1120px;margin:auto;padding:32px}h1{font-size:38px;line-height:1.2}h2{line-height:1.3}a{color:#24665f;text-underline-offset:3px}nav{display:flex;gap:12px;flex-wrap:wrap;margin:30px 0}nav a{padding:8px 12px;background:white;border:1px solid #d9e2de;border-radius:5px}article{background:white;border:1px solid #d9e2de;border-radius:8px;padding:28px;margin:28px 0;scroll-margin-top:20px}video{width:100%;max-height:760px;background:#edf1ee;border:1px solid #d9e2de}.eyebrow{font-size:12px;font-weight:750;text-transform:uppercase;letter-spacing:.08em}.actions{display:flex;gap:20px;flex-wrap:wrap}details{padding:20px;background:#edf1ee}footer{margin-top:32px;font-size:14px}@media(max-width:600px){header,main{padding:18px}article{padding:16px}h1{font-size:30px}}
</style><header><a href="../">← CSiM issues and solutions</a><h1>Dashboard workflows and evidence</h1><p>See the reporting controls and resulting charts. Each recording shows an asserted workflow, with time to read the labels and results.</p>'''
body+=f'<p>Release <code>{revision[:8]}</code> · <a href="../#demo-access">Instance links and logins</a> · <a href="screenshots/">Screenshot acceptance checks</a></p><nav>'+''.join(nav)+'</nav></header><main>'+''.join(cards)
body+='''<details><summary>Dashboard transfer checks</summary><p>The main build imports complete assets and repairs cached chart references with the deployment helper. The snapshot remaps those references natively. The checks compare all 20 charts and six datasets, then change and restore existing definitions without duplicates.</p><p><a href="checks/corrected-import.json">Main definition comparison</a> · <a href="checks/preview-import.json">Snapshot definition comparison</a> · <a href="checks/corrected-receipt.json">Main destination identifiers</a> · <a href="checks/preview-receipt.json">Snapshot destination identifiers</a></p></details><footer>Automated validation and the team’s acceptance are separate. <a href="../#review">Review checklist</a> · <a href="../release.json">Release details</a></footer></main></html>'''
(evidence/'index.html').write_text(body)
(evidence/'manifest.json').write_text(json.dumps({'release':release,'workflows':published},indent=2))
print(output)
