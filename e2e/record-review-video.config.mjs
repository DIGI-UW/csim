import {defineConfig} from '@playwright/test';
process.env.CSIM_PROFILE ||= 'standard';
process.env.CSIM_NATIVE_DATES ||= '1';
process.env.CSIM_DASHBOARD_SLUG ||= 'csim-individual-standard-month-selectors';
const {default:acceptance}=await import('./acceptance.config.mjs');
export default defineConfig({...acceptance,testDir:'./record-review-video'});
