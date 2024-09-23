select * from HumanResources.EmployeePayHistory
 
 select sum(totaldue) from Sales.SalesOrderHeader

 -------- windows functions -------------

 select SalesPersonID, totaldue, sum(totaldue)over() as 'sum of total due' 
 from Sales.SalesOrderHeader

 select sum(totaldue) 
 from Sales.SalesOrderHeader


 select BusinessEntityID, Rate, AVG(rate)over() from HumanResources.EmployeePayHistory

 select BusinessEntityID, Rate, 'percentage' = Rate/ MAX(rate)over()*100 from HumanResources.EmployeePayHistory

 ------------ join -------------

Select FirstName,LastName, JobTitle, Rate, 'maxrate'= max(rate)over(), 'Difffromavgrate' = Rate-max(rate)over() from (Person.Person
 left join HumanResources.EmployeePayHistory on Person.BusinessEntityID = EmployeePayHistory.BusinessEntityID) 
 left join HumanResources.Employee on Person.BusinessEntityID = Employee.BusinessEntityID

 ------partition by order by clause ---------------

 select Product.Name as ProductName, ProductSubcategory.Name as productSubcategory, 
 ProductCategory.Name as productName, ListPrice, AVG(ListPrice)over(Partition by ProductCategory.Name,ProductSubcategory.Name) 
 from (Production.Product 
 inner join Production.ProductSubcategory 
 on Product.ProductSubcategoryID = ProductSubcategory.ProductSubcategoryID)
 inner join Production.ProductCategory on Product.ProductSubcategoryID = ProductCategory.ProductCategoryID

 select Product.Name as ProductName, ProductSubcategory.Name as productSubcategory, ProductCategory.Name as productName,
 ListPrice, AVG(listprice) OVER(PARTITION BY ProductCategory.Name, ProductSubcategory.Name) as AverageLP, 
 ListPrice-AVG(listprice) OVER(PARTITION BY ProductCategory.Name)
from (Production.Product
 inner join Production.ProductSubcategory
 on Product.ProductSubcategoryID = ProductSubcategory.ProductSubcategoryID)
 inner join Production.ProductCategory on Product.ProductSubcategoryID = ProductCategory.ProductCategoryID

 ------------ Row number ----------------

 SELECT
[SalesOrderID] ,
[SalesOrderDetailID],
[LineTotal] ,
ProductIDLineTotal = sum([LineTotal])OVER(PARTITION BY salesorderId),
Ranking =ROW_NUMBER() OVER(ORDER BY [LineTotal] desc)
from sales.SalesOrderDetail

-------- Rank & Dense_Rank (Case) ---------
select * from Production.Product
select * from Production.ProductCategory
select * from Production.ProductSubcategory



 select A.Name as ProductName, B.Name as productSubcategory, C.Name as productName,
 ListPrice, 'Price Rank'= row_number() over(partition by C.Name order by listprice),
 'Price Rank with rank'= rank() over(partition by C.Name order by listprice),
 'Price Rank with dense rank'= dense_rank() over(partition by C.Name order by listprice)
 ,case
	when rank() over(partition by C.name order by listprice)<=5
	then 'yes'
	else 'no'
	end as Top5
 from Production.Product A
 join Production.ProductSubcategory B
 on A.ProductSubcategoryID = B.ProductSubcategoryID
 join Production.ProductCategory C on B.ProductCategoryID = C.ProductCategoryID
 
 ----------- Lead and Lag -------------

 select PurchaseOrderID, OrderDate, TotalDue, Name ,
 'PrevOrderFromVendorAmt'=lag(TotalDue,1)over(order by orderdate),
 'NextOrderByEmployeeVendor'=LEAD(TotalDue,1)over(partition by employeeid order by totaldue)
 from Purchasing.PurchaseOrderHeader
 join Purchasing.Vendor on PurchaseOrderHeader.VendorID=Vendor.BusinessEntityID
 where OrderDate >='2013' and TotalDue>=500

 ---------- first_value --------------

 select PurchaseOrderID, OrderDate, TotalDue, Name ,
 first_value(TotalDue) over(partition by Name order by TotalDue desc),
  first_value(TotalDue) over(partition by Name order by TotalDue)
 from Purchasing.PurchaseOrderHeader
 join Purchasing.Vendor on PurchaseOrderHeader.VendorID=Vendor.BusinessEntityID
 where OrderDate >='2013' and TotalDue>=500


 select BusinessEntityID as EmployeeID, JobTitle, HireDate, VacationHours, 
 firsthirevach=FIRST_VALUE(vacationhours)over(partition by jobtitle order by hiredate desc)
 from HumanResources.Employee
 order by JobTitle, HireDate asc


select a.ProductID, a.Name, b.ModifiedDate, 
b.ListPrice,
highprice=first_value(b.ListPrice)over(partition by a.name order by b.listprice desc),
lowprice=first_value(b.ListPrice)over(partition by a.name order by b.listprice),
Diff=abs(first_value(b.ListPrice)over(partition by a.name order by b.listprice desc)-first_value(b.ListPrice)over(partition by a.name order by b.listprice))
from Production.Product A
join Production.ProductListPriceHistory B
on A.ProductID=B.ProductID
order by a.ProductID, b.ModifiedDate


---------- subqueries --------------

select PurchaseOrderID,VendorID,OrderDate, TaxAmt, Freight, ranking
from
(select PurchaseOrderID,VendorID,OrderDate, TaxAmt, Freight ,
Dense_Rank()over(partition by vendorid order by totaldue desc)
as ranking
from Purchasing.PurchaseOrderHeader) A
where ranking between 1 and 3


-------------


SELECT OrderDate, TotalDue,
SalesLast3Days= sum(TotalDue) OVER(ORDER BY orderDate ROWS BETWEEN 1 PRECEDING and 1 FOLLOWING)
FROM (SELECT
OrderDate ,
TotalDue = SUM(TotalDue)
FROM
Sales.SalesOrderHeader
WHERE YEAR (OrderDate) =2014
GROUP BY
OrderDate) A
 

 ------------------
 SELECT
 YEAR,MONTH,SUMTOTAL,
 Rolling3MonthTotal= SUM(SUMTOTAL)OVER(ORDER BY YEAR, MONTH ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),
 MovingAvg6Month=AVG(SUMTOTAL)OVER(ORDER BY YEAR, MONTH ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING),
 MovingAvgNext2Months=AVG(SUMTOTAL)OVER(ORDER BY YEAR, MONTH ROWS BETWEEN CURRENT ROW AND 2 FOLLOWING)
 FROM
 (SELECT 
 SUM(SubTotal) AS SUMTOTAL,  
 YEAR(ORDERDATE) AS YEAR, 
 MONTH(OrderDate) AS MONTH
 FROM Purchasing.PurchaseOrderHeader
 GROUP BY YEAR(ORDERDATE), MONTH(OrderDate)) A
 ORDER BY YEAR, MONTH

 ------------ scaler subquery -------------

 select max(vacationhours) from HumanResources.Employee

 select BusinessEntityID, JobTitle, VacationHours, 
 MaxVacationHours = (select max(vacationhours) from HumanResources.Employee),
 percentvachours =  VacationHours*1.00/(select max(vacationhours) from HumanResources.Employee)
 from HumanResources.Employee
 where (VacationHours*1.00/(select max(vacationhours) from HumanResources.Employee))>=0.8

 ------------- correlated subquery --------------

 SELECT
SalesOrderID
, OrderDate
, SubTotal
, TaxAmt
, Freight
, TotalDue
, Multiordercount=(
SELECT COUNT(*)
FROM AdventureWorks2022.Sales.SalesOrderDetail b
WHERE b.SalesOrderID = a.SalesOrderID and OrderQty>1
)
FROM AdventureWorks2022.Sales.SalesOrderHeader A

select * from sales.SalesOrderDetail
select * from Sales.SalesOrderHeader


select PurchaseOrderID, VendorID, OrderDate, TotalDue, 
NonRejectedItems=(
select count(*) 
from Purchasing.PurchaseOrderDetail b
where a.PurchaseOrderID=b.PurchaseOrderID and RejectedQty = 0
),
MostExpensiveItem=(
select max(unitprice) 
from Purchasing.PurchaseOrderDetail b
where a.PurchaseOrderID=b.PurchaseOrderID
group by PurchaseOrderID
)
from Purchasing.PurchaseOrderHeader a



-------------------------------------------------


SELECT
 A.[salesorderiD]
,A.[OrderDate]
,A.[TotalDue]
 FROM 
 sales.SalesOrderHeader A
   WHERE not exists 
     (
       select B.LineTotal
       from 
       Sales.SalesOrderDetail B
          where b.LineTotal>10000
          AND A.SalesOrderID=B.SalesOrderID
     )
 order by 1

 ----------------------------------------------------------------

 select * from Purchasing.PurchaseOrderHeader
 select * from Purchasing.PurchaseOrderDetail where RejectedQty>0 order by 1

 select A.*
 from Purchasing.PurchaseOrderHeader a
 where exists(
	select *
	from Purchasing.PurchaseOrderDetail b
	where OrderQty>500 and UnitPrice>50 and a.PurchaseOrderID=b.PurchaseOrderID
	)
order by 1

---------------------------------------------------------------------------

 select A.*
 from Purchasing.PurchaseOrderHeader a
 where exists(
	select 1
	from Purchasing.PurchaseOrderDetail b
	where RejectedQty<=0 and a.PurchaseOrderID=b.PurchaseOrderID
	)
order by 1

----------------for xml path--------------------

select
',' + CAST(cast(LineTotal as money) as varchar)
from
Sales.SalesOrderDetail
for xml path('')


---------stuff needs 4 arg i.e. what to place, where to start in the 4th arg, how much to clip off from the 1st arg, where to place------

select stuff (
(select
',' + CAST(cast(LineTotal as money) as varchar)
from
Sales.SalesOrderDetail
where SalesOrderID=43659
for xml path('')),1,1,'')


-------------------------------------
select * from Production.Product
select * from Production.ProductSubcategory



select SubcategoryName= a.name ,
Products= (select STUFF(
		(select 
		','+ B.name
		from Production.Product B
		where ProductSubcategoryID=21
		--where a.ProductSubcategoryID=b.ProductSubcategoryID and ListPrice>50
		for xml path('')),1,1,''))
from Production.ProductSubcategory A




SELECT *
FROM
(SELECT
ProductCategoryName = D.Name,
A.LineTotal, OrderQty
FROM Sales.SalesOrderDetail A
JOIN production.product B
ON A.ProductID = B.ProductID
JOIN Production.Productsubcategory C
ON B.ProductSubcategoryID = C.ProductSubcategoryID
JOIN Production.Productcategory D
ON C.ProductCategoryID = D.ProductCategoryID) A

PIVOT(
SUM(LineTotal)
FOR ProductCategoryName IN
(
	[bikes],[clothing]
		) 
) B

order by 1



select *
from
(select gender, JobTitle, VacationHours from HumanResources.Employee
) A
pivot(
avg(vacationhours) for jobtitle in (
[Sales Representative], [Buyer], [Janitor]
)) B




---------------common table expression---------------------

-------without cte-----example 1----------
select 
ordermonth, 
'sum of top 10'=SUM(TotalDue),
'sum of prev top 10'= lag(sum(TotalDue),1)over(order by ordermonth)
from
(
select  
OrderDate,
TotalDue,
ordermonth=DATEFROMPARTS(year(orderdate),month(orderdate),1),
orderrank= row_number()over(partition by DATEFROMPARTS(year(orderdate),month(orderdate),1) order by totaldue desc)
from Sales.SalesOrderHeader) A
where orderrank<=10
group by ordermonth
order by ordermonth

--------using cte----------example 1----------
with sale as (
select  
OrderDate,
TotalDue,
ordermonth=DATEFROMPARTS(year(orderdate),month(orderdate),1),
orderrank= row_number()over(partition by DATEFROMPARTS(year(orderdate),month(orderdate),1) order by totaldue desc)
from Sales.SalesOrderHeader
)

select 
ordermonth, 
'sum of top 10'=SUM(TotalDue),
'sum of prev top 10'= lag(sum(TotalDue),1)over(order by ordermonth)
from
sale
where orderrank<=10
group by ordermonth
order by ordermonth



------------------Using CTE---------------------example 2-----------

with sale as (
SELECT 
OrderDate
	,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
	,TotalDue
	,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
	FROM Sales.SalesOrderHeader
)
,purchase as 
(
SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM Purchasing.PurchaseOrderHeader
),
totpurch as 
(
SELECT
	OrderMonth,
	TotalPurchases = SUM(TotalDue)
	FROM purchase
	WHERE OrderRank > 10
	GROUP BY OrderMonth
)

, totsal as(
SELECT
	OrderMonth,
	TotalSales = SUM(TotalDue)
	FROM sale
	WHERE OrderRank > 10
	GROUP BY OrderMonth
	)
	select A.OrderMonth,
A.TotalSales,
B.TotalPurchases
from
	totsal A
	join totpurch B ON A.OrderMonth = B.OrderMonth
	order by 1

---------------------Above query without cte-----------------example 2-----------

SELECT
A.OrderMonth,
A.TotalSales,
B.TotalPurchases

FROM (
	SELECT
	OrderMonth,
	TotalSales = SUM(TotalDue)
	FROM (
		SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM Sales.SalesOrderHeader
		) S
	WHERE OrderRank > 10
	GROUP BY OrderMonth
) A

JOIN (
	SELECT
	OrderMonth,
	TotalPurchases = SUM(TotalDue)
	FROM (
		SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM Purchasing.PurchaseOrderHeader
		) P
	WHERE OrderRank > 10
	GROUP BY OrderMonth
) B	ON A.OrderMonth = B.OrderMonth

ORDER BY 1


---------------recursive cte----------------

with numberseries as (
select 1 as mynumb

union all

select mynumb+1 
from numberseries
where mynumb<100
)

select mynumb from numberseries
where mynumb % 2 = 0

-----------date recursive cte--------------

with dateseries as (
select cast('1/1/2020' as date) as mydate

union all

select DATEADD(MONTH,1,mydate)
from dateseries
where mydate<CAST('12/1/2029' as date)
)

select mydate from dateseries
option(MAXRECURSION 200)


--------------Temp Tables-----------------


SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		  into #sales
		FROM Sales.SalesOrderHeader



SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		  into #purhcase
		FROM Purchasing.PurchaseOrderHeader




SELECT
	OrderMonth,
	TotalPurchases = SUM(TotalDue)
	into #totpurch
	FROM #purhcase
	WHERE OrderRank > 10
	GROUP BY OrderMonth


SELECT
	OrderMonth,
	TotalSales = SUM(TotalDue)
	into  #totsal
	FROM #sales
	WHERE OrderRank > 10
	GROUP BY OrderMonth
	


select A.OrderMonth,
A.TotalSales,
B.TotalPurchases
from
	#totsal A
	join #totpurch B ON A.OrderMonth = B.OrderMonth
	order by 1


---------- create table insert into ------------------


create table #sales(
OrderDate date
,OrderMonth date
,TotalDue money
,OrderRank int
)
insert into #sales
SELECT 
		   OrderDate
		  ,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
		  ,TotalDue
		  ,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
		FROM Sales.SalesOrderHeader
select * from #sales

--------------Update------------------

CREATE Table #New
(OrderDate DATETIME,
Ordermonth DATE,
Totaldue MONEY,
orderrank INT,
OrderType VARCHAR(32))


INSERT INTO #New
(OrderDate ,
Ordermonth ,
Totaldue ,
orderrank ,
OrderType )

SELECT
	OrderDate
	,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
	,TotalDue
	,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC),
	OrderType= 'Sales'
FROM Sales.SalesOrderHeader


select * from #New

UPDATE #New
Set OrderType =
CASE when Orderrank < 10 THEN
'purchase' else 'sale' end

drop table #new


--Re-write an optimized version of the below query using temp tables and UPDATE statements:

SELECT 
	   A.BusinessEntityID
      ,A.Title
      ,A.FirstName
      ,A.MiddleName
      ,A.LastName
	  ,B.PhoneNumber
	  ,PhoneNumberType = C.Name
	  ,D.EmailAddress

FROM AdventureWorks2022.Person.Person A
	LEFT JOIN AdventureWorks2022.Person.PersonPhone B
		ON A.BusinessEntityID = B.BusinessEntityID
	LEFT JOIN AdventureWorks2022.Person.PhoneNumberType C
		ON B.PhoneNumberTypeID = C.PhoneNumberTypeID
	LEFT JOIN AdventureWorks2022.Person.EmailAddress D
		ON A.BusinessEntityID = D.BusinessEntityID


--Rewrite:

CREATE TABLE #PersonContactInfo
(
	   BusinessEntityID INT
      ,Title VARCHAR(8)
      ,FirstName VARCHAR(50)
      ,MiddleName VARCHAR(50)
      ,LastName VARCHAR(50)
	  ,PhoneNumber VARCHAR(25)
	  ,PhoneNumberTypeID VARCHAR(25)
	  ,PhoneNumberType VARCHAR(25)
	  ,EmailAddress VARCHAR(50)
)

INSERT INTO #PersonContactInfo
(
	   BusinessEntityID
      ,Title
      ,FirstName
      ,MiddleName
      ,LastName
)

SELECT
	   BusinessEntityID
      ,Title
      ,FirstName
      ,MiddleName
      ,LastName

FROM AdventureWorks2022.Person.Person


UPDATE A
SET
	PhoneNumber = B.PhoneNumber,
	PhoneNumberTypeID = B.PhoneNumberTypeID

FROM #PersonContactInfo A
	JOIN AdventureWorks2022.Person.PersonPhone B
		ON A.BusinessEntityID = B.BusinessEntityID


UPDATE A
SET	PhoneNumberType = B.Name

FROM #PersonContactInfo A
	JOIN AdventureWorks2022.Person.PhoneNumberType B
		ON A.PhoneNumberTypeID = B.PhoneNumberTypeID


UPDATE A
SET	EmailAddress = B.EmailAddress

FROM #PersonContactInfo A
	JOIN AdventureWorks2022.Person.EmailAddress B
		ON A.BusinessEntityID = B.BusinessEntityID


SELECT * FROM #PersonContactInfo

-----------------------Clustered and Non Clustered Index-------------------------------

CREATE TABLE #PersonContactInfo
(
	   BusinessEntityID INT
      ,Title VARCHAR(8)
      ,FirstName VARCHAR(50)
      ,MiddleName VARCHAR(50)
      ,LastName VARCHAR(50)
	  ,PhoneNumber VARCHAR(25)
	  ,PhoneNumberTypeID VARCHAR(25)
	  ,PhoneNumberType VARCHAR(25)
	  ,EmailAddress VARCHAR(50)
)

INSERT INTO #PersonContactInfo
(
	   BusinessEntityID
      ,Title
      ,FirstName
      ,MiddleName
      ,LastName
)

SELECT
	   BusinessEntityID
      ,Title
      ,FirstName
      ,MiddleName
      ,LastName

FROM AdventureWorks2022.Person.Person


create clustered index personcontact_idx on #PersonContactInfo(BusinessEntityID)


UPDATE A
SET
	PhoneNumber = B.PhoneNumber,
	PhoneNumberTypeID = B.PhoneNumberTypeID

FROM #PersonContactInfo A
	JOIN AdventureWorks2022.Person.PersonPhone B
		ON A.BusinessEntityID = B.BusinessEntityID

create nonclustered index personcontact_idx2 on #PersonContactInfo(PhoneNumberTypeID)


UPDATE A
SET	PhoneNumberType = B.Name

FROM #PersonContactInfo A
	JOIN AdventureWorks2022.Person.PhoneNumberType B
		ON A.PhoneNumberTypeID = B.PhoneNumberTypeID


UPDATE A
SET	EmailAddress = B.EmailAddress

FROM #PersonContactInfo A
	JOIN AdventureWorks2022.Person.EmailAddress B
		ON A.BusinessEntityID = B.BusinessEntityID


SELECT * FROM #PersonContactInfo

------------------------lookup table-------------------------------

create table Adventureworks2022.dbo.Calander
(
datevalue date,
weekdaynumber int,
weekdayname varchar(32),
monthdate int,
monthnumb int,
yearnumb int,
weekend tinyint,
holiday tinyint
)


with dateseries as (
select cast('01/01/2011' as date) as mydate

union all

select DATEADD(DAY,1,mydate)
from dateseries
where mydate<cast('12/31/2030' as date)
)


insert into Adventureworks2022.dbo.Calander
(
datevalue)

select mydate from dateseries
option(MAXRECURSION 10000)

select * from Calander

update Adventureworks2022.dbo.Calander
set
weekdaynumber=DATEPART(weekday,datevalue),
weekdayname=format(datevalue,'dddd'),
monthnumb=month(datevalue),
yearnumb=year(datevalue),
monthdate=day(datevalue)

update Adventureworks2022.dbo.Calander
set
weekend=
case when weekdaynumber in (1,7) then 1
else 0
end

update Adventureworks2022.dbo.Calander
set
holiday=
case when monthdate=1 and monthnumb=1 then 1
else 0
end

select * from Purchasing.PurchaseOrderHeader A
	join Calander B on A.OrderDate = B.datevalue
		where b.holiday=1 and b.weekend=1

------------------------------------View--------------------------------------
CREATE VIEW Sales.vw_Top10MonthOverMonth AS

 WITH Sales AS
(
SELECT
OrderDate
,OrderMonth = DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1)
,TotalDue
,OrderRank = ROW_NUMBER() OVER(PARTITION BY DATEFROMPARTS(YEAR(OrderDate),MONTH(OrderDate),1) ORDER BY TotalDue DESC)
FROM AdventureWorks2022.Sales.SalesOrderHeader
)
 
,Top10Sales AS
(
SELECT
OrderMonth,
Top10Total = SUM(TotalDue)
FROM Sales
WHERE OrderRank <= 10
GROUP BY OrderMonth
)
 
 
SELECT
A.OrderMonth,
A.Top10Total,
PrevTop10Total = B.Top10Total
 
FROM Top10Sales A
LEFT JOIN Top10Sales B
ON A.OrderMonth = DATEADD(MONTH,1,B.OrderMonth)
 
 --------------view can not be created using temp tables-------------------

 -------------Variables-----------------

 declare @myvar int
 select @myvar=11
 select @myvar

 ---------------------------------------------------------------------

 --Starter code:

 declare @maxvachours int
 select @maxvachours= (SELECT MAX(VacationHours) FROM AdventureWorks2022.HumanResources.Employee)

SELECT
	   BusinessEntityID
      ,JobTitle
      ,VacationHours
	  ,MaxVacationHours = @maxvachours
	  ,PercentOfMaxVacationHours = (VacationHours * 1.0) / @maxvachours

FROM AdventureWorks2022.HumanResources.Employee

WHERE (VacationHours * 1.0) / @maxvachours >= 0.8


------------exercise-----------------

declare @today date
set @today=cast(GETDATE() as date)

declare @POM date
set @POM = DATEFROMPARTS(YEAR(@today),month(@today),15)

declare @EOM date
set @EOM = DATEADD(day,-1,@POM)

declare @startingdate date
select @startingdate = (
select 
case when @today > @POM then dateadd(month,-1,@POM)
else dateadd(month,-2,@POM)
end)
select @startingdate

declare @enddate date
Select @enddate = (
select 
case when @today > @POM then @EOM
else dateadd(month,-1,@EOM)
end
)
select @enddate

------------------user defined functions-----------------

create function dbo.ufncurrentdate()
returns date
as
begin
 return cast(getdate() as date)
end


create function dbo.ufnpercent(@firstnum float,@secondnum float)
returns varchar(8)
as
begin
return cast(format((@firstnum/@secondnum),'P') as varchar(8))
end

select dbo.ufnpercent(8,100)

declare @maxvach int
set @maxvach=(
select max(VacationHours) from AdventureWorks2022.HumanResources.Employee
)

select BusinessEntityID,JobTitle,VacationHours, 
'PercentOfMaxVacation'= dbo.ufnpercent(VacationHours,@maxvach)
from HumanResources.Employee

--drop function dbo.ufnpercent1


-------------------Ufn Table valued function-----------------------


create function Production.ufn_ProductsByPriceRange(@min int, @max int)
returns table
as 
return(
select ProductID, name, ListPrice 
from Production.Product
where ListPrice between @min and @max)

select * 
from Production.ufn_ProductsByPriceRange(0,100)

--drop function Production.ufn_ProductsByPriceRange

create procedure OrdersAboveThreshold(@Threshold int,@StartYear int,@EndYear int)
as
begin
 select SalesOrderID,TotalDue,OrderDate 
 from Sales.SalesOrderHeader
 where TotalDue>@Threshold and OrderDate between DATEFROMPARTS(@startYear,01,01) and datefromparts(@EndYear,12,31)
end

--select DATEFROMPARTS(2021,01,01) 

exec OrdersAboveThreshold 10000,2010,2011,1

declare @myvar int=1
select @myvar

create table #orders(
orderid int,
TotalDue float,
OrderDate date,
)

select TotalDue,OrderDate--, ordertype='Sales'
into #orders
from Sales.salesOrderHeader
insert into #orders(TotalDue,OrderDate)--,ordertype)
select TotalDue,OrderDate--, ordertype='Purchase'
from Purchasing.PurchaseOrderHeader

select * from #orders

--select * from Purchasing.PurchaseOrderHeader
--select * from Sales.SalesOrderHeader

--truncate table #orders
drop table #orders


select * from Calander


select * from Purchasing.PurchaseOrderHeader
select * from Sales.SalesOrderHeader

select orderid=SalesOrderID, TotalDue, OrderDate,ordertype='sales'  
into #orders
from Sales.SalesOrderHeader

insert into #orders(orderid,TotalDue,OrderDate,ordertype)
select orderid=PurchaseOrderID, TotalDue, OrderDate,ordertype='Purchase'  
from Purchasing.PurchaseOrderHeader

select * from #orders

create table #orders(
orderid int,
totaldue money,
orderdate date,
ordertype varchar(32)
)
insert into #orders(
orderid ,
totaldue ,
orderdate ,
ordertype 
)
select orderid=salesorderid,TotalDue,OrderDate,ordertype='Sales' 
from sales.SalesOrderHeader
union all
select orderid=PurchaseOrderID,TotalDue,OrderDate,ordertype='Purchase' 
from Purchasing.PurchaseOrderHeader

select * from #orders

exec dbo.OrdersAboveThreshold 100,2010,2011,3

SELECT TOP 100 FROM Production.Product


SELECT * FROM Person.Person 
WHERE FirstName LIKE '%RA%'--@variable


declare @NameToSearch varchar(32)='FirstName'
declare @SearchPattern varchar(32)='ra'
declare @dynamicsql varchar(max)
set @dynamicsql='SELECT * FROM Person.Person 
WHERE '
set @dynamicsql = @dynamicsql + @NameToSearch
set @dynamicsql = @dynamicsql + ' LIKE '
set @dynamicsql = @dynamicsql + '''' +'%' + @SearchPattern + '%' + ''''
select @dynamicsql


exec dbo.NameSearch firstname,r,2
