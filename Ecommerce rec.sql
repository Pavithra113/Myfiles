--- Ecommerce recommendation and user behaviour analytics ---
create database ecommerce

---create users table---
create table users (UserID int Primary key, Name varchar(100), Email nvarchar(100), JoinDate date)

create table products (ProductID int primary key, ProductName varchar(100), Category nvarchar(50), Price decimal(10,2), Stock Int)

create table Orders (OrderID int primary key, UserID Int, Orderdate Date, Totalamount decimal(10,2) foreign key (UserId) references users(UserID))

create table Orderdetails (OrderdetailID int primary key, OrderID Int, ProductID Int, Quantity int, SubTotal decimal(10,2)
foreign key (OrderId) references Orders(OrderID),
foreign key (ProductId) references products(ProductID))

create table ProductRecommendations (RecommendationID int primary key, UserID Int, ProductID Int, Recommendationdate Date
foreign key (UserId) references Users(UserID),
foreign key (ProductId) references products(ProductID))

create table RecommendationAudit (AuditID int primary key, UserID Int, ProductID Int, Recommendationdate Date, AuditDate datetime
foreign key (UserId) references Users(UserID),
foreign key (ProductId) references products(ProductID))

-- USER DATA
INSERT INTO Users (UserID, Name, Email, JoinDate) VALUES
(1, 'Alice', 'alice@example.com', '2024-01-15'),
(2, 'Bob', 'bob@example.com', '2024-03-22'),
(3, 'Charlie', 'charlie@example.com', '2024-05-10'),
(4, 'Diana', 'diana@example.com', '2024-06-01'),
(5, 'Eve', 'eve@example.com', '2024-07-12'),
(6, 'Frank', 'frank@example.com', '2024-08-15'),
(7, 'Grace', 'grace@example.com', '2024-09-10'),
(8, 'Hank', 'hank@example.com', '2024-10-01'),
(9, 'Ivy', 'ivy@example.com', '2024-11-05'),
(10, 'Jack', 'jack@example.com', '2024-12-01');


-- PRODUCTS DATA
INSERT INTO Products (ProductID, ProductName, Category, Price, Stock) VALUES
(101, 'Laptop', 'Electronics', 700.00, 50),
(102, 'Headphones', 'Electronics', 50.00, 200),
(103, 'Coffee Maker', 'Appliances', 80.00, 75),
(104, 'Smartphone', 'Electronics', 500.00, 120),
(105, 'Blender', 'Appliances', 60.00, 90),
(106, 'Tablet', 'Electronics', 300.00, 100),
(107, 'Microwave', 'Appliances', 150.00, 40),
(108, 'Gaming Console', 'Electronics', 400.00, 30),
(109, 'Vacuum Cleaner', 'Appliances', 120.00, 60),
(110, 'Smartwatch', 'Electronics', 200.00, 150);

-- ORDERS DATA
INSERT INTO Orders (OrderID, UserID, OrderDate, TotalAmount) VALUES
(1, 1, '2024-06-10', 750.00),
(2, 2, '2024-07-05', 80.00),
(3, 3, '2024-07-15', 900.00),
(4, 4, '2024-08-01', 120.00),
(5, 5, '2024-08-20', 650.00),
(6, 6, '2024-09-05', 400.00),
(7, 7, '2024-09-25', 150.00),
(8, 8, '2024-10-10', 1000.00),
(9, 9, '2024-10-25', 200.00),
(10, 10, '2024-11-10', 750.00);

-- ORDER DETAILS DATA
INSERT INTO OrderDetails (OrderDetailID, OrderID, ProductID, Quantity, Subtotal) VALUES
(1, 1, 101, 1, 700.00),
(2, 1, 102, 1, 50.00),
(3, 2, 103, 1, 80.00),
(4, 3, 104, 1, 500.00),
(5, 3, 106, 2, 400.00),
(6, 4, 105, 2, 120.00),
(7, 5, 108, 1, 400.00),
(8, 5, 109, 2, 240.00),
(9, 6, 102, 8, 400.00),
(10, 7, 110, 1, 150.00);

-- PRODUCT RECOMMENDATION DATA
INSERT INTO ProductRecommendations (RecommendationID, UserID, ProductID, Recommendationdate) VALUES
(1, 1, 103, '2024-06-12'),
(2, 1, 104, '2024-06-15'),
(3, 2, 105, '2024-07-07'),
(4, 2, 106, '2024-07-09'),
(5, 3, 107, '2024-07-17'),
(6, 4, 108, '2024-08-05'),
(7, 5, 109, '2024-08-22'),
(8, 6, 110, '2024-09-07'),
(9, 7, 101, '2024-09-27'),
(10, 8, 102, '2024-10-12');

---Fetch all orders placed by users who joined before march 2024
select OrderID, O.UserID, JoinDate, Orderdate, Totalamount from Orders O
Inner join users u
on o.UserID = u.UserID
where u.JoinDate < '2024-03-01'

---List all products under the "Electronics" category with price greater than $100
Select * from products
where Category= 'Electronics' and Price > 100

--#FUNCTIONS##--
---Scalar function to calculate total revenue from all orders
/*
create function GetTotalRevenue()
returns decimal(10,2)
As Begin
	Declare @TotalRevenue Decimal(10,2)
	Select @TotalRevenue = sum(Totalamount) from Orders
	Return @Totalrevenue
End
*/
Select dbo.gettotalrevenue() as TotalRevenue

---Function to return total products purchased by a specific user
/*
Create function GetTotalProductPurchased(@userid Int)
returns int
as begin
	Declare @TotalProducts int
	Select @TotalProducts = sum(Quantity)
	from Orders o
	inner join Orderdetails d
	on o.OrderID = d. OrderID
	where UserID= @userId
	Return @totalproducts
End
*/
Select dbo.getTotalproductpurchased(5)

---Transaction to place an order ensuring consistency
Begin transaction

Begin try
	Insert into Orders values (11,3,'2024-12-01',750)
	insert into Orderdetails values (11,11,101,1,700)
	Update products set Stock = Stock - 1
	where ProductID = 101
	Commit transaction
End try
Begin catch
	Rollback transaction
	throw
End catch

Select * from Orders
Select * from Orderdetails
Select * from users


---##Stored Procedure##---
---Stored procedure to add a new user and recommend a random product---

CREATE PROCEDURE AddUserAndRecommendProduct
    @UserID INT,
    @Name NVARCHAR(100),
    @Email NVARCHAR(100),
    @JoinDate DATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID)
    BEGIN
        PRINT 'Error: UserID already exists.';
        RETURN;
    END;

    DECLARE @ProductID INT;
    DECLARE @RecommendationID INT;
    SELECT @RecommendationID = ISNULL(MAX(RecommendationID), 0) + 1 FROM ProductRecommendations;
    
	INSERT INTO Users
    VALUES (@UserID, @Name, @Email, @JoinDate);

    SELECT TOP 1 @ProductID = ProductID FROM Products ORDER BY NEWID();

    INSERT INTO ProductRecommendations
    VALUES (@RecommendationID, @UserID, @ProductID, GETDATE());

    PRINT 'User and recommendation is added successfully.'

END;

-- Adding user with ID 401
EXEC AddUserAndRecommendProduct
    @UserID = 401,
    @Name = 'Johan',
    @Email = 'Johan@example.com',
    @JoinDate = '2024-11-10';

-- Adding user with ID 402
EXEC AddUserAndRecommendProduct
    @UserID = 402,
    @Name = 'Emma',
    @Email = 'emma@example.com',
    @JoinDate = '2024-11-12';

Select * from users where UserID in (401,402)

Select * from ProductRecommendations where UserID in (401,402)

---Fetch the total revenue grouped by product categories with max to min
Select Category, Sum(SubTotal) as TotalRevenue
from Orderdetails O
inner join products P
on O.ProductID = P.ProductID
Group by category
order by 2 desc

-- 2. Identify the top 2 user Name, ID, total with the highest spending.
Select top 2 U.UserID, U.Name, Sum(Totalamount) as Total
from users u
inner join Orders O
on U.UserID = O.UserID
group by U.UserID, U.Name
Order by 3 Desc

-- 3. Suggest products not yet purchased by a specific user.
/*
Create function Productnotpurchased (@userId int)
returns table
As Return (
	Select ProductID, ProductName, Category
	from Products P
	where ProductID not in (
			Select ProductID from Orders o
			Inner join Orderdetails Od
			on O.OrderID = OD.OrderID
			where O.UserID = @UserID)
)
*/

Select * from dbo.Productnotpurchased(6)
