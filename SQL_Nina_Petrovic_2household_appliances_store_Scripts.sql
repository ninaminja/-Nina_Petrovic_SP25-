
-- Create a physical 
--database with a separate database and schema and give it an appropriate domain-related name. 

--I fixed this part and added DELETE IF EXISTS for everything needed

DROP VIEW IF EXISTS simple_quarterly_analytics CASCADE;

DROP FUNCTION IF EXISTS update_product();
DROP FUNCTION IF EXISTS add_payment functuins();

DROP TABLE IF EXISTS stock CASCADE;
DROP TABLE IF EXISTS procurement_order CASCADE;
DROP TABLE IF EXISTS payment CASCADE;
DROP TABLE IF EXISTS order_product CASCADE;
DROP TABLE IF EXISTS ordered CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP TABLE IF EXISTS employee CASCADE;
DROP TABLE IF EXISTS category CASCADE;
DROP TABLE IF EXISTS supplier CASCADE;
DROP TABLE IF EXISTS customer CASCADE;


-- Drop role and its owned objects safely
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'manager_role') THEN
        EXECUTE 'DROP OWNED BY manager_role';
        EXECUTE 'DROP ROLE manager_role';
    END IF;
END
$$;

DROP VIEW IF EXISTS simple_quarterly_analytics CASCADE;

DROP SCHEMA IF EXISTS home_products CASCADE;

BEGIN;

CREATE DATABASE household_appliances_store;

CREATE SCHEMA IF NOT EXISTS home_products;

-- 1. Customer table
CREATE TABLE IF NOT EXISTS customer(
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    full_name_customer VARCHAR(100) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(255) NOT NULL,
    address VARCHAR(255) NOT null,
     CONSTRAINT customer_email_unique UNIQUE(email)
);

-- 2. Supplier table
CREATE TABLE IF NOT EXISTS supplier(
    supplier_id SERIAL PRIMARY KEY,
    company_name VARCHAR(255) NOT NULL,
    contact_name VARCHAR(255) NOT NULL,
    phone VARCHAR(255) NOT NULL,
    full_supplier_info VARCHAR(100) GENERATED ALWAYS AS (contact_name || ' ' || phone) STORED,
    email VARCHAR(255) NOT NULL
);

-- 3. Category table
CREATE TABLE IF NOT EXISTS category(
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL,
    "size" VARCHAR(50) NOT NULL DEFAULT 'Undefined' CHECK (size IN ('Small', 'Big')),
    description TEXT NOT NULL
);

-- 4. Employee table
CREATE TABLE IF NOT EXISTS employee(
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
  	full_name_employee VARCHAR(100) GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,
    email VARCHAR(255) NOT NULL,
    position VARCHAR(255) NOT NULL
);

-- 5. Product table
CREATE TABLE IF NOT EXISTS product(
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(255) NOT NULL,
    model VARCHAR(255) NOT NULL,
    full_info_product VARCHAR(100) GENERATED ALWAYS AS (name || ' ' || brand || ' ' || model) STORED,
    price DECIMAL(8,2) NOT NULL CHECK (price > 0),
    stock_quantity INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    supplier_id INTEGER NOT NULL
);

-- 6. Ordered table (I fixed this part and added total_price directly in CREATE TABLE)
CREATE TABLE IF NOT EXISTS ordered(
    order_id SERIAL PRIMARY KEY,
    order_date DATE NOT NULL,
    customer_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    status VARCHAR(50) NOT NULL
    total_price DECIMAL(8,2) NOT NULL
);

-- 7. Order_Product table
CREATE TABLE IF NOT EXISTS order_product(
    order_product_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    amount DECIMAL(8,2) NOT NULL
);

-- 8. Payment table
CREATE TABLE IF NOT EXISTS payment(
    payment_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    payment_date DATE NOT NULL,
    amount_paid DECIMAL(8,2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_status VARCHAR(50) NOT NULL
);

-- 9. Procurement Order table
CREATE TABLE IF NOT EXISTS procurement_order(
    purchase_id SERIAL PRIMARY KEY,
    supplier_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity_ordered INTEGER NOT NULL,
    order_date DATE NOT NULL,
    delivery_date DATE NOT NULL
);

-- 10. Stock table
CREATE TABLE IF NOT EXISTS stock(
    stock_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    date_movement DATE NOT NULL,
    movement_type VARCHAR(50) NOT NULL,
    quantity_in INTEGER NOT NULL,
    quantity_out INTEGER NOT NULL
);

COMMIT;



--Use ALTER TABLE to add at least 5 check constraints across the tables to restrict certain values, as example 
--date to be inserted, which must be greater than January 1, 2024
--inserted measured value that cannot be negative
--inserted value that can only be a specific value
--unique
--not null

--alert table to add FK keys to order_produc table 
BEGIN;
ALTER TABLE IF EXISTS order_product
    ADD CONSTRAINT  order_product_product_id_fk FOREIGN KEY ("product_id") REFERENCES product("product_id");

ALTER TABLE IF EXISTS order_product
    ADD CONSTRAINT order_product_order_id_fk FOREIGN KEY ("order_id") REFERENCES "ordered"("order_id");

-- FKs to ordered table
ALTER TABLE  IF EXISTS ordered
    ADD CONSTRAINT order_customer_id_fk FOREIGN KEY ("customer_id") REFERENCES customer("customer_id");

ALTER TABLE IF EXISTS ordered
    ADD CONSTRAINT order_employee_id_fk FOREIGN KEY ("employee_id") REFERENCES employee("employee_id");

--FKs to profuct table 
ALTER TABLE IF EXISTS product
    ADD CONSTRAINT product_supplier_id_fk FOREIGN KEY ("supplier_id") REFERENCES supplier("supplier_id");

ALTER TABLE IF EXISTS product
    ADD CONSTRAINT product_category_id_fk FOREIGN KEY ("category_id") REFERENCES category("category_id");
--Fk to procurment_order
ALTER TABLE IF EXISTS procurement_order
    ADD CONSTRAINT procurement_order_supplier_id_fk FOREIGN KEY ("supplier_id") REFERENCES supplier("supplier_id");

ALTER TABLE IF EXISTS procurement_order
    ADD CONSTRAINT procurement_order_product_id_fk FOREIGN KEY ("product_id") REFERENCES product("product_id");

--FK to payment table 
ALTER TABLE IF EXISTS payment
    ADD CONSTRAINT payment_order_id_fk FOREIGN KEY ("order_id") REFERENCES "ordered"("order_id");
--Fk to stock
ALTER TABLE IF EXISTS stock
    ADD CONSTRAINT stock_product_id_fk FOREIGN KEY ("product_id") REFERENCES product("product_id");



--adding CHECK alters 

--number of products in stock must not be negative
ALTER TABLE IF EXISTS product
    ADD CONSTRAINT chk_product_stock_nonnegative
CHECK (stock_quantity >= 0);


ALTER TABLE IF EXISTS order_product
    ADD CONSTRAINT chk_order_product_nonnegative
CHECK (quantity >= 0);

ALTER TABLE IF EXISTS procurement_order
    ADD CONSTRAINT chk_procurement_quantity_positive
CHECK (quantity_ordered > 0);

--adding CHECK alter for date that must be after 01.01.2024

ALTER TABLE IF EXISTS ordered
    ADD CONSTRAINT chk_order_date_after_2024 CHECK (order_date > '2024-01-01');

ALTER TABLE IF EXISTS payment
    ADD CONSTRAINT chk_payment_date_after_2024 CHECK (payment_date > '2024-01-01');

ALTER TABLE IF EXISTS procurement_order
    ADD CONSTRAINT chk_procurement_order_date_after_2024 CHECK (order_date > '2024-01-01');


ALTER TABLE IF EXISTS procurement_order
    ADD CONSTRAINT chk_procurement_delivery_date_after_2024 CHECK (delivery_date > '2024-01-01');

ALTER TABLE IF EXISTS stock
    ADD CONSTRAINT chk_stock_date_movement_after_2024 CHECK (date_movement > '2024-01-01');

--payment must be positive

ALTER TABLE IF EXISTS payment
    ADD CONSTRAINT chk_payment_amount_positive CHECK (amount_paid >= 0);


--we precise status of our order here
ALTER TABLE IF EXISTS ordered
    ADD CONSTRAINT chk_order_status_valid CHECK (status IN ('Pending', 'Completed', 'Cancelled'));

-- this check is for type of payment that customer will use 
ALTER TABLE IF EXISTS payment
    ADD CONSTRAINT chk_payment_method_valid CHECK (payment_method IN ('Cash', 'Card'));


--we'll set default status for payment 
ALTER TABLE IF EXISTS payment
    ALTER COLUMN payment_status SET DEFAULT 'Pending';
-- we follow status of payment through this check 
ALTER TABLE IF EXISTS payment
    ADD CONSTRAINT chk_payment_status_valid CHECK (payment_status IN ('Paid', 'Pending', 'Failed'));

-- we must know when some product is in or out of magacine 
ALTER TABLE IF EXISTS stock
    ADD CONSTRAINT chk_stock_movement_type_valid CHECK (movement_type IN ('In', 'Out'));

--quantity of products at stock must always be positive
ALTER TABLE IF EXISTS stock
    ADD CONSTRAINT chk_quantity_in_nonnegative CHECK (quantity_in >= 0);

ALTER TABLE IF EXISTS stock
    ADD CONSTRAINT chk_quantity_out_nonnegative CHECK (quantity_out >= 0);


--adding UNIQUE constraints to table

ALTER TABLE supplier
    ADD CONSTRAINT uq_supplier_email UNIQUE (email);

ALTER TABLE supplier
    ADD CONSTRAINT uq_supplier_phone UNIQUE (phone);

ALTER TABLE customer 
		ADD CONSTRAINT uq_customer_phone UNIQUE (phone);

ALTER TABLE employee 
		ADD CONSTRAINT uq_employee_email UNIQUE (email);

ALTER TABLE category
ADD CONSTRAINT uq_category_name UNIQUE (category_name);

ALTER TABLE product
ADD CONSTRAINT uq_product_name UNIQUE (name);


COMMIT;


--4. Populate the tables with the sample data generated, ensuring each table has at least 6+ rows (for a total of 36+ rows in all the tables) for the last 3 months.
--Create DML scripts for insert your data. 
--Ensure that the DML scripts do not include values for surrogate keys, as these keys should be generated by the database during runtime. 
--Also, ensure that any DEFAULT values required are specified appropriately in the DML scripts. 
--These DML scripts should be designed to successfully adhere to all previously defined constraints


--here is insert for customer table
INSERT INTO customer (first_name, last_name, email, phone, address)
VALUES
    ('Anna', 'Smith', 'anna.smith@email.com', '555-1234', '123 King Street, London'),
    ('Michael', 'Johnson', 'michael.johnson@email.com', '555-2345', '456 Queen Road, Manchester'),
    ('Olivia', 'Brown', 'olivia.brown@email.com', '555-3456', '789 Prince Avenue, Birmingham'),
    ('James', 'Taylor', 'james.taylor@email.com', '555-4567', '101 Duke Lane, Leeds'),
    ('Emily', 'Wilson', 'emily.wilson@email.com', '555-5678', '202 Earl Street, Liverpool'),
    ('William', 'Moore', 'william.moore@email.com', '555-6789', '303 Baron Street, Bristol')
ON CONFLICT (email) DO NOTHING;

--supplier table inserts
INSERT INTO supplier (company_name, contact_name, phone, email)
VALUES
    ('ElectroMax Ltd.', 'Peter Green', '020-111-2345', 'peter.green@electromax.com'),
    ('FurniCo', 'Emma White', '020-222-3456', 'emma.white@furnico.com'),
    ('KitchenKing', 'Alexander Black', '020-333-4567', 'alex.black@kitchenking.com'),
    ('GardenStyle', 'Sophia Miller', '020-444-5678', 'sophia.miller@gardenstyle.com'),
    ('OfficePro', 'Liam Davis', '020-555-6789', 'liam.davis@officepro.com'),
    ('HouseHold Goods', 'Isabella Clark', '020-666-7890', 'isabella.clark@household.com')
ON CONFLICT (email) DO NOTHING;

--category table inserts
INSERT INTO category (category_name, size, description)
VALUES
    ('Electronics', 'Small', 'Electronic devices and gadgets'),
    ('Furniture', 'Big', 'Furniture for homes and offices'),
    ('Kitchenware', 'Small', 'Appliances and kitchen utensils'),
    ('Garden', 'Big', 'Garden tools and furniture'),
    ('Office Supplies', 'Small', 'Office materials and equipment'),
    ('Home Decor', 'Small', 'Decorative items for homes')
ON CONFLICT (category_name) DO NOTHING;

--employee table insert
INSERT INTO employee (first_name, last_name, email, position)
VALUES
    ('Sarah', 'Evans', 'sarah.evans@email.com', 'Sales Manager'),
    ('Marco', 'Hindo', 'marco1hidno@email.com', 'Deliverer'),
    ('David', 'Smith', 'david.s@email.com', 'Deliverer'),
    ('David', 'Walker', 'david.walker@email.com', 'Customer Support Agent'),
    ('Jessica', 'Robinson', 'jessica.robinson@email.com', 'Warehouse Associate'),
    ('Daniel', 'Hall', 'daniel.hall@email.com', 'Accountant'),
    ('Mia', 'Young', 'mia.young@email.com', 'Marketing Specialist'),
    ('Matthew', 'Allen', 'matthew.allen@email.com', 'Logistics Coordinator')
ON CONFLICT (email) DO NOTHING;

--product, I didn't hardcode IDs of company name and category
INSERT INTO product (name, brand, model, price, stock_quantity, category_id, supplier_id)
SELECT 
    'Refrigerator', 'Samsung', 'RT29K5030S8', 599.99, 20, c.category_id, s.supplier_id
FROM category c
JOIN supplier s ON s.company_name  = 'HouseHold Goods'
WHERE c.category_name = 'Electronics'
ON CONFLICT (name)DO NOTHING;

INSERT INTO product (name, brand, model, price, stock_quantity, category_id, supplier_id)
SELECT 
    'Microwave Oven', 'Panasonic', 'NN-SN966S', 199.99, 25, c.category_id, s.supplier_id
FROM category c
JOIN supplier s ON s.company_name  = 'ElectroMax Ltd.'
WHERE c.category_name = 'Kitchenware'
ON CONFLICT (name)DO NOTHING;

INSERT INTO product (name, brand, model, price, stock_quantity, category_id, supplier_id)
SELECT 
    'Vacuum Cleaner', 'Dyson', 'V11 Torque Drive', 599.99, 30, c.category_id, s.supplier_id
FROM category c
JOIN supplier s ON s.company_name = 'HouseHold Goods'
WHERE c.category_name = 'Electronics'
ON CONFLICT (name)DO NOTHING;

INSERT INTO product (name, brand, model, price, stock_quantity, category_id, supplier_id)
SELECT 
    'Blender', 'Philips', 'HR3652/00', 129.99, 40, c.category_id, s.supplier_id
FROM category c
JOIN supplier s ON s.company_name  = 'OfficePro'
WHERE c.category_name = 'Office Supplies'
ON CONFLICT (name) DO NOTHING;


INSERT INTO product (name, brand, model, price, stock_quantity, supplier_id, category_id)
SELECT 'Garden Table Set', 'Madamehome', 'NU-725774', 499.99, 15, s.supplier_id, c.category_id
FROM category c 
JOIN supplier s ON s.company_name = 'GardenStyle'
WHERE c.category_name = 'Garden'
ON CONFLICT (name) DO NOTHING;

INSERT INTO product (name, brand, model, price, stock_quantity, supplier_id, category_id)
SELECT 'Wall Painting', 'Artsy','photo-731', 299.99, 25, s.supplier_id, c.category_id
FROM category c 
JOIN supplier s ON s.company_name = 'HouseHold Goods'
WHERE c.category_name = 'Home Decor'
ON CONFLICT (name) DO NOTHING;


--order table insert, again, i tried not to hardcode values for customer and employee (in this case it's delivery man who is employeer)

INSERT INTO ordered (order_date, status, customer_id, employee_id, total_price)
SELECT '2025-02-01', 'Completed', c.customer_id, e.employee_id, 567.33
FROM customer c
JOIN employee e ON e.email = 'david.s@email.com'
WHERE c.email = 'anna.smith@email.com'
ON CONFLICT DO NOTHING;

INSERT INTO ordered (order_date, status, customer_id, employee_id, total_price)
SELECT '2025-03-10', 'Pending', c.customer_id, e.employee_id,6533
FROM customer c
JOIN employee e ON e.email = 'david.s@email.com'
WHERE c.email = 'michael.johnson@email.com'
ON CONFLICT DO NOTHING;

INSERT INTO ordered (order_date, status, customer_id, employee_id,total_price)
SELECT '2025-03-15', 'Cancelled', c.customer_id,e.employee_id ,255.98
FROM customer c
JOIN employee e ON e.email = 'marco1hidno@email.com'
WHERE c.email = 'olivia.brown@email.com'
ON CONFLICT DO NOTHING;

INSERT INTO ordered (order_date, status, customer_id, employee_id,total_price)
SELECT '2025-04-05', 'Pending', c.customer_id, e.employee_id,865.24
FROM customer c
JOIN employee e ON e.email = 'marco1hidno@email.com'
WHERE c.email = 'james.taylor@email.com'
ON CONFLICT DO NOTHING;

INSERT INTO ordered (order_date, status, customer_id, employee_id,total_price)
SELECT '2025-04-12', 'Completed', c.customer_id, e.employee_id,8742.86
FROM customer c
JOIN employee e ON e.email = 'david.s@email.com'
WHERE c.email = 'emily.wilson@email.com'
ON CONFLICT DO NOTHING;

INSERT INTO ordered (order_date, status, customer_id,employee_id,total_price)
SELECT '2025-04-20', 'Cancelled', c.customer_id, e.employee_id,235.64
FROM customer c
JOIN employee e ON e.email = 'marco1hidno@email.com'
WHERE c.email = 'william.moore@email.com'
ON CONFLICT DO NOTHING;

--order_product table 

INSERT INTO order_product (order_id, product_id, quantity, amount)
SELECT o.order_id, p.product_id, 1, o.total_price
FROM ordered o
JOIN product p ON p.model = 'RT29K5030S8'
WHERE o.total_price = 6533
ON CONFLICT DO NOTHING;

INSERT INTO order_product (order_id, product_id, quantity, amount)
SELECT o.order_id, p.product_id, 2, o.total_price
FROM ordered o
JOIN product p ON p.model = 'NN-SN966S'
WHERE o.total_price = 567.33
ON CONFLICT DO NOTHING;

INSERT INTO order_product (order_id, product_id, quantity, amount)
SELECT o.order_id, p.product_id, 6, o.total_price
FROM ordered o
JOIN product p ON p.model = 'V11 Torque Drive'
WHERE o.total_price = 6533
ON CONFLICT DO NOTHING;

INSERT INTO order_product (order_id, product_id, quantity, amount)
SELECT o.order_id, p.product_id, 2, o.total_price
FROM ordered o
JOIN product p ON p.model = 'HR3652/00'
WHERE o.total_price = 255.98
ON CONFLICT DO NOTHING;

INSERT INTO order_product (order_id, product_id, quantity, amount)
SELECT o.order_id, p.product_id, 1, o.total_price
FROM ordered o
JOIN product p ON p.model = 'NU-725774'
WHERE o.total_price = 865.24
ON CONFLICT DO NOTHING;

INSERT INTO order_product (order_id, product_id, quantity, amount)
SELECT o.order_id, p.product_id, 30, o.total_price
FROM ordered o
JOIN product p ON p.model = 'photo-731'
WHERE o.total_price = 8742.86
ON CONFLICT DO NOTHING;


--payment table, i connected customer with correct order from them and where is based on mail from customer

INSERT INTO payment (order_id, payment_date, amount_paid, payment_method, payment_status)
SELECT o.order_id, '2025-02-01', 567.33, 'Card', 'Paid'
FROM ordered o
JOIN customer c ON c.customer_id = o.customer_id
WHERE c.email = 'anna.smith@email.com'
ON CONFLICT DO NOTHING;

INSERT INTO payment (order_id, payment_date, amount_paid, payment_method, payment_status)
SELECT o.order_id, '2025-03-10', 6533, 'Card', 'Pending'
FROM ordered o
JOIN customer c ON c.customer_id = o.customer_id
WHERE c.email = 'michael.johnson@email.com'
ON CONFLICT DO NOTHING;

INSERT INTO payment (order_id, payment_date, amount_paid, payment_method, payment_status)
SELECT o.order_id, '2025-03-15', 400.98, 'Cash', 'Failed'
FROM ordered o
JOIN customer c ON c.customer_id = o.customer_id
WHERE c.email = 'olivia.brown@email.com'
ON CONFLICT DO NOTHING;

INSERT INTO payment (order_id, payment_date, amount_paid, payment_method, payment_status)
SELECT o.order_id, '2025-04-05', 865.24, 'Card', 'Pending'
FROM ordered o
JOIN customer c ON c.customer_id = o.customer_id
WHERE c.email = 'james.taylor@email.com'
ON CONFLICT DO NOTHING;

INSERT INTO payment (order_id, payment_date, amount_paid, payment_method, payment_status)
SELECT o.order_id, '2025-04-12', 8742.86, 'Card', 'Paid'
FROM ordered o
JOIN customer c ON c.customer_id = o.customer_id
WHERE c.email = 'emily.wilson@email.com'
ON CONFLICT DO NOTHING;

INSERT INTO payment (order_id, payment_date, amount_paid, payment_method, payment_status)
SELECT o.order_id, '2025-04-20', 300.64, 'Cash', 'Failed'
FROM ordered o
JOIN customer c ON c.customer_id = o.customer_id
WHERE c.email = 'william.moore@email.com'
ON CONFLICT DO NOTHING;

-- procurement_order table inserts
INSERT INTO procurement_order (supplier_id, product_id, quantity_ordered, order_date, delivery_date)
SELECT s.supplier_id, p.product_id, 50, '2025-01-15', '2025-01-25'
FROM supplier s
JOIN product p ON p.name = 'Refrigerator'
WHERE s.company_name = 'HouseHold Goods'
ON CONFLICT DO NOTHING;

INSERT INTO procurement_order (supplier_id, product_id, quantity_ordered, order_date, delivery_date)
SELECT s.supplier_id, p.product_id, 100, '2025-02-10', '2025-02-20'
FROM supplier s
JOIN product p ON p.name = 'Microwave Oven'
WHERE s.company_name = 'ElectroMax Ltd.'
ON CONFLICT DO NOTHING;

INSERT INTO procurement_order (supplier_id, product_id, quantity_ordered, order_date, delivery_date)
SELECT s.supplier_id, p.product_id, 75, '2025-02-15', '2025-02-25'
FROM supplier s
JOIN product p ON p.name = 'Vacuum Cleaner'
WHERE s.company_name = 'HouseHold Goods'
ON CONFLICT DO NOTHING;

INSERT INTO procurement_order (supplier_id, product_id, quantity_ordered, order_date, delivery_date)
SELECT s.supplier_id, p.product_id, 120, '2025-03-05', '2025-03-15'
FROM supplier s
JOIN product p ON p.name = 'Blender'
WHERE s.company_name = 'OfficePro'
ON CONFLICT DO NOTHING;

INSERT INTO procurement_order (supplier_id, product_id, quantity_ordered, order_date, delivery_date)
SELECT s.supplier_id, p.product_id, 30, '2025-03-20', '2025-03-30'
FROM supplier s
JOIN product p ON p.name = 'Garden Table Set'
WHERE s.company_name = 'GardenStyle'
ON CONFLICT DO NOTHING;

INSERT INTO procurement_order (supplier_id, product_id, quantity_ordered, order_date, delivery_date)
SELECT s.supplier_id, p.product_id, 60, '2025-04-10', '2025-04-20'
FROM supplier s
JOIN product p ON p.name = 'Wall Painting'
WHERE s.company_name = 'HouseHold Goods'
ON CONFLICT DO NOTHING;


-- stock table inserts
INSERT INTO stock (product_id, date_movement, movement_type, quantity_in, quantity_out)
SELECT p.product_id, '2025-01-25', 'In', 50, 30
FROM product p
WHERE p.name = 'Refrigerator'
ON CONFLICT DO NOTHING;

INSERT INTO stock (product_id, date_movement, movement_type, quantity_in, quantity_out)
SELECT p.product_id, '2025-02-20', 'In', 100, 0
FROM product p
WHERE p.name = 'Microwave Oven'
ON CONFLICT DO NOTHING;

INSERT INTO stock (product_id, date_movement, movement_type, quantity_in, quantity_out)
SELECT p.product_id, '2025-02-25', 'In', 75, 10
FROM product p
WHERE p.name = 'Vacuum Cleaner'
ON CONFLICT DO NOTHING;

INSERT INTO stock (product_id, date_movement, movement_type, quantity_in, quantity_out)
SELECT p.product_id, '2025-03-15', 'In', 120, 0
FROM product p
WHERE p.name = 'Blender'
ON CONFLICT DO NOTHING;

INSERT INTO stock (product_id, date_movement, movement_type, quantity_in, quantity_out)
SELECT p.product_id, '2025-03-30', 'In', 30, 0
FROM product p
WHERE p.name = 'Garden Table Set'
ON CONFLICT DO NOTHING;

INSERT INTO stock (product_id, date_movement, movement_type, quantity_in, quantity_out)
SELECT p.product_id, '2025-04-20', 'In', 60, 5
FROM product p
WHERE p.name = 'Wall Painting'
ON CONFLICT DO NOTHING;


--5. Create the following functions.
--5.1 Create a function that updates data in one of your tables. This function should take the following input arguments:
--The primary key value of the row you want to update
--The name of the column you want to update
--The new value you want to set for the specified column

--This function should be designed to modify the specified row in the table, updating the specified column with the new value.

--I tried to update product table here 
CREATE OR REPLACE FUNCTION update_product(
    p_product_id INTEGER,
    p_column_name TEXT,
    p_new_value TEXT
) RETURNS VOID AS $$
BEGIN
    -- Validate the column name
    IF p_column_name NOT IN ('name', 'brand', 'model', 'price', 'stock_quantity', 'category_id', 'supplier_id') THEN
        RAISE EXCEPTION 'Invalid column name for product table: %', p_column_name;
    END IF;
    
    -- Handle numeric columns differently
    IF p_column_name IN ('price', 'stock_quantity', 'category_id', 'supplier_id') THEN
        EXECUTE format('
            UPDATE product 
            SET %I = $1::numeric 
            WHERE product_id = $2', 
            p_column_name)
        USING p_new_value, p_product_id;
    ELSE
        EXECUTE format('
            UPDATE product 
            SET %I = $1 
            WHERE product_id = $2', 
            p_column_name)
        USING p_new_value, p_product_id;
    END IF;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Product with ID % not found', p_product_id;
    END IF;
END;
$$ LANGUAGE plpgsql;

--5.2 Create a function that adds a new transaction to your transaction table. 
--You can define the input arguments and output format. 
--Make sure all transaction attributes can be set with the function (via their natural keys). 
--The function does not need to return a value but should confirm the successful insertion of the new transaction.

CREATE OR REPLACE FUNCTION add_payment(
    p_customer_email TEXT,
    p_employee_email TEXT,
    p_payment_date DATE,
    p_amount_paid DECIMAL(8,2),
    p_payment_method VARCHAR(50),
    p_payment_status VARCHAR(50) DEFAULT 'Pending'
) RETURNS TEXT AS $$
DECLARE
    v_order_id INTEGER;
    v_customer_id INTEGER;
    v_order_exists BOOLEAN;
BEGIN
    -- finding the most recent order for this customer
    SELECT o.order_id, o.customer_id 
    INTO v_order_id, v_customer_id
    FROM ordered o
    JOIN customer c ON o.customer_id = c.customer_id
    WHERE c.email = p_customer_email
    ORDER BY o.order_date DESC
    LIMIT 1;
    
    -- verifying we found an order
    IF v_order_id IS NULL THEN
        RETURN FORMAT('No order found for customer with email: %s', p_customer_email);
    END IF;
    
    -- verifying if employee exists
    PERFORM 1 FROM employee WHERE email = p_employee_email;
    IF NOT FOUND THEN
        RETURN FORMAT('Employee with email %s not found', p_employee_email);
    END IF;
    
    -- inserting the payment
    INSERT INTO payment (
        order_id,
        payment_date,
        amount_paid,
        payment_method,
        payment_status
    ) VALUES (
        v_order_id,
        p_payment_date,
        p_amount_paid,
        p_payment_method,
        p_payment_status
    );
    
    RETURN FORMAT('Successfully added payment of %s for order %s (customer ID: %s)',
                 p_amount_paid, v_order_id, v_customer_id);
EXCEPTION
    WHEN OTHERS THEN
        RETURN FORMAT('Error adding payment: %s', SQLERRM);
END;
$$ LANGUAGE plpgsql;

--and i tried this example : 
SELECT add_payment(
    'anna.smith@email.com',  -- customer email
    'david.s@email.com',     -- employee email
    '2025-05-01',           -- payment date
    199.99,                 -- amount
    'Card',                 -- payment method
    'Paid'                  -- status
);


--6.Create a view that presents analytics for the most recently added quarter in your database. 
--Ensure that the result excludes irrelevant fields such as surrogate keys and duplicate entries.

CREATE OR REPLACE VIEW simple_quarterly_analytics AS
WITH quarter_dates AS (
    SELECT 
        DATE_TRUNC('quarter', CURRENT_DATE) AS quarter_start,
        DATE_TRUNC('quarter', CURRENT_DATE) + INTERVAL '3 months' AS quarter_end
),
current_quarter AS (
    SELECT 
        quarter_start,
        quarter_end,
        TO_CHAR(quarter_start, 'YYYY-Q') AS quarter_name
    FROM quarter_dates
)
SELECT 
    -- Quarter identification
    cq.quarter_name AS quarter,
    
    -- Basic sales metrics
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(op.amount)::numeric, 2) AS total_revenue,
    ROUND(AVG(op.amount)::numeric, 2) AS average_order_value,
    
    -- Customer metrics
    COUNT(DISTINCT c.customer_id) AS active_customers,
    
    -- Product metrics
    (SELECT name FROM product p
     JOIN order_product op2 ON p.product_id = op2.product_id
     JOIN ordered o2 ON o2.order_id = op2.order_id
     WHERE o2.order_date BETWEEN cq.quarter_start AND cq.quarter_end
     GROUP BY p.product_id, p.name
     ORDER BY SUM(op2.quantity) DESC LIMIT 1) AS best_selling_product,
    
    -- Category metrics
    (SELECT category_name FROM category cat
     JOIN product p2 ON p2.category_id = cat.category_id
     JOIN order_product op3 ON op3.product_id = p2.product_id
     JOIN ordered o3 ON o3.order_id = op3.order_id
     WHERE o3.order_date BETWEEN cq.quarter_start AND cq.quarter_end
     GROUP BY cat.category_id, cat.category_name
     ORDER BY SUM(op3.amount) DESC LIMIT 1) AS top_category

FROM current_quarter cq
LEFT JOIN ordered o ON o.order_date BETWEEN cq.quarter_start AND cq.quarter_end
LEFT JOIN order_product op ON op.order_id = o.order_id
LEFT JOIN customer c ON c.customer_id = o.customer_id
GROUP BY cq.quarter_name, cq.quarter_start, cq.quarter_end;

--7. Create a read-only role for the manager.
-- This role should have permission to perform SELECT queries on the database tables, and also be able to log in. 
--Please ensure that you adhere to best practices for database security when defining this role

--creating manager role
DROP OWNED BY manager_role;
DROP ROLE IF EXISTS manager_role;
CREATE ROLE manager_role WITH PASSWORD 'housePassword7';

--giving grant access to database
GRANT CONNECT ON DATABASE household_appliances_store2 TO manager_role;

--adding login to this role
ALTER ROLE manager_role WITH LOGIN;


--grant read-only access to tables
GRANT SELECT ON 
    public.customer,
    public.product,
    public.ordered,
    public.order_product,
    public.payment,
    public.supplier,
    public.category,
    public.procurement_order,
    public.stock,
    public.employee
TO manager_role;

--trying if SELECT works
SET ROLE manager_role;

--selecting this, it works
SELECT * FROM public.customer LIMIT 1;


