/*
Covid 19 Data Exploration [Updated March 2022]
Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Converting Data Types, Creating Views
*/

select *
from dbo.coviddeaths
where continent is not null 
order by 3,4

--select *
--from dbo.covidvaccinations
--order by 3,4

--Selecting relevant data that we will begin exploring

Select location, date, total_cases, new_cases, new_deaths, population
from dbo.coviddeaths
order by 1,2

--looking at total cases vs total deaths
--This shows likelihood of dying if you contract covid (in the UK)

Select location, date, total_cases, new_deaths, (total_deaths/total_cases *100) as DeathPercentage
from dbo.coviddeaths
where location = 'United Kingdom'
order by 1,2

--Looking at total cases vs population
--shows what percentage of population got covid (in the UK)
Select location, date, total_cases, population, (total_cases/population *100) as covidcaughtpercentage
from dbo.coviddeaths
where location = 'United Kingdom'
order by 1,2

--Looking at countries with highest infection rate versus population 

Select Location, Population, max(total_cases) as HighestInfectionCount, max((total_cases/population *100)) as PercentPopulationInfected
from dbo.coviddeaths
--where location = 'United Kingdom'
group by population, location 
order by PercentPopulationInfected desc


--showing the countries with highest death count per population
--converting total_death value to an integer datatype.
--We could also use CONVERT(int,total_deaths)

Select Location, Population, max(cast(total_deaths as int)) as totaldeathcount
from dbo.coviddeaths
--where location = 'United Kingdom'
where continent is not null
group by population, location 
order by totaldeathcount desc

--grouping by continent
--showing the continents with the highest death count per population

Select location, max(cast(total_deaths as int)) as totaldeathcount
from dbo.coviddeaths
--where location = 'United Kingdom'
where continent is null
group by location
order by totaldeathcount desc

--global numbers comparing total cases, total deaths and percentage of deaths from total cases

Select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths,
sum(cast(new_deaths as int))/sum(new_cases)*100 as deathpercentage
from dbo.coviddeaths
--where location = 'United Kingdom'
where continent is not null
order by 1,2

--Joining covid deaths and covid vaccination tables together
select *
from coviddeaths de
join covidvaccinations va
on de.location = va.location 
and de.date = va.date

--Looking at total population vs vaccinations

select de.continent, de.location, de.date, de.population, va.new_vaccinations
from coviddeaths de
join covidvaccinations va
on de.location = va.location 
and de.date = va.date
where de.continent is not null
order by 2,3 

--creating a rolling count of vaccinations by country
select de.continent, de.location, de.date, de.population, va.new_vaccinations,
sum(cast(va.new_vaccinations as bigint)) over (partition by de.location order by de.location, de.date)
from coviddeaths de
join covidvaccinations va
on de.location = va.location 
and de.date = va.date
where de.continent is not null
order by 2,3

--using a CTE to get a value for percentage of population vaccinated as a rolling count

with popvsvac (Continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as
(
select de.continent, de.location, de.date, de.population, va.new_vaccinations,
sum(cast(va.new_vaccinations as bigint)) over (partition by de.location order by de.location, de.date)
from coviddeaths de
join covidvaccinations va
on de.location = va.location 
and de.date = va.date
where de.continent is not null
)

select *, (rollingpeoplevaccinated/population)*100 as percentagevaccinatedpopulation
from popvsvac


--using a temp table 
-- by implementing DROP function, we can execute the function numerous times without errors when making amendments to the the table
DROP table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric, 
rollingpeoplevaccinated numeric
)

insert into #percentpopulationvaccinated
select de.continent, de.location, de.date, de.population, va.new_vaccinations,
sum(cast(va.new_vaccinations as bigint)) over (partition by de.location order by de.location, de.date)
from coviddeaths de
join covidvaccinations va
on de.location = va.location 
and de.date = va.date
where de.continent is not null


select *, (rollingpeoplevaccinated/population)*100 as percentagevaccinatedpopulation
from #percentpopulationvaccinated

--creating view to store data for later visualisations

create view percentpopulationvaccinated as 
select de.continent, de.location, de.date, de.population, va.new_vaccinations,
sum(cast(va.new_vaccinations as bigint)) over (partition by de.location order by de.location, de.date) as rollingpeoplevaccinated
from coviddeaths de
join covidvaccinations va
on de.location = va.location 
and de.date = va.date
where de.continent is not null

