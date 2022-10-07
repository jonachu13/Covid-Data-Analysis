
-- Viewing all the columns of the two databases
SELECT * 
FROM dbo.CovidDeaths$;

SELECT *
FROM Jonabase.dbo.CovidVaccinations$;

-- It works! Analysis begin...
SELECT location,date,total_cases,new_cases,total_deaths,population 
FROM Jonabase.dbo.CovidDeaths$
WHERE continent is not null -- must include to remove uncleaned data
ORDER BY 1,2;

-- Total Case vs Total Deaths + DeathPercentage
SELECT location,date,total_cases,total_deaths,population, (total_deaths/total_cases)*100 as DeathPercentage
FROM Jonabase.dbo.CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2;

-- total cases vs population + % of pop that got covid
SELECT location,date,total_cases,total_deaths,population, (total_cases/population)*100 as PopPercent
FROM Jonabase.dbo.CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2;

-- what country has the highest infection rate? 
SELECT location,population,MAX(total_cases) as HighestInfectionCount,Max((total_cases/population))*100 as MaxPopPercent
FROM Jonabase.dbo.CovidDeaths$
GROUP BY location,population
ORDER BY 4 DESC;

-- Showing countries with the highest death count
SELECT location, MAX(cast(total_deaths as int))as totaldeathcount
FROM Jonabase.dbo.CovidDeaths$
WHERE continent is not null --gotta do this to make sure it's continent only. 
GROUP BY location
ORDER BY totaldeathcount DESC;

-- How are we doing here on earth? here's some global numbers
SELECT date, sum(new_cases) as totalcases,SUM(CAST(new_deaths as int))as totaldeaths,SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM Jonabase.dbo.CovidDeaths$
WHERE continent is not null
GROUP BY date
ORDER BY 1,2;

-- back to vaccination table...by join
SELECT * 
FROM Jonabase.dbo.CovidDeaths$ dea
JOIN Jonabase.dbo.CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date;

-- Total population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, vac.new_vaccinations
FROM Jonabase.dbo.CovidDeaths$ dea
JOIN Jonabase.dbo.CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- Rolling count of people vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint,vac.new_vaccinations))OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVacc
FROM Jonabase.dbo.CovidDeaths$ dea
JOIN Jonabase.dbo.CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--Using a CTE to pull percent vaccinated in addition to a window statement to segment aggreagations by location
WITH popvsvac (continent,location,date,population,new_vaccinations,RollingPeopleVacc)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint,vac.new_vaccinations))OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVacc
FROM Jonabase.dbo.CovidDeaths$ dea
JOIN Jonabase.dbo.CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVacc/population)*100 as percentvaccinated
FROM popvsvac

-- Finished finding what I was looking for, so I'll save this vew for future use!
CREATE VIEW vaccinationview as --the rest is copy and pasted from the query above
WITH popvsvac (continent,location,date,population,new_vaccinations,RollingPeopleVacc)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(bigint,vac.new_vaccinations))OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVacc
FROM Jonabase.dbo.CovidDeaths$ dea
JOIN Jonabase.dbo.CovidVaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVacc/population)*100 as percentvaccinated
FROM popvsvac

-- now I could pull this whenever I want simply with:
SELECT *
from vaccinationview;


