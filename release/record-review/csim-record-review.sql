-- One row per uploaded submission. This view does not change reporting totals.
-- UNION ALL preserves repeats and records that appear in both source files.
WITH uploaded AS (
  SELECT 'Current'::text AS source, record_id AS "record_ID",
         redcap_repeat_instance, redcap_repeat_instrument,
         hosp_name, location, month, year, qi_asb_complete,
         sign_symp, ucx_positive, urinalysis, tx___1, duration
  FROM v1."UTI Individual Current"
  UNION ALL
  SELECT 'Historical', record_id, NULL::bigint, NULL::text,
         hosp_name, location, month, year, NULL::bigint,
         sign_symp, ucx_positive, urinalysis, tx___1, duration
  FROM v1."UTI Individual Historical 2024-2025"
), reviewed AS (
  SELECT u.*, h.hosp AS hospital_name, TRIM(h.state) AS state,
         CASE WHEN u.month::int BETWEEN 1 AND 12 AND u.year::int BETWEEN 1 AND 9999
              THEN make_date(u.year::int, u.month::int, 1) END AS reporting_month,
         concat_ws('; ',
           CASE WHEN u.hosp_name IS NULL THEN 'Missing hospital code'
                WHEN h.hosp_code IS NULL THEN 'Hospital missing from lookup' END,
           CASE WHEN u.source = 'Current' AND u.qi_asb_complete IS DISTINCT FROM 2
                THEN 'Current record is not complete' END,
           CASE WHEN u.month IS NULL OR u.year IS NULL THEN 'Missing reporting month or year'
                WHEN NOT (u.month::int BETWEEN 1 AND 12 AND u.year::int BETWEEN 1 AND 9999)
                THEN 'Invalid reporting month or year' END
         ) AS review_note
  FROM uploaded u
  LEFT JOIN v1."CSiM Hospitals and States" h ON h.hosp_code = u.hosp_name
)
SELECT source, "record_ID", redcap_repeat_instance, redcap_repeat_instrument,
       hosp_name AS hospital_code, hospital_name, state, reporting_month,
       month AS submitted_month, year AS submitted_year,
       location AS location_code,
       CASE location WHEN 1 THEN 'Ambulatory care clinic' WHEN 2 THEN 'Emergency Department'
         WHEN 3 THEN 'Inpatient' WHEN 4 THEN 'Rehab or long-term care'
         WHEN 5 THEN 'Urgent or quick care' WHEN 6 THEN 'Other'
         ELSE 'Unspecified' END AS location_name,
       CASE WHEN review_note = '' THEN 'Included' ELSE 'Excluded' END AS reporting_status,
       CASE WHEN review_note = '' THEN 'Contributes before dashboard date and population filters'
            ELSE review_note END AS review_note,
       qi_asb_complete, sign_symp, ucx_positive, urinalysis, tx___1, duration
FROM reviewed
