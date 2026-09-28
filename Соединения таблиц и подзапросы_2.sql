Основная часть:
Задание №1

SELECT 
    c.first_name AS "Имя пользователя",
    c.last_name AS "Фамилия пользователя", 
    a.address,
    ci.city,
    co.country
FROM customer c
JOIN address a ON c.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id;

Задание №2.1

select store_id, count(*)
from store
join customer using (store_id)
group by store_id

Задание №2.2

select store_id as "Идентификатор магазина", count(*) as "Количество покупателей"
from store
join customer using (store_id)
group by store_id
having count(*) > 300

Задание №2.3

select "Идентификатор магазина" , "Количество покупателей", c."city" as "Город", concat(s.first_name, ' ', s.last_name) as "Имя сотрудника"
from (
	select store_id as "Идентификатор магазина", store.address_id, count(*) as "Количество покупателей"
	from store
	join customer using (store_id)
	group by store_id
	having count(*) > 300) t
join address a on a.address_id = t.address_id
join city c on c.city_id = a.city_id 
join staff s on s.store_id = t."Идентификатор магазина"


Задание №3

SELECT
   f.title AS "Название фильма",
   COUNT(DISTINCT r.rental_id) AS "Количество аренд"
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
WHERE EXISTS (
   SELECT 1
   FROM film_actor fa
   JOIN actor a ON fa.actor_id = a.actor_id
   WHERE fa.film_id = f.film_id AND a.first_name ilike 'Julia'
)
GROUP BY f.film_id, f.title
ORDER BY "Количество аренд" DESC


Задание №4

select concat(c.last_name, ' ', c.first_name) as "Фамилия и имя", count(r.rental_id) as "Количество фильмов", round(sum(p.amount)) as "Общая стоимость платежей", 
min(p.amount) as "Минимальное значение платежа", max(p.amount) as "Максимальное значение платежа"
from customer c 
join rental r on r.customer_id = c.customer_id
join payment p on r.customer_id =  p.customer_id and p.rental_id = r.rental_id 
group by c.customer_id

Задание №5

SELECT 
    c1.city AS "Город 1", 
    c2.city AS "Город 2" 
FROM city c1 
CROSS JOIN city c2 
WHERE c1.city < c2.city


Задание №6


(select 'наибольшее кол-во продаж - ' || c.name || ' в размере ' || count(p.rental_id) || ' на сумму ' || sum(p.amount)
from payment p
inner join rental r on r.rental_id = p.rental_id
inner join inventory i on i.inventory_id = r.inventory_id
inner join film f on f.film_id = i.film_id
inner join film_category fc on fc.film_id = f.film_id
inner join category c on c.category_id = fc.category_id
group by c.category_id, c.name
order by count(p.rental_id) desc
limit 1)
union all
(select 'наименьшее кол-во продаж - ' || c.name || ' в размере ' || count(p.rental_id) || ' на сумму ' || sum(p.amount)
from payment p
inner join rental r on r.rental_id = p.rental_id
inner join inventory i on i.inventory_id = r.inventory_id
inner join film f on f.film_id = i.film_id
inner join film_category fc on fc.film_id = f.film_id
inner join category c on c.category_id = fc.category_id
group by c.category_id, c.name
order by count(p.rental_id) asc
limit 1)


Дополнительная часть:
Задание №1

select 
	f.title, 
	f.rating, 
	l.name as language, 
	cat.name as category, 
	rental_count.rent_count, 
	rental_count.total_summa
from film f
left join language l on f.language_id = l.language_id
left join (
	select
		fc.film_id,
		string_agg(c.name, ', ') as name
	from film_category fc
	join category c on fc.category_id = c.category_id
	group by fc.film_id
) cat on f.film_id = cat.film_id
left join (
	select 
		i.film_id, 
		count(r.rental_id) as rent_count,
		sum(p.amount) as total_summa
	from inventory i 
	join rental r on i.inventory_id = r.inventory_id
	join payment p on r.rental_id = p.rental_id
	group by i.film_id 
) rental_count on f.film_id = rental_count.film_id
order by f.title


Задание №2

вар.1

select 
	f.title, 
	f.rating, 
	l.name as language, 
	cat.name as category, 
	rental_count.rent_count, 
	rental_count.total_summa
from film f
left join language l on f.language_id = l.language_id
left join (
	select
		fc.film_id,
		string_agg(c.name, ', ') as name
	from film_category fc
	join category c on fc.category_id = c.category_id
	group by fc.film_id
) cat on f.film_id = cat.film_id
left join (
	select 
		i.film_id, 
		count(r.rental_id) as rent_count,
		sum(p.amount) as total_summa
	from inventory i 
	join rental r on i.inventory_id = r.inventory_id
	join payment p on r.rental_id = p.rental_id
	group by i.film_id 
) rental_count on f.film_id = rental_count.film_id
where rental_count.film_id is null
order by f.title

вар.2 

SELECT 
    f.title, 
    f.rating, 
    l.name AS language, 
    cat.category_names AS category, 
    rental_count.rent_count, 
    rental_count.total_summa
FROM film f
LEFT JOIN language l ON f.language_id = l.language_id
-- Lateral join для категорий
LEFT JOIN LATERAL (
    SELECT string_agg(c.name, ', ') AS category_names
    FROM film_category fc
    JOIN category c ON fc.category_id = c.category_id
    WHERE fc.film_id = f.film_id
) cat ON TRUE
-- Lateral join для аренды
LEFT JOIN LATERAL (
    SELECT 
        count(r.rental_id) AS rent_count, 
        sum(p.amount) AS total_summa
    FROM inventory i
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN payment p ON r.rental_id = p.rental_id
    WHERE i.film_id = f.film_id
) rental_count ON TRUE
WHERE rental_count.rent_count = 0 OR rental_count.rent_count IS NULL
ORDER BY f.title

Задание №3

SELECT 
    f.film_id AS "Идентификатор фильма", 
    f.title AS "Название фильма", 
    (
        SELECT array_agg(pos - 1) -- Вычитаем 1, чтобы индекс начинался с 0
        FROM (
            SELECT array_position(all_cats.ids, fc.category_id) AS pos
            FROM film_category fc
            CROSS JOIN (
                -- Формируем один массив всех ID категорий, отсортированных по имени
                SELECT array_agg(category_id ORDER BY name) AS ids FROM category
            ) all_cats
            WHERE fc.film_id = f.film_id
        ) sub
    ) AS "Массив с индексами"
FROM film f
ORDER BY f.film_id


Задание №4

SELECT 
    t1.customer_id,
    (SELECT STRING_AGG(category_name || ' (' || cat_count || ')', ', ' ORDER BY cat_count DESC)
     FROM (
        SELECT sub_c.name AS category_name, COUNT(sub_fc.film_id) AS cat_count
        FROM rental sub_r
        JOIN inventory sub_i ON sub_r.inventory_id = sub_i.inventory_id
        JOIN film_category sub_fc ON sub_i.film_id = sub_fc.film_id
        JOIN category sub_c ON sub_fc.category_id = sub_c.category_id
        WHERE sub_r.customer_id = t1.customer_id
        GROUP BY sub_c.name
        ORDER BY cat_count DESC, sub_c.name ASC
        LIMIT 2 
     ) AS top_2
    ) as top_categories
FROM rental t1
GROUP BY t1.customer_id
ORDER BY t1.customer_id


