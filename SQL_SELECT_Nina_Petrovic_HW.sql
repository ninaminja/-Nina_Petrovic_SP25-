--this part will show all the title of movies, when they are released and their rate (numeric) but only for these one that are released between 2017 and 2019 
--as well only movies which category is 'Animation'
SELECT f.title, f.release_year, f.rental_rate
FROM film f
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category c ON fc.category_id = c.category_id
WHERE f.release_year BETWEEN 2017 AND 2019 
  AND f.rental_rate > 1
  AND c.name = 'Animation'
ORDER BY f.title

--this query will show revenue earned by each store (that's why we have information about location of each store).
--we use inventory table as well as payment to actually show true value of revenue for each store.
--on last part we will show only payments that are surely made after 31.03.2017 
SELECT 
    CONCAT(a.address, ', ', a.address2) AS full_address,
    SUM(p.amount) AS revenue
FROM store s
INNER JOIN address a ON s.address_id = a.address_id
INNER JOIN inventory i ON s.store_id = i.store_id
INNER JOIN rental r ON i.inventory_id = r.inventory_id
INNER JOIN payment p ON r.rental_id = p.rental_id
WHERE p.payment_date > '2017-03-31' -- Using payment_date instead of rental_date
GROUP BY a.address, a.address2
ORDER BY revenue DESC;

--this query will show actors by number of movies they took part in(so who acted in most of movies will be first)
--we will get to know this from table film_actors because they're related.
--and important part is that we are looking for movies that are released after 2015. We will group everything by name and surname of actor and order by number of movies (which is point of ranking actors)
--in the end, limit is to show only 5 actors 
SELECT 
    a.first_name,
    a.last_name,
    COUNT(f.film_id) AS number_of_movies
FROM 
    actor a
INNER JOIN film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN film f ON fa.film_id = f.film_id
WHERE 
    f.release_year > 2015
GROUP BY 
    a.actor_id, a.first_name, a.last_name
ORDER BY 
    number_of_movies DESC
LIMIT 5;

--this query will show all movies that are 'Drama', 'Travel' and 'Documentary' per year, with that we will show release year and order it by release year as well
SELECT 
    f.release_year,
    SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END) AS number_of_drama_films,
    SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END) AS number_of_travel_movies,
    SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END) AS number_of_documentary_movies
FROM film f
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category c ON fc.category_id = c.category_id
WHERE c.name IN ('Drama', 'Travel', 'Documentary')
GROUP BY f.release_year
ORDER BY f.release_year DESC;

--this query will show employees that generated most revenue in 2017. In query we can see story id, staff name and surname
--we will show this only for 2017, that's why we have between(first and last date in a year). We will order this by revenue and show only 3 of them
SELECT 
    s.first_name,
    s.last_name,
    st.store_id,
    SUM(p.amount) AS total_revenue
FROM 
    payment p
JOIN 
    staff s ON p.staff_id = s.staff_id
JOIN 
    store st ON s.store_id = st.store_id
WHERE 
    p.payment_date BETWEEN '2017-01-01' AND '2017-12-31'
GROUP BY 
    s.staff_id, s.first_name, s.last_name, st.store_id
ORDER BY 
    total_revenue DESC
LIMIT 3;

--in this query we will show all the movies that are rented more than others. with that we will pay attention to audience for these movies (for that we will use Motion Picture Association film rating system)
--in this query we used CTE because it's more readable (and it's my first time writing query with CTE so i wanted to try and learn)
WITH film_rentals AS (
SELECT f.film_id, f.title, f.rating, COUNT (r.rental_id) AS rental_count
FROM public.film f
LEFT JOIN public.inventory i ON f.film_id = i.film_id
LEFT JOIN public.rental r ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title, f.rating)
SELECT
fr.title, fr.rental_count, fr.rating,
CASE 
WHEN fr.rating = 'G' THEN 'all ages'
WHEN fr.rating= 'PG' THEN 'age 18+'
WHEN fr.rating = 'R' THEN 'ages 17+(with parents)'
WHEN fr.rating ='NC-17' THEN 'adults only (18+)'
ELSE 'unknown'
END AS expected_audience
FROM film_rentals fr
ORDER BY fr.rental_count DESC
LIMIT 5;

--this query will show all actors that didn't act for a longer period of time.
--i tried to do this with logic current date - release date, so biggest gap is what we need 
-- with this, i combined film_actor because there we have all info about actors releated to films
--on the last we did order by based on years_since_last_film
SELECT a.actor_id, a.first_name, a.last_name,
MAX (f.release_year) AS last_year_of_film,
EXTRACT (YEAR FROM current_date) - MAX (f.release_year) AS years_since_last_film
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f ON fa.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY years_since_last_film DESC;

