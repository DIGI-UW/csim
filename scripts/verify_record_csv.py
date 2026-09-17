"""Compare all CSV fields and preserve duplicate rows and repeat identifiers."""
import collections,csv,json,sys
from decimal import Decimal
from pathlib import Path
expected=json.loads(Path(sys.argv[1]).read_text())
with open(sys.argv[2],newline='',encoding='utf-8-sig') as f:
    reader=csv.DictReader(f); columns=reader.fieldnames; actual=list(reader)
assert set(columns)==set(expected['columns']),(columns,expected['columns'])
numeric={'record_ID','redcap_repeat_instance','hospital_code','submitted_month','submitted_year','location_code','qi_asb_complete','sign_symp','ucx_positive','urinalysis','tx___1','duration'}
def key(row):
    values=[]
    for col in sorted(columns):
        value=row[col]
        if value is None or value in ('','null','None','NaN'):value=None
        elif col in numeric:value=Decimal(str(value))
        elif col=='reporting_month':value=str(value).split('T')[0].split(' ')[0]
        values.append(value)
    return tuple(values)
assert collections.Counter(map(key,actual))==collections.Counter(map(key,expected['rows'])),'CSV rows differ from the verified record view'
print(json.dumps({'rows':len(actual),'columns':len(columns),'allValuesMatch':True,'duplicatesPreserved':True}))
