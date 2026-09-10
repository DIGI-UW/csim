WITH raw_data AS (
    SELECT
        hosp_name, location, month, year
    FROM "v1"."UTI Individual Current"
    WHERE hosp_name IS NOT NULL
      AND qi_asb_complete = 2
      AND month IS NOT NULL
      AND year IS NOT NULL

    UNION ALL

    SELECT
        hosp_name, location, month, year
    FROM "v1"."UTI Individual Historical 2024-2025"
    WHERE hosp_name IS NOT NULL
      AND month IS NOT NULL
      AND year IS NOT NULL
),

hospital_loc AS (
    SELECT 
        i.hosp_name AS hosp_num,
        LPAD(i.hosp_name::TEXT, 2, '0') AS hosp_code,
        TRIM(h.state) AS state,
        CASE i.location
            WHEN 1 THEN 'Ambulatory care clinic'
            WHEN 2 THEN 'Emergency Department'
            WHEN 3 THEN 'Inpatient'
            WHEN 4 THEN 'Rehab or long-term care'
            WHEN 5 THEN 'Urgent or quick care'
            WHEN 6 THEN 'Other'
        END AS location_name,
        i.location AS location_code,
        TO_DATE(i.year::TEXT || '-' || LPAD(i.month::TEXT, 2, '0') || '-01', 'YYYY-MM-DD') AS month_date,
        COUNT(*) AS n_submissions
    FROM raw_data i
    LEFT JOIN "v1"."CSiM Hospitals and States" h 
        ON i.hosp_name = h.hosp_code
    WHERE h.hosp_code IS NOT NULL
    GROUP BY i.hosp_name, TRIM(h.state), i.location, i.month, i.year
),

-- All locations combined per hospital per month
hospital_loc_allloc AS (
    SELECT 
        i.hosp_name AS hosp_num,
        LPAD(i.hosp_name::TEXT, 2, '0') AS hosp_code,
        TRIM(h.state) AS state,
        'All locations' AS location_name,
        0 AS location_code,
        TO_DATE(i.year::TEXT || '-' || LPAD(i.month::TEXT, 2, '0') || '-01', 'YYYY-MM-DD') AS month_date,
        COUNT(*) AS n_submissions
    FROM raw_data i
    LEFT JOIN "v1"."CSiM Hospitals and States" h 
        ON i.hosp_name = h.hosp_code
    WHERE h.hosp_code IS NOT NULL
    GROUP BY i.hosp_name, TRIM(h.state), i.month, i.year
),

combined AS (
    SELECT * FROM hospital_loc
    UNION ALL
    SELECT * FROM hospital_loc_allloc
),

state_loc AS (
    SELECT 
        NULL::BIGINT AS hosp_num,
        state AS hosp_code,
        state,
        location_name,
        location_code,
        month_date,
        SUM(n_submissions) AS n_submissions
    FROM combined
    GROUP BY state, location_name, location_code, month_date
),

cohort_loc AS (
    SELECT 
        NULL::BIGINT AS hosp_num,
        'Cohort' AS hosp_code,
        'ALL' AS state,
        location_name,
        location_code,
        month_date,
        SUM(n_submissions) AS n_submissions
    FROM combined
    GROUP BY location_name, location_code, month_date
)

SELECT * FROM combined
UNION ALL
SELECT * FROM state_loc
UNION ALL
SELECT * FROM cohort_loc
ORDER BY month_date, hosp_code, location_code
