Задание №1

select *, cardinality(special_features)
from film

select title, special_features, array_position(special_features, 'Behind the Scenes')
from film 
where special_features @> array['Behind the Scenes']

ответ

select title, special_features
from film
where special_features && array['Behind the Scenes']

select title, special_features
from film
where special_features @> array['Behind the Scenes']

select title, special_features
from film
where 'Behind the Scenes' = any(special_features)

select title, special_features
from film 
where special_features::text like '%Behind the Scenes%' 

select title, array_agg(unnest)
from (
 select title, unnest(special_features), film_id
 from film) t
where unnest = 'Behind the Scenes'
group by film_id, title

Задание №2

select *
from payment

select payment_id, amount, payment_date 
from payment
where payment_date >= '2005-06-17 00:00:00'
	and payment_date <= '2005-06-20'
    and amount > 1.00
order by payment_date

select payment_id, amount, payment_date
from payment
where payment_date :: date between '17/06/2005' and '19.06.2005' 
      and amount > 1.00
order by payment_date


Задание №3

select 
    customer_id as "Идентификатор пользователя", 
    sum(amount) as "Сумма платежей"
from payment
group by customer_id
order by "Сумма платежей" desc
limit 5

Задание №4

select 
	customer_id as "customer_id",
    jsonb_array_length(preferences->'profile'->'favorite_genres') as "Количество предпочитаемых жанров"
from customer


Задание №5

select customer_id, jsonb_pretty(preferences)
from customer

select (preferences->'notifications'-> 'email')
from customer
 
select count(*)
from customer
where (preferences->'notifications')->>'email' = 'false'

Задание №6

select customer_id, date_trunc('month', payment_date), sum(amount)
from payment 
group by customer_id, date_trunc('month', payment_date)
order by 1, 2, 3

Задание №7

select 
    staff_id as "Идентификатор сотрудника",
    sum(amount) as "Сумма платежей"
from payment 
group by staff_id
order by "Сумма платежей" desc

Задание №8

select customer_id,
    round(avg(extract(day from return_date - rental_date)), 2) as "Среднее количество дней"
from rental
group by customer_id
order by customer_id


Дополнительная часть:
Задание №1 - 

explain analyze

select 
    extract(isodow from rental_date)::integer as "День недели",
    count(*) as "Количество аренд"
from rental 
group by extract(isodow from rental_date)::integer
having count(*) = (
    select MAX(ct) 
    from (
        select count(*) AS ct 
        from rental 
        group by extract(isodow from rental_date)::integer
    ) sub
)
order by "День недели"

explain analyze

select 
    extract(isodow from rental_date)::integer AS "День недели",
    count(*) as "Количество аренд"
from rental 
group by extract(isodow from rental_date)::integer
order by "Количество аренд" desc
fetch first 1 rows with ties 


explain analyze
select 
    extract(isodow from rental_date)::integer AS "День недели",
    count(*) as "Количество аренд"
from rental 
group by extract(isodow from rental_date)::integer
order by "Количество аренд" desc
limit 1

explain analyze

select 
    extract(dow from rental_date) as "День недели",
    count(*) as "Количество аренд"
from rental 
group by extract(dow from rental_date)
order by "Количество аренд" desc
fetch first 1 rows with ties 


explain analyze
select date_part('isodow', rental_date), 
	count(date_part('isodow', rental_date)) as "Количество аренд"
from rental r 
group by date_part('isodow', rental_date)
order by "Количество аренд" desc
fetch first 1 rows with ties 


Задание №2

select staff_id
from payment
group by staff_id

select staff_id , 
      count(payment_id ) as "Количество продаж",
       case
		    when count(payment_id ) > 7300 then 'Да'
	 	    else 'Нет'	
  	   end	as "Премия"
from payment 
group by staff_id


Задание №3

select customer_id,rental_date
from rental
group by customer_id,rental_date
order by rental_date

судя по всему в период с с 10 июня 2005 включительно по 13 июня 2005 вообще не было аренд, поэтому видимо итог пустой

select 
    customer_id as "Идентификатор пользователя", count(rental_id) as "Количество аренд"
from rental 
where rental_date >= '10.06.2005' 
  and rental_date < '13/06/2005'
group by customer_id
having count(rental_id) > 3
order by "Количество аренд" desc
limit 3

поменяла даты чтобы посмотреть, как отработает другой период

select 
    customer_id as "Идентификатор пользователя", count(rental_id) as "Количество аренд"
from rental 
where rental_date >= '01.08.2005' 
  and rental_date < '30.08.2005'
group by customer_id
having count(rental_id) > 3
order by "Количество аренд" desc
limit 3





