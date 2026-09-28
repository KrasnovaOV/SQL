Задание №1

select distinct city
from city c

Задание №2

select distinct city
from city c
where city like 'L%a'
and city not like '% %'

Задание №3

select payment_id , payment_date, amount
from payment
order by payment_date desc
limit 10

Задание №4
еще два варианта, постаралась регулярные не использовать

select concat(last_name, ' ', first_name) as "Фамилия и имя", email as "Электронная почта", 
concat(substring (email from position('@' in email) + 0)) as "Домен электронной почты",
length(email) as "Длина емэйла"
from customer

select concat(last_name, ' ', first_name) as "Фамилия и имя", email as "Электронная почта",
substr (email, strpos (email, '@')) as "Домен электронной почты",
length(email) as "Длина емэйла"
from customer



Задание №5

select lower(last_name) as last_name, lower(first_name) as first_name, active
from customer
	where (first_name = 'KELLY' or first_name = 'WILLIE') and active = 1

Задание №6

select film_id, title, round(cast(rental_rate as numeric) / length, 3) as rent_leng
from film
where lower(title) like 'be%'
    and length(description) > 100
    and round(cast(rental_rate as numeric) / length, 3) > 0.015;


Дополнительная часть:
Задание №1

select title, rating, rental_rate
from film
where rating::text like 'R' and rental_rate between 0 and 3.00
	or rating::text like 'PG-13' and rental_rate >= 4.00

Задание №2

select title, description , character_length(description) 
from film
order by 3 desc
limit 3

Задание №3

select email,
split_part(email, '@', 1) as "Имя почтового ящика",
split_part(email, '@', 2) as "Домен"
from customer


Задание №4
вариант 1, но не совсем рабочий, после точки возвращает заглавную букву

select email,
    initcap(split_part(email, '@', 1)) as "Имя почтового ящика",
    initcap (split_part(email, '@', 2)) as "Домен"
from customer

вариант 2, всю голову сломала, может можно проще??

select email,
    concat(UPPER(LEFT(split_part(email, '@', 1), 1)), LOWER(SUBSTRING(split_part(email, '@', 1) FROM 2))) as "Имя почтового ящика",                
    concat(UPPER(LEFT(split_part(email, '@', 2), 1)), LOWER(SUBSTRING(split_part(email, '@', 2) FROM 2))) as "Домен"
from customer





