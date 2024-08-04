/* Tabulka cislo 1
 * pro data mezd a cen potravin za Českou republiku 
 * sjednocených na totožné porovnatelné období – společné roky
 */

CREATE TABLE OR REPLACE t_Arina_Spirkova_project_SQL_primary_final AS
SELECT
	cpc.name AS food_category,
	cpc.price_value,
	cpc.price_unit,
	cp.value AS price,
	cp.date_from,
	cp.date_to,
	cpay.payroll_year ,
	cpay.value AS avg_wages,
	cpib.name AS industry_branch
FROM czechia_price cp
JOIN czechia_payroll cpay 
	ON YEAR(cp.date_from) = cpay.payroll_year
	AND cpay.value_type_code = '5958'
	AND cp.region_code IS NULL
JOIN czechia_price_category cpc 
	ON cp.category_code = cpc.code
JOIN czechia_payroll_industry_branch cpib 
	ON cpay.industry_branch_code = cpib.code;

SELECT *
FROM t_Arina_Spirkova_project_SQL_primary_final taspspf 
ORDER BY food_category, date_from, price_value;


/* Tabulka cislo 2
 * pro dodatečná data o dalších evropských státech
 */

CREATE OR REPLACE  TABLE t_Arina_Spirkova_project_SQL_secondary_final AS
SELECT 
	e.country,
	e.population,
	e.gini,
	e.GDP,
	e.year
FROM economies e 
JOIN countries c ON e.country = c.country
WHERE c.continent = 'Europe'
	AND e.GDP IS NOT NULL;

/* Otázka číslo 1
Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
*/

-- 1. Vytvoříme pohled pro průměrné mzdy podle roku a sektoru práce
CREATE OR REPLACE VIEW 
	v_arina_spikova_avg_wages_by_year_and_Sector AS
SELECT
	industry_branch,
	payroll_year,
	ROUND(AVG(avg_wages)) AS avg_wages_CZK
FROM t_Arina_Spirkova_project_SQL_primary_final taspspf 
GROUP BY industry_branch, payroll_year;

-/* Popis:
*Tento dotaz vytváří pohled, který zobrazuje průměrné mzdy v korunách pro jednotlivá odvětví v konkrétních letech. 
*Data jsou seskupena podle odvětví (industry_branch) a roku (payroll_year), přičemž se vypočítává průměrná mzda pro každou kombinaci 
*těchto hodnot.
*/

-- Zobrazení dat z vytvořeného pohledu
SELECT * 
FROM v_arina_spikova_avg_wages_by_year_and_Sector; -- Tento dotaz jednoduše zobrazuje všechna data z pohledu v_arina_spikova_avg_wages_by_year_and_Sector, což znamená, že se zobrazí průměrné mzdy podle odvětví a roku

-- Vytvoření pohledu pro trend růstu mezd podle sektoru a roku
CREATE OR REPLACE VIEW v_arina_spirkova_wages_growth_trend_by_sector_and_year AS 
SELECT
    newer_avg.industry_branch, 
    older_avg.payroll_year AS older_year,
    older_avg.avg_wages_CZK AS older_wages,
    newer_avg.payroll_year AS newer_year,
    newer_avg.avg_wages_CZK AS newer_wages,
    newer_avg.avg_wages_CZK - older_avg.avg_wages_CZK AS wages_difference_czk,
    ROUND(((newer_avg.avg_wages_CZK / older_avg.avg_wages_CZK) * 100) - 100, 2) AS wages_difference_percentage,
    CASE
        WHEN newer_avg.avg_wages_CZK > older_avg.avg_wages_CZK THEN 'UP'
        ELSE 'DOWN'
    END AS wages_trend
FROM v_arina_spikova_avg_wages_by_year_and_Sector AS newer_avg
JOIN v_arina_spikova_avg_wages_by_year_and_Sector AS older_avg
    ON newer_avg.industry_branch = older_avg.industry_branch
    AND newer_avg.payroll_year = older_avg.payroll_year + 1
ORDER BY newer_avg.industry_branch;

/* Tento dotaz vytváří pohled, který analyzuje meziroční trend růstu mezd v jednotlivých odvětvích. 
 * Vypočítává se rozdíl mezi mzdami v jednotlivých letech a zobrazuje se, zda mzdy rostly (UP) nebo klesaly (DOWN). 
 * Pohled také ukazuje procentuální změnu mezd mezi těmito roky.
 */

-- Zobrazení dat z pohledu s trendy růstu mezd podle sektoru a roku
SELECT *
FROM v_arina_spirkova_wages_growth_trend_by_sector_and_year;

-- Mzdy ve všech sledovaných odvětí rostou, růst však nebyl rovnoměrný a byl zaznamenán i pokles.

-- Dotaz, který ukázuje odvětví a roky s klesajícími mzdami:
SELECT
    industry_branch,
    older_year,
    newer_year,
    older_wages,
    newer_wages,
    wages_difference_czk,
    wages_difference_percentage,
    wages_trend
FROM v_arina_spirkova_wages_growth_trend_by_sector_and_year
WHERE wages_trend = 'DOWN'
ORDER BY wages_difference_percentage ASC;

/* Tento dotaz filtruje data z pohledu v_arina_spirkova_wages_growth_trend_by_sector_and_year a zobrazuje pouze ty roky 
 * a odvětví, kde došlo k poklesu mezd.Data jsou seřazena podle procentuálního poklesu, přičemž na prvních místech jsou 
 * zobrazeny největší poklesy.
 */

-- Výsledkem posledního dotazu je zjištění, že největší meziroční pokles mezd byl zaznamenán v odvětví Peněžnictví a pojišťovnictví, 
-- kde průměrná mzda klesla o -8,91 % z 50 254 Kč na 45 775 Kč.

/* Otazka číslo 2
Kolik je možné si koupit litrů mléka a kilogramů chleba 
za první a poslední srovnatelné období v dostupných datech cen a mezd?
 */

SELECT 
	food_category,
	price_value,
	price_unit,
	payroll_year,
	ROUND(avg(price), 2) AS avg_price,
	ROUND(avg ( avg_wages) , 2) AS 'avg_wages',
	ROUND((round(avg(avg_wages), 2)) / (round(avg(price), 2))) AS avg_purchase_power
FROM t_Arina_Spirkova_project_SQL_primary_final taspspf 
WHERE payroll_year IN (2006,2018)
	AND food_category IN ('Mléko polotučné pasterované', 'Chléb konzumní kminový')
GROUP BY food_category, payroll_year;

/* ROK 2006 - 'Chleb konzumni kminovy' 
 * V roce 2006 prumerna cena byla 16.20 Kč pri prumerne mzde 20753.78 Kč se dalo koupit 1,287 kusu
 * Mleko polotucne pasterizovane
 * V roce 2006 prumerna cena byla 14.44 Kč pri prumerne mzde 20753.78 Kč se dalo koupit 1,437 kusu
 * ROK 2018 - Chleb konzumni kminovy 
 * V roce 2018 prumerna cena byla 24.24 Kč pri prumerne mzde 32535.86 Kč se dalo koupit 1342 kusu
 * Mleko polotucne pasterizovane
 * V roce 2018 prumerna cena byla 14.44 Kč pri prumerne mzde 32535.86 Kč se dalo koupit 1642 kusu
 */


/* Otazka cislo 3 
 * Která kategorie potravin zdražuje nejpomaleji 
 * (je u ní nejnižší percentuální meziroční nárůst)?
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
Cukr krystalový je jedním z produktů, jehož cena rostla nejméně ze všech potravinových kategorií. 
Ve skutečnosti výsledky ukazují, že cena této kategorie dokonce klesala každý rok průměrně o  -1,92 %.
*/

/* Otazka cislo 4
 * Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 */

CREATE VIEW Prumerna_mzda_v_CR_2006_2018 AS
SELECT
	industry_branch,
    payroll_year AS year,
    AVG(avg_wages) AS average_wage
FROM
    t_Arina_Spirkova_project_SQL_primary_final
WHERE
    payroll_year BETWEEN 2006 AND 2018
GROUP BY
    payroll_year
ORDER BY
    payroll_year;

SELECT *
FROM Prumerna_mzda_v_CR_2006_2018 pmvc;

CREATE VIEW Vyvoj_rustu_mezd AS
WITH wage_growth AS (
    SELECT
        payroll_year AS year,
        AVG(avg_wages) AS avg_wages
    FROM
        t_Arina_Spirkova_project_SQL_primary_final
    WHERE
        payroll_year BETWEEN 2006 AND 2018
    GROUP BY
        payroll_year
)
SELECT
    w1.year,
    ((w1.avg_wages - w0.avg_wages) / w0.avg_wages) * 100 AS wage_increase_pct
FROM
    wage_growth w1
JOIN
    wage_growth w0 ON w1.year = w0.year + 1
ORDER BY
    w1.year;

SELECT *
FROM Vyvoj_rustu_mezd vrm;

CREATE VIEW Prumerne_ceny_potravin_v_CR_2006_2018 AS
SELECT
	food_category,
    YEAR(date_from) AS year,
    AVG(price) AS average_price
FROM
    t_Arina_Spirkova_project_SQL_primary_final
WHERE
    YEAR(date_from) BETWEEN 2006 AND 2018
GROUP BY
    YEAR(date_from)
ORDER BY
    YEAR(date_from);
   
SELECT *
FROM `Průměrné_ceny_potravin` pmrcp;

CREATE VIEW Trend_vyvoje_rustu_cen_potravin AS
WITH price_growth AS (
    SELECT
        YEAR(date_from) AS year,
        AVG(price) AS avg_price
    FROM
        t_Arina_Spirkova_project_SQL_secondary_final
    WHERE
        YEAR(date_from) BETWEEN 2006 AND 2018
    GROUP BY
        YEAR(date_from)
)
SELECT
    p1.year,
    ((p1.avg_price - p0.avg_price) / p0.avg_price) * 100 AS price_increase_pct
FROM
    price_growth p1
JOIN
    price_growth p0 ON p1.year = p0.year + 1
ORDER BY
    p1.year;
   
SELECT *
FROM Trend_vyvoje_rustu_cen_potravin tvrcp;

CREATE VIEW Porovnani_mezirocniho_narustu_cen_a_mezd AS
WITH price_growth AS (
    SELECT
        YEAR(date_from) AS year,
        AVG(price) AS avg_price
    FROM
        t_Arina_Spirkova_project_SQL_primary_final
    GROUP BY
        YEAR(date_from)
),
wage_growth AS (
    SELECT
        payroll_year AS year,
        AVG(avg_wages) AS avg_wages
    FROM
        t_Arina_Spirkova_project_SQL_primary_final
    GROUP BY
        payroll_year
),
price_change AS (
    SELECT
        p1.year,
        ((p1.avg_price - p0.avg_price) / p0.avg_price) * 100 AS price_increase_pct
    FROM
        price_growth p1
    JOIN
        price_growth p0 ON p1.year = p0.year + 1
),
wage_change AS (
    SELECT
        w1.year,
        ((w1.avg_wages - w0.avg_wages) / w0.avg_wages) * 100 AS wage_increase_pct
    FROM
        wage_growth w1
    JOIN
        wage_growth w0 ON w1.year = w0.year + 1
)
SELECT
    p.year,
    p.price_increase_pct,
    w.wage_increase_pct
FROM
    price_change p
JOIN
    wage_change w ON p.year = w.year
ORDER BY
    p.year;
   
SELECT * 
FROM Porovnani_mezirocniho_narustu_cen_a_mezd;

/*	Otazka cislo 5
 * Má výška HDP vliv na změny ve mzdách a cenách potravin? 
 * Neboli, pokud HDP vzroste výrazněji v jednom roce, 
 * projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
 */

-- Шаг 1: Создание представления для ВВП в Чехии (2006-2018)
CREATE OR REPLACE VIEW v_spirkova_gdp_cr_2006_2018 AS 
SELECT * 
FROM t_Arina_Spirkova_project_SQL_secondary_final
WHERE country = 'Czech Republic'
AND year BETWEEN 2006 AND 2018;

-- Шаг 2: Представление для тренда ВВП (междугодовые изменения)

CREATE OR REPLACE VIEW v_spirkova_arina_gdp_trend_diff_cr_2006_2018 AS 
SELECT 
    gdp1.year AS older_year, 
    gdp1.GDP AS older_gdp, 
    gdp2.year AS newer_year, 
    gdp2.GDP AS newer_gdp,
    ROUND((gdp2.GDP - gdp1.GDP) / gdp1.GDP * 100, 2) AS gdp_diff_percentage
FROM 
    v_spirkova_gdp_cr_2006_2018 AS gdp1
JOIN 
    v_spirkova_gdp_cr_2006_2018 AS gdp2
ON 
    gdp2.year = gdp1.year + 1;
   
-- Шаг 3: Представление для тренда средней заработной платы (междугодовые изменения)

CREATE OR REPLACE VIEW v_spirkova_avg_wages_trend_diff_cr_2006_2018 AS 
SELECT 
    wage1.payroll_year AS older_year, 
    wage2.payroll_year AS newer_year, 
    ROUND((wage2.avg_wages - wage1.avg_wages) / wage1.avg_wages * 100, 2) AS avg_wages_diff_percentage
FROM 
    t_Arina_Spirkova_project_SQL_primary_final AS wage1
JOIN 
    t_Arina_Spirkova_project_SQL_primary_final AS wage2
ON 
    wage2.payroll_year = wage1.payroll_year + 1
WHERE 
    wage1.payroll_year BETWEEN 2006 AND 2018
GROUP BY 
    wage1.payroll_year;
   
-- Шаг 4: Представление для тренда средней цены на продукты питания (междугодовые изменения)

CREATE OR REPLACE VIEW v_spirkova_avg_food_price_trend_diff_cr_2006_2018 AS 
SELECT 
    price1.year AS older_year, 
    price2.year AS newer_year, 
    ROUND((price2.avg_price - price1.avg_price) / price1.avg_price * 100, 2) AS avg_price_diff_percentage
FROM 
    (SELECT YEAR(date_from) AS year, AVG(price) AS avg_price 
     FROM t_Arina_Spirkova_project_SQL_primary_final 
     WHERE YEAR(date_from) BETWEEN 2006 AND 2018 
     GROUP BY YEAR(date_from)) AS price1
JOIN 
    (SELECT YEAR(date_from) AS year, AVG(price) AS avg_price 
     FROM t_Arina_Spirkova_project_SQL_primary_final 
     WHERE YEAR(date_from) BETWEEN 2006 AND 2018 
     GROUP BY YEAR(date_from)) AS price2
ON 
    price2.year = price1.year + 1;

-- Шаг 5: Объединение данных ВВП, заработных плат и цен на продукты питания
   
CREATE OR REPLACE VIEW v_spirkova_arina_foodprice_wages_gdp_trend AS 
SELECT 
    gdp.older_year, 
    gdp.newer_year, 
    fpt.avg_price_diff_percentage, 
    wag.avg_wages_diff_percentage, 
    gdp.gdp_diff_percentage
FROM 
    v_spirkova_arina_gdp_trend_diff_cr_2006_2018 AS gdp
JOIN 
    v_spirkova_avg_wages_trend_diff_cr_2006_2018 AS wag
ON 
    wag.older_year = gdp.older_year
JOIN 
    v_spirkova_avg_food_price_trend_diff_cr_2006_2018 AS fpt 
ON 
    fpt.older_year = gdp.older_year;

-- Шаг 6: Анализ средних значений междугодовых изменений за весь период
   
-- Средние междугодовые изменения за весь период
SELECT 
    ROUND(AVG(avg_price_diff_percentage), 2) AS avg_foodprice_growth_trend_percentage, 
    ROUND(AVG(avg_wages_diff_percentage), 2) AS avg_wages_growth_trend_percentage, 
    ROUND(AVG(gdp_diff_percentage), 2) AS avg_gdp_growth_trend_percentage
FROM 
    v_spirkova_arina_foodprice_wages_gdp_trend;

SELECT 
	ROUND(AVG(avg_price_diff_percentage), 2) AS avg_foodprice_growth_trend_percentage, 
    ROUND(AVG(avg_wages_diff_percentage), 2) AS avg_wages_growth_trend_percentag, 
    ROUND(AVG(gdp_diff_percentage), 2) AS avg_gdp_growth_trend_percentage,
    (SELECT MIN(older_year) FROM v_spirkova_arina_foodprice_wages_gdp_trend) AS year_from,
    (SELECT MAX(newer_year) FROM v_spirkova_arina_foodprice_wages_gdp_trend) AS year_to
FROM 
    v_spirkova_arina_foodprice_wages_gdp_trend;


-- Шаг 7: Анализ суммарных изменений за весь период
   
-- Суммарные изменения за весь период
SELECT 
    MIN(older_year) AS year_from,
    MAX(newer_year) AS year_to,
    ROUND(SUM(avg_price_diff_percentage), 2) AS total_foodprice_growth_trend_percentage, 
    ROUND(SUM(avg_wages_diff_percentage), 2) AS total_wages_growth_trend_percentage, 
    ROUND(SUM(gdp_diff_percentage), 2) AS total_gdp_growth_trend_percentage
FROM 
    v_spirkova_arina_foodprice_wages_gdp_trend; 
