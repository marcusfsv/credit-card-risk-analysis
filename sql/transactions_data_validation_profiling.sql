--
--
-- TABLE:
-- transactions
--
--

--      1. Overview

-- View the first 5 rows of the dataset
SELECT * FROM transactions LIMIT 5;

--      2. Duplicates and missing values

-- Check the number of rows, duplicates, and average transactions per card
SELECT 
  COUNT(*) AS num_rows, 
  COUNT (DISTINCT transaction_id) AS distinct_transaction_id,
  COUNT(*) / COUNT(DISTINCT card_id) AS avg_transactions_per_card
FROM transactions;

-- Checking for missing values (NULL)
SELECT
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) AS null_transaction_id,
    SUM(CASE WHEN card_id IS NULL THEN 1 ELSE 0 END) AS null_card_id,
    SUM(CASE WHEN timestamp IS NULL THEN 1 ELSE 0 END) AS null_timestamp,
    SUM(CASE WHEN amount IS NULL THEN 1 ELSE 0 END) AS null_amount,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS null_category
FROM transactions;

--      3. Column-by-Column Review

-- Checking for unusual values in timestamp
SELECT
	MIN(timestamp) AS min_timestamp, 
	MAX(timestamp) AS max_timestamp
FROM transactions;

-- Checking for consistency in timestamp
SELECT
	t.transaction_id,
	t.card_id,
	t.timestamp,
	cc.card_id,
	cc.issued_date,
	cc.status,
	cc.status_date
FROM transactions t
JOIN v_credit_cards cc
ON t.card_id = cc.card_id
WHERE DATE(t.timestamp) < cc.issued_date  -- transaction before card issuance: not logical
OR DATE(t.timestamp) > CURRENT_DATE -- transaction in the future
OR (cc.status != 'Active' AND DATE(t.timestamp) > cc.status_date) -- transaction when the card was inactive
;

-- Basic descriptive stats for amount
SELECT 
  ROUND(AVG(amount),2) AS avg_amount,
  ROUND(STDDEV(amount),2) AS std_amount,
  MIN(amount) AS min_amount,
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY amount) AS q1_amount,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY amount) AS q3_amount,
  MAX(amount) AS max_amount
FROM transactions;

-- Checking for unique and unusual values in category
SELECT 
	category,
	COUNT(*)
FROM transactions
GROUP BY 1
ORDER BY 2 DESC;

--      4.	Transformation and Grouping

--      5.	Cross-Tab Check

-- Checking for cross-tab consistency
SELECT 
  category,
  ROUND(AVG(amount),2) AS avg_amount
FROM transactions
GROUP BY 1
ORDER BY 2 DESC;