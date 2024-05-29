/* Tabulka cislo 1
 * pro data mezd a cen potravin za Českou republiku 
 * sjednocených na totožné porovnatelné období – společné roky
 */

CREATE TABLE t_Arina_Spirkova_project_SQL_primary_final AS
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

CREATE TABLE t_Arina_Spirkova_project_SQL_secondary_final AS
SELECT 
	e.country,
	e.population,
	e.gini,
	e.GDP
FROM economies e 
JOIN countries c ON e.country = c.country
WHERE c.continent = 'Europe'
	AND e.GDP IS NOT NULL;


/* Otazka cislo 1
Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
*/

-- 1. Vytvorime pohled prumerne mzdy podle roku a sektoru prace
CREATE OR REPLACE VIEW 
	v_arina_spikova_avg_wages_by_year_and_Sector AS
SELECT
	industry_branch,
	payroll_year,
	ROUND(AVG(avg_wages)) AS avg_wages_CZK
FROM t_Arina_Spirkova_project_SQL_primary_final taspspf 
GROUP BY industry_branch, payroll_year;

SELECT * 
FROM v_arina_spikova_avg_wages_by_year_and_Sector;

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

SELECT *
FROM v_arina_spirkova_wages_growth_trend_by_sector_and_year;

-- Mzdy ve vsech sledovanych odveti rostou, rust vsak nebyl rovnomerny a byl zaznamenan i pokles.

-- Dotaz, který ukáže odvětví a roky s klesajícími mzdami:
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

Nejvetsi mezirocni pokles byl zaznamenan u odvetvi Peněžnictví a pojišťovnictví, kde prumerna mzda se snizila o -8,91% a TO z 50254 Kč do 45775 Kč 


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








