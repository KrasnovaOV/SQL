--Задания:
--1. Получите количество проектов, подписанных в 2023 году.
--В результат вывести одно значение количества.

select count(*) as project_count
from project
where sign_date >= date '2023-01-01'
  and sign_date < date '2024-01-01';

--2. Получите общий возраст сотрудников, нанятых в 2022 году.
--Результат вывести одним значением в виде "... years ... months ... days"
--Использование более 2х функций для работы с типом данных дата и время будет являться ошибкой.

select
    sum(age(current_date, p.birthdate)) as total_age
from employee e
join person p on p.person_id = e.person_id
where e.hire_date >= date '2022-01-01'
  and e.hire_date < date '2023-01-01';


--3. Получите сотрудников, у которого фамилия начинается на М, всего в фамилии 8 букв и который работает дольше других.
--Если таких сотрудников несколько, выведите одного случайного.
--В результат выведите два столбца, в первом должны быть имя и фамилия через пробел, во втором дата найма.

select
    p.last_name || ' ' || p.first_name as fio,
    e.hire_date
from employee e
join person p on p.person_id = e.person_id
where p.last_name like 'М%'
  and length(p.last_name) = 8
order by e.hire_date asc, random()
limit 1;

--4. Получите среднее значение полных лет сотрудников, которые уволены и не задействованы на проектах.
--В результат вывести одно среднее значение. Если получаете null, то в результат нужно вывести 0.

select 
    coalesce(avg(date_part('year', age(current_date, p.birthdate))), 0) as average_full_years
from person p
join employee e on p.person_id = e.person_id
left join project pr on e.employee_id = any (employees_id)
where e.dismissal_date is not null 
  and pr.project_id is null

--5. Чему равна сумма полученных платежей от контрагентов из Жуковский, Россия.
--В результат вывести одно значение суммы.

explain analyze	

select sum(pp.amount) as total_amount
	from customer c
join address a on c.address_id = a.address_id
join city ct on a.city_id = ct.city_id and ct.city_name = 'Жуковский'
join country cn on ct.country_id = cn.country_id and cn.country_name = 'Россия'
join project pr on pr.customer_id = c.customer_id
join project_payment pp on pr.project_id = pp.project_id
where pp.fact_transaction_timestamp is not null
  
explain analyze	

--вар.2 немного оптимизированее
select sum(pp.amount) as total_amount
	from project_payment pp
join project pr on pp.project_id = pr.project_id
join customer c on pr.customer_id = c.customer_id
join address a on c.address_id = a.address_id
join city ct on a.city_id = ct.city_id
join country cn on ct.country_id = cn.country_id
	where cn.country_name = 'Россия'
  and ct.city_name = 'Жуковский'
  and pp.fact_transaction_timestamp is not null

--6. Пусть руководитель проекта получает премию в 1% от стоимости завершенных проектов.
--Если взять завершенные проекты, какой руководитель проекта получит самый большой бонус?
--В результат нужно вывести идентификатор руководителя проекта, его ФИО и размер бонуса.
--Если таких руководителей несколько, предусмотреть вывод всех.

select pr.project_manager_id,p.full_fio, sum(pr.project_cost) * 0.01 as bonus
	from project pr
join employee e on e.employee_id = pr.project_manager_id
join person p on p.person_id = e.person_id
where pr.status = 'Завершен'
group by project_manager_id,full_fio
order by bonus desc

--7. Получите накопительный итог планируемых авансовых платежей на каждый месяц в отдельности.
--Выведите в результат те даты планируемых платежей, которые идут после преодаления накопительной суммой значения в 30 000 000
--В результат должна попасть дата 2022-06-23

explain analyze

select plan_payment_date, sum
	from (select*, row_number() over (partition by date_trunc ('month', plan_payment_date) order by plan_payment_date)
	from (select project_payment_id, project_id, payment_type, plan_payment_date,
	sum (amount) over (partition by date_trunc ('month', plan_payment_date) order by plan_payment_date)
	from project_payment pp 
where payment_type = 'Авансовый')
where sum > 30000000)
where row_number = 1

explain analyze

select distinct on (date_trunc('month', plan_payment_date)) 
    plan_payment_date::date as pay_date, accumulation
from (select plan_payment_date,
        sum(amount) over (partition by date_trunc('month', plan_payment_date) 
        order by plan_payment_date, project_payment_id
        ) as accumulation
    from project_payment
    where payment_type = 'Авансовый'
) sub
where accumulation > 30000000
order by date_trunc('month', plan_payment_date), plan_payment_date

--8. Используя рекурсию посчитайте сумму фактических окладов сотрудников из структурного подразделения с id равным 17 
--и всех дочерних подразделений.
--В результат вывести одно значение суммы.

explain analyze

with recursive unithierarchy as (
    select unit_id
    from company_structure
    where unit_id = 17
union all
    select cs.unit_id
    from company_structure cs
    join unithierarchy uh on uh.unit_id = cs.parent_id
)
select sum(ep.salary * ep.rate) as total_salary
from unithierarchy uh
join position p on p.unit_id = uh.unit_id
join employee_position ep on ep.position_id = p.position_id


--9. Задание выполняется одним запросом.
--Сделайте сквозную нумерацию фактических платежей по проектам на каждый год в отдельности в порядке даты платежей.
--Получите платежи, сквозной номер которых кратен 5.
--Выведите скользящее среднее размеров платежей с шагом 2 строки назад и 2 строки вперед от текущей.
--Получите сумму скользящих средних значений.
--Получите сумму стоимости проектов на каждый год.
--Выведите в результат значение года (годов) и сумму проектов, где сумма проектов меньше, чем сумма скользящих средних значений.

with pay_num as (
    -- 1. формируем сквозную нумерацию и рассчитываем скользящее среднее по годам
    select
        date_part('year', pp.fact_transaction_timestamp) as pay_year,
        row_number() over (
            partition by date_part('year', pp.fact_transaction_timestamp)
            order by pp.fact_transaction_timestamp, pp.project_payment_id
        ) as rn,
        avg(pp.amount) over (
            partition by date_part('year', pp.fact_transaction_timestamp)
            order by pp.fact_transaction_timestamp, pp.project_payment_id
            rows between 2 preceding and 2 following
        ) as moving_avg
    from project_payment pp
    where pp.fact_transaction_timestamp is not null
),
avg_sum_by_year as (
    -- 2. суммируем скользящие средние для платежей, чей номер кратен 5 (группировка по году)
    select
        pay_year,
        sum(moving_avg) as sum_moving_avg
    from pay_num
    where rn % 5 = 0
    group by pay_year
),
project_sum_by_year as (
    -- 3. считаем общую стоимость проектов на каждый год
    select
        date_part('year', sign_date)::int as project_year,
        sum(project_cost) as sum_project_cost
    from project
    group by date_part('year', sign_date)
)
-- 4. сравниваем суммы по соответствующим годам и выводим результат
select
    ps.project_year as year,
    ps.sum_project_cost
from project_sum_by_year ps
join avg_sum_by_year av on ps.project_year = av.pay_year
where ps.sum_project_cost < av.sum_moving_avg
order by ps.project_year;


--10. Создайте материализованное представление, которое будет хранить отчет следующей структуры:
--идентификатор проекта
--название проекта
--дата последней фактической оплаты по проекту
--размер последней фактической оплаты
--ФИО руководителей проектов
--Названия контрагентов
--В виде строки названия типов работ по каждому контрагенту


create materialized view project_report as
select
    pr.project_id,
    pr.project_name,
    pp.fact_transaction_timestamp as last_payment_date,
    pp.amount as last_payment_amount,
    pr.full_fio as manager_fio,
    c.customer_name,
    c.work_types
from (select p1.full_fio, p.project_id, p.project_name, p.customer_id 
    from project p 
    join employee e on e.employee_id = p.project_manager_id 
    join person p1 on p1.person_id = e.person_id) pr
join (select project_id, amount, fact_transaction_timestamp, 
        row_number() over (partition by project_id order by fact_transaction_timestamp desc) as rn 
    from project_payment 
    where fact_transaction_timestamp is not null) pp on pr.project_id = pp.project_id
join (select c.customer_id, c.customer_name, string_agg(tow.type_of_work_name, ', ') as work_types 
    from customer c 
    join customer_type_of_work ctow on ctow.customer_id = c.customer_id 
    join type_of_work tow on ctow.type_of_work_id = tow.type_of_work_id 
    group by c.customer_id, c.customer_name) c on pr.customer_id = c.customer_id
where pp.rn = 1;
    

