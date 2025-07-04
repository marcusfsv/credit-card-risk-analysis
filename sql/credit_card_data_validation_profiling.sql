--
--
-- TABLE:
-- credit_card
--
--

--      1. Overview

-- View the first 5 rows of the dataset
SELECT * FROM credit_cards LIMIT 5;

--      2. Duplicates and missing values

-- Check the number of rows and duplicates
SELECT 
    COUNT(*) AS num_rows, 
    COUNT (DISTINCT card_id) AS distinct_card_id 
FROM credit_cards;

-- Checking for missing values (NULL)
SELECT
    SUM(CASE WHEN card_id IS NULL THEN 1 ELSE 0 END) AS null_card_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN issued_date IS NULL THEN 1 ELSE 0 END) AS null_issued_date,
    SUM(CASE WHEN card_tier IS NULL THEN 1 ELSE 0 END) AS null_card_tier,
    SUM(CASE WHEN credit_limit IS NULL THEN 1 ELSE 0 END) AS null_credit_limit,
    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) AS null_status,
	SUM(CASE WHEN status_date IS NULL THEN 1 ELSE 0 END) AS null_status_date,
    SUM(CASE WHEN is_primary IS NULL THEN 1 ELSE 0 END) AS null_is_primary_bool
FROM credit_cards;

--      3. Column-by-Column Review

-- Checking for unique and unusual values in card_tier
SELECT 
	card_tier,
	COUNT(*)
FROM credit_cards
GROUP BY 1;

-- Checking for unusual values in issued_date
SELECT
	MIN(issued_date) AS min_issued_date, 
	MAX(issued_date) AS max_issued_date
FROM credit_cards;

-- Checking for consistency in issued_date
SELECT 
	cc.card_id,
	cc.customer_id,
	cc.issued_date,
	c.customer_id,
	c.created_at
FROM credit_cards cc
JOIN v_customers c
ON cc.customer_id = c.customer_id
WHERE cc.issued_date < c.created_at
OR cc.issued_date > CURRENT_DATE;

-- Basic descriptive stats for credit_limit
SELECT 
  ROUND(AVG(credit_limit),2) AS avg_credit_limit,
  ROUND(STDDEV(credit_limit),2) AS std_credit_limit,
  MIN(credit_limit) AS min_credit_limit,
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY credit_limit) AS q1_credit_limit,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY credit_limit) AS median_credit_limit,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY credit_limit) AS q3_credit_limit,
  MAX(credit_limit) AS max_credit_limit
FROM credit_cards;

-- Checking for unique and unusual values in status
SELECT 
	status,
	COUNT(*)
FROM credit_cards
GROUP BY 1;

-- Checking for consistency in status_date
SELECT 
	SUM(CASE WHEN status_date < CURRENT_DATE AND status = 'Active' THEN 1 ELSE 0 END) AS wrong_active_status,
	SUM(CASE WHEN status_date > CURRENT_DATE AND status != 'Active' THEN 1 ELSE 0 END) AS wrong_inactive_status,
	SUM(CASE WHEN status_date < issued_date THEN 1 ELSE 0 END) AS status_before_issued
FROM credit_cards;

-- Checking frequency for is_primary
SELECT is_primary,
	COUNT(*)
FROM credit_cards
GROUP BY 1;

--      4.	Transformation and Grouping

-- Creating a new VIEW with credit_limit bands
CREATE OR REPLACE VIEW v_credit_cards AS
SELECT
  *,
  CASE
  	WHEN credit_limit <= 3000 THEN 'Low (≤3K)'
	  WHEN credit_limit <= 6000 THEN 'Medium (3K-6K)'
	  WHEN credit_limit <= 10000 THEN 'Upper-Mid (6K-10K)'
	  WHEN credit_limit <= 20000 THEN 'High (10K-20K)'
    ELSE 'Very High (20K+)'
  END AS credit_limit_bin
FROM credit_cards;

--      5.	Cross-Tab Check

-- Checking for cross-tab consistency
SELECT 
  card_tier,
  credit_limit_bin,
  COUNT(*)
FROM v_credit_cards
GROUP BY 1, 2
ORDER BY 1, 2;