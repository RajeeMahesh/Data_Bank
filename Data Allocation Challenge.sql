For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

1. running customer balance column that includes the impact each transaction
select *, sum(ps_value) over(partition by customer_id 
                               order by txn_date
                               rows unbounded preceding) as r_tot
from 
      (select *, 
              (case when txn_type = 'deposit' then txn_amount
                   else -(txn_amount)
              end) as ps_value
      from data_bank.customer_transactions
      ) t1
      
3. minimum, average and maximum values of the running balance for each customer
select customer_id, min(r_tot), round(avg(r_tot),2), max(r_tot)
from
      (select *, sum(ps_value) over(partition by customer_id 
                                     order by txn_date
                                     rows unbounded preceding) as r_tot
      from 
            (select *, 
                    (case when txn_type = 'deposit' then txn_amount
                         else -(txn_amount)
                    end) as ps_value
            from data_bank.customer_transactions
            ) t1)t2
group by customer_id

Option 1: data is allocated based off the amount of money at the end of the previous month
select m+1 as monthly_storage, sum(monthly_tot)
from 
    (select m, customer_id,sum(txn_amount)as monthly_tot
    from 
        (select customer_id, extract(month from txn_date) as m, txn_amount
        from data_bank.customer_transactions)t1
    group by m, customer_id
    order by m, customer_id)t2
group by m