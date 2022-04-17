/* 1) ALL DATA SELECTION (1)*/
/* 1. Show all information about all library subscribers */
SELECT *
FROM [subscribers];

/* 2) DISTINCT DATA SELECTION (2-5)*/
/* 2. Show ids (without duplication) of those subscribers, who visited the library at least once */
SELECT DISTINCT [sb_subscriber]
FROM [subscriptions];

/* 3. Show the list of all subscribers along with information of their names count */
SELECT [s_name], 
	COUNT(*) AS [people_count]
FROM [subscribers]
GROUP BY [s_name];

/* 4. all ids (without duplication) of all books ever taken by subscribers */
SELECT DISTINCT [sb_book] 
FROM [subscriptions];

/* 5. all books along with count of times each book was taken by a subscriber */
SELECT [sb_book], 
	COUNT(*) AS book_count
FROM [subscriptions]
GROUP BY [sb_book];

/* 3) COUNT Function and its Performance (6-7)*/
/* 6. Show how many books are there in the library */
SELECT COUNT(*) AS [total_books]
FROM [books];

/* 7. Show how many subscribers are there in the library */
SELECT COUNT(*) AS [total_subscribers]
FROM [subscribers];

/* 4) COUNT Function with Conditions (8-11)*/
/* 8. Show how many copies of books are taken by subscribers */
SELECT COUNT([sb_book]) AS [in_use]
FROM [subscriptions]
WHERE [sb_is_active] = 'Y'

/* 9. Show how many different books are taken by subscribers */
SELECT COUNT(DISTINCT [sb_book]) AS [in_use]
FROM [subscriptions]
WHERE [sb_is_active] = 'Y'

/* 10. how many times subscribers have taken books */
SELECT COUNT("sb_subscriber") AS "subscribers"
FROM "subscriptions";

/* 11. how many subscribers have taken books */
SELECT COUNT(DISTINCT "sb_subscriber") AS "subscribers"
FROM "subscriptions";

/* 5) SUM, MIN, MAX, AVG functions (12-13)*/
/* 12. Show total, mimimum, maximum and average copies of books quantities */
SELECT SUM([b_quantity]) AS [sum],
	MIN([b_quantity]) AS [min],
	MAX([b_quantity]) AS [max],
	AVG(CAST([b_quantity] AS FLOAT)) AS [avg]
FROM [books];

/* 13. show the first and the last dates when a book was taken by a subscriber */
SELECT MIN("sb_start") AS "first_date",
	MAX("sb_start") AS "last_date"
FROM "subscriptions";

/* 6) Ordering Query Results (14-16) */
/* 14. Show all books ordered by issuing year (ascending) */
SELECT [b_name], [b_year]
FROM [books]
ORDER BY [b_year] ASC

/* 15. Show all books ordered by issuing year (descending) */
SELECT [b_name], [b_year]
FROM [books]
ORDER BY [b_year] DESC;

/* 16. show the all authors ordered by their names descending (i.e., "Z -> A") */
SELECT "a_name"
FROM "authors"
ORDER BY "a_name" DESC;

/* 7) Compound Conditions (17-20)*/
/* 17. Show all books that are:
- ssued in 1990-2000 year range;
- represented with at least 3 copies. */
-- Variant 1
SELECT "b_name", "b_year", "b_quantity"
FROM "books"
WHERE "b_year" BETWEEN 1990 AND 2000
	AND "b_quantity" >= 3;
-- Variant 2
SELECT "b_name", "b_year", "b_quantity"
FROM "books"
WHERE "b_year" >= 1990 
	AND "b_year" <= 2000
	AND "b_quantity" >= 3;

/* 18. Show all subscriptions that had occured in summer of 2012 */
SELECT [sb_id], [sb_start]
FROM [subscriptions]
WHERE [sb_start] >= '2012-06-01'
	AND [sb_start] < '2012-09-01';

/* 19. Show books that have the number of their copies less than average number of all books copies */
SELECT "b_name", "b_quantity"
FROM "books",
	(SELECT AVG("b_quantity") AS a
	FROM "books") 
    AS b
WHERE "b_quantity" < b.a;

/* 20. Show ids and dates of all subscriptions occurred during the first year of the library work 
(i.e., up to Dec 31st of the year when the first subscription had happened) */
SELECT sb_id, sb_start
FROM subscriptions, (SELECT MIN(YEAR(sb_start)) AS start_year FROM subscriptions) AS a 
WHERE YEAR(sb_start) <= a.start_year;

/* 8) Minimum and Maximum Values (21-26)*/
/* 21. Show one (any!) book, the number of copies of which is maximum (is equal to the maximum for all books) */
--Variant 1
SELECT TOP 1 b_name, b_quantity
FROM books
ORDER BY b_quantity DESC;
--Variant 2
SELECT b_name, b_quantity
FROM books
ORDER BY b_quantity DESC
OFFSET 0 ROWS
FETCH NEXT 1 ROWS ONLY;

/* 22. Show all books, the number of copies of which is maximum (and is the same for all these books) */
-- Variant 1
SELECT b_name, b_quantity
FROM books
WHERE b_quantity = (SELECT MAX(b_quantity) FROM books);
-- Variant 2
SELECT b_name, b_quantity
FROM (SELECT b_name, b_quantity,
	RANK() OVER (ORDER BY b_quantity DESC) AS rn
    FROM books) AS temporary_data
    WHERE rn=1;

/* 23. Show a book (if any) which has more copies than other book */
-- Variant 1
SELECT b_name, b_quantity
FROM books AS ext
WHERE b_quantity > ALL (SELECT b_quantity
						FROM books AS inte
                        WHERE ext.b_id != inte.b_id);
-- Variant 2
WITH ranked
	AS (SELECT b_name, b_quantity,
		RANK() OVER(ORDER BY b_quantity DESC) AS ranq
        FROM books),
	counted
    AS (SELECT ranq, COUNT(*) AS competitors
		FROM ranked
        GROUP BY ranq)
SELECT b_name, b_quantity
FROM ranked JOIN counted ON ranked.ranq = counted.ranq
WHERE counted.ranq = 1
	AND counted.competitors = 1;

/* 24. show the identifier of one (any) subscriber who has taken the most books from the library */
SELECT TOP 1 sb_subscriber, COUNT(sb_subscriber) AS coun
FROM subscriptions
GROUP BY sb_subscriber
ORDER BY coun DESC;

/* 25. show the identifiers of all subscribers who has taken the most books from the library */
WITH counted
    AS (SELECT sb_subscriber, COUNT(sb_subscriber) AS books_quantity
		FROM subscriptions
        GROUP BY sb_subscriber)
SELECT sb_subscriber, books_quantity
FROM counted
WHERE books_quantity = (SELECT MAX(books_quantity) FROM counted);

/* 26. show the identifier of the "champion subscriber" who has taken more books from the library than any other subscriber */
WITH counted
    AS (SELECT sb_subscriber, COUNT(sb_subscriber) AS books_quantity
		FROM subscriptions
        GROUP BY sb_subscriber)
SELECT TOP 1 sb_subscriber, MAX(books_quantity)
FROM counted
GROUP BY sb_subscriber;

/* 9) Average Values (27-31) */
/* 27. Show the average quantity of copies of books each reader currently has taken (query without DISTINCT)
Show the average quantity of books each reader currently has taken (query with DISTINCT) */
SELECT AVG(CAST([books_per_subscriber] AS FLOAT)) AS [avg_books]
FROM (SELECT COUNT(DISTINCT [sb_book]) AS [books_per_subscriber]
	FROM [subscriptions]
    WHERE [sb_is_active] = 'Y'
    GROUP BY [sb_subscriber]) AS [count_subquery];

/* 28. Show the average number of days a subscriber reads a book (take into account only cases when a book was returned) */
SELECT AVG(CAST(DATEDIFF(day, [sb_finish], [sb_start]) AS FLOAT)) AS [avg_days]
FROM [subscriptions]
WHERE [sb_is_active] = 'N';

/* 29. Show rhe average number of days a subscriber reads a book (take into account both cases when a book was returned and was not yet returned) */
SELECT AVG(CAST([diff] AS FLOAT)) AS [avg_days]
FROM (
	SELECT DATEDIFF(day, [sb_start], [sb_finish]) AS [diff]
    FROM [subscriptions]
    WHERE ([sb_finish] <= CONVERT(date, GETDATE()) AND [sb_is_active] = 'N')
		OR ([sb_finish] > CONVERT(date, GETDATE()) AND [sb_is_active] = 'Y')
    UNION ALL
    SELECT DATEDIFF(day, [sb_start], CONVERT(date, GETDATE())) AS [diff]
    FROM [subscriptions]
    WHERE ([sb_finish] <= CONVERT(date, GETDATE()) AND [sb_is_active] = 'Y')
		OR ([sb_finish] > CONVERT(date, GETDATE()) AND [sb_is_active] = 'N')
	) AS [diffs];

/* 30. average number of copies of books registered in the library*/
SELECT AVG(CAST([b_quantity] AS FLOAT))
FROM [books];
 
/* 31. average number of days a subscriber is registered in the library (the registration period starts with the first subscription date and ends with the current date)*/
SELECT AVG(CAST([diff] AS FLOAT)) AS [avg_days]
FROM ( SELECT DATEDIFF(day, [sb_start], CONVERT(date, GETDATE())) AS [diff]
	FROM [subscriptions]
	) AS [d];

/* 10) Data Grouping (32-34)*/
/* 32. Show (for each year) how many books was taken by subscribers */
SELECT YEAR([sb_start]) AS [year],
	COUNT([sb_id]) AS [books_taken]
FROM [subscriptions]
GROUP BY YEAR([sb_start])
ORDER BY [year];

/* 33. Show (for each year) how many subscribers were taking books */
SELECT YEAR([sb_start]) AS [year],
	COUNT(DISTINCT [sb_subscriber]) AS [subscribers]
FROM [subscriptions]
GROUP BY YEAR([sb_start])
ORDER BY [year];

/* 34. Show how many books were returned and are not returned to the library */
SELECT (CASE
	WHEN [sb_is_active] = 'Y'
	THEN 'Not returned'
	ELSE 'Returned'
	END) AS [status],
	COUNT([sb_id]) AS [books]
FROM [subscriptions]
GROUP BY (CASE
	WHEN [sb_is_active] = 'Y'
	THEN 'Not returned'
	ELSE 'Returned'
	END)
ORDER BY [status] DESC;

/* 11) Using JOINs to Obtain Human-readable Data (35-38)*/
/* 35. Show human-readable information about all books (title, author, genre) */
SELECT [b_name], [a_name], [g_name]
FROM [books]
join [m2m_books_authors] on [books].[b_id] = [m2m_books_authors].[b_id]
join [authors] on [m2m_books_authors].[b_id] = [authors].[a_id]
join [m2m_books_genres] on [books].[b_id] = [m2m_books_genres].[b_id]
join [genres] on [m2m_books_genres].[g_id] = [genres].[g_id];

/* 36. Show human-readable information about all subscriotions (i.e. with subscriber's name and book's title) */
SELECT [b_name], [s_id], [s_name], [sb_start], [sb_finish]
FROM [books]
	JOIN [subscriptions] ON [b_id] = [sb_book]
	JOIN [subscribers] ON [sb_subscriber] = [s_id];

/* 37. books written by more than one author */
SELECT [b_name]
FROM [books]
join [m2m_books_authors] on [books].[b_id] = [m2m_books_authors].[b_id]
join [authors] on [m2m_books_authors].[b_id] = [authors].[a_id]
WHERE [books].[b_id] IN
       (SELECT [b_id]
           FROM [m2m_books_authors]
         GROUP BY [b_id]
         HAVING COUNT(*) > 1)
GROUP BY [b_name]
ORDER BY [b_name];

/* 38. books that are written in exactly one genre.*/
SELECT [b_name], [g_name]
FROM [books]
join [m2m_books_genres] on [books].[b_id] = [m2m_books_genres].[b_id]
join [genres] on [m2m_books_genres].[g_id] = [genres].[g_id]
WHERE [books].[b_id] IN
       (SELECT [b_id]
           FROM [m2m_books_genres]
         GROUP BY [b_id]
         HAVING COUNT(*) = 1)
ORDER BY [b_name];

/* 12) Using JOINs with Columns-to-Rows Transformation (39-41)*/
/* 39. Show all books along with their authors (books' titles duplication is not allowed) */
SELECT [b_name] AS [book], STRING_AGG([a_name], ', ') WITHIN GROUP (ORDER BY [a_name] ASC) AS [author(s)]
FROM [books]
	JOIN [m2m_books_authors] on [books].[b_id] = [m2m_books_authors].[b_id]
	JOIN [authors] on [m2m_books_authors].[b_id] = [authors].[a_id]
GROUP BY [books].[b_id], [books].[b_name]
ORDER BY [books].[b_name];

/* 40. Show all books along with their authors and genres (books' titles and/or authors' names duplication is not allowed) */
WITH [books_names_and_authors] AS 
(
	SELECT [books].[b_id], [books].[b_name] AS [book],
		STRING_AGG([a_name], ', ') WITHIN GROUP (ORDER BY [a_name] ASC) AS [author(s)]
	FROM [books]
		JOIN [m2m_books_authors] ON [books].[b_id] = [m2m_books_authors].[b_id]
		JOIN [authors] on [m2m_books_authors].[b_id] = [authors].[a_id]
	GROUP BY [books].[b_id], [books].[b_name]
),
[books_genres] AS
(
	SELECT [books].[b_id],
		STRING_AGG([g_name], ', ') WITHIN GROUP (ORDER BY [g_name] ASC) AS [genre(s)]
	FROM [books]
		JOIN [m2m_books_genres] on [books].[b_id] = [m2m_books_genres].[b_id]
		JOIN [genres] on [m2m_books_genres].[g_id] = [genres].[g_id]
	GROUP BY [books].[b_id]
)
SELECT [books_names_and_authors].[book],
		[books_names_and_authors].[author(s)],
		[books_genres].[genre(s)]
FROM [books_names_and_authors]
	JOIN [books_genres] ON [books_names_and_authors].[b_id] = [books_genres].[b_id];

/* 41. all authors along with their books and genres (authors� names and/or books� titles duplication is not allowed)*/
WITH [books_names_and_authors] AS 
(
	SELECT [authors].[a_id], [authors].[a_name] AS [author],
		STRING_AGG([b_name], ', ') WITHIN GROUP (ORDER BY [b_name] ASC) AS [book(s)]
	FROM [authors]
		JOIN [m2m_books_authors] ON [authors].[a_id] = [m2m_books_authors].[a_id]
		JOIN [books] on [m2m_books_authors].[b_id] = [books].[b_id]
	GROUP BY [authors].[a_id], [authors].[a_name]
),
[books_genres] AS
(
	SELECT [books].[b_id],
		STRING_AGG([g_name], ', ') WITHIN GROUP (ORDER BY [g_name] ASC) AS [genre(s)]
	FROM [books]
		JOIN [m2m_books_genres] on [books].[b_id] = [m2m_books_genres].[b_id]
		JOIN [genres] on [m2m_books_genres].[g_id] = [genres].[g_id]
	GROUP BY [books].[b_id]
)
SELECT [books_names_and_authors].[author],
		[books_names_and_authors].[book(s)],
		[books_genres].[genre(s)]
FROM [books_names_and_authors]
	JOIN [books_genres] ON [books_names_and_authors].[a_id] = [books_genres].[b_id];

/* 13) JOINs and Subqueries with IN (42-44)*/
/* 42. Show all subscribers who have ever taken a book from the library (do not use JOIN) */
SELECT s_id, s_name
FROM subscribers
WHERE s_id IN (SELECT distinct sb_subscriber
				FROM subscriptions);

/* 43. Show all subscribers who have never taken a book from the library (use JOIN) */
SELECT s_id, s_name
FROM subscribers
LEFT JOIN subscriptions ON s_id = sb_subscriber
WHERE sb_subscriber IS NULL;

/* 44. Show all subscribers who have never taken a book from the library (do not use JOIN) */
SELECT s_id, s_name
FROM subscribers
WHERE s_id NOT IN (SELECT distinct sb_subscriber
				FROM subscriptions);

/* 14) Non-trivial Cases of JOINs and Subqueries with IN (45-47)*/
/* 45. Show all subscribers who doesn't have a book now (use JOIN) */
SELECT [s_id], [s_name]
FROM [subscribers]
LEFT OUTER JOIN [subscriptions] ON [s_id] = [sb_subscriber]
GROUP BY [s_id], [s_name]
HAVING COUNT(CASE 
				WHEN [sb_is_active] = 'Y'
				THEN [sb_is_active]
				ELSE NULL
			END) = 0;

/* 46. Show all subscribers who doesn't have a book now (do not use JOIN) */
SELECT s_id, s_name
FROM subscribers
WHERE s_id NOT IN (SELECT distinct sb_subscriber
				FROM subscriptions
				WHERE sb_is_active = 'Y');

/* 47. show all such books that not a single copy of which is now taken by any subscriber */
SELECT [b_id], [b_name]
FROM [books]
LEFT OUTER JOIN [subscriptions] ON [b_id] = [sb_book]
GROUP BY [b_id], [b_name]
HAVING COUNT(CASE
			WHEN [sb_is_active] = 'Y'
			THEN [sb_is_active]
			ELSE NULL
			END) = 0;

SELECT b_id, b_name
FROM books
WHERE b_id NOT IN (SELECT distinct sb_book
				FROM subscriptions
                WHERE sb_is_active = 'Y');

/* 15) Double Subqueries with IN (48-50)*/
/* 48. a) Show all books from "Programming" and/or "Classic" genres (do not use JOIN, genres' ids are known) */
SELECT b_id, b_name
FROM books
WHERE b_id IN (SELECT DISTINCT b_id
				FROM m2m_books_genres
                WHERE g_id IN (2, 5))
ORDER BY b_name ASC;

/* b) Show all books from "Programming" and/or "Classic" genres (do not use JOIN, genres' ids are unknown) */
SELECT b_id, b_name
FROM books
WHERE b_id IN (SELECT DISTINCT b_id
				FROM m2m_books_genres
                WHERE g_id IN (SELECT g_id
								FROM genres
                                WHERE g_name IN ('Programming', 'Classic')
                                ))
ORDER BY b_name ASC;

/* c) Show all books from "Programming" and/or "Classic" genres (use JOIN, genres' ids are known) */
SELECT DISTINCT [books].[b_id], [b_name]
FROM [books] JOIN [m2m_books_genres] ON [books].[b_id] = [m2m_books_genres].[b_id]
WHERE [g_id] IN (2, 5)
ORDER BY [b_name] ASC;

/* d) Show all books from "Programming" and/or "Classic" genres (use JOIN, genres' ids are unknown) */
SELECT DISTINCT [books].[b_id], [b_name]
FROM [books] JOIN [m2m_books_genres] ON [books].[b_id] = [m2m_books_genres].[b_id]
WHERE [g_id] IN (SELECT g_id
				FROM genres
                WHERE g_name IN ('Programming', 'Classic')
                 )
ORDER BY [b_name] ASC;

/* 49. show all books written by Alexander Pushkin and/or Isaac Asimov (either individually or as co-authors)*/
SELECT books.b_id, b_name
FROM books JOIN m2m_books_authors ON books.b_id = m2m_books_authors.b_id
WHERE a_id IN (SELECT a_id
	FROM authors
    WHERE a_name IN ('Alexander Pushkin', 'Isaac Asimov')
    )
ORDER BY b_name ASC;

/* 50. show all books written by Dale Carnegie AND Bjarne Stroustrup (as co-authors)*/
SELECT [books].[b_id], [b_name]
FROM [books] 
JOIN [m2m_books_authors] ON [books].[b_id] = [m2m_books_authors].[b_id]
WHERE [a_id] IN (SELECT [a_id]
	FROM [authors]
    WHERE [a_name] IN ('Dale Carnegie', 'Bjarne Stroustrup')
    )
GROUP BY [books].[b_id], [b_name]
HAVING COUNT([b_name]) > 1
ORDER BY [b_name] ASC;

/* 16) JOINs with COUNT (51-53)*/
/* 51. Show all books having more than one author */
SELECT [books].[b_id], [b_name], COUNT([m2m_books_authors].[a_id]) AS [author _count]
FROM [books] 
JOIN [m2m_books_authors] ON [books].[b_id] = [m2m_books_authors].[b_id]
GROUP BY [books].[b_id], [b_name]
HAVING COUNT([m2m_books_authors].[a_id]) > 1;

/* 52. Show for all books how many copies of them are now available in the library */
-- Variant 1: correlated query
SELECT DISTINCT b_id, b_name,
( b_quantity - (SELECT COUNT([int].sb_book)
	FROM subscriptions AS [int]
    WHERE [int].sb_book = ext.sb_book
    AND [int].sb_is_active = 'Y') 
    ) AS real_count
FROM books
LEFT OUTER JOIN subscriptions AS ext ON books.b_id = ext.sb_book
ORDER BY real_count DESC;

-- Variant 2: correlated subquery and Common Table Expression
WITH books_taken AS
	( SELECT sb_book AS b_id,
		COUNT(sb_book) AS taken
	FROM subscriptions
    WHERE sb_is_active = 'Y'
    GROUP BY sb_book)
SELECT b_id, b_name,
( b_quantity - ISNULL((SELECT taken
						FROM books_taken
                        WHERE books.b_id = books_taken.b_id), 0
                        )) AS real_count
FROM books
ORDER BY real_count DESC;

-- Variant 3: correlated subquery and two Common Table Expression
WITH books_taken 
	AS (SELECT sb_book
    FROM subscriptions
    WHERE sb_is_active = 'Y'),
    real_taken
    AS (SELECT b_id, COUNT(sb_book) AS taken
    FROM books
    LEFT OUTER JOIN books_taken ON b_id = sb_book
    GROUP BY b_id)
SELECT b_id, b_name,
( b_quantity - (SELECT taken
				FROM real_taken
                WHERE books.b_id = real_taken.b_id)) AS real_count
FROM books
ORDER BY real_count DESC;

-- Variant 4: without subqueries
WITH books_taken
	AS (SELECT sb_book, COUNT(sb_book) AS taken
    FROM subscriptions
    WHERE sb_is_active = 'Y'
    GROUP BY sb_book)
SELECT b_id, b_name,
	(b_quantity - ISNULL(taken, 0)) AS real_count
FROM books
LEFT OUTER JOIN books_taken ON b_id = sb_book
ORDER BY real_count DESC;

/* 53. show:
a) all authors, who has written more than one book;*/
SELECT authors.a_id, authors.a_name
FROM authors
JOIN m2m_books_authors ON  m2m_books_authors.a_id = authors.a_id
GROUP BY authors.a_id, authors.a_name
HAVING COUNT(m2m_books_authors.a_id) > 1;

/* b) all books that are written in more than one genre;*/
SELECT books.b_id, books.b_name
FROM books
JOIN m2m_books_genres ON books.b_id = m2m_books_genres.b_id
GROUP BY books.b_id, books.b_name
HAVING COUNT(m2m_books_genres.b_id) > 1;

/* c) all subscribers having more than one book;*/
WITH many_books
AS (select sb_subscriber
						FROM subscriptions 
                        WHERE sb_is_active = 'Y'
                        group by sb_subscriber
                        having count(sb_subscriber) >1)
SELECT s_id, s_name
FROM subscribers 
JOIN many_books ON s_id = sb_subscriber;

/* d) how many copies of each book is taken by subscribers;*/
WITH copies AS (
SELECT sb_book, COUNT(sb_book) as quantity
FROM subscriptions
WHERE sb_is_active = 'Y'
GROUP BY sb_book)
SELECT b_id, b_name, quantity
FROM books
JOIN copies ON b_id =sb_book;

/* e) all authors along with total copies of their books;*/
WITH tab AS (SELECT authors.a_id, authors.a_name, books.b_quantity
FROM authors
JOIN m2m_books_authors ON  m2m_books_authors.a_id = authors.a_id
JOIN books ON books.b_id = m2m_books_authors.b_id
)
SELECT a_name, SUM(b_quantity) AS quantity
FROM tab
GROUP BY a_name;

/* f) all authors along with count their books (just books, not copies);*/
WITH tab AS (SELECT authors.a_name AS author, books.b_name AS 'book(s)'
FROM authors
JOIN m2m_books_authors ON m2m_books_authors.a_id = authors.a_id
JOIN books ON books.b_id = m2m_books_authors.b_id
)
SELECT author, COUNT('book(s)') AS qyantity
FROM tab
GROUP BY author
ORDER BY author;

/* g) all subscribers with overdue subscriptions (along with books copies count).*/
WITH sub AS (SELECT sb_subscriber, sb_book
FROM subscriptions
WHERE sb_is_active = 'Y' AND sb_finish < GETDATE()
)
SELECT sb_subscriber, s_name, COUNT(sb_book) AS quantity
FROM sub
JOIN subscribers ON sub.sb_subscriber = subscribers.s_id
GROUP BY sb_subscriber, s_name;

/* 17) JOINs with COUNT and Aggregation Functions (54-59)*/
/* 54. Show all authors along  with subscription to their books count */
SELECT authors.a_id, authors.a_name, COUNT(sb_book) AS books
FROM authors
JOIN m2m_books_authors ON m2m_books_authors.a_id = authors.a_id
LEFT OUTER JOIN subscriptions ON m2m_books_authors.b_id = sb_book
GROUP BY authors.a_id, authors.a_name
ORDER BY COUNT(sb_book) DESC;

/* 55. Show the most popular author(s) */
-- Variant 1: usind MAX
WITH prepared_data AS (
	SELECT authors.a_id, authors.a_name, COUNT(sb_book) AS books
	FROM authors
	JOIN m2m_books_authors ON m2m_books_authors.a_id = authors.a_id
	LEFT OUTER JOIN subscriptions ON m2m_books_authors.b_id = sb_book
	GROUP BY authors.a_id, authors.a_name
	)
SELECT a_id, a_name, books
FROM prepared_data
WHERE books = (SELECT MAX(books)
	FROM prepared_data);

-- Variant 2: usung RANK
WITH prepared_data
AS (SELECT authors.a_id, authors.a_name, COUNT(sb_book) AS books,
	RANK() OVER ( ORDER BY COUNT(sb_book) DESC) AS [rank]
	FROM authors
	JOIN m2m_books_authors ON m2m_books_authors.a_id = authors.a_id
	LEFT OUTER JOIN subscriptions ON m2m_books_authors.b_id = sb_book
	GROUP BY authors.a_id, authors.a_name)
SELECT a_id, a_name, books
FROM prepared_data
WHERE [rank] = 1;

-- Variant 3: using TOP ... WITH TIES
WITH prepared_data AS (
	SELECT authors.a_id, authors.a_name, COUNT(sb_book) AS books
	FROM authors
	JOIN m2m_books_authors ON m2m_books_authors.a_id = authors.a_id
	LEFT OUTER JOIN subscriptions ON m2m_books_authors.b_id = sb_book
	GROUP BY authors.a_id, authors.a_name
	)
SELECT TOP 1 WITH TIES a_id, a_name, books
FROM prepared_data
ORDER BY books DESC;

/* 56. Show average authors popularity*/
SELECT AVG(CAST(books AS FLOAT)) AS avg_reading
FROM (SELECT COUNT(sb_book) AS books
	FROM authors
	JOIN m2m_books_authors ON m2m_books_authors.a_id = authors.a_id
	LEFT OUTER JOIN subscriptions ON m2m_books_authors.b_id = sb_book
	GROUP BY authors.a_id) AS prepared_data;

/* 57. Show median authors popularity */
WITH popularity
	AS (SELECT COUNT(sb_book) AS books
	FROM authors
	JOIN m2m_books_authors ON m2m_books_authors.a_id = authors.a_id
	LEFT OUTER JOIN subscriptions ON m2m_books_authors.b_id = sb_book
	GROUP BY authors.a_id)
SELECT DISTINCT PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY books) OVER () AS Median
FROM popularity;

/* 58. Show if there's such an error as "subscribers have taken more copies of a book than there was in the library" (return 1 if error exists, 0 if doesn't)*/
WITH books_taken
	AS (SELECT sb_book, COUNT(sb_book) AS taken
	FROM subscriptions
	WHERE sb_is_active = 'Y'
	GROUP BY sb_book)
SELECT TOP 1 CASE
	WHEN EXISTS (SELECT TOP 1 b_id
				FROM books
				LEFT OUTER JOIN books_taken ON b_id = sb_book
				WHERE (b_quantity - ISNULL(taken, 0)) < 0)
	THEN 1
	ELSE 0
	END AS error_exists
FROM books_taken;

/* 59. show:
a1) genres popularity in the library;*/
SELECT genres.g_id, g_name, COUNT(b_id) AS popularity
FROM genres
LEFT OUTER JOIN m2m_books_genres ON m2m_books_genres.g_id = genres.g_id
GROUP BY genres.g_id, g_name
ORDER BY popularity DESC;

/*a2) genres popularity along subscribers;*/
SELECT genres.g_id, g_name, COUNT(books.b_id) AS popularity
FROM genres
JOIN m2m_books_genres ON m2m_books_genres.g_id = genres.g_id
JOIN books ON m2m_books_genres.b_id = books.b_id
LEFT OUTER JOIN subscriptions ON books.b_id = subscriptions.sb_book
GROUP BY genres.g_id, g_name
ORDER BY popularity DESC;

/*b) the most popular genre (or genres, if there are many);*/
WITH prepared_data
AS (SELECT genres.g_id, g_name, COUNT(books.b_id) AS popularity
FROM genres
JOIN m2m_books_genres ON m2m_books_genres.g_id = genres.g_id
JOIN books ON m2m_books_genres.b_id = books.b_id
LEFT OUTER JOIN subscriptions ON books.b_id = subscriptions.sb_book
GROUP BY genres.g_id, g_name)
SELECT g_id, g_name, popularity
FROM prepared_data
WHERE popularity = (SELECT MAX(popularity)
	FROM prepared_data);
    
/*c) average genres' popularity;*/
SELECT  AVG(CAST(popularity AS FLOAT)) AS avg_genre
FROM (
SELECT genres.g_id, g_name, COUNT(books.b_id) AS popularity
FROM genres
JOIN m2m_books_genres ON m2m_books_genres.g_id = genres.g_id
JOIN books ON m2m_books_genres.b_id = books.b_id
LEFT OUTER JOIN subscriptions ON books.b_id = subscriptions.sb_book
GROUP BY genres.g_id, g_name) AS prepared_data;

/*d) median genres' popularity */
WITH genres_popularity
AS (SELECT genres.g_id, g_name, COUNT(books.b_id) AS popularity
	FROM genres
JOIN m2m_books_genres ON m2m_books_genres.g_id = genres.g_id
JOIN books ON m2m_books_genres.b_id = books.b_id
LEFT OUTER JOIN subscriptions ON books.b_id = subscriptions.sb_book
GROUP BY genres.g_id, g_name)
SELECT DISTINCT PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY popularity) OVER () AS Median
FROM genres_popularity;

/* 18) Multiple and Compound Conditions (60-)*/
/* 60. Show all authors whose books belong to two or more genred simultaneously */
SELECT a_id, a_name, MAX(genres_count) AS genres_count
FROM (SELECT authors.a_id, authors.a_name, COUNT(m2m_books_genres.g_id) AS genres_count
	FROM authors
    JOIN m2m_books_authors ON authors.a_id = m2m_books_authors.a_id
    JOIN m2m_books_genres ON m2m_books_authors.b_id = m2m_books_genres.b_id
    GROUP BY authors.a_id, a_name, m2m_books_authors.b_id
    HAVING COUNT(m2m_books_genres.g_id) > 1) AS prepared_data
GROUP BY a_id, a_name;

/* 61. Show all authors who ever worked in two or more genres */  
SELECT prepared_data.a_id, a_name, COUNT(g_id) AS genres_count
FROM (SELECT DISTINCT m2m_books_authors.a_id, m2m_books_genres.g_id
	FROM m2m_books_genres
    JOIN m2m_books_authors ON m2m_books_genres.b_id = m2m_books_authors.b_id
    ) AS prepared_data
JOIN authors ON  prepared_data.a_id = authors.a_id
GROUP BY prepared_data.a_id, a_name
HAVING COUNT(g_id) > 1;

/* 62. show all subscribers who has ever taken books with maximum genres variety (per one book)*/
SELECT s_id, s_name, MAX(genres_count) AS genres_count
FROM (SELECT books.b_id,
			books.b_name,
			COUNT(m2m_books_genres.g_id) AS genres_count
	FROM books
        JOIN m2m_books_genres ON  books.b_id = m2m_books_genres.b_id
    GROUP BY  
			books.b_id,
			books.b_name
	HAVING COUNT(m2m_books_genres.g_id) > 1) AS prepared_data
JOIN subscriptions ON b_id = sb_book
JOIN subscribers ON sb_subscriber = s_id
GROUP BY s_id, s_name;

/* 63. show all subscribers who reads books of the most versatile genres (even if each book is in one genre only)*/
SELECT s_id, s_name, COUNT(g_id) AS genres_count
FROM (SELECT DISTINCT books.b_id, m2m_books_genres.g_id, subscriptions.sb_subscriber
	FROM books
    JOIN m2m_books_genres ON  books.b_id = m2m_books_genres.b_id
    JOIN subscriptions ON m2m_books_genres.b_id = subscriptions.sb_book
     ) AS prepared_data
JOIN subscribers ON prepared_data.sb_subscriber = subscribers.s_id
GROUP BY s_id, s_name
HAVING COUNT(g_id) > 1;

/* 19) JOINs with MIN, MAX, AVG, range (64-69)*/
/* 64. Show the subscriber who was the first library client (i.e. the first to take a book)*/
-- Variant 1: using MIN
SELECT s_name
FROM subscribers
WHERE s_id = (SELECT sb_subscriber
	FROM subscriptions
    WHERE sb_id = (SELECT MIN(sb_id)
					FROM subscriptions));
-- Variant 2: using ordering
SELECT s_name
FROM subscribers
WHERE s_id = (SELECT TOP 1 sb_subscriber
	FROM subscriptions
    ORDER BY sb_id ASC );

/* 65. Show the subscriber (or subscribers, if many) who spent the less time reading a book (take into account only returned books)*/
-- Variant 1: using subquery and ordering
SELECT DISTINCT s_id, s_name, DATEDIFF(day, sb_start, sb_finish) as [days]
FROM subscribers
JOIN subscriptions ON s_id = sb_subscriber
WHERE sb_is_active = 'N'
AND DATEDIFF(day, sb_start, sb_finish) = 
	(SELECT TOP 1 DATEDIFF(day, sb_start, sb_finish) as [days]
    FROM subscriptions
    WHERE sb_is_active = 'N'
    ORDER BY [days] ASC
    );

-- Variant 2: using Common Table Expression and MIN
WITH prepared_data
AS (SELECT DISTINCT s_id, s_name, DATEDIFF(day, sb_start, sb_finish) as [days]
	FROM subscribers
    JOIN subscriptions ON s_id = sb_subscriber
    WHERE sb_is_active = 'N')
SELECT s_id, s_name, [days]
FROM prepared_data
WHERE [days] = (SELECT MIN([days])
				FROM prepared_data);

-- Variant 3:  using Common Table Expression and rank
WITH prepared_data
AS (SELECT DISTINCT s_id, s_name, DATEDIFF(day, sb_start, sb_finish) as [days],
	RANK() OVER (ORDER BY DATEDIFF(day, sb_start, sb_finish) ASC) as [rank]
    FROM subscribers
    JOIN subscriptions ON s_id = sb_subscriber
    WHERE sb_is_active = 'N')
SELECT s_id, s_name, [days]
FROM prepared_data
WHERE [rank] = 1;

/* 66. For each subscriber show the list of books he has taken during his first visit to the library */
WITH step_1
	AS (SELECT sb_subscriber, MIN(sb_start) AS min_date
		FROM subscriptions
		GROUP BY sb_subscriber),
	step_2
	AS (SELECT subscriptions.sb_subscriber,
				subscriptions.sb_book
		FROM subscriptions
		JOIN step_1 ON subscriptions.sb_subscriber = step_1.sb_subscriber
			AND subscriptions.sb_start = step_1.min_date),
	step_3
	AS (SELECT s_id, s_name, b_name
		FROM subscribers
		JOIN step_2 ON s_id = sb_subscriber
		JOIN books ON sb_book = b_id)
SELECT s_id, s_name, 
	STRING_AGG([b_name], ', ') WITHIN GROUP (ORDER BY [b_name] ASC) AS [books_list]
	/*STUFF (( SELECT ', ' + [int].b_name
			FROM step_3 AS [int]
			WHERE ext.s_id = [int].s_id
			ORDER BY [int].b_name
			FOR xml path(''), type).value('.', 'nvarchar(max)'),1,2,'') AS books_list*/
FROM step_3 AS ext
GROUP BY s_id, s_name;

/* 67. For each subscriber show the first book he has taken from the library */
-- Varinat 1a: four steps without ranking
SELECT s_id, s_name, b_name
FROM (SELECT subscriptions.sb_subscriber, sb_book
	FROM subscriptions
    JOIN (SELECT subscriptions.sb_subscriber,
				MIN(sb_id) AS min_sb_id
			FROM subscriptions
            JOIN (SELECT sb_subscriber, MIN(sb_start) AS min_sb_start
				FROM subscriptions
                GROUP BY sb_subscriber) AS step_1
			ON subscriptions.sb_subscriber = step_1.sb_subscriber
            AND subscriptions.sb_start = step_1.min_sb_start
		GROUP BY subscriptions.sb_subscriber, min_sb_start) AS step_2
	ON subscriptions.sb_id = step_2.min_sb_id) AS step_3
JOIN subscribers ON sb_subscriber = s_id
JOIN books ON sb_book = b_id;

-- Varinat 1a: four steps without ranking
WITH step_1
	AS (SELECT sb_subscriber, MIN(sb_start) AS min_sb_start
		FROM subscriptions
		GROUP BY sb_subscriber),
	step_2
	AS (SELECT subscriptions.sb_subscriber, MIN(sb_id) AS min_sb_id
		FROM subscriptions
		JOIN step_1 ON subscriptions.sb_subscriber = step_1.sb_subscriber
		AND subscriptions.sb_start = step_1.min_sb_start
		GROUP BY subscriptions.sb_subscriber, min_sb_start),
	step_3
	AS (SELECT subscriptions.sb_subscriber, sb_book
		FROM subscriptions
		JOIN step_2 ON subscriptions.sb_id = step_2.min_sb_id)
SELECT s_id, s_name, b_name
FROM step_3
JOIN subscribers ON sb_subscriber = s_id
JOIN books ON sb_book = b_id;

-- Variant 2: two steps with ranking
WITH step_1
	AS (SELECT sb_subscriber, sb_start, sb_id, sb_book,
		ROW_NUMBER() OVER(
			PARTITION BY sb_subscriber
			ORDER BY sb_subscriber ASC) AS rank_by_subscriber,
        ROW_NUMBER() OVER(
			PARTITION BY sb_subscriber, sb_start
			ORDER BY sb_subscriber, sb_start ASC) AS rank_by_date
        FROM subscriptions)
SELECT s_id, s_name, b_name
FROM step_1
JOIN subscribers ON sb_subscriber = s_id
JOIN books ON sb_book = b_id
WHERE rank_by_subscriber = 1 AND rank_by_date = 1;

-- Variant 3: three steps with rank and grouping
WITH step_1
	AS (SELECT sb_subscriber, sb_start,
			MIN(sb_id) AS min_sb_id,
			RANK() OVER( PARTITION BY sb_subscriber ORDER BY sb_start ASC) AS [rank]
		FROM subscriptions
		GROUP BY sb_subscriber, sb_start),
	step_2
	AS (SELECT subscriptions.sb_subscriber, subscriptions.sb_book
		FROM subscriptions
		JOIN step_1 ON subscriptions.sb_id = step_1.min_sb_id
		WHERE [rank] = 1)
SELECT s_id, s_name, b_name
FROM step_2
JOIN subscribers ON sb_subscriber = s_id
JOIN books ON sb_book = b_id;

/*68. show the subscriber who was (for now) the last library client (i.e., the last to take a book)*/
WITH t 
	AS (SELECT TOP 1 sb_subscriber
		FROM subscriptions
    ORDER BY sb_start DESC)
SELECT s_name
FROM subscribers
JOIN t ON s_id = sb_subscriber;

/*69. the subscriber (or subscribers, if many) who spent the most time reading a book (take into account only returned books)*/
WITH prepared_data
AS (SELECT DISTINCT s_id, s_name, DATEDIFF(day, sb_start, sb_finish) as [days],
	RANK() OVER (ORDER BY DATEDIFF(day, sb_start, sb_finish) DESC) as [rank]
    FROM subscribers
    JOIN subscriptions ON s_id = sb_subscriber
    WHERE sb_is_active = 'N')
SELECT s_id, s_name, [days]
FROM prepared_data
WHERE [rank] = 1;

/* 20) All JOINs (70-77)*/
/* 70. INNER JOIN: to show list of subscribers along with dates of each their visit to the library;*/
SELECT s_id, s_name, sb_start
FROM subscribers 
JOIN subscriptions ON s_id = sb_subscriber
order by s_id, sb_start;

/* 71. LEFT OUTER JOIN: list of ALL subscribers along with dates of each their visit to the library (no mater if a subscriber ever visited the library or not);*/
SELECT s_id, s_name, sb_start
FROM subscribers 
LEFT JOIN subscriptions ON s_id = sb_subscriber
order by s_id, sb_start;

/* 72. Exclusive LEFT OUTER JOIN: list of subscribers who has never visited the library;*/
SELECT s_id, s_name
FROM subscribers 
LEFT JOIN subscriptions ON s_id = sb_subscriber
WHERE sb_subscriber IS NULL;

/* 73. list of books that were never taken by any subscriber;*/
SELECT DISTINCT b_id, b_name
FROM books
LEFT JOIN subscriptions ON b_id = sb_book
WHERE sb_book IS NULL;

/* 74. list of all subscribers along with all books potentially available to each subscriber;*/
/* 75. list of all subscribers along with all books each subscriber had never taken from the library;*/
/* 76. list of all subscribers along with all books (issued before 2010) potentially available to each subscriber;*/
/* 77. list of all subscribers along with all books (issued before 2010) each subscriber had never taken from the library.*/

/* 21) Data Insertion (78-79)*/
/* 78. Add to the database the following information: on Jan 15, 2016 a subscriber with id 4 has taken a book with id 3 and has promised to return it on Jan 30, 2016. */
/* ! in MS SQL we do not pass Primary Key at all. Otherwise we have to pass an explicit unique value and use SET IDENTITY_INSERT [subscriptions] ON (and then OFF)*/
INSERT INTO subscriptions
	(sb_subscriber,
    sb_book,
    sb_start,
    sb_finish,
    sb_is_active)
VALUES (4,
    3,
    CAST('2016-01-15' AS DATE),
    CAST('2016-01-30' AS DATE),
    'N');
INSERT INTO subscriptions
	(sb_subscriber,
    sb_book,
    sb_start,
    sb_finish,
    sb_is_active)
VALUES (4,
    3,
    '2016-01-15',
    '2016-01-30',
    'N');

/* 79. Add to the database the following information: on Jan 25, 2016 a subscriber with id 2 has taken books with ids 1,3,5 and has promised to return it on Apr 30, 2016. */
INSERT INTO subscriptions
	(sb_subscriber,
    sb_book,
    sb_start,
    sb_finish,
    sb_is_active)
VALUES (2,
    1,
    CAST('2016-01-25' AS DATE),
    CAST('2016-04-30' AS DATE),
    'N'),
    (2,
    3,
    CAST('2016-01-25' AS DATE),
    CAST('2016-04-30' AS DATE),
    'N'),
    (2,
    5,
    CAST('2016-01-25' AS DATE),
    CAST('2016-04-30' AS DATE),
    'N');

/* 22) Data Update (80-84)*/
/* 80. Update subscription with id 99 changing the return date to current date and making the book as returned*/
UPDATE subscriptions
SET sb_finish = CONVERT(date, GETDATE()), /* ��� ������� ���� ���� '2021-04-09'*/
	sb_is_active = N'N'
WHERE sb_id = 99; /* ����������� ��������� �������, ����� ����� ��������� ��� ���� ������� */  
  
/* 81. For all books that were taken on Jan 25, 2016 by the subscriber with id 2 prolong promised return date for two months */
UPDATE subscriptions
SET sb_finish = DATEADD(month, 2, sb_finish)
WHERE sb_subscriber = 2
	AND sb_start = CONVERT(date, '2016-01-25');
	
/* 82. mark all subscriptions with ids <=50 as returned;*/
UPDATE subscriptions
SET sb_is_active = 'N'
WHERE sb_id <= 50;

/* 83. decrease by three days the start date for all subscriptions made before Jan 1st 2012;*/
UPDATE subscriptions
SET sb_start = DATEADD(day, -3, sb_start)
WHERE sb_start < CONVERT(date, '2012-01-01');

/* 84. mark all subscriptions made by the subscriber with id 2 as NOT returned.*/
UPDATE subscriptions
SET sb_is_active = 'Y'
WHERE sb_subscriber = 2;

/* 23) Data Deletion (85-87)*/
/* 85. Delete information about that fact that a subscriber with id 4 on Jan 15,2016 has taken a book with id 3. */
DELETE FROM subscriptions
WHERE sb_subscriber = 4
AND sb_start = CONVERT(date, '2016-01-15')
AND sb_book = 3;

/* 86. Delete information about all subscriptions made by a subscriber with id 3 on Sundays */
DELETE FROM subscriptions
WHERE sb_subscriber = 3
AND DATEPART(weekday, sb_start) = 7; /* 1 - Monday*/

/* 87. delete all subscriptions made after 20th day of each month*/
DELETE FROM subscriptions
WHERE DATEPART(day, sb_start) > 20;

/* 24) Data Merging (88-89)*/
/* 88. Add "Philosophy", "Detective", "Classic" genres to the database (no genres duplication allowed)*/
MERGE INTO genres
USING (VALUES (N'Philosophy'),
				(N'Detective'),
				(N'Classic') ) AS new_genres(g_name)
ON genres.g_name = new_genres.g_name
WHEN NOT MATCHED BY TARGET THEN
	INSERT (g_name)
	VALUES (new_genres.g_name);

/* 89. Copy all genres from "Library for experiments" database to "Library" one. In case of primary keys duplication add "[OLD]" suffix to the existing genre's name. */
-- Allow explicit data insertion into IDENTITY-field:
SET IDENTITY_INSERT [genres] ON;
-- Merge data:
MERGE [library].[dbo].[genres] AS [destination]
USING [library_exp].[dbo].[genres] AS [source]
ON [destination].[g_id] = [source].[g_id]
WHEN MATCHED THEN
UPDATE SET [destination].[g_name] = CONCAT([destination].[g_name], N' [OLD]')
WHEN NOT MATCHED THEN
INSERT ([g_id], [g_name])
VALUES ([source].[g_id], [source].[g_name]);
-- Prohibit explicit data insertion into IDENTITY-field:
SET IDENTITY_INSERT [genres] OFF;

/* 25) Conditional Data Modification (90)*/
/* 90. Add to the database the information about such a fact that on
Feb 1st 2015 the subscriber with id 4 had taken books with ids 2
and 3, he had promised to return those books on July 20th 2015.
If current date is less than July 20th 2015 mark these
subscriptions as "not returned", or mark them as "returned"
otherwise.*/
INSERT INTO subscriptions
	(sb_subscriber,
    sb_book,
    sb_start,
    sb_finish,
    sb_is_active)
    VALUES
    (4,
    2,
    CONVERT(date, '2015-02-01'),
    CONVERT(date, '2015-07-20'),
    CASE
		WHEN CONVERT(date,GETDATE()) < CONVERT(date, '2015-07-20')
        THEN (SELECT 'Y')
        ELSE (SELECT 'N')
	END
    ),
    (4,
    3,
    CONVERT(date, '2015-02-01'),
    CONVERT(date, '2015-07-20'),
    CASE
		WHEN CONVERT(date,GETDATE()) < CONVERT(date, '2015-07-20')
        THEN (SELECT 'Y')
        ELSE (SELECT 'N')
	END
    );

SELECT *
FROM subscriptions;