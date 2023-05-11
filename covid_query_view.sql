-- Create view for future data visualisation

-- Total Population vs Vaccinations (per day)
CREATE VIEW PopulationVaccinated
AS (
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CAST(v.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingVaccinatedPeople
FROM portfolioproject.coviddeaths d
JOIN portfolioproject.covidvaccinations v
	ON d.location = v.location
	AND d.date = v.date
WHERE d.continent IS NOT NULL AND d.continent != ""
ORDER BY d.location, d.date
);


-- Global counts of infected (per day)
CREATE VIEW GlobalCasesPercentage
AS (
SELECT location, date, population, total_cases, (total_cases/population)*100 AS "Cases Percentage" 
FROM portfolioproject.coviddeaths
WHERE continent IS NOT NULL AND continent != ""
GROUP BY date
ORDER BY date
);

-- Global counts of death (per day)
CREATE VIEW GlobalDeathPercentage
AS (
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS "Death Percentage" 
FROM portfolioproject.coviddeaths
WHERE continent IS NOT NULL AND continent != ""
GROUP BY date
ORDER BY date
);



