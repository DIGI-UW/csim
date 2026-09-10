WITH raw_data AS (
    SELECT
        hosp_name, month, year,
        tx___1, duration
    FROM "v1"."UTI Individual Current"
    WHERE hosp_name IS NOT NULL
      AND qi_asb_complete = 2
      AND month IS NOT NULL
      AND year IS NOT NULL

    UNION ALL

    SELECT
        hosp_name, month, year,
        tx___1, duration
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
        SUM(CASE WHEN i.tx___1 = 0 AND i.duration IS NOT NULL THEN i.duration ELSE 0 END) AS dur_sum,
        SUM(CASE WHEN i.tx___1 = 0 AND i.duration IS NOT NULL THEN 1 ELSE 0 END) AS dur_count,
        CASE 
            WHEN SUM(CASE WHEN i.tx___1 = 0 AND i.duration IS NOT NULL THEN 1 ELSE 0 END) > 0
            THEN SUM(CASE WHEN i.tx___1 = 0 AND i.duration IS NOT NULL THEN i.duration ELSE 0 END)::FLOAT /
                 SUM(CASE WHEN i.tx___1 = 0 AND i.duration IS NOT NULL THEN 1 ELSE 0 END)
            ELSE NULL
        END AS avg_dur
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
        SUM(CASE WHEN avg_dur IS NOT NULL THEN avg_dur * ucsub ELSE 0 END) / 
            NULLIF(SUM(CASE WHEN avg_dur IS NOT NULL THEN ucsub ELSE 0 END), 0) AS state_avg_dur
    FROM hospital_agg
    GROUP BY state, month_date
),

cohort_avg AS (
    SELECT
        month_date,
        SUM(CASE WHEN avg_dur IS NOT NULL THEN avg_dur * ucsub ELSE 0 END) / 
            NULLIF(SUM(CASE WHEN avg_dur IS NOT NULL THEN ucsub ELSE 0 END), 0) AS cohort_avg_dur
    FROM hospital_agg
    GROUP BY month_date
)

SELECT
    h.hosp_num,
    h.hosp_code,
    h.state AS "State",
    TO_CHAR(h.month_date, 'Mon YYYY') AS "Month",
    ROUND(h.avg_dur::numeric, 1) AS "Your Hospital (Days)",
    ROUND(s.state_avg_dur::numeric, 1) AS "Your State (Days)",
    ROUND(c.cohort_avg_dur::numeric, 1) AS "Cohort (Days)"
FROM hospital_latest h
LEFT JOIN state_avg s ON h.state = s.state AND h.month_date = s.month_date
LEFT JOIN cohort_avg c ON h.month_date = c.month_date
ORDER BY h.hosp_code
