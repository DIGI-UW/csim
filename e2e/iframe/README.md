# Embedded dashboard navigation regression

From `e2e/`, run against the existing official Superset 6.1.0 instance:

```sh
CSIM_OUTPUT=../output/iframe-standard npx playwright test -c iframe.config.mjs
```

Set `CSIM_BASE_URL`, `CSIM_ENV_FILE`, `CSIM_USERNAME`, `CSIM_PASSWORD`, or
`CSIM_DASHBOARD_SLUG` to use another authorized instance. No imports or dashboard
edits occur. The selected hospital defaults to 53; `CSIM_IFRAME_HOSPITAL` changes it.

The suite tests the direct page and ordinary cross-origin iframe with and without
`standalone=2`. Each run changes real filters, preserves their shareable URL,
clicks every Table of Contents entry, and checks visible destinations, unchanged
filters and all five trend result sets, no document reload, and no popup. Screenshots are saved
for all nine section destinations. Video is disabled.

The host is served at `http://127.0.0.1:18781/?dashboard=<encoded-dashboard-URL>`.
It can also be opened manually while `node iframe/server.mjs` is running.

Different localhost ports test cross-origin behavior but remain same-site.
This does not establish that a client WordPress site permits embedding, forwards
login, or uses the same sandbox attributes. Those must also be checked against
the actual client page. This harness does not relax Superset frame or cookie
policies and will expose any embedding block configured by the target instance.
