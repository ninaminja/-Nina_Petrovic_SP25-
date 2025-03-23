SELECT a.actor_id, a.first_name, a.last_name,
MAX (f2.release_year - f1.release_year) AS longest_gap
FROM public.actor a
RIGHT JOIN public.film_actor fa1 ON a.actor_id = fa1.actor_id
RIGHT JOIN public.film f1 ON fa1.film_id = f1.film_id
RIGHT JOIN public.film_actor fa2 ON a.actor_id = fa2.actor_id
RIGHT JOIN public.film f2 ON fa2.film_id = f2.film_id
WHERE f2.release_year > f1.release_year
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY longest_gap;