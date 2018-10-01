# -*- coding: utf-8 -*-
# ---
# jupyter:
#   jupytext_format_version: '1.3'
#   kernelspec:
#     display_name: Python (priceshock)
#     language: python
#     name: priceshock
#   language_info:
#     codemirror_mode:
#       name: ipython
#       version: 3
#     file_extension: .py
#     mimetype: text/x-python
#     name: python
#     nbconvert_exporter: python
#     pygments_lexer: ipython3
#     version: 3.6.5
# ---

import os
import pandas as pd
import psycopg2
import matplotlib
# %matplotlib inline


# # Expected increases as a result of DT changes
#
# These are the changes we expect in the next month of prescribing data based on the released drug tariff data for that month.

# +
PREV_PRESCRIBING_MONTH = '2018-06-01'
CURRENT_PRESCRIBING_MONTH = '2018-07-01'
TARIFF_MONTH = '2018-08-01'
password = os.environ['DB_PASS']
sql = open("dt_change.sql").read().format(
    current_prescribing_month=CURRENT_PRESCRIBING_MONTH,
    prev_prescribing_month=PREV_PRESCRIBING_MONTH,
    tariff_month=TARIFF_MONTH
)

con = "postgresql://prescribing_readonly:{password}@largeweb2.ebmdatalab.net:5432/prescribing".format(password=password)

df = pd.read_sql_query(
    sql, con)
    
# -

df.groupby('tariff_category').sum()

df.groupby('tariff_category').sum().plot.bar(
    y='delta', 
    logy=True,
    title="Expected net price increases by DT Category in {}".format(TARIFF_MONTH))

# Largest price increases expected OUTSIDE category M
df2 = df[df.tariff_category != "Part VIIIA Category M"]
df2.head(10)

# # Actual cost changes relating to things outside the Drug Tariff
#
# This is a combination of branded prescribing and NP8 generics.
#
# Although based on actual prescribing data, we could potentially do a projection based on DMD price data, if that's any good (we've never looked at it)

sql = open("np8_change.sql").read().format(
    current_prescribing_month=CURRENT_PRESCRIBING_MONTH,
    prev_prescribing_month=PREV_PRESCRIBING_MONTH,
    tariff_month=TARIFF_MONTH
)
df3 = pd.read_sql_query(
    sql, con)
    


# Top NP8 / branded price changes
df3.sort_values('delta', ascending=False).head()

# The same, but just NP8 generics
df3[df3.type == 'generic'].sort_values('delta', ascending=False).head()

# I think following shows that branded switching is actually costing the MHS *more* money overall.

# Total price increases related to each type
pd.options.display.float_format = '£{:,.2f}'.format
pd.DataFrame(df3.groupby('type')['delta', 'cost'].sum())

# # Trends in generic prescribing

# +

sql = """
SELECT
  processing_date, SUBSTR(presentation_code, 11, 2) = 'AA' as is_generic, SUM(cost)
FROM
  vw__presentation_summary
GROUP BY processing_date, is_generic order by processing_date, is_generic"""
df4 = pd.read_sql_query(
    sql, con)
    

# -

df4 = df4.set_index('processing_date')

df5 = df4.pivot(columns='is_generic')
df5.columns = ['branded', 'generic']
df5.rolling(3).mean().plot.area(title="Total cost of all prescribing, last 5 years")


df5['branded_as_percent'] = df5.branded / (df5.branded + df5.generic)
df5.plot.line(y='branded_as_percent', title="Branded prescribing as percentage of all prescribing")
