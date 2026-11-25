-- Legacy batch SLA report from a business-date and job-ID text extract.
-- This legacy report treats integer job IDs as text patterns within each date.
-- Report operations group 1 (job IDs 1–100) for business dates 2026-10-01 through 2026-10-07.
-- ATTEMPT_COUNT includes every attempt. FAILED_ATTEMPT_COUNT counts FAILED only.
-- A success at DEADLINE_TS is on time. Omit on-time entries.
WITH RUN_SUMMARY AS (
    SELECT
        S.BUSINESS_DATE,
        S.JOB_ID,
        S.JOB_NAME,
        S.DEADLINE_TS,
        (
            SELECT COUNT(*)
            FROM BOB_SQL_LAB.BATCH_RUN R
            WHERE TRIM(CHAR(R.JOB_ID)) LIKE TRIM(CHAR(S.JOB_ID))
              AND R.BUSINESS_DATE = S.BUSINESS_DATE
        ) AS ATTEMPT_COUNT,
        (
            SELECT COUNT(*)
            FROM BOB_SQL_LAB.BATCH_RUN R
            WHERE TRIM(CHAR(R.JOB_ID)) LIKE TRIM(CHAR(S.JOB_ID))
              AND R.BUSINESS_DATE = S.BUSINESS_DATE
              AND R.RUN_STATUS = 'FAILED'
        ) AS FAILED_ATTEMPT_COUNT,
        (
            SELECT MIN(R.END_TS)
            FROM BOB_SQL_LAB.BATCH_RUN R
            WHERE TRIM(CHAR(R.JOB_ID)) LIKE TRIM(CHAR(S.JOB_ID))
              AND R.BUSINESS_DATE = S.BUSINESS_DATE
              AND R.RUN_STATUS = 'SUCCESS'
        ) AS FIRST_SUCCESS_TS
    FROM BOB_SQL_LAB.BATCH_SCHEDULE S
    WHERE S.BUSINESS_DATE >= DATE('2026-10-01')
      AND S.BUSINESS_DATE < DATE('2026-10-08')
      AND S.JOB_ID BETWEEN 1 AND 100
)
SELECT
    BUSINESS_DATE,
    JOB_ID,
    JOB_NAME,
    DEADLINE_TS,
    ATTEMPT_COUNT,
    FAILED_ATTEMPT_COUNT,
    FIRST_SUCCESS_TS,
    CASE
        WHEN ATTEMPT_COUNT = 0 THEN 'MISSED'
        WHEN FIRST_SUCCESS_TS IS NULL THEN 'NO_SUCCESS'
        ELSE 'LATE'
    END AS SLA_STATUS
FROM RUN_SUMMARY
WHERE FIRST_SUCCESS_TS IS NULL OR FIRST_SUCCESS_TS > DEADLINE_TS
ORDER BY BUSINESS_DATE, JOB_ID;
