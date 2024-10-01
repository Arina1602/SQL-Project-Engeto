/* Otazka cislo 4
 * Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
 */

-- VIEW Průměrná mzda v ČR od roku 2006 do roku 2018 (průměr za všechna odvětví)
CREATE OR REPLACE VIEW v_arina_spirkova_project_avg_wages_cr_2006_2018 AS 
SELECT 
	industry_branch, 
	payroll_year, 
	round(avg(avg_wages)) AS avg_wages_CR_CZK
FROM t_Arina_Spirkova_project_SQL_primary_final
GROUP BY payroll_year;

SELECT * 
FROM v_arina_spirkova_project_avg_wages_cr_2006_2018;

-- VIEW Trend růstu mezd v ČR od roku 2006 do roku 2018
CREATE OR REPLACE VIEW v_arina_spirkova_project_avg_wages_trend_diff_cr_2006_2018 AS 
SELECT
	awcr1.payroll_year AS older_year, 
	awcr1.avg_wages_CR_CZK AS older_wages,
	awcr2.payroll_year AS newer_year,
	awcr2.avg_wages_CR_CZK AS newer_wages,
	round((awcr2.avg_wages_CR_CZK - awcr1.avg_wages_CR_CZK) / awcr1.avg_wages_CR_CZK * 100, 2) AS avg_wages_diff_percentage
FROM v_arina_spirkova_project_avg_wages_cr_2006_2018 AS awcr1
JOIN v_arina_spirkova_project_avg_wages_cr_2006_2018 AS awcr2
	ON awcr2.industry_branch = awcr1.industry_branch 
		AND awcr2.payroll_year = awcr1.payroll_year + 1;

SELECT * 
FROM v_arina_spirkova_project_avg_wages_trend_diff_cr_2006_2018;

-- VIEW Průměrné ceny potravin v ČR v letech 2006 až 2018 (průměr za všechny kategorie)
CREATE OR REPLACE VIEW v_arina_spirkova_project_avg_food_price_cr_2006_2018 AS 
SELECT 
	food_category,
	YEAR(date_from) AS year,
	round(avg(price), 2) AS avg_food_price_cr_czk
FROM t_Arina_Spirkova_project_SQL_primary_final
GROUP BY YEAR(date_from);

SELECT * 
FROM v_arina_spirkova_project_avg_food_price_cr_2006_2018;

-- VIEW Trend růstu cen potravin v ČR v letech 2006 až 2018
CREATE OR REPLACE VIEW v_arina_spirkova_project_avg_food_price_trend_diff_cr_2006_2018 AS 
SELECT 
	afp1.year AS older_year, 
	afp1.avg_food_price_cr_czk AS older_price, 
	afp2.year AS newer_year, 
	afp2.avg_food_price_cr_czk AS newer_price,
	afp2.avg_food_price_cr_czk - afp1.avg_food_price_cr_czk AS avg_price_diff_czk,
	round((afp2.avg_food_price_cr_czk - afp1.avg_food_price_cr_czk) / afp1.avg_food_price_cr_czk * 100, 2) AS avg_price_diff_percentage
FROM v_arina_spirkova_project_avg_food_price_cr_2006_2018 AS afp1
JOIN v_arina_spirkova_project_avg_food_price_cr_2006_2018 AS afp2 
	ON afp2.food_category = afp1.food_category
		AND afp2.year = afp1.year + 1
GROUP BY afp1.year;

SELECT * 
FROM v_arina_spirkova_project_avg_food_price_trend_diff_cr_2006_2018;


-- VIEW Srovnání meziročního růstu průměrných cen a mezd v ČR
CREATE OR REPLACE VIEW v_arina_spir_yoy_growth_comparison AS 
SELECT 
    afptd.older_year, 
    awtd.newer_year,
    awtd.avg_wages_diff_percentage,
    afptd.avg_price_diff_percentage,
    afptd.avg_price_diff_percentage - awtd.avg_wages_diff_percentage AS price_wages_diff
FROM v_arina_spirkova_project_avg_food_price_trend_diff_cr_2006_2018 AS afptd
JOIN v_arina_spirkova_project_avg_wages_trend_diff_cr_2006_2018 AS awtd 
    ON awtd.older_year = afptd.older_year;

SELECT * 
FROM v_arina_spir_yoy_growth_comparison
ORDER BY price_wages_diff DESC;

-- V žádném z posuzovaných let nebyl meziroční nárůst cen potravin vyšší než 10 %.
