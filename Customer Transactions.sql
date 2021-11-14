2. What is the average total historical deposit counts and amounts for all customers?
select customer_id, sum(txn_amount), count(txn_amount)
from data_bank.customer_transactions
group by customer_id
order by customer_id
3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
select * from 
		(select customer_id, 
			   extract (month from txn_date) as m,
			   count(case when txn_type = 'deposit' then txn_amount end) as Dep_count,
			   count(case when txn_type = 'withdrawal' then txn_amount end) as wd_count,
			   count(case when txn_type = 'purchase' then txn_amount end) as pur_count
		from data_bank.customer_transactions
		group by customer_id,m
		order by m, customer_id) t1
where dep_count > 1 and (wd_count = 1 or pur_count = 1)
4. What is the closing balance for each customer at the end of the month?
select *, SUM(total) OVER (
							partition by customer_id
							order by m
							rows unbounded preceding) as running_total,
		  SUM(total) OVER (
							partition by customer_id
							order by m
							rows between 1 preceding and current row) as r
from(
		select  customer_id, extract (month from txn_date) as m, 
				sum(case when txn_type = 'deposit' then txn_amount
					else -txn_amount 
					end) as total 
		from data_bank.customer_transactions
		group by customer_id, m
		order by customer_id, m) t1
    
5. What is the percentage of customers who increase their closing balance by more than 5%?
select *, (big_cust/all_cust)*100 as final_answer
from 
          (select all_cust, (coalesce (big_cust,0)) as big_cust
          from 
                (select count as all_cust, lag(count) over (order by count) as big_cust from 
                      (select count( distinct ddb.customer_id)
                      from 
 
                      (select * from 
                                    (select *, ((running_total-opening_bal)/opening_bal)*100 as incr_perc
                                    from 
                                          (select customer_id, m, total, running_total, coalesce(opening_bal,0) as opening_bal
                                          from 
                                                (select *, lag(running_total) over (partition by customer_id
                                                                                order by m) as opening_bal
                                                from                                 
                                                      (select *, SUM(total) OVER (
                                                                                  partition by customer_id
                                                                                  order by m
                                                                                  rows unbounded preceding) as running_total,
                                                                SUM(total) OVER (
                                                                                  partition by customer_id
                                                                                  order by m
                                                                                  rows between 1 preceding and current row) as r
                                                      from(
                                                              select  customer_id, extract (month from txn_date) as m, 
                                                                      sum(case when txn_type = 'deposit' then txn_amount
                                                                          else -txn_amount 
                                                                          end) as total 
                                                              from data_bank.customer_transactions
                                                              group by customer_id, m
                                                              order by customer_id, m) t1)t2)t3)t4
                                    where opening_bal <> 0)t5
                      where incr_perc > 5 and opening_bal < running_total) ddb
                      union 
                      select count(distinct odb.customer_id)
                      from data_bank.customer_transactions odb) count_table) final_table) fin_ans
where big_cust <> 0
