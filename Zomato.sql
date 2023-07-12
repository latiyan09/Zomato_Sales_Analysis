  use sales_schema;
  
  create table sales(
  customer_id varchar(1),
  order_date date,
  product_id int);
  
 insert into sales(customer_id, order_date,product_id)
  values
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3'); 
  
  Select* from Sales;
  
  create table menu(
  product_id int,
  product_name varchar(10),
  price int);
  
  insert into menu(product_id, product_name, price)
  values
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');  
  
  Select * from menu;
  
  create table members (
  customer_id VARCHAR(1), 
  join_date DATE);
 
  insert into members(customer_id,join_date)
  values
  ('A','2021-01-07'),
  ('B','2021-01-09');
  
    Select * from members;
    
  -- 1. What is the total amount each customer spent at the restaurant?
  Select customer_id, sum(price) as Total_sale from sales as s left outer join menu as m on s.product_id=m.product_id group by customer_id;
  
  -- How many days has each customer visited the restaurant?
  Select customer_id, count(distinct(order_date)) as VisitCount from sales group by customer_id;
 
   -- How many times each customer visited the restaurant?
    Select customer_id, count(*) as VisitCount from sales group by customer_id;
    
    -- What was the first item from the menu purchased by each customer?
#ranking the order_date 
# row number is a function that assigns a sequential integer to each row within the partition
# using dense_rank() instead of row_number

with ordered_sales as(
select customer_id, product_name, order_date, dense_rank() over (partition by customer_id order by order_date) as Ranks from sales as s left outer join menu as m on s.product_id= m.product_id)

select customer_id, product_name, order_date from ordered_sales where Ranks=1 group by customer_id;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?

Select product_id, count(*) as OrderCount from sales group by product_id order by OrderCount desc;

-- Which item was the most popular for each customer?
with popular_food as(
select customer_id, product_id, count(*) as OrderCount, dense_rank() over (partition by customer_id order by count(product_id) desc) as Ranks from sales group by customer_id, product_id)

select customer_id, product_id, OrderCount
from popular_food
where ranks=1;

-- Which item was purchased first by the customer after they became a member?
with member_customer as(
select s.customer_id, product_id, order_date, join_date, dense_rank() over(partition by customer_id order by order_date) as Ranks from sales as s left outer join members as m on s.customer_id=m.customer_id 
where order_date >= join_date)

select customer_id, product_id, order_date
from member_customer
where ranks=1;

-- Which item was purchased just before the customer became a member?
with member_customer as(
select s.customer_id, product_id, order_date, join_date, dense_rank() over(partition by customer_id order by order_date desc) as ranks from sales as s left outer join members as m on s.customer_id=m.customer_id 
where order_date < join_date)

select customer_id, product_id, order_date
from member_customer
where ranks=1;

-- What is the total items and amount spent for each member before they become a member?

with member_customer as(
select s.customer_id, s.product_id, product_name, price, order_date, join_date from sales as s 
left outer join members as m on s.customer_id = m.customer_id 
left outer join menu as me on s.product_id = me.product_id
where order_date < join_date)

select customer_id, count(product_id), sum(price) from member_customer group by customer_id;

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier- how many points would each customer have? 
#To create conditional statement use- case when

with member_customer as(
select s.customer_id, s.product_id, product_name, price, order_date, case when s.product_id =1 then price*20 else price *10 end as Points from sales as s 
left outer join members as m on s.customer_id = m.customer_id 
left outer join menu as me on s.product_id = me.product_id)

select customer_id, count(product_id), sum(Points) as TotalPoints from member_customer group by customer_id;

--  In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

with member_customer as(
Select s.customer_id, s.product_id, product_name ,join_date, order_date, price , datediff(Order_date,join_date) as Validdays,
case when s.product_id =1 then price*20 when s.product_id !=1 and datediff(Order_date,join_date) between 0 and 7 then price*20 else price *10 end as Points from sales as s 
left outer join members as m on s.customer_id = m.customer_id 
left outer join menu as me on s.product_id = me. product_id
where order_date <= '2021-01-31')

Select customer_id, count(product_id), sum(Points) as TotalPoints from member_customer group by customer_id;






