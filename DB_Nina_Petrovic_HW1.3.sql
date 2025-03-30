SELECT f.release_year,
COALESCE ((SELECT COUNT (f1.film_id)
FROM public.film f1
INNER JOIN public. film_category fc1 ON f1.film_id=fc1.film_id
INNER JOIN public.category c1 ON fc1.category_id = c1.category_id
WHERE c1.name= 'Drama' AND f1.release_year = f.release_year),0)
AS number_of_drama_films,
COALESCE ((SELECT COUNT(f2.film_id)
FROM public.film f2
INNER JOIN public.film_category fc2 ON f2.film_id = fc2.film_id
INNER JOIN public.category c2 ON fc2.category_id = c2.category_id
WHERE c2.name = 'Travel' AND f2.release_year = f.release_year), 0)
AS number_of_travel_movies,
COALESCE ((SELECT COUNT (f3.film_id)
FROM public.film f3
INNER JOIN public.film_category fc3 ON f3.film_id = fc3.film_id
INNER JOIN public.category c3 ON fc3.category_id = c3. category_id
WHERE c3.name = 'Documentary' AND f3.release_year = f.release_year), 0)
AS number_of_documentary_movies
FROM public.film f
GROUP BY f.release_year
ORDER BY f.release_year DESC;