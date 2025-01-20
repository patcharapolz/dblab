-- 1.	วิเคราะห์การทำกำไรจากแต่ละผลิตภัณฑ์
-- 1.1 สินค้าที่มีกำไรมากที่สุด จาก ยอดขายรวม
SELECT
    p.product_name,
    SUM(((od.unit_price * (1 - od.discount)) - p.unit_price) * od.quantity) AS total_profit,
	SUM(p.unit_price * od.quantity) AS total_cost,
	(SUM(((od.unit_price * (1 - od.discount)) - p.unit_price) * od.quantity) / SUM(p.unit_price * od.quantity)) * 100 AS profit_percentage
	
FROM
    order_details od
JOIN
    products p ON od.product_id = p.product_id
GROUP BY
    p.product_name
ORDER BY
    total_profit DESC
LIMIT 1;

-- 1.2 ใช้ Common Table Expression (CTE) เพื่อการค้นหาได้ทั้งสินค้าที่ขายได้มากที่สุด และขายได้น้อยที่สุด
WITH product_profit AS
(SELECT
    p.product_name,
    SUM(((od.unit_price * (1 - od.discount)) - p.unit_price) * od.quantity) AS total_profit,
	SUM(p.unit_price * od.quantity) AS total_cost,
	(SUM(((od.unit_price * (1 - od.discount)) - p.unit_price) * od.quantity) / SUM(p.unit_price * od.quantity)) * 100 AS profit_percentage
	
FROM
    order_details od
JOIN
    products p ON od.product_id = p.product_id
GROUP BY
    p.product_name
) 
SELECT product_name, profit_percentage FROM product_profit ORDER BY  total_profit DESC LIMIT 1;

-- 1.3 ใช้ Common Table Expression (CTE) เพื่อการค้นหาได้ทั้งสินค้าที่ขายได้มากที่สุด และขายได้น้อยที่สุด
WITH product_profit AS
(SELECT
    p.product_name,
    SUM(((od.unit_price * (1 - od.discount)) - p.unit_price) * od.quantity) AS total_profit,
	SUM(p.unit_price * od.quantity) AS total_cost,
	(SUM(((od.unit_price * (1 - od.discount)) - p.unit_price) * od.quantity) / SUM(p.unit_price * od.quantity)) * 100 AS profit_percentage
	
FROM
    order_details od
JOIN
    products p ON od.product_id = p.product_id
GROUP BY
    p.product_name
) 
SELECT product_name, profit_percentage FROM product_profit ORDER BY  total_profit ASC LIMIT 1;

-- 1.4 ค้นหาสินค้าที่ขายได้มากที่สุดและขายได้น้อยที่สุดพร้อมกัน
WITH product_profit AS
(SELECT
    p.product_name,
    SUM(((od.unit_price * (1 - od.discount)) - p.unit_price) * od.quantity) AS total_profit,
	SUM(p.unit_price * od.quantity) AS total_cost,
	(SUM(((od.unit_price * (1 - od.discount)) - p.unit_price) * od.quantity) / SUM(p.unit_price * od.quantity)) * 100 AS profit_percentage
	
FROM
    order_details od
JOIN
    products p ON od.product_id = p.product_id
GROUP BY
    p.product_name
)
-- คำสั่งนี้จะหาสินค้าที่ทำกำไรมากที่สุดและน้อยที่สุดพร้อมคำนวณกำไรเป็นเปอร์เซ็นต์
SELECT
    -- สินค้าที่ทำกำไรมากที่สุด
    (SELECT product_name FROM product_profit ORDER BY total_profit DESC LIMIT 1) AS most_profitable_product,
    -- กำไรเป็นเปอร์เซ็นต์ของสินค้าที่ทำกำไรมากที่สุด
    (SELECT profit_percentage FROM product_profit ORDER BY total_profit DESC LIMIT 1) AS most_profitable_product_percentage,
    -- สินค้าที่ทำกำไรน้อยที่สุด
    (SELECT product_name FROM product_profit ORDER BY total_profit ASC LIMIT 1) AS least_profitable_product,
    -- กำไรเป็นเปอร์เซ็นต์ของสินค้าที่ทำกำไรน้อยที่สุด
    (SELECT profit_percentage FROM product_profit ORDER BY total_profit ASC LIMIT 1) AS least_profitable_product_percentage;


-- การทำนายเทรนด์การขายในเดือนถัดไป
-- 2.1 monthly_sales CTE:
-- คำนวณยอดขายรายเดือนของแต่ละผลิตภัณฑ์ (รวมการคิดส่วนลด) โดยใช้ SUM(od.quantity * od.unit_price * (1 - od.discount)).
-- ใช้ EXTRACT() เพื่อดึงปีและเดือนจาก order_date ของคำสั่งซื้อ.

-- sales_growth CTE:
-- ใช้ฟังก์ชัน LAG() เพื่อนำ ยอดขายในเดือนก่อนหน้า มาเปรียบเทียบกับยอดขายในเดือนปัจจุบัน.
-- คำนวณ อัตราการเติบโต (growth rate) โดยใช้สมการ (total_sales - previous_month_sales) / previous_month_sales * 100.
-- ในกรณีที่ไม่มีเดือนก่อนหน้า (คือเดือนแรกของปีหรือผลิตภัณฑ์ที่มีเพียงเดือนเดียว), จะใช้ CASE เพื่อให้ค่าของ growth_rate เป็น NULL.

WITH monthly_sales AS (
    SELECT
        p.product_name,
        EXTRACT(YEAR FROM o.order_date) AS sales_year,
        EXTRACT(MONTH FROM o.order_date) AS sales_month,
        SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_sales
    FROM
        order_details od
    JOIN
        orders o ON od.order_id = o.order_id
    JOIN
        products p ON od.product_id = p.product_id
    WHERE
        o.order_date IS NOT NULL AND o.order_date > '1998-01-01'
    GROUP BY
        p.product_name, EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date)
	--ORDER BY p.product_name
),
sales_growth AS (
    SELECT
        product_name,
        sales_year,
        sales_month,
        total_sales,
        LAG(total_sales) OVER (PARTITION BY product_name ORDER BY sales_year, sales_month) AS previous_month_sales,
        -- คำนวณอัตราการเติบโตของยอดขาย
        CASE
            WHEN LAG(total_sales) OVER (PARTITION BY product_name ORDER BY sales_year, sales_month) IS NOT NULL
            THEN (total_sales - LAG(total_sales) OVER (PARTITION BY product_name ORDER BY sales_year, sales_month)) 
                 / LAG(total_sales) OVER (PARTITION BY product_name ORDER BY sales_year, sales_month) * 100
            ELSE NULL
        END AS growth_rate
    FROM
        monthly_sales
)
-- SELECT * FROM sales_growth;
-- คัดเลือกสินค้าที่มีอัตราการเติบโตสูงสุดในเดือนล่าสุด
SELECT
    product_name,
    sales_year,
    sales_month,
    total_sales,
    previous_month_sales,
    growth_rate
FROM
    sales_growth
WHERE
    growth_rate IS NOT NULL
ORDER BY
    growth_rate DESC, total_sales DESC
LIMIT 2;


-- 2.2 ใช้ LEFT JOIN แทนการใช้ LAG
-- current.sales_month = previous.sales_month + 1
WITH monthly_sales AS (
    SELECT
        p.product_name,
        EXTRACT(YEAR FROM o.order_date) AS sales_year,
        EXTRACT(MONTH FROM o.order_date) AS sales_month,
        SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_sales
    FROM
        order_details od
    JOIN
        orders o ON od.order_id = o.order_id
    JOIN
        products p ON od.product_id = p.product_id
    WHERE
        o.order_date IS NOT NULL AND o.order_date > '1998-01-01'
    GROUP BY
        p.product_name, EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date)
	--ORDER BY p.product_name
)
-- เชื่อมตาราง monthly_sales กับตัวเองเพื่อดึงข้อมูลของเดือนก่อนหน้า
SELECT
    current.product_name,
    current.sales_year,
    current.sales_month,
    current.total_sales,
    previous.total_sales AS previous_month_sales,
    -- คำนวณอัตราการเติบโตของยอดขาย
    CASE
        WHEN previous.total_sales IS NOT NULL
        THEN (current.total_sales - previous.total_sales) / previous.total_sales * 100
        ELSE NULL
    END AS growth_rate
FROM
    monthly_sales current
LEFT JOIN
    monthly_sales previous
    ON current.product_name = previous.product_name
    AND current.sales_year = previous.sales_year
    AND current.sales_month = previous.sales_month + 1
WHERE
    previous.total_sales IS NOT NULL
ORDER BY
    growth_rate DESC, current.total_sales DESC
LIMIT 2;


-- 3. การวิเคราะห์ความสัมพันธ์ระหว่างการสั่งซื้อและจำนวนสินค้า
-- 3.1 การวิเคราะห์ความสัมพันธ์ระหว่าง จำนวนสินค้าที่สั่งซื้อ (Quantity) และ มูลค่าคำสั่งซื้อ (Total Order Value) สำหรับคำสั่งซื้อที่มี จำนวนสินค้ามากกว่า 10 ชิ้น จะช่วยให้เราทราบว่า การเพิ่มจำนวนสินค้าที่สั่งซื้อ จะมีผลต่อ มูลค่าคำสั่งซื้อ อย่างไร โดยจะคำนวณและวิเคราะห์ว่า คำสั่งซื้อที่มีจำนวนสินค้ามาก จะทำให้ มูลค่าคำสั่งซื้อเพิ่มขึ้น ตามไปด้วยหรือไม่

SELECT o.order_id,
       SUM(od.quantity) AS total_quantity,
       SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_order_value
FROM order_details od
JOIN orders o ON od.order_id = o.order_id
GROUP BY o.order_id
HAVING SUM(od.quantity) > 10
ORDER BY total_quantity DESC;

-- 3.2 
-- ค่าเฉลี่ยของจำนวนสินค้าที่สั่งซื้อ คือ 66.4477806788511749 ชิ้น และ ค่าเฉลี่ยของมูลค่าคำสั่งซื้อ คือ 1639.8801483961217
-- ส่วนเบี่ยงเบนมาตรฐาน ของจำนวนสินค้ามีค่าค่อนข้างสูง (50.1287155156720703) ซึ่งบ่งบอกว่า จำนวนสินค้าที่สั่งซื้อต่างกัน ในแต่ละคำสั่งซื้ออย่างมาก
-- ส่วนเบี่ยงเบนมาตรฐาน ของมูลค่าคำสั่งซื้อก็มีค่า (1875.1688388415091) ซึ่งแสดงให้เห็นว่ามูลค่าคำสั่งซื้อมีความแตกต่างกันค่อนข้างมากในคำสั่งซื้อที่มีจำนวนสินค้ามากกว่า 10 ชิ้น

SELECT AVG(total_quantity) AS avg_quantity,
       AVG(total_order_value) AS avg_order_value,
       STDDEV(total_quantity) AS stddev_quantity,
       STDDEV(total_order_value) AS stddev_order_value
FROM (
    SELECT SUM(od.quantity) AS total_quantity,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_order_value
    FROM order_details od
    JOIN orders o ON od.order_id = o.order_id
    GROUP BY o.order_id
    HAVING SUM(od.quantity) > 10
) AS summary;


-- สรุป:
-- การวิเคราะห์ความสัมพันธ์ระหว่าง จำนวนสินค้าที่สั่งซื้อ และ มูลค่าคำสั่งซื้อ สามารถแสดงให้เห็นว่า การเพิ่มจำนวนสินค้าที่สั่งซื้อ มักจะ เพิ่มมูลค่าคำสั่งซื้อ ตามไปด้วย และการใช้ ค่ เฉลี่ย และ ส่วนเบี่ยงเบนมาตรฐาน จะช่วยให้เราเข้าใจถึงการกระจายของข้อมูลและความแตกต่างของมูลค่าคำสั่งซื้อในกลุ่มลูกค้าที่มีการสั่งซื้อสินค้ามาก


-- 4. วิเคราะห์ลูกค้าที่มีการซื้อซ้ำบ่อยที่สุด
-- 4.1 หาลูกค้าที่ซื้อสินค้าบ่อยที่สุด 3 รายแรก
SELECT o.customer_id,
       COUNT(o.order_id) AS total_orders
FROM orders o
GROUP BY o.customer_id
ORDER BY total_orders DESC
LIMIT 3;

--- 4.2 ลูกค้าที่ซื้อสินค้าบ่อยที่สุด 3 ราย และคำนวณรายได้ที่สร้าง
SELECT o.customer_id,
       COUNT(DISTINCT o.order_id) AS total_orders,
       SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_spent
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY o.customer_id
ORDER BY total_orders DESC
LIMIT 3;

-- 4.3 ลูกค้าที่ซื้อสินค้าบ่อยที่สุด 3 รายแรก พร้อมทั้งคำนวณ รายได้ที่ลูกค้าเหล่านั้นสร้าง และ สินค้าที่ซื้อบ่อยที่สุด สำหรับแต่ละลูกค้า
-- คำนวณลูกค้าที่ยอดคำสั่งซื้อมากที่สุด 3 รายแรก และมูลค่าการใช้จ่าย
-- ขั้นตอนการวิเคราะห์:
-- คำนวณจำนวนคำสั่งซื้อ (total_orders) และ มูลค่าการใช้จ่าย (total_spent) สำหรับลูกค้า 3 อันดับแรกที่ซื้อบ่อยที่สุด
-- หาสินค้าที่ยอดนิยม สำหรับลูกค้าแต่ละราย โดยการคำนวณจำนวนที่ซื้อมากที่สุดใน order_details
-- จัดกลุ่มข้อมูล และทำการ จัดอันดับ โดยใช้ COUNT(), SUM() และ GROUP BY เพื่อให้เห็น ลูกค้า และ สินค้าที่ซื้อบ่อยที่สุด
-- คำนวณลูกค้าที่ซื้อสินค้าบ่อยที่สุด 3 ราย พร้อมมูลค่าการใช้จ่าย
WITH customer_orders AS (
    SELECT o.customer_id,
           COUNT(DISTINCT o.order_id) AS total_orders,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_spent
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.customer_id
    ORDER BY total_orders DESC
    LIMIT 3
),
-- คำนวณสินค้าที่ลูกค้าแต่ละคนซื้อบ่อยที่สุด
product_frequency AS (
    SELECT o.customer_id,
           od.product_id,
           p.product_name,
           SUM(od.quantity) AS total_quantity
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN products p ON od.product_id = p.product_id
    WHERE o.customer_id IN (SELECT customer_id FROM customer_orders)
    GROUP BY o.customer_id, od.product_id, p.product_name
    ORDER BY total_quantity DESC
)
-- นำข้อมูลจากลูกค้าและสินค้าที่ซื้อบ่อยที่สุดมารวมกัน
SELECT co.customer_id,
       co.total_orders,
       co.total_spent,
       pf.product_name,
       pf.total_quantity
FROM customer_orders co
JOIN product_frequency pf ON co.customer_id = pf.customer_id
WHERE pf.total_quantity = (
    SELECT MAX(total_quantity)
    FROM product_frequency
    WHERE customer_id = co.customer_id
)
ORDER BY co.total_orders DESC;


-- 5 การวิเคราะห์ยอดขายตามภูมิภาค
-- 5.1 ประเทศที่มียอดซื้อสินค้าน้อยที่สุด
SELECT c.country,
       SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
WHERE c.country IS NOT NULL  -- กรองประเทศที่เป็น NULL
GROUP BY c.country
ORDER BY total_sales ASC
LIMIT 1;

-- 5.2 
-- 1. คำนวณยอดขายรวมของแต่ละประเทศเพื่อหาประเทศที่มียอดซื้อสินค้าน้อยที่สุด
WITH CountrySales AS (
    SELECT c.country,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_details od ON o.order_id = od.order_id
    WHERE c.country IS NOT NULL
    GROUP BY c.country
    ORDER BY total_sales ASC
    LIMIT 1
)

-- 2. คำนวณสินค้าที่ขายดีที่สุดในประเทศที่มียอดซื้อสินค้าน้อยที่สุด
SELECT c.country,
       p.product_name,
       SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales,
       SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN products p ON od.product_id = p.product_id
JOIN orders o ON od.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN CountrySales cs ON c.country = cs.country  -- เชื่อมกับ CountrySales ที่คำนวณยอดขายรวมของแต่ละประเทศ
GROUP BY c.country, p.product_name
ORDER BY total_sales DESC
LIMIT 1;

-- 6 การวิเคราะห์ประสิทธิภาพการทำงานของพนักงานจากคำสั่งซื้อที่ได้รับมอบหมาย
-- 6.1 จำนวนคำสั่งซื้อที่พนักงานแต่ละคนจัดการในแต่ละเดือน และ อัตราการเสร็จสิ้นคำสั่งซื้อ (คำสั่งซื้อที่มี shipped_date เทียบกับคำสั่งซื้อทั้งหมด)
SELECT e.first_name || ' ' || e.last_name AS employee_name,  -- ชื่อพนักงาน
       EXTRACT(YEAR FROM o.order_date) AS year,               -- ปีของคำสั่งซื้อ
       EXTRACT(MONTH FROM o.order_date) AS month,             -- เดือนของคำสั่งซื้อ
       COUNT(o.order_id) AS total_orders,                     -- จำนวนคำสั่งซื้อทั้งหมด
       COUNT(CASE WHEN o.shipped_date IS NOT NULL THEN 1 END) AS shipped_orders,  -- จำนวนคำสั่งซื้อที่เสร็จสิ้น
       ROUND(
           (COUNT(CASE WHEN o.shipped_date IS NOT NULL THEN 1 END) * 100) / COUNT(o.order_id), 
           2
       ) AS completion_rate -- อัตราการเสร็จสิ้นคำสั่งซื้อ
FROM employees e
JOIN orders o ON e.employee_id = o.employee_id
GROUP BY e.employee_id, EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date)
ORDER BY year, month, employee_name;

-- 6.2 
WITH EmployeeSales AS (
    -- 1. คำนวณยอดขายรวมและอัตราการเสร็จสิ้นคำสั่งซื้อในแต่ละเดือน
    SELECT e.employee_id,
           e.first_name || ' ' || e.last_name AS employee_name,
           EXTRACT(YEAR FROM o.order_date) AS year,
           EXTRACT(MONTH FROM o.order_date) AS month,
           COUNT(o.order_id) AS total_orders,
           COUNT(CASE WHEN o.shipped_date IS NOT NULL THEN 1 END) AS shipped_orders,
           ROUND(
               (COUNT(CASE WHEN o.shipped_date IS NOT NULL THEN 1 END) * 100) / COUNT(o.order_id), 
               2
           ) AS completion_rate,
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales
    FROM employees e
    JOIN orders o ON e.employee_id = o.employee_id
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY e.employee_id, EXTRACT(YEAR FROM o.order_date), EXTRACT(MONTH FROM o.order_date)
)

-- 2. หาพนักงานที่มีอัตราการเสร็จสิ้นคำสั่งซื้อต่ำที่สุดและแสดงยอดขาย
SELECT employee_name, 
       year, 
       month, 
       completion_rate, 
       total_sales
FROM EmployeeSales
WHERE completion_rate = (
    -- หาค่า completion rate ต่ำที่สุด
    SELECT MIN(completion_rate)
    FROM EmployeeSales
)
ORDER BY total_sales DESC;

-- 7 การวิเคราะห์ผลกระทบของพนักงานที่รับผิดชอบการขายในแต่ละภูมิภาค
-- 7.1 
WITH TotalSales AS (
    -- คำนวณยอดขายรวมทั้งหมดจากทุกพนักงาน
    SELECT SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales_all
    FROM employees e
    JOIN employee_territories et ON e.employee_id = et.employee_id
    JOIN territories t ON et.territory_id = t.territory_id
    JOIN region r ON t.region_id = r.region_id
    JOIN orders o ON e.employee_id = o.employee_id
    JOIN order_details od ON o.order_id = od.order_id
),
EmployeeSales AS (
    -- คำนวณยอดขายของแต่ละพนักงานในแต่ละภูมิภาคและเขตพื้นที่
    SELECT e.first_name || ' ' || e.last_name AS employee_name,   -- ชื่อพนักงาน
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales  -- ยอดขายรวมของพนักงาน
    FROM employees e
    JOIN employee_territories et ON e.employee_id = et.employee_id
    JOIN territories t ON et.territory_id = t.territory_id
    JOIN region r ON t.region_id = r.region_id
    JOIN orders o ON e.employee_id = o.employee_id
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY e.employee_id
)
-- หาพนักงานที่มียอดขายสูงสุดและคำนวณเปอร์เซ็นต์
SELECT es.employee_name, 
       es.total_sales,
       ts.total_sales_all,
       (es.total_sales / ts.total_sales_all) * 100 AS sales_percentage
FROM EmployeeSales es
CROSS JOIN TotalSales ts
ORDER BY es.total_sales DESC
LIMIT 1;

-- ถ้าต้องการแสดง Territories
WITH TotalSales AS (
    -- คำนวณยอดขายรวมทั้งหมดจากทุกพนักงาน
    SELECT SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales_all
    FROM employees e
    JOIN employee_territories et ON e.employee_id = et.employee_id
    JOIN territories t ON et.territory_id = t.territory_id
    JOIN region r ON t.region_id = r.region_id
    JOIN orders o ON e.employee_id = o.employee_id
    JOIN order_details od ON o.order_id = od.order_id
),
EmployeeSales AS (
    -- คำนวณยอดขายของแต่ละพนักงานในแต่ละภูมิภาคและเขตพื้นที่
    SELECT e.first_name || ' ' || e.last_name AS employee_name,   -- ชื่อพนักงาน
           SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_sales,  -- ยอดขายรวมของพนักงาน
           STRING_AGG(DISTINCT t.territory_description, ', ') AS territories  -- รวมเขตพื้นที่ที่พนักงานดูแล
    FROM employees e
    JOIN employee_territories et ON e.employee_id = et.employee_id
    JOIN territories t ON et.territory_id = t.territory_id
    JOIN region r ON t.region_id = r.region_id
    JOIN orders o ON e.employee_id = o.employee_id
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY e.employee_id
)
-- หาพนักงานที่มียอดขายสูงสุดและคำนวณเปอร์เซ็นต์ พร้อมแสดงเขตพื้นที่
SELECT es.employee_name, 
       es.total_sales,
       ts.total_sales_all,
       es.territories,  -- แสดงเขตพื้นที่ที่พนักงานดูแล
       (es.total_sales / ts.total_sales_all) * 100 AS sales_percentage
FROM EmployeeSales es
CROSS JOIN TotalSales ts
ORDER BY es.total_sales DESC
LIMIT 1;
