import {expect} from '@playwright/test';
export const trendNames=[
  'Inappropriate UTI diagnosis (time series)',
  'Inappropriate UTI+ASPN diagnosis (time series)',
  'Positive UA (time series)',
  'Therapy duration (time series)',
  'UC submissions (time series)',
];
export const filters={hospital:'NATIVE_FILTER-yTQKvlEARkQ8t2O7SfLEE',grain:'NATIVE_FILTER-KyTwDhtSKTATUbbB9Yka_'};
export async function openDashboard(page,profile='corrected') {
  const replies=new Map(),failures=[],jobs=new Set();
  page.on('response',response=>{
    if(!response.url().includes('/api/v1/chart/data'))return;
    const job=(async()=>{
      try{
        const request=response.request().postDataJSON();
        const id=request?.form_data?.slice_id;
        const body=await response.json();
        if(!response.ok()||body.result?.some(r=>r.error))failures.push({id,status:response.status(),body});
        if(id)replies.set(id,{request,result:body.result?.[0]});
      }catch(error){if(!/No resource|No data found|aborted/i.test(error.message))failures.push({error:error.message});}
    })();jobs.add(job);job.finally(()=>jobs.delete(job));
  });
  await page.addInitScript(()=>{
    const proto=CanvasRenderingContext2D.prototype,fill=proto.fillText,clear=proto.clearRect;
    proto.clearRect=function(...args){if(args[0]===0&&args[1]===0)this.canvas.__periodLabels=[];return clear.apply(this,args);};
    proto.fillText=function(text,x,y,...rest){
      if(/^(?:\d{4}|Q[1-4] \d{4}|[A-Z][a-z]{2} \d{4})$/.test(String(text))){
        const point=new DOMPoint(x,y).matrixTransform(this.getTransform());
        (this.canvas.__periodLabels ||= []).push({text:String(text),x:point.x,y:point.y});
      }return fill.call(this,text,x,y,...rest);
    };
  });
  await page.goto(`/superset/dashboard/csim-individual-${profile.startsWith('preview')?'preview':profile==='baseline'?'baseline':'corrected'}/`);
  await expect(page.getByRole('button',{name:'Apply filters',exact:true})).toBeVisible();
  const links=page.locator('a[href*="slice_id="]');
  await expect(links).toHaveCount(20);
  await page.waitForLoadState('networkidle');
  const trends=[];
  for(const name of trendNames){
    const link=page.getByRole('link',{name,exact:true});
    const href=await link.getAttribute('href');
    const id=Number(new URL(href,'http://local').searchParams.get('slice_id'));
    trends.push({name,id,plot:page.locator(`#chart-id-${id}`),holder:page.locator('[data-test=dashboard-component-chart-holder]').filter({has:link})});
  }
  return {trends,replies,failures,settle:()=>Promise.all([...jobs])};
}
export async function timeUnit(page,name){
  const control=page.getByRole('combobox',{name:filters.grain,exact:true});
  const current=await control.evaluate(el=>el.closest('[title]')?.getAttribute('title') || el.closest('.ant-select').querySelector('.ant-select-selection-item')?.getAttribute('title'));
  if(current===name)return;
  await control.press('ArrowDown');
  await page.getByRole('option',{name,exact:true}).click();
  await page.getByRole('button',{name:'Apply filters',exact:true}).click();
  await page.waitForLoadState('networkidle');
}
export async function timePeriod(page,from,until){
  await page.getByRole('button',{name:'Time Period',exact:true}).click();
  const editor=page.getByRole('tooltip').filter({hasText:'Edit time range'});
  await editor.getByRole('combobox',{name:'Range type',exact:true}).press('ArrowDown');
  await page.getByRole('option',{name:'Advanced',exact:true}).click();
  const boxes=editor.getByRole('textbox');
  await boxes.nth(0).fill(from);
  await boxes.nth(1).fill(until);
  await editor.getByRole('button',{name:/^apply$/i}).click();
  await page.getByRole('button',{name:'Apply filters',exact:true}).click();
  await page.waitForLoadState('networkidle');
}
export async function paintedLabels(plot){
  return plot.locator('canvas').evaluateAll(canvases=>{
    const unique=new Map(canvases.flatMap(c=>c.__periodLabels||[]).map(label=>[label.text,label]));
    return [...unique.values()].sort((a,b)=>a.x-b.x).map(label=>label.text);
  });
}

export async function hospital(page,name){
  const control=page.getByRole('combobox',{name:filters.hospital,exact:true});
  const remove=control.locator('xpath=ancestor::*[contains(concat(" ",normalize-space(@class)," ")," ant-select ")][1]').locator('.ant-select-selection-item-remove');
  while(await remove.count())await remove.first().click();
  if(await control.getAttribute('aria-expanded') !== 'true')await control.press('ArrowDown');
  await page.locator('.ant-select-dropdown:visible').getByTitle(name,{exact:true}).click();
  await control.press('Escape');
  await page.getByRole('button',{name:'Apply filters',exact:true}).click();
  await page.waitForLoadState('networkidle');
}
export async function allTrends(watch){
  const rows={};
  for(const trend of watch.trends){
    await trend.holder.scrollIntoViewIfNeeded();
    await expect.poll(()=>watch.replies.get(trend.id)?.result).toBeTruthy();
    await watch.settle();
    rows[trend.name]=watch.replies.get(trend.id).result.data;
  }
  return rows;
}

export async function location(page,name){
  const control=page.getByRole('combobox',{name:'NATIVE_FILTER-BPP7wo77GPPbinIYZiwM8',exact:true});
  await control.press('ArrowDown');
  await page.getByRole('option',{name,exact:true}).click();
}
