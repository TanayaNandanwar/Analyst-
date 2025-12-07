create database Project2;

use Project2;

1. create foreign key

alter table orders 
add foreign key(customer_id) references customers(customer_id);

alter table order_items
add foreign key(order_id) references orders(order_id);

alter table order_items
add foreign key(product_id) references products(product_id);

alter table website_sessions
add foreign key(customer_id) references customers(customer_id);

alter table inventory
add foreign key(product_id) references products(product_id);

alter table vendors
add foreign key(product_id) references products(product_id);

alter table fulfillment
add foreign key(order_id) references orders(order_id);

alter table fulfillment
add foreign key(vendor_id) references vendors(vendor_id);

select * from customers;
select * from fulfillment;
select * from inventory;
select * from marketing_campaigns;
select * from order_items;
select * from orders;
select * from products;
select * from vendors;
select * from website_sessions;

1. Identify repeat customers and find how many days they took to place their second order.

with cte_repeat as
(
select customer_id, order_id, order_date,
row_number() over (partition by customer_id order by order_date) as
repeaters from orders
)

select a.customer_id,
datediff(day,a.order_date,b.order_date) as days_between_orders
from cte_repeat a 
join cte_repeat b
on a.customer_id = b.customer_id 
where a.repeaters = 1 and b.repeaters = 2;

2. Top 5 products that will stockout first based on 7-day sales velocity

select * from products;
select * from inventory;
select * from orders;
select * from order_items;

with cte_sales as
(
select oi.product_id, avg(oi.quantity) as avg_qty
from order_items oi join orders o
on o.order_id = oi.order_id 
where o.order_date >=dateadd(day, 7, getdate())
group by oi.product_id
)

select i.product_id, oi.quantity, s.avg_qty,
(oi.quantity/avg_qty) as days_until_stockout
from inventory i 
join cte_sales s on 
i.product_id = s.product_id 
join order_items oi 
on oi.product_id = i.product_id
where s.avg_qty >0 
order by days_until_stockout asc;

select order_date from orders;

3. Customers with 5+ sessions but no orders

select * from customers;
select * from website_sessions;

select ws.customer_id
from website_sessions ws join customers c
on c.customer_id = ws.customer_id
join orders o 
on o.customer_id = c.customer_id
group by ws.customer_id
having count(distinct ws.session_id)>=5
and count(o.order_id) = 0;

4. Worst-performing vendor (SLA breach rate)

select * from vendors;
select * from orders;
select * from fulfillment;

select v.vendor_id, v.vendor_name,
count(*) as total_orders,
sum(case when datediff(day,o.order_date,o.delivery_date) > 7 then 1 else 0 end) as sla_breach
from fulfillment f 
join vendors v 
on f.vendor_id = v.vendor_id
join orders o on f.order_id = o.order_id
group by v.vendor_id, v.vendor_name
order by sla_breach desc;

5. Orders delivered 3+ days late & total delay (Assume expected delivery = order_date + 5 days.)

select order_id, order_date, delivery_date,
dateadd(day,5,order_date) as expected_delivery,
datediff(day,dateadd(day,5,order_date),delivery_date) as delay
from orders
where delivery_date > dateadd(day, 5, order_date)
and datediff(day,dateadd(day,5,order_date),delivery_date) >= 3
order by delay desc;

6. Top 10% customers contributing most revenue

select distinct top 10 percent
    o.customer_id,
    sum(oi.quantity * oi.price_per_unit) as total_revenue
from orders o
join order_items oi on o.order_id = oi.order_id
group by o.customer_id
order by total_revenue desc;

7. Product categories with highest return/fulfillment failure

select * from orders;
select * from products;
select * from fulfillment;
select * from order_items;

select distinct fulfillment_status from fulfillment;

select p.category, o.order_status,
count(p.category) as failed
from fulfillment f join 
order_items oi 
on f.order_id = oi.order_id
join products p
on oi.product_id = p.product_id
join orders o 
on o.order_id = oi.order_id
where order_status = 'returned'
group by p.category, o.order_status
order by failed desc;

8. Orders containing products currently out of stock

select * from order_items;
select * from orders;
select * from products;

select distinct quantity from order_items;

select p.product_id,p.product_name,o.order_id
from order_items oi join orders o 
on oi.order_id = o.order_id
join products p 
on oi.product_id = p.product_id 
where oi.quantity = 0;

9. Products sold out in last 3 months

SELECT DISTINCT 
    oi.product_id
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_date >= DATEADD(month, -3, GETDATE())
  AND oi.quantity = 0;

10. Revenue Lost Due to Stockouts

select oi.product_id,
sum(oi.quantity*oi.price_per_unit) as lost_revenue
from orders o join order_items oi
on oi.order_id = o.order_id
where oi.quantity = 0
group by oi.product_id
order by lost_revenue desc;

11. Churned customers (no orders in last 60 days)

select c.customer_id
from customers c
left join orders o 
on c.customer_id = o.customer_id
and order_date>=dateadd(day,-60,getdate())
group by c.customer_id
having count(o.order_id) = 0;






























































