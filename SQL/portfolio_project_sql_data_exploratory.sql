--SELECT location, date, total_cases, new_cases, total_deaths, population
--FROM portfolio_project..CovidDeaths
--ORDER BY 1,2

-- Looking at total cases vs. total deaths in Vietnam
-- Demonstrate the chance of dying if you get infected in Vietnam
SELECT 
	location, date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases)*100 AS death_rate
FROM 
	portfolio_project..CovidDeaths
WHERE 
	location = 'Vietnam'
ORDER BY 1,2;

-- Let's look at the total cases vs. population and infection rate
SELECT location, date, population, total_cases, (total_cases/population)*100 AS infection_rate
FROM portfolio_project..CovidDeaths
WHERE location = 'Vietnam'
ORDER BY 1,2;

-- Demonstrating the highest infection rate in each country
SELECT 
	location, 
	population AS population, 
	max(total_cases) AS highest_total_cases, 
	max((total_cases/population))*100 AS highest_infection_rate
FROM portfolio_project..CovidDeaths
GROUP BY location, population
ORDER BY highest_infection_rate DESC;

-- Latest total_cases vs. total_deaths in each continent. By the time this project is going on, the dataset contains data upto 12-Jan-2022.
SELECT
	location AS continent,
	total_cases,
	CAST(total_deaths as float) AS total_deaths
FROM 
	portfolio_project..CovidDeaths
WHERE
	location IN ('Europe','North America', 'South America', 'Asia', 'Africa', 'Oceania', 'World', 'International', 'European Union')
	AND date = '2022-01-12'
ORDER BY total_deaths DESC;

-- Latest total_cases vs. total_deaths in different class. 

SELECT
	location AS classes,
	total_cases,
	CAST(total_deaths as float) AS total_deaths
FROM 
	portfolio_project..CovidDeaths
WHERE
	continent IS NULL
	AND location NOT IN ('Europe','North America', 'South America', 'Asia', 'Africa', 'Oceania', 'World', 'International', 'European Union')
	AND date = '2022-01-12'
ORDER BY total_deaths DESC;


-- Looking at new vaccinations vs. population per day in Vietnam
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations, vac.total_vaccinations
	   ,SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vac_per_day
	   ,vac.people_vaccinated
	   ,vac.people_fully_vaccinated
FROM portfolio_project..CovidDeaths as dea
JOIN portfolio_project..CovidVac as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.location = 'Vietnam'
ORDER BY 1, 2;
-- The sum function was used to add up new vacs everyday to calculate the total vaccinations column. The reason why the total_vaccinations
-- and the total_vac_per_day were different is because the new_vaccinations column was missing some data. If the total_vaccinations was not 
-- recorded, this would be a good way to calculate the total_vac.

-- USE CTE
WITH pops_vs_vac (location, date, population, new_vaccinations, total_vac_per_day, people_vaccinated, people_fully_vaccinated) 
AS
(
SELECT dea.location, dea.date, dea.population, vac.new_vaccinations
	   ,SUM(CONVERT(float, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vac_per_day
	   ,vac.people_vaccinated
	   ,vac.people_fully_vaccinated
FROM portfolio_project..CovidDeaths as dea
JOIN portfolio_project..CovidVac as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.location = 'Vietnam'
)
SELECT *, (people_vaccinated/population)*100 AS vac_rate
FROM pops_vs_vac


-- TEMP TABLE
DROP TABLE IF EXISTS #percent_pop_vaccinated 
CREATE TABLE #percent_pop_vaccinated
(
location nvarchar(255)
,date datetime
,population numeric
,new_vaccinations numeric
,total_vac_per_day numeric
,people_vaccinated numeric
, people_fully_vaccinated numeric
)
INSERT INTO #percent_pop_vaccinated
SELECT dea.location, dea.date, dea.population, CONVERT(bigint, vac.new_vaccinations) AS new_vaccinations
	   , SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vac_per_day
	   , CONVERT(bigint,vac.people_vaccinated) AS people_vaccinated
	   , CONVERT(bigint,vac.people_fully_vaccinated) AS people_fully_vaccinated
FROM portfolio_project..CovidDeaths as dea
JOIN portfolio_project..CovidVac as vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *, (people_vaccinated/population)*100 AS vac_rate
FROM #percent_pop_vaccinated
WHERE location = 'Vietnam'
ORDER BY location, date;

-- Creating View to store data for visualizations
CREATE VIEW vaccinations_vs_pops AS
SELECT dea.location, dea.date, dea.population, CONVERT(bigint, vac.new_vaccinations) AS new_vaccinations
	   , SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS total_vac_per_day
	   , CONVERT(bigint,vac.people_vaccinated) AS people_vaccinated
	   , CONVERT(bigint,vac.people_fully_vaccinated) AS people_fully_vaccinated
FROM portfolio_project..CovidDeaths as dea
JOIN portfolio_project..CovidVac as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL