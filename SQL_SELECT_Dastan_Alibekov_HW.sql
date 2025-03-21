-- Part 1
--1.

select f.title, f.release_year
from film f 
inner join film_category fc using(film_id)
inner join category c using(category_id)
where c.name = 'Animation'
and f.rental_rate < 1
and f.release_year between 2017 and 2019
order by title;

-- 2.

select a.address || coalesce(a.address2,'') address, sum(p.amount) as revenue_in_2017
from payment p 
inner join rental r on r.rental_id = p.rental_id
inner join inventory i on i.inventory_id = r.inventory_id
inner join store on i.store_id = store.store_id
inner join address a on store.address_id = a.address_id
where p.payment_date >= '2017-03-01'
group by a.address || coalesce(a.address2,'');

-- 3.

select a.first_name, a.last_name , count(fa.film_id) number_of_movies
from actor a 
inner join film_actor fa using(actor_id)
inner join film f using(film_id)
where f.release_year > 2015
group by actor_id, a.first_name, a.last_name
order by number_of_movies desc
limit 6; -- included top 6 as there is a tie in number of movies

--4. 

select f.release_year, 
		count(*) filter(where c.name = 'Drama') number_of_drama_movies,
		count(*) filter(where c.name = 'Travel') number_of_travel_movies,
		count(*) filter(where c.name = 'Documentary') number_of_documentary_movies
from film f
left join film_category fc using(film_id)
left join category c using(category_id)
where c.name in ('Drama', 'Travel', 'Documentary') 	-- just to optimize
group by f.release_year
order by release_year desc;


-- Part 2

--1. 

/* the below query logic does not seem to be working correctly, as there are inventory rentals from both stores 1 and 2, that were 
paid for in each employee's last transaction day in 2017  */

with last_pmt as (
	select distinct
	--p.payment_date, 
	p.staff_id, i.store_id
	from payment p 
	inner join
		(select p.staff_id, max(p.payment_date) payment_date
		from payment p 
		group by p.staff_id) t
	on t.staff_id = p.staff_id and p.payment_date = t.payment_date
	inner join rental r on r.rental_id = p.rental_id
	inner join inventory i on i.inventory_id = r.inventory_id
	inner join staff s on p.staff_id = s.staff_id
	where extract(year from p.payment_date) = 2017
)

-- Thus, below query logic is done without using a cte

select s.first_name, s.last_name, s.store_id, sum(p.amount) as revenue_in_2017
from payment p 
inner join staff s on p.staff_id = s.staff_id
where extract(year from p.payment_date) = 2017
group by s.staff_id, s.first_name, s.last_name, s.store_id
order by revenue_in_2017 desc
limit 3;

--2 

select 
	f.title,
	count(*) times_rented,
	f.rating, 
	case
		when f.rating = 'G' then '0+'
		when f.rating = 'PG' then '0+ guidence suggested'
		when f.rating = 'PG-13' then '13+ or with guidence'
		when f.rating = 'R' then '17+ or with guidence'
		when f.rating = 'NC-17' then '17+ strictly'
	end as age_rating_desc
from rental r
inner join inventory i on r.inventory_id = i.inventory_id
inner join film f on i.film_id = f.film_id
group by 
	f.film_id,
	f.title,
	f.rating
order by times_rented desc
limit 5;

--Part 3

--V1

with current_year as (
	select extract(year from CURRENT_DATE)
)

select a.first_name, a.last_name, (select * from current_year) - max(f.release_year) as years_from_current
from actor a
inner join film_actor fa on a.actor_id = fa.actor_id
inner join film f on f.film_id = fa.film_id
group by a.actor_id, a.first_name, a.last_name
order by years_from_current desc
limit 10;

--V2

select 
	a.actor_id ,
	a.first_name,
	a.last_name,
	coalesce (f.release_year - lag(f.release_year, 1) over 
		(partition by a.actor_id order by f.release_year), 0) as years_between_films
from actor a
inner join film_actor fa on a.actor_id = fa.actor_id
inner join film f on f.film_id = fa.film_id
order by years_between_films desc
limit 10;

--V2 without window functions

select 
	distinct
    a.actor_id,
    a.first_name,
    a.last_name,
    coalesce(f.release_year - (
        select max(f_prev.release_year) 
        from film_actor fa_prev
        join film f_prev on fa_prev.film_id = f_prev.film_id
        where fa_prev.actor_id = a.actor_id 
        and f_prev.release_year < f.release_year
    ), 0) as years_between_films
from actor a
inner join film_actor fa on a.actor_id = fa.actor_id
inner join film f on f.film_id = fa.film_id
order by years_between_films desc
limit 10;