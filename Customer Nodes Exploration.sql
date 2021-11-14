1.How many days on average are customers reallocated to a different node?
select round(avg(t1.time_period),2)
from
		(select customer_id, round(avg(end_date - start_date),2) as time_period
		from data_bank.customer_nodes
		where end_date <> '9999-12-31'
		group by customer_id 
		order by customer_id) t1
    
2. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
select percentile_cont(.50) within group (order by time_period) as median, 
		percentile_cont(.80) within group (order by time_period) as eighty_percentile,
		percentile_cont(.95) within group (order by time_period) as nintyfive_percentile
from 
		(select customer_id, round(avg(end_date - start_date),2) as time_period 
		from data_bank.customer_nodes 
		where end_date <> '9999-12-31'
		group by customer_id
		order by customer_id) t1
		
