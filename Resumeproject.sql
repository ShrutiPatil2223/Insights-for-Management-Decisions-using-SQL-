/*. 1. Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
business in the  APAC  region. */

select market 
from dim_customer
where region = 'APAC' and customer = "Atliq Exclusive";

/* 2.  What is the percentage of unique product increase\
 in 2021 vs. 2020? The 
final output contains these fields, 
unique_products_2020 
unique_products_2021 
percentage_chg */
select distinct s.product_code as p
from fact_sales_monthly s
join fact_gross_price g
on s.product_code = g.product_code;

with CTE1 as(
SELECT 
COUNT(DISTINCT PRODUCT_CODE) AS unique_product_code_20
from fact_sales_monthly
where fiscal_year=2020
),
cte2 as 
(
select count(distinct product_code) as unique_product_code_21
from fact_sales_monthly
where fiscal_year = 2021
)

select unique_product_code_20,unique_product_code_21,
round 
(
((unique_product_code_21 - unique_product_code_20)/unique_product_code_20)*100,2
)as perc_change
from CTE1 cross join cte2;

/* 3. */

select segment, count(distinct product_code) as product_count
from dim_product dp
group by segment
having product_count
order by product_count desc;

/*4 */

with uniq_prod_count_2020 AS (
  SELECT segment,
  count(distinct product_code) as product_count_2020,
  fiscal_year
  
  from dim_product dp
  join fact_sales_monthly f USING (product_code)
  where fiscal_year = 2020
  group by segment
  ),
  
  uniq_prod_count_2021 AS (
  SELECT segment,
  count(distinct product_code) as product_count_2021,
  fiscal_year
  
  from dim_product dp
  join fact_sales_monthly f USING (product_code)
  where fiscal_year = 2021
  group by segment
  )
   
   select 
	segment,
    product_count_2020,
    product_count_2021,
    product_count_2021 - product_count_2020 as Difference
    
    from uniq_prod_count_2020 
    join uniq_prod_count_2021 using (segment)
    group by segment
    order by DIfference Desc;
    
/*5*/

select product_code, product, min(manufacturing_cost) as low_cost, max(manufacturing_cost) as high_cost
from fact_manufacturing_cost m
join dim_product p using (product_code)
group by product_code, product
order by low_cost desc;


/*5*/

SELECT 
    product_code, 
    product, 
    manufacturing_cost AS low_cost, 
    manufacturing_cost AS high_cost
FROM 
    fact_manufacturing_cost m
JOIN 
    dim_product p USING (product_code)
WHERE 
    manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
   or 
    manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY 
    low_cost asc;


/*6*/

select customer_code,customer, round(avg(pre_invoice_discount_pct),4) as disc
from fact_pre_invoice_deductions f
join dim_customer using (customer_code)
where fiscal_year = 2021 and
    market = 'India'
group by customer_code,customer
order by disc Desc
limit 5;


/*7

month 
year
gross_sales_monthly*/

select monthname(date) as months ,s.fiscal_year, sum(gross_price * sold_quantity) as gross_cnt
from fact_sales_monthly s
join fact_gross_price g using (product_code)
join dim_customer c using (customer_code)
where customer = 'Atliq Exclusive'
group by months, s.fiscal_year
order by s.fiscal_year;


/*8*/
select 
	case 
		WHEN MONTH(date) in (9,10,11) then "Q1" 
        when MONTH(date) in (12,1,2) then "Q2" 
        when month(date) in (3,4,5) then "Q3"
        else "Q4"
	end as Quarters,
    sum(sold_quantity) as total_sold_Quantity
    
from fact_sales_monthly 
where fiscal_year = 2020
group by Quarters
order by total_sold_Quantity desc ;
    
/*9*/
/*
channel 
gross_sales_mln 
percentage;*/

with cte as (
select channel,  sum(gross_price * sold_quantity) as gross_sales_ml
from dim_customer c
join fact_sales_monthly s using (customer_code)
join fact_gross_price g using (product_code)
where s.fiscal_year = 2021
group by channel
)
select cte.*,
((gross_sales_ml*100) / sum(gross_sales_ml) over()) as percentage
from cte
order by percentage;
 
/*10*/
/*
division 
product_code 
product 
total_sold_quantity 
rank_order*/

with cte as(
select division, product_code, product, sum(sold_quantity) as total_sold_quantity
from dim_product p 
join fact_sales_monthly s using (product_code)
where fiscal_year = 2021
group by division, product,product_code
order by total_sold_quantity
),

rank1 as (
select * ,
DENSE_RANK() OVER (
      PARTITION BY division 
      ORDER BY 
        total_sold_quantity DESC	
    ) AS rank_order 
from cte
) 

select * from rank1 
where rank_order <=3;