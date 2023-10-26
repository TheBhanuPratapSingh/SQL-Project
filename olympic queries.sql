-- 1. TOTAL NUMBER OF OLYMPIC GAMES HAVE BEEN HELD.

SELECT COUNT(DISTINCT Games) AS Total_Olympic_Games
FROM athlete_events;

-- 2. LIST DOWN ALL OLYMPIC GAMES HELD SO FAR

SELECT DISTINCT year, season, city
FROM athlete_events
ORDER BY year;

-- 3. MENTION THE TOTAL NUMBER OF NATIONS PARTICIPATED IN EACH OLYMICS GAME

WITH cte AS 
(SELECT games, noc.region
FROM athlete_events ae
JOIN noc_regions noc 
ON ae.NOC = noc.NOC)
SELECT games, count(DISTINCT region) AS total_countries
FROM cte
GROUP BY games;


-- 4. WHICH YEAR SAW THE HIGHEST AND LOWEST NUMBER OF COUNTRIES PARTICIPATING IN OLYMPICS

WITH cte1 AS 
(SELECT DISTINCT games, region
FROM athlete_events a
JOIN noc_regions n ON a.NOC = n.NOC),
cte2 AS 
(SELECT games, count(DISTINCT region) AS total_countries
FROM cte1 GROUP BY games),
cte3 AS 
(SELECT *,concat(games, "_", total_countries) AS final
FROM cte2)
SELECT FIRST_VALUE(final) over (ORDER BY total_countries ASC) AS least_attendance,
FIRST_VALUE(final) over (
ORDER BY total_countries DESC) AS highest_attendance
FROM cte3 LIMIT 1;

-- 5. WHICH NATION HAS PARTICIPATED IN ALL THE OLYMPIC GAMES

WITH cte1 AS 
(SELECT region, count(DISTINCT games) AS n_participated
FROM athlete_events ae
JOIN noc_regions noc 
ON noc.noc = ae.noc
GROUP BY region
ORDER BY n_participated DESC),
cte2 AS
(SELECT count(DISTINCT games) AS n_games
FROM athlete_events)
SELECT region
FROM cte1 JOIN cte2 
ON cte2.n_games = cte1.n_participated;

-- 6.IDENTIFY THE SPORTS WHICH WAS PLAYED IN ALL THE SUMMER OLYMPIC GAMES

WITH cte1 AS 
(SELECT sport, count(DISTINCT games) AS no_games 
FROM athlete_events
GROUP BY sport),
cte2 AS 
(SELECT count(DISTINCT games) AS total_games
FROM athlete_events
WHERE Season = 'Summer')
SELECT sport, no_games, total_games
FROM cte1 JOIN cte2 
ON cte2.total_games = cte1.no_games
ORDER BY sport;

-- 7.SPORTS WHICH WERE JUST PLAYED ONCE IN ALL THE OLYMPICS

WITH cte AS 
(SELECT sport, count(DISTINCT games) AS no_games
FROM athlete_events
GROUP BY sport)
SELECT DISTINCT cte.sport, no_games, ae.games
FROM cte JOIN athlete_events ae 
ON ae.sport = cte.sport
WHERE no_games = 1
ORDER BY cte.sport;

-- 8.FETCH THE TOTAL NUMBER OF SPORTS PLAYED IN EACH OLYMPIC GAMES

SELECT games, count(DISTINCT sport)
FROM athlete_events
GROUP BY
Games
ORDER BY games DESC;

-- 9.FETCH THE OLDEST ATHLETES TO WIN THE GOLD MEDALS

WITH cte1 AS 
(SELECT name, medal, age
FROM athlete_events
WHERE medal = 'Gold' AND age IS NOT NULL),
cte2 AS 
(SELECT name, medal, age, DENSE_RANK() over (ORDER BY age DESC) AS rnk
FROM cte1)
SELECT name, medal, age FROM cte2 WHERE
rnk = 1;

-- 1O.FIND THE RATIO OF MALE AND FEMALE ATHLETES PARTICIPATED IN ALL OLYMPIC GAMES

with cte as
(SELECT
CASE WHEN sex = 'M' THEN 1 ELSE 0 END AS male,
CASE WHEN sex = 'F' THEN 1 ELSE 0 END AS female
FROM athlete_events)
SELECT CONCAT(1,":",ROUND(sum(male) / sum(female),2)) as ratio
FROM cte;

-- 11.FETCH THE TOP 5 ATHLETES WHO HAVE WON THE MOST GOLD MEDALS

WITH cte AS 
(SELECT name,
CASE WHEN medal = 'Gold' THEN 1 ELSE 0 END AS gold
FROM athlete_events)
SELECT name, sum(gold) AS golds
FROM cte
GROUP BY name
ORDER BY golds DESC
LIMIT 5;

-- 12.FETCH THE TOP 5 ATHLETES WHO HAVE WON THE MOST MEDALS (GOLD/SILVER/BRONZE)

WITH cte AS 
(SELECT name,
CASE WHEN medal IS NOT NULL THEN 1 ELSE 0 END AS medals
FROM athlete_events)
SELECT name, sum(medals) AS most_medals
FROM cte
GROUP BY name
ORDER BY most_medals DESC
LIMIT 5;

-- 13.FETCH THE TOP 5 SUCCESSFUL COUNTRIES IN OLYMPICS. SUCCESS IS DEFINED BY NUMBER OF MEDALS WON.

WITH cte1 AS (
SELECT region,
CASE WHEN medal IS NOT NULL THEN 1 ELSE 0 END AS medals
FROM athlete_events ae
JOIN noc_regions noc 
ON noc.noc = ae.noc),
cte2 AS 
(SELECT region, sum(medals) AS total_medals 
FROM cte1
GROUP BY region
ORDER BY total_medals DESC)
SELECT region, total_medals,
rank() over (ORDER BY total_medals DESC) AS rnk
FROM cte2
LIMIT 5;

-- 14. LIST DOWN TOTAL GOLD/SILVER/BRONZE MEDALS WON BY EACH COUNTRY

WITH cte AS 
(SELECT region,
IF(medal = 'Gold', 1, 0) gold,
IF(medal = 'silver', 1, 0) silver,
IF(medal = 'bronze', 1, 0) bronze
FROM athlete_events a
JOIN noc_regions n 
ON n.noc = a.noc)
SELECT region, sum(gold) gold, sum(silver) silver, sum(bronze) bronze
FROM cte 
GROUP BY region
ORDER BY gold DESC, silver DESC, bronze DESC;

-- 15. LIST DOWN TOTAL GOLD/SILVER/BRONZE MEDALS WON BY EACH COUNTRY CORRESPONDING TO EACH OLYMPIC GAMES.

SELECT a.games AS games, n.region AS country, 
SUM(IF(medal = "gold", 1, 0)) AS gold_medals,
SUM(IF(medal = "silver",1 , 0)) AS silver_medals,
SUM(IF(medal = "bronze",1 , 0)) AS bronze_medals
FROM athlete_events a JOIN noc_regions n
ON a.NOC = n.NOC
GROUP BY games, country
ORDER BY games;


-- 16. IDENTIFY WICH COUNTRY WON MOST GOLD, MOST SILVER MOST BRONZE IN EACH OLYMPIC GAMES.

WITH cte1 AS
(SELECT a.games AS games, n.region AS country, 
SUM(IF(medal = "gold", 1, 0)) AS gold_medals,
SUM(IF(medal = "silver",1 , 0)) AS silver_medals,
SUM(IF(medal = "bronze",1 , 0)) AS bronze_medals
FROM athlete_events a JOIN noc_regions n
ON a.NOC = n.NOC
GROUP BY games, country
ORDER BY games),
cte2 as
(select *,
(rank() over(partition by games ORDER BY gold_medals DESC))  max_gold,
(rank() over(partition by games ORDER BY silver_medals DESC)) max_silver, 
(rank() over(partition by games ORDER BY bronze_medals DESC)) max_bronze 
FROM cte1),
cte3 as
(SELECT games,
IF(max_gold = 1, concat(country, '-', gold_medals), NULL) max_gold,
IF(max_silver = 1,concat(country, '-', silver_medals),NULL) max_silver,
IF(max_bronze = 1,concat(country, '-', bronze_medals),NULL) max_bronze
FROM cte2
ORDER BY games)
SELECT games,
GROUP_CONCAT(max_gold) max_gold,
GROUP_CONCAT(max_silver) max_silver,
GROUP_CONCAT(max_bronze) max_bronze
FROM cte3 GROUP BY games;


/* 17. IDENTIFY WICH COUNTRY WON MOST GOLD, MOST SILVER MOST BRONZE IN EACH OLYMPIC GAMES.
	   AND THE MOST MEDALS IN EACH OLYMPICS */

WITH cte1 AS
(SELECT a.games AS games, n.region AS country, 
SUM(IF(medal = "gold", 1, 0)) AS gold_medals,
SUM(IF(medal = "silver",1 , 0)) AS silver_medals,
SUM(IF(medal = "bronze",1 , 0)) AS bronze_medals,
SUM(IF(medal in ("gold","silver","bronze"),1,0)) as total_medals
FROM athlete_events a JOIN noc_regions n
ON a.NOC = n.NOC
GROUP BY games, country
ORDER BY games),
cte2 as
(select *,
(rank() over(partition by games ORDER BY gold_medals DESC))  max_gold,
(rank() over(partition by games ORDER BY silver_medals DESC)) max_silver, 
(rank() over(partition by games ORDER BY bronze_medals DESC)) max_bronze,
(rank() over(partition by games ORDER BY total_medals DESC)) max_medal 
FROM cte1),
cte3 as
(SELECT games,
IF(max_gold = 1, concat(country, '-', gold_medals), NULL) max_gold,
IF(max_silver = 1,concat(country, '-', silver_medals),NULL) max_silver,
IF(max_bronze = 1,concat(country, '-', bronze_medals),NULL) max_bronze,
IF(max_medal = 1,concat(country, '-', total_medals),NULL) max_medal
FROM cte2
ORDER BY games)
SELECT games,
GROUP_CONCAT(max_gold) max_gold,
GROUP_CONCAT(max_silver) max_silver,
GROUP_CONCAT(max_bronze) max_bronze,
GROUP_CONCAT(max_medal) max_medal
FROM cte3 GROUP BY games;

-- 18. WHICH COUNTRY NEVER WON GOLD MEDAL BUT HAVE WON SILVER/BRONZE MEDALS?

WITH cte1 AS
(SELECT a.games AS games, n.region AS country, 
SUM(IF(medal = "gold", 1, 0)) AS gold_medals,
SUM(IF(medal = "silver",1 , 0)) AS silver_medals,
SUM(IF(medal = "bronze",1 , 0)) AS bronze_medals
FROM athlete_events a JOIN noc_regions n
ON a.NOC = n.NOC
GROUP BY games, country
ORDER BY games)
SELECT * FROM cte1 WHERE 
gold_medals = 0 AND (silver_medals > 0 OR bronze_medals > 0);

-- 19. IN WHICH SPORT INDIA HAS WON HIGHEST MEDALS

SELECT NOC,Sport, COUNT(Medal) AS Total_Medal
FROM athlete_events 
WHERE noc = 'IND' AND medal != 'NA'
GROUP BY NOC, Sport
ORDER BY COUNT(Medal) DESC
LIMIT 1;


-- 20. BREAK DOWN ALL OLYMPIS GAMES WHERE INDIA HAS WON MEDALS IN HOCKEY AND MENTION NUMBERS ALSO 

SELECT games, NOC, Sport, COUNT(Medal) AS Total_Medal
FROM athlete_events 
WHERE noc = 'IND'AND medal != 'NA' AND sport = "Hockey"
GROUP BY NOC, Sport,games
ORDER BY COUNT(Medal) DESC;







