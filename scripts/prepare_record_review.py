"""Prepare the optional client review query without shipping a DB connection."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def build():
    manifest = json.loads((ROOT / 'dashboard/client-update/manifest.json').read_text())
    sql = (ROOT / 'review/record-review.sql').read_text()
    for source, destination in manifest['preservedRelations'].items():
        sql = sql.replace('v1."' + source + '"', 'v1."' + destination + '"')
    folder = ROOT / 'release/record-review'
    folder.mkdir(parents=True, exist_ok=True)
    output = folder / 'csim-record-review.sql'
    output.write_text(sql)
    (folder / 'SHA256SUMS').write_text(hashlib.sha256(output.read_bytes()).hexdigest() + '  ' + output.name + '\n')


if __name__ == '__main__':
    build()
