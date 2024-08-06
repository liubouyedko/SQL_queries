SELECT 
    category.name as category_name, 
    COUNT(film.film_id) as film_count
FROM category 
    LEFT JOIN film_category 
        ON category.category_id = film_category.category_id
    LEFT JOIN film
        ON film_category.film_id = film.film_id
GROUP BY category.name
ORDER BY COUNT(film.film_id) DESC;



SELECT 
    a.actor_id, 
    a.first_name, 
    a.last_name, 
    COUNT(r.inventory_id) AS rent_count
FROM actor AS a
    LEFT JOIN film_actor AS fa 
        ON a.actor_id = fa.actor_id
    LEFT JOIN film AS f
        ON fa.film_id = f.film_id
    LEFT JOIN inventory AS i
        ON f.film_id = i.film_id
    LEFT JOIN rental AS r
        ON i.inventory_id = r.inventory_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY COUNT(r.inventory_id) DESC
LIMIT 10;


SELECT 
    c.category_id, 
    c.name, 
    SUM(p.amount) AS total_amount_of_money
FROM category AS c
    LEFT JOIN film_category AS fc
        ON c.category_id = fc.category_id
    LEFT JOIN film AS f
        ON fc.film_id = f.film_id
    LEFT JOIN inventory AS i
        ON f.film_id = i.film_id
    LEFT JOIN rental AS r
        ON i.inventory_id = r.inventory_id
    LEFT JOIN payment AS p
        ON r.rental_id = p.rental_id
GROUP BY c.category_id, c.name
ORDER BY total_amount_of_money DESC
LIMIT 1;



SELECT 
    f.film_id,
    f.title
FROM film AS f
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory as i
    WHERE f.film_id = i.film_id
);



WITH ActorFilmCount AS (
    SELECT 
        a.actor_id,
        a.first_name,
        a.last_name,
        COUNT(c.category_id) AS amount_of_children_films
    FROM actor AS a
        LEFT JOIN film_actor AS fa
            ON a.actor_id = fa.actor_id
        LEFT JOIN film AS f 
            ON fa.film_id = f.film_id
        LEFT JOIN film_category AS fc
            ON f.film_id = fc.film_id
        LEFT JOIN category AS c 
            ON fc.category_id = c.category_id
    WHERE c.name='Children'
    GROUP BY a.actor_id
),
ranked_actors AS (
    SELECT 
        actor_id,
        first_name,
        last_name,
        amount_of_children_films,
        DENSE_RANK() OVER (ORDER BY amount_of_children_films DESC) AS rk 
    FROM ActorFilmCount
)
SELECT 
    actor_id,
    first_name,
    last_name,
    amount_of_children_films
FROM ranked_actors
WHERE rk <= 3;


SELECT 
    city.city_id,
    city.city,
    SUM(CASE WHEN cus.active = 1 THEN 1 ELSE 0 END) AS active_customers,
    SUM(CASE WHEN cus.active = 0 THEN 1 ELSE 0 END) AS inactive_customers
FROM city
    LEFT JOIN address AS a
        ON city.city_id = a.city_id
    LEFT JOIN customer AS cus
        ON a.address_id = cus.address_id
GROUP BY city.city_id, city.city
ORDER BY inactive_customers DESC;



WITH RentalHours AS (
    SELECT 
        cat.name AS category_name,
        city.city AS city_name,
        SUM(EXTRACT(EPOCH FROM (r.return_date - r.rental_date)) / 3600) AS total_hours
    FROM city
        LEFT JOIN address AS a 
            ON city.city_id = a.city_id
        LEFT JOIN customer AS cus 
            ON a.address_id = cus.address_id
        LEFT JOIN rental AS r 
            ON cus.customer_id = r.customer_id
        LEFT JOIN inventory AS i 
            ON r.inventory_id = i.inventory_id
        LEFT JOIN film AS f
            ON i.film_id = f.film_id
        LEFT JOIN film_category AS fc
            ON f.film_id = fc.film_id
        LEFT JOIN category AS cat 
            ON fc.category_id = cat.category_id
    GROUP BY cat.name, city.city 
),
CategoryHours AS (
    SELECT 
        category_name,
        SUM(total_hours) AS category_total_hours
    FROM RentalHours 
    WHERE city_name ILIKE 'a%'
    GROUP BY category_name
),
CategoryHoursDash AS (
    SELECT
        category_name,
        SUM(total_hours) AS category_total_hours
    FROM RentalHours
    WHERE city_name LIKE '%-%'
    GROUP BY category_name
),
TopCategoryHours AS (
    SELECT 
        category_name,
        category_total_hours
    FROM CategoryHours
    UNION ALL
    SELECT
        category_name,
        category_total_hours
    FROM CategoryHoursDash
),
MaxCategoryHours AS (
    SELECT category_name, category_total_hours
    FROM TopCategoryHours
    ORDER BY category_total_hours DESC
    LIMIT 2
)
SELECT * FROM MaxCategoryHours;
