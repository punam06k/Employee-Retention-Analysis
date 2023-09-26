create database hr_analytics;

use hr_analytics;


create table if not exists hr_2(
EmployeeID int not null unique,
MonthlyIncome int not null,
MonthlyRate int not null,
NumCompaniesWorked int not null,
Over18 varchar(5) not null,
OverTime varchar(5) not null,
PercentSalaryHike int not null,
PerformanceRating int not null,
RelationshipSatisfaction int not null,
StandardHours int not null,
StockOptionLevel int not null,
TotalWorkingYears int not null,
TrainingTimesLastYear int not null,
WorkLifeBalance int not null,
YearsAtCompany int not null,
YearsInCurrentRole int not null,
YearsSinceLastPromotion int not null,
YearsWithCurrManager int not null,
primary key (EmployeeID)
);

set session sql_mode = '';

load data infile
'C:/HR_2.csv'
into table hr_2
CHARACTER SET latin1
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

select * from hr_2;

create table if not exists hr_1( 
Age int not null,
Attrition varchar(5),
BusinessTravel varchar(25),
DailyRate int not null,
Department varchar(25),
DistanceFromHome int not null,
Education int not null,
EducationField varchar(25),
EmployeeCount int not null,
EmployeeNumber int not null,
EnvironmentSatisfaction int not null,
Gender varchar(10),
HourlyRate int not null,
JobInvolvement int not null,
JobLevel int not null,
JobRole varchar(25),
JobSatisfaction int not null,
MaritalStatus varchar(10),
primary key (EmployeeNumber),
foreign key (EmployeeNumber) references  hr_2(EmployeeID)  
);

load data infile
'C:/HR_1.csv'
into table hr_1
CHARACTER SET latin1
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

select * from hr_1;

create view hr_data as select * from hr_2 left join hr_1 on hr_2.EmployeeID = hr_1.EmployeeNumber;
select * from hr_data;

-- 1)Average Attrition rate for all Departments.
alter table hr_1
add column `Attrition_Count` int NOT NULL;

update hr_1 set `Attrition_Count`= case
when Attrition = "Yes" then 1
when Attrition = "No" then 0
end; 

select * from hr_1;

select Department,
round(avg(Attrition_Count)*100,2) as "Average Attrition Rate"
from hr_1 
group by Department;

-- 2)Average Hourly rate of Male Research Scientist
select JobRole, Gender, avg(HourlyRate) from hr_1 
where JobRole = "Research Scientist" and Gender = "Male";

-- 3)Attrition rate Vs Monthly income stats.
alter table hr_2
add column `MonthlyIncomeBucket` varchar(50) not null;

update hr_2
set  `MonthlyIncomeBucket` = 
case when MonthlyIncome < 5000 then "0-4999"
     when MonthlyIncome >= 5000 and MonthlyIncome < 10000 then "5000-9999"
     when MonthlyIncome >= 10000 and MonthlyIncome < 15000 then "10000-14999"
	 when MonthlyIncome >= 15000 and MonthlyIncome < 20000 then "15000-19999"
	 when MonthlyIncome >= 20000 and MonthlyIncome < 25000 then "20000-24999"
	 when MonthlyIncome >= 25000 and MonthlyIncome < 30000 then "25000-29999"
	 when MonthlyIncome >= 30000 and MonthlyIncome < 35000 then "30000-34999"
	 when MonthlyIncome >= 35000 and MonthlyIncome < 40000 then "35000-39999"
	 when MonthlyIncome >= 40000 and MonthlyIncome < 45000 then "40000-44999"
     when MonthlyIncome >= 45000 then "50000 plus"
     end ;
     
select * from hr_2;

select b.MonthlyIncomeBucket, 
concat(format(avg(a.attrition_rate)*100,2),'%') as Average_attrition,
format(avg(b.monthlyincome),2) as Average_Monthly_Income
from ( select Department,Attrition,EmployeeNumber,
case when Attrition = 'yes' then 1
else 0
end as attrition_rate from hr_1) as a
inner join hr_2 as b on b.EmployeeId = a.EmployeeNumber
group by b.MonthlyIncomeBucket
order by b.MonthlyIncomeBucket asc;


-- 4)Average working years for each Department
select hr_1.Department, 
avg(hr_2.TotalWorkingYears) 
as "Average Working Years" 
from hr_1, hr_2 
where hr_2.EmployeeID = hr_1.EmployeeNumber 
group by hr_1.Department;

-- 5)Job Role Vs Work life balance

select JobRole,
sum(case when WorkLifeBalance = '1' then 1 else 0 end)as Poor,
sum(case when WorkLifeBalance = '2' then 1 else 0 end)as Good,
sum(case when WorkLifeBalance = '3' then 1 else 0 end)as  Good,
sum(case when WorkLifeBalance = '4' then 1 else 0 end)as Excellent
from hr_data
group by JobRole
order by JobRole;


-- 6)Attrition rate Vs Year since last promotion relation.

alter table hr_2
add column `YearSinceLastPromotionBucket` varchar(50) not null;

update hr_2 set YearSinceLastPromotionBucket = 
case when YearsSinceLastPromotion <= 5 then  "0-5"
	 when YearsSinceLastPromotion <= 10 then "6-10"
	 when YearsSinceLastPromotion <= 15 then "11-15"
	 when YearsSinceLastPromotion <= 20 then "16-20"
	 when YearsSinceLastPromotion <= 25 then "21-25"
	 when YearsSinceLastPromotion <= 30 then "26-30"
	 when YearsSinceLastPromotion <= 35 then "31-35"
     when YearsSinceLastPromotion > 35 then "35 above"
     end;
     
select * from hr_2;

select hr_2.YearSinceLastPromotionBucket,
concat(round(count(case when hr_1.Attrition='Yes' then "" end)/count(hr_1.EmployeeNumber)*100,2),"%")
as "Average Attrition Rate" from  hr_1, hr_2 
where hr_2.EmployeeID = hr_1.EmployeeNumber 
group by YearSinceLastPromotionBucket 
order by YearSinceLastPromotionBucket;


-- New KPI
/*1)Write an query to find the details of employee under attrition having 
5+ years of experience in between age group 27-35*/
select * from hr_data
where Age between 27 and 35
and TotalWorkingYears >= 5;

/*2)Fetch the details of employees having maximum and minimum salary 
working in different departments who received less than 13% salary hike.*/
select Department,
       PercentSalaryHike,
	   max(MonthlyIncome), 
       min(MonthlyIncome) 
from hr_data
where PercentSalaryHike < 13
group by Department;

/*3)Calculate average monthly income of all employees 
who worked more than 3 years whose education background is medical.*/
select avg(MonthlyIncome) from hr_data
where YearsAtCompany = 3 and EducationField = "Medical";


#4) Employees with max performance rating but promotion for 4 years and above.
select * from hr_2
where PerformanceRating = (select max(PerformanceRating) from hr_2)
and YearsSinceLastPromotion >= 4;

#5) who has max & min percentage salary hike
select YearsAtCompany, PercentSalaryHike, YearsSinceLastPromotion,
       max(PercentSalaryHike),
       min(PercentSalaryHike)
       from hr_2 
group by YearsAtCompany, PercentSalaryHike, YearsSinceLastPromotion
order by max(PercentSalaryHike) desc, min(PercentSalaryHike) asc;

#6)Employees working overtime but given min salary hike and are less than 5 yrs with company
select * from hr_data
where OverTime = "Yes" and PercentSalaryHike = (select max(PercentSalaryHike) from hr_2)
and YearsAtCompany < 5
and Attrition = "Yes";


  