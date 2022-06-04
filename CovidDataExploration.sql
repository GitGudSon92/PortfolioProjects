--This was a guided project following Alex the Analyst's youtube video
SELECT *
    FROM PortfolioProjectCovid19..CovidDeaths
    WHERE continent is not NULL
    ORDER BY 3,4

--SELECT *
--FROM PortfolioProjectCovid19..CovidVaccinations
--ORDER BY 3,4

--Select Datat that we are going  to be using

SELECT [location], [date], total_cases, new_cases, total_deaths, population
    FROM PortfolioProjectCovid19..CovidDeaths
    ORDER BY 1,2

-- Looking at Total Cases vs Total Deaths
--Shows the likelihood of dying if you contract covid in your country
SELECT [location], [date], total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
    FROM PortfolioProjectCovid19..CovidDeaths
    WHERE [location] LIKE '%states%'
    ORDER BY 1,2

--Looking at total cases vs the population
--Shows what percentage of the population got Covid
SELECT [location], [date], total_cases, population, (total_cases/population) * 100 AS PercentOfPopulationInfected
    FROM PortfolioProjectCovid19..CovidDeaths
    --WHERE [location] LIKE '%states%'
    ORDER BY 1,2

-- Looking at countries with highest infection rate compared to population
SELECT [location], population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) * 100 AS PercentOfPopulationInfected
    FROM PortfolioProjectCovid19..CovidDeaths
    GROUP BY population, [location]
    ORDER BY PercentOfPopulationInfected DESC

--Showing Countries with the highest death count per population
SELECT [location], MAX(CAST(total_deaths AS int)) as TotalDeathCount
    FROM PortfolioProjectCovid19..CovidDeaths
    WHERE continent is not NULL
    GROUP BY [location]
    ORDER BY TotalDeathCount DESC

-- Breaking things down by continent
SELECT [location], MAX(CAST(total_deaths AS int)) as TotalDeathCount
    FROM PortfolioProjectCovid19..CovidDeaths
    WHERE continent is NULL
    GROUP BY [location]
    ORDER BY TotalDeathCount DESC

-- Showing the contintents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS int)) as TotalDeathCount
    FROM PortfolioProjectCovid19..CovidDeaths
    WHERE continent is NULL
    GROUP BY continent
    ORDER BY TotalDeathCount DESC

-- Global Numbers
SELECT DATE, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) as total_deaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 as DeathPercentage
FROM PortfolioProjectCovid19..CovidDeaths
WHERE continent is not NULL
GROUP BY [date]
ORDER BY 1,2

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) as total_deaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 as DeathPercentage
FROM PortfolioProjectCovid19..CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2

-- Loking at Total Population VS Vaccination 

SELECT 
    dea.continent, 
    dea.[location], 
    dea.[date], 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.[location] ORDER BY dea.location, dea.date) as rolling_vaccinations
FROM PortfolioProjectCovid19..CovidDeaths dea
JOIN PortfolioProjectCovid19..CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent is NOT NULL
ORDER BY 2,3

-- Use CTE this isn't correct investigate
WITH Pop_vs_Vac (continent, location, date, population, new_vaccinations, rolling_vaccinations)
AS 
(SELECT 
    dea.continent, 
    dea.[location], 
    dea.[date], 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations as bigint)) OVER (PARTITION BY dea.[location] ORDER BY dea.location, dea.date) as rolling_vaccinations
FROM PortfolioProjectCovid19..CovidDeaths dea
JOIN PortfolioProjectCovid19..CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent is NOT NULL
)

SELECT *, (rolling_vaccinations/population)*100
FROM Pop_vs_Vac

-- Temp Table

DROP TABLE IF exists #PercentPopulationVaccination
CREATE Table #PercentPopulationVaccination
(
    continent nvarchar(255),
    LOCATION NVARCHAR(255),
    DATE DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaaccinated NUMERIC
)
INSERT into #PercentPopulationVaccination
SELECT 
    dea.continent, 
    dea.[location], 
    dea.[date], 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.[location] ORDER BY dea.location, dea.date) as RollingPeopleVaaccinated
FROM PortfolioProjectCovid19..CovidDeaths dea
JOIN PortfolioProjectCovid19..CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent is NOT NULL

SELECT *, (RollingPeopleVaaccinated/population)*100
FROM #PercentPopulationVaccination

-- Creating View to store data for later visualizations
CREATE VIEW 
	PercentPopulationVaccination 
AS
SELECT 
    dea.continent, 
    dea.[location], 
    dea.[date], 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.[location] ORDER BY dea.location, dea.date) as RollingPeopleVaaccinated
FROM PortfolioProjectCovid19..CovidDeaths dea
JOIN PortfolioProjectCovid19..CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date]
WHERE dea.continent is NOT NULL

SELECT *
FROM PercentPopulationVaccination

