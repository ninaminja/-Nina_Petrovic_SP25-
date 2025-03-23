SELECT CONCAT (address.address, '',address.address2,'') AS full_adress,
SUM(p.amount) AS revenue
FROM public.store s
INNER JOIN public.address ON s.address_id = address.address_id
INNER JOIN public.inventory i ON s.store_id = i. store_id
INNER JOIN public.rental r ON i. inventory_id = r. inventory_id
INNER JOIN public.payment p ON r.rental_id = p.rental_id
WHERE r.rental_date > '2017-03-31'
AND s.store_id IN (
SELECT DISTINCT s2. store_id
FROM public.store s2
INNER JOIN public.inventory i2 ON s2.store_id = i2.store_id
INNER JOIN public.rental r2 ON i2.inventory_id = r2.inventory_id
WHERE r.rental_date > '2017-03-31')
GROUP BY full_adress
ORDER BY revenue DESC;