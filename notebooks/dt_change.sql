WITH
  month_1 AS (
  SELECT
    bnf_code,
    name,
    tariff_category,
    coalesce(price_concession_pence,
      price_pence) AS price
  FROM
    dmd_product
  INNER JOIN
    dmd_tariffprice
  ON
    product_id = dmdid
  LEFT JOIN
    dmd_ncsoconcession
  ON
    dmd_tariffprice.vmpp_id = dmd_ncsoconcession.vmpp_id
    AND dmd_tariffprice.date = dmd_ncsoconcession.date
  WHERE
    dmd_tariffprice.date = '{current_prescribing_month}'),
  month_2 AS (
  SELECT
    bnf_code,
    coalesce(price_concession_pence,
      price_pence) AS price
  FROM
    dmd_product
  INNER JOIN
    dmd_tariffprice
  ON
    product_id = dmdid
  LEFT JOIN
    dmd_ncsoconcession
  ON
    dmd_tariffprice.vmpp_id = dmd_ncsoconcession.vmpp_id
    AND dmd_tariffprice.date = dmd_ncsoconcession.date
  WHERE
    dmd_tariffprice.date = '{tariff_month}'),
  changes AS (
  SELECT
    month_1.bnf_code,
    month_1.name,
    month_1.tariff_category,
    month_1.price AS month_1_price,
    month_2.price AS month_2_price
  FROM
    month_2
  LEFT JOIN
    month_1
  ON
    month_2.bnf_code = month_1.bnf_code
  WHERE
    month_2.price <> month_1.price )
SELECT
  bnf_code,
  name,
  tariff_lookup."desc" AS tariff_category,
  (month_1_price * items)/100 AS month_1_total,
  (month_2_price * items)/100 AS month_2_total,
  (month_2_price * items)/100 - (month_1_price * items)/100 AS delta,
  cost
FROM
  changes
INNER JOIN
  vw__presentation_summary
ON
  presentation_code = bnf_code
  AND processing_date = '{current_prescribing_month}'
INNER JOIN
  dmd_lookup_dt_payment_category as tariff_lookup
ON cd = tariff_category
ORDER BY
  (month_2_price * items)/100 - (month_1_price * items)/100 DESC
