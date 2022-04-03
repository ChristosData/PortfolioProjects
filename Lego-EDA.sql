--data downloaded from https://rebrickable.com/downloads/

--what is the total number of parts per theme?

create view dbo.analytics_main as

select s.set_num, s.name as set_name, s.year, s.theme_id, cast(s.num_parts as numeric) num_parts, t.name as theme_name, t.parent_id, p.name as parent_theme_name
from  [dbo].[sets] s
left join [dbo].[themes] t
	on s.theme_id = t.id
left join [dbo].[themes] p
	on t.parent_id = p.id

	select * from dbo.analytics_main

select theme_name, sum(num_parts) as total_num_parts
from dbo.analytics_main
--where parent_theme_name is not null
group by theme_name
order by 2 desc 

--what are the total parts per year?
select year, sum(num_parts) as total_num_parts
from dbo.analytics_main
--where parent_theme_name is not null
group by year
order by 1 desc 

--how many sets were created in each century in the dataset?
--add century column, separate year into buckets
ALTER view [dbo].[analytics_main] as

select s.set_num, s.name as set_name, s.year, s.theme_id, cast(s.num_parts as numeric) num_parts, t.name as theme_name, t.parent_id, p.name as parent_theme_name,
case 
	when s.year between 1901 and 2000 then '20th_century'
	when s.year between 2001 and 2100 then '21st_century'
end
as Century
from  [dbo].[sets] s
left join [dbo].[themes] t
	on s.theme_id = t.id
left join [dbo].[themes] p
	on t.parent_id = p.id
GO

select * from [dbo].[analytics_main]

select Century, count(num_parts) as total_num_parts
from dbo.analytics_main
--where parent_theme_name is not null
group by Century
order by 2 desc 


--what percentage of sets created in the 21st century are train themed
--create a subquery (CTE)

with CTE as
(
select Century, count(set_num) total_set_num, theme_name 
from dbo.analytics_main
where century = '21st_century'
group by century, theme_name
)
select  sum(total_set_num), sum(percent_total)
from
(
select century, theme_name, total_set_num, sum(total_set_num) OVER() as total, CAST(1.00*total_set_num / sum(total_set_num) OVER () as decimal(5,4)) *100 as percent_total
from CTE
)m
where theme_name like '%train%'


--what was the most popular theme by year in the 21st century?
select year, theme_name, total_set_num
from(
select year,  theme_name , count(set_num) total_set_num, row_number() over (partition by year order by count(set_num) desc) rn
from dbo.analytics_main
where century = '21st_century'
group by year, theme_name
) m
where rn = 1
order by year desc 
