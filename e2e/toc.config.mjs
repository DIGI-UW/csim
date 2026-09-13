import {defineConfig} from '@playwright/test';
import acceptance from './acceptance.config.mjs';

// Section navigation is regression evidence, never a published workflow video.
export default defineConfig({...acceptance,testDir:'./navigation',use:{...acceptance.use,video:'off'}});
