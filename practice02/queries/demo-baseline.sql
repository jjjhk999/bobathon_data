-- Daily approved payments per active Seoul merchant.
-- The legacy report compares export-formatted merchant IDs and payment dates,
-- then performs separate lookups for count and amount within the weekly extract.
SELECT
    M.MERCHANT_ID,
    M.MERCHANT_NAME,
    (
        SELECT COUNT(*)
        FROM BOB_SQL_LAB.PAYMENT P
        WHERE TRIM(CHAR(P.MERCHANT_ID)) = TRIM(CHAR(M.MERCHANT_ID))
          AND P.PAYMENT_STATUS = 'APPROVED'
          AND P.PAYMENT_TS >= TIMESTAMP('2026-10-12-00.00.00')
          AND P.PAYMENT_TS < TIMESTAMP('2026-10-19-00.00.00')
          AND VARCHAR_FORMAT(P.PAYMENT_TS, 'YYYY-MM-DD') = '2026-10-15'
    ) AS APPROVED_COUNT,
    DECIMAL(COALESCE(
        (
            SELECT SUM(P.AMOUNT)
            FROM BOB_SQL_LAB.PAYMENT P
            WHERE TRIM(CHAR(P.MERCHANT_ID)) = TRIM(CHAR(M.MERCHANT_ID))
              AND P.PAYMENT_STATUS = 'APPROVED'
              AND P.PAYMENT_TS >= TIMESTAMP('2026-10-12-00.00.00')
          AND P.PAYMENT_TS < TIMESTAMP('2026-10-19-00.00.00')
          AND VARCHAR_FORMAT(P.PAYMENT_TS, 'YYYY-MM-DD') = '2026-10-15'
        ), 0
    ), 18, 2) AS APPROVED_TOTAL
FROM BOB_SQL_LAB.MERCHANT M
WHERE M.REGION = 'SEOUL' AND M.ACTIVE_YN = 'Y'
ORDER BY M.MERCHANT_ID;
