-- because make items can appear in DT at different pack sizes, we
-- need to work out the most expensive per-quantity cost (on
-- assumption that'll be used) and use that to work out the total cost
-- change.
-- comment to test PRs
WITH month_1 AS (
SELECT
  product_id,
  bnf_code,
  name,
  tariff_lookup."desc" AS tariff_category,
  MAX(coalesce(price_concession_pence,
      price_pence)/qtyval) AS price_per_quantity
FROM
  dmd_tariffprice
INNER JOIN
  dmd_vmpp
ON vppid = vmpp_id
LEFT JOIN
  dmd_ncsoconcession
ON
  dmd_tariffprice.vmpp_id = dmd_ncsoconcession.vmpp_id
  AND dmd_tariffprice.date = dmd_ncsoconcession.date
RIGHT JOIN
  dmd_product
ON product_id = dmdid
INNER JOIN
  dmd_lookup_dt_payment_category as tariff_lookup
ON cd = dmd_product.tariff_category
WHERE
  dmd_tariffprice.date = '{prev_prescribing_month}'
GROUP BY
  product_id, bnf_code, name, tariff_lookup."desc"
),
month_2 AS (
SELECT
  product_id,
  bnf_code,
  name,
  tariff_lookup."desc" AS tariff_category,
  MAX(coalesce(price_concession_pence,
      price_pence)/qtyval) AS price_per_quantity
FROM
  dmd_tariffprice
INNER JOIN
  dmd_vmpp
ON vppid = vmpp_id
LEFT JOIN
  dmd_ncsoconcession
ON
  dmd_tariffprice.vmpp_id = dmd_ncsoconcession.vmpp_id
  AND dmd_tariffprice.date = dmd_ncsoconcession.date
RIGHT JOIN
  dmd_product
ON product_id = dmdid
INNER JOIN
  dmd_lookup_dt_payment_category as tariff_lookup
ON cd = dmd_product.tariff_category
WHERE
  dmd_tariffprice.date = '{current_prescribing_month}'
GROUP BY
  product_id, bnf_code, name, tariff_lookup."desc"
),
  changes AS (
  SELECT
    month_1.bnf_code,
    month_1.name,
    month_1.tariff_category,
    month_1.price_per_quantity AS month_1_price,
    month_2.price_per_quantity AS month_2_price
  FROM
    month_2
  LEFT JOIN
    month_1
  ON
    month_2.bnf_code = month_1.bnf_code
)
SELECT
  bnf_code,
  name,
  tariff_category,
  (month_1_price * quantity)/100 AS month_1_total,
  (month_2_price * quantity)/100 AS month_2_total,
  (month_2_price * quantity)/100 - (month_1_price * quantity)/100 AS delta,
  cost
FROM
  changes
INNER JOIN
  vw__presentation_summary
ON
  presentation_code = bnf_code
  AND processing_date = '{current_prescribing_month}'
ORDER BY
  (month_2_price * quantity)/100 - (month_1_price * quantity)/100 DESC
