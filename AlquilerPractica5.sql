-- Ventas totales por categoría

SELECT c.name AS categoria,
       SUM(p.amount) AS total_ventas
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY total_ventas DESC;

-- Ventas totales por tienda, con ciudad, país y encargado

SELECT (ci.city || ', ' || co.country) AS ubicacion,
       s.store_id,
       (st.first_name || ' ' || st.last_name) AS encargado,
       SUM(p.amount) AS total_ventas
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN staff st ON r.staff_id = st.staff_id
JOIN store s ON st.store_id = s.store_id
JOIN address a ON s.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id
GROUP BY ubicacion, s.store_id, encargado
ORDER BY total_ventas DESC;

-- Lista de películas con categoría, precio, duración y actores

SELECT f.film_id,
       f.title,
       f.description,
       c.name AS categoria,
       f.rental_rate AS precio,
       f.length AS duracion,
       f.rating AS clasificacion,
       STRING_AGG(a.first_name || ' ' || a.last_name, ', ') AS actores
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
JOIN film_actor fa ON f.film_id = fa.film_id
JOIN actor a ON fa.actor_id = a.actor_id
GROUP BY f.film_id, f.title, f.description, categoria, precio, duracion, clasificacion
ORDER BY f.title;

-- Actores con sus categorías y películas

SELECT (a.first_name || ' ' || a.last_name) AS actor,
       STRING_AGG(DISTINCT c.name || ' : ' || f.title, ' | ') AS categorias_peliculas
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY actor
ORDER BY actor;

-- Vistas

SELECT * FROM view_ventas_categoria;
SELECT * FROM view_ventas_tienda;
SELECT * FROM view_peliculas_info;
SELECT * FROM view_actores_categoria_pelicula;

CREATE VIEW view_ventas_categoria AS
SELECT c.name AS categoria, SUM(p.amount) AS total_ventas
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY total_ventas DESC;

CREATE VIEW view_ventas_tienda AS
SELECT (ci.city || ', ' || co.country) AS ubicacion,
       s.store_id,
       (st.first_name || ' ' || st.last_name) AS encargado,
       SUM(p.amount) AS total_ventas
FROM payment p
JOIN rental r ON p.rental_id = r.rental_id
JOIN staff st ON r.staff_id = st.staff_id
JOIN store s ON st.store_id = s.store_id
JOIN address a ON s.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id
GROUP BY ubicacion, s.store_id, encargado
ORDER BY total_ventas DESC;

CREATE VIEW view_peliculas_info AS
SELECT f.film_id, f.title, f.description, c.name AS categoria,
       f.rental_rate AS precio, f.length AS duracion,
       f.rating AS clasificacion,
       STRING_AGG(a.first_name || ' ' || a.last_name, ', ') AS actores
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
JOIN film_actor fa ON f.film_id = fa.film_id
JOIN actor a ON fa.actor_id = a.actor_id
GROUP BY f.film_id, f.title, f.description, categoria, precio, duracion, clasificacion;

CREATE VIEW view_actores_categoria_pelicula AS
SELECT (a.first_name || ' ' || a.last_name) AS actor,
       STRING_AGG(DISTINCT c.name || ':' || f.title, ', ') AS categorias_peliculas
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY actor;

-- Restricciones Check

ALTER TABLE film
ADD CONSTRAINT chk_length_positive CHECK (length > 0),
ADD CONSTRAINT chk_rental_rate_positive CHECK (rental_rate >= 0);

-- Este trigger actualiza automáticamente la columna last_update de la tabla customer cada vez que se modifica un registro.
-- Una solución similar se puede aplicar, por ejemplo, en la tabla film, inventory o staff, donde queramos mantener el registro de la última modificación. 

-- Trigger Insersion en Film

CREATE TABLE film_inserts (
    film_id INT,
    fecha_insercion TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION log_film_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO film_inserts(film_id) VALUES (NEW.film_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger Eliminacion en Film

CREATE OR REPLACE FUNCTION log_film_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO film_inserts(film_id) VALUES (NEW.film_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_log_film_insert
AFTER INSERT ON film
FOR EACH ROW
EXECUTE FUNCTION log_film_insert();

-- Secuencias Explicación

/* En PostgreSQL, las secuencias se usan para generar identificadores únicos automáticamente, normalmente asociados a columnas con SERIAL o GENERATED.
Por ejemplo, customer_id o film_id usan secuencias para garantizar valores consecutivos sin conflictos.*/
