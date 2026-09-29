import {defineConfig} from '@playwright/test';
process.env.CSIM_PROFILE ||= 'standard';
process.env.CSIM_NATIVE_DATES ||= '1';
process.env.CSIM_DASHBOARD_SLUG ||= 'csim-individual-standard-month-selectors';
const {default:acceptance}=await import('./acceptance.config.mjs');
const host=`http://127.0.0.1:${process.env.CSIM_IFRAME_PORT||18781}`;
export default defineConfig({...acceptance,
  testDir:'./iframe',
  webServer:{command:'node iframe/server.mjs',url:host,reuseExistingServer:!process.env.CI},
  use:{...acceptance.use,video:'off'},
});
