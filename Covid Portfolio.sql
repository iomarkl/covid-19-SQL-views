select *
from PortfolioProject..CovidDeath
order by 3,4

--select *
--from PortfolioProject..CovidVac

-- select data that we are going to be using 

select location,date,total_cases,new_cases,total_deaths,population
from PortfolioProject..CovidDeath
order by 1,2


--looking at totalcases vs total deaths
select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeath
order by 1,2

--000
--let's see italy numbers
select *
--location,date,total_cases,new_cases,cast(total_deaths as int) as total_death,(total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeath
where location = 'italy'
order by 4
-- We note that the numbers of new cases began to explode on  19th February
--It's the same day that Atalanta Bergamo plays aganist Valencia in ucl in ITALY
--000

--number of Intensive Care Unit Patient Per Million
select cast(max(icu_patients_per_million) as float) as icuPatientPerMillion,location
--location,date,total_cases,new_cases,cast(total_deaths as int) as total_death,(total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeath
group by location
having max(icu_patients_per_million)  is not null
order by 1 desc

--looking the percentage of death to the cases and looking for the highest infection count across europe
select location,population,Max(total_cases) as HighestInfectionCount,MAX((total_deaths/total_cases))*100 as DeathPercentage
from PortfolioProject..CovidDeath
where continent = 'Europe'
group by location,population
order by DeathPercentage desc

--let's take a look in China
select location,date,total_cases,cast(total_deaths as int) as total_death ,(total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeath
where location = 'China'
order by 2


--PercaentPopulationInfection
select location,population,Max(total_cases) as HighestInfectionInOneDay,MAX((total_cases/population))*100 as PercaentPopulationInfection
from PortfolioProject..CovidDeath
where location <> continent
group by location,population
order by PercaentPopulationInfection desc

--showing countries with highest death count per population
select location,Max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeath
where location <> continent
group by location
order by TotalDeathCount desc

--most countries with highest death per population in Europe
select location,Max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeath
where location <> continent and continent = 'Europe'
group by location
order by TotalDeathCount desc

--most countries with highest death per population in Africa
--be aware that some countries in Africa doesn't have an integrity data due to  poor infrastructure
select location,Max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeath
where location <> continent and continent = 'Africa'
group by location
order by TotalDeathCount desc

--let's break things down by continent
select continent,sum(cast(new_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeath
where continent is not null 
group by continent
order by TotalDeathCount desc


--global numbers 
select date,SUM(new_cases) as total_cases ,sum(cast(new_deaths as int)) as total_deaths
,(sum(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
--,,cast(total_deaths as int) as total_death,(total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeath
where continent is not null
group by date
order by 1,2

--global numbers
select SUM(new_cases) as total_cases ,sum(cast(new_deaths as int)) as total_deaths
,(sum(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
--,,cast(total_deaths as int) as total_death,(total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeath
where continent is not null
--group by date
order by 1,2

--let's take a look in vac table
Select *
From PortfolioProject..CovidVac

--hospital_beds per thousand
select distinct det.location, hospital_beds_per_thousand,det.population
from PortfolioProject..CovidVac vac
join PortfolioProject..CovidDeath det
	on det.location=vac.location
where det.location <> det.continent and hospital_beds_per_thousand is not null
order by hospital_beds_per_thousand desc

--aged 65 older percentage and total deaths
select distinct vac.location, aged_65_older,max(cast(total_deaths as int)) as total_death
from PortfolioProject..CovidVac vac
join PortfolioProject..CovidDeath det
	on det.location=vac.location
where det.location <> det.continent and aged_65_older is not null
group by vac.location,aged_65_older
order by aged_65_older desc

--GDP per capita
select distinct location, gdp_per_capita
from PortfolioProject..CovidVac
where location <> continent and gdp_per_capita is not null
order by gdp_per_capita desc

--life expectancy per location
select distinct location, life_expectancy
from PortfolioProject..CovidVac
where location <> continent and life_expectancy is not null

--diabetes prevalence
select distinct location, diabetes_prevalence
from PortfolioProject..CovidVac
where location <> continent and diabetes_prevalence is not null


Select * 
From PortfolioProject..CovidDeath dt
join PortfolioProject..CovidVac vc
	On dt.location=vc.location

--looking at total population vs vaccinations

Select dt.continent,dt.location,dt.date,dt.population,vc.new_vaccinations
,sum(cast(vc.new_vaccinations as int)) over ( partition by dt.location order by dt.location,dt.date) as rollingpeoplevaccinated,

From PortfolioProject..CovidDeath dt
join PortfolioProject..CovidVac vc
	On dt.location=vc.location
where dt.continent is not null
order by 2,3

--use cte

with PopvsVac (continent,location,date,population,new_vaccinations,rollingpeoplevaccinated)
as 
(
Select dt.continent,dt.location,dt.date,dt.population,vc.new_vaccinations
,SUM(cast(vc.new_vaccinations as float)) OVER (Partition by dt.location
    Order by dt.location, dt.date ROWS UNBOUNDED PRECEDING) as rollingpeoplevaccinated

From PortfolioProject..CovidDeath dt
join PortfolioProject..CovidVac vc
	On dt.location=vc.location
	and dt.date=vc.date
where dt.continent is not null
--order by 2,3
)
select *, (rollingpeoplevaccinated/population)*100
from PopvsVac


--temp table
Drop Table if  exists #PercentPopulationVaccinated
create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)
insert into #PercentPopulationVaccinated
--temp table

Select dt.continent,dt.location,dt.date,dt.population,vc.new_vaccinations
,SUM(cast(vc.new_vaccinations as float)) OVER (Partition by dt.location
    Order by dt.location, dt.date ROWS UNBOUNDED PRECEDING) as rollingpeoplevaccinated

From PortfolioProject..CovidDeath dt
join PortfolioProject..CovidVac vc
	On dt.location=vc.location
	and dt.date=vc.date
--where dt.continent is not null
--order by 2,3

select *, (rollingpeoplevaccinated/population)*100
from #PercentPopulationVaccinated

--creating view to store data for later visualizations

Create View PercentPopulationVaccinated22 as 
Select dt.continent,dt.location,dt.date,dt.population,vc.new_vaccinations
,SUM(cast(vc.new_vaccinations as float)) OVER (Partition by dt.location
    Order by dt.location, dt.date ROWS UNBOUNDED PRECEDING) as rollingpeoplevaccinated

From PortfolioProject..CovidDeath dt
join PortfolioProject..CovidVac vc
	On dt.location=vc.location
	and dt.date=vc.date
where dt.continent is not null
--order by 2,3

select *
from PercentPopulationVaccinated