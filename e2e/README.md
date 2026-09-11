# Dashboard regression and evidence

Run `npm ci` and `npx playwright install chromium` in this directory.

- `CSIM_PROFILE=corrected npm test`: all browser checks, no video.
- Repeat with `preview`, `fixture`, and `preview-fixture` after initialization.
- `npx playwright test -c site.config.mjs`: overview navigation and responsive layout, no video.
- `CSIM_RECORD=1 CSIM_OUTPUT=/absolute/run/path npm test -- --grep '\b02 '`: record an asserted dashboard workflow.

`CSIM_BASE_URL`, `CSIM_USERNAME`, `CSIM_PASSWORD`, and `CSIM_ENV_FILE` select a
remote instance and its viewer login. The credentials and browser session are
excluded from published evidence. `CSIM_DATA_PROFILE=edge-cases` and
`CSIM_DASHBOARD_SLUG=csim-filter-examples` run known-record checks against the
linked worked-example dashboard.

Assertions inspect chart responses, exact numerical examples, the current
HTML document, and the dates actually painted by the chart canvas. Screenshot
attachments retain the real renderer. Recording adds reading pauses and
checkpoints only; it does not replace assertions or paint chart values.

The video renderer in `video/render.py` uses recorded interactions, introduction
and section cards, persistent captions, and six-second minimum screenshot
holds. It decodes the final videos and compares every checkpoint with the
asserted screenshot. Contact sheets require visual inspection before publication.
Website navigation tests never record or enter the public workflow collection.

The presentation checks capture all 21 September opening panels (20 for the preserved April comparison) and all eleven date
axes at 1024, 1280 and 1600 pixels. They measure the text actually painted on the
canvas, including the first/last label and the gap between labels. Captures wait
for chart pixels to settle after animation. Workflow checkpoints also produce
screenshots when video is off.

Publish with `scripts/build_evidence_site.py --screenshot-review /path/review.json`
after inspecting the screenshots. The review contains `revision`, `reviewed: true`,
and a `runs` list. Each run names its `key`, readable `label`, dashboard `url`,
absolute Playwright `report` path and that report's `sha256`. Include the three
full dashboard variants with both supplied and known-record data. The publisher
rejects failed runs, changed reports, runtime changes after review and missing
issue coverage. It groups screenshots by concern, with the version details
collapsed until opened.

## Record the current public options

From the repository root, use `python3 scripts/record_evidence.py september-months`
or `september-months-examples` for the full custom September dashboard. Use
`official` or `official-examples` for the official stable candidate. Supply
`--base-url`, `--access-file`, `--runtime-revision` and `--runtime-image-id` from the
matching deployment receipt when recording a public instance. The access file
is read only for authentication and is excluded from provenance and publication.

The test revision, deployed runtime revision and input-data checksum are recorded
separately. These targets record dashboard behavior only. Official wording and
date-editor differences are shown as differences, not accepted fixes. Inspect
all generated contact sheets before publishing any film.
