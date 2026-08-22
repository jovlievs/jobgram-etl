
-- 1. Eng talabgir ko'nikmalar: O'zbekiston IT
-- bozorida (yoki tanlangan sohada) eng ko'p so'ralayotgan
-- top-5 ko'nikma (skills) qaysilar?

select top 5
    ds.skill_name,
    count(*) as demand
from gold.bridge_job_skills bs
join gold.dim_skills ds on bs.skill_id = ds.skill_id
join gold.fact_jobs fj on fj.job_id = bs.job_id
join gold.dim_occupations do on do.occupation_id = fj.occupation_id
where
    lower(do.occupation_name) like '%dasturchi%'
 or lower(do.occupation_name) like '%developer%'
 or lower(do.occupation_name) like '%programmer%'
 or lower(do.occupation_name) like '%it%'
 or lower(do.occupation_name) like '%digital%'
 or lower(do.occupation_name) like '%kompyuter%'
group by ds.skill_name
order by count(*) desc;


-- 2. Hududiy maoshlar farqi: Toshkent shahri bilan viloyatlar o'rtasidagi
-- o'rtacha maosh farqi necha foiz? Qaysi viloyatda vakansiyalar soni o'sishi eng yuqori?
with temp as (
    select
        dl.city,
        avg(fj.salary) as avg_salary,
        count(*) as vakansiyalar_soni
    from gold.fact_jobs fj
    join gold.dim_locations dl on dl.location_id = fj.location_id
    group by dl.city
)
-- toshkent - 100
-- current - x = current * 100 / toshkent

select
    city,
    round(avg_salary, 2) as avg_salary,
    vakansiyalar_soni,
    round(avg_salary * 100 / (select avg_salary from temp where city IN ('Toshkent')) - 100, 2) as percent_diff
from temp
order by vakansiyalar_soni desc;


-- 3. Qaysi viloyatda vakansiyalar soni o'sishi eng yuqori?

with temp as (
    select
        dl.city,
        format(fj.job_date, 'yyyy-MM') as year_month,
        count(*) as monthly_count,
        first_value(count(*)) over (
            partition by dl.city order by format(fj.job_date, 'yyyy-MM') asc
            rows between unbounded preceding and current row
        ) as first_month_count
    from gold.fact_jobs fj
    join gold.dim_locations dl on dl.location_id = fj.location_id
    group by dl.city, format(fj.job_date, 'yyyy-MM')
)

select top 10
    city,
    sum(monthly_count) as total_sum,
    count(distinct year_month) as total_month,
    first_month_count,
    round((sum(monthly_count) - first_month_count) * 1.0 / (count(distinct year_month)), 2) as growth
from temp
group by city, first_month_count
order by growth desc;


-- 4. "Oltin" kasblar: Qaysi occupation (kasb) turi bo'yicha eng kam vakansiya bor,
-- lekin maosh eng baland? (Kadrlar yetishmovchiligi tahlili).

select
    occupation_name,
    avg(salary) as avg_salary,
    count(*) as soni
from gold.fact_jobs fj
join gold.dim_occupations do on do.occupation_id = fj.occupation_id
group by occupation_name
having count(*) >= 2
order by avg_salary desc, soni asc;


-- 5. Kompaniyalar faolligi: Qaysi channels (kanallar) orqali eng sifatli
-- vakansiyalar (yuqori maoshli va talablari aniq) e'lon qilinmoqda?

with temp as (
    select
        job_id,
        count(*) as skill_count
    from gold.bridge_job_skills
    group by job_id
)

select
    dc.channel_name,
    count(fj.job_id) as sifatli_vacancy_soni,
    round(avg(fj.salary), 2) as avg_quality_salary
from gold.fact_jobs fj
join gold.dim_channels dc on dc.channel_id = fj.channel_id
join temp on temp.job_id = fj.job_id
where temp.skill_count >= 3
group by dc.channel_name
having count(fj.job_id) >= 3
order by avg_quality_salary desc;
