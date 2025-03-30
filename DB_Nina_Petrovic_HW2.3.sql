SELECT a.actor_id, a.first_name, a.last_name,
MAX (f.release_year) AS last_year_of_film,
EXTRACT (YEAR FROM current_date) - MAX (f.release_year) AS years_since_last_film
FROM public.actor a
INNER JOIN public.film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN public.film f ON f.film_id = f.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY years_since_last_film DESC;