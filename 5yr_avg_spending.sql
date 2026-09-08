/*
Data Cleaning and Analysis Project: 5-Year Average Spending Trend Analysis
Purpose: Cleans raw transaction data, extracts annual spend metrics, and computes
the 5-year average percent change in spending across different business categories.
*/


-- Initialize database
USE finance
GO


CREATE VIEW dbo.v_category_spending_trends AS
-- Stage and clean raw data
WITH 
cleaned AS (
	SELECT
		category,
		YEAR(CAST(transaction_date AS DATE)) AS year,
		TRY_CAST(
			(REPLACE(REPLACE(CAST(amount AS VARCHAR(50)), '$', ''), ',', '')) 
			AS DECIMAL(10, 2)) AS amount
	FROM dbo.raw_transactions_final
),


-- Sum total spending per category per calendar year
yearly AS (
	SELECT
		category, 
		year, 
		SUM(amount) AS total_spend
	FROM cleaned
	GROUP BY category, year
),


-- Compute year-over-year (YoY) percent change metrics 
pct_change AS(
	SELECT
		category, 
		year,
		total_spend,
		
		-- Look backward one year
		LAG(total_spend) OVER (PARTITION By category ORDER BY year) as prev_year_spend,
		
		-- Compute YoY percent change: ((Current - Previous)/Previous) * 100
		(total_spend - LAG(total_spend) OVER (PARTITION By category ORDER BY year))
		/LAG(total_spend) OVER (PARTITION By category ORDER BY year)*100 AS pct_change_yearly
	FROM yearly
)


-- Average YoY percent change into its 5-year average percent change per category
SELECT
	category,
	AVG(pct_change_yearly) as average_pct_change
FROM pct_change
GROUP BY category;
GO
