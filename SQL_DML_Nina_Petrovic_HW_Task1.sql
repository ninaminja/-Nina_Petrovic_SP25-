--this query will add films to film table, special part 'where not exists' will not add these movies if they're
--already here. Maybe bad part of this query is fact that we must rewrite this for each movie

INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update)
SELECT 
    'The Matrix',
    'A computer hacker learns about the true nature of reality',
    1999,
    (SELECT language_id FROM language WHERE name = 'English' LIMIT 1),
    3,  -- rental duration (weeks)
    4.99,  -- rental rate
    136,  -- length (minutes)
    19.99,  -- replacement cost
    'R',
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'The Matrix');

INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update)
SELECT 
    'Tenet',
    'A secret agent learns to manipulate time',
    2020,
    (SELECT language_id FROM language WHERE name = 'English' LIMIT 1),
    2,  -- rental duration (weeks)
    9.99,  -- rental rate
    150,  -- length (minutes)
    24.99,  -- replacement cost
    'PG-13',
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'Tenet');

INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update)
SELECT 
    'Parasite',
    'A poor family infiltrates a wealthy household',
    2019,
    (SELECT language_id FROM language WHERE name = 'English' LIMIT 1),
    1,  -- rental duration (weeks)
    19.99,  -- rental rate
    132,  -- length (minutes)
    21.99,  -- replacement cost
    'R',
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (SELECT 1 FROM film WHERE title = 'Parasite');


--this query will add all actors in actor table. I tried to do this with insert into, I wrote all imporant parts
--of actor table and from is to write values for each actor

INSERT INTO actor (first_name, last_name, last_update)
    SELECT first_name, last_name, CURRENT_DATE
    FROM (VALUES
        ('Keanu','Reeves'),
        ('Laurence','Fishburne'),
        ('Carrie-Anne','Moss'),
        ('John David','Washington'),
        ('Robert','Pattinson'),
        ('Song','Kang-ho'),
        ('Choi','Woo-shik'),
        ('Park','So-dam')
)AS actor_data(first_name, last_name)

--this query will combine table film_actor, so each actor is related to film they're playing in 
--last part 'not exists' will check if there is already pair like we want to insert, if there is not, insert will happen
--at last query will return actor_id and film_id, what we needed

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT 
    actor_id,
    film_id,
    CURRENT_DATE
FROM (
    VALUES
    	--the Matrix
        (261, 1038), -- Keanu Reeves
        (262, 1038), -- Laurence Fishburne
        (263, 1038), -- Carrie-Anne Moss
         -- Tenet
        (264, 1040), -- John David Washington
        (265, 1040), -- Robert Pattinson
          -- Parasite 
        (266, 1041), -- Song Kang-ho
        (267, 1041), -- Choi Woo-shik
        (268, 1041)  -- Park So-dam
) AS new_relations(actor_id, film_id)
WHERE NOT EXISTS (
    SELECT 1 FROM film_actor fa 
    WHERE fa.actor_id = new_relations.actor_id 
    AND fa.film_id = new_relations.film_id
)
RETURNING actor_id, film_id;

--this query will add films to the store, i chose only 1st store to put all three movies in there

INSERT INTO inventory (film_id, store_id)
VALUES 
		(1038,1),
		(1040,1),
		(1041,1);
		
--next part is to change existing customer who has more than 43 rental and payment records. first i found this customer with this query

SELECT c.customer_id
    FROM customer c
    JOIN rental r ON c.customer_id = r.customer_id
    JOIN payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(DISTINCT r.rental_id) >= 43 AND COUNT(DISTINCT p.payment_id) >= 43
    LIMIT 1
    
-- after that I updated it to my informations. id of customer was 148, that's why I've put 148 here 
    
UPDATE customer c
SET 
	first_name='Nina',
	last_name='Petrovic',
	email='culibrkminja@gmail.com',
	address_id=258
WHERE c.customer_id= 148;

--in this query i deleted records and payments, so after this it's 0

DELETE FROM payment 
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Nina' AND last_name = 'Petrovic')
RETURNING payment_id, amount, payment_date;
DELETE FROM rental 
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Nina' AND last_name = 'Petrovic')
RETURNING rental_id, inventory_id, rental_date;

--now, with this query i will make reservation to the film but it's not paid yet
--we will insert into table rental so there we have information about films that we rented 
--current date is because we want to use today's date
--part 'where' is to make sure which film we want to rent, so we can type title of film 
--and part 'select customer' is to make sure we rent this films on our name, subquery will help in this because we can select customer and staff as well with rental_date, inventory_id, customer and staff id

INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id)
SELECT CURRENT_DATE, inventory_id, 
       (SELECT customer_id FROM customer WHERE first_name = 'Nina' AND last_name = 'Petrovic'),
       (SELECT staff_id FROM staff LIMIT 1)
FROM inventory
WHERE film_id IN (SELECT film_id FROM film WHERE title = 'The Matrix')
LIMIT 1
RETURNING *;

--this part is not necessary but i check if rental is okay made with this query

SELECT 
    r.rental_id,
    f.title AS film,
    r.rental_date,
    r.return_date,
    p.payment_id
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
LEFT JOIN payment p ON r.rental_id = p.rental_id
WHERE r.customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Nina' AND last_name = 'Petrovic')
AND p.payment_id IS NULL;  

--in this part we will pay for rented films 
--i used begin and commit for successful outcome. First i stardet with insert into table 'payment', after that
--I will specify what rental and customer is in question. This query will do in pricipe 'latest rental' so we don't have to specify id of rental film
--returning is eith * because we want to see all informations
--price and date will be changed based on movie

BEGIN;
    INSERT INTO payment (
        customer_id,
        staff_id,
        rental_id,
        amount,
        payment_date
    )
    WITH latest_rental AS (
        SELECT rental_id, customer_id
        FROM rental
        WHERE customer_id = (SELECT customer_id FROM customer 
                            WHERE first_name = 'Nina' AND last_name = 'Petrovic')
        ORDER BY rental_date DESC
        LIMIT 1
    )
    SELECT 
        lr.customer_id,          
        (SELECT staff_id FROM staff LIMIT 1),
        lr.rental_id,
        4.99,
        '2017-02-15'
    FROM latest_rental lr      
    RETURNING *;
COMMIT;

--this is also not necessary but with this query we will check if payment is valid

SELECT * FROM payment 
WHERE rental_id = (SELECT rental_id FROM rental 
                  WHERE customer_id = (SELECT customer_id FROM customer 
                                     WHERE first_name = 'Nina' AND last_name = 'Petrovic')
                  ORDER BY rental_date DESC
                  LIMIT 1);




