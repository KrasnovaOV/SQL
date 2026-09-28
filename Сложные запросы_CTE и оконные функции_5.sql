--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--1.1 Пронумеруйте все платежи от 1 до N по дате платежа
--1.2 Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа
--1.3 Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна быть 
--сперва по дате платежа, а затем по размеру платежа от наименьшей к большей
--1.4 Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к меньшему так, 
--чтобы платежи с одинаковым значением имели одинаковое значение номера.
--В результирующей таблице должны быть следующие столбцы: Идентификатор платежа, дата платежа, 
--идентификатор пользователя, размер платежа, 4 столбца с результатами оконных функций.

SELECT customer_id  as "Идентификатор пользователя", payment_id as "Идентификатор платежа", payment_date as "Дата платежа", amount as "размер платежа", 
	row_number() over (order by payment_date) as "Номер платежа по дате",
	row_number() over (partition by customer_id order by payment_date) as "Номер платежа покупателя по дате",
	sum(p.amount) over (partition by p.customer_id order by p.payment_date) as "Сумма платежа нарастающим итогом",
	dense_rank() over (partition by p.customer_id order by amount desc) as "Номер платежа покупателя по стоим"
FROM payment p
order by customer_id, "Номер платежа покупателя по стоим"

--исправленное
SELECT 
    payment_id AS "Идентификатор платежа", 
    payment_date AS "Дата платежа", 
    customer_id AS "Идентификатор пользователя", 
    amount AS "Размер платежа",
    ROW_NUMBER() OVER (ORDER BY payment_date) AS "Номер платежа по дате",
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date) AS "Номер платежа покупателя по дате",
    SUM(amount) OVER (
        PARTITION BY customer_id 
        ORDER BY payment_date ASC, amount ASC
    ) AS "Сумма платежа нарастающим итогом",
    DENSE_RANK() OVER (
        PARTITION BY customer_id 
        ORDER BY amount DESC
    ) AS "Номер платежа покупателя по стоимости"
FROM payment
ORDER BY customer_id, payment_date;


--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.
--В результирующей таблице должны быть следующие столбцы: Идентификатор платежа, дата платежа, 
--идентификатор пользователя, текущий размер платежа, размер платежа из предыдущей строки.

 select customer_id  as "Идентификатор пользователя", payment_id as "Идентификатор платежа", payment_date as "Дата платежа", amount as "размер платежа",
 	lag(p.amount,1,0.) over (partition by customer_id order by p.payment_date)
 from payment p
 order by customer_id


--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.
--В результирующей таблице должны быть следующие столбцы: Идентификатор платежа, дата платежа, идентификатор пользователя, 
--текущий размер платежа, следующий размер платежа, разница между текущим и следующим платежами.

--select customer_id, payment_id, payment_date, amount,
	--amount - lead(p.amount,1,0.) over (partition by customer_id  order by p.payment_date, customer_id) as difference
--from payment p

SELECT 
    payment_id,
    payment_date,
    customer_id,
    amount AS current_amount,
    LEAD(amount) OVER (PARTITION BY customer_id ORDER BY payment_date) AS next_amount,
    amount - LEAD(amount) OVER (PARTITION BY customer_id ORDER BY payment_date) AS difference
FROM payment p
ORDER BY customer_id, payment_date

--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.
--В результирующей таблице должны быть следующие столбцы: Все столбцы из таблицы с платежами.

--select customer_id, payment_id, payment_date, last_value
from(
	select customer_id, payment_id, payment_date,
		last_value(amount) over (partition by customer_id order by payment_date desc),
		row_number() over (partition by customer_id order by payment_date desc) 
	from payment) p 
where row_number = 1

SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date DESC) AS rn
    FROM payment
) t
WHERE rn = 1
ORDER BY customer_id


--ЗАДАНИЕ №5
--Одним запросом ответить на два вопроса: в какой из месяцев было получено платежей на наибольшую сумму? 
--На какую сумму по отношению к предыдущему месяцу было сдано в аренду больше/меньше фильмов.
--Обязательное условие для выполнения задания: Таблица payment должна быть использована строго один раз. Если в топ 1 попадает несколько месяцев, 
--в результате должны быть все месяцы попавшие в топ 1. Топ 1 месяц получать через оконную функцию.
--В результирующей таблице должны быть следующие столбцы: Значение месяца, сумма за месяц, сумма за предыдущий месяц, разница между суммами.

WITH MonthlyStats AS (
    SELECT 
        DATE_TRUNC('month', payment_date) AS month_value,
        SUM(amount) AS current_month_sum,
        LAG(SUM(amount)) OVER (ORDER BY DATE_TRUNC('month', payment_date)) AS prev_month_sum
    FROM payment
    GROUP BY 1
),
RankedStats AS (
    SELECT 
        month_value::date,
        current_month_sum,
        prev_month_sum,
        (current_month_sum - COALESCE(prev_month_sum, 0)) AS difference,
        RANK() OVER (ORDER BY current_month_sum DESC) as rnk
    FROM MonthlyStats
)
SELECT 
    month_value,
    current_month_sum,
    prev_month_sum,
    difference
FROM RankedStats
WHERE rnk = 1


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя сотрудника в виде 
--одного значения, сумма продаж на каждый день, накопительный итог.

SELECT 
    CONCAT(s.last_name, ' ', s.first_name) AS full_name,
    t1.sum_amount AS daily_amount,
    SUM(t1.sum_amount) OVER (
        PARTITION BY t1.staff_id 
        ORDER BY t1.payment_date
    ) AS running_total
FROM (
    SELECT 
        p.staff_id,
        p.payment_date::date AS payment_date,
        SUM(p.amount) AS sum_amount
    FROM payment p
    WHERE DATE_TRUNC('month', p.payment_date) = '2005-08-01'::date
    GROUP BY p.staff_id, p.payment_date::date
) t1
JOIN staff s ON t1.staff_id = s.staff_id
ORDER BY t1.staff_id, t1.payment_date;



--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку
--В результирующей таблице должны быть следующие столбцы: Идентификатор пользователя, 
--фамилия и имя пользователя в виде одного значения.

SELECT 
    p.customer_id,
    CONCAT(c.last_name, ' ', c.first_name) AS full_name
FROM (
    SELECT 
        p.customer_id,
        ROW_NUMBER() OVER (ORDER BY payment_date) AS rn
    FROM payment p
    WHERE payment_date::date = '2005-08-20'
) p
JOIN customer c ON p.customer_id = c.customer_id
WHERE p.rn % 100 = 0


--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм
--В результирующей таблице должны быть следующие столбцы: Название страны, фамилия и имя пользователя в 
--виде одного значения лучшего по количеству, фамилия и имя пользователя в виде одного значения лучшего 
--по сумме платежей, фамилия и имя пользователя в виде одного значения последним арендовавшим фильм.
--Есть два варианта решения: получать одного случайного, если в топ 1 попадает несколько пользователей, 
--выводить всех пользователей, попавших в топ 1. Выбор варианта остается за вами.


EXPLAIN	ANALYZE --
WITH customer_country AS (
    SELECT DISTINCT
        c.country,
        cu.customer_id,
        CONCAT_WS(' ', cu.last_name, cu.first_name) AS fio
    FROM country c 
    JOIN city ci ON ci.country_id = c.country_id 
    JOIN address a ON a.city_id = ci.city_id 
    JOIN customer cu ON cu.address_id = a.address_id 
),
top_rentals AS (
    SELECT 
        cc.country,
        cc.fio AS top_rentals_fio,
        ROW_NUMBER() OVER (PARTITION BY cc.country ORDER BY COUNT(r.rental_id) DESC) AS rn
    FROM customer_country cc
    JOIN rental r ON r.customer_id = cc.customer_id
    GROUP BY cc.country, cc.fio
),
top_amounts AS (
    SELECT 
        cc.country,
        cc.fio AS top_amount_fio,
        ROW_NUMBER() OVER (PARTITION BY cc.country ORDER BY SUM(p.amount) DESC) AS rn
    FROM customer_country cc
    JOIN payment p ON p.customer_id = cc.customer_id
    GROUP BY cc.country, cc.fio
),
last_rental AS (
    SELECT 
        cc.country,
        cc.fio AS last_rental_fio,
        ROW_NUMBER() OVER (PARTITION BY cc.country ORDER BY MAX(r.rental_date) DESC) AS rn
    FROM customer_country cc
    JOIN rental r ON r.customer_id = cc.customer_id
    GROUP BY cc.country, cc.fio
)
SELECT 
    cc.country,
    MAX(tr.top_rentals_fio) AS top_quantity_fio,
    MAX(ta.top_amount_fio) AS top_amount_fio,
    MAX(lr.last_rental_fio) AS last_rental_fio
FROM customer_country cc
LEFT JOIN top_rentals tr ON tr.country = cc.country AND tr.rn = 1
LEFT JOIN top_amounts ta ON ta.country = cc.country AND ta.rn = 1
LEFT JOIN last_rental lr ON lr.country = cc.country AND lr.rn = 1
GROUP BY cc.country
ORDER BY cc.country

--исправленный
EXPLAIN	ANALYZE
WITH customer_base AS (
    SELECT DISTINCT
        c.country_id,
        c.country,
        cu.customer_id,
        CONCAT_WS(' ', cu.last_name, cu.first_name) AS fio
    FROM customer cu
    JOIN address a ON a.address_id = cu.address_id
    JOIN city ci ON ci.city_id = a.city_id
    JOIN country c ON c.country_id = ci.country_id  -- country 1 раз
),
top_rentals AS (
    SELECT 
        cb.country,
        cb.fio,
        ROW_NUMBER() OVER (PARTITION BY cb.country ORDER BY COUNT(r.rental_id) DESC) AS rn
    FROM customer_base cb                    -- customer уже использован выше
    JOIN rental r ON r.customer_id = cb.customer_id  -- rental 1 раз
    GROUP BY cb.country, cb.fio
),
top_amounts AS (
    SELECT 
        cb.country,
        cb.fio,
        ROW_NUMBER() OVER (PARTITION BY cb.country ORDER BY SUM(p.amount) DESC) AS rn
    FROM customer_base cb                    -- customer уже использован выше  
    JOIN payment p ON p.customer_id = cb.customer_id  -- payment 1 раз
    GROUP BY cb.country, cb.fio
),
last_rental AS (
    SELECT 
        cb.country,
        cb.fio,
        ROW_NUMBER() OVER (PARTITION BY cb.country ORDER BY MAX(r.rental_date) DESC) AS rn
    FROM customer_base cb                    -- customer уже использован выше
    JOIN rental r ON r.customer_id = cb.customer_id  -- rental уже использован выше
    GROUP BY cb.country, cb.fio
)
SELECT 
    cb.country,
    MAX(tr.fio) AS top_quantity_fio,
    MAX(ta.fio) AS top_amount_fio,
    MAX(lr.fio) AS last_rental_fio
FROM customer_base cb
LEFT JOIN top_rentals tr ON tr.country = cb.country AND tr.rn = 1
LEFT JOIN top_amounts ta ON ta.country = cb.country AND ta.rn = 1
LEFT JOIN last_rental lr ON lr.country = cb.country AND lr.rn = 1
GROUP BY cb.country
ORDER BY cb.country;

--исправленный 2
WITH customer_country AS (
    -- Этот блок остается без изменений, так как он формирует справочник
    SELECT DISTINCT
        c.country,
        cu.customer_id,
        CONCAT_WS(' ', cu.last_name, cu.first_name) AS fio
    FROM country c 
    JOIN city ci ON ci.country_id = c.country_id 
    JOIN address a ON a.city_id = ci.city_id 
    JOIN customer cu ON cu.address_id = a.address_id 
),
customer_stats AS (
    -- Объединяем все расчеты в один блок
    SELECT
        cc.country,
        cc.fio,
        -- Рейтинг по количеству аренд
        ROW_NUMBER() OVER (PARTITION BY cc.country ORDER BY COUNT(DISTINCT r.rental_id) DESC) AS rn_rentals,
        -- Рейтинг по сумме платежей
        ROW_NUMBER() OVER (PARTITION BY cc.country ORDER BY SUM(p.amount) DESC) AS rn_amounts,
        -- Рейтинг по дате последней аренды
        ROW_NUMBER() OVER (PARTITION BY cc.country ORDER BY MAX(r.rental_date) DESC) AS rn_last_date
    FROM customer_country cc
    LEFT JOIN rental r ON r.customer_id = cc.customer_id
    LEFT JOIN payment p ON p.customer_id = cc.customer_id
    GROUP BY cc.country, cc.fio
)
SELECT DISTINCT
    cs.country,
    MAX(CASE WHEN cs.rn_rentals = 1 THEN cs.fio END) AS top_quantity_fio,
    MAX(CASE WHEN cs.rn_amounts = 1 THEN cs.fio END) AS top_amount_fio,
    MAX(CASE WHEN cs.rn_last_date = 1 THEN cs.fio END) AS last_rental_fio
FROM customer_stats cs
GROUP BY cs.country
ORDER BY cs.country;

--доп.задание КАЛЕНДАРЬ
сформировать календарь рабочих дней на 2026 с учетом выходных и праздничных дней.

create temporary table xml_prod_calendar as 
 select xml
  $$ <calendar year="2026" lang="ru" date="2025.09.30" country="ru">
<holidays>
<holiday id="1" title="Новогодние каникулы"/>
<holiday id="2" title="Рождество Христово"/>
<holiday id="3" title="День защитника Отечества"/>
<holiday id="4" title="Международный женский день"/>
<holiday id="5" title="Праздник Весны и Труда"/>
<holiday id="6" title="День Победы"/>
<holiday id="7" title="День России"/>
<holiday id="8" title="День народного единства"/>
</holidays>
<days>
<day d="01.01" t="1" h="1"/>
<day d="01.02" t="1" h="1"/>
<day d="01.03" t="1" h="1"/>
<day d="01.04" t="1" h="1"/>
<day d="01.05" t="1" h="1"/>
<day d="01.06" t="1" h="1"/>
<day d="01.07" t="1" h="2"/>
<day d="01.08" t="1" h="1"/>
<day d="01.09" t="1" f="01.03"/>
<day d="02.23" t="1" h="3"/>
<day d="03.08" t="1" h="4"/>
<day d="03.09" t="1" f="03.08"/>
<day d="04.30" t="2"/>
<day d="05.01" t="1" h="5"/>
<day d="05.08" t="2"/>
<day d="05.09" t="1" h="6"/>
<day d="05.11" t="1" f="05.09"/>
<day d="06.11" t="2"/>
<day d="06.12" t="1" h="7"/>
<day d="11.03" t="2"/>
<day d="11.04" t="1" h="8"/>
<day d="12.31" t="1" f="01.04"/>
</days>
</calendar> $$ as xml_data;
  
 select *
 from xml_prod_calendar
 
 drop table prod_calendar
 
 create table prod_calendar (
	id serial primary key,
	date date not null,
	description text,
	type text not null)
	
select *
from prod_calendar

with xml_year as (
 select hol_year
 from xml_prod_calendar, xmltable('//calendar' passing xml_data columns
  hol_year int path '@year')),
xml_holidays as (
 select holiday_id, holiday_desc
 from xml_prod_calendar, xmltable('//calendar/holidays/holiday' passing xml_data columns
  holiday_id int path '@id',
  holiday_desc text path '@title')),
xml_days as (
 select hol_date, hol_type, hol_desc, hol_from
 from xml_prod_calendar, xmltable('//calendar/days/day' passing xml_data columns
  hol_date text path '@d',
  hol_type int path '@t',
  hol_desc int path '@h',
  hol_from text path '@f'))
insert into prod_calendar (date, description, type)
select concat(xy.hol_year, '.', xd.hol_date)::date, 
 coalesce(xh.holiday_desc, 'Перенос с ' || split_part(xd.hol_from, '.', 2) || '.' || split_part(xd.hol_from, '.', 1) || '.' || xy.hol_year), 
 case
  when hol_type = 1 then 'выходной день'
  when hol_type = 2 then 'рабочий и сокращенный'
  when hol_type = 3 then 'рабочий день'
 end
from xml_days xd
cross join xml_year xy
left join xml_holidays xh on xd.hol_desc = xh.holiday_id 
order by 1;

with recursive r as (
	select '01.01.2026'::date start_date
	union
	select start_date + 1
	from r 
	where start_date < '31.12.2026'::date)
select * 
from r
where start_date not in (select date from prod_calendar where type = 'выходной день') 
	and date_part('isodow', start_date) not in (6,7)
union 
select date 
from prod_calendar 
where type != 'выходной день'
order by 1


