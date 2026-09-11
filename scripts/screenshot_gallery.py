"""Publish inspected Playwright screenshots, grouped by the reporting concern."""
import hashlib
import base64
import html
import json
import re
from pathlib import Path
import shutil
import subprocess


GROUPS = [
    ('opening-panels', 'A useful opening view', 'The opening demo has useful content'),
    ('axis-spacing', 'Readable labels at three widths', 'Date labels retain both ends'),
    ('grouping', 'Month, Quarter and Year, including hover details', '02 '),
    ('missing-periods', 'Missing months, valid zero and partial quarters', '03 '),
    ('filter-recovery', 'Change, clear and reselect filters', '04 '),
    ('month-controls', 'Inclusive month controls and partial-period notes', '07 '),
    ('multiple-series', 'Multiple series across a year boundary', '06 '),
    ('time-menus', 'Main and snapshot Time Unit choices', '05 '),
    ('full-dashboard', 'The complete dashboard after import', '01 '),
]


def specs(suites):
    for suite in suites:
        yield from suite.get('specs', [])
        yield from specs(suite.get('suites', []))


def attachment_json(attachment):
    if 'path' in attachment:
        return json.loads(Path(attachment['path']).read_text())
    return json.loads(base64.b64decode(attachment['body']))


def build_gallery(root: Path, destination: Path, review_file: Path, revision: str):
    review = json.loads(review_file.read_text())
    if review.get('reviewed') is not True:
        raise ValueError('The screenshot review must be completed before publication.')
    # The review names the tested source. Documentation-only changes can follow it.
    subprocess.run(['git', 'diff', '--exit-code', review['revision'], revision, '--',
                    'dashboard', 'data', 'patches', 'superset_config.py', 'compose.yaml',
                    'Dockerfile', 'Dockerfile.formatter', 'Dockerfile.month-controls', 'e2e/acceptance',
                    'e2e/acceptance.config.mjs', 'e2e/month-controls.config.mjs'],
                   cwd=root, check=True, stdout=subprocess.DEVNULL)
    destination.mkdir(parents=True, exist_ok=True)
    groups = {anchor: [] for anchor, _, _ in GROUPS}
    manifest = {'testedRevision': review['revision'], 'reviewed': True, 'runs': []}
    for run in review['runs']:
        report_path = Path(run['report'])
        raw = report_path.read_bytes()
        if hashlib.sha256(raw).hexdigest() != run['sha256']:
            raise ValueError('Results changed after screenshot review: ' + run['label'])
        report = json.loads(raw)
        if report['stats']['unexpected'] or report['stats'].get('flaky'):
            raise ValueError('Cannot publish a passing claim for a failing run.')
        summary = {key: run[key] for key in ('key', 'label', 'url', 'sha256')}
        summary.update(passed=report['stats']['expected'], skipped=report['stats']['skipped'], screenshots=[])
        chart_names = {}
        for spec in specs(report['suites']):
            for test in spec['tests']:
                for attachment in test['results'][-1].get('attachments', []):
                    if attachment['name'] == 'opening-view':
                        chart_names.update({str(row['id']): row['title'] for row in attachment_json(attachment)})
        for spec in specs(report['suites']):
            group = next((anchor for anchor, _, match in GROUPS if spec['title'].startswith(match)), None)
            if group is None:
                continue
            for test in spec['tests']:
                result = test['results'][-1]
                if result['status'] != 'passed':
                    continue
                pictures = []
                for number, attachment in enumerate(result.get('attachments', [])):
                    if attachment.get('contentType') != 'image/png':
                        continue
                    relative = Path(run['key']) / group / f'{number + 1:03d}.png'
                    target = destination / relative
                    target.parent.mkdir(parents=True, exist_ok=True)
                    if 'path' in attachment:
                        shutil.copy2(Path(attachment['path']), target)
                    else:
                        target.write_bytes(base64.b64decode(attachment['body']))
                    label = attachment['name']
                    chart = re.fullmatch(r'(Month|Quarter|Year|chart)-(\d+)', label)
                    if chart and chart[2] in chart_names:
                        label = chart_names[chart[2]] + ('' if chart[1] == 'chart' else ' · ' + chart[1] + ' grouping')
                    pictures.append(f'<figure><a href="{relative.as_posix()}"><img loading="lazy" src="{relative.as_posix()}" alt="{html.escape(label, quote=True)}"></a><figcaption>{html.escape(label)}</figcaption></figure>')
                    summary['screenshots'].append({'file': relative.as_posix(), 'label': label, 'test': spec['title']})
                if pictures:
                    groups[group].append(f'<details><summary>{html.escape(run["label"])} · {len(pictures)} screenshots</summary><p><a href="{html.escape(run["url"], quote=True)}">Open this dashboard ↗</a></p><div class="grid">{"".join(pictures)}</div></details>')
        manifest['runs'].append(summary)
    missing = [anchor for anchor, entries in groups.items() if not entries]
    if missing:
        raise ValueError('Missing screenshot coverage: ' + ', '.join(missing))
    nav = ''.join(f'<a href="#{anchor}">{title}</a>' for anchor, title, _ in GROUPS)
    sections = ''.join(f'<section id="{anchor}"><h2>{title}</h2>{"".join(groups[anchor])}</section>' for anchor, title, _ in GROUPS)
    body = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CSiM dashboard screenshot checks</title><style>
*{box-sizing:border-box}body{max-width:1200px;margin:auto;padding:28px;background:#f5f7f4;color:#253c3b;font:16px/1.6 system-ui,sans-serif}h1,h2{line-height:1.25}a{color:#24665f;text-underline-offset:3px}nav{display:flex;flex-wrap:wrap;gap:12px;margin:24px 0}nav a,details{background:white;border:1px solid #d9e2de;border-radius:6px;padding:12px}section{margin:36px 0;scroll-margin-top:20px}details{margin:12px 0}summary{cursor:pointer;font-weight:650}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,430px),1fr));gap:18px}figure{margin:0}img{display:block;width:100%;height:auto;border:1px solid #d9e2de}figcaption{font-size:13px;padding:8px}footer{font-size:14px;margin-top:32px}
</style><a href="../../">← CSiM issues and solutions</a><h1>Dashboard screenshot checks</h1><p>Inspect the actual chart output for each reporting concern. Expand a dashboard version to see its screenshots; select an image for full size.</p><p>The checks cover all twenty opening panels and all eleven date axes. Label spacing is measured at 1024, 1280 and 1600 pixels. Known-record examples check missing values, valid zeroes and partial quarters against explicit expected results.</p>'''
    body += f'<p>Tested source <code>{review["revision"][:8]}</code> · <a href="../">Watch dashboard workflows</a> · <a href="../../#demo-access">Matching links and logins</a></p><nav>{nav}</nav>{sections}'
    body += '<footer>Historical authoring and intermittent saved-link issues remain separately identified in the <a href="../../#next-title">remaining issues</a>. Screenshots and automated checks support review; Beth’s usability acceptance is separate. <a href="manifest.json">Validation inventory</a></footer></html>'
    (destination / 'index.html').write_text(body)
    (destination / 'manifest.json').write_text(json.dumps(manifest, indent=2))
