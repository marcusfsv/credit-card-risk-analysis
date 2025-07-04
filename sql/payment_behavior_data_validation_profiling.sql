--
--
-- TABLE:
-- payment_behavior
--
--

--      1. Overview

-- View the first 5 rows of the dataset
SELECT * FROM payment_behavior LIMIT 5;

--      2. Duplicates and missing values

-- Check the number of rows and duplicates
SELECT 
    COUNT(*) AS num_rows, 
    COUNT (DISTINCT card_id) AS distinct_card_id 
FROM payment_behavior;

-- Checking the missing cards from payment_behavior
SELECT *
FROM credit_cards
WHERE card_id NOT IN (
  SELECT DISTINCT card_id FROM payment_behavior
);

-- Checking for missing values (NULL)
SELECT
    SUM(CASE WHEN card_id IS NULL THEN 1 ELSE 0 END) AS null_card_id,
    SUM(CASE WHEN snapshot_date IS NULL THEN 1 ELSE 0 END) AS null_snapshot_date,
    SUM(CASE WHEN balance IS NULL THEN 1 ELSE 0 END) AS null_balance,
    SUM(CASE WHEN payment_made IS NULL THEN 1 ELSE 0 END) AS null_payment_made,
    SUM(CASE WHEN late_payment IS NULL THEN 1 ELSE 0 END) AS null_late_payment
FROM payment_behavior;

--      3. Column-by-Column Review

-- Checking for unusual values in snapshot_date
SELECT
	MIN(snapshot_date) AS min_snapshot_date, 
	MAX(snapshot_date) AS max_snapshot_date
FROM payment_behavior;

-- Basic descriptive stats for balance
SELECT 
  ROUND(AVG(balance),2) AS avg_balance,
  ROUND(STDDEV(balance),2) AS std_balance,
  MIN(balance) AS min_balance,
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY balance) AS q1_balance,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY balance) AS median_balance,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY balance) AS q3_balance,
  MAX(balance) AS max_balance
FROM payment_behavior;

-- Basic descriptive stats for payment_made
SELECT 
  ROUND(AVG(payment_made),2) AS avg_payment_made,
  ROUND(STDDEV(payment_made),2) AS std_payment_made,
  MIN(payment_made) AS min_payment_made,
  PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY payment_made) AS q1_payment_made,
  PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY payment_made) AS median_payment_made,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY payment_made) AS q3_payment_made,
  MAX(payment_made) AS max_payment_made
FROM payment_behavior;

-- Checking frequency for late_payment
SELECT late_payment,
	COUNT(*)
FROM payment_behavior
GROUP BY 1;

--      4.	Transformation and Grouping

--      5.	Cross-Tab Check

-- Checking for cross-tab consistency with late payment rate
SELECT 
  pb.card_id,
  COUNT(*) AS num_late_payments,
  snapshots.num_snapshots,
  ROUND(COUNT(*) * 1.0 / snapshots.num_snapshots, 2) AS late_rate
FROM payment_behavior pb
JOIN (
  SELECT card_id, COUNT(*) AS num_snapshots
  FROM payment_behavior
  GROUP BY card_id
) snapshots ON pb.card_id = snapshots.card_id
WHERE pb.late_payment = TRUE
GROUP BY pb.card_id, snapshots.num_snapshots
ORDER BY num_late_payments DESC
LIMIT 10;
