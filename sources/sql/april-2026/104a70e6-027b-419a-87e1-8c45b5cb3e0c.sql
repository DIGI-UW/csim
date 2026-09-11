WITH raw_data AS (
    SELECT
        hosp_name, sign_symp, month, year,
        ucx_positive, urinalysis, tx___1
    FROM "v1"."UTI Individual Current"
    WHERE hosp_name IS NOT NULL
      AND qi_asb_complete = 2
      AND month IS NOT NULL
      AND year IS NOT NULL

    UNION ALL

    SELECT
        hosp_name, sign_symp, month, year,
        ucx_positive, urinalysis, tx___1
    FROM "v1"."UTI Individual Historical"
    WHERE hosp_name IS NOT NULL
      AND month IS NOT NULL
      AND year IS NOT NULL
),

hospital_agg AS (
    SELECT 
        i.hosp_name AS hosp_num,
        LPAD(i.hosp_name::TEXT, 2, '0') AS hosp_code,
        TRIM(h.state) AS state,
        TO_DATE(i.year::TEXT || '-' || LPAD(i.month::TEXT, 2, '0') || '-01', 'YYYY-MM-DD') AS month_date,
        COUNT(*) AS ucsub,
        SUM(CASE WHEN i.ucx_positive = 1 AND i.tx___1 = 0 THEN 1 ELSE 0 END) AS txpos,
        SUM(CASE WHEN i.ucx_positive = 1 AND i.sign_symp = 0 AND i.tx___1 = 0 THEN 1 ELSE 0 END) AS asbtreated,
        CASE 
            WHEN SUM(CASE WHEN i.ucx_positive = 1 AND i.tx___1 = 0 THEN 1 ELSE 0 END) > 0 
            THEN SUM(CASE WHEN i.ucx_positive = 1 AND i.sign_symp = 0 AND i.tx___1 = 0 THEN 1 ELSE 0 END)::FLOAT / 
                 SUM(CASE WHEN i.ucx_positive = 1 AND i.tx___1 = 0 THEN 1 ELSE 0 END)
            ELSE NULL 
        END AS inappdx
    FROM raw_data i
    LEFT JOIN "v1"."CSiM Hospitals and States" h 
        ON i.hosp_name = h.hosp_code
    WHERE h.hosp_code IS NOT NULL
    GROUP BY i.hosp_name, TRIM(h.state), i.month, i.year
),

hospital_latest AS (
    SELECT *
    FROM hospital_agg a
    WHERE month_date = (
        SELECT MAX(month_date) 
        FROM hospital_agg 
        WHERE hosp_code = a.hosp_code
    )
),

state_avg AS (
    SELECT
        state,
        month_date,
        SUM(inappdx * ucsub) / 
            NULLIF(SUM(CASE WHEN inappdx IS NOT NULL THEN ucsub ELSE 0 END), 0) AS state_inappdx
    FROM hospital_agg
    GROUP BY state, month_date
),

cohort_avg AS (
    SELECT
        month_date,
        SUM(inappdx * ucsub) / 
            NULLIF(SUM(CASE WHEN inappdx IS NOT NULL THEN ucsub ELSE 0 END), 0) AS cohort_inappdx
    FROM hospital_agg
    GROUP BY month_date
)

SELECT
    h.hosp_num,
    h.hosp_code,
    h.state AS "State",
    TO_CHAR(h.month_date, 'Mon YYYY') AS "Month",
    h.inappdx AS "Your Hospital",
    s.state_inappdx AS "Your State",
    c.cohort_inappdx AS "Cohort",
    CASE 
        WHEN h.inappdx IS NULL THEN 'No data'
        WHEN h.inappdx < c.cohort_inappdx THEN 'Better than cohort ✓'
        WHEN h.inappdx > c.cohort_inappdx THEN 'Worse than cohort - <a href="https://uwcsim.org/course/asb-101-2023-2024/" target="_blank">Support resources</a>'
        ELSE 'Same as cohort'
    END AS "Comparison"
FROM hospital_latest h
LEFT JOIN state_avg s ON h.state = s.state AND h.month_date = s.month_date
LEFT JOIN cohort_avg c ON h.month_date = c.month_date
ORDER BY h.hosp_code
