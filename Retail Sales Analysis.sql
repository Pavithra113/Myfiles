create database retail_sales
use retail_sales

create table sales_report (Product_ID int, Product_Name varchar(max), Category varchar(max),Stock_Quantity int,Supplier varchar(max),Discount decimal(10,2),
Rating decimal(10,2),Reviews int,SKU varchar(10),Warehouse varchar(max),Return_Policy varchar(max),Brand varchar(10),Supplier_Contact varchar(20),
Placeholder int, Price decimal(10,2))

---Path of file - F:\Office\Projects
---Bulk inserting the data in csv file - Data_retail.csv

Bulk insert sales_report from 'F:\Office\Projects\Data_retail.csv'
with (fieldterminator = ',',
			rowterminator = '\n',
							firstrow = 2,
										maxerrors = 20)

select * from sales_report

---There's no null or blank values in any cells which needs to be cleaned
---As well there's no duplicate rows which needs to be removed

SELECT Product_ID, Product_Name, Category, Stock_Quantity, Supplier, Discount, Rating, Reviews, SKU, Warehouse, Return_Policy, Brand, Supplier_Contact, Price, COUNT(*) AS Duplicate_Count
FROM sales_report
GROUP BY Product_ID, Product_Name, Category, Stock_Quantity, Supplier, Discount, Rating, Reviews, SKU, Warehouse, Return_Policy, Brand, Supplier_Contact, Price
HAVING COUNT(*) > 1;

select column_name,data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'sales_report'

select * from sales_report where Rating > 5
select * from sales_report where Price < 0 or Stock_Quantity < 0

---SQL query analysis

---1. Identifies products with prices higher than the average price within their category.
select product_id, product_name, Category, Price
from sales_report s
where price > (select avg(Price) from sales_report where Category = s.Category)
order by 3

---2.Finding Categories with Highest Average Rating Across Products.
select category, avg(rating) as Avg_rating
from sales_report
group by Category
order by Avg_rating desc

---3.Find the most reviewed product in each warehouse
with RankedProducts as (  
    select Product_ID, Product_Name, Warehouse, Reviews,  
           rank() over (partition by Warehouse order by Reviews desc) as Rank  
    from sales_report  
)  
select * from RankedProducts  
where Rank = 1

---4. Find products that have higher-than-average prices within their category, along with their discount and supplier.
select product_id, product_name, Category, Price, Discount, Supplier
from sales_report s
where price > (select avg(Price) from sales_report where Category = s.Category)
order by 3

---5. Query to find the top 2 products with the highest average rating in each category
with RankedProducts as (
    select Product_ID, Product_Name, Category, AVG(Rating) as AvgRating,  
           RANK() over (partition by Category order by AVG(Rating) desc) as Rank  
    from sales_report  
    group by Product_ID, Product_Name, Category
)  
select * from RankedProducts  
where Rank <= 3

---6. Analysis Across All Return Policy Categories(Count, Avgstock, total stock, weighted_avg_rating, etc)
select count(product_id) as ProductCount, Avg(Stock_Quantity) as AvgStock, Sum(Stock_Quantity) as TotalStock,
sum(rating * reviews)/ sum(Reviews) as WeightedAvg, Return_Policy
from sales_report
group by Return_Policy
