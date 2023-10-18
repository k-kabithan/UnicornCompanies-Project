SELECT *
FROM UnicornCompanies..Unicorn_Data

-- Edit Country name from China to Hong kong, and fill null
SELECT *
FROM UnicornCompanies..Unicorn_Data
WHERE Country like '%kong%'
ORDER BY Country asc;

UPDATE UnicornCompanies..Unicorn_Data
SET City = 'Hong Kong'
WHERE City is Null AND Country = 'Hong Kong'

UPDATE UnicornCompanies..Unicorn_Data
SET Country = 'China'
WHERE Country = 'Hong Kong';

SELECT *
FROM UnicornCompanies..Unicorn_Data

SELECT City, Country
FROM UnicornCompanies..Unicorn_Data
ORDER BY City asc;

UPDATE UnicornCompanies..Unicorn_Data
SET City = 'Nassau'
WHERE Country = 'Bahamas';

DELETE FROM UnicornCompanies..Unicorn_Data
WHERE Company is null and Valuation is null and Industry is Null

SELECT *
FROM UnicornCompanies..Unicorn_Data
-----------------------------------------------------------------
-- Create new columns for Valuation and Funding to have integers. Also convert Year_Founded to dates using temporary table
SELECT *
FROM UnicornCompanies..Unicorn_Data


ALTER TABLE UnicornCompanies..Unicorn_Data
ADD Valuation_new BIGINT;

ALTER TABLE UnicornCompanies..Unicorn_Data
ADD Funding_new BIGINT;

SELECT *
FROM UnicornCompanies..Unicorn_Data
ORDER BY Funding asc;

UPDATE UnicornCompanies..Unicorn_Data
SET Valuation_new = CAST(REPLACE(REPLACE(Valuation, '$', ''), 'B', '') AS BIGINT) * 1000000000
WHERE Valuation LIKE '$%B';

UPDATE UnicornCompanies..Unicorn_Data
SET Funding_new = CAST(REPLACE(REPLACE(Funding, '$', ''), 'B', '') AS BIGINT) * 1000000000
WHERE Funding LIKE '$%B';

UPDATE UnicornCompanies..Unicorn_Data
SET Funding_new = CAST(REPLACE(REPLACE(Funding, '$', ''), 'M', '') AS BIGINT) * 1000000
WHERE Funding LIKE '$%M';

UPDATE UnicornCompanies..Unicorn_Data
SET Funding = Null
WHERE Funding = 'Unknown';

SELECT *
FROM UnicornCompanies..Unicorn_Data
ORDER BY Funding asc;

SELECT Select_Investors
FROM UnicornCompanies..Unicorn_Data

SELECT *
FROM UnicornCompanies..Unicorn_Data
ORDER BY Company asc

ALTER TABLE Unicorn_Data
ADD Date_Founded datetime;

UPDATE Unicorn_Data
SET Unicorn_Data.Date_Founded = DateFoundedUnicorn.Date_Founded
FROM Unicorn_Data
INNER JOIN DateFoundedUnicorn ON Unicorn_Data.Company = DateFoundedUnicorn.Company;
-----------------------------------------------------------------------------------------
-- Attempt to create separate tables for investors and creating a junction table to link both companies and investors.
/* CREATE TABLE UnicornCompanies..Investors (
	Investor_ID INT IDENTITY(1,1) PRIMARY KEY,
	Investor_Name NVARCHAR (255) NOT NULL
);

CREATE TABLE UnicornCompanies..Company_Investor (
    Company_ID INT NOT NULL,
    Investor_ID INT NOT NULL,
    PRIMARY KEY (Company_ID, Investor_ID),
    FOREIGN KEY (Company_ID) REFERENCES Unicorn_Data(Company_ID),
    FOREIGN KEY (Investor_ID) REFERENCES Investors(Investor_ID)
);


INSERT INTO UnicornCompanies..Investors (Investor_Name)
SELECT DISTINCT LTRIM(RTRIM(value))
FROM UnicornCompanies..Unicorn_Data
CROSS APPLY string_split(Select_Investors, ',')
WHERE LTRIM(RTRIM(value)) <> ''


INSERT INTO Company_Investor (Company_ID, Investor_ID)
SELECT Unicorn_Data.Company_ID, Investors.Investor_ID
FROM Unicorn_Data
CROSS APPLY string_split(Select_Investors, ',')
INNER JOIN Investors ON LTRIM(RTRIM(value)) = Investors.Investor_Name 
*/

--------------------------------------------------------------------------------------------------
-- Using XML column to separate each investor to use in queries in main table.

USE UnicornCompanies
SELECT *
FROM Unicorn_Data

ALTER TABLE Unicorn_Data
ADD Investors xml;

UPDATE Unicorn_Data
SET Investors = (
	SELECT (
		SELECT DISTINCT LTRIM(RTRIM(value)) AS Investor_Name
		FROM string_split(Select_Investors, ',')
		FOR XML PATH(''), TYPE
	)
);


-- Find the investors that invested in a specific Company/Company_ID
SELECT Company, Company_ID, Investor_Name.value('.', 'nvarchar(max)') AS Investor_Name
FROM Unicorn_Data
CROSS APPLY Investors.nodes('/Investor_Name') AS Investors(Investor_Name)
WHERE Company_ID = 6;


-- Find the number of companies a specific investor invested in
SELECT Company_ID, Company, Select_Investors
FROM Unicorn_Data
WHERE Investors.exist('/Investor_Name[text()="Canaan Partners"]') = 1;


--- Figure out how long it took for each company to reach a valuation of $1B.

ALTER TABLE Unicorn_Data
ADD Days_Taken AS DATEDIFF(day, Date_Founded, Date_Joined);

SELECT Company, Date_Joined, Date_Founded, Days_Taken
FROM Unicorn_Data
ORDER BY Days_Taken DESC;

SELECT AVG(Days_Taken) as Avg_Days_Taken
FROM (
  SELECT DATEDIFF(day, Date_Founded, Date_Joined) as Days_Taken
  FROM Unicorn_Data
  WHERE Company_ID <> 715 --Yidian has negative days taken, so exclude
) as subquery


-- Notice that the company "Yidian Zixun" has a negative Days_Taken value.
-- Which makes no sense in terms of when it was founded to when it became a unicorn company

-----------------------------------------------------------------------------------------
--- Visual 1 - Distribution of companies by industry, size proportional to valuation

SELECT Company, Industry, Valuation_new
FROM UnicornCompanies..Unicorn_Data
ORDER BY Industry asc;

-----------------------------------------------------------------------------------------
--- Visual 2 - Locations of all companies, with filters (continent, country, city)

SELECT Company, Continent, Country, City
FROM UnicornCompanies..Unicorn_Data
ORDER BY Continent asc;

-----------------------------------------------------------------------------------------
--- Visual 3 - Relationship between company valuations and total funding, colour of dot referencing industry
-- Valuation of a company based on a specific range of funding they had

SELECT Company, Industry, Valuation_new, Funding_new 
FROM UnicornCompanies..Unicorn_Data
ORDER BY Funding_new asc;

-----------------------------------------------------------------------------------------
--- Visual 4 - Top 10 unicorn companies by valuation

SELECT Company, Valuation_new
FROM UnicornCompanies..Unicorn_Data
ORDER BY Valuation_new desc;


SELECT *
FROM UnicornCompanies..Unicorn_Data
ORDER BY Industry desc;

-----------------------------------------------------------------------------------------
--- Visual 5 - Number of companies each investor invested in, in descending order

SELECT InvestorName, COUNT(*) AS Invested_Companies
FROM (
    SELECT DISTINCT a.Company, b.c.value('.', 'nvarchar(max)') AS InvestorName
    FROM Unicorn_Data a
    CROSS APPLY a.Investors.nodes('/Investor_Name') b(c)
) AS Investors
WHERE InvestorName != ''
GROUP BY InvestorName
ORDER BY Invested_Companies desc;

----------------------------------------------------------------------------------------
--- Potential Visualisations

SELECT Country, COUNT(*) AS Num_Unicorns
FROM Unicorn_Data
GROUP BY Country
ORDER BY Num_Unicorns DESC;
