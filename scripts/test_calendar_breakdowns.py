#!/usr/bin/env python3
"""Read-only numerical checks against both initialized local demo databases.

Compare every observed row with the original dataset SQL, including its ranking
and counts. Calendar rows may add NULL measures but must not change observations.
Run inside a CSiM Superset container after examples-init.
"""
from collections import Counter
from datetime import date
import json
import os
from pathlib import Path
from types import SimpleNamespace

from jinja2 import Environment, StrictUndefined
import psycopg2
import yaml


ROOT = Path(__file__).resolve().parents[1]
DATASETS = {
    "UTI_Top_Abx_-_Ind_37.yaml": "prescription_count",
    "UTI_Location_-_Ind_38.yaml": "n_submissions",
}


def months(start, end):
    current = date.fromisoformat(start).replace(day=1)
    stop = date.fromisoformat(end)
    while current < stop:
        yield current
        current = date(current.year + (current.month == 12), current.month % 12 + 1, 1)


def read_sql(profile, filename):
    path = ROOT / "dashboard" / profile / "datasets" / "PostgreSQL" / filename
    return yaml.safe_load(path.read_text())["sql"].strip().rstrip(";")


def check(connection, filename, measure, start, end):
    original = read_sql("corrected", filename)
    template = Environment(undefined=StrictUndefined).from_string(read_sql("reconciled", filename))
    corrected = template.render(
        from_dttm=start, to_dttm=end,
        get_time_filter=lambda *_args, **_kwargs: SimpleNamespace(from_expr=start, to_expr=end),
    )
    with connection.cursor() as cursor:
        cursor.execute(
            f"SELECT * FROM ({original}) original WHERE month_date >= %s AND month_date < %s",
            (start, end),
        )
        columns = [column.name for column in cursor.description]
        before = cursor.fetchall()
        cursor.execute(corrected)
        assert [column.name for column in cursor.description] == columns, filename
        after = cursor.fetchall()
    measure_index = columns.index(measure)
    month_index = columns.index("month_date")
    observed_after = [row for row in after if row[measure_index] is not None]
    assert Counter(observed_after) == Counter(before), (
        filename, start, "observation or rank changed",
        {"removed": list((Counter(before) - Counter(observed_after)).items())[:3],
         "added": list((Counter(observed_after) - Counter(before)).items())[:3]},
    )
    dimension_indices = [columns.index(name) for name in (
        ["hosp_code", "location_code", "antibiotic_name"]
        if "antibiotic_name" in columns else ["hosp_code", "location_code"]
    )]
    dimensions = {tuple(row[i] for i in dimension_indices) for row in before}
    actual_keys = Counter((tuple(row[i] for i in dimension_indices), row[month_index]) for row in after)
    expected_keys = Counter((dimension, month) for dimension in dimensions for month in months(start, end))
    assert actual_keys == expected_keys, (filename, start, "calendar missing or duplicate period")
    null_rows = [row for row in after if row[measure_index] is None]
    if "rnk" in columns:
        assert all(row[columns.index("rnk")] is None for row in null_rows), "invented rank"
    # Exact row equality above also covers every grouped total, not just a count.
    return {"dataset": filename, "window": [start, end], "observedRows": len(before),
            "nullCalendarRows": len(null_rows), "observationsUnchanged": True,
            "calendarComplete": True}


def main():
    results = []
    for database, windows in {
        "csim_demo": [("2025-09-01", "2026-10-01"), ("2026-02-01", "2026-04-01")],
        "csim_fixture": [("2025-11-01", "2026-05-01"), ("2026-02-01", "2026-04-01")],
    }.items():
        with psycopg2.connect(host="db", user="csim", password=os.environ["CSIM_DB_PASSWORD"], dbname=database) as connection:
            connection.set_session(readonly=True)
            for start, end in windows:
                for filename, measure in DATASETS.items():
                    results.append({"database": database, **check(connection, filename, measure, start, end)})
    assert any(item["nullCalendarRows"] for item in results), "missing-period case not exercised"
    print(json.dumps({"status": "PASS", "cases": results}, indent=2))


if __name__ == "__main__":
    main()
