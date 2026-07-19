use [European Soccer Database];
go
select*from club_financials;
select*from league_metrics;
select *from player_market_values;
select*from record_transfers;
select *from transfers_history;

SELECT TOP 2* FROM transfers_history;
SELECT TOP 2* FROM club_financials;
SELECT TOP 2* FROM player_market_values;
SELECT TOP 2* FROM league_metrics;
SELECT TOP 2* FROM record_transfers;

SELECT *
FROM club_financials
WHERE revenue_eur_m IS NULL;

SELECT
COUNT(*) AS MissingRevenue
FROM club_financials
WHERE revenue_eur_m IS NULL;

select top 10 
club_name,
max(revenue_eur_m) as revenue
from club_financials
group by club_name
order by revenue desc;

select club_name,
sum(net_transfer_spend_eur_m) as spend
from club_financials
group by club_name
order by spend desc;

select 
AVG(market_value_eur_m)
from player_market_values;

select 
      player_name,
	  market_value_eur_m
from player_market_values
order by market_value_eur_m ;



WITH clubrevenue AS
(
SELECT
club_name,
SUM(revenue_eur_m) Revenue
FROM Club_Financials
GROUP BY club_name
)
SELECT *FROM clubrevenue;


select 
       year,
       club_name,
	   revenue_eur_m,
	   rank()over(order by revenue_eur_m desc) ranking
from club_financials;

SELECT
club_name,
COUNT(*)NumberOfTransfers 
FROM transfers_history t , club_financials c
where t.year =c.year
GROUP BY club_name
ORDER BY NumberOfTransfers DESC;


SELECT
        country,
		sum(revenue_eur_m) as total_revenue
from club_financials
group by country
order by total_revenue;

with revenue as
(
 select 
		club_name,
		sum(revenue_eur_m) as total_revenue
		from club_financials
		group by club_name
)
select top 5 * from revenue
order by total_revenue desc;


select 
		club_name
		revenue_eur_m,
		ROW_NUMBER()over(order by revenue_eur_m desc) rownum
		from club_financials;


select 
		player_name,
		market_value_eur_m,
		dense_rank ()over(order by market_value_eur_m desc) player_rank
		from player_market_values;


select
		club_name,
		year,
		revenue_eur_m,
		lag(revenue_eur_m) over(partition by club_name order by year desc) as PreviousRevenue
from club_financials;

select 
		club_name,
		year,
		revenue_eur_m,
		lead(revenue_eur_m) over(partition by club_name order by year desc) nextrevenye

from club_financials


select 
		club_name,
		year,
		revenue_eur_m,
		sum(revenue_eur_m) over(partition by club_name order by year desc) Running_total
from club_financials;


select

		club_name,
		year,
		revenue_eur_m,
		AVG(revenue_eur_m) over(partition by club_name order by year 
		rows between 2 preceding and current row) movingaverage
from club_financials;


create view vw_clubRevenue
as 
select
				club_name,
				revenue_eur_m,
				country
from club_financials;


select *from vw_clubRevenue;

create procedure sp_topRevenue
as
begin 

select top 10
			club_name,
			revenue_eur_m
			from club_financials
end;

exec sp_topRevenue


create table Dimdate
(

datekey int identity (1,1) primary key,
year int,
season varchar (30)
);

insert into Dimdate(year,season)
select distinct 
year,
season
from transfers_history

union 
select distinct 
year,
CAST(year as varchar(5))
from club_financials;

select* from Dimdate

create table Dim_club
(

club_key int identity (1,1) primary key,
club_name varchar (40),
league  varchar (40),
country varchar (30),
StadiumCapacity int
);

INSERT INTO Dim_club
(
club_name,League,Country,StadiumCapacity
)
SELECT DISTINCT
club_name,
league,
country,
stadium_capacity
FROM club_financials;


select*from Dim_club;


create table Dim_league
(
league_key int identity (1,1) primary key,
league_name varchar(30),
country varchar(30),
num_teams int
);

insert into Dim_league
select distinct 
		league,
		country,
		num_teams
		from league_metrics;

select * from Dim_league;


create table Dim_player
(
		playerkey int identity (1,1) primary key ,
		player_name varchar (50),
		position varchar(10),
		age int
		);


insert into Dim_player
select distinct
				player_name,
				position,
				age
from player_market_values;

select *from Dim_player;


CREATE TABLE FactClubFinancials
(
FactID INT IDENTITY PRIMARY KEY,

DateKey INT,

ClubKey INT,

Revenue DECIMAL(18,2),

WageBill DECIMAL(18,2),

NetTransferSpend DECIMAL(18,2),

OperatingProfit DECIMAL(18,2),

FOREIGN KEY(DateKey)
REFERENCES DimDate(DateKey),

FOREIGN KEY(ClubKey)
REFERENCES Dim_club (Club_Key)
);


INSERT INTO FactClubFinancials
(
DateKey,

ClubKey,

Revenue,

WageBill,

NetTransferSpend,

OperatingProfit
)

SELECT

d.DateKey,

c.club_key,

f.revenue_eur_m,

f.wage_bill_eur_m,

f.net_transfer_spend_eur_m,

f.operating_profit_eur_m

FROM club_financials f

JOIN DimDate d

ON f.year=d.Year

JOIN Dim_club c

ON f.club_name=c.club_name;

select *from FactClubFinancials;



CREATE TABLE FactTransfers
(
TransferKey INT IDENTITY PRIMARY KEY,

DateKey INT,

PlayerKey INT,

FromClubKey INT,

ToClubKey INT,

TransferFee DECIMAL(18,2),

FOREIGN KEY(DateKey)
REFERENCES DimDate(DateKey),

FOREIGN KEY(PlayerKey)
REFERENCES Dim_Player(PlayerKey),

FOREIGN KEY(FromClubKey)
REFERENCES Dim_Club(Club_Key),

FOREIGN KEY(ToClubKey)
REFERENCES Dim_Club(Club_Key)
);



INSERT INTO FactTransfers
(
DateKey,

PlayerKey,

FromClubKey,

ToClubKey,

TransferFee
)

SELECT

d.DateKey,

p.PlayerKey,

fc.club_key,

tc.club_key,

t.is_free_transfer

FROM transfers_history t

JOIN DimDate d

ON t.year=d.Year

JOIN Dim_player p

ON t.player_name=p.Player_Name

LEFT JOIN Dim_club fc

ON t.from_club=fc.Club_Name

LEFT JOIN Dim_Club tc

ON t.to_club=tc.Club_Name;


select*from FactTransfers

alter table facttransfers
add is_free_transfer int ;

insert into FactTransfers (is_free_transfer)
select is_free_transfer
from record_transfers ;

update FactTransfers
set is_free_tarnsfer
from record_transfers;

UPDATE FactTransfers
SET Is_Free_Transfer =
CASE
    WHEN TransferFee IS NULL OR TransferFee = 0 THEN 1
    ELSE 0
END;

SELECT
    COUNT(*) AS TotalRows,
    COUNT(TransferFee) AS RowsWithFee,
    SUM(CASE WHEN TransferFee IS NULL THEN 1 ELSE 0 END) AS NullFees
FROM FactTransfers;

CREATE VIEW vw_ClubFinancialPerformance
AS
SELECT
    d.Year,
    c.club_name,
    c.League,
    c.Country,
    f.Revenue,
    f.WageBill,
    f.NetTransferSpend,
    f.OperatingProfit
FROM FactClubFinancials f
JOIN Dim_club c
    ON f.ClubKey = c.club_key
JOIN DimDate d
    ON f.DateKey = d.DateKey;

	select *from vw_ClubFinancialPerformance



create view vw_revenueRanking
as
 
			select 
				year,
				club_name,
				league,
				revenue,
				rank() over(partition by year order by revenue desc) rankRevenue
				from vw_ClubFinancialPerformance;


select*from vw_revenueRanking


create view vw_OperatingProfit
as
		select 
		year,
		club_name,
		revenue,
		OperatingProfit,
		(OperatingProfit/revenue)*100 as profitmargin
		from vw_ClubFinancialPerformance;

select*from vw_OperatingProfit

CREATE VIEW vw_Transfers
AS
SELECT
    d.Year,
    p.player_name,
    fc.Club_Name AS FromClub,
    tc.club_name AS ToClub,
    t.TransferFee
FROM FactTransfers t
JOIN Dim_player p
ON t.PlayerKey=p.PlayerKey

LEFT JOIN Dim_Club fc
ON t.FromClubKey=fc.Club_Key

LEFT JOIN Dim_club tc
ON t.ToClubKey=tc.Club_Key

JOIN DimDate d
ON t.DateKey=d.DateKey;


select *from vw_Transfers


create view vw_toptransfers
as
		select top 100
		player_name,
		fromclub,
		toclub,
		TransferFee
		from vw_Transfers
		order by TransferFee desc;

		select*from vw_toptransfers



create view vw_playermarketvalue
as
				select 
				player_name,
				position,
				age,
				market_value_eur_m,
				dense_rank()over(order by market_value_eur_m desc) as rankvalue
				from player_market_values;



select*from vw_playermarketvalue



CREATE PROCEDURE sp_TopRevenueClubs
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 10
        Year,
        Club_Name,
        League,
        Revenue
    FROM vw_ClubFinancialPerformance
    ORDER BY Revenue DESC;
END;

CREATE PROCEDURE sp_TopTransfers
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 20
        Player_Name,
        FromClub,
        ToClub,
        TransferFee
    FROM vw_Transfers
    ORDER BY TransferFee DESC;
END;

EXEC sp_TopTransfers

CREATE PROCEDURE sp_TopProfitClubs
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 10
        Club_Name,
        Year,
        OperatingProfit
    FROM vw_ClubFinancialPerformance
    ORDER BY OperatingProfit DESC;
END;

exec sp_TopProfitClubs


CREATE PROCEDURE sp_WageAnalysis
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        Club_Name,
        Year,
        Revenue,
        WageBill,
        ROUND((WageBill / Revenue) * 100,2) AS WagePercentage
    FROM vw_ClubFinancialPerformance;
END;


exec sp_WageAnalysis


CREATE PROCEDURE sp_TopMarketValuePlayers
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP 20
        Player_Name,
        Position,
        Market_Value_EUR_M
    FROM vw_PlayerMarketValue
    ORDER BY Market_Value_EUR_M DESC;
END;

exec sp_TopMarketValuePlayers

SELECT
    Year,
    League,
    club_name,
    Revenue,
    RANK() OVER(
        PARTITION BY Year, League
        ORDER BY Revenue DESC
    ) AS RevenueRank
FROM vw_ClubFinancialPerformance;


select 
		club_name,
		year,
		revenue,
		lag(revenue) over (partition by club_name order by revenue desc) previousrevenue
		from vw_ClubFinancialPerformance;



SELECT
    club_name,
    Year,
    Revenue,
    LAG(Revenue) OVER(PARTITION BY Club_Name ORDER BY Year) PreviousRevenue,

    ROUND(
        (
            Revenue -
            LAG(Revenue) OVER(PARTITION BY Club_Name ORDER BY Year)
        )
        /
        NULLIF(
            LAG(Revenue) OVER(PARTITION BY Club_Name ORDER BY Year),
            0
        ) *100,2
    ) AS GrowthRate
FROM vw_ClubFinancialPerformance;



SELECT 
		club_name,
		year,
		revenue,
		sum(revenue) over (partition by club_name order by year ) as runningrevenue
		from vw_ClubFinancialPerformance;




SELECT

club_name,

Year,

Revenue,

AVG(Revenue)
OVER(
PARTITION BY Club_Name
ORDER BY Year
ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
) MovingAverage

FROM vw_ClubFinancialPerformance;




WITH AvgProfit AS
(
SELECT
AVG(OperatingProfit) AvgProfit
FROM vw_ClubFinancialPerformance
)

SELECT

club_name,

Year,

OperatingProfit

FROM vw_ClubFinancialPerformance

CROSS JOIN AvgProfit

WHERE OperatingProfit>AvgProfit;



select 
			club_name,
			revenue,
			case
			when revenue >= 500 then 'Elite'
			when revenue >= 300 then 'HIGH'
			when revenue >= 150 then 'MEDIUM'
			else 'LOW'
			end revenue_category
			from vw_ClubFinancialPerformance;











