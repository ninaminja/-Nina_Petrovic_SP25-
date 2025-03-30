SELECT f. title,f.release_year, f.rental_rate
FROM film f
WHERE f.release_year BETWEEN 2017 AND 2019 AND f.rental_rate > 1
AND f.film_id IN (
SELECT fc.film_id
FROM film_category fc
INNER JOIN public.category c ON fc.category_id = c.category_id
WHERE c.name = 'Animation')
ORDER BY f.title;