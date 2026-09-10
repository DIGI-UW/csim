WITH raw_data AS (
    SELECT
        hosp_name, location, month, year, tx___1,
        tx___2, tx___3, tx___4, tx___5, tx___6, tx___7,
        other_tx___1, other_tx___2, other_tx___3, other_tx___4,
        other_tx___5, other_tx___6, other_tx___7, other_tx___8,
        other_tx___9, other_tx___10, other_tx___11, other_tx___12
    FROM "v1"."UTI Individual Current"
    WHERE hosp_name IS NOT NULL
      AND qi_asb_complete = 2
      AND month IS NOT NULL
      AND year IS NOT NULL

    UNION ALL

    SELECT
        hosp_name, location, month, year, tx___1,
        tx___2, tx___3, tx___4, tx___5, tx___6, tx___7,
        other_tx___1, other_tx___2, other_tx___3, other_tx___4,
        other_tx___5, other_tx___6, other_tx___7, other_tx___8,
        other_tx___9, other_tx___10, other_tx___11, other_tx___12
    FROM "v1"."UTI Individual Historical 2024-2025"
    WHERE hosp_name IS NOT NULL
      AND month IS NOT NULL
      AND year IS NOT NULL
),

antibiotic_long AS (
    SELECT
        i.hosp_name,
        TRIM(h.state) AS state,
        i.location,
        i.month,
        i.year,
        antibiotic_name,
        1 AS prescription_count
    FROM raw_data i
    LEFT JOIN "v1"."CSiM Hospitals and States" h
        ON i.hosp_name = h.hosp_code
    CROSS JOIN LATERAL (
        VALUES
            (CASE WHEN i.tx___2 = 1 THEN 'Ceftriaxone' END),
            (CASE WHEN i.tx___3 = 1 THEN 'Cephalexin' END),
            (CASE WHEN i.tx___4 = 1 THEN 'Fluoroquinolone' END),
            (CASE WHEN i.tx___5 = 1 THEN 'Nitrofurantoin' END),
            (CASE WHEN i.tx___6 = 1 THEN 'TMP/SMX' END),
            (CASE WHEN i.tx___7 = 1 AND (i.other_tx___1 = 1 OR i.other_tx___2 = 1 OR i.other_tx___4 = 1)
                  THEN 'Oral beta-lactam' END),
            (CASE WHEN i.tx___7 = 1 AND (i.other_tx___3 = 1 OR i.other_tx___5 = 1 OR i.other_tx___6 = 1
                       OR i.other_tx___7 = 1 OR i.other_tx___8 = 1 OR i.other_tx___9 = 1
                       OR i.other_tx___10 = 1 OR i.other_tx___11 = 1 OR i.other_tx___12 = 1)
                  THEN 'Other' END)
    ) AS abx(antibiotic_name)
    WHERE i.tx___1 = 0
      AND h.hosp_code IS NOT NULL
      AND antibiotic_name IS NOT NULL
),

-- Location-specific aggregation
hospital_abx AS (
    SELECT
        hosp_name AS hosp_num,
        LPAD(hosp_name::TEXT, 2, '0') AS hosp_code,
        state,
        CASE location
            WHEN 1 THEN 'Ambulatory care clinic'
            WHEN 2 THEN 'Emergency Department'
            WHEN 3 THEN 'Inpatient'
            WHEN 4 THEN 'Rehab or long-term care'
            WHEN 5 THEN 'Urgent or quick care'
            WHEN 6 THEN 'Other'
        END AS location_name,
        location AS location_code,
        TO_DATE(year::TEXT || '-' || LPAD(month::TEXT, 2, '0') || '-01', 'YYYY-MM-DD') AS month_date,
        antibiotic_name,
        SUM(prescription_count) AS prescription_count
    FROM antibiotic_long
    GROUP BY hosp_name, state, location, month, year, antibiotic_name
),

-- All locations combined per hospital
hospital_abx_allloc AS (
    SELECT
        hosp_name AS hosp_num,
        LPAD(hosp_name::TEXT, 2, '0') AS hosp_code,
        state,
        'All locations' AS location_name,
        0 AS location_code,
        TO_DATE(year::TEXT || '-' || LPAD(month::TEXT, 2, '0') || '-01', 'YYYY-MM-DD') AS month_date,
        antibiotic_name,
        SUM(prescription_count) AS prescription_count
    FROM antibiotic_long
    GROUP BY hosp_name, state, month, year, antibiotic_name
),

combined_hosp AS (
    SELECT * FROM hospital_abx
    UNION ALL
    SELECT * FROM hospital_abx_allloc
),

state_abx AS (
    SELECT
        NULL::BIGINT AS hosp_num,
        state AS hosp_code,
        state,
        location_name, location_code, month_date,
        antibiotic_name,
        SUM(prescription_count) AS prescription_count
    FROM combined_hosp
    GROUP BY state, location_name, location_code, month_date, antibiotic_name
),

cohort_abx AS (
    SELECT
        NULL::BIGINT AS hosp_num,
        'Cohort' AS hosp_code,
        'ALL' AS state,
        location_name, location_code, month_date,
        antibiotic_name,
        SUM(prescription_count) AS prescription_count
    FROM combined_hosp
    GROUP BY location_name, location_code, month_date, antibiotic_name
),

all_levels AS (
    SELECT * FROM combined_hosp
    UNION ALL
    SELECT * FROM state_abx
    UNION ALL
    SELECT * FROM cohort_abx
),

ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY hosp_code, location_code, month_date
            ORDER BY prescription_count DESC, antibiotic_name
        ) AS rnk
    FROM all_levels
)

SELECT
    hosp_num, hosp_code, state,
    location_name, location_code, month_date,
    antibiotic_name, prescription_count, rnk
FROM ranked
WHERE rnk <= 3
ORDER BY month_date, hosp_code, location_code, rnk
