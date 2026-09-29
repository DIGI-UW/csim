"""Read-only calendar and range checks through native Superset SQL templating."""
from datetime import datetime
import json
import os
from pathlib import Path
from unittest.mock import patch

import psycopg2
import yaml
from superset.app import create_app
from superset.jinja_context import get_template_processor

ROOT = Path(__file__).resolve().parents[1]


def main():
    app = create_app()
    definition = yaml.safe_load((ROOT / 'dashboard/standard-month-selectors-examples/datasets/PostgreSQL/Reporting_period.yaml').read_text())
    cases = [
        ('January rollover', '2027-01-15', '12 months ago', 'Last complete month', 'P1M', 'Jan 2026', 'Dec 2026', False),
        ('Leap-year March', '2024-03-20', '12 months ago', 'Last complete month', 'P1M', 'Mar 2023', 'Feb 2024', False),
        ('Next calendar month', '2026-10-01', '12 months ago', 'Last complete month', 'P1M', 'Oct 2025', 'Sep 2026', False),
        ('Explicit year boundary', '2026-09-15', '2025-12', '2026-01', 'P1M', 'Dec 2025', 'Jan 2026', False),
        ('One inclusive month', '2026-09-15', '2024-02', '2024-02', 'P1M', 'Feb 2024', 'Feb 2024', False),
        ('Reversed selection', '2026-09-15', '2026-05', '2026-04', 'P1M', 'May 2026', 'Apr 2026', True),
        ('Partial quarter', '2026-09-15', '2026-02', '2026-03', 'P3M', 'Feb 2026', 'Mar 2026', False),
        ('Partial year', '2026-09-15', '2026-02', '2026-03', 'P1Y', 'Feb 2026', 'Mar 2026', False),
        ('No date limits', '2026-09-15', None, None, 'P1M', 'No start limit', 'No end limit', False),
    ]
    results = []
    with app.app_context():
        from superset import db
        from superset.connectors.sqla.models import SqlaTable
        table = db.session.query(SqlaTable).filter_by(uuid=definition['uuid']).one()
        with psycopg2.connect(host='db', user='csim', password=os.environ['CSIM_DB_PASSWORD'], dbname='csim_fixture') as connection:
            connection.set_session(readonly=True)
            for name, today, start, end, grain, expected_from, expected_through, invalid in cases:
                now = datetime.fromisoformat(today)
                filters = [{'expressionType':'SIMPLE', 'subject':column, 'operator':'IN', 'comparator':[value], 'clause':'WHERE'}
                           for column, value in [('from_month',start),('through_month',end)] if value]
                # Replace only the clock-dependent relative-date boundary. The
                # native filter macros, template sandbox and database execute normally.
                def relative_boundary(value):
                    assert value == 'Last month', value
                    return now, now
                cache_keys = []
                with app.test_request_context(), patch('superset.views.utils.get_form_data', return_value=({'adhoc_filters':filters}, {})), patch('superset.jinja_context.get_since_until_from_time_range', side_effect=relative_boundary):
                    processor = get_template_processor(database=table.database, table=table, time_grain=grain, extra_cache_keys=cache_keys)
                    query = processor.process_template(table.sql)
                with connection.cursor() as cursor:
                    cursor.execute(query)
                    rows = cursor.fetchall()
                    assert len(rows) == 1, name
                    row = dict(zip([c.name for c in cursor.description], rows[0]))
                assert (row['From'],row['Through']) == (expected_from,expected_through), (name,row)
                assert row['Group by'] == {'P1M':'Month','P3M':'Quarter','P1Y':'Year'}[grain], (name,row)
                assert ('selected range is reversed' in row['Status']) == invalid, (name,row)
                if grain != 'P1M':
                    assert 'Only the selected months contribute' in row['Status'], (name,row)
                assert now.replace(day=1).strftime('%Y-%m-%d 00:00:00') in cache_keys, (name,cache_keys)
                results.append({'case':name, 'from':row['From'], 'through':row['Through'], 'grouping':row['Group by'], 'invalidRange':invalid})
    print(json.dumps({'status':'PASS','cases':results}, indent=2))


if __name__ == '__main__':
    main()
