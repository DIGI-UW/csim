import {waitForChartPaint} from './dashboard.mjs';
import {recording} from '../acceptance.config.mjs';

// Screenshots are taken only after the workflow assertion that they explain.
export async function scene(page,info,name,chapter,caption,majorBreak){
  await page.mouse.move(5,5);
  if(recording)await page.waitForTimeout(1800);
  await waitForChartPaint(page);
  const file=info.outputPath(`${name}.png`);
  await page.screenshot({path:file});
  await info.attach(name,{path:file,contentType:'image/png'});
  (info._csimScenes ||= []).push({name,chapter,caption,majorBreak,atSeconds:(Date.now()-info._csimStart)/1000});
}
export function enableRecording(test){
  test.beforeEach(async({},info)=>{info._csimStart=Date.now();info._csimScenes=[];});
  test.afterEach(async({},info)=>{
    if(recording&&info._csimScenes.length)await info.attach('video-scenes',{body:Buffer.from(JSON.stringify({scenes:info._csimScenes})),contentType:'application/json'});
  });
}
