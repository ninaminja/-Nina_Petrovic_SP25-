--this query will add films to film table, special part 'where not exists' will not add these movies if they're
--already here. Maybe bad part of this query is fact that we must rewrite this for each movie

INSERT INTO film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update)
SELECT 
    'The Matrix',
    'A computer hacker learns about the true nature of reality',
    1999,
    (SELECT language_id FROM language WHERE name = 'English' LIMIT 1),
    21,  -- rental duration (weeks)
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
    14,  -- rental duration (weeks)
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
    7,  -- rental duration (weeks)
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
WHERE NOT EXISTS (
    SELECT 1 FROM actor 
    WHERE actor.first_name = actor_data.first_name 
    AND actor.last_name = actor_data.last_name
);

--this query will combine table film_actor, so each actor is related to film they're playing in 
--i changed this query so it's not hardcoded
--last part 'not exists' will check if there is already pair like we want to insert, if there is not, insert will happen
--at last query will return actor_id and film_id, what we needed

INSERT INTO film_actor (actor_id, film_id, last_update)
SELECT 
    a.actor_id,
    f.film_id,
    CURRENT_DATE
FROM (
    VALUES
        ('Keanu', 'Reeves', 'The Matrix'),
        ('Laurence', 'Fishburne', 'The Matrix'),
        ('Carrie-Anne', 'Moss', 'The Matrix'),
        ('John David', 'Washington', 'Tenet'),
        ('Robert', 'Pattinson', 'Tenet'),
        ('Song', 'Kang-ho', 'Parasite'),
        ('Choi', 'Woo-shik', 'Parasite'),
        ('Park', 'So-dam', 'Parasite')
) AS casting_data(first_name, last_name, film_title)
JOIN actor a ON a.first_name = casting_data.first_name 
            AND a.last_name = casting_data.last_name
JOIN film f ON f.title = casting_data.film_title
WHERE NOT EXISTS (
    SELECT 1 FROM film_actor fa 
    WHERE fa.actor_id = a.actor_id 
    AND fa.film_id = f.film_id
)
RETURNING actor_id, film_id;

--this query will add films to the store
--i tried this function to get random store 

INSERT INTO inventory (film_id, store_id)
SELECT 
    f.film_id,
    (1 + FLOOR(RANDOM() * 2))::INT AS store_id  -- Randomly selects store 1 or 2
FROM (
    VALUES
        ('The Matrix'),
        ('Tenet'),
        ('Parasite')
) AS film_titles(title)
JOIN film f ON f.title = film_titles.title
WHERE NOT EXISTS (
    SELECT 1 FROM inventory i
    WHERE i.film_id = f.film_id
    AND i.store_id = (1 + FLOOR(RANDOM() * 2))::INT
)
RETURNING film_id, store_id;

--i changed this query so now i will update user who has more than 43 payments and rentals
--address and id of customer are chosed random
--i've put limit 1 because i want only 1 customer to be updated
    
UPDATE customer c
SET 
    first_name = 'Nina',
    last_name = 'Petrovic',
    email = 'culibrkminja@gmail.com',
    address_id = (
        SELECT address_id 
        FROM address 
        ORDER BY RANDOM() 
        LIMIT 1  -- Random address
    )
    WHERE c.customer_id IN (
    SELECT p.customer_id
    FROM payment p
    GROUP BY p.customer_id
    HAVING COUNT(p.payment_id) > 43
    INTERSECT  -- Ensures BOTH conditions are met
    SELECT r.customer_id
    FROM rental r
    GROUP BY r.customer_id
    HAVING COUNT(r.rental_id) > 43
)
LIMIT 1
RETURNING *;

--in this query i deleted records and payments, so after this it's 0
BEGIN
DELETE FROM payment 
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Nina' AND last_name = 'Petrovic')
RETURNING payment_id, amount, payment_date;
DELETE FROM rental 
WHERE customer_id = (SELECT customer_id FROM customer WHERE first_name = 'Nina' AND last_name = 'Petrovic')
RETURNING rental_id, inventory_id, rental_date
COMMIT;

--now, with this query i will make reservation to the film but it's not paid yet
--we will insert into table rental so there we have information about films that we rented 
--current date is because we want to use today's date
--part 'where' is to make sure which film we want to rent, so we can type title of film 
--and part 'select customer' is to make sure we rent this films on our name, subquery will help in this because we can select customer and staff as well with rental_date, inventory_id, customer and staff id
--I added part staff id to fix my mistake because i didn't connect staff_id and film_id, now staff_id is working at the same store where film_id is 
--I added return date too, now customer has 5 days to retrun film
INSERT INTO rental (rental_date, inventory_id, customer_id, staff_id, return_date)
SELECT 
    CURRENT_DATE, 
    i.inventory_id, 
    (SELECT customer_id FROM customer WHERE first_name = 'Nina' AND last_name = 'Petrovic'),
    (SELECT staff_id FROM staff s WHERE s.store_id = i.store_id LIMIT 1),
    CURRENT_DATE + INTERVAL '5 days'
FROM inventory i
WHERE i.film_id = (SELECT film_id FROM film WHERE title ='Tenet' LIMIT 1)
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
--I fixed my mistake because last code was hardcoded; i tried in this first part to specify which customer is paying 
--there, i added actual_duration because i needed that for calculating actual price 
--so, in part 'CASE' there is all logic, when film is returned in time or earlier, price is standard with added cost of 1 dollar per day
--if it's returned late, then it's base cost and plus penatility for extra days, i've put 10% of film's replacement_cost, so this will be added on price if customer is late 

WITH latest_rental AS (
    SELECT 
        r.rental_id, 
        r.customer_id, 
        f.rental_duration, 
        COALESCE(DATE_PART('day', r.return_date - r.rental_date), f.rental_duration) AS actual_duration,
        f.replacement_cost
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    WHERE r.customer_id = (
        SELECT customer_id 
        FROM customer 
        WHERE first_name = 'Nina' AND last_name = 'Petrovic'
    )
    ORDER BY r.rental_date DESC
    LIMIT 1
)
INSERT INTO payment (
    customer_id,
    staff_id,
    rental_id,
    amount,
    payment_date
)
SELECT 
    lr.customer_id,          
    (SELECT staff_id FROM staff LIMIT 1),
    lr.rental_id,
    CASE 
        WHEN lr.actual_duration <= lr.rental_duration THEN lr.rental_duration * 1.0
        ELSE (lr.rental_duration * 1.0) + ((lr.actual_duration - lr.rental_duration) * (lr.replacement_cost * 0.1))
    END AS amount,
    CURRENT_DATE
FROM latest_rental lr      
RETURNING *;

--this is also not necessary but with this query we will check if payment is valid

SELECT * FROM payment 
WHERE rental_id = (SELECT rental_id FROM rental 
                  WHERE customer_id = (SELECT customer_id FROM customer 
                                     WHERE first_name = 'Nina' AND last_name = 'Petrovic')
                  ORDER BY rental_date DESC
                  LIMIT 1);




