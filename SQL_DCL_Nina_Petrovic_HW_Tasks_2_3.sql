--Task 2. Implement role-based authentication model for dvd_rental database

--1.Create a new user with the username "rentaluser" and the password "rentalpassword". Give the user the ability 
--to connect to the database but no other permissions.

--here i made rentaluser with specific password
CREATE USER rentaluser WITH PASSWORD 'rentalpassword';

--here i have connect to database premission but nothing else besides that
GRANT CONNECT ON DATABASE your_database_name TO rentaluser;

--2.Grant "rentaluser" SELECT permission for the "customer" table. Сheck to make sure this 
--permission works correctly—write a SQL query to select all customers.

--here i granted select premission for customer table to rentaluser
GRANT SELECT ON customer TO rentaluser;

--first I need to switch to rentaluser
SET ROLE rentaluser;

--we will check if current user is rentaluser
SELECT current_user;

--we will try to select everything from customer table, it works (there is 599 rows)
SELECT * FROM customer;

--3.Create a new user group called "rental" and add "rentaluser" to the group. 
--first we need to get back to previous user (postgres) because if we stay in rentaluser we can't do this, we don't have premission
SET ROLE postgres;

--we are creating role 
CREATE ROLE rental;

--and adding rentaluser to it 
GRANT rental TO rentaluser;

--4. Grant the "rental" group INSERT and UPDATE permissions for the "rental" table. Insert a new row and update one
-- existing row in the "rental" table under that role. 

--granting INSERT and UPDATE to rental group on rental table
GRANT INSERT ON rental TO rental;
GRANT UPDATE ON rental TO rental;

--testing this as rentaluser 
SET ROLE rental;


--i tried to insert but i got mistake, after research i fonud out i must use USAGE: 
GRANT USAGE, SELECT ON SEQUENCE rental_rental_id_seq TO rental;

--i tried to insert without hardcoding but i don't have premission for inventory table so i did it this way: 
INSERT INTO rental (
    rental_date,
    inventory_id,
    customer_id,
    return_date,
    staff_id,
    last_update
)
VALUES (
    CURRENT_TIMESTAMP,
    1525,
    (SELECT customer_id FROM customer LIMIT 1),
    CURRENT_TIMESTAMP + INTERVAL '3 days',
    1,
    CURRENT_TIMESTAMP
);


--this is update query: 
UPDATE rental
SET return_date = CURRENT_TIMESTAMP,
    last_update = CURRENT_TIMESTAMP
WHERE rental_id = (
    SELECT MAX(rental_id) FROM rental
);


--this is to check if everything is correct
SELECT * FROM rental ORDER BY rental_id DESC LIMIT 1;

--5. Revoke the "rental" group's INSERT permission for the "rental" table. 
--Try to insert new rows into the "rental" table make sure this action is denied.

--first i got back on postgres role, then used this query to revoke insert and got back in rental role 
--when i use same code for insert i get error : SQL Error [42501]: ERROR: permission denied for table rental
REVOKE INSERT ON rental FROM rental;

--6.Create a personalized role for any customer already existing in the dvd_rental database. 
--The name of the role name must be client_{first_name}_{last_name} (omit curly brackets). 
--The customer's payment and rental history must not be empty. 

--first i will find customer who has everything needed( in my case this is tommy collazo)
SELECT c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
JOIN rental r ON c.customer_id = r.customer_id
LIMIT 1;

--with this way i'll check if everything is here
SELECT * FROM customer c 
JOIN payment p ON c.customer_id  = p.customer_id
WHERE c.first_name = 'Tommy'

--creating role for tommy
CREATE ROLE client_Tommy_Collazo;

--giving premissions
GRANT SELECT ON customer TO client_Tommy_Collazo;
GRANT SELECT ON rental TO client_Tommy_Collazo;
GRANT SELECT ON payment TO client_Tommy_Collazo;




--Task 3. Implement row-level security
--Configure that role so that the customer can only access their own data in the "rental" and "payment" tables. 
--Write a query to make sure this user sees only their own data.

--enabling RLS on the tables
ALTER TABLE rental ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;

--creating one generic customer role
CREATE ROLE customer_role;
GRANT CONNECT ON DATABASE dvdrental TO customer_role;
GRANT SELECT ON rental, payment, customer TO customer_role;

--creating a simple policy function
CREATE OR REPLACE FUNCTION current_customer_id()
RETURNS integer AS $$
BEGIN
    -- This assumes application sets a session variable
    RETURN current_setting('app.current_customer_id')::integer;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL; -- no access if not set
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

--creating RLS policies for payment and rental
CREATE POLICY customer_rental_access ON rental
    FOR SELECT TO customer_role
    USING (customer_id = current_customer_id());

CREATE POLICY customer_payment_access ON payment
    FOR SELECT TO customer_role
    USING (customer_id = current_customer_id());

--setting the customer ID for the session (maybe this is not the best way because we have to type exact ID but i didn't find any other way...)
SET app.current_customer_id = '459'; 

--switching to customer role
SET ROLE customer_role;

--now customer can only see their own data
SELECT * FROM rental; 
SELECT * FROM payment; 






