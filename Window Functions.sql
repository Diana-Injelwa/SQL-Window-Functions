USE sql_tutorials;

SELECT * FROM employee;
-- 1. ROW_NUMBER()
-- Fetch the first 2 employees to join the company from each department
/* To answer this question we assume that emp_id of
employees who joined earlier is smaller than that of 
employees who joine later on */ 
SELECT emp_id, emp_name, department
FROM(
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY department ORDER BY emp_id) AS rn
    FROM employee
) subquery
WHERE subquery.rn < 3;

-- 2. RANK()
-- Fetch top 3 employees earning the maximum salary in each department
SELECT emp_name, department, salary
FROM(
    SELECT *,
        RANK() OVER(PARTITION BY department ORDER BY salary DESC) AS rnk
    FROM employee
) subquery
WHERE subquery.rnk < 4;

-- Alternatively we can use DENSE_RANK() which gives the same results as RANK()
SELECT emp_name, department, salary
FROM(
    SELECT *,
        DENSE_RANK() OVER(PARTITION BY department ORDER BY salary DESC) AS d_rnk
    FROM employee
) subquery
WHERE subquery.d_rnk < 4;

-- LAG()
-- Check whether the salary of an employee is higher, lower or equal to the previous employee's salary
SELECT emp_id, emp_name, department, salary,
    CASE
        WHEN salary > previous_salary THEN "Higher than previous employee's salary"
        WHEN salary < previous_salary THEN "Lower than previous employee's salary"
        WHEN salary = previous_salary THEN "Same as previous employee's salary"
    END AS salary_comparison
FROM(
    SELECT *,
        LAG(salary) OVER(PARTITION BY department ORDER BY emp_id) AS previous_salary
    FROM employee    
) subquery;

-- LEAD()
-- Write a query to check if the salary of an employee is higher, equal or lower than the next employee
SELECT emp_id, emp_name, department, salary,
    CASE
        WHEN salary > next_emp_salary THEN "Higher than next employee's salary"
        WHEN salary < next_emp_salary THEN "Lower than next employee's salary"
        WHEN salary = next_emp_salary THEN "Same as next employee's salary"
    END AS next_salary_comparison
FROM(
    SELECT *,
        LEAD(salary) OVER(PARTITION BY department ORDER BY emp_id) AS next_emp_salary
    FROM employee
) subquery;

-- FIRST_VALUE()
-- What is the most expensive product under each category
SELECT *,
    FIRST_VALUE(product_name) OVER(PARTITION BY product_category ORDER BY price DESC) AS most_expensive_product
FROM product;

-- LAST_VALUE()
-- What is the least expensive product under each category
/* NOTE: It is important to specify the right Frame Clause when using LAST_VALUE() abd NTH_VALUE()
window function so as the function can have access to all the records of 
the partitions. The default Frame Clause in MySQL is 
"RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW" which we need to modify
to "RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING" in order to get
the correct results set */
SELECT *,
    LAST_VALUE(product_name)
        OVER(PARTITION BY product_category ORDER BY price DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS least_expensive_product
FROM product;

-- NTH_VALUE()
-- What is the 2nd most expensive product under each category
SELECT *,
    NTH_VALUE(product_name, 2)
        OVER(PARTITION BY product_category ORDER BY price DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS 2nd_most_exp_product
FROM product;

-- NTILE
-- Group all the Phones into expensive phones, mid range phones and cheaper phones
SELECT product_name, price,
    CASE
        WHEN buckets = 1 THEN 'Expensive'
        WHEN buckets = 2 THEN 'Mid-range'
        ELSE 'Cheaper'
    END AS price_bucket
FROM(
    SELECT *,
        NTILE(3) OVER(ORDER BY price DESC) AS buckets
    FROM product
    WHERE product_category = 'Phone'    
) subquery;

-- Using WINDOW clause in queries
-- Find the 2nd most expensive product and the least expensive product under each category
SELECT *,
    NTH_VALUE(product_name, 2) OVER w AS 2nd_most_exp_product,
    LAST_VALUE(product_name) OVER w AS least_expensive_product
FROM product
WINDOW w AS(PARTITION BY product_category ORDER BY price DESC
            RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING);

