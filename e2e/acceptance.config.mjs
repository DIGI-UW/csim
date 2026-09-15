import fs from 'node:fs';
import path from 'node:path';
import { defineConfig } from '@playwright/test';
export const profile=process.env.CSIM_PROFILE || 'corrected';
export const root=path.resolve('..');
export const fixture=process.env.CSIM_DATA_PROFILE==='edge-cases'||profile.includes('fixture');
export const reconciled=process.env.CSIM_DASHBOARD_SLUG?.startsWith('csim-reconciled') || process.env.CSIM_DASHBOARD_SLUG?.startsWith('csim-individual-reconciled') || ['standard','development'].includes(profile);
export const chartCount=process.env.CSIM_NATIVE_MONTHS==='1'?22:reconciled?21:20;
export const recording=process.env.CSIM_RECORD==='1';
const profiles=JSON.parse(fs.readFileSync(path.join(root,'data/profiles.json'),'utf8'));
export const dataProfile=profiles[fixture?'edge-cases':'supplied-demo'];
export const openingHospital=process.env.CSIM_DASHBOARD_SLUG?.includes('examples')?profiles['edge-cases'].openingHospital:profiles['supplied-demo'].openingHospital;
export const env=Object.fromEntries(fs.readFileSync(process.env.CSIM_ENV_FILE || path.join(root,`.env.${profile}`),'utf8').trim().split('\n').map(line=>[line.split('=')[0],line.slice(line.indexOf('=')+1)]));
export const baseURL=process.env.CSIM_BASE_URL || `http://127.0.0.1:${env.CSIM_PORT}`;
export const directory=process.env.CSIM_OUTPUT || path.join(root,'output','acceptance',profile);
export const authFile=path.join(directory,'.auth.json');
export default defineConfig({
  testDir:'./acceptance',globalSetup:'./acceptance/setup.mjs',
  workers:1,retries:0,forbidOnly:!!process.env.CI,timeout:240000,
  expect:{timeout:30000},outputDir:path.join(directory,'results'),
  reporter:[['list'],['json',{outputFile:path.join(directory,'results.json')}]],
  use:{baseURL,storageState:authFile,viewport:{width:1600,height:1100},actionTimeout:20000,navigationTimeout:60000,video:recording?{mode:'on',size:{width:1600,height:1100}}:'off',trace:'off',screenshot:'only-on-failure'},
});
