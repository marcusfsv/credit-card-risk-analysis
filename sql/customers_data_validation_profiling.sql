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

--      4.	Transformation and Grouping

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

--      5.	Cross-Tab Check

-- Checking for cross-tab consistency
SELECT 
  employment_status,
  income_bracket,
  COUNT(*)
FROM v_customers
GROUP BY 1, 2
ORDER BY 1, 2;
