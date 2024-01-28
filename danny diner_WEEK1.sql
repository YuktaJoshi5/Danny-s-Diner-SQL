
use dannys_diner;


  select * from sales, menu, members;
  
#-- Each of the following case study questions can be answered using a single SQL statement:
#1.  What is the total amount each customer spent at the restaurant?

SELECT
s.customer_id,
sum(m.price) as total_amount 
FROM sales as s left join menu as m using(product_id) 
GROUP BY s.customer_id;

#2. How many days has each customer visited the restaurant?

SELECT
customer_id, 
count(distinct order_date) as no_of_days 
FROM sales 
GROUP BY customer_id;

#3. What was the first item from the menu purchased by each customer?

with top_prod as 
(SELECT 
s.order_date,
s.customer_id,
s.product_id,
m.product_name
FROM sales as s LEFT JOIN menu as m using(product_id)
)

select
	customer_id,
    product_name
from
	(SELECT 
	row_number() over (PARTITION BY customer_id order by order_date ) as customer_rank,
	customer_id, product_name 
	FROM top_prod) orders_rnk
where
	customer_rank=1;
-- order by can be done for the columns under select statement.
-- having and row window function cannot come together.

#4. What is the most purchased item on the menu and how many times was it purchased by all customers?


SELECT count(s.product_id) as no_times, m.product_name
FROM sales as s join menu as m using(product_id) 
GROUP BY s.product_id, m.product_name 
ORDER BY no_times DESC limit 1;

#5. Which item was the most popular for each customer?


SELECT 
COUNT(s.product_id) as item_count,
s.customer_id,
m.product_name
FROM sales as s join menu as m using(product_id)
GROUP BY s.customer_id, m.product_name order by item_count desc;


#6. Which item was purchased first by the customer after they became a member?

with numbering as (SELECT 
s.customer_id, s.order_date, m.join_date, s.product_id, men.product_name
from sales as s join members as m using(customer_id) join menu as men using(product_id)
where m.join_date < s.order_date
order by s.order_date)

select * from
(select row_number() over (partition by customer_id order by order_date) numberd, customer_id, product_name,order_date,join_date 
from numbering) 
num where numberd = 1;


#7. Which item was purchased just before the customer became a member?

with bef_join as (
select s.product_id, m.product_name, s.order_date, mem.join_date, s.customer_id from sales as s join menu as m using(product_id) join members as mem using(customer_id) 
where s.order_date < mem.join_date)

select product_id, customer_id,  product_name, order_date, join_date from 
(select rank() over (partition by customer_id, product_name order by order_date) ranking, product_id, customer_id, product_name, order_date, join_date
from bef_join) ordering  ;


#8. What is the total items and amount spent for each member before they became a member?
select  s.customer_id, count(s.product_id) as total_item, sum(m.price) as total_amount from sales as s join menu as m using(product_id)
join members as mem using(customer_id) where mem.join_date > s.order_date group by s.customer_id order by total_amount asc;


#9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select 
s.customer_id, sum(m.price) as total_amount, 
sum(case 
when m.product_name = 'sushi' then m.price*20
when m.product_name = 'ramen' or m.product_name =  'curry' then m.price*10
end ) as points
from sales as s join menu as m using(product_id) group by s.customer_id;

#10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer 
-- A and B have at the end of January?

select customer_id,
sum(case
when order_date between join_date and week then price*20
else price*10
end) as points from
(select s.customer_id, date_add(mem.join_date, interval(6)day) as week, mem.join_date,m.product_name, s.order_date, m.price
from sales as s join menu as m using(product_id) join members as mem using(customer_id) where order_date < '2021-02-01') as new_points group by customer_id;

#11. Table recreation - add 'N' if the customer wasnt a member and 'Y' if was a member. 



select s.customer_id, s.order_date, m.product_name, m.price,
case
when s.order_date >= mem.join_date then 'Y'
when s.order_date < mem.join_date then  'N'
else 'N'
end as member
from sales as s left join menu as m using(product_id) left join members as mem using(customer_id);

#12. Ranking -  does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.

with mem_rank as(
select s.customer_id, s.order_date, m.product_name, m.price,
case
when s.order_date >= mem.join_date then 'Y'
when s.order_date < mem.join_date then  'N'
else 'N'
end as member
from sales as s join menu as m using(product_id) join members as mem using(customer_id))
select *,
case
when  member = 'N' then 'Null'
else rank() over (partition by customer_id, member order by order_date, member)
end as ranking from mem_rank ;