"""Compare every exported aggregate value with an independent full SQL result."""
import csv,json,math,sys
from pathlib import Path
expected=json.loads(Path(sys.argv[1]).read_text())
with open(sys.argv[2],newline='',encoding='utf-8-sig') as file:
    reader=csv.DictReader(file)
    columns=reader.fieldnames
    actual=list(reader)
assert set(columns)==set(expected['columns']), (columns,expected['columns'])
assert len(actual)==expected['rowCount'], (len(actual),expected['rowCount'])
def date(value):
    return str(value).replace('T',' ').split(' ')[0]
def key(row):
    return (row['hosp_code'],str(int(float(row['location_code']))),date(row['month_date']))
actual_by_key={key(row):row for row in actual}
assert len(actual_by_key)==len(actual), 'Unexpected duplicate aggregate keys'
for row in expected['rows']:
    found=actual_by_key[key(row)]
    for column,value in row.items():
        observed=found[column]
        if value is None:
            assert observed in ('','null','None','NaN'), (key(row),column,observed)
        elif column=='month_date':
            assert date(value)==date(observed)
        elif isinstance(value,(int,float)):
            assert math.isclose(float(observed),value,rel_tol=1e-10,abs_tol=1e-12), (key(row),column,value,observed)
        else:
            assert str(value)==observed, (key(row),column,value,observed)
print(json.dumps({'rows':len(actual),'columns':len(columns),'allValuesMatch':True}))
