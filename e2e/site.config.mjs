import {defineConfig} from '@playwright/test';
export default defineConfig({testDir:'./site',workers:1,retries:0,
  webServer:process.env.CSIM_DESIGN_URL?undefined:{command:'python3 -m http.server 18780 --bind 127.0.0.1 --directory ../design',url:'http://127.0.0.1:18780',reuseExistingServer:!process.env.CI},
  use:{baseURL:process.env.CSIM_DESIGN_URL||'http://127.0.0.1:18780',video:'off',trace:'off',screenshot:'only-on-failure'},
  outputDir:'../output/site-results',reporter:[['list'],['json',{outputFile:'../output/site-results.json'}]]});
