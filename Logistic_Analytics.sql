create database logistics;
use logistics;

select * from fedex_delivery_agents;
select * from fedex_orders;
select * from fedex_routes;
select * from fedex_shipments;
select * from fedex_warehouses;

Alter table fedex_orders
rename column ï»¿Order_ID to Order_ID;
Alter table fedex_routes
rename column ï»¿Route_ID to Route_ID;
Alter table fedex_shipments
rename column ï»¿Shipment_ID to Shipment_ID;
Alter table fedex_delivery_agents
rename column ï»¿Agent_ID to Agent_ID;
Alter table fedex_warehouses
rename column ï»¿Warehouse_ID to Warehouse_ID;

#Task-1

# 1.1 
select Order_ID, count(*) as duplicate_count from fedex_orders
group by Order_ID having COUNT(*) > 1;

select Shipment_ID, count(*) as duplicate_count
FROM fedex_shipments group by Shipment_ID having count(*) > 1;

#1.2
select * from fedex_shipments where Delay_Hours is null;

#1.3
Alter table fedex_orders modify column Order_Date datetime; 
Alter table fedex_shipments modify column Pickup_Date datetime;
Alter table fedex_shipments modify column Delivery_Date datetime;

#1.4
select Shipment_ID, Pickup_Date, Delivery_Date,
'Invalid Delivery Timeline' as Issue FROM fedex_shipments WHERE Delivery_Date < Pickup_Date;

#1.5 
#Invalid Route_ID in Orders
select o.* from fedex_orders o left join fedex_routes r
on o.Route_ID = r.Route_ID where r.Route_ID is null;
#Invalid Warehouse_ID in Orders
select o.* from fedex_orders o left join fedex_warehouses w
on o.Warehouse_ID = w.Warehouse_ID where w.Warehouse_ID is null;
#Invalid Order_ID in Shipments
select s.* from fedex_shipments s left join fedex_orders o
on s.Order_ID = o.Order_ID where o.Order_ID is null;
#Invalid Agent_ID in Shipments
select s.* from fedex_shipments s left join fedex_delivery_agents a
on s.Agent_ID = a.Agent_ID where a.Agent_ID is null;
#Invalid Route_ID in Shipments
select s.* from fedex_shipments s left join fedex_routes r
on s.Route_ID = r.Route_ID where r.Route_ID is null;
#Invalid Warehouse_ID in Shipments
select s.* from fedex_shipments s left join fedex_warehouses w
on s.Warehouse_ID = w.Warehouse_ID where w.Warehouse_ID is null;

# Task - 2
select * from fedex_shipments;
select * from fedex_orders;

# 2.1 Difference of pickup and delivery date in hours
select Shipment_ID, Timestampdiff(hour, Pickup_Date, Delivery_Date) 
as Delivery_Time_Taken from fedex_shipments;

# 2.2 Top 10 delayed routes based on average delay hours
select Route_ID, round(avg(delay_hours),1) as Avg_Delay_Hours from fedex_shipments
group by Route_ID order by Avg_Delay_Hours desc limit 10;

# 2.3 Rank shipments by delay within each Warehouse_ID
select Shipment_ID, Warehouse_ID, dense_rank() over(partition by Warehouse_ID order by delay_hours desc) as Ranking
from fedex_shipments;

# 2.4 Average delay per Delivery_Type
select o.Delivery_Type, round(avg(s.delay_hours),1) as Avg_Delay_Hours from 
fedex_orders o left join fedex_shipments s on o.Order_ID = s.Order_ID
group by o.Delivery_Type order by Avg_Delay_Hours desc;

# Task 3 Route Optimization Insights
use logistics;
select * from fedex_shipments;
select * from fedex_routes;

# 3.1 For each Route - Average transit time across all shipments
select s.Shipment_ID, r.Route_ID, r.Avg_Transit_Time_Hours from 
fedex_shipments s left join fedex_routes r on s.Route_ID = r.Route_ID;

# 3.2 Avg. delay per route
select r.Route_ID, round(avg(s.Delay_Hours),1) as Avg_Delay from 
fedex_routes r left join fedex_shipments s on s.Route_ID = r.Route_ID
group by r.Route_ID order by Avg_Delay desc;

# 3.3 Distance-to-time efficiency ratio
select Route_ID, round(Distance_KM/Avg_Transit_Time_Hours,2) as Distance_To_Time_Ratio
from fedex_routes order by Distance_To_Time_Ratio desc;

# 3.4 Worst 3 routes with the lowest efficiency ratio
select Route_ID, round(Distance_KM/Avg_Transit_Time_Hours,2) as Distance_To_Time_Ratio
from fedex_routes order by Distance_To_Time_Ratio asc limit 3;

# 3.5 Routes with >20% of shipments delayed beyond expected transit time
with cte as (select s.Shipment_ID, s.Route_ID, r.Avg_Transit_Time_Hours, s.Delay_Hours
from fedex_shipments s join fedex_routes r on s.Route_ID = r.Route_ID)
select Route_ID, round(count(case when Delay_Hours>Avg_Transit_Time_Hours then 1 end)*100/count(*),2) 
as Percent_Delayed_Beyond_Transit_Time from cte 
group by Route_ID having Percent_Delayed_Beyond_Transit_Time > 20
order by Percent_Delayed_Beyond_Transit_Time desc;

# 3.6 Recommendation for potential routes for optimization

# Average Delay hours of Route 2 and 7 are very high (41 and 34). These routes need proper optimisations
# In terms of Distance to time efficiency Route 3, 15, 6 are the worst of all (37.66, 52.7, 101.46).
# Routes 8, 2, 7 have the highest percentage of delayed shipments close to 36%. 

# For these routes we have to - Investigate recurring bottlenecks such as customs clearance, congestion, or warehouse overload.
# Introduce alternate routing during peak shipment periods and optimize route planning to reduce unnecessary idle time.
# Prioritize delay alerts for these routes and deploy experienced delivery agents in high-risk zones.

# Task 4 Warehouse Performance

select * from fedex_warehouses;
select * from fedex_shipments;

# 4.1 Top 3 warehouses with the highest average delay in shipments dispatched
select Warehouse_ID, round(avg(Delay_Hours),2) as Average_Delay 
from fedex_shipments group by Warehouse_ID
order by Average_Delay desc limit 3;

# 4.2  Total shipments vs Delayed shipments for each warehouse
select Warehouse_ID, count(*) as Total_Shipments, 
count(case when Delay_Hours>0 then 1 end) as Delayed_Shipments,
round(count(case when Delay_Hours>0 then 1 end)*100/count(*),2) as Percentage
from fedex_shipments group by Warehouse_ID
order by Percentage desc;

# 4.3 Warehouses where average delay exceeds the global average delay
with cte as (
select avg(delay_hours) as Global_Avg_Delay 
from fedex_shipments)
select Warehouse_ID from fedex_shipments
group by Warehouse_ID having avg(delay_hours) > (select Global_Avg_Delay from cte);

# 4.4 Ranking all warehouses based on on-time delivery percentage
with cte as (
select Warehouse_ID, count(*) as Total_Shipments, 
round((1-(count(case when Delay_Hours>0 then 1 end)/count(*)))*100,2) as On_Time_Percentage 
from fedex_shipments group by Warehouse_ID )
select *, dense_rank() over(order by On_Time_Percentage desc) as Ranking from cte;


# Task 5:  Delivery Agent Performance

select * from fedex_delivery_agents;
select * from fedex_routes;
select * from fedex_shipments;

# 5.1 Ranking delivery agents (per route) by on-time delivery percentage
with cte as (
select Agent_ID, Route_ID,
round((count(case when Delay_Hours=0 then 1 end)/count(*))*100,2) as On_Time_Percentage 
from fedex_shipments group by Route_ID, Agent_ID )
select *, dense_rank() over(partition by Route_ID order by On_Time_Percentage desc) as Ranking from cte;

# 5.2 Agents whose on-time % is below 85%
select Agent_ID,
round((count(case when Delay_Hours=0 then 1 end)/count(*))*100,2) as On_Time_Percentage 
from fedex_shipments group by Agent_ID having On_Time_Percentage < 85.00;

# 5.3 The average rating and experience (in years) of the top 5 vs bottom 5 agents
(select a.Agent_ID,
round((count(case when s.Delay_Hours=0 then 1 end)/count(*))*100,2) as On_Time_Percentage,
a.Experience_Years, a.Avg_Rating
from fedex_delivery_agents a left join fedex_shipments s 
on a.Agent_ID = s.Agent_ID
group by a.Agent_ID, a.Experience_Years, a.Avg_Rating order by On_Time_Percentage desc limit 5)
Union 
(select a.Agent_ID,
round((count(case when s.Delay_Hours=0 then 1 end)/count(*))*100,2) as On_Time_Percentage,
a.Experience_Years, a.Avg_Rating
from fedex_delivery_agents a left join fedex_shipments s 
on a.Agent_ID = s.Agent_ID
group by a.Agent_ID, a.Experience_Years, a.Avg_Rating order by On_Time_Percentage, a.Avg_Rating, a.Experience_Years limit 5);

# 5.4 Recommendations for low performing agents 
# Targeted Training Programs on: Time management, Customer handling and communication
# Route Familiarization: Reassign low-performing agents temporarily to less complex delivery zones.
# Give weekly targets for On-time delivery %, Customer feedback ratings 
# Workload Balancing Strategies : Reduce excessive shipment allocation for these agents and pair them with experienced staff.

# Task 6: Shipment Tracking Analytics

select * from fedex_shipments;

# 6.1 For each shipment: The latest status along with the latest Delivery_Date. 
select Shipment_ID, Delivery_Date as Latest_Delivery_Date, Delivery_Status
from fedex_shipments where (Shipment_ID, Delivery_date) in (select Shipment_ID, Max(Delivery_Date) as Latest_Delivery_Date 
from fedex_shipments group by Shipment_ID);

# 6.2 Routes where the majority of shipments are still “In Transit” or “Returned”
select Route_ID, count(case when delivery_status = "In Transit" or delivery_status = "Returned" then 1 end) as Not_Delivered_Shipments,
count(*) as Total_Shipments, 
count(case when delivery_status = "In Transit" or delivery_status = "Returned" then 1 end)*100/count(*) as Percentage_Not_Delivered
from fedex_shipments group by Route_ID order by Percentage_Not_Delivered desc;

# 6.3 The most frequent delay reasons
select Delay_Reason, count(Shipment_ID) as Frequency from fedex_shipments
group by Delay_Reason order by Frequency desc limit 3;

# 6.4 Orders with exceptionally high delay (>120 hours)
select Order_ID, Delay_Hours, Delay_Reason
from fedex_shipments where Delay_Hours > 120
order by Delay_Hours desc;

with cte as (select Order_ID, Delay_Hours, Delay_Reason
from fedex_shipments where Delay_Hours > 120
order by Delay_Hours desc)
select Delay_Reason, count(*) from cte group by Delay_Reason;

# Task 7: Advanced KPI Reporting

select * from fedex_routes;
select * from fedex_shipments;
select * from fedex_warehouses;

# 7.1 Average Delivery Delay per Source_Country
select Source_Country, round(avg(Delay_Hours),2) as Average_Delay
from fedex_routes r left join fedex_shipments s 
on r.Route_ID = s.Route_ID group by Source_Country
order by Average_Delay desc;

# 7.2 Orders On-Time Delivery %
select Order_ID,
round((count(case when Delay_Hours=0 then 1 end)/count(*))*100,2) as `On_Time_Delivery%`
from fedex_shipments group by Order_ID order by `On_Time_Delivery%` desc;

# 7.3 Average Delay (in hours) per Route_ID
select Route_ID, round(avg(Delay_Hours),2) as Average_Delay 
from fedex_shipments group by Route_ID order by Average_Delay desc;

# 7.4 Warehouse Utilization %
with cte as (Select Warehouse_ID, count(*) as Shipment_Handled from fedex_shipments group by Warehouse_ID)
select w.Warehouse_ID, round(cte.Shipment_Handled/w.Capacity_per_day * 100,2) as `Warehouse_Utilization%`
from fedex_warehouses w left join cte on w.Warehouse_ID = cte.Warehouse_ID 
order by `Warehouse_Utilization%` desc;
