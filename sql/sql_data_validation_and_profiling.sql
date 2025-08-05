--
--
-- TABLE:
-- customers
--
--

--      1. Overview

-- View the first 5 rows of the dataset
SELECT * FROM customers LIMIT 5;

--      2. Duplicates and missing values

-- Check the number of rows and duplicates
SELECT 
    COUNT(*) AS num_rows, 
    COUNT (DISTINCT customer_id) AS distinct_customer_id 
FROM customers;

-- Checking for missing values (NULL)
SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END) AS null_created_at,
    SUM(CASE WHEN birth_date IS NULL THEN 1 ELSE 0 END) AS null_birth_date,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS null_gender,
    SUM(CASE WHEN province IS NULL THEN 1 ELSE 0 END) AS null_province,
    SUM(CASE WHEN income_bracket IS NULL THEN 1 ELSE 0 END) AS null_income_bracket,
    SUM(CASE WHEN employment_status IS NULL THEN 1 ELSE 0 END) AS null_employment_status,
    SUM(CASE WHEN marital_status IS NULL THEN 1 ELSE 0 END) AS null_marital_status
FROM customers;

--      3. Column-by-Column Review

-- Checking for unique and unusual values in gender
SELECT 
  gender,
  COUNT(*)
FROM customers
GROUP BY 1;

-- Checking for unusual values in birth_date
SELECT
  MIN(birth_date) AS min_birth, 
  MAX(birth_date) AS max_birth
FROM customers;

-- Checking for unusual values in province
SELECT 
    DISTINCT province,
    COUNT(*)
FROM customers
GROUP BY 1
ORDER BY 2 DESC;

-- Checking for unique and unusual values in income_bracket
SELECT 
  DISTINCT (income_bracket),
  COUNT(*)
FROM customers
GROUP BY 1;

-- Checking for unique and unusual values in employment_status
SELECT 
  DISTINCT (employment_status),
  COUNT(*)
FROM customers
GROUP BY 1;

-- Checking for unique and unusual values in marital_status
SELECT 
  DISTINCT (marital_status),
  COUNT(*)
FROM customers
GROUP BY 1;

-- Checking for unusual values in created_at
SELECT 
  MIN(created_at) AS min_created_at,
  MAX(created_at) AS max_created_at
FROM customers;

-- Checking for consistency in the dates
SELECT * FROM customers WHERE birth_date > created_at OR created_at > CURRENT_DATE;

--      4.  Transformation and Grouping

-- Creating VIEW with customer_age and account_age
CREATE OR REPLACE VIEW v_customers AS
SELECT 
  *,
  EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) AS customer_age,
  EXTRACT(YEAR FROM AGE(CURRENT_DATE, created_at)) AS account_age
FROM customers;

-- Checking for outliers in the age columns
SELECT 
  MIN(customer_age) AS min_customer_age, 
  MAX(customer_age) AS max_customer_age, 
  MIN(account_age) AS min_account_age, 
  MAX(account_age) AS max_account_age 
FROM v_customers;

--      5.  Cross-Tab Check

-- Checking for cross-tab consistency
SELECT 
  employment_status,
  income_bracket,
  COUNT(*)
FROM v_customers
GROUP BY 1, 2
ORDER BY 1, 2;

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

--      4.  Transformation and Grouping

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

--      5.  Cross-Tab Check

-- Checking for cross-tab consistency
SELECT 
  card_tier,
  credit_limit_bin,
  COUNT(*)
FROM v_credit_cards
GROUP BY 1, 2
ORDER BY 1, 2;

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

--      4.  Transformation and Grouping

--      5.  Cross-Tab Check

-- Checking for cross-tab consistency
SELECT 
  category,
  ROUND(AVG(amount),2) AS avg_amount
FROM transactions
GROUP BY 1
ORDER BY 2 DESC;

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

--      4.  Transformation and Grouping

--      5.  Cross-Tab Check

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
) AS snapshots 
  ON pb.card_id = snapshots.card_id
WHERE pb.late_payment = TRUE
GROUP BY pb.card_id, snapshots.num_snapshots
ORDER BY num_late_payments DESC
LIMIT 10;
