import fs from 'node:fs';
import {test,expect} from '@playwright/test';
import {profile,dataProfile} from '../acceptance.config.mjs';
import {openDashboard,timePeriod,timeUnit,hospital,allTrends,paintedPeriodBounds,waitForChartPaint} from './dashboard.mjs';

// This is an observation run, not a passing exact-format acceptance claim.
// Every required label/layout discrepancy is retained in the machine-readable report.
test('Official dashboard checks all eleven date axes across groupings and widths',async({page},info)=>{
  test.skip(!['standard','development'].includes(profile));
  test.setTimeout(600000);
  const watch=await openDashboard(page,profile);
  await timePeriod(page,'2025-09-01','2026-10-01');
  await hospital(page,'Cohort');
  await hospital(page,dataProfile.openingHospital,'NATIVE_FILTER-PsH68K-xwsp1NWi3i2HxI');
  const cases=[];
  for(const width of [1024,1280,1600]){
    await page.setViewportSize({width,height:1100});
    for(const grain of ['Month','Quarter','Year']){
      await timeUnit(page,grain);await allTrends(watch);
      for(const chart of watch.dateAxes){
        await chart.holder.scrollIntoViewIfNeeded();await watch.settle();
        await expect.poll(()=>watch.replies.get(chart.id)?.result).toBeTruthy();
        const result=watch.replies.get(chart.id).result;
        expect(result.error,chart.name).toBeNull();
        await waitForChartPaint(chart.plot);
        const bounds=await paintedPeriodBounds(chart.plot);
        // Decode the candidate's buckets to retain the ORIGINAL expected wording
        // below. Year-first labels must be reported as gaps, never accepted here.
        const dates=result.data.map(row=>{
          if(row.month_date!==undefined)return Number(row.month_date);
          const match=/^(\d{4})(?:-(\d{2})| Q([1-4]))?/.exec(row.period_label||'');
          return match?Date.UTC(Number(match[1]),match[2]?Number(match[2])-1:match[3]?(Number(match[3])-1)*3:0,1):NaN;
        }).filter(Number.isFinite);
        const expected=[];
        if(dates.length){
          const cursor=new Date(Math.min(...dates)),last=Math.max(...dates);
          while(cursor.getTime()<=last){
            const year=cursor.getUTCFullYear();
            expected.push(grain==='Year'?String(year):grain==='Quarter'?`Q${Math.floor(cursor.getUTCMonth()/3)+1} ${year}`:new Intl.DateTimeFormat('en-US',{month:'short',year:'numeric',timeZone:'UTC'}).format(cursor));
            cursor.setUTCMonth(cursor.getUTCMonth()+({Month:1,Quarter:3,Year:12}[grain]));
          }
        }
        const actual=bounds.map(item=>item.text);
        const issues=[];
        if(JSON.stringify(actual)!==JSON.stringify(expected))issues.push('Exact period wording or complete tick list differs');
        bounds.forEach((item,index)=>{
          if(item.left<8||item.right>item.canvasWidth-8||item.top<0||item.bottom>item.canvasHeight-8)issues.push(`Clipped or crowded edge: ${item.text}`);
          if(index&&item.left-bounds[index-1].right<3)issues.push(`Overlapping or crowded labels: ${bounds[index-1].text} / ${item.text}`);
        });
        const screenshot=info.outputPath(`${width}-${grain}-${chart.id}.png`);
        await chart.holder.screenshot({path:screenshot});
        cases.push({width,grain,chart:chart.name,expected,actual,bounds,issues,screenshot,rows:result.data});
      }
    }
  }
  expect(watch.failures).toEqual([]);
  expect(cases).toHaveLength(99);
  const supportedOfficial=process.env.CSIM_NATIVE_MONTHS==='1'||process.env.CSIM_NATIVE_DATES==='1';
  const supportedGaps=cases.flatMap(item=>item.issues.filter(issue=>issue!=='Exact period wording or complete tick list differs'));
  const report={application:'unmodified',profile,
    labelContract:supportedOfficial?'year-first labels: YYYY-MM, YYYY Qn, YYYY':'month-name-first comparison',
    acceptance:supportedOfficial?(supportedGaps.length?'GAPS':'PASS'):(cases.some(c=>c.issues.length)?'GAPS':'PASS'),cases};
  fs.writeFileSync(info.outputPath('native-label-comparison.json'),JSON.stringify(report,null,2));
  await info.attach('native-label-comparison',{body:Buffer.from(JSON.stringify(report)),contentType:'application/json'});
  if(supportedOfficial){
    // Enforce the official option's documented wording and geometry separately
    // from the original month-name-first acceptance comparison above.
    for(const item of cases){
      const supported=item.expected.map(label=>{
        if(item.grain==='Year')return label;
        if(item.grain==='Quarter'){const [quarter,year]=label.split(' ');return `${year} ${quarter}`;}
        const [month,year]=label.split(' ');
        const number=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'].indexOf(month)+1;
        return `${year}-${String(number).padStart(2,'0')}`;
      });
      expect(item.actual,`${item.chart}, ${item.grain}, ${item.width}px: every supported period label`).toEqual(supported);
      expect(item.issues.filter(issue=>issue!=='Exact period wording or complete tick list differs'),
        `${item.chart}, ${item.grain}, ${item.width}px: label geometry`).toEqual([]);
    }
  }
});
