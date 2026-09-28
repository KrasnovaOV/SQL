--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
--SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1.1
--Выведите для каждого сотрудника сведения о самой первой продаже этого сотрудника.
--Решение должно быть через оконную функцию.
--В результирующей таблице должны быть следующие столбцы:Все столбцы из таблицы с платежами.

explain analyze
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY staff_id ORDER BY payment_date ASC
           ) AS rn
    FROM payment
) ranked_payments
WHERE rn = 1;



--ЗАДАНИЕ №1.2
--Выведите для каждого сотрудника сведения о самой первой продаже этого сотрудника.
--Решение должно быть через агрегацию.
--В результирующей таблице должны быть следующие столбцы:Все столбцы из таблицы с платежами.

explain analyze

SELECT *
FROM payment p1
WHERE p1.payment_date = (
    SELECT MIN(p2.payment_date)
    FROM payment p2
    WHERE p2.staff_id = p1.staff_id
);

--исправленный вариант, без коррел.подзапроса
select p1.*
from payment p1
inner join (
    select
        staff_id,
        min(payment_date) as first_date
    from payment
    group by staff_id
) p2
    on p1.staff_id = p2.staff_id
    and p1.payment_date = p2.first_date;

--ЗАДАНИЕ №1.3
--Выведите для каждого сотрудника сведения о самой первой продаже этого сотрудника.
--Решение должно быть через distinct on.
--В результирующей таблице должны быть следующие столбцы:Все столбцы из таблицы с платежами.

explain analyze
SELECT DISTINCT ON (staff_id) *
FROM payment
ORDER BY staff_id, payment_date ASC;


--ЗАДАНИЕ №2
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.
--Обязательное условие для выполнения задания: Должно быть использовано СТЕ в котором получаете нужные фильмы. 
--В сте должна быть использована строго одна таблица.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя пользователя в виде одного значения, 
--количество арендованных фильмов.

explain analyze

with cte as (
    select film_id, title, special_features
    from film 
    where special_features && array['Behind the Scenes']
)
select c.first_name || ' ' || c.last_name as "Фамилия и имя", 
       count(cte.film_id) as "Количество арендованных фильмов"
from customer c
left join rental r on c.customer_id = r.customer_id
left join inventory i on r.inventory_id = i.inventory_id
left join cte on cte.film_id = i.film_id 
group by c.customer_id
order by "Количество арендованных фильмов" desc;


--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".
--Обязательное условие для выполнения задания: Должен быть использован подзапрос в котором получаете нужные фильмы. 
--В подзапросе должна быть использована строго одна таблица.
--В результирующей таблице должны быть следующие столбцы: Фамилия и имя пользователя в виде одного значения, 
--количество арендованных фильмов.

explain analyze

SELECT 
    c.first_name || ' ' || c.last_name AS "Фамилия и имя",
    COUNT(*) AS "Количество арендованных фильмов"
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id
LEFT JOIN inventory i ON r.inventory_id = i.inventory_id
WHERE i.film_id IN (
    SELECT film_id 
    FROM film 
    WHERE special_features && ARRAY['Behind the Scenes']
)
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY "Количество арендованных фильмов" DESC;



--ЗАДАНИЕ №4
--Создайте материализованное представление с запросом из задания №3
--и напишите запрос для обновления материализованного представления

CREATE MATERIALIZED VIEW customer_behind_the_scenes_rentals AS
SELECT 
    c.first_name || ' ' || c.last_name AS "Фамилия и имя",
    COUNT(*) AS "Количество арендованных фильмов"
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id
LEFT JOIN inventory i ON r.inventory_id = i.inventory_id
WHERE i.film_id IN (
    SELECT film_id 
    FROM film 
    WHERE special_features && ARRAY['Behind the Scenes']
)
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY "Количество арендованных фильмов" DESC;

--ЗАДАНИЕ №5
--С помощью explain analyze проведите анализ стоимости выполнения запросов из всех предыдущих заданий и ответьте на вопросы:
--1. какой вариант вычислений затрачивает меньше ресурсов системы: из задания 1.1, 1.2 или 1.3.
--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE из 2 задания или с использованием подзапроса из 3 задания.

1.1 cost=0.00..279.49 actual time=0.042..3.430 
1.2 cost=0.00..5358133.82 actual time=18482.643..82409.701 
1.3 cost=0.00..279.49 actual time=0.021..2.171 
 очевидно 1.3
 
 2 cost=836.82..838.32 actual time=19.663..19.701 
 3 cost=406.68..408.18 actual time=4.473..4.492 
 очевидно 3
 
 
--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Откройте по ссылке SQL-запрос: https://letsdocode.ru/sql-main/sql-hw5.sql
--Сделайте explain analyze этого запроса.
--Основываясь на описании запроса, найдите узкие места и опишите их.
--Сравните с вашим решением из 3 задания.
--Сделайте построчное описание explain analyze на русском языке оптимизированного запроса. 
--Описание строк в explain можно посмотреть по ссылке: https://use-the-index-luke.com/sql/explain-plan/postgresql/operations

 --Сделайте explain analyze этого запроса.
EXPLAIN	analyze ---- 586.0  / 17.658
select distinct cu.first_name  || ' ' || cu.last_name as name, 
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc

--Основываясь на описании запроса, найдите узкие места и опишите их.

Unique  (cost=585.98..586.00 rows=2 width=44) (actual time=44.342..44.490 rows=413 loops=1)
  ->  Sort  (cost=585.98..585.99 rows=2 width=44) (actual time=44.340..44.385 rows=736 loops=1)
        Sort Key: (count(r.inventory_id) OVER (?)) DESC, ((((cu.first_name)::text || ' '::text) || (cu.last_name)::text))
        Sort Method: quicksort  Memory: 60kB
        ->  WindowAgg  (cost=585.93..585.97 rows=2 width=44) (actual time=41.270..41.771 rows=736 loops=1)
              ->  Sort  (cost=585.93..585.93 rows=2 width=21) (actual time=41.209..41.261 rows=736 loops=1)
                    Sort Key: cu.customer_id
                    Sort Method: quicksort  Memory: 54kB
                    ->  Nested Loop Left Join  (cost=115.09..585.92 rows=2 width=21) (actual time=9.186..40.526 rows=736 loops=1)
                          ->  Nested Loop Left Join  (cost=114.82..585.31 rows=2 width=6) (actual time=8.782..35.832 rows=736 loops=1)
                                ->  Subquery Scan on inv  (cost=110.50..548.42 rows=2 width=4) (actual time=7.767..16.239 rows=211 loops=1)
                                      Filter: (inv.sf_string ~~ '%Behind the Scenes%'::text)
                                      Rows Removed by Filter: 16151
                                      ->  ProjectSet  (cost=110.50..319.37 rows=18324 width=712) (actual time=7.727..14.632 rows=16362 loops=1)
                                            ->  Hash Full Join  (cost=110.50..193.39 rows=4581 width=68) (actual time=7.716..11.288 rows=4623 loops=1)
                                                  Hash Cond: (i.film_id = f.film_id)
                                                  ->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.042..1.376 rows=4581 loops=1)
                                                  ->  Hash  (cost=98.00..98.00 rows=1000 width=68) (actual time=7.644..7.645 rows=1000 loops=1)
                                                        Buckets: 1024  Batches: 1  Memory Usage: 110kB
                                                        ->  Seq Scan on film f  (cost=0.00..98.00 rows=1000 width=68) (actual time=0.072..7.269 rows=1000 loops=1)
                                ->  Bitmap Heap Scan on rental r  (cost=4.32..18.41 rows=4 width=6) (actual time=0.036..0.087 rows=3 loops=211)
                                      Recheck Cond: (inventory_id = inv.inventory_id)
                                      Heap Blocks: exact=734
                                      ->  Bitmap Index Scan on idx_fk_inventory_id  (cost=0.00..4.32 rows=4 width=0) (actual time=0.010..0.010 rows=3 loops=211)
                                            Index Cond: (inventory_id = inv.inventory_id)
                          ->  Index Scan using customer_pkey on customer cu  (cost=0.28..0.30 rows=1 width=17) (actual time=0.006..0.006 rows=1 loops=736)
                                Index Cond: (customer_id = r.customer_id)
Planning Time: 48.857 ms
Execution Time: 45.925 ms

КРИТИЧЕСКИЕ УЗКИЕ МЕСТА запроса (45.9ms)
УЗКОЕ МЕСТО №1: unnest() + LIKE (14.6ms = 32%)
ProjectSet  (actual time=7.727..14.632 rows=16362 loops=1)
  ->  Hash Full Join inventory×film (4623 строки)
Проблема: unnest(special_features) раздувает 1000 фильмов × 4581 inventory = 16k → 16k×4 = 65k строк
Хуже: LIKE '%Behind%' фильтрует ПОСЛЕ unnest → 16 151 строк удалено зря!
Итог: 95% лишних вычислений

УЗКОЕ МЕСТО №2: WindowAgg на 736 строках (41.8ms = 91%)
WindowAgg  (actual time=41.270..41.771 rows=736 loops=1)
  ->  Sort  (41.209..41.261 rows=736)  // 2 сортировки!
Проблема: COUNT() OVER (PARTITION BY) требует сортировки всех 736 клиентов
Хуже: ДВЕ сортировки подряд (WindowAgg + внешний ORDER BY)
Правильно наверное: GROUP BY customer_id = одна агрегация без сортировки

УЗКОЕ МЕСТО №3: FULL OUTER JOIN × 3
Hash Full Join  (cost=110.50..193.39 rows=4581)  // Вместо LEFT JOIN!
Nested Loop Left Join × 211 раз (40.5ms!)
Проблема: FULL OUTER создает дубликаты + nullи
Итог: DISTINCT в конце (Unique узел)

УЗКОЕ МЕСТО №4: Поздняя фильтрация (после JOINов)
Subquery Scan on inv  (Rows Removed by Filter: 16151)
Фильтр LIKE применяется ПОСЛЕ всех JOINов!.

--Сравните с вашим решением из 3 задания (Запрос из 3 задания - 1, Запрос https://letsdocode.ru/sql-main/sql-hw5.sql - 2)
Разбор узких мест Запроса 2
Критические проблемы:
--unnest(f.special_features)
1000 фильмов × средне 4 features = 4000 строк
× 4581 inventory = 18+ МЛН строк!

--FULL OUTER JOIN × 3
customer (599) × rental (16k) × inventory (4.5k) = 40+ МЛН строк

--LIKE '%Behind%'
Сканирует все раз--unnest--енные строки
Не использует индексы
Последний фильтр = поздно!

--DISTINCT + COUNT() OVER()
Двойная обработка одних и тех же данных
--DISTINCT на миллионах строк = ад

--оптимизированный запрос
explain analyze --(cost=800.20..809.19 rows=599 width=57) (actual time=17.525..17.598 rows=599 loops=1
with cte as (
    select film_id from film 
    where special_features && array['behind the scenes']
)
select c.first_name || ' ' || c.last_name, 
       count(cte.film_id)
from customer c
left join rental r on c.customer_id = r.customer_id
left join inventory i on r.inventory_id = i.inventory_id
left join cte on cte.film_id = i.film_id 
group by c.customer_id, c.first_name, c.last_name;

--Сделайте построчное описание explain analyze на русском языке оптимизированного запроса. 
HashAggregate  (cost=800.20..809.19 rows=599 width=57) (actual time=17.525..17.598 rows=599 loops=1)  
Group Key: c.customer_id  
Batches: 1  Memory Usage: 105kB  
->  Hash Left Join  (cost=282.68..719.98 rows=16044 width=21) (actual time=4.208..15.626 rows=16044 loops=1)
Hash Cond: (i.film_id = film.film_id)
->  Hash Left Join  (cost=181.55..576.57 rows=16044 width=19) (actual time=2.393..12.542 rows=16044 loops=1)
Hash Cond: (r.inventory_id = i.inventory_id)
->  Hash Right Join  (cost=53.48..406.33 rows=16044 width=21) (actual time=1.345..9.383 rows=16044 loops=1)
Hash Cond: (r.customer_id = c.customer_id)                    
->  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=6) (actual time=0.144..3.145 rows=16044 loops=1)
->  Hash  (cost=45.99..45.99 rows=599 width=17) (actual time=0.893..0.893 rows=599 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 39kB
->  Seq Scan on customer c  (cost=0.00..45.99 rows=599 width=17) (actual time=0.029..0.578 rows=599 loops=1)
->  Hash  (cost=70.81..70.81 rows=4581 width=6) (actual time=0.949..0.949 rows=4581 loops=1)
Buckets: 8192  Batches: 1  Memory Usage: 234kB
->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.024..0.582 rows=4581 loops=1)
->  Hash  (cost=100.50..100.50 rows=50 width=4) (actual time=1.608..1.609 rows=50 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 10kB
->  Seq Scan on film  (cost=0.00..100.50 rows=50 width=4) (actual time=1.496..1.600 rows=50 loops=1)
Filter: (special_features && '{"Behind the Scenes"}'::text[])
Rows Removed by Filter: 950
Planning Time: 14.757 ms
Execution Time: 19.615 ms

Общая информация
HashAggregate: Узел, который выполняет агрегацию данных (в нашем случае — GROUP BY).
Planning Time: Время, затраченное планировщиком на построение плана (14.757 мс).
Execution Time: Общее время выполнения запроса (19.615 мс). Это очень быстро.

Детальный разбор (снизу вверх)
1. Самый нижний уровень (Источники данных)
Seq Scan on film
Что делает: Последовательно (строка за строкой) читает таблицу film.
Filter: Применяет фильтр special_features && '{"Behind the Scenes"}'. Оператор && проверяет наличие элемента в массиве. Это эффективно.
Статистика: Из 1000 строк (rows=1000) фильтр пропустил только 50, отбросив 950.
Время: Сканирование и фильтрация заняли около 1.6 мс.

Seq Scan on inventory
Что делает: Последовательно читает таблицу inventory.
Статистика: В таблице 4581 строка. Сканирование заняло около 0.6 мс.

Seq Scan on customer
Что делает: Последовательно читает таблицу customer.
Статистика: В таблице 599 строк. Сканирование заняло около 0.6 мс.

Seq Scan on rental
Что делает: Последовательно читает таблицу rental.
Статистика: Самая большая таблица в запросе — 16044 строки. Сканирование заняло около 3.1 мс.

2. Хеширование (Подготовка к соединениям)
Прежде чем соединять большие таблицы, PostgreSQL строит в оперативной памяти "хеш-таблицы" для меньших таблиц, чтобы потом быстро находить соответствия.
Hash (для film)
Создает хеш-таблицу из 50 строк, полученных после фильтрации.
Использует 10kB памяти.

Hash (для inventory)
Создает хеш-таблицу из всех 4581 строк таблицы inventory.
Использует 234kB памяти.

Hash (для customer)
Создает хеш-таблицу из всех 599 строк таблицы customer.
Использует 39kB памяти.

3. Соединения (Joins)
PostgreSQL использует алгоритм Hash Join, который очень эффективен для больших объемов данных. 
Он берет хеш-таблицу (построенную выше) и пробегает по второй таблице, находя совпадения по ключу.

Hash Right Join (rental и customer)
Соединяет таблицы rental и customer по ключу customer_id.
Результат: 16044 строки.
Это соединение заняло большую часть времени на этом этапе (около 9.4 мс).

Hash Left Join (результат выше + inventory)
Соединяет результат предыдущего шага с таблицей inventory по ключу inventory_id.
Результат: 16044 строки.

Hash Left Join (результат выше + film)
Соединяет результат с таблицей film по ключу film_id.
Результат: 16044 строки.

4. Финальная агрегация
HashAggregate
Что делает: Берет огромный результат соединений (16044 строки) и группирует их по c.customer_id, 
чтобы получить итоговый результат (599 строк).
Эффективность: Использует хеширование для группировки, что быстрее сортировки для больших данных.
Память: Использует всего 105kB памяти.

--ЗАДАНИЕ №2
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день
--В результирующей таблице должны быть следующие столбцы: Идентификатор магазина, день аренды, 
--количество фильмов, день продажи, сумма продаж.

нет решения, нет изначальных данных
WITH rental_stats AS (
    SELECT 
        c.store_id,
        date_trunc('day', r.rental_date)::date AS rental_day,
        COUNT(r.rental_id) AS rental_count,
        ROW_NUMBER() OVER (PARTITION BY c.store_id ORDER BY COUNT(r.rental_id) DESC) AS rn_rental
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    GROUP BY c.store_id, rental_day
),
payment_stats AS (
    SELECT 
        c.store_id,
        date_trunc('day', p.payment_date)::date AS payment_day,
        SUM(p.amount) AS payment_amount,
        ROW_NUMBER() OVER (PARTITION BY c.store_id ORDER BY SUM(p.amount)) AS rn_payment
    FROM customer c
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.store_id, payment_day
)
SELECT 
    rs.store_id AS "Идентификатор магазина",
    rs.rental_day AS "День аренды",
    rs.rental_count AS "Количество фильмов",
    ps.payment_day AS "День продажи",
    ps.payment_amount AS "Сумма продаж"
FROM rental_stats rs
JOIN payment_stats ps ON rs.store_id = ps.store_id 
    AND rs.rn_rental = 1 AND ps.rn_payment = 1;

--ЗАДАНИЕ №3
--Создайте не наполненное материализованное представление, которое будет хранить отчёт следующей структуры:
--идентификатор сотрудника
--ФИО сотрудника в виде одной строки
--город проживания сотрудника
--идентификатор магазина
--город магазина
--дата последнего платежа, принятого сотрудником
--размер последнего платежа, принятого сотрудником
--общая сумма продаж

CREATE MATERIALIZED VIEW staff_sales_report 
(WITHOUT OIDS) AS 
SELECT 
    s.staff_id AS "идентификатор сотрудника",
    s.first_name || ' ' || s.last_name AS "ФИО сотрудника",
    a.city AS "город проживания сотрудника",
    st.store_id AS "идентификатор магазина",
    ct.city AS "город магазина",
    p.last_payment_date AS "дата последнего платежа",
    p.last_payment_amount AS "размер последнего платежа",
    p.total_sales AS "общая сумма продаж"
FROM staff s
JOIN address a ON s.address_id = a.address_id
JOIN store st ON s.store_id = st.store_id
JOIN city ct ON st.address_id = ct.city_id
LEFT JOIN (
    SELECT 
        staff_id,
        MAX(payment_date) AS last_payment_date,
        FIRST_VALUE(amount) OVER (
            PARTITION BY staff_id 
            ORDER BY payment_date DESC 
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_payment_amount,
        SUM(amount) AS total_sales
    FROM payment
    GROUP BY staff_id
) p ON s.staff_id = p.staff_id