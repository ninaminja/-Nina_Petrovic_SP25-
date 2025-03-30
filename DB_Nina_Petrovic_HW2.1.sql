WITH staff_revenue AS (
SELECT s.staff_id, s.first_name, s.last_name, s2.store_id,
SUM (p.amount) As total_ravenue
FROM staff s
INNER JOIN public.payment p ON s.staff_id = p.staff_id
INNER JOIN public.store s2 ON s2.store_id =s2.store_id
WHERE EXTRACT (YEAR FROM p.payment_date) = 2017
GROUP BY s.staff_id, s.first_name, s.Last_name, s2.store_id)
SELECT sr.staff_id, sr.first_name, sr.last_name, sr.store_id, sr.total_ravenue
FROM staff_revenue sr
ORDER BY sr.total_ravenue
LIMIT 3;