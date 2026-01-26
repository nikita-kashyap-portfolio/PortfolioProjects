SELECT t1.orderDate, t1.orderNumber,quantityOrdered,priceEach,productName,productLine,buyPrice,country, city FROM
orders t1
inner join orderdetails t2
on t1.orderNumber = t2.orderNumber
inner join products t3
on t2.productCode =t3.productCode
inner join customers t4
on t1.customerNumber = t4.customerNumber
where year(orderDate) = 2004;

-- Product Purchase Together with CTEs -- 
with prod_sales as
(
SELECT orderNumber, t1.productCode, productLine FROM
orderdetails t1
inner join products t2
ON t1.productCode = t2.productCode
)
select distinct t1.orderNumber,t1.productLine as product_one , t2.productLine as product_two 
 from prod_sales t1
left join prod_sales t2
ON t1.orderNumber = t2.orderNumber and t1.productLine<> t2.productLine;

-- Credit Limit Group CTEs-- 
with  sales as
(SELECT t1.orderNumber,t1.customerNumber,productCode,quantityOrdered, priceEach,priceEach*quantityOrdered as sales_value,creditLimit FROM
orders t1
inner join orderdetails t2
on t1.orderNumber = t2.orderNumber
inner join customers t3
on t1.customerNumber = t3.customerNumber
)
select orderNumber,customerNumber,
case when creditLimit < 75000 then 'a:less than $75k'
when creditLimit between 75000 and 100000 then 'b: $75k-$100k'
when creditLimit between 100000 and 150000 then 'c:$100k-$1500k'
when creditLimit >150000 then 'd:Over $150k'
 else 'Other'
 end as creditlimit_group,
 sum(sales_value) as sales_value 
from sales
group by orderNumber,customerNumber,creditlimit_group
;

-- Sales Value Change From Pervious Order Subquery CTEs, and Subquery

with main_cte as
(
select orderNumber, orderDate, customerNumber, sum(Sales_value) as sales_value
from
(SELECT t1.orderNumber ,orderDate ,customerNumber, productCode, quantityOrdered*priceEach as sales_value FROM orders t1
inner join orderdetails t2
on t1.orderNumber = t2.orderNumber) main
group by orderNumber, orderDate, customerNumber),

sales_query as
(
select t1.*, customerName, row_number() over (partition by customerName order by orderDate) as purchase_number,
lag(sales_value)over (partition by customerName order by orderDate) as previous_sales_value from main_cte t1
inner join customers t2
on t1.customerNumber = t2.customerNumber
)

select *,sales_value - previous_sales_value as purchase_value_change from sales_query
where previous_sales_value IS NOT NULL;


-- Office Sales by Customer Country CTEs
with main_cte as
(
SELECT t1.orderNumber,
t2.productCode,
t2.quantityOrdered,
t2.priceEach,
quantityOrdered*priceEach as sales_value,
t3.city as customer_city,
t3.country as customer_country,
productLine, t6.city as office_city,
t6.country as office_country FROM orders t1
inner join orderdetails t2
on t1.orderNumber = t2.orderNumber
inner join customers t3
on t1.customerNumber = t3.customerNumber
inner join products t4
on t2.productCode = t4.productCode
inner join employees t5
on t3.salesRepEmployeeNumber = t5.employeeNumber
inner join offices t6
on t5.officeCode = t6.officeCode
)

SELECT orderNumber, customer_city, 
customer_country, 
productline, 
office_city, 
office_country, sum(sales_value) as sales_values
FROM main_cte
group by orderNumber, customer_city, 
customer_country, 
productline, 
office_city, 
office_country;

-- customers Affected  by Late Shipping CASE WHEN

SELECT *, date_add(shippedDate, interval 3 day) as latest_arrival,
case when date_add(shippedDate, interval 3 day)> requiredDate then 1 else 0 end as late_flag
FROM orders
where 
(case when date_add(shippedDate, interval 3 day)> requiredDate then 1 else 0 end = 1);

-- CUSTOMERS WHO GO OVER CREDIT LIMIT CTEs

with cte_sales as
(
SELECT orderDate,
t1.customerNumber,
t1.orderNumber,
customerName,
productCode,
creditLimit,
quantityOrdered*priceEach as sales_value 
FROM orders t1
inner join orderdetails t2
on t1.orderNumber = t2.orderNumber
inner join customers t3
on t1.customerNumber = t3.customerNumber),

running_total_sales_cte as
(SELECT *, lead(orderDate) over (partition by customerNumber order by orderDate) as next_order_date FROM
(
SELECT orderdate,
ordernumber,
customernumber,
customername,
creditlimit,
sum(sales_value) as sales_value
 FROM cte_sales
 group by  orderdate,
ordernumber,
customernumber,
customername,
creditlimit
) subquery
),

payments_cte as
( SELECT *
FROM payments),
main_cte as
(
SELECT t1.*,
sum(sales_value)over (partition by t1.customernumber order by orderdate) as running_total_sales,
sum(amount) over (partition by t1.customerNumber order by orderDate)as running_total_payments 
 FROM running_total_sales_cte t1
 left join payments_cte t2 
 ON t1.customerNumber = t2.customerNumber and t2.paymentdate between t1.orderdate and case when t1.next_order_date is null then current_date else next_order_date end
 order by t1.customerNumber, orderDate 
 )
 SELECT *, running_total_sales - running_total_payments as money_owed ,
 creditlimit - (running_total_sales - running_total_payments) as difference
 FROM main_cte;