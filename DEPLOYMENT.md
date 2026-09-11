# Reproducible deployment

Deploy from a reviewed revision on `origin/main`. The main and snapshot images
are built from pinned upstream sources and the patches in this repository.
The supplied demo dump is restored with PostgreSQL 14.24. Normal updates change
definitions without restoring the reporting database.

## Build, stage, and initialize

Build and test locally using the README commands. CI must pass for the release.
The current Catalyst server and local images use ARM64. The staging command
streams the two tested images and the Git archive to a revision directory.

```sh
bash deploy/server.sh stage FULL_GIT_REVISION
bash deploy/server.sh init FULL_GIT_REVISION
```

Initialization creates two independent Superset metadata stores, two reporting
clusters, and their supplied-data and known-record databases. It refuses an
existing reporting schema. Credentials live in `/home/ubuntu/csim/shared`;
release directories link those environment files. It also creates the viewer
accounts, imports the hourly snapshot example, verifies definitions and runs a
changed-definition update followed by restoration.

The importer connects to Superset's loopback HTTP listener. It retains its
session cookie on that internal connection even when browser cookies require
HTTPS. CI checks this configuration with an import and changed-definition
update; public browser cookies remain HTTPS-only.

For subsequent releases:

```sh
bash deploy/server.sh stage FULL_GIT_REVISION
bash deploy/server.sh update FULL_GIT_REVISION
```

Updates back up each metadata database before importing. The original source
archives and reporting data remain unchanged. Definitions for the linked
examples are updated separately from their one-time data initialization.

## Hostnames and publication

The proxy joins the new Superset services through distinct Docker aliases.
The previous CSiM containers remain available for rollback. Add hostnames as a
separate step, after dashboard validation:

```sh
bash deploy/server.sh hosts FULL_GIT_REVISION
```

- `dashboard.csim.uwdigi.org`: released build and CSiM formatter.
- `preview.csim.uwdigi.org`: independently pinned development snapshot.
- `csim.uwdigi.org`: redirects to the main installation.
- `design.csim.uwdigi.org`: overview, matching viewer logins and evidence.

Record the dashboard workflows at the release revision with
`scripts/record_evidence.py`. Inspect each film’s encoded-frame contact sheets
and save the reviewed workflow IDs in its `reviewed-frames.json`. Assemble the
site with `scripts/build_evidence_site.py`, supplying the deployed viewer files.
Copy only the assembled release directory to the proxy’s
`/srv/media/csim-design-v2` host mount. No navigation-test video is published.

Validate HTTPS, the two viewer sessions, all chart requests, downloadable
bundles, generated chart links and login return destinations. Then enable old
Catalyst-link redirects:

```sh
bash deploy/server.sh redirects FULL_GIT_REVISION
```

The redirect keeps paths and queries, removes the old application prefix and
updates the old full-dashboard slug. URL fragments remain browser-side. The
Caddy configuration is validated before replacement; its admin API is disabled,
so applying it requires a brief proxy restart. Gateway and other Catalyst routes
are preserved by the configuration renderer.

## Rollback

The proxy configuration path saved in
`/home/ubuntu/csim/shared/last-proxy-backup` restores the immediately previous
route state. Copy its contents over the existing Caddyfile and restart
`catalyst-demo-caddy-1`. The old `csim-date-repro` and `csim-upstream-preview`
containers remain intact during migration.

For a later definition rollback, use the previous release directory and image
revision, restore the corresponding metadata backup while that Superset is
stopped, then restart it. Do not reset or reseed the reporting database.

Beth’s review remains a separate acceptance step; it is not implied by a
successful deployment or passing browser checks.
