import fs from 'node:fs';
import {test,expect} from '@playwright/test';
import {openDashboard,hospital,timeUnit,waitForChartPaint} from './dashboard.mjs';

// The expected colors come directly from Yao's unchanged April export, not
// from the generated dashboard or the current Superset color assignments.
const april=fs.readFileSync('../sources/exports/april-2026/unpacked/dashboard_export_20260423T185803/dashboards/CSiM_UTI_ASB_Dashboard_Individual_Data_11.yaml','utf8');
const palette={};
for(const line of april.split('  label_colors:\n')[1].split(/\n  \S/)[0].split('\n')){
  const match=/^    (.*?): ['"]?(#[\dA-Fa-f]{6})['"]?$/.exec(line);
  if(match)palette[match[1].replace(/^['"]|['"]$/g,'')]=match[2].toLowerCase();
}

async function canvasColors(plot){
  return plot.locator('canvas').evaluateAll(canvases=>{
    const counts={};
    for(const canvas of canvases){
      const pixels=canvas.getContext('2d').getImageData(0,0,canvas.width,canvas.height).data;
      for(let i=0;i<pixels.length;i+=4){
        if(pixels[i+3]!==255)continue;
        const key='#'+[pixels[i],pixels[i+1],pixels[i+2]].map(n=>n.toString(16).padStart(2,'0')).join('');
        counts[key]=(counts[key]||0)+1;
      }
    }
    return counts;
  });
}

test('Yao April colors survive hospital context and Month Quarter Year',async({page},info)=>{
  test.skip(process.env.CSIM_NATIVE_DATES!=='1','Current official dashboard only');
  test.setTimeout(240000);
  expect(palette.Ceftriaxone).toBe('#1a5276');
  expect(palette['>7 days']).toBe('#990000');
  const watch=await openDashboard(page,'standard');
  const cases=[];
  for(const selection of [{hospital:'53',comparison:'Cohort'},{hospital:'31',comparison:'OR'}]){
    const mainPopulation=selection.hospital==='53'?'Cohort':selection.hospital;
    await hospital(page,mainPopulation);
    await hospital(page,selection.hospital,'NATIVE_FILTER-PsH68K-xwsp1NWi3i2HxI');
    await hospital(page,selection.comparison,'NATIVE_FILTER-E7fn9Wg9JfYAppl0ZHbXG');
    for(const grain of ['Month','Quarter','Year']){
      await timeUnit(page,grain);
      for(const chart of watch.dateAxes){
        await chart.holder.scrollIntoViewIfNeeded();
        await expect.poll(()=>watch.replies.get(chart.id)?.result?.status).toBe('success');
        await waitForChartPaint(chart.plot);
        const result=watch.replies.get(chart.id).result;
        const series=Object.keys(result.data[0]||{}).filter(key=>key!=='period_label'&&key!=='month_date');
        const expected=series.filter(key=>result.data.some(row=>Number(row[key])>0)).map(key=>{
          const labels=Object.keys(palette).filter(label=>watch.trends.includes(chart)||!(/^[0-9]+$|^[A-Z]{2,}$/.test(label)||label==='Cohort'));
          const category=labels.find(label=>key===label||key.endsWith(', '+label)||key.startsWith(label+', '));
          expect(category,`${chart.name}: color assignment for ${key}`).toBeTruthy();
          return {series:key,color:palette[category]};
        });
        const painted=await canvasColors(chart.plot);
        const caseResult={chart:chart.name,...selection,mainPopulation,grain,expected,actual:expected.map(e=>({...e,pixels:painted[e.color]||0}))};
        cases.push(caseResult);
        await chart.holder.screenshot({path:info.outputPath(`${selection.hospital}-${grain}-${chart.id}.png`)});
        fs.writeFileSync(info.outputPath('palette-comparison.json'),JSON.stringify(cases,null,2));
        for(const color of new Set(expected.map(item=>item.color))){
          expect(painted[color]||0,`${chart.name}: ${color} from April must appear in rendered pixels`).toBeGreaterThan(5);
        }
      }
    }
  }
  expect(cases).toHaveLength(66);
  expect(watch.failures).toEqual([]);
});
