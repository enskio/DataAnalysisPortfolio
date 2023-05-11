-- Select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM portfolioproject.coviddeaths
ORDER BY 1, 2;

-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if infected by Covid
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS "Death Percentage" 
FROM portfolioproject.coviddeaths
-- WHERE location like '%states%'
ORDER BY 1, 2;

-- Looking at the Total Cases vs Population
SELECT location, date, population, total_cases, (total_cases/population)*100 AS "Cases Percentage" 
FROM portfolioproject.coviddeaths
-- WHERE location like '%states%'
ORDER BY 1, 2;

-- Find out which country has the highest infection rate (total_cases/population)
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS InfectionPercentageInCountries
FROM portfolioproject.coviddeaths
GROUP BY location, population
ORDER BY CasesPercentageInCountries DESC;

-- Find out which country has the highest death rate (total_deaths/population)
SELECT location, population, MAX(CAST(total_deaths AS UNSIGNED)) AS HighestDeathCount, (MAX(total_deaths)/population)*100 AS DeathPercentageInCountries
FROM portfolioproject.coviddeaths
GROUP BY location, population
ORDER BY DeathPercentageInCountries DESC;

-- Shows continent's death count
SELECT continent, MAX(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCountContinent
FROM portfolioproject.coviddeaths
WHERE continent IS NOT NULL AND continent != ""
GROUP BY continent
ORDER BY TotalDeathCountContinent DESC;

-- Shows country's death count
SELECT location, SUM(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM portfolioproject.coviddeaths
WHERE continent IS NOT NULL AND continent != ""
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Global counts of infected and death per day
SELECT date, SUM(CAST(total_cases AS UNSIGNED)) AS TotalInfectedCount, SUM(CAST(total_deaths AS UNSIGNED)) AS TotalDeathCount, SUM(CAST(total_deaths AS UNSIGNED))/(SUM(CAST(total_cases AS UNSIGNED)))*100 AS DeathPercentage
FROM portfolioproject.coviddeaths
WHERE continent IS NOT NULL AND continent != ""
GROUP BY date
ORDER BY date;

-- Join CovidDeaths and CovidVaccinations table together
SELECT *
FROM portfolioproject.coviddeaths d
JOIN portfolioproject.covidvaccinations c
	ON d.location = c.location
	AND d.date = c.date;


-- Total Population vs Vaccinations (per day)
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingCountVaccinatedPeople
FROM portfolioproject.coviddeaths d
JOIN portfolioproject.covidvaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.continent != ""
ORDER BY d.location, d.date;


-- Use CTE to calculate percentage of people getting vaccinated per day
WITH PopVsVac (continent, location, date, population, new_vaccination, RollingVaccinatedPeople)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingVaccinatedPeople
FROM portfolioproject.coviddeaths d
JOIN portfolioproject.covidvaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.continent != ""
-- ORDER BY d.location, d.date
)
SELECT * , (RollingVaccinatedPeople/population)*100 AS RollingVaccinatedPeoplePercentage
FROM PopVsVac
ORDER BY location, date;



-- Use temp table to calculate percentage of people getting vaccinated per day with rolling vaccinated people number
CREATE TEMPORARY TABLE IF NOT EXISTS PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population int,
new_vaccinations int,
RollingVaccinatedPeople float
)
IGNORE AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingVaccinatedPeople
FROM portfolioproject.coviddeaths d
JOIN portfolioproject.covidvaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.continent != ""
-- ORDER BY d.location, d.date
);
SELECT *, (RollingVaccinatedPeople/population)*100 AS RollingVaccinatedPeoplePercentage
FROM PercentPopulationVaccinated
ORDER BY location, date;
