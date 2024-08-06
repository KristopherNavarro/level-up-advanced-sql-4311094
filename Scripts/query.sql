
SELECT sql
FROM sqlite_schema
WHERE name = 'employee';

-- Create a list of employees and their immediate managers
SELECT employee.firstName AS employee_first, 
  employee.lastName AS employee_last, 
  manager.firstName AS manager_first, 
  manager.lastName AS manager_last
FROM employee
INNER JOIN employee AS manager
ON manager.employeeId = employee.managerId;

-- Find salespeople who have zero sales
SELECT emp.employeeId,
  emp.firstName, 
  emp.lastName,
  emp.title,
  COUNT(sales.salesId) AS num_sales
FROM employee AS emp
LEFT JOIN sales
ON emp.employeeId = sales.employeeId
WHERE emp.title = 'Sales Person'
GROUP BY emp.employeeId
HAVING num_sales = 0;


-- How many cars have been sold per employee?
SELECT emp.employeeId,
  emp.firstName, 
  emp.lastName,
  COUNT(sales.salesId) AS cars_sold
FROM employee AS emp
  INNER JOIN sales
    ON emp.employeeId = sales.employeeId
GROUP BY emp.employeeId, 
  emp.firstName, 
  emp.lastName
ORDER BY cars_sold DESC;

-- Produce a report that lists the least and most expensive car sold by each employee this year (2023)
SELECT emp.employeeId, 
    emp.firstName, 
    emp.lastName, 
    COUNT(sls.salesId) AS number_of_sales,
    MIN(sls.salesAmount) AS min_sale, 
    MAX(sls.salesAmount) AS max_sale
FROM employee AS emp
INNER JOIN sales AS sls
  ON emp.employeeId = sls.employeeId
WHERE strftime('%Y',sls.soldDate) = "2023"
GROUP BY emp.employeeId, emp.firstName, emp.lastName
ORDER BY max_sale DESC;

-- Get a list of employees who have made more than five sales this year
SELECT emp.employeeId,
    emp.firstName,
    emp.lastName,
    COUNT(sls.salesId) AS number_of_sales
FROM employee AS emp
INNER JOIN sales AS sls 
    ON emp.employeeId = sls.employeeId
WHERE strftime('%Y', sls.soldDate) = "2023"
GROUP BY emp.employeeId, emp.firstName, emp.lastName
HAVING number_of_sales > 5
ORDER BY number_of_sales DESC;

-- Summarize sales per year by using a CTE
WITH sales_by_year AS (
    SELECT ROUND(SUM(salesAmount),2) AS total_sales, strftime('%Y',soldDate) AS year
    FROM sales
    GROUP BY year
)

SELECT year, FORMAT('$%.2f',total_sales) AS total_sales -- FORMAT taken from answer
FROM sales_by_year
ORDER BY year;

-- Display the number of sales for each employee by month for 2021 (think about using CASE statements)
-- each employee should be one row, with columns for the aggregated sales for each month
WITH employee_sales AS (
    SELECT emp.employeeId, 
        emp.firstName, 
        emp.lastName,
        sls.salesAmount,
        strftime('%m', sls.soldDate) AS month,
        strftime('%Y', sls.soldDate) AS year
    FROM sales AS sls 
      INNER JOIN employee AS emp 
        ON sls.employeeId = emp.employeeId
  )

SELECT employeeId,
    firstName,
    lastName,
    SUM(CASE WHEN month = '01' THEN salesAmount ELSE 0 END) AS Jan_Sales,
    SUM(CASE WHEN month = '02' THEN salesAmount ELSE 0 END) AS Feb_Sales,
    SUM(CASE WHEN month = '03' THEN salesAmount ELSE 0 END) AS Mar_Sales,
    SUM(CASE WHEN month = '04' THEN salesAmount ELSE 0 END) AS Apr_Sales,
    SUM(CASE WHEN month = '05' THEN salesAmount ELSE 0 END) AS May_Sales,
    SUM(CASE WHEN month = '06' THEN salesAmount ELSE 0 END) AS Jun_Sales,
    SUM(CASE WHEN month = '07' THEN salesAmount ELSE 0 END) AS Jul_Sales,
    SUM(CASE WHEN month = '08' THEN salesAmount ELSE 0 END) AS Aug_Sales,
    SUM(CASE WHEN month = '09' THEN salesAmount ELSE 0 END) AS Sep_Sales,
    SUM(CASE WHEN month = '10' THEN salesAmount ELSE 0 END) AS Oct_Sales,
    SUM(CASE WHEN month = '11' THEN salesAmount ELSE 0 END) AS Nov_Sales,
    SUM(CASE WHEN month = '12' THEN salesAmount ELSE 0 END) AS Dec_Sales,
    SUM(salesAmount) AS Total_Sales
FROM employee_sales
WHERE year = '2021'
GROUP BY employeeId,
    firstName,
    lastName
ORDER BY employeeId
    
    
-- Find the sales of cars that are electric by using a subquery
SELECT salesAmount
FROM sales
WHERE inventoryId = (
    SELECT inv.inventoryId
    FROM inventory AS inv
      INNER JOIN model AS mod
        ON inv.modelId = mod.modelId
    WHERE mod.EngineType = 'Electric'
);
-- -- ANSWER:
SELECT sls.soldDate, sls.salesAmount, inv.colour, inv.year
FROM sales AS sls 
INNER JOIN inventory AS inv 
  ON sls.inventoryId = inv.inventoryId
WHERE inv.modelId IN (
  SELECT modelId
  FROM model
  WHERE EngineType = 'Electric'
);

-- Get a list of sales people and rank the car models they've sold the most of
-- Tables: employee > sales > inventory > model

SELECT emp.firstName,
    emp.lastName,
    RANK() OVER (ORDER BY mod.model) as Model_rank

FROM employee AS emp 
INNER JOIN sales AS sls
  ON emp.employeeId = sls.employeeId
    INNER JOIN inventory AS inv
      ON sls.inventoryId = inv.inventoryId
        INNER JOIN model AS mod
          ON inv.modelId = mod.modelId
GROUP BY emp.firstName, emp.lastName;

-- -- ANSWER:
-- -- first join the tables to get the necessary data
SELECT emp.firstName, emp.lastName, mdl.model, sls.salesId
FROM sales AS sls 
INNER JOIN employee AS emp 
  ON sls.employeeId = emp.employeeId
INNER JOIN inventory AS inv 
  ON inv.inventoryId = sls.inventoryId
INNER JOIN model AS mdl 
  ON mdl.modelId = inv.modelId

-- -- apply the grouping
SELECT emp.firstName, emp.lastName, mdl.model,
    COUNT(model) AS NumberSold
FROM sales AS sls 
INNER JOIN employee AS emp 
  ON sls.employeeId = emp.employeeId
INNER JOIN inventory AS inv 
  ON inv.inventoryId = sls.inventoryId
INNER JOIN model AS mdl 
  ON mdl.modelId = inv.modelId
GROUP BY emp.firstName, emp.lastName, mdl.model

-- -- add in the windowing function
SELECT emp.firstName, emp.lastName, mdl.model, 
    COUNT(model) AS NumberSold,
    RANK() OVER (PARTITION BY sls.employeeId
                  ORDER BY COUNT(model) DESC) AS Rank
FROM sales AS sls 
INNER JOIN employee AS emp 
  ON sls.employeeId = emp.employeeId
INNER JOIN inventory AS inv 
  ON inv.inventoryId = sls.inventoryId
INNER JOIN model AS mdl 
  ON mdl.modelId = inv.modelId
GROUP BY emp.firstName, emp.lastName, mdl.model

-- Generate a sales report showing total sales per month and an annual running total
-- -- ANSWER: 
-- -- get the needed data
SELECT strftime('%Y', soldDate) AS soldYear,
    strftime('%m', soldDate) AS soldMonth,
    salesAmount
FROM sales 

-- -- apply the grouping
SELECT strftime('%Y', soldDate) AS soldYear,
    strftime('%m', soldDate) AS soldMonth,
    salesAmount
FROM sales 
GROUP BY soldYear, soldMonth
ORDER BY soldYear, soldMonth

-- -- add the window function - simplify with cte
WITH cte_sales AS (
  SELECT strftime('%Y', soldDate) AS soldYear,
    strftime('%m', soldDate) AS soldMonth,
    SUM(salesAmount) AS salesAmount
  FROM sales 
  GROUP BY soldYear, soldMonth
)
SELECT soldYear, soldMonth, salesAmount,
  SUM(salesAmount) OVER (
    PARTITION BY soldYear
    ORDER BY soldYear, soldMonth) AS AnnualSales_RunningTotal
FROM cte_sales
ORDER BY soldYear, soldMonth

-- Create a report showing the number of cars sold this month and last month
-- -- ANSWER:
-- -- get the data
SELECT strftime('%Y-%m', soldDate) AS MonthSold,
  COUNT(*) AS NumberCarsSold
FROM sales
GROUP BY strftime('%Y-%m', soldDate)

-- -- Apply the window function
SELECT strftime('%Y-%m', soldDate) AS MonthSold,
  COUNT(*) AS NumberCarsSold,
  LAG (COUNT(*), 1, 0) OVER calMonth AS LastMonthCarsSold
FROM sales
GROUP BY strftime('%Y-%m', soldDate)
WINDOW calMonth AS (ORDER BY strftime('%Y-%m', soldDate))
ORDER BY strftime('%Y-%m', soldDate)