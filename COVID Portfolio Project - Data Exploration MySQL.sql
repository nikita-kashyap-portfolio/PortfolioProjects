SELECT * FROM portfolioproject.coviddeaths
where continent is not null
ORDER BY 3,4;

SELECT * FROM portfolioproject.covidvaccinations
ORDER BY 3,4; 

-- select data that we are going to be using 

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portfolioproject.coviddeaths
ORDER BY 1,2;

-- looking at total cases vs total deaths
-- shows likelihood of fying if you contract covid in your country

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathspercentage
from portfolioproject.coviddeaths
where location like '%India%'
and continent is not null
order by 1,2;

-- looking at total cases vs poplulation
-- shows what % of population got covid

select location, date, total_cases, population, (total_cases/population)*100 as populationpercentage
from portfolioproject.coviddeaths
where location like '%India%'
order by 1,2;

-- looking at countries with highest infection rate compared to population

select location, population, max(total_cases) as HighestinfectionCount, max(total_cases/population)*100 as percentagepopulationinfected
from portfolioproject.coviddeaths
-- where location like '%India%'
group by location, population
order by percentagepopulationinfected desc;

-- showing countries with death count per population 
select location,  max(total_deaths) as totaldeathcount
from portfolioproject.coviddeaths
-- where location like '%India%'
where continent is not null
group by location
order by totaldeathcount desc;

-- let's break things down by continent



-- showing continents with the highest death counts per population

select continent,  max(total_deaths ) as totaldeathcount
from portfolioproject.coviddeaths
-- where location like '%India%'
 where continent is not null
group by continent
order by totaldeathcount desc; 

-- Global Members

select date, sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases*100) as deathpercentage
from portfolioproject.coviddeaths
-- where location like '%India%'
where continent is not null
group by date
order by 1,2;

-- looking at total population vs vaccination 
select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over(partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated
from portfolioproject.coviddeaths dea
 join portfolioproject.covidvaccinations vac
  on dea.location = vac.location
   and dea.date = vac.date
   where dea.continent is not null
   order by 2,3 ;
   
   -- use cte
   with PopvsVac (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
   as 
   (
select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over(partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated 
from portfolioproject.coviddeaths dea
 join portfolioproject.covidvaccinations vac
  on dea.location = vac.location
   and dea.date = vac.date
   where dea.continent is not null
   -- order by 2,3 
   )
   select *,
   (RollingPeopleVaccinated/population)*100 as VaccinatedPercentage
   from PopvsVac;
   
   
   -- temp table
   
   drop temporary table if exists PercentPopulationVaccinated ;
 create temporary table PercentPopulationVaccinated 
 (
 continent varchar(225),
 location varchar(225),
 DATE datetime,
 Population numeric,
 New_vaccination numeric,
 RollingPeopleVaccinated numeric
 );

 insert into PercentPopulationVaccinated 
 select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over(partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated 
from portfolioproject.coviddeaths dea
 join portfolioproject.covidvaccinations vac
  on dea.location = vac.location
   and dea.date = vac.date
   where dea.continent is not null ;
   -- order by 2,3 
   
  select *,
   (RollingPeopleVaccinated/population)*100 as VaccinatedPercentage
   from PercentPopulationVaccinated ;
   
   --  creating view to store for later visualizations
create view PercentPopulationVaccinated as
   select dea.continent, dea.location,dea.date, dea.population, vac.new_vaccinations,
sum(vac.new_vaccinations) over(partition by dea.location order by dea.location,
dea.date) as RollingPeopleVaccinated 
from portfolioproject.coviddeaths dea
 join portfolioproject.covidvaccinations vac
  on dea.location = vac.location
   and dea.date = vac.date
   where dea.continent is not null 
   order by 2,3 
;
   select *
   from PercentPopulationVaccinated;
