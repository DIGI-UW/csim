// Validate a generated or published evidence artifact; never record website video.
import {chromium} from '@playwright/test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
const url=process.env.CSIM_EVIDENCE_URL||'http://127.0.0.1:18780/evidence/current/';
const out=process.env.CSIM_OUTPUT||'../output/evidence-smoke';await fs.mkdir(out,{recursive:true});
const browser=await chromium.launch();
try{
 const page=await browser.newPage({viewport:{width:1280,height:1000}});
 await page.goto(url);await page.getByRole('heading',{level:1,name:'CSiM dashboard workflows'}).waitFor();
 const videos=page.locator('video');assert.equal(await videos.count(),6);
 const result=[];
 for(let i=0;i<6;i++){
  const video=videos.nth(i);await video.scrollIntoViewIfNeeded();
  await video.evaluate(el=>{el.muted=true;el.load();});
  await page.waitForFunction(i=>{const v=document.querySelectorAll('video')[i];return v.readyState>=2&&v.duration>30;},i);
  await video.evaluate(el=>el.play());await page.waitForFunction(i=>document.querySelectorAll('video')[i].currentTime>0.2,i);await video.evaluate(el=>{el.pause();el.currentTime=2;});
  await page.waitForFunction(i=>{const v=document.querySelectorAll('video')[i];return !v.seeking&&v.readyState>=2&&v.currentTime>=2;},i);
  result.push(await video.evaluate(el=>({source:el.querySelector('source').src,duration:el.duration,decoded:true})));
 }
 for(const width of [1280,390]){
  await page.setViewportSize({width,height:1000});await page.evaluate(()=>scrollTo(0,0));
  assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
  await page.screenshot({path:`${out}/evidence-${width}.png`});
 }
 const manifest=await page.request.get(new URL('validation.json',url).href);assert(manifest.ok());
 const data=await manifest.json();assert.equal(data.xAxisScreenshots,99);
 await fs.writeFile(`${out}/playback.json`,JSON.stringify({url,videos:result,xAxisScreenshots:99},null,2));
 console.log('Six videos decode and play; desktop/mobile layout and 99-screenshot manifest pass.');
}finally{await browser.close();}
