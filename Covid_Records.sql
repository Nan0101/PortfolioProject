select * from CovidDeaths
where location like'%income%'
order by 3,4


select * from CovidVaccinations
order by 3,4

--likelihood of death if covid contracted in the country
select location,date,total_cases, total_deaths, (total_deaths/total_cases)* 100 as deathPercent
from CovidDeaths
where location like '%India%'
order by 1,2

--what percentage of population got covid
select location,date,total_cases, Population, (total_cases/population)* 100 as infectedPercent
from CovidDeaths
where location like '%India%'
order by 1,2 

--countried with highest infection rate compared to population
select location,population, max(total_cases) as higestInfectionCount,
	max((total_cases/population))* 100 as infectionPercent
from CovidDeaths
group by location, population
order by infectionPercent desc

--countries with highest death count
select location,population, max(total_deaths) as totalDeathCount
from CovidDeaths
where continent is not null
group by location, population
order by totalDeathCount desc

--LET'S BREAK THINGS DOWN BY CONTINENT
select location, max(total_deaths) as totalDeathCount
from CovidDeaths
where continent is null
and location not like '%income%'
group by location
order by totalDeathCount desc

-- total cases/deaths/death percentage GLOABALLY grouped by date
select date, sum(new_cases) as total_cases, 
		sum(new_deaths) as total_deaths,
		(sum(new_deaths)/sum(new_cases))* 100 as deathPercent
from CovidDeaths
where continent is not null
group by date
having sum(new_cases) <> 0
order by 1,2

--check for divide by zero error in previous query
select date, sum(new_cases) as total_case from CovidDeaths group by date
having sum(new_cases) = 0

--total cases/deaths and rate recorded overall
select sum(new_cases) as total_cases, 
		sum(new_deaths) as total_deaths,
		(sum(new_deaths)/sum(new_cases))* 100 as deathPercent
from CovidDeaths
where continent is not null
having sum(new_cases) <> 0
order by 1,2

-- total population vs vaccinations
-- total number of people vaccinated
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--rolling count of all the people that have been vaccinated across locations
--using PARTITION BY

select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

--total percentage of people vaccinated
-- USE CTE

with PopVsVac (continent, location, date, population,new_vaccinations, RollingPeopleVaccinated)
as 
(select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select * , (RollingPeopleVaccinated/population)*100
from PopVsVac

--TEMP TABLE for above criteria
drop table if exists #PercentPeopleVaccinated
create table #PercentPeopleVaccinated
(
continent nvarchar(255),
Location nvarchar(255),
Date date,
Population numeric,
Vaccination numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPeopleVaccinated
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *,(RollingPeopleVaccinated/Population)*100
from #PercentPeopleVaccinated

-- Creating VIEW to store data for future visualizations
create view PercentPopulationVaccinatedv as
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
	sum(vac.new_vaccinations) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select * 
from PercentPopulationVaccinatedv
