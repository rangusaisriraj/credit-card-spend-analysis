-- SQL Portfolio Project
-- Download credit card transactions dataset from:
-- https://www.kaggle.com/datasets/thedevastator/analyzing-credit-card-spending-habits-in-india

-- Import the dataset into SQL Server with table name: credit_card_transactions
-- Before importing:
--   - Change all column names to lower case
--   - Replace spaces in column names with underscores
--   - Change the data types appropriately (don't keep all columns as varchar)

-- Convert transaction_id to INT
ALTER TABLE credit_card
ALTER COLUMN transaction_id INT;

-- Convert city to VARCHAR(50)
ALTER TABLE credit_card
ALTER COLUMN city VARCHAR(50);

-- Convert transaction_date to DATE
ALTER TABLE credit_card
ALTER COLUMN transaction_date DATE;

-- Convert card_type to VARCHAR(20)
ALTER TABLE credit_card
ALTER COLUMN card_type VARCHAR(20);

-- Convert exp_type to VARCHAR(20)
ALTER TABLE credit_card
ALTER COLUMN exp_type VARCHAR(20);

-- Convert gender to CHAR(1)
ALTER TABLE credit_card
ALTER COLUMN gender CHAR(1);

-- Convert amount to BIGINT to avoid overflow
ALTER TABLE credit_card
ALTER COLUMN amount BIGINT;


-- Optional: Use the dataset from the Resources section file if Kaggle is not accessible

-- Write 4 to 6 exploratory queries on the dataset and document your findings

-- Questions:

-- 1. Write a query to print top 5 cities with highest spends 
--    and their percentage contribution of total credit card spends

SELECT  TOP 5 city ,SUM(amount) AS total_amount, 
ROUND( 100.0*SUM(amount)/(SELECT SUM(amount) FROM credit_Card),2) AS total_percentage 
FROM credit_card 
GROUP BY city
ORDER BY total_amount DESC;

-- 2. Write a query to print highest spend month and amount spent in that month 
-- for each card type
WITH CTE AS (
SELECT card_type, FORMAT(transaction_date, 'yyyy-MM') AS mth, SUM(amount) AS spend
FROM credit_card
GROUP BY card_type, FORMAT(transaction_date, 'yyyy-MM')),
CTE2 AS(
SELECT *, RANK() OVER(PARTITION BY card_type ORDER BY spend DESC) AS rn
FROM CTE)

SELECT * FROM CTE2 WHERE rn =1;


-- 3. (Solve after next session) 
--    Write a query to print the transaction details (all columns from the table) 
--    for each card type when it reaches a cumulative total of 1,000,000 in spends
--    (Output should contain 4 rows, one for each card type)

WITH CTE1 AS (

SELECT *, SUM(amount) OVER (PARTITION BY card_type ORDER BY transaction_date, transaction_id) AS Ct
FROM credit_card
),
CTE2 AS (SELECT * FROM CTE1 WHERE ct >= 1000000)

SELECT * FROM (
SELECT *, ROW_NUMBER() OVER (PARTITION BY card_type ORDER BY transaction_date, transaction_id)AS rn
FROM CTE2) C
WHERE rn = 1;



-- 4. Write a query to find the city which had the lowest percentage spend for Gold card type

WITH CTE AS (
SELECT city, SUM(amount) AS gc_total FROM credit_card
WHERE card_type = 'Gold'
GROUP BY city),
CTE2 AS (
SELECT SUM(amount) AS totalg_perc FROM credit_card WHERE card_type= 'Gold')

SELECT TOP 1 city, ROUND(100.0*gc_total/totalg_perc,2) as percentag FROM CTE c
CROSS JOIN CTE2 c2
ORDER BY percentag ASC;


-- 5. Write a query to print 3 columns: 
--    city, highest_expense_type, lowest_expense_type 
--    (Example output: Delhi, Bills, Fuel)

WITH cte1 as (
SELECT city, exp_type, SUM(amount) as total_amount FROM credit_card
GROUP BY city, exp_type),

Rnk_high_low AS 
( SELECT *, RANK() OVER(PARTITION BY city ORDER BY total_amount DESC) AS rn1,
RANK() OVER (PARTITION BY city ORDER BY total_amount ASC) AS rn2 FROM cte1)

SELECT city, MAX(CASE WHEN rn1 = 1 THEN exp_type END) AS highest_expense,
MAX(CASE WHEN rn2 =1 THEN exp_type END) AS lowest_expense
FROM Rnk_high_low
GROUP BY city;
					

-- 6. Write a query to find percentage contribution of spends by females for each expense type

WITH total_cte AS
(
SELECT exp_type, SUM(amount) AS t_total FROM credit_card
GROUP BY exp_type) ,

 f_sum_cte AS (
SELECT exp_type, SUM(amount) as f_total FROM credit_card
WHERE gender = 'F'
GROUP BY exp_type)

SELECT c1.exp_type, ROUND((100.0* ISNULL(f_total,0)/t_total),2) AS percentage FROM total_cte c1 
 LEFT JOIN f_sum_cte c2 
ON c1.exp_type = c2.exp_type


-- 7. Which card and expense type combination saw the 
-- highest month-over-month growth in January 2014?

WITH CTE AS (

SELECT exp_type, card_type, FORMAT(transaction_date, 'yyyy-MM') AS ymth, 
SUM(amount) AS total_amount FROM credit_card
GROUP BY exp_type, card_type, FORMAT(transaction_date, 'yyyy-MM')),

prev_sale AS (
SELECT *, LAG(total_amount) OVER (PARTITION BY exp_type, card_type ORDER BY ymth) AS prev_sales
FROM CTE)

SELECT top 1 *, ROUND((100.0* total_amount-prev_sales/prev_sales),2) AS mom_growth FROM prev_sale
WHERE ymth = '2014-01'
ORDER BY mom_growth DESC




-- 8. During weekends, which city has the highest total spend to total number of transactions ratio?


WITH weekend as(
SELECT city, SUM(amount) AS total_amount, COUNT(*) As Txn_count
FROM credit_card
WHERE DATEPART(WEEKDAY,transaction_date) IN(1,7)
GROUP BY city)

SELECT TOP 1 city, total_amount/txn_count AS txn_ratio FROM weekend
ORDER BY txn_ratio DESC;




-- 9. Which city took the least number of days to reach 
-- its 500th transaction after the first transaction in that city?

WITH txn_order AS (
SELECT *, ROW_NUMBER()OVER(PARTITION BY city ORDER BY transaction_date, transaction_id) AS rn
FROM credit_card),
dates AS(
SELECT city, 
MIN(CASE WHEN rn = 1 THEN transaction_date END) AS first_date,
MIN(CASE WHEN rn = 500 THEN transaction_date END) AS to_500th_date
FROM txn_order
GROUP BY city
HAVING COUNT(*) >= 500)

SELECT top 1 *, DATEDIFF(DAY,first_date, to_500th_date) AS no_of_days FROM dates
ORDER BY no_of_days ASC

