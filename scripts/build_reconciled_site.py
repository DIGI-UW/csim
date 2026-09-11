"""Add September evidence while preserving previously published workflow provenance."""
import argparse
import hashlib
import html
import json
from pathlib import Path
import shutil
import subprocess

import screenshot_gallery

ROOT = Path(__file__).resolve().parents[1]
p = argparse.ArgumentParser()
p.add_argument('--previous-release', required=True, type=Path)
p.add_argument('--review', required=True, type=Path)
p.add_argument('--recording', required=True, type=Path)
a = p.parse_args()
revision = subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
previous = a.previous_release.resolve()
# The prior artifact is immutable: verify it before retaining its evidence.
for line in (previous/'SHA256SUMS').read_text().splitlines():
    digest, name = line.split(None,1)
    assert hashlib.sha256((previous/name.lstrip('*')).read_bytes()).hexdigest()==digest,name
output = ROOT/'output/public-release'/revision
if output.exists():
    raise ValueError('Choose a new committed revision; release directories are immutable')
shutil.copytree(previous,output)
shutil.copy2(ROOT/'design/index.html',output/'index.html')
old_release=json.loads((previous/'release.json').read_text())
release=dict(old_release,revision=revision,previousOverviewRevision=old_release['revision'])
deployment=ROOT/'output/reconciled-deployment'
verification=json.loads((deployment/'reconciliation-verification.json').read_text())
assert verification['beforeSha256']==verification['afterSha256']
assets_revision=(deployment/'assets-revision.txt').read_text().strip()
release['reconciledAssets']={'revision':assets_revision,'url':'https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-reconciled/',
    'charts':21,'datasets':6,'preservation':verification,'runtimeImageId':(deployment/'runtime-image-id.txt').read_text().strip()}
(output/'release.json').write_text(json.dumps(release,indent=2))
for name in ['reconciled','reconciled-examples']:
    shutil.copy2(deployment/f'{name}-dashboard.zip',output/'definitions'/f'csim-individual-{name}.zip')
destination=output/'evidence/september'
destination.mkdir(parents=True,exist_ok=True)
screenshot_gallery.GROUPS=[g for g in screenshot_gallery.GROUPS if g[0]!='month-controls']
screenshot_gallery.GROUPS.insert(0,('september-additions','Beth’s additions and comparison selectors','08 '))
screenshot_gallery.build_gallery(ROOT,destination/'screenshots',a.review,revision)
gallery=destination/'screenshots/index.html'
content=gallery.read_text().replace('all twenty opening panels','all twenty-one opening panels').replace('href="../../','href="../../../')
gallery.write_text(content)
recording=a.recording.resolve()
provenance=json.loads((recording/'provenance.json').read_text())
reviewed=json.loads((recording/'reviewed-frames.json').read_text())
assert '08' in reviewed['workflowIds']
film=json.loads((recording/'films/manifest.json').read_text())['workflows']['08']
subprocess.run(['git','diff','--exit-code',provenance['revision'],revision,'--','dashboard','patches','data','e2e/acceptance','e2e/acceptance.config.mjs'],cwd=ROOT,check=True)
for field,name in [('file','workflow.mp4'),('captions','captions.vtt')]:shutil.copy2(film[field],destination/name)
checks=[c for c in film['checkpoints'] if c.get('assertedScreenshot')]
assert checks
shutil.copy2(checks[0]['assertedScreenshot'],destination/'opening.png')
for i,sheet in enumerate(film['contactSheets']):shutil.copy2(sheet,destination/f'frames-{i+1}.jpg')
for path in deployment.glob('*.json'):shutil.copy2(path,destination/path.name)
(destination/'validation.json').write_text(json.dumps({'assetsRevision':assets_revision,'recordedRevision':provenance['revision'],
    'runtime':old_release['deployments']['main'],'framesChecked':film['framesChecked'],
    'maxPixelDifference':film['maxPixelDifference'],'visuallyReviewed':True},indent=2))
(destination/'index.html').write_text(f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>September CSiM dashboard: workflow and screenshots</title><style>body{{max-width:1100px;margin:auto;padding:28px;background:#f5f7f4;color:#253c3b;font:17px/1.6 system-ui}}h1,h2{{line-height:1.2}}a{{color:#24665f}}video{{width:100%;background:white}}section,details{{padding:22px;background:white;border:1px solid #d9e2de;border-radius:8px;margin:24px 0}}.links{{display:flex;gap:18px;flex-wrap:wrap}}img{{max-width:100%}}</style>
<a href="../../">← CSiM issues and solutions</a><h1>Beth’s September version</h1><p>The familiar controls, Beth’s 21-chart presentation, and the date/filter corrections are available together. The established 20-chart version remains unchanged.</p>
<p class="links"><a href="https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-reconciled/">Open September dashboard ↗</a><a href="../../#demo-access">Matching login</a><a href="https://dashboard.csim.uwdigi.org/superset/dashboard/csim-individual-corrected/">Compare established version ↗</a></p>
<section><h2>Latest data, section links and comparison selectors</h2><p>The recording uses known records. The latest-data card remains independent of the viewing window; section links keep the selections; and named states produce comparison charts.</p><video controls preload="none" poster="opening.png"><source src="workflow.mp4" type="video/mp4"><track kind="captions" src="captions.vtt" srclang="en" label="English"></video><p class="links"><a href="https://dashboard.csim.uwdigi.org/superset/dashboard/csim-reconciled-examples/">Repeat with known records ↗</a><a href="frames-1.jpg">Inspected video frames</a><a href="validation.json">Validation details</a></p></section>
<section><h2>Check every original reporting concern</h2><p>The screenshots cover all 21 opening panels, eleven date axes in Month/Quarter/Year at three widths, hover details, missing periods, valid zeroes, partial quarters, multiple series and filter recovery. Both supplied and known-record data are included.</p><p><a href="screenshots/">Open the September screenshot gallery →</a></p></section>
<details><summary>Version and import checks</summary><p>Dashboard assets: <code>{assets_revision[:12]}</code>. Runtime: the existing main Superset 6.1.0 CSiM build. Adding this version left {verification['existingDashboardsUnchanged']} existing dashboard definitions unchanged.</p><p><a href="reconciliation-verification.json">Preservation check</a> · <a href="reconciled-import-verification.json">21-chart definition check</a> · <a href="https://github.com/DIGI-UW/csim/blob/main/RECONCILIATION.md">Included changes and reproduction</a></p></details><p>Automated checks and screenshot review are complete for this release. Beth’s usability acceptance remains separate.</p></html>''')
index=output/'evidence/index.html'
text=index.read_text().replace('<nav>','<nav><a href="september/">September version: additions and full screenshot checks</a>',1)
index.write_text(text)
(output/'SHA256SUMS').unlink()
(output/'SHA256SUMS').write_text(''.join(hashlib.sha256(f.read_bytes()).hexdigest()+'  '+f.relative_to(output).as_posix()+'\n' for f in sorted(output.rglob('*')) if f.is_file()))
print(output)
