--ЗАДАНИЕ №1

--Спроектируйте базу данных, содержащую три справочника:
--· язык (английский, французский и т. п.);
--· народность (славяне, англосаксы и т. п.);
--· страны (Россия, Германия и т. п.).
--Две таблицы со связями: язык-народность и народность-страна, отношения многие ко многим. Пример таблицы со связями — film_actor.
--Требования к таблицам-справочникам:
--· наличие ограничений первичных ключей.
--· идентификатору сущности должен присваиваться автоинкрементом;
--· наименования сущностей не должны содержать null-значения, не должны допускаться --дубликаты в названиях сущностей.
--Требования к таблицам со связями:
--· наличие ограничений первичных и внешних ключей.

--В качестве ответа на задание пришлите запросы создания таблиц и запросы по --добавлению в каждую таблицу по 5 строк с данными.
 
-- Новая Схема
CREATE SCHEMA schema_countries

--СОЗДАНИЕ ТАБЛИЦЫ ЯЗЫКИ

create table language (
	language_id serial2 primary key,
	language_name varchar(100) not null unique
)

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ ЯЗЫКИ
insert into language(language_id, language_name)
values (1, 'Русский'), (2, 'Французский'), (3, 'Японский'), (4, 'Английский'), (5, 'Немецкий')

select *
from "language"

--СОЗДАНИЕ ТАБЛИЦЫ НАРОДНОСТИ

create table nationality(
	nationality_id serial primary key,
	nationality_name varchar(100) not null unique
)

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ НАРОДНОСТИ

insert into nationality(nationality_id, nationality_name)
values (1, 'Славяне'), (2, 'Англо-Саксы'), (3, 'Французы'), (4, 'Японцы'), (5, 'Немцы')

select *
from nationality

--СОЗДАНИЕ ТАБЛИЦЫ СТРАНЫ

create table country(
	country_id serial primary key,
	country_name varchar(100) not null unique
)

--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СТРАНЫ

insert into country(country_id, country_name)
values (1, 'Россия'), (2, 'Англия'), (3, 'Франция'), (4, 'Япония'), (5,'Германия')

select *
from country

--СОЗДАНИЕ ПЕРВОЙ ТАБЛИЦЫ СО СВЯЗЯМИ

create table language_nationality(
	language_id int2 not null references language(language_id),
	nationality_id int2 not null references nationality(nationality_id),
	primary key(language_id, nationality_id)
)


--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ

insert into language_nationality(language_id, nationality_id)
values (1, 1), (2, 2), (4, 2), (3, 4), (4, 4) ,(2, 3), (4, 3), (5, 5), (4, 5)

select *
from language_nationality


--СОЗДАНИЕ ВТОРОЙ ТАБЛИЦЫ СО СВЯЗЯМИ

create table country_nationality(
	country_id int2 not null references country(country_id),
	nationality_id int2 not null references nationality(nationality_id),
	primary key(country_id, nationality_id)
)


--ВНЕСЕНИЕ ДАННЫХ В ТАБЛИЦУ СО СВЯЗЯМИ

insert into country_nationality(nationality_id, country_id)
values (1, 1), (2, 2), (3, 3 ), (4, 4), (2, 3),(5, 5), (5, 3), (5, 2)

--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============
 

--ЗАДАНИЕ №1 
--Создайте новую таблицу film_new со следующими полями:
--·   	film_name - название фильма - тип данных varchar(255) и ограничение not null
--·   	film_year - год выпуска фильма - тип данных integer, условие, что значение должно быть больше 0
--·   	film_rental_rate - стоимость аренды фильма - тип данных numeric(4,2), значение по умолчанию 0.99
--·   	film_duration - длительность фильма в минутах - тип данных integer, ограничение not null и условие, что значение должно быть больше 0
--Если работаете в облачной базе, то перед названием таблицы задайте наименование вашей схемы.

CREATE TABLE film_new (
film_name VARCHAR (255) NOT NULL,
film_year integer CHECK (film_year > 0),
film_rental_rate numeric(4,2) DEFAULT (0.99),
film_duration integer NOT NULL CHECK (film_duration> 0)
)

--ЗАДАНИЕ №2 
--Заполните таблицу film_new данными с помощью SQL-запроса, где колонкам соответствуют массивы данных:
--·       film_name - array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']
--·       film_year - array[1994, 1999, 1985, 1994, 1993]
--·       film_rental_rate - array[2.99, 0.99, 1.99, 2.99, 3.99]
--·   	  film_duration - array[142, 189, 116, 142, 195]

INSERT INTO film_new (film_name, film_year,film_rental_rate, film_duration )
	VALUES (
		UNNEST (array['The Shawshank Redemption', 'The Green Mile', 'Back to the Future', 'Forrest Gump', 'Schindlers List']),			
	    UNNEST (array[1994, 1999, 1985, 1994, 1993]),
		UNNEST (array[2.99, 0.99, 1.99, 2.99, 3.99]),
	    UNNEST (array[142, 189, 116, 142, 195])
	    )

select *
from film_new

	    
--ЗАДАНИЕ №3
--Обновите стоимость аренды фильмов в таблице film_new с учетом информации, 
--что стоимость аренды всех фильмов поднялась на 1.41

UPDATE film_new
SET film_rental_rate = film_rental_rate + 1.41

select *
from film_new

--ЗАДАНИЕ №4
--Фильм с названием "Back to the Future" был снят с аренды, 
--удалите строку с этим фильмом из таблицы film_new

DELETE FROM film_new
WHERE film_name = 'Back to the Future'

--ЗАДАНИЕ №5
--Добавьте в таблицу film_new запись о любом другом новом фильме

INSERT INTO film_new (film_name, film_year, film_rental_rate, film_duration )
	VALUES 
		('Avatar', 2009, 3.05, 166)

select *
from film_new

--ЗАДАНИЕ №6
--Напишите SQL-запрос, который выведет все колонки из таблицы film_new, 
--а также новую вычисляемую колонку "длительность фильма в часах", округлённую до десятых

SELECT *,
	round( (film_duration::NUMERIC) / 60, 1) AS "длительность фильма в часах"
FROM
	film_new

--ЗАДАНИЕ №7 
--Удалите таблицу film_new

Drop table film_new cascade
