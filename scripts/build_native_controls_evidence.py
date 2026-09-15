"""Build the official month-control evidence from asserted runs and reviewed films."""
import argparse
import html
import json
from pathlib import Path
import shutil

root=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
for arg in ['recording','supplied-review','range-review']:p.add_argument('--'+arg,required=True,type=Path)
p.add_argument('--output',type=Path,default=root/'design/evidence/native-controls')
a=p.parse_args();dest=a.output;dest.mkdir(parents=True,exist_ok=True)
for directory in [a.recording,a.supplied_review,a.range_review]:
 result=json.loads((directory/'results.json').read_text())
 assert result['stats']['expected']>0 and result['stats']['unexpected']==0 and result['stats']['flaky']==0 and not result.get('errors'), f'Passing checks required: {directory}'
film=json.loads((a.recording/'films/manifest.json').read_text())
reviewed=json.loads((a.recording/'reviewed-frames.json').read_text())
assert {'11','12'} <= set(reviewed['workflowIds']), 'Inspect both films before publishing'
provenance=json.loads((a.recording/'provenance.json').read_text())
axes_path=next(a.supplied_review.glob('results/**/native-label-comparison.json'))
axes=json.loads(axes_path.read_text());assert len(axes['cases'])==99
assert all(not any('edge:' in issue or 'crowded labels:' in issue for issue in c['issues']) for c in axes['cases'])
def copy(source,name):
 shutil.copy2(source,dest/name)
 return name
videos=[]
for id,title in [('11','Inclusive months, missing data and grouping'),('12','Correct a reversed range on the same page')]:
 f=film['workflows'][id];copy(f['file'],f'workflow-{id}.mp4');copy(f['captions'],f'captions-{id}.vtt')
 shots=[c['assertedScreenshot'] for c in f['checkpoints'] if c.get('assertedScreenshot')];assert shots
 copy(shots[0],f'poster-{id}.png')
 for i,sheet in enumerate(f['contactSheets']):copy(sheet,f'frames-{id}-{i+1}.jpg')
 videos.append(f'<article><h3>{title}</h3><video controls preload="none" poster="poster-{id}.png"><source src="workflow-{id}.mp4" type="video/mp4"><track kind="captions" src="captions-{id}.vtt" srclang="en" label="English"></video><p><a href="frames-{id}-1.jpg">Inspected video frames</a></p></article>')
for directory,pattern,name in [(a.supplied_review,'native-rolling-defaults.png','opening.png'),(a.range_review,'native-warning-1024.png','warning.png'),(a.range_review,'native-partial-summary.png','partial.png')]:copy(next(directory.glob('results/**/'+pattern)),name)
cards=[]
for i,c in enumerate(axes['cases']):
 name=copy(c['screenshot'],f'axis-{i+1}.png');label=html.escape(f'{c["chart"]} · {c["grain"]} · {c["width"]}px')
 cards.append(f'<figure><a href="{name}"><img loading="lazy" src="{name}" alt="{label}"></a><figcaption>{label}</figcaption></figure>')
copy(axes_path,'axis-checks.json')
for name,directory in [('supplied-tests.json',a.supplied_review),('range-tests.json',a.range_review)]:copy(directory/'results.json',name)
for name in ['provenance.json','reviewed-frames.json']:copy(a.recording/name,name)
validation={'dashboardAssetsRevision':provenance.get('assetsRevision'),'testRevision':provenance['revision'],'workflowIds':['11','12'],'dateAxes':11,'axisScreenshots':99,'widths':[1024,1280,1600],'geometryIssues':0,'wordingDifference':'Year-first labels replace month-name-first labels','bethAcceptance':'not recorded'}
(dest/'validation.json').write_text(json.dumps(validation,indent=2)+'\n')
(dest/'index.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CSiM: official month-control evidence</title><style>body{max-width:1120px;margin:auto;padding:28px;background:#f5f7f4;color:#253c3b;font:17px/1.6 system-ui}h1,h2,h3{line-height:1.25}a{color:#24665f}section,details,article{padding:22px;background:white;border:1px solid #d9e2de;border-radius:8px;margin:24px 0}img,video{width:100%;height:auto}figure{margin:18px 0}figcaption{font-size:14px}.gallery{display:grid;grid-template-columns:1fr 1fr;gap:16px}summary{cursor:pointer;font-weight:600}@media(max-width:650px){body{padding:16px}.gallery{grid-template-columns:1fr}}</style>
<a href="../../">← CSiM issues and solutions</a><h1>Month controls in official Superset</h1><p>Select an inclusive month range, compare Month, Quarter and Year, and see which dates contribute to the results. These workflows use official Superset 6.1.0 and the full September reporting dashboard.</p><p><a href="https://standard.csim.uwdigi.org/superset/dashboard/csim-individual-standard-month-selectors/">Open dashboard</a> · <a href="../../#standard-instance">Matching login</a> · <a href="https://standard.csim.uwdigi.org/superset/dashboard/csim-standard-month-selectors-examples/">Repeat the known-number examples</a></p>
<section><h2>The opening window keeps moving</h2><p>“12 months ago” through “Last complete month” includes twelve complete months. The summary shows the actual dates. Choose named months to keep a fixed range.</p><a href="opening.png"><img src="opening.png" alt="Opening dashboard with moving month defaults and resolved dates"></a></section>
<section id="range"><h2>Understand the applied dates</h2><p>February–March grouped as Quarter contains only February and March. If From is later than Through, the summary explains which ending month to choose. This warning appears after Apply; the custom alternative also prevents Apply.</p><div class="gallery"><figure><a href="partial.png"><img src="partial.png" alt="Reporting summary for February through March grouped by quarter"></a><figcaption>Partial-quarter guidance.</figcaption></figure><figure><a href="warning.png"><img src="warning.png" alt="Full reversed-range message visible at a 1024-pixel dashboard width"></a><figcaption>Correction message at the narrowest reviewed width.</figcaption></figure></div></section>
<section><h2>Watch the dashboard workflows</h2>'''+''.join(videos)+'''</section><details><summary>All eleven date charts at three widths</summary><p>Month, Quarter and Year views at 1024, 1280 and 1600 pixels. No clipped or crowded period labels were found in these checks. Month and quarter wording is year-first: 2025-01 and 2025 Q1. The custom alternative uses Jan 2025 and Q1 2025.</p><div class="gallery">'''+''.join(cards)+'''</div></details><details><summary>Validation details</summary><p><a href="validation.json">Coverage and release</a> · <a href="provenance.json">Recording source</a> · <a href="axis-checks.json">Rendered date-label checks</a> · <a href="supplied-tests.json">Full dashboard checks</a> · <a href="range-tests.json">Known-number checks</a></p><p>These checks cover the displayed workflow. Beth’s acceptance and the separate reporting-data questions remain open.</p></details></html>''')
print(dest)
