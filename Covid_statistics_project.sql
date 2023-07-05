SELECT *
FROM covidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM covidProject..CovidVaccinations
--ORDER BY 3,4


-- Total Cases compared to Total Deaths (percentage)
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM covidProject..CovidDeaths
WHERE location like '%Romania%'
ORDER BY 1,2

--Total Cases compared to Population (percentage)
--What percentage of population contracted Covid at some point
SELECT location, date, total_cases, population, (total_cases/population)*100 as ContractedPercentage
FROM covidProject..CovidDeaths
--WHERE location like '%Romania%'
ORDER BY 1,2

--What countries have the highest infection rate compared to population
SELECT location, MAX(total_cases) as HighestInfectionCount, population, MAX(total_cases/population)*100 as InfectionRatePercentage
FROM covidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectionRatePercentage desc

--What countries have the highest number of deaths due to COVID-19 in relation to their population
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM covidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount desc

--What countries have the highest number of deaths due to COVID-19 in relation to their population by continent
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM covidProject..CovidDeaths
WHERE continent IS NULL 
AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY TotalDeathCount desc

-- Global numbers
--Grouped by date
SELECT date, SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases) as DeathPercentage
FROM covidProject..CovidDeaths
WHERE continent IS NOT NULL and new_cases <> 0
GROUP BY date
ORDER BY 1,2

--Total numbers
SELECT SUM(new_cases) as TotalCases, SUM(new_deaths) as TotalDeaths, SUM(new_deaths)/SUM(new_cases) as DeathPercentage
FROM covidProject..CovidDeaths
WHERE continent IS NOT NULL and new_cases <> 0
--GROUP BY date
ORDER BY 1,2

-- Total population in relation to Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM covidProject..CovidDeaths dea
JOIN covidProject..CovidVaccinations vac
	ON dea.location = vac.location 
	and  dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--USE CTE

With PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
AS(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM covidProject..CovidDeaths dea
JOIN covidProject..CovidVaccinations vac
	ON dea.location = vac.location 
	and  dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated/Population)*100 as VaccinatedPercentage
FROM PopvsVac
ORDER BY 2,3



--TEMP TABLE
--DROP TABLE IF EXISTS #PercentagePopulationVaccinated -> for newer versions
IF OBJECT_ID('tempdb..#PercentagePopulationVaccinated') IS NOT NULL
    DROP TABLE #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(
	Continent nvarchar(255), 
	Location nvarchar(255), 
	Date datetime, 
	Population numeric, 
	New_vaccinations numeric, 
	RollingPeopleVaccinated numeric
)


INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM covidProject..CovidDeaths dea
JOIN covidProject..CovidVaccinations vac
	ON dea.location = vac.location 
	and  dea.date = vac.date
WHERE dea.continent is not null


SELECT *, (RollingPeopleVaccinated/Population)*100 as VaccinatedPercentage
FROM #PercentagePopulationVaccinated
ORDER BY 2,3

--Create view to store date for later visualization
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM covidProject..CovidDeaths dea
JOIN covidProject..CovidVaccinations vac
	ON dea.location = vac.location 
	and  dea.date = vac.date
WHERE dea.continent is not null