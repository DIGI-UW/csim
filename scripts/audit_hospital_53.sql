-- Read-only source reconciliation for the hospital shown in Beth's September 11 screenshot.
-- Run against the supplied demo database, not a production connection.
-- Counts describe this input; they do not make the disputed client total an accepted rule.
BEGIN READ ONLY;
SELECT jsonb_build_object(
  'hospital', 53,
  'historical', (
    SELECT jsonb_build_object(
      'rows', count(*),
      'distinct_record_ids', count(DISTINCT record_id),
      'distinct_rows', count(DISTINCT to_jsonb(h)),
      'rows_with_reporting_month', count(*) FILTER (WHERE month IS NOT NULL AND year IS NOT NULL),
      'first_month', min(make_date(year::int, month::int, 1)),
      'last_month', max(make_date(year::int, month::int, 1))
    ) FROM v1."UTI Individual Historical" h WHERE hosp_name = 53
  ),
  'historical_2024_2025', (
    SELECT jsonb_build_object('rows', count(*), 'distinct_record_ids', count(DISTINCT record_id))
    FROM v1."UTI Individual Historical 2024-2025" WHERE hosp_name = 53
  ),
  'current', (
    SELECT jsonb_build_object('rows', count(*), 'complete_rows', count(*) FILTER (WHERE qi_asb_complete = 2))
    FROM v1."UTI Individual Current" WHERE hosp_name = 53
  ),
  'historical_by_year', (
    SELECT jsonb_object_agg(year::text, n) FROM (
      SELECT year, count(*) n FROM v1."UTI Individual Historical" WHERE hosp_name = 53 GROUP BY year
    ) counts
  )
);
ROLLBACK;
