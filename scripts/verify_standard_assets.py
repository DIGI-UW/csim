"""Prove that a standard comparison serves the pinned Apache frontend assets."""
import argparse
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
HASH_ASSETS = """
import hashlib, pathlib
root = pathlib.Path('/app/superset/static/assets')
digest = hashlib.sha256()
files = sorted(path for path in root.rglob('*') if path.is_file())
assert files, 'No frontend assets found'
for path in files:
    digest.update(str(path.relative_to(root)).encode() + b'\\0')
    digest.update(hashlib.sha256(path.read_bytes()).digest())
print(digest.hexdigest())
"""


def output(*args):
    return subprocess.check_output(args, text=True).strip()


def verify(profile):
    env = dict(line.split('=', 1) for line in (ROOT / f'.env.{profile}').read_text().splitlines())
    assert env['CSIM_DOCKERFILE'] == 'Dockerfile', 'Comparison must use the driver-only image'
    base = env['CSIM_SUPERSET_IMAGE']
    assert '@sha256:' in base, 'Apache image must be pinned by digest'
    container = f'csim-{profile}-superset-1'
    expected = output('docker', 'run', '--rm', '--entrypoint', 'python3', base, '-c', HASH_ASSETS)
    actual = output('docker', 'exec', container, 'python3', '-c', HASH_ASSETS)
    assert actual == expected, 'Running frontend differs from the pinned upstream image'
    receipt = {
        'profile': profile, 'upstreamImage': base,
        'runningImageId': output('docker', 'inspect', '--format', '{{.Image}}', container),
        'upstreamAssetSha256': expected, 'runningAssetSha256': actual,
        'unmodifiedFrontend': True,
    }
    destination = ROOT / 'output' / f'{profile}-asset-verification.json'
    destination.write_text(json.dumps(receipt, indent=2)+'\n')
    print(json.dumps(receipt))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('profile', choices=('standard', 'development'))
    verify(parser.parse_args().profile)
