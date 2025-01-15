

-- 1. วิเคราะห์การทำกำไรจากแต่ละผลิตภัณฑ์
-- คำถาม:
-- จากข้อมูลการขายผลิตภัณฑ์ที่คุณมี คุณสามารถคำนวณได้หรือไม่ว่าผลิตภัณฑ์ใดทำกำไรให้กับบริษัทมากที่สุด? แล้วกำไรจากผลิตภัณฑ์ไหนที่ต่ำที่สุด?

-- โจทย์:
-- เขียน query ที่ช่วยให้คุณสามารถคำนวณกำไรจากการขายผลิตภัณฑ์แต่ละตัว โดยนำราคาขาย (unit_price) มาหักลบกับราคาต้นทุน (supplier_price) (คุณสามารถสมมติราคาต้นทุนหรือดึงข้อมูลจากตารางของ suppliers หากมีอยู่) จากนั้นคำนวณกำไรสะสมของแต่ละผลิตภัณฑ์

-- Solution: คำนวณกำไรจากการขายผลิตภัณฑ์แต่ละตัวโดยการหักลบ unit_price กับราคาต้นทุนสมมติ (หรือข้อมูลจาก suppliers) และคูณด้วยจำนวนที่ขาย สรุปกำไรสะสมทั้งหมดของแต่ละผลิตภัณฑ์ จัดเรียงผลิตภัณฑ์จากกำไรสูงสุดไปต่ำสุด

WITH product_profit AS (
    SELECT p.product_name, 
           SUM(od.quantity * (od.unit_price - p.supplier_price)) AS total_profit
    FROM products p
    JOIN order_details od ON p.product_id = od.product_id
    GROUP BY p.product_name
)
SELECT product_name, total_profit
FROM product_profit
ORDER BY total_profit DESC;
คำอธิบาย:


-- 2. การทำนายเทรนด์การขายในเดือนถัดไป
-- คำถาม:
-- คุณต้องการทำนายว่าผลิตภัณฑ์ไหนจะขายดีในเดือนถัดไป โดยการวิเคราะห์เทรนด์จากยอดขายในช่วงเดือนที่ผ่านมา คุณจะใช้ข้อมูลใดในการคาดการณ์?

-- โจทย์:
-- เขียน query ที่สามารถช่วยให้คุณหาผลิตภัณฑ์ที่มีการเติบโตยอดขายในแต่ละเดือน โดยเปรียบเทียบยอดขายเดือนนี้กับยอดขายเดือนก่อนหน้า และคำนวณอัตราการเติบโตของยอดขายจากผลิตภัณฑ์ที่ขายดีในเดือนล่าสุด
-- คำอธิบาย:

-- ใช้ LAG() เพื่อเปรียบเทียบยอดขายของเดือนปัจจุบันกับเดือนก่อนหน้า
-- คำนวณการเติบโตของยอดขายในแต่ละผลิตภัณฑ์
-- แสดงการเติบโตในรูปเปอร์เซ็นต์และจัดเรียงจากผลิตภัณฑ์ที่มีการเติบโตสูงสุด
-- Solution:

WITH monthly_sales AS (
    SELECT p.product_name, 
           EXTRACT(MONTH FROM o.order_date) AS sale_month,
           SUM(od.quantity * od.unit_price) AS total_sales
    FROM order_details od
    JOIN products p ON od.product_id = p.product_id
    JOIN orders o ON od.order_id = o.order_id
    GROUP BY p.product_name, EXTRACT(MONTH FROM o.order_date)
),
sales_growth AS (
    SELECT sale_month, 
           product_name, 
           total_sales,
           LAG(total_sales) OVER (PARTITION BY product_name ORDER BY sale_month) AS prev_month_sales
    FROM monthly_sales
)
SELECT sale_month, product_name, total_sales, 
       (total_sales - prev_month_sales) / prev_month_sales * 100 AS growth_percentage
FROM sales_growth
WHERE prev_month_sales IS NOT NULL
ORDER BY growth_percentage DESC;


-- 3. การวิเคราะห์ความสัมพันธ์ระหว่างการสั่งซื้อและจำนวนสินค้า
-- คำถาม:
-- การวิเคราะห์ของคุณจะบอกอะไรได้บ้างเกี่ยวกับความสัมพันธ์ระหว่างจำนวนสินค้าที่ลูกค้าซื้อกับมูลค่าของคำสั่งซื้อ? คำตอบนี้จะช่วยให้คุณปรับกลยุทธ์การขายหรือไม่?

-- โจทย์:
-- เขียน query ที่คำนวณความสัมพันธ์ระหว่างจำนวนสินค้าที่ซื้อ (quantity) กับมูลค่าของคำสั่งซื้อ (unit_price * quantity) เพื่อดูว่าการเพิ่มจำนวนสินค้าจะส่งผลต่อยอดขายอย่างไร
-- คำอธิบาย:

-- คำนวณความสัมพันธ์ระหว่างจำนวนสินค้าที่สั่งซื้อกับมูลค่าคำสั่งซื้อ
-- ใช้ HAVING เพื่อกรองคำสั่งซื้อที่มีจำนวนสินค้ามากกว่า 10
-- ช่วยให้ทราบว่าในคำสั่งซื้อที่มีจำนวนสินค้าสูง จะส่งผลต่อยอดขายอย่างไร
-- Solution:

SELECT SUM(od.quantity) AS total_quantity, 
       SUM(od.quantity * od.unit_price) AS total_sales_value
FROM order_details od
GROUP BY od.order_id
HAVING SUM(od.quantity) > 10;

-- 4. วิเคราะห์ลูกค้าที่มีการซื้อซ้ำบ่อยที่สุด
-- คำถาม:
-- คุณต้องการค้นหาลูกค้าที่มีการซื้อสินค้าบ่อยที่สุดในช่วงเวลาที่ผ่านมา และหาว่าลูกค้าเหล่านี้ซื้อสินค้าประเภทใดมากที่สุด

-- โจทย์:
-- เขียน query ที่สามารถหาลูกค้าที่มีการซื้อสินค้าหลายครั้ง (มีคำสั่งซื้อหลายครั้ง) และสินค้าประเภทใดที่พวกเขาซื้อบ่อยที่สุด
-- คำอธิบาย:

-- คำนวณจำนวนคำสั่งซื้อที่ลูกค้าทำ
-- กรองลูกค้าที่มีคำสั่งซื้อมากกว่า 3 ครั้ง
-- นำเสนอผลิตภัณฑ์ที่ลูกค้าซื้อบ่อยที่สุดจากกลุ่มลูกค้าที่ซื้อบ่อย
-- Solution:

WITH customer_orders AS (
    SELECT o.customer_id, COUNT(o.order_id) AS order_count
    FROM orders o
    GROUP BY o.customer_id
),
frequent_customers AS (
    SELECT c.customer_id, c.company_name, co.order_count
    FROM customers c
    JOIN customer_orders co ON c.customer_id = co.customer_id
    WHERE co.order_count > 3
),
top_products AS (
    SELECT o.customer_id, p.product_name, COUNT(od.product_id) AS product_count
    FROM order_details od
    JOIN orders o ON od.order_id = o.order_id
    JOIN products p ON od.product_id = p.product_id
    GROUP BY o.customer_id, p.product_name
)
SELECT fc.company_name, tp.product_name, tp.product_count
FROM frequent_customers fc
JOIN top_products tp ON fc.customer_id = tp.customer_id
ORDER BY tp.product_count DESC;


-- 5. การวิเคราะห์ยอดขายตามภูมิภาค
-- คำถาม:
-- จากข้อมูลการขายในแต่ละภูมิภาค คุณสามารถสรุปได้ไหมว่าภูมิภาคใดที่มียอดขายต่ำสุด? แล้วทำไมภูมิภาคนั้นถึงมียอดขายต่ำ?

-- โจทย์:
-- เขียน query ที่สามารถสรุปยอดขายรวมจากลูกค้าในแต่ละประเทศ และเปรียบเทียบว่าภูมิภาคไหนมีการขายดีที่สุดและภูมิภาคไหนมียอดขายต่ำสุด
-- คำอธิบาย:

-- คำนวณยอดขายรวมจากลูกค้าทุกคนในแต่ละประเทศ
-- สรุปยอดขายจากแต่ละภูมิภาคและจัดเรียงตามยอดขายจากมากไปน้อย
-- สามารถใช้ผลลัพธ์เพื่อวิเคราะห์ภูมิภาคที่มียอดขายต่ำสุดและค้นหาสาเหตุ เช่น สินค้าที่ไม่เป็นที่นิยมในภูมิภาคนั้น หรือการจัดส่งที่มีปัญหา

-- Solution:

SELECT c.country, SUM(od.quantity * od.unit_price) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.country
ORDER BY total_sales DESC;


-- 8. การวิเคราะห์ประสิทธิภาพการทำงานของพนักงานจากคำสั่งซื้อที่ได้รับมอบหมาย
-- คำถาม:
-- คุณต้องการทราบว่าแต่ละพนักงานมีประสิทธิภาพในการจัดการคำสั่งซื้อเป็นอย่างไร? โดยพิจารณาจากจำนวนคำสั่งซื้อที่พวกเขาจัดการได้ในแต่ละเดือน และจำนวนคำสั่งซื้อที่มีการจัดส่งแล้ว (shipped)

-- โจทย์:
-- เขียน query เพื่อหาคำสั่งซื้อที่แต่ละพนักงานได้จัดการ และคำนวณอัตราการเสร็จสิ้นคำสั่งซื้อ (คำสั่งซื้อที่จัดส่งแล้ว) โดยแยกตามเดือน
-- คำอธิบาย:

-- ใช้ข้อมูลจากตาราง orders เพื่อหาจำนวนคำสั่งซื้อที่พนักงานแต่ละคนจัดการในแต่ละเดือน
-- คำนวณอัตราการเสร็จสิ้นคำสั่งซื้อ (คำสั่งซื้อที่มี shipped_date เทียบกับคำสั่งซื้อทั้งหมด)
-- แสดงชื่อพนักงานพร้อมกับคำสั่งซื้อที่จัดการในแต่ละเดือน

-- Solution:

WITH employee_orders AS (
    SELECT o.employee_id,
           EXTRACT(MONTH FROM o.order_date) AS order_month,
           COUNT(o.order_id) AS total_orders,
           COUNT(CASE WHEN o.shipped_date IS NOT NULL THEN 1 END) AS completed_orders
    FROM orders o
    GROUP BY o.employee_id, EXTRACT(MONTH FROM o.order_date)
)
SELECT e.first_name || ' ' || e.last_name AS employee_name,
       eo.order_month,
       eo.total_orders,
       eo.completed_orders,
       (eo.completed_orders * 100.0 / eo.total_orders) AS completion_rate
FROM employees e
JOIN employee_orders eo ON e.employee_id = eo.employee_id
ORDER BY eo.order_month, completion_rate DESC;


-- 9. การวิเคราะห์ผลกระทบของพนักงานที่รับผิดชอบการขายในแต่ละภูมิภาค
-- คำถาม:
-- คุณต้องการวิเคราะห์ประสิทธิภาพของพนักงานที่ดูแลคำสั่งซื้อจากภูมิภาคต่าง ๆ และดูว่า พนักงานในภูมิภาคใดมียอดขายสูงสุด

-- โจทย์:
-- เขียน query เพื่อหาพนักงานที่ดูแลคำสั่งซื้อจากภูมิภาคต่าง ๆ โดยเปรียบเทียบยอดขายรวมในแต่ละภูมิภาค และดูว่าภูมิภาคใดที่พนักงานมีการขายสูงสุด
-- คำอธิบาย:

-- ใช้ข้อมูลจาก employees, orders, order_details, และ customers เพื่อหายอดขายรวมที่แต่ละพนักงานจัดการในแต่ละภูมิภาค
-- กลุ่มข้อมูลตาม employee_id และ country จากตาราง customers ซึ่งเป็นตัวแทนของภูมิภาค
-- แสดงผลยอดขายรวมจากแต่ละภูมิภาค และจัดอันดับพนักงานที่มียอดขายสูงสุด

-- Solution:

SELECT e.first_name || ' ' || e.last_name AS employee_name,
       c.country AS region,
       SUM(od.quantity * od.unit_price) AS total_sales
FROM employees e
JOIN orders o ON e.employee_id = o.employee_id
JOIN order_details od ON o.order_id = od.order_id
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY e.employee_id, c.country
ORDER BY total_sales DESC;
