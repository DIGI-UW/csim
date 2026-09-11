"""Publish only asserted, visually reviewed recordings and real chart screenshots."""
import argparse
import hashlib
import html
import json
from pathlib import Path
import shutil

p=argparse.ArgumentParser()
p.add_argument('--custom',required=True,type=Path)
p.add_argument('--official',required=True,type=Path)
p.add_argument('--screenshot-review',required=True,type=Path)
p.add_argument('--output',required=True,type=Path)
a=p.parse_args()
if a.output.exists():
    raise SystemExit('Use a new output directory; evidence releases are immutable')
review=json.loads(a.screenshot_review.read_text())
assert review['reviewed'] and review['chartScreenshots']==99
report=Path(review['testReport'])
assert hashlib.sha256(report.read_bytes()).hexdigest()==review['reportSha256']
runs={}
for name,path in [('custom',a.custom),('official',a.official)]:
    provenance=json.loads((path/'provenance.json').read_text())
    films=json.loads((path/'films/manifest.json').read_text())['workflows']
    inspected=json.loads((path/'reviewed-frames.json').read_text())
    assert set(films)==set(inspected['workflowIds']) and inspected['reviewed']
    assert provenance['runtimeRevision']==review['runtimeRevision']
    assert provenance['runtimeImageId'], 'A public film requires the deployed image identity'
    for number,film in films.items():
        assert film['maxPixelDifference']<=6 and film['framesChecked']>0
        assert inspected['filmSha256'][number]==hashlib.sha256(Path(film['file']).read_bytes()).hexdigest()
    runs[name]=(path,provenance,films)
a.output.mkdir(parents=True)
styles='body{max-width:1160px;margin:auto;padding:26px;background:#f4f7f5;color:#19332d;font:16px/1.55 system-ui}h1,h2{line-height:1.2}a{color:#09614d}section,article,details{background:white;border:1px solid #cddbd5;border-radius:8px;padding:22px;margin:20px 0}video,img{max-width:100%;height:auto}video{width:100%;background:#edf3ef}.grid{display:grid;grid-template-columns:1fr 1fr;gap:18px}.grid article{margin:0}summary{cursor:pointer}code{overflow-wrap:anywhere}@media(max-width:720px){.grid{grid-template-columns:1fr}body{padding:16px}}'
content=['<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CSiM dashboard workflows</title><style>'+styles+'</style><a href="../../comparison.html">← Compare custom and official Superset</a><h1>CSiM dashboard workflows</h1><p>Try the date controls, change the grouping and check hospital results. Each recording shows a running full September dashboard. The official option retains its native date editor and year-first labels.</p>']
manifest={'runtimeRevision':review['runtimeRevision'],'xAxisScreenshots':99,'screenshotsReviewed':True,'presentationFindings':review['findings'],'options':{}}
for name,(path,provenance,films) in runs.items():
    guide=json.loads((path/'workflow-guide.json').read_text())
    heading='Client month controls and exact date wording' if name=='custom' else 'Official Superset controls and date labels'
    dashboard=provenance['baseURL']+'/superset/dashboard/'+provenance['dashboardSlug']+'/'
    content.append('<section><h2>'+heading+'</h2><p><a href="'+html.escape(dashboard)+'">Open this dashboard</a> · <a href="../../comparison.html#'+name+'">Matching login</a></p><div class="grid">')
    published={}
    for number,film in sorted(films.items()):
        dest=a.output/name/number;dest.mkdir(parents=True)
        shutil.copy2(film['file'],dest/'workflow.mp4');shutil.copy2(film['captions'],dest/'captions.vtt')
        checkpoint=next(c for c in film['checkpoints'] if c.get('assertedScreenshot'))
        shutil.copy2(checkpoint['assertedScreenshot'],dest/'poster.png')
        for i,sheet in enumerate(film['contactSheets']):shutil.copy2(sheet,dest/f'frames-{i+1}.jpg')
        prefix=name+'/'+number
        title=html.escape(guide[number]['label']);expected=html.escape(guide[number]['expected'])
        content.append('<article><h3>'+title+'</h3><video controls preload="none" poster="'+prefix+'/poster.png"><source src="'+prefix+'/workflow.mp4" type="video/mp4"><track kind="captions" src="'+prefix+'/captions.vtt" srclang="en" label="English"></video><p>'+expected+'</p><details><summary>Inspected frames and checks</summary><p>'+str(film['framesChecked'])+' encoded checkpoints match the asserted screenshots.</p>'+''.join('<p><a href="'+prefix+'/frames-'+str(i+1)+'.jpg">Frames '+str(i+1)+'</a></p>' for i in range(len(film['contactSheets'])))+'</details></article>')
        published[number]={'title':guide[number]['label'],'durationSeconds':film['durationSeconds'],'framesChecked':film['framesChecked'],'maxPixelDifference':film['maxPixelDifference'],'sha256':hashlib.sha256((dest/'workflow.mp4').read_bytes()).hexdigest()}
    content.append('</div></section>')
    manifest['options'][name]={'provenance':provenance,'workflows':published}
content.append('<section><h2>Every date chart at three screen widths</h2><p>Eleven charts, three groupings and three widths: all 99 x-axis captures retain chronological, complete labels. The narrow monthly antibiotic charts still need more space between their long vertical count title and the legend.</p>')
shots=a.output/'screenshots';shots.mkdir()
for item in review['sheets']:
    source=Path(item['sheet']);assert hashlib.sha256(source.read_bytes()).hexdigest()==item['sha256']
    shutil.copy2(source,shots/source.name)
    content.append('<details><summary>'+html.escape(source.stem)+'</summary><a href="screenshots/'+source.name+'"><img loading="lazy" src="screenshots/'+source.name+'" alt="'+html.escape(source.stem)+' date-axis screenshots"></a></details>')
content.append('</section><details><summary>Build and evidence details</summary><p>Runtime/definitions: <code>'+review['runtimeRevision']+'</code>. These checks establish the shown workflows; CI completion, editor handover and Beth’s acceptance are recorded separately.</p><p><a href="validation.json">Validation manifest</a></p></details></html>')
(a.output/'index.html').write_text(''.join(content))
(a.output/'validation.json').write_text(json.dumps(manifest,indent=2)+'\n')
(a.output/'SHA256SUMS').write_text(''.join(hashlib.sha256(f.read_bytes()).hexdigest()+'  '+str(f.relative_to(a.output))+'\n' for f in sorted(a.output.rglob('*')) if f.is_file()))
print(a.output)
