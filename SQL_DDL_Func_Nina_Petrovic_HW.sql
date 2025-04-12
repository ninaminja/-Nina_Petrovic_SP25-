--Task 1. Create a view
CREATE OR REPLACE VIEW sales_revenue_by_category_qtr AS
WITH current_quarter_sales AS (
    SELECT 
        c.category_id,
        c.name AS category,
        SUM(p.amount) AS total_revenue
    FROM 
    --here we will get all needed informations
        payment p
        JOIN rental r ON p.rental_id = r.rental_id
        JOIN inventory i ON r.inventory_id = i.inventory_id
        JOIN film f ON i.film_id = f.film_id
        JOIN film_category fc ON f.film_id = fc.film_id
        JOIN category c ON fc.category_id = c.category_id
    WHERE 
    --just transactions that has happened in this quarter
        EXTRACT(QUARTER FROM p.payment_date) = EXTRACT(QUARTER FROM CURRENT_DATE)
        AND EXTRACT(YEAR FROM p.payment_date) = EXTRACT(YEAR FROM CURRENT_DATE)
    GROUP BY 
        c.category_id, c.name
)
SELECT 
    category,
    total_revenue AS total_sales_revenue
FROM 
    current_quarter_sales
WHERE 
--just categories that had 1 or more revenues
    total_revenue > 0
ORDER BY 
    total_revenue DESC;

--Task 2. Create a query language functions
--we have in_year and in_quarter to specify year or default to be current 
--if quarter is for ex 0 or 5 it will give an error
--we will combine all needed tables 
--and HAVING SUM is to show just catrgories that had amount
CREATE OR REPLACE FUNCTION get_sales_revenue_by_category_qtr(
    in_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT,
    in_quarter INT DEFAULT EXTRACT (QUARTER FROM CURRENT_DATE)::INT
)
RETURNS TABLE (
    category_name TEXT,
    total_revenue NUMERIC
)
AS $$
BEGIN

    IF in_quarter NOT BETWEEN 1 AND 4 THEN
        RAISE EXCEPTION 'Quarter must be between 1 and 4. Got: %', in_quarter;
    END IF;

    RETURN QUERY
    SELECT
        c.name AS category_name,
        SUM(p.amount) AS total_revenue
    FROM payment p
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = in_year
      AND EXTRACT(QUARTER FROM p.payment_date) = in_quarter
    GROUP BY c.name
    HAVING SUM(p.amount) > 0;
END;
$$ LANGUAGE plpgsql;

--Task 3. Create procedure language functions

CREATE OR REPLACE FUNCTION most_popular_films_by_countries(
    country_names TEXT[]
)
RETURNS TABLE (
    country TEXT,
    film TEXT,
    rating TEXT,
    language TEXT,
    length INT,
    release_year INT
) AS $$
BEGIN
    -- validate input
    IF array_length(country_names, 1) IS NULL THEN
        RAISE EXCEPTION 'Country names array cannot be empty';
    END IF;
    
    RETURN QUERY
    WITH country_film_stats AS (
        SELECT 
            co.country AS country_name,
            f.title AS film_title,
            f.rating,
            l.name AS language_name,
            f.length,
            f.release_year,
            COUNT(r.rental_id) AS rental_count,
            ROW_NUMBER() OVER (PARTITION BY co.country ORDER BY COUNT(r.rental_id) DESC) AS rank
        FROM 
            country co
            JOIN city ci ON co.country_id = ci.country_id
            JOIN address a ON ci.city_id = a.city_id
            JOIN customer cu ON a.address_id = cu.address_id
            JOIN rental r ON cu.customer_id = r.customer_id
            JOIN inventory i ON r.inventory_id = i.inventory_id
            JOIN film f ON i.film_id = f.film_id
            JOIN language l ON f.language_id = l.language_id
        WHERE 
            co.country = ANY(country_names)
        GROUP BY 
            co.country, f.title, f.rating, l.name, f.length, f.release_year
    )
    SELECT 
        cfs.country_name::TEXT,
        cfs.film_title::TEXT,
        cfs.rating::TEXT,
        cfs.language_name::TEXT,
        cfs.length::INT,
        cfs.release_year::INT
    FROM 
        country_film_stats cfs
    WHERE 
        cfs.rank = 1
    ORDER BY 
        array_position(country_names, cfs.country_name);
    
    IF NOT FOUND THEN
        RAISE NOTICE 'No rental data found for the specified countries';
    END IF;
END;
$$ LANGUAGE plpgsql;

--Task 4. Create procedure language functions

CREATE OR REPLACE FUNCTION find_available_movies(
    search_term TEXT
)
RETURNS TABLE (
    row_number BIGINT,
    title TEXT,
    language TEXT,
    status TEXT
) AS $$
BEGIN
    -- check for empty search term
    IF search_term IS NULL OR trim(search_term) = '' THEN
        RAISE NOTICE 'Please provide a search term';
        RETURN;
    END IF;

    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER (ORDER BY f.title) AS row_number,
        f.title::TEXT,
        l.name::TEXT AS language,
        CASE 
            WHEN NOT EXISTS (
                SELECT 1 FROM rental r 
                JOIN inventory i ON r.inventory_id = i.inventory_id 
                WHERE i.film_id = f.film_id AND r.return_date IS NULL
            ) THEN 'Available'
            ELSE 'Currently rented'
        END::TEXT AS status
    FROM 
        film f
        JOIN language l ON f.language_id = l.language_id
    WHERE 
        f.title ILIKE '%' || search_term || '%'
    ORDER BY 
        f.title;


    IF NOT FOUND THEN
        RAISE NOTICE 'No movies found containing "%"', search_term;
    END IF;
END;
$$ LANGUAGE plpgsql;


--Task 5. Create procedure language functions

CREATE OR REPLACE FUNCTION new_movie(
    p_title TEXT,
    p_release_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    p_language_name TEXT DEFAULT 'Klingon'
)
RETURNS INT AS $$
DECLARE
    v_language_id INT;
    v_film_id INT;
    v_count INT;
BEGIN
    -- validate movie title, there no one can add title of film without name or with blank string
    IF p_title IS NULL OR trim(p_title) = '' THEN
        RAISE EXCEPTION 'Movie title cannot be empty';
    END IF;
    
    -- check if language exists
    SELECT language_id INTO v_language_id 
    FROM language 
    WHERE name = p_language_name;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Language "%" does not exist in the language table', p_language_name;
    END IF;
    
    -- Check for duplicate movie title
    SELECT COUNT(*) INTO v_count 
    FROM film 
    WHERE title = p_title;
    
    IF v_count > 0 THEN
        RAISE EXCEPTION 'Movie "%" already exists', p_title;
    END IF;
    
    -- generate new film ID
    SELECT COALESCE(MAX(film_id), 0) + 1 INTO v_film_id FROM film;
    
    -- Insert the new movie
    INSERT INTO film (
        film_id,
        title,
        language_id,
        release_year,
        rental_duration,
        rental_rate,
        replacement_cost,
        last_update
    ) VALUES (
        v_film_id,
        p_title,
        v_language_id,
        p_release_year,
        3,           -- rental duration (3 days)
        4.99,        -- rental rate
        19.99,       -- replacement cost
        CURRENT_TIMESTAMP
    );
    
    RETURN v_film_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error creating movie: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;


