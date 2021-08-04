create database miniproj;
use miniproj;

select * from cust_dimen;
select * from market_fact;
select * from orders_dimen;
select * from prod_dimen;
select * from shipping_dimen;

-- Question 1
Create table combined_sales as
 (select m.sales, m.discount, m.order_quantity, m.profit, m.shipping_cost, 
 m.product_base_margin, c.*, o.*, s.ship_mode, s.ship_date, s.ship_id, p.*
from market_fact m inner join cust_dimen c
on m.cust_id =c.cust_id
inner join orders_dimen o
on m.ord_id=o.ord_id
inner join prod_dimen p
on m.prod_id = p.prod_id
inner join shipping_dimen s
on m.ship_id = s.ship_id);
select * from combined_sales;

-- Question 2
create or replace view top3 as  
(with test as
(select c.cust_id, c.customer_name, count(m.order_quantity) max_order
from market_fact m inner join cust_dimen c
on m.cust_id = c.cust_id 
group by C.cust_id, c.customer_name order by count(m.order_quantity) desc)
select *,
dense_rank() over (order by max_order desc) d_rank
from test);

select * from top3 where d_rank<=3;

-- Question 3
select m.*, o.order_date, s.ship_date,
datediff(str_to_date(s.ship_date, '%d-%m-%Y'), str_to_date(o.order_date,'%d-%m-%Y')) as DaysTakenForDelivery
from market_fact m inner join orders_dimen o
on m.ord_id = o.ord_id
inner join shipping_dimen s
on m.ship_id =s.ship_id order by daystakenfordelivery;

-- Question 4
select m.*, o.order_date, s.ship_date,
datediff(str_to_date(s.ship_date, '%d-%m-%Y'), str_to_date(o.order_date,'%d-%m-%Y')) as DaysTakenForDelivery
from market_fact m inner join orders_dimen o
on m.ord_id = o.ord_id
inner join shipping_dimen s
on m.ship_id =s.ship_id order by daystakenfordelivery desc limit 1;

-- question 5
select p.prod_id, p.product_category, sum(sales) over (partition by prod_id) t_sales
from market_fact m inner join prod_dimen p
on m.prod_id = p.prod_id;

-- Question 6
select p.prod_id, p.product_category, sum(profit) over (partition by prod_id) T_profit
from market_fact m inner join prod_dimen p
on m.prod_id = p.prod_id;

-- Question 7
 /* select count(distinct cust_id) u_cust from combined_sales
 where order_date between '01-01-2011' and '31-01-2011';
 select distinct cust_id, count(order_date) from combined_sales 
 where order_date between '01-01-2011' and '31-12-2011'
 group by cust_id
 having count( distinct date_format(order_date, '%d-%m-%Y'))=12;*/
 
 /* select distinct cust_id, count(order_date) from combined_sales 
 where order_date between '01-01-2011' and '31-12-2011' and cust_id in 
 (select count(distinct cust_id) u_cust from combined_sales
 where order_date between '01-01-2011' and '31-01-2011')
 group by cust_id
 having count( distinct date_format(order_date, '%d-%m-%Y'))=12;*/
 
 -- Mini project discussion answer
 select distinct year(Order_Date), month(Order_Date),
		count(Cust_id) over(partition by month(Order_Date)) as tot_cus 
from combined_table
where  year(Order_Date) = 2011 and Cust_id in (select distinct Cust_id
										from combined_table
										where month(Order_Date) = 1 and year(Order_Date) = 2011);

 -- question 8
 /* create view retention as 
 (with test1 as
 (with test as 
 (select cust_id, month (str_to_date (order_date, '%d-%m-%Y')) as month1,
 lag(month (str_to_date (order_date, '%d-%m-%Y')),1) over (partition  by cust_id) prev_visit from combined_sales)
 select cust_id, month1, prev_visit, prev_visit-month1 as time_lapse from test )
 select cust_id, month1, prev_visit, time_lapse, 
 case when time_lapse = 1 or time_lapse =-1 then 'retained'
 when time_lapse is null then 'Churned'
 else 'irregular'
 end as category
 from test1);*/
 
 -- Mini project discussion answer
 -- Step 1:
select timestampdiff(month, '2009-01-01', '2009-12-01');

create view vist_log as
select cust_id, timestampdiff(month, '2009-01-01', order_date) as visit_m
from combined_table
group by 1,2
order by 1,2;

select * from vist_log;

-- Step 2:
create view time_lapse_ as
select distinct  cust_id, visit_m,
		lead(visit_m) over (partition by cust_id order by cust_id, visit_m) time_lead
from vist_log;

select * from time_lapse_;

-- Step 3:
create view time_gaps as
select cust_id, visit_m, time_lead, time_lead - visit_m as time_gaps
from time_lapse_;

select * from time_gaps;

-- Step 4: =1 retained, >1 as irregular and NULL as churned
create view cust_cat as 
select cust_id, visit_m, 
case 
when time_gaps = 1 then 'retained'
when time_gaps >1 then 'irregular'
when time_gaps is null then 'churned'
end as cus_cat
from time_gaps;

select * from cust_cat;

-- Step 5:
select month(order_date),
(count(if(cus_cat = 'retained', 1, NULL)) / count(cc.cust_id)) as retention
from cust_cat cc
join combined_table ct on cc.cust_id = ct.cust_id
group by month(order_date)
order by month(order_date);