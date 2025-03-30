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
END
FROM film_rentals fr
ORDER BY fr.rental_count DESC
LIMIT 5;