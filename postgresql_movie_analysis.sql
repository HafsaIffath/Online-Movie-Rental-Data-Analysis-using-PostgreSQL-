-- Online Movie Rental Data Analysis using PostgreSQL: A project focused on extracting meaningful insights from rental data to understand customer preferences, popular movies, and rental trends.

-- 1. Create a list of all the different(distinct) replacement costs of the films

-- What is the lowest replacement cost
SELECT DISTINCT(replacement_cost) 
FROM film
ORDER BY 1
LIMIT 1;

-- 2. Write a query that gives an overview of how many films have replacements costs in the following cost ranges

-- 1) low: 9.99 - 19.99

-- 2) medium: 20.00 - 24.99

-- 3) high: 25.00 - 29.99


-- How many films have a replacement cost in the "low" group?
SELECT COUNT(*) as no_of_films,
CASE
WHEN replacement_cost>=9.99 AND replacement_cost<=19.99 THEN 'low'
WHEN replacement_cost>=20 AND replacement_cost<=24.99 THEN 'medium'
WHEN replacement_cost>=25 AND replacement_cost<=29.99 THEN 'high'
END as category_based_on_replacement_cost
FROM film
WHERE 
CASE
WHEN replacement_cost>=9.99 AND replacement_cost<=19.99 THEN 'low'
WHEN replacement_cost>=20 AND replacement_cost<=24.99 THEN 'medium'
WHEN replacement_cost>=25 AND replacement_cost<=29.99 THEN 'high'
END ='low'
GROUP BY 
category_based_on_replacement_cost
ORDER BY 1 DESC;

-- 3. Create a list of the film titles including their title, length, and category name ordered descendingly by length. Filter the results to only the movies in the category 'Drama' or 'Sports'.

-- In which category is the longest film and how long is it?

SELECT f.title, f.length,c.name
FROM film f
INNER JOIN film_category fc
ON f.film_id=fc.film_id 
INNER JOIN category c
ON fc.category_id=c.category_id AND c.name IN ('Drama','Sports')
ORDER BY f.length DESC
LIMIT 1;

-- 4. Create an overview of how many movies (titles) there are in each category (name).

-- Which category (name) is the most common among the films?
SELECT COUNT(*) as no_of_movies, c.name as Category
FROM film f
INNER JOIN film_category fc
ON f.film_id=fc.film_id 
INNER JOIN category c
ON fc.category_id=c.category_id 
GROUP BY c.name
ORDER BY 1 DESC;

-- 5.  Create an overview of the actors' first and last names and in how many movies they appear in.

-- Which actor is part of most movies?
SELECT a.first_name,a.last_name, COUNT(*) as no_of_movies
FROM actor a
INNER JOIN film_actor fa
ON a.actor_id=fa.actor_id
GROUP BY  a.first_name,a.last_name
ORDER BY 3 DESC
LIMIT 1; 

-- 6. Create an overview of the addresses that are not associated to any customer.

-- How many addresses are that?
SELECT COUNT(*) as no_of_addresses
FROM address a
LEFT JOIN customer c
ON c.address_id=a.address_id
WHERE c.customer_id IS NULL;

-- 7.  Create the overview of the sales  to determine the from which city (we are interested in the city in which the customer lives, not where the store is) most sales occur.

--  What city is that and how much is the amount?
SELECT c.city , SUM(amount) as total_amount
FROM customer cu
INNER JOIN address a
ON cu.address_id=a.address_id
INNER JOIN city c
ON c.city_id=a.city_id
INNER JOIN payment p
ON p.customer_id=cu.customer_id
GROUP BY c.city
ORDER BY 2 DESC
LIMIT 1;

-- 8. Create an overview of the revenue (sum of amount) grouped by a column in the format "country, city".

-- Which country, city has the least sales?
SELECT co.country || ', '|| ci.city, sum(amount)
FROM customer c
INNER JOIN address a
ON a.address_id=c.address_id
INNER JOIN city ci
ON ci.city_id=a.city_id
INNER JOIN country co
ON co.country_id=ci.country_id
INNER JOIN payment p
ON p.customer_id=c.customer_id
GROUP BY co.country || ', '|| ci.city
ORDER BY 2 ASC;

--  9. Create a list with the average of the sales amount each staff_id has per customer.

--  Which staff_id makes on average more revenue per customer?

SELECT staff_id, ROUND(AVG(total),2) 
FROM 
(SELECT staff_id, customer_id,SUM(amount) as total FROM payment
GROUP BY staff_id, customer_id
ORDER BY 3) sub
GROUP BY staff_id;

-- 10. Create a query that shows average daily revenue of all Sundays.

-- What is the daily average revenue of all Sundays?

SELECT ROUND(AVG(total),2)
FROM
( SELECT SUM(amount) as total FROM payment
WHERE EXTRACT(dow FROM payment_date)=0
GROUP BY DATE(payment_date),EXTRACT(dow FROM payment_date) )


-- 11. Create a list of movies - with their length and their replacement cost - that are longer than the average length in each replacement cost group.

-- Which two movies are the shortest on that list and how long are they?

SELECT title, length, replacement_cost
FROM film f1
WHERE length > (SELECT AVG(length)
			   FROM film f2
			   WHERE f1.replacement_cost=f2.replacement_cost) 
ORDER BY 2 ASC;

-- 12.  Create a list that shows the "average customer lifetime value" grouped by the different districts.

-- Which district has the highest average customer lifetime value?
SELECT district, ROUND(AVG(total),2) 
FROM(
SELECT district,p.customer_id, SUM(amount) as total
FROM payment p
INNER JOIN customer c
ON c.customer_id=p.customer_id
INNER JOIN address a
ON a.address_id=c.address_id
GROUP BY district,p.customer_id
	)
GROUP BY district
ORDER BY 2 DESC;

-- 13. Create a list that shows all payments including the payment_id, amount, and the film category (name) plus the total amount that was made in this category. Order the results ascendingly by the category (name) and as second order criterion by the payment_id ascendingly.

-- What is the total revenue of the category 'Action' and what is the lowest payment_id in that category 'Action'?

SELECT title, amount, payment_id, name,
(SELECT SUM(amount)
FROM payment p
LEFT JOIN rental r
ON r.rental_id=p.rental_id
LEFT JOIN inventory i
ON i.inventory_id=r.inventory_id
LEFT JOIN film f
ON f.film_id=i.film_id
LEFT JOIN film_category fc
ON fc.film_id=f.film_id
LEFT JOIN category c2
ON c2.category_id=fc.category_id
WHERE c2.name=c1.name)
FROM payment p
LEFT JOIN rental r
ON r.rental_id=p.rental_id
LEFT JOIN inventory i
ON i.inventory_id=r.inventory_id
LEFT JOIN film f
ON f.film_id=i.film_id
LEFT JOIN film_category fc
ON fc.film_id=f.film_id
LEFT JOIN category c1
ON c1.category_id=fc.category_id
ORDER BY name ASC, payment_id ASC

-- 14. Create a list with the top overall revenue of a film title (sum of amount per title) for each category (name).

-- Which is the top-performing film in the animation category?

SELECT title, name, SUM(amount) as total
FROM payment p
LEFT JOIN rental r
ON r.rental_id=p.rental_id
LEFT JOIN inventory i
ON i.inventory_id=r.inventory_id
LEFT JOIN film f
ON f.film_id=i.film_id
LEFT JOIN film_category fc
ON fc.film_id=f.film_id
LEFT JOIN category c
ON c.category_id=fc.category_id
GROUP BY name,title
HAVING sum(amount)=(SELECT MAX(total)
				   FROM (SELECT title, name, SUM(amount) as total
					FROM payment p
					LEFT JOIN rental r
					ON r.rental_id=p.rental_id
					LEFT JOIN inventory i
					ON i.inventory_id=r.inventory_id
					LEFT JOIN film f
					ON f.film_id=i.film_id
					LEFT JOIN film_category fc
					ON fc.film_id=f.film_id
					LEFT JOIN category c
					ON c.category_id=fc.category_id
					GROUP BY name,title) sub
				   WHERE c.name=sub.name);
