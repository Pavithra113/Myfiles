create database Pandemic_mortality
use Pandemic_mortality

Create table mortal_report
(date_as_of Date,Jurisdiction_Residence varchar(max),Group_interval varchar(max),data_period_start date,data_period_end	date,COVID_deaths int,
COVID_pct_of_total decimal(10,2),pct_change_wk decimal(10,2),pct_diff_wk decimal(10,2),crude_COVID_rate decimal(10,2),aa_COVID_rate decimal(10,2))

---Path of file - F:\Office\Projects
---Bulk inserting the data in csv file - DA_Data - Pandemic.csv

Bulk insert mortal_report from 'F:\Office\Projects\DA_Data - Pandemic.csv'
with (fieldterminator = ',',
			rowterminator = '\n',
							firstrow = 2,
										maxerrors = 20)

Select * from mortal_report

select column_name,data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'mortal_report'

---Data Cleaning 
---Convert cells with zero value and blanks to null value

/*Select COVID_pct_of_total from mortal_report where COVID_pct_of_total = 0*/
Update mortal_report
set COVID_pct_of_total = 0
WHERE TRY_CAST(COVID_pct_of_total AS DECIMAL(10,2)) is null

update mortal_report
set  COVID_pct_of_total = Null
WHERE COVID_pct_of_total = 0 

/*Select COVID_deaths from mortal_report where COVID_deaths = 0*/
Update mortal_report
set COVID_deaths = 0
WHERE TRY_CAST(COVID_deaths AS DECIMAL(10,2)) is null

update mortal_report
set  COVID_deaths = Null
WHERE COVID_deaths = 0 

/*Select pct_change_wk from mortal_report where pct_change_wk = 0*/
Update mortal_report
set pct_change_wk = 0
WHERE TRY_CAST(pct_change_wk AS DECIMAL(10,2)) is null

update mortal_report
set pct_change_wk = Null
WHERE pct_change_wk = 0 

/*Select pct_diff_wk from mortal_report where pct_diff_wk = 0*/
Update mortal_report
set pct_diff_wk = 0
WHERE TRY_CAST(pct_diff_wk AS DECIMAL(10,2)) is null

update mortal_report
set  pct_diff_wk = Null
WHERE pct_diff_wk = 0 

/*Select crude_COVID_rate from mortal_report where crude_COVID_rate = 0*/
Update mortal_report
set crude_COVID_rate = 0
WHERE TRY_CAST(crude_COVID_rate AS DECIMAL(10,2)) is null

update mortal_report
set  crude_COVID_rate = Null
where crude_COVID_rate = 0 

/*Select aa_COVID_rate from mortal_report where aa_COVID_rate = 0*/
Update mortal_report
set aa_COVID_rate = 0
where TRY_CAST(aa_COVID_rate as decimal(10,2)) is null

update mortal_report
set  aa_COVID_rate = Null
where aa_COVID_rate = 0 


----SQL Analysis---

---1. Retrieve the jurisdiction residence with the highest number of COVID deaths for the latest  data period end date.
select jurisdiction_residence, covid_deaths,data_period_end
from mortal_report
where data_period_end = (select max(data_period_end) from mortal_report)
order by 2 desc

---2. Retrieve the top 5 jurisdictions with the highest percentage difference in aa_COVID_rate compared to the overall crude COVID rate for the latest data period end date.
select top 5 Jurisdiction_Residence, aa_COVID_rate, crude_COVID_rate, ((aa_COVID_rate - crude_COVID_rate) / crude_COVID_rate) * 100 as pct_diff
from mortal_report
where data_period_end = (select max(data_period_end) from mortal_report)
order by 4 desc

---3. Calculate the average COVID deaths per week for each jurisdiction residence and group, for  the latest 4 data period end dates.
with Latestdataperiod as (
select distinct top 4 data_period_end from mortal_report
order by data_period_end desc)

select jurisdiction_residence, group_interval, avg(covid_deaths) as Avg_Covid_Deaths 
from mortal_report
where data_period_end in (select data_period_end from latestdataperiod)
group by Jurisdiction_Residence, Group_interval

---4. Retrieve the data for the latest data period end date, but exclude any jurisdictions that had  zero COVID deaths and have missing values in any other column.
select * from mortal_report
where data_period_end = (select max(data_period_end) from mortal_report)
and covid_deaths > 0
and covid_pct_of_total is not null
and pct_change_wk is not null
and pct_diff_wk is not null
and crude_COVID_rate is not null
and aa_COVID_rate is not null

---5. Calculate the week-over-week percentage change in COVID_pct_of_total for all jurisdictions  and groups, but only for the data period start dates after March 1, 2020.
---At first, we need previous week value to proceed, then by subtracting the previous week's value from the current week's value, dividing by the previous week's value, and multiplying by 100
With PreviousWeekValue as (
select jurisdiction_residence,Group_interval, data_period_start, covid_pct_of_total,
lag(covid_pct_of_total) over (partition by Jurisdiction_residence, Group_interval order by data_period_start) as Prev_CPT
from mortal_report
where data_period_start > '2020-03-01'
)
select jurisdiction_residence,Group_interval, data_period_start, covid_pct_of_total, Prev_cpt,
((covid_pct_of_total - prev_cpt)/prev_cpt)*100 as pct_chng_wk
from PreviousWeekValue
where COVID_pct_of_total is not null and prev_cpt is not null
order by 1,2,3

---6. Group the data by jurisdiction residence and calculate the cumulative COVID deaths for each  jurisdiction, but only up to the latest data period end date.
select Jurisdiction_Residence, sum(COVID_deaths) as Cumulative_covid_deaths
from mortal_report
where data_period_end = (select max(data_period_end) from mortal_report)
group by Jurisdiction_Residence



----Implementation of Function & Procedure-
/*Create a stored procedure that takes in a date  range and calculates the average weekly percentage change in COVID deaths for each  jurisdiction. 
The procedure should return the average weekly percentage change along with  the jurisdiction and date range as output. 
Additionally, create a user-defined function that  takes in a jurisdiction as input and returns the average crude COVID rate for that jurisdiction 
over the entire dataset. Use both the stored procedure and the user-defined function 
to compare the average weekly percentage change in COVID deaths for each jurisdiction to the average crude COVID rate for that jurisdiction.*/

create procedure AvgWeeklyPctChange (@start_date date, @end_date date)
as
begin
declare @WeeklyChng table (Jurisdiction_Residence Varchar(max), data_period_start date, COVID_deaths int,prev_COVID_deaths int)
insert into @WeeklyChng 
	select Jurisdiction_Residence, data_period_start, COVID_deaths,
	lag(COVID_deaths) over (partition by Jurisdiction_Residence order by data_period_start) as prev_COVID_deaths
	from mortal_report
	where data_period_start between @start_date and @end_date

	Select Jurisdiction_residence, avg(((COVID_deaths - prev_COVID_deaths) / prev_COVID_deaths) * 100) as avg_weekly_pct_change
	from @Weeklychng
	where prev_COVID_deaths is not null and COVID_deaths is not null
	group by Jurisdiction_Residence
End

exec dbo.AvgWeeklyPCtChange '2020-03-01','2024-03-01'


create function AvgCrudeCovidRate(@Jurisdiction_residence Varchar(max))
returns float
as begin
	declare @AvgRate as float
	select @AvgRate = Avg(crude_COVID_rate)
	from mortal_report
	where Jurisdiction_Residence = @Jurisdiction_residence
	and crude_COVID_rate is not null
	return @avgrate
End

Select dbo.AvgCrudeCovidRate('Florida')

Select * from mortal_report

