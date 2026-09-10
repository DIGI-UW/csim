"""Add CSiM host routes; enable legacy redirects only as a separate step."""
import argparse
from pathlib import Path
import re
p=argparse.ArgumentParser()
p.add_argument('original',type=Path)
p.add_argument('destination',type=Path)
p.add_argument('--redirects',action='store_true')
a=p.parse_args()
text=a.original.read_text().split('# BEGIN CSIM HOSTS')[0].rstrip()+'\n'
if a.redirects:
    start=text.index('\t# Public guide:')
    end=text.index('\t# Everything else is the SPA',start)
    text=text[:start]+'''\t# Old CSiM links retain their path and query on the new host.
\t@old_design path /superset/design /superset/design/*
\thandle @old_design {
\t\troute {
\t\t\turi strip_prefix /superset/design
\t\t\tredir https://design.csim.uwdigi.org{uri} 308
\t\t}
\t}
\t@old_main path /superset /superset/*
\thandle @old_main {
\t\troute {
\t\t\turi strip_prefix /superset
\t\t\turi query next ^/superset/ /
\t\t\turi replace csim-full-synthetic csim-individual-corrected
\t\t\tredir https://dashboard.csim.uwdigi.org{uri} 308
\t\t}
\t}
\t@old_preview path /superset-preview /superset-preview/*
\thandle @old_preview {
\t\troute {
\t\t\turi strip_prefix /superset-preview
\t\t\turi query next ^/superset-preview/ /
\t\t\turi replace csim-full-synthetic csim-individual-preview
\t\t\tredir https://preview.csim.uwdigi.org{uri} 308
\t\t}
\t}

'''+text[end:]
text+='\n# BEGIN CSIM HOSTS\n'+(Path(__file__).parent/'hosts.Caddyfile').read_text()
a.destination.write_text(text)
