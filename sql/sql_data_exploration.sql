--
--
-- SQL Data Exploration
--
--


-- Question 1


-- Late payment rate by client and card tier
-- Ordered by number of late payments
SELECT
  cc.customer_id,
  pb.card_id,
  COUNT(*) AS num_late_payments,
  snapshots.num_snapshots,
  ROUND(COUNT(*) * 1.0 / snapshots.num_snapshots, 2) AS late_rate
FROM v_credit_cards cc
JOIN payment_behavior pb
ON cc.card_id = pb.card_id
JOIN (
  SELECT card_id, COUNT(*) AS num_snapshots
  FROM payment_behavior
  GROUP BY card_id
) AS snapshots
ON pb.card_id = snapshots.card_id
WHERE pb.late_payment = TRUE
GROUP BY cc.customer_id, pb.card_id, snapshots.num_snapshots
ORDER BY num_late_payments DESC, late_rate DESC
LIMIT 10;

-- Late payment rate by client and card tier
-- Ordered by percentage of late payments
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
AND snapshots.num_snapshots >= 4
GROUP BY pb.card_id, snapshots.num_snapshots
ORDER BY 4 DESC, 2 DESC
LIMIT 10;

-- Average utilization rate by customer
SELECT
  cc.customer_id,
  cc.credit_limit_bin,
  cc.credit_limit,
  pb.card_id,
  ROUND(AVG(pb.balance / cc.credit_limit), 2) AS avg_utilization
FROM payment_behavior pb
LEFT JOIN (
  SELECT 
    card_id,
    customer_id,
    credit_limit,
    credit_limit_bin
  FROM v_credit_cards
) AS cc
ON pb.card_id = cc.card_id
GROUP BY 1, 2, 3, 4
ORDER BY 5 DESC, 3 DESC
LIMIT 10;

-- Riskiest customers with high utilization and late payment rate
SELECT
  cc.customer_id,
  pb.card_id,
  ROUND(AVG(pb.balance / cc.credit_limit), 2) AS avg_utilization,
  SUM(CASE WHEN pb.late_payment THEN 1 ELSE 0 END) AS num_late_payments,
  snapshots.num_snapshots,
  ROUND(SUM(CASE WHEN pb.late_payment THEN 1 ELSE 0 END) * 1.0 / snapshots.num_snapshots, 2) AS late_rate
FROM payment_behavior pb
LEFT JOIN (
  SELECT 
    card_id,
    customer_id,
    credit_limit,
    credit_limit_bin
  FROM v_credit_cards
) AS cc ON pb.card_id = cc.card_id
JOIN (
  SELECT card_id, COUNT(*) AS num_snapshots
  FROM payment_behavior
  GROUP BY card_id
) AS snapshots ON pb.card_id = snapshots.card_id
WHERE snapshots.num_snapshots >= 4
GROUP BY 1, 2, 5
ORDER BY late_rate DESC, avg_utilization DESC
LIMIT 15;


-- Question 3


-- High utilization and late payment rate by gender
SELECT
  cs.gender,
  COUNT(DISTINCT cs.customer_id) AS num_customers,
  ROUND(AVG(pb.balance / cc.credit_limit), 2) AS avg_utilization,
  ROUND(SUM(CASE WHEN pb.late_payment THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 2) AS late_rate
FROM v_customers cs
JOIN credit_cards cc ON cs.customer_id = cc.customer_id
JOIN payment_behavior pb ON cc.card_id = pb.card_id
GROUP BY cs.gender
ORDER BY late_rate DESC;

-- High utilization and late payment rate by province
SELECT
  cs.province,
  COUNT(DISTINCT cs.customer_id) AS num_customers,
  ROUND(AVG(pb.balance / cc.credit_limit), 2) AS avg_utilization,
  ROUND(SUM(CASE WHEN pb.late_payment THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 2) AS late_rate
FROM v_customers cs
JOIN credit_cards cc ON cs.customer_id = cc.customer_id
JOIN payment_behavior pb ON cc.card_id = pb.card_id
GROUP BY cs.province
ORDER BY late_rate DESC;

-- High utilization and late payment rate by income bracket
SELECT
  cs.income_bracket,
  COUNT(DISTINCT cs.customer_id) AS num_customers,
  ROUND(AVG(pb.balance / cc.credit_limit), 2) AS avg_utilization,
  ROUND(SUM(CASE WHEN pb.late_payment THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 2) AS late_rate
FROM v_customers cs
JOIN credit_cards cc ON cs.customer_id = cc.customer_id
JOIN payment_behavior pb ON cc.card_id = pb.card_id
GROUP BY cs.income_bracket
ORDER BY late_rate DESC;

-- High utilization and late payment rate by employment status
SELECT
  cs.employment_status,
  COUNT(DISTINCT cs.customer_id) AS num_customers,
  ROUND(AVG(pb.balance / cc.credit_limit), 2) AS avg_utilization,
  ROUND(SUM(CASE WHEN pb.late_payment THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 2) AS late_rate
FROM v_customers cs
JOIN credit_cards cc ON cs.customer_id = cc.customer_id
JOIN payment_behavior pb ON cc.card_id = pb.card_id
GROUP BY cs.employment_status
ORDER BY late_rate DESC;

-- High utilization and late payment rate by marital status
SELECT
  cs.marital_status,
  COUNT(DISTINCT cs.customer_id) AS num_customers,
  ROUND(AVG(pb.balance / cc.credit_limit), 2) AS avg_utilization,
  ROUND(SUM(CASE WHEN pb.late_payment THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 2) AS late_rate
FROM v_customers cs
JOIN credit_cards cc ON cs.customer_id = cc.customer_id
JOIN payment_behavior pb ON cc.card_id = pb.card_id
GROUP BY cs.marital_status
ORDER BY late_rate DESC;

-- Creating VIEW with customer_age, age band, and account_age
CREATE OR REPLACE VIEW v_customers AS
SELECT 
  *,
  EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) AS customer_age,
  EXTRACT(YEAR FROM AGE(CURRENT_DATE, created_at)) AS account_age,
  CASE
    WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) < 20 THEN '<20'
    WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) < 30 THEN '20-29'
    WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) < 40 THEN '30-39'
    WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) < 50 THEN '40-49'
    WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date)) < 60 THEN '50-59'
    ELSE '60+'
  END AS age_band
FROM customers;

-- High utilization and late payment rate by customer age
SELECT
  cs.age_band,
  COUNT(DISTINCT cs.customer_id) AS num_customers,
  ROUND(AVG(pb.balance / cc.credit_limit), 2) AS avg_utilization,
  ROUND(SUM(CASE WHEN pb.late_payment THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 2) AS late_rate
FROM v_customers cs
JOIN credit_cards cc ON cs.customer_id = cc.customer_id
JOIN payment_behavior pb ON cc.card_id = pb.card_id
GROUP BY cs.age_band
ORDER BY cs.age_band;


-- Question 4


-- Customers with high risk and short relationship
SELECT 
  c.customer_id,
  cc.card_id,
  c.account_age,
  ROUND(AVG(pb.balance / cc.credit_limit), 2) AS avg_utilization,
  SUM(CASE WHEN pb.late_payment THEN 1 ELSE 0 END) AS late_payments
FROM v_customers c
JOIN v_credit_cards cc ON c.customer_id = cc.customer_id
JOIN payment_behavior pb ON cc.card_id = pb.card_id
GROUP BY c.customer_id, cc.card_id, c.account_age
HAVING account_age < 2 -- not loyal
   AND AVG(pb.balance / cc.credit_limit) > 0.85 -- risky
   AND SUM(CASE WHEN pb.late_payment THEN 1 ELSE 0 END) >= 2
ORDER BY late_payments DESC;

-- Customers with low spend and repeated lateness
SELECT 
  c.customer_id,
  ROUND(AVG(t.amount), 2) AS avg_spend,
  ROUND(SUM(CASE WHEN pb.late_payment THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 2) AS late_rate
FROM v_customers c
JOIN v_credit_cards cc ON c.customer_id = cc.customer_id
JOIN transactions t ON cc.card_id = t.card_id
JOIN payment_behavior pb ON cc.card_id = pb.card_id
GROUP BY c.customer_id, c.account_age
HAVING AVG(t.amount) < 100 -- not a profitable spender
  AND c.account_age > 0
  AND ROUND(SUM(CASE WHEN pb.late_payment THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 2) >= 0.3
ORDER BY late_rate DESC;


-- Final Views


-- Risk analysis view
CREATE OR REPLACE VIEW v_customer_risk_summary AS
SELECT 
  c.customer_id,
  cc.card_id,
  c.gender,
  EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birth_date)) AS customer_age,
  CASE
    WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birth_date)) < 20 THEN '<20'
    WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birth_date)) < 30 THEN '20-29'
    WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birth_date)) < 40 THEN '30-39'
    WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birth_date)) < 50 THEN '40-49'
    WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.birth_date)) < 60 THEN '50-59'
  	ELSE '60+'
  END AS age_band,
  EXTRACT(YEAR FROM AGE(CURRENT_DATE, c.created_at)) AS account_age,
  c.income_bracket,
  c.employment_status,
  c.marital_status,
  cc.card_tier,
  cc.credit_limit,
  CASE
    WHEN cc.credit_limit <= 3000 THEN 'Low (≤3K)'
    WHEN cc.credit_limit <= 6000 THEN 'Medium (3K-6K)'
    WHEN cc.credit_limit <= 10000 THEN 'Upper-Mid (6K-10K)'
    WHEN cc.credit_limit <= 20000 THEN 'High (10K-20K)'
    ELSE 'Very High (20K+)'
  END AS credit_limit_bin,
  cc.status,
  cc.status_date,
  pb.snapshot_date,
  pb.balance,
  pb.payment_made,
  pb.late_payment
FROM customers c
JOIN credit_cards cc ON c.customer_id = cc.customer_id
JOIN payment_behavior pb ON cc.card_id = pb.card_id;

-- Spending analysis view
CREATE OR REPLACE VIEW v_transaction_summary AS
SELECT 
  c.customer_id,
  cc.card_id,
  t.timestamp AS transaction_date,
  t.amount,
  t.category,
  c.income_bracket,
  cc.card_tier
FROM customers c
JOIN credit_cards cc ON c.customer_id = cc.customer_id
JOIN transactions t ON cc.card_id = t.card_id;