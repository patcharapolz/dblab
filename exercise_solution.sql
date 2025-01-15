-- Exercise 1: INNER JOIN
-- Objective: Retrieve a list of customers and their orders, including the customer name, order ID, and order date.
-- Solution:
-- We'll perform an INNER JOIN between the Customers and Orders tables. This will give us only the customers who have placed orders.

SELECT customers.customer_id, customers.contact_name, orders.order_id, orders.order_date
FROM customers
INNER JOIN orders ON customers.customer_id = orders.customer_id;

-- Exercise 2: LEFT OUTER JOIN
-- Objective: Retrieve a list of all customers and their orders, including customers who have not placed any orders.
-- Solution:
-- We'll use a LEFT JOIN to get all customers, even those who haven't placed any orders. This ensures that customers without orders will be included in the result set, with NULL values for the order-related columns.

SELECT customers.customer_id, customers.contact_name, orders.order_id, orders.order_date
FROM customers
LEFT JOIN orders ON customers.customer_id = orders.customer_id;

-- Exercise 3: RIGHT OUTER JOIN
-- Objective: Retrieve a list of all orders and the customers who placed them, even if some orders do not have an associated customer.
-- Solution:
-- We'll use a RIGHT JOIN to ensure we get all orders, even if some orders have no corresponding customer (e.g., due to missing or invalid customer information).
SELECT customers.customer_id, customers.contact_name, orders.order_id, orders.order_date
FROM customers
RIGHT JOIN orders ON customers.customer_id = orders.customer_id;

-- Exercise 4: FULL OUTER JOIN
-- Objective: Retrieve a list of all customers and all orders, including customers who have not placed any orders and orders with no corresponding customer.
-- Solution:
-- We'll use a FULL OUTER JOIN to get all customers and all orders, regardless of whether there is a match.
SELECT customers.customer_id, customers.contact_name, orders.order_id, orders.order_date
FROM customers
FULL OUTER JOIN orders ON customers.customer_id = orders.customer_id;

-- Exercise 5: Combining Multiple JOINs
-- Objective: Retrieve the list of customers, their orders, and the employees who processed those orders. Include customers who haven’t placed any orders, and orders with no assigned employees.
-- Solution:
-- We'll use LEFT JOIN between Customers and Orders, and then a LEFT JOIN between Orders and Employees. This ensures that we get all customers, all orders, and the employee who processed the order (if available).
SELECT customers.customer_id, customers.contact_name, orders.order_id, orders.order_date,
       employees.first_name AS employee_first_name, employees.last_name AS employee_last_name
FROM customers
LEFT JOIN orders ON customers.customer_id = orders.customer_id
LEFT JOIN employees ON orders.employee_id = employees.employee_id;


-- Exercise 1: Count the Number of Orders for Each Customer
-- Objective: Retrieve the number of orders placed by each customer.
-- Solution:
-- We will use the COUNT() function to count the number of orders for each customer, grouped by customer_id.
SELECT customers.customer_id, customers.contact_name, COUNT(orders.order_id) AS order_count
FROM customers
LEFT JOIN orders ON customers.customer_id = orders.customer_id
GROUP BY customers.customer_id, customers.contact_name
ORDER BY order_count DESC;

-- Exercise 2: Total Sales for Each Employee
-- Objective: Calculate the total sales (order amount) processed by each employee.
-- Solution:
-- We will join the Orders table with the OrderDetails table to get the total sales per employee. The total sales will be the sum of unit_price * quantity for each order processed by an employee.
SELECT employees.first_name, employees.last_name, SUM(order_details.unit_price * order_details.quantity) AS total_sales
FROM employees
JOIN orders ON employees.employee_id = orders.employee_id
JOIN order_details ON orders.order_id = order_details.order_id
GROUP BY employees.employee_id, employees.first_name, employees.last_name
ORDER BY total_sales DESC;

-- Exercise 3: Average Order Value
-- Objective: Calculate the average value of orders placed by customers.
-- Solution:
-- We will use the AVG() function to calculate the average value of each order, and we’ll group by customer_id to get this per customer.

SELECT customers.customer_id, customers.contact_name, AVG(order_details.unit_price * order_details.quantity) AS avg_order_value
FROM customers
JOIN orders ON customers.customer_id = orders.customer_id
JOIN order_details ON orders.order_id = order_details.order_id
GROUP BY customers.customer_id, customers.contact_name
ORDER BY avg_order_value DESC;


-- Exercise 4: Find the Most Expensive Product Sold
-- Objective: Retrieve the most expensive product sold by calculating the maximum price from the order_details table.
-- Solution:
-- We will use the MAX() function to find the highest price for products sold.

SELECT products.product_name, MAX(order_details.unit_price) AS max_price
FROM products
JOIN order_details ON products.product_id = order_details.product_id
GROUP BY products.product_name
ORDER BY max_price DESC
LIMIT 1;


-- Exercise 5: Total Quantity Ordered for Each Product
-- Objective: Calculate the total quantity of each product ordered.
-- Solution:
-- We will use the SUM() function to calculate the total quantity of each product ordered by customers.

SELECT products.product_name, SUM(order_details.quantity) AS total_quantity_ordered
FROM products
JOIN order_details ON products.product_id = order_details.product_id
GROUP BY products.product_name
ORDER BY total_quantity_ordered DESC;


-- Exercise 2: Find Products That Have Never Been Ordered
-- Objective: Retrieve a list of products that have never been ordered.
-- Solution:
-- We will use a LEFT JOIN between the Products table and the OrderDetails table to identify products that don't appear in the OrderDetails.
SELECT products.product_name
FROM products
LEFT JOIN order_details ON products.product_id = order_details.product_id
WHERE order_details.product_id IS NULL;

-- Exercise 4: Find Customers Who Have Placed Orders in Both 1996 and 1997
-- Objective: Retrieve a list of customers who have placed orders in both 1996 and 1997.
-- Solution:
-- We will use a subquery to first identify customers who have placed orders in 1996, then check for those who have also placed orders in 1997.

SELECT DISTINCT customers.customer_id, customers.contact_name
FROM customers
WHERE customers.customer_id IN (
    SELECT orders.customer_id
    FROM orders
    WHERE EXTRACT(YEAR FROM orders.order_date) = 1996
)
AND customers.customer_id IN (
    SELECT orders.customer_id
    FROM orders
    WHERE EXTRACT(YEAR FROM orders.order_date) = 1997
);


-- Exercise 5: List Products That Were Ordered More Than 100 Times in Total
-- Objective: Retrieve a list of products that have been ordered more than 100 times in total across all orders.
-- Solution:
-- We will use a GROUP BY query with the SUM() function to calculate the total quantity ordered for each product. Then, we filter to only include products with more than 100 total orders.

SELECT products.product_name, SUM(order_details.quantity) AS total_quantity_ordered
FROM products
JOIN order_details ON products.product_id = order_details.product_id
GROUP BY products.product_name
HAVING SUM(order_details.quantity) > 100;

-- Exercise 6: Find the Employee Who Processed the Most Expensive Order
-- Objective: Identify the employee who processed the most expensive order based on the total price (sum of unit_price * quantity for all items in the order).
-- Solution:
-- We will first calculate the total price for each order and then find the employee who processed the highest-value order.

SELECT employees.first_name, employees.last_name, orders.order_id, 
       SUM(order_details.unit_price * order_details.quantity) AS total_order_value
FROM employees
JOIN orders ON employees.employee_id = orders.employee_id
JOIN order_details ON orders.order_id = order_details.order_id
GROUP BY employees.employee_id, employees.first_name, employees.last_name, orders.order_id
ORDER BY total_order_value DESC
LIMIT 1;

-- Exercise 7: List the Top 5 Products by Total Sales Value
-- Objective: Retrieve the top 5 products based on their total sales value (total revenue generated by each product, calculated as unit_price * quantity).
-- Solution:
-- We will calculate the total sales for each product, then order the results by total sales value in descending order and limit the result to the top 5.

SELECT products.product_name, SUM(order_details.unit_price * order_details.quantity) AS total_sales_value
FROM products
JOIN order_details ON products.product_id = order_details.product_id
GROUP BY products.product_name
ORDER BY total_sales_value DESC
LIMIT 5;


-- Gamification
-- 1. สร้างร้านค้าออนไลน์ของคุณเอง!
-- คำถาม: สมมติว่าคุณกำลังเปิดร้านค้าออนไลน์ที่ขายสินค้าหลายประเภท คุณต้องการจะตั้งโปรโมชันให้ลูกค้าที่ซื้อสินค้าหลายชนิดจากหลายหมวดหมู่โดยเฉพาะ ลูกค้าที่สั่งซื้อสินค้าใน 3 หมวดหมู่ขึ้นไปจะได้รับส่วนลด 10% สำหรับการซื้อครั้งถัดไป
-- โจทย์: เขียน query เพื่อหาลูกค้าที่ซื้อสินค้า 3 หมวดหมู่ขึ้นไป
-- Query ตัวอย่าง:
SELECT c.company_name, COUNT(DISTINCT p.category_id) AS category_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
GROUP BY c.company_name
HAVING COUNT(DISTINCT p.category_id) >= 3
ORDER BY category_count DESC;

-- 2. ติดตามการพัฒนาผลิตภัณฑ์ใหม่
-- คำถาม: คุณกำลังจะเปิดตัวผลิตภัณฑ์ใหม่ และต้องการรู้ว่าผลิตภัณฑ์ไหนที่ได้รับความนิยมมากที่สุดหลังจากการเปิดตัว
-- โจทย์: เขียน query ที่สามารถติดตามยอดขายของผลิตภัณฑ์ใหม่ๆ ในช่วงเวลา 6 เดือนแรก
-- Query ตัวอย่าง:
WITH product_sales AS (
    SELECT p.product_name, EXTRACT(MONTH FROM o.order_date) AS sale_month,
           SUM(od.quantity * od.unit_price) AS total_sales
    FROM products p
    JOIN order_details od ON p.product_id = od.product_id
    JOIN orders o ON od.order_id = o.order_id
    WHERE o.order_date >= '1997-01-01' AND o.order_date <= '1997-06-30'
    GROUP BY p.product_name, EXTRACT(MONTH FROM o.order_date)
)
SELECT product_name, SUM(total_sales) AS total_sales_in_6_months
FROM product_sales
GROUP BY product_name
HAVING SUM(total_sales) > 1000
ORDER BY total_sales_in_6_months DESC;


-- 3. จัดอันดับผลิตภัณฑ์ตามความต้องการ
-- คำถาม: คุณต้องการดูว่าในแต่ละเดือนสินค้าประเภทไหนได้รับความนิยมสูงสุดจากคำสั่งซื้อ
-- โจทย์: เขียน query เพื่อหาผลิตภัณฑ์ที่มีการขายดีที่สุดในแต่ละเดือน
-- Query ตัวอย่าง:
WITH monthly_sales AS (
    SELECT p.product_name, EXTRACT(MONTH FROM o.order_date) AS sale_month,
           SUM(od.quantity) AS total_sold
    FROM order_details od
    JOIN products p ON od.product_id = p.product_id
    JOIN orders o ON od.order_id = o.order_id
    GROUP BY p.product_name, EXTRACT(MONTH FROM o.order_date)
)
SELECT sale_month, product_name, total_sold
FROM (
    SELECT sale_month, product_name, total_sold,
           ROW_NUMBER() OVER (PARTITION BY sale_month ORDER BY total_sold DESC) AS rank
    FROM monthly_sales
) AS ranked
WHERE rank = 1
ORDER BY sale_month;


-- 4. ติดตามคำสั่งซื้อที่ผิดปกติ
-- คำถาม: คุณต้องการหาคำสั่งซื้อที่มีการซื้อสินค้าจำนวนมากเกินไป หรือราคาสูงผิดปกติ
-- โจทย์: เขียน query เพื่อหาออร์เดอร์ที่มีจำนวนสินค้ามากเกินไปหรือราคาสูงเกินมาตรฐาน (อาจตั้งเงื่อนไขเป็น 1000 หน่วยหรือราคาสูงกว่าราคาปกติที่เฉลี่ย)
-- Query ตัวอย่าง:
SELECT o.order_id, o.order_date, c.company_name, p.product_name, od.quantity, od.unit_price,
       od.quantity * od.unit_price AS total_price
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE od.quantity > 1000 OR od.quantity * od.unit_price > 5000
ORDER BY total_price DESC;

-- 5. สร้างรายงานคำสั่งซื้อที่ส่งช้า
-- คำถาม: ค้นหาคำสั่งซื้อที่มีการจัดส่งช้ากว่าปกติ (เกินกว่า 10 วัน) และลูกค้าที่มีการสั่งซื้อมากที่สุด
-- โจทย์: เขียน query เพื่อหาคำสั่งซื้อที่มีการจัดส่งช้า และคำนวณระยะเวลาการจัดส่ง
-- Query ตัวอย่าง:

SELECT o.order_id, c.company_name, o.order_date, o.shipped_date,
       (o.shipped_date - o.order_date) AS shipping_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.shipped_date IS NOT NULL
  AND (o.shipped_date - o.order_date) > 10
ORDER BY shipped_date, shipping_days DESC;

-- 6. การคำนวณยอดขายเฉลี่ยของลูกค้า
-- คำถาม: คุณต้องการทราบยอดขายเฉลี่ยของลูกค้าจากทุกคำสั่งซื้อที่พวกเขาทำ
-- โจทย์: เขียน query เพื่อหายอดขายเฉลี่ยจากการสั่งซื้อของลูกค้าแต่ละราย
-- Query ตัวอย่าง:
SELECT c.company_name, AVG(od.quantity * od.unit_price) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.company_name
ORDER BY avg_order_value DESC;


-- 7. การค้นหาผลิตภัณฑ์ที่ไม่ได้ถูกสั่งซื้อมานาน มากกว่า 1 ปี
-- คำถาม: คุณต้องการหาผลิตภัณฑ์ที่ไม่ได้ถูกสั่งซื้อมานาน (ตั้งแต่วันที่สั่งซื้อล่าสุด)
-- โจทย์: เขียน query เพื่อหาผลิตภัณฑ์ที่ไม่ได้ถูกสั่งซื้อมานานที่สุด
-- Query ตัวอย่าง:
SELECT p.product_name
FROM products p
LEFT JOIN order_details od ON p.product_id = od.product_id
LEFT JOIN orders o ON od.order_id = o.order_id
WHERE o.order_date IS NULL OR o.order_date < CURRENT_DATE - INTERVAL '1 year';


-- 8. การหาลูกค้าที่ซื้อสินค้าหลายประเภทมากที่สุด
-- คำถาม: ค้นหาลูกค้าที่ซื้อสินค้าหลายประเภท (category) มากที่สุด
-- โจทย์: เขียน query ที่คำนวณจำนวนหมวดหมู่ที่ลูกค้าซื้อสินค้าหลายประเภท
-- Query ตัวอย่าง:
SELECT c.company_name, COUNT(DISTINCT p.category_id) AS category_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
JOIN products p ON od.product_id = p.product_id
GROUP BY c.company_name
ORDER BY category_count DESC
LIMIT 10;


-- 9. การจัดอันดับการขายตามประเทศ
-- คำถาม: คุณต้องการทราบว่ายอดขายรวมในแต่ละประเทศเป็นอย่างไร
-- โจทย์: เขียน query เพื่อติดตามยอดขายรวมจากลูกค้าในแต่ละประเทศ
-- Query ตัวอย่าง:
SELECT c.country, SUM(od.quantity * od.unit_price) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.country
ORDER BY total_sales DESC;


-- 10. หาผลิตภัณฑ์ที่มียอดขายต่ำสุดในแต่ละปี
-- คำถาม: ค้นหาผลิตภัณฑ์ที่มียอดขายต่ำสุดในแต่ละปี
-- โจทย์: เขียน query เพื่อหาผลิตภัณฑ์ที่มียอดขายต่ำสุดในแต่ละปี
-- Query ตัวอย่าง:
WITH yearly_sales AS (
    SELECT p.product_name, EXTRACT(YEAR FROM o.order_date) AS sale_year,
           SUM(od.quantity * od.unit_price) AS total_sales
    FROM order_details od
    JOIN products p ON od.product_id = p.product_id
    JOIN orders o ON od.order_id = o.order_id
    GROUP BY p.product_name, EXTRACT(YEAR FROM o.order_date)
)
SELECT sale_year, product_name, total_sales
FROM (
    SELECT sale_year, product_name, total_sales,
           RANK() OVER (PARTITION BY sale_year ORDER BY total_sales ASC) AS rank
    FROM yearly_sales
) AS ranked
WHERE rank = 1
ORDER BY sale_year;

