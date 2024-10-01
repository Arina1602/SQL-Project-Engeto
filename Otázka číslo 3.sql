/* Otazka cislo 3 
 * Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
 */

CREATE OR REPLACE VIEW v_arina_spirkova_avg_food_price_by_year AS 
SELECT 
    food_category,
    price_value AS value, 
    price_unit AS unit, 
    payroll_year AS year, 
    ROUND(AVG(price), 2) AS avg_price
FROM t_Arina_Spirkova_project_SQL_primary_final taspspf 
GROUP BY food_category, price_value, price_unit, payroll_year;


CREATE OR REPLACE VIEW v_arina_spirkova_food_price_trend AS
SELECT 
    older.food_category, 
    older.value,
    older.unit,
    older.year AS older_year,
    older.avg_price AS older_price,
    newer.year AS newer_year,
    newer.avg_price AS newer_price, 
    newer.avg_price - older.avg_price AS price_difference_czk,
    ROUND((newer.avg_price - older.avg_price) / older.avg_price * 100, 2) AS price_difference_percent,
    CASE
        WHEN newer.avg_price > older.avg_price 
        THEN 'UP'
        ELSE 'DOWN'
    END AS price_trend
FROM v_arina_spirkova_avg_food_price_by_year AS older
JOIN v_arina_spirkova_avg_food_price_by_year AS newer 
    ON older.food_category = newer.food_category
    AND newer.year = older.year + 1
ORDER BY older.food_category, older.year;

SELECT *
FROM v_arina_spirkova_avg_food_price_by_year;

-- Dotaz zaměřený na výpočet průměrného meziročního růstu cen potravin za období od roku 2006 do roku 2018.
SELECT 
    food_category,
    AVG(price_difference_percent) AS avg_annual_growth_percent
FROM v_arina_spirkova_food_price_trend
WHERE older_year BETWEEN 2006 AND 2017
    AND newer_year BETWEEN 2007 AND 2018
GROUP BY food_category
ORDER BY avg_annual_growth_percent ASC;

/* 
Cukr krystalový je jedním z produktů, jehož cena rostla nejméně ze všech potravinových kategorií. Ve skutečnosti výsledky ukazují, že cena této kategorie dokonce klesala každý rok průměrně o  -1,92 %.
*/
