##1. Show film which dont have any screening
SELECT f.id, f.name
FROM film f
LEFT JOIN screening s ON f.id = s.film_id
WHERE s.id IS NULL;

#2. Who book more than 1 seat in 1 booking
SELECT 
    first_name,
    last_name,
	booking_id, 
    COUNT(seat_id) AS num_of_seats_booked
FROM reserved_seat r
JOIN booking b ON r.booking_id = b.id
JOIN customer c ON b.customer_id = c.id
GROUP BY booking_id
HAVING num_of_seats_booked > 1

#3. Show room show more than 2 film in one day
SELECT 
	room_id,
	COUNT(DISTINCT (film_id)) as num_of_films,
	DATE(start_time) AS day
FROM screening 
GROUP BY room_id, day
HAVING num_of_films > 2;

#4. which room show the least film?
WITH film_per_room AS (
	SELECT 
		room_id,
		COUNT(DISTINCT (film_id)) AS num_of_films
	FROM screening
	GROUP BY room_id
),
min_film_shown_per_room AS (
	SELECT MIN(num_of_films) AS min_num_of_film
    FROM film_per_room
)
SELECT room_id, name, num_of_films
FROM film_per_room f
JOIN min_film_shown_per_room m ON f.num_of_films = m.min_num_of_film
JOIN room r ON f.room_id = r.id;

#5. what film don't have booking
SELECT 
	name,
    COUNT(b.id) AS num_of_booking
FROM film f
LEFT JOIN screening s ON f.id = s.film_id
LEFT JOIN booking b ON s.id = b.screening_id
GROUP BY name
HAVING num_of_booking = 0;

#6. WHAT film have show the biggest number of room?
WITH room_per_film AS (
	SELECT 
		film_id,
		COUNT(DISTINCT (room_id)) AS num_of_room
	FROM screening
	GROUP BY film_id
),
max_room_shown_per_film AS (
	SELECT MAX(num_of_room) AS max_num_of_room
    FROM room_per_film
)
SELECT film_id, name, num_of_room
FROM room_per_film r
JOIN max_room_shown_per_film m ON r.num_of_room = m.max_num_of_room
JOIN film f ON r.film_id = f.id;

#7. Show number of film that show in every day of week and order descending
SELECT 
	DATE_FORMAT(start_time,'%a') AS day_of_week,
	COUNT(DISTINCT (film_id)) AS num_of_film
FROM screening
GROUP BY day_of_week
ORDER BY num_of_film DESC;

#8. Show total length of each film that showed in 28/5/2022
SELECT 
	film_id,
    name,
    SUM(length_min) AS total_length_min,
	DATE(start_time) AS day
FROM screening s
JOIN film f ON s.film_id = f.id
WHERE DATE(start_time) = '2022-05-28'
GROUP BY 1,4;

#9. What film has showing time above and below average show time of all film
WITH session_count AS (
	SELECT 
		f.id,
		(COUNT(start_time) * length_min) AS showtime
	FROM film f
	LEFT JOIN screening s ON s.film_id = f.id
	GROUP BY 1
), 
avg_count AS (
	SELECT AVG(showtime) AS avg_showtime
	FROM session_count
)
SELECT 
	f.id,
    f.name,
    sc.showtime,
    CASE 
		WHEN sc.showtime > ac.avg_showtime THEN 'Above Average'
        WHEN sc.showtime < ac.avg_showtime THEN 'Below Average'
        ELSE 'Average'
	END AS showtime_rating
FROM film f
JOIN session_count sc ON f.id = sc.id
CROSS JOIN avg_count ac
ORDER BY showtime_rating

#10. what room have least number of seat?
SELECT 
	name, 
	COUNT(number) AS num_of_seats
FROM room r
JOIN seat s ON r.id = s.room_id
GROUP BY name
ORDER BY 2
LIMIT 1;

#11. what room have number of seat bigger than average number of seat of all rooms
WITH num_of_seats AS (
	SELECT
		room_id,
		COUNT(number) AS seat_per_room
	FROM seat
	GROUP BY room_id
),
avg_num_of_seats AS (
	SELECT AVG(seat_per_room) AS avg_num
	FROM num_of_seats
)
SELECT 
	room_id,
    seat_per_room
FROM num_of_seats n
JOIN avg_num_of_seats a ON n.seat_per_room > a.avg_num
GROUP BY room_id

#12 Ngoai nhung seat mà Ong Dung booking duoc o booking id = 1 thi ong CÓ THỂ (CAN) booking duoc nhung seat nao khac khong? - NOT DONE
WITH dung_booking AS (
	SELECT screening_id, booking_id, first_name, last_name, seat_id
	FROM reserved_seat r
	JOIN booking b ON r.booking_id = b.id
	JOIN customer c ON b.customer_id = c.id
	WHERE c.first_name = 'dung' AND c.last_name = 'nguyen'
),
booked_seat AS (
	SELECT s.id AS seat_id, rs.booking_id, b.screening_id
	FROM seat s
	LEFT JOIN reserved_seat rs ON s.id = rs.seat_id
	LEFT JOIN booking b ON rs.booking_id = b.id
	WHERE b.screening_id IN (SELECT screening_id FROM dung_booking)
)
SELECT DISTINCT s.id AS seat_id
FROM screening sc
JOIN dung_booking d ON sc.id = d.screening_id
JOIN room r ON sc.room_id = r.id
JOIN seat s ON r.id = s.room_id
WHERE s.id NOT IN (SELECT seat_id FROM booked_seat)
    
#13. Show Film with total screening and order by total screening. BUT ONLY SHOW DATA OF FILM WITH TOTAL SCREENING > 10
SELECT 
	film_id,
    name,
    COUNT(s.id) AS total_screening
FROM screening s
JOIN film f ON s.film_id = f.id
GROUP BY film_id
HAVING total_screening > 10
ORDER BY total_screening

#14. TOP 3 DAY OF WEEK based on total booking
SELECT 
	DATE_FORMAT(start_time,'%a') AS weekdate,
    COUNT(b.id) AS booking_per_day
FROM booking b
RIGHT JOIN screening s ON b.screening_id = s.id
GROUP BY weekdate
ORDER BY 2 DESC
LIMIT 3

#15. CALCULATE BOOKING rate over screening of each film ORDER BY RATES.
SELECT 
	f.name, 
	COUNT(DISTINCT b.id) AS booking_count, 
	COUNT(DISTINCT s.id) AS total_screening,
	ROUND(COALESCE((COUNT(DISTINCT b.id) / COUNT(DISTINCT s.id) * 100),0),2) AS booking_rate_percentage
FROM film f
LEFT JOIN screening s ON f.id = s.film_id
LEFT JOIN booking b ON s.id = b.screening_id
GROUP BY 1
ORDER BY 4 DESC;

#16. CONTINUE Q15 -> WHICH film has rate over average ?.
WITH booking_rate AS (
	SELECT 
		f.name, 
		COUNT(DISTINCT b.id) AS booking_count, 
		COUNT(DISTINCT s.id) AS total_screening,
		ROUND(COALESCE((COUNT(DISTINCT b.id) / COUNT(DISTINCT s.id) * 100),0),2) AS booking_rate_percentage
	FROM film f
	LEFT JOIN screening s ON f.id = s.film_id
	LEFT JOIN booking b ON s.id = b.screening_id
	GROUP BY 1
	ORDER BY 4 DESC
),
avg_booking_rate AS (
	SELECT AVG(booking_rate_percentage) AS avg_rate
    FROM booking_rate
)
SELECT 
	name, 
	booking_rate_percentage
FROM booking_rate b
JOIN avg_booking_rate a ON b.booking_rate_percentage > a.avg_rate

#17.TOP 2 people who enjoy the least TIME (in minutes) in the cinema based on booking info - 
#only count who has booking info (example : Dũng book film tom&jerry 4 times -> Dũng enjoy 90 mins x 4)
SELECT 
	CONCAT (c.first_name,' ', c.last_name) AS customer_name,
    SUM(f.length_min) AS enjoy_time
FROM customer c
JOIN booking b ON c.id = b.customer_id
JOIN reserved_seat rs ON b.id = rs.booking_id
JOIN screening s ON b.screening_id = s.id
JOIN film f ON s.film_id = f.id
GROUP BY customer_name
ORDER BY enjoy_time
LIMIT 2;


        




	


