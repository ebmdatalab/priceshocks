WITH
  np8 AS (
  SELECT
    bnf_code,
    CASE
      WHEN SUBSTR(bnf_code, 11, 2) = 'AA' THEN 'generic'
      ELSE 'branded'
    END AS type
  FROM
    dmd_product
  LEFT JOIN (
    SELECT
      *
    FROM
      dmd_tariffprice
    WHERE
      date = '{current_prescribing_month}') dmd_tariffprice
  ON
    product_id = dmdid
  WHERE
    bnf_code IS NOT NULL
  GROUP BY
    bnf_code
  HAVING
    SUM(price_pence) IS NULL ),
  month_1 AS (
  SELECT
    *,
    cost/quantity AS cost_per_quantity
  FROM
    vw__presentation_summary
  INNER JOIN
    np8
  ON
    np8.bnf_code = presentation_code
  WHERE
    processing_date = '{prev_prescribing_month}' ),
  month_2 AS (
  SELECT
    *,
    cost/quantity AS cost_per_quantity
  FROM
    vw__presentation_summary
  INNER JOIN
    np8
  ON
    np8.bnf_code = presentation_code
  WHERE
    processing_date = '{current_prescribing_month}' )
SELECT
  month_1.presentation_code,
  name,
  month_1.type,
  month_2.cost_per_quantity - month_1.cost_per_quantity AS per_quantity_delta,
  month_2.cost - month_1.cost AS delta,
  month_1.cost AS month_1_cost,
  month_2.cost AS month_2_cost,
  month_1.quantity AS month_1_quantity,
  month_2.quantity AS month_2_quantity

FROM
  month_1
INNER JOIN
  month_2
ON
  month_1.presentation_code = month_2.presentation_code
LEFT JOIN frontend_presentation ON frontend_presentation.bnf_code = month_1.presentation_code
