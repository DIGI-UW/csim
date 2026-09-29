"""Record and verify the real saved record-review CSV workflow on the demo.

Requires the saved review chart and its demo sources already installed. The
source-oracle check uses an isolated fixture transaction and rolls it back.
Neither chart nor reporting source definitions are edited by this recorder.
"""
import argparse,datetime,hashlib,json,os,shutil,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--output',type=Path,default=ROOT/'output/recordings/record-export')
p.add_argument('--base-url',default='http://127.0.0.1:18194')
p.add_argument('--container',default='csim-standard-superset-1')
a=p.parse_args()
run=a.output.resolve();run.mkdir(parents=True,exist_ok=True)
# Run the established independent source/aggregate checks immediately before
# recording; the browser then validates its actual CSV against this oracle.
subprocess.run(['docker','exec',a.container,'python','/repro/scripts/test_record_review.py'],check=True)
env=dict(os.environ,CSIM_PROFILE='standard',CSIM_NATIVE_DATES='1',CSIM_RECORD='1',CSIM_DASHBOARD_SLUG='csim-individual-standard-month-selectors',CSIM_BASE_URL=a.base_url,CSIM_OUTPUT=str(run),CSIM_ORACLE_CONTAINER=a.container)
revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip()
testfile=ROOT/'e2e/record-review-video/download.spec.mjs'
provenance={'timestamp':datetime.datetime.now(datetime.timezone.utc).isoformat(),'revision':revision,'baseURL':a.base_url,'target':'saved Individual records — Review and download chart','profile':'supplied-demo','testSha256':hashlib.sha256(testfile.read_bytes()).hexdigest(),'clientInstallationVerified':False}
(run/'provenance.json').write_text(json.dumps(provenance,indent=2))
subprocess.run(['npx','playwright','test','-c','record-review-video.config.mjs'],cwd=ROOT/'e2e',env=env,check=True)
verification=json.loads(next((run/'results').glob('*/csv-verification.json')).read_text())
assert verification['allValuesMatch'] and verification['duplicatesPreserved']
summary=f"The downloaded CSV contains {verification['rows']:,} individual records and {verification['columns']} columns. Current and Historical identifiers are preserved. Repeat after the next upload: open this chart, Update chart, Export All Data."
guide={'13':{'label':'Download individual records','try':'Review and download Current and Historical records.','expected':summary,'videoIntro':'Current and Historical records in one CSV, including record identifiers. Official Superset 6.1.0 demonstration with demo data.','videoOutro':summary}}
(run/'workflow-guide.json').write_text(json.dumps(guide,indent=2))
(run/'publication.json').write_text(json.dumps({'workflowIds':['13']}))
subprocess.run(['uv','run','--with-requirements',str(ROOT/'e2e/video/requirements.txt'),'python',str(ROOT/'e2e/video/render.py'),str(run)],cwd=ROOT,check=True)
shutil.copyfile(run/'films/workflow-13.mp4',run/'record-export.mp4')
shutil.copyfile(run/'films/workflow-13.vtt',run/'captions.vtt')
shutil.copyfile(run/'films/13/encoded-00.png',run/'poster.png')
print(json.dumps({'video':str(run/'record-export.mp4'),'captions':str(run/'captions.vtt'),'poster':str(run/'poster.png'),'csvVerification':verification,'filmValidation':str(run/'films/13/validation.json')},indent=2))
