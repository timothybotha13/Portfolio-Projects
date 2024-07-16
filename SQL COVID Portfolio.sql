--FROM PortfolioProject..CovidDeaths

--FROM PortfolioProject..CovidVaccinations


-- Select Data that we are going to be using

SELECT continent, Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
AND date = '2020-01-05 00:00:00.000'
ORDER BY 2,3


-- BY COUNTRY

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your country
SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths)/CONVERT(float, total_cases)*100) AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'United Kingdom'
AND continent IS NOT NULL
ORDER BY 1,2


-- Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
SELECT location, date, population, total_cases, (CONVERT(float, total_cases)/population*100) AS percent_infected
FROM PortfolioProject..CovidDeaths
WHERE location = 'United Kingdom'
AND continent IS NOT NULL
ORDER BY 1,2


-- Looking at Countries with highest Infection Rate compared to Population
SELECT location, population, MAX(CAST(total_cases AS int)) AS highest_infection_count, MAX(CONVERT(float, total_cases)/population)*100 AS highest_percent_infected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


-- Looking at Countries with highest Death Count per Poplution
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC


-- BY CONTINENT
-- Looking at continents with the highest death count per population

-- Using aggregate numbers provided in raw data
SELECT location, MAX(CAST(total_deaths AS int)) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
AND location NOT LIKE '%income' 
AND location NOT LIKE '%Union'
GROUP BY location
ORDER BY 2 DESC

-- Using aggregate functions, if raw data doesn't contain aggregate numbers
SELECT continent, SUM((CAST(new_deaths AS bigint))) AS total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC

-- Looking at continencts with highest Infection Rate compared to Population
SELECT continent, MAX(CAST(total_cases AS int)) AS highest_infection_count, MAX(CONVERT(float, total_cases)/population)*100 AS highest_percent_infected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 3 DESC



-- GLOBAL NUMBERS


-- Looking at global Cases vs Deaths
SELECT date, SUM(CAST(total_cases AS int)) AS global_total_cases, SUM(CAST(total_deaths AS int)) AS global_total_deaths, 
ROUND(SUM(CONVERT(float, total_deaths))/SUM(CONVERT(float, total_cases))*100, 3) AS global_death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1



-- Looking at Total Population vs Vaccinations


-- USE CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_total_vaccinations)
AS (
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CAST(cv.new_vaccinations AS bigint)) OVER (PARTITION BY cd.location ORDER BY cd.location,cd.date) AS rolling_total_vaccinations
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
)

SELECT *, ROUND((rolling_total_vaccinations/population)*100, 4) AS percent_vaccinated
FROM PopvsVac
ORDER BY 2, 3


-- USE TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_total_vaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CAST(cv.new_vaccinations AS bigint)) OVER (PARTITION BY cd.location ORDER BY cd.location,cd.date) AS rolling_total_vaccinations
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL

SELECT *, ROUND((rolling_total_vaccinations/population)*100, 4) AS percent_vaccinated
FROM #PercentPopulationVaccinated
ORDER BY 2, 3



-- Creating views to store data for later visualisations

CREATE VIEW PopvsVac AS
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, SUM(CAST(cv.new_vaccinations AS bigint)) OVER (PARTITION BY cd.location ORDER BY cd.location,cd.date) AS rolling_total_vaccinations
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccinations cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
