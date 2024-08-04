SELECT firstName, lastName, title
FROM employee
LIMIT 5;

GO 

SELECT model, EngineType
FROM model
LIMIT 5;

SELECT sql
FROM sqlite_schema
WHERE name = 'employee';

SELECT * 
FROM employee
LIMIT 10;

-- 
SELECT employee.firstName AS employee_first, 
  employee.lastName AS employee_last, 
  manager.firstName AS manager_first, 
  manager.lastName AS manager_last
FROM employee
INNER JOIN employee AS manager
ON manager.employeeId = employee.managerId;

-- 
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

--
SELECT *
FROM sales
FULL JOIN customer
ON sales.customerId = customer.customerId;
-- the answer was three separate queries, utilizing UNION

--
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

--

