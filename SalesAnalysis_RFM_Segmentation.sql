---Inspecting Data
select * from dbo.sales_data

--Checking unique values
select distinct status from dbo.sales_data 
select distinct year_id from dbo.sales_data
select distinct PRODUCTLINE from dbo.sales_data 
select distinct COUNTRY from dbo.sales_data 
select distinct DEALSIZE from dbo.sales_data 
select distinct TERRITORY from dbo.sales_data 


---ANALYSIS
----Let's start by grouping sales by productline
select PRODUCTLINE, round(sum(sales),0) Revenue
from dbo.sales_data
group by PRODUCTLINE
order by 2 desc

--grouping revenue by year to check which year had the highest revenue 
select YEAR_ID, round(sum(sales),0) Revenue
from dbo.sales_data
group by YEAR_ID
order by 2 desc

--2005 revenue was the lowest, checking MONTH_ID to see if they operated the entire year, we find they only operated 5 months out of the entire year
select distinct MONTH_ID from dbo.sales_data
where year_id = 2005
order by 1 asc


select  DEALSIZE,  round(sum(sales),0) Revenue
from dbo.sales_data
group by  DEALSIZE
order by 2 desc


----Finding what the best month for sales in a specific year was and displaying the figures.
select  MONTH_ID, round(sum(sales),0) Revenue, count(ORDERNUMBER) Frequency
from dbo.sales_data
where YEAR_ID = 2004 --change year to see the rest
group by  MONTH_ID
order by 2 desc

--November is the best performing month for both 2003 and 2004

--Finding what product line is contributing the most to the revenue
select  MONTH_ID, PRODUCTLINE, round(sum(sales),0)  Revenue, count(ORDERNUMBER)
from dbo.sales_data
where YEAR_ID = 2004 and MONTH_ID = 11 --change year to see the rest
group by  MONTH_ID, PRODUCTLINE
order by 3 desc


--Finding out the most valuable customers in terms of monetary value (Using RFM Analysis)
--Using a temp table and CTE


DROP TABLE IF EXISTS #rfm
with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from dbo.sales_data) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from dbo.sales_data)) Recency --Recency value displays the days elapsed since last order
	from dbo.sales_data
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar) rfm_cell_string
	into #rfm
from rfm_calc c

--we can run the above query now with this temp table
select * from #rfm

--creating segmentation with a case statement
--we created 4 buckets [1-4], the higher the number, the higher the value 
--444 = the customer buys frequently, number of items is alot and high order value
--111 =  the customer buys infrequently, small number of items and low order value
select CUSTOMERNAME , rfm_cell_string, rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (high order value spenders who have not purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 421, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm



--What products are most often sold together? 
--subqueries
--converting results from XML to a string
select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from dbo.sales_data p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
--looking at all the orders that have shipped
				select ORDERNUMBER, count(*) rn
				FROM dbo.sales_data
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 2
		)
--making a join between both columns of order numbers
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from dbo.sales_data s
order by 2 desc
--running the queries above we can begin to see different orders from different customers who order similar products
--knowing this we can run promotions on items which are typically bundled/ordered together.


---EXTRAs----
--Which city has the highest number of sales in the UK
select city, sum (sales) Revenue
from dbo.sales_data
where country = 'UK'
group by city
order by 2 desc



---What is the best selling product in the United States? [ranked by highest revenue]
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from dbo.sales_data
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc
