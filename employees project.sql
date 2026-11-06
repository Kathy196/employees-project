# Employee Database Project


USE employees;

SELECT * FROM departments;

SELECT * FROM dept_emp LIMIT 10;

SELECT * FROM dept_manager;

SELECT * FROM employees LIMIT 10;

SELECT * FROM salaries LIMIT 10;

SELECT * FROM titles ;



# 1. The current department of each employee   
/*
findings : The Company should carefully look after and care for the employees who 
have been with us since 1985 and are still here today.
*/

SELECT 
	d_e.emp_no,
    CONCAT(e.first_name, " ", e.last_name) AS employee_name,
    e.gender,
    d.dept_name,
    d_e.from_date,
    d_e.to_date
FROM dept_emp d_e
JOIN departments d
	ON d_e.dept_no = d.dept_no

JOIN employees e
	ON e.emp_no = d_e.emp_no
WHERE to_date = "9999-01-01";


-- -----
# 2. Top 5 Highest-Paid Employees by Department and Gender (with Average Comparison)
/*
Finding : The highest average salary is in the Sales Departments.
*/

WITH salary_table AS (
SELECT 
	e.emp_no,
    e.gender,
    s.salary,
    COUNT(s.salary) OVER(PARTITION BY e.emp_no ORDER BY s.salary) AS salary_count,
    AVG(s.salary) OVER(PARTITION BY e.emp_no ORDER BY s.salary) AS avg_salary
FROM employees e 
JOIN salaries s 
	ON e.emp_no = s.emp_no),

department_table AS (
SELECT 
	de.emp_no,
    d.dept_name
    
FROM departments d 
JOIN dept_emp de 
	ON d.dept_no = de.dept_no)

SELECT 
	department_table.dept_name,
    salary_table.gender,
    salary_table.salary_count,
    salary_table.avg_salary
FROM salary_table 
JOIN department_table 
	ON salary_table.emp_no = department_table.emp_no
ORDER BY salary_table.avg_salary DESC;


-- -----
# 3. Departments with average salary above 70,000  
/*
Findings : The average salary is above $70000 in 5 Departments : Marketing, Sales, Research,
Quality Management and Finance. There are 7 employees in total. 
*/

SELECT
	s.emp_no,
    d_e.dept_no,
    d.dept_name,
    s.avg_salary

FROM
(SELECT 
	emp_no,
    ROUND(AVG(salary)) AS avg_salary
FROM salaries
GROUP BY emp_no
HAVING AVG(salary) > 70000) AS s

JOIN
(SELECT 
	emp_no,
    dept_no
FROM dept_manager) AS d_e
ON s.emp_no = d_e.emp_no

JOIN 
(SELECT 
	dept_no,
    dept_name
FROM departments) AS d
ON d.dept_no = d_e.dept_no
ORDER BY s.avg_salary DESC;


-- -----
#4. The most common job title for each department     
/*
Finding : The most common job titles are 'Engineer' in the Development department (58135),
'Engineer' in Production (49649) and 'Senior Engineer' in Development (49326).
*/
  
SELECT 
	d.dept_name,
    t.title,
    COUNT(*) AS title_count,
    RANK() OVER(PARTITION BY d.dept_no) AS rank_count,
    ROW_NUMBER() OVER(PARTITION BY d.dept_no ORDER BY title DESC) AS row_counts
FROM titles t
JOIN dept_emp de 
	ON t.emp_no = de.emp_no 
JOIN departments d 
	ON d.dept_no = de.dept_no 
GROUP BY d.dept_name,t.title;

-- ----- (option 2)

WITH job_count AS (
SELECT 
	d.dept_name,
    t.title,
    COUNT(*) AS title_count,
    RANK() OVER(PARTITION BY d.dept_name ) AS rank_count,
    ROW_NUMBER() OVER(PARTITION BY d.dept_name ORDER BY COUNT(*) DESC) AS row_counts
FROM titles t 
JOIN dept_emp de 
	ON t.emp_no = de.emp_no 
JOIN departments d 
	ON d.dept_no = de.dept_no 
GROUP BY d.dept_name,t.title)

SELECT 
	dept_name,
	title,
    title_count,
    rank_count,
    row_counts
FROM job_count
ORDER BY title_count DESC;


-- ---- 
# 5. Employees who have changed departments more than 1 time      
/*
Finding : Most employees changed departments 2 times
*/

SELECT 
	e.emp_no,
    CONCAT(e.first_name, " ", e.last_name) AS employee_name,
    COUNT(dept_emp.dept_no) 
FROM employees e

JOIN dept_emp
	ON e.emp_no = dept_emp.emp_no
    
GROUP BY e.emp_no,
	employee_name
HAVING COUNT(dept_emp.dept_no) > 1;

-- -- (option 2)

WITH dept_changed AS (
SELECT 
	e.emp_no,
    CONCAT(e.first_name, " ", e.last_name) AS employee_name,
    COUNT(dept_emp.dept_no) OVER(PARTITION BY e.emp_no) AS dept_count,
    d.dept_name,
    LAG(d.dept_name) OVER(PARTITION BY e.emp_no) AS previous_dept
FROM employees e

JOIN dept_emp
	ON e.emp_no = dept_emp.emp_no
    
JOIN departments d 
	ON d.dept_no = dept_emp.dept_no)

SELECT 
	emp_no,
    employee_name,
    dept_name,
    previous_dept
FROM dept_changed
WHERE dept_count > 1;

--  ----
# 6. Salary growth percentage for each employee      
/*
Finding : Salary growth ranged from negative percentages up to a maximum of 7%
*/

WITH e AS
(SELECT 
	emp_no,
    first_name,
    last_name,
    gender
FROM employees),
s AS 
(SELECT 
	emp_no,
    salary,
    LAG(salary) OVER(PARTITION BY emp_no ) AS previous_salary
FROM salaries)

SELECT 
	e.emp_no,
    e.first_name,
    e.last_name,
    e.gender,
    s.salary,
    s.previous_salary,
    CONCAT(ROUND(((s.salary-s.previous_salary)/ s.previous_salary)*100),"%") AS salary_growth_pct
FROM e
JOIN s
	ON e.emp_no = s.emp_no;


-- ---
# 7. Departments with the most gender diversity  (the count of male and female employees per department)
/*
Finding : Every Department has more Male than Female employees, with the 'Development' department
having the largest number of employees overall. 
*/

SELECT 
    d.dept_name,
    SUM(CASE gender WHEN "M" THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE gender WHEN "F" THEN 1 ELSE 0 END) AS female_count,
    COUNT(*) AS total_employees
    
FROM employees e

JOIN dept_emp
	ON e.emp_no = dept_emp.emp_no

JOIN departments d
	ON d.dept_no = dept_emp.dept_no

GROUP BY d.dept_name
ORDER BY total_employees DESC;

-- -----
# 8. Each department manager’s average managed salary    
/*
Finding : The managers in the 'Marketing' and 'Sales' departments earn the highest average salaries. 
*/

SELECT 
	dm.emp_no,
    dm.dept_no,
    ROUND(AVG(s.salary)) AS avg_salary
FROM employees e
JOIN dept_manager dm 
	ON e.emp_no = dm.emp_no 
JOIN salaries s
	ON s.emp_no = e.emp_no
GROUP BY dm.dept_no,dm.emp_no
ORDER BY avg_salary DESC;



/* 9. Create a view of current employees with salary information,       
then create a stored procedure to generate department-level summaries.
*/


CREATE VIEW current_employees_salary AS
SELECT 
	e.emp_no,
    e.first_name,
    e.last_name,
    e.gender,
    s.salary,
    s.from_date,
    s.to_date
    
FROM employees e
JOIN salaries s 
	ON e.emp_no = s.emp_no 
WHERE to_date = "9999-01-01";

SELECT * FROM current_employees_salary;

-- ----- -----

DELIMITER $$
CREATE PROCEDURE departmentlevel(
IN deptName VARCHAR(40)
)
BEGIN
SELECT 
	d.dept_name,
    
    SUM(s.salary) AS total_spent ,
    ROUND(AVG(s.salary)) AS average_spent
FROM dept_emp de
JOIN salaries s 
	ON de.emp_no = s.emp_no 
JOIN departments d 
	ON d.dept_no = de.dept_no
WHERE s.to_date = "9999-01-01"
GROUP BY d.dept_name
ORDER BY total_spent DESC;
END $$
DELIMITER ;

CALL departmentlevel("Sales");

