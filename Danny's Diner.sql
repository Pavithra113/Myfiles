create database dannys_diner

Use dannys_diner

Create table members (customer_id varchar(1), join_date date)
Create table menu (product_id int, product_name varchar(5), price int)
Create table sales (customer_id varchar(1), order_date date, product_id int)

Insert into sales values
('A','2021-01-01', '1'),
('A','2021-01-01', '2'),
('A','2021-01-07', '2'),
('A','2021-01-10', '3'),
('A','2021-01-11', '3'),
('A','2021-01-11', '3'),
('B','2021-01-01', '2'),
('B','2021-01-02', '2'),
('B','2021-01-04', '1'),
('B','2021-01-11', '1'),
('B','2021-01-16', '3'),
('B','2021-02-01', '3'),
('C','2021-01-01', '3'),
('C','2021-01-01', '3'),
('C','2021-01-07', '3')

Insert into menu values 
(1,'Sushi',10),
(2,'Curry',15),
(3,'Ramen',12)

Insert into members values
('A', '2021-01-07'),
('B', '2021-01-09')

select * from members
select * from menu
select * from sales

---Case study questions---
---1.What is the total amount each customer spent at the restaurant?
select customer_id, sum(price) as Total_amount
from sales s
inner join menu m
on s.product_id = m.product_id
group by customer_id 

---2.How many days has each customer visited the restaurant?
Select customer_id, count(distinct order_date) as No_of_times_visited
from sales
group by customer_id

---3.What was the first item from the menu purchased by each customer?
With Rank as
(
Select S.customer_id, 
       M.product_name, 
	     S.order_date,
	     DENSE_RANK() OVER (PARTITION BY S.Customer_ID Order by S.order_date) as 'rank'
From Menu m
Join Sales s
On m.product_id = s.product_id
Group by S.customer_id, M.product_name,S.order_date
)
Select Customer_id, product_name
From Rank
Where rank = 1

---4.What is the most purchased item on the menu and how many times was it purchased by all customers?
Select top 1 m.product_name, COUNT(s.product_id) as mostpurchaseditem
from menu m
inner join sales s
on m.product_id = s.product_id
group by m.product_name
order by 2 desc

---5.Which item was the most popular for each customer?
With Rank as
(
Select S.customer_id, 
       M.product_name, 
	     COUNT(S.product_id) as mostpopular,
	     DENSE_RANK() OVER (PARTITION BY S.Customer_ID Order by COUNT(S.product_id) desc) as 'rank'
From Menu m
Join Sales s
On m.product_id = s.product_id
Group by S.customer_id,S.product_id, M.product_name
)
Select Customer_id, product_name,mostpopular
From Rank
Where rank = 1

---6.Which item was purchased first by the customer after they became a member?
With Rank as
(
Select S.customer_id, 
       M.product_name, 
	     S.order_date,
	     DENSE_RANK() OVER (PARTITION BY S.Customer_ID Order by S.order_date) as 'rank'
From Menu m
Join Sales s
On m.product_id = s.product_id
join members me
on me.customer_id = s.customer_id
where s.order_date >= me.join_date
)
Select Customer_id, product_name, order_date
From Rank
Where rank = 1

---7. Which item was purchased just before the customer became a member?
With Rank as
(
Select S.customer_id, 
       M.product_name, 
	     S.order_date,
	     DENSE_RANK() OVER (PARTITION BY S.Customer_ID Order by S.order_date desc) as 'rank'
From Menu m
Join Sales s
On m.product_id = s.product_id
join members me
on me.customer_id = s.customer_id
where s.order_date < me.join_date
)
Select Customer_id, product_name, order_date
From Rank
Where rank = 1

---8.What is the total items and amount spent for each member before they became a member?
Select S.customer_id, 
       COUNT(s.product_id) as totalitems, 
	     sum(m.price) as amountspent
From Menu m
Join Sales s
On m.product_id = s.product_id
join members me
on me.customer_id = s.customer_id
where s.order_date < me.join_date
group by s.customer_id

---9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
With Points as
(
Select *, Case When product_id = 1 THEN price*20
               Else price*10
			   End as Points
From Menu
)
Select S.customer_id, Sum(P.points) as Pointsearned
From Sales S
Join Points p
On p.product_id = S.product_id
Group by S.customer_id;

---10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
	--- how many points do customer A and B have at the end of January?
With Dates as
(
select *, DATEADD(day,6,join_date) as valid_date,
	EOMONTH('2021-01-31') as last_date
	from members
)
select s.customer_id,SUM(Case 
		       When m.product_ID = 1 THEN m.price*20
			     When S.order_date between D.join_date and D.valid_date Then m.price*20
			     Else m.price*10
			     END 
		       ) as Points
from dates d
join sales s
on d.customer_id = s.customer_id
join menu m
on m.product_id = s.product_id
where s.order_date < d.last_date
group by s.customer_id

