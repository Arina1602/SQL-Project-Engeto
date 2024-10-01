/* Otazka cislo 5
 * Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
 */

-- 1. VIEW HDP v ČR v letech 2006 - 2018
CREATE OR REPLACE VIEW v_arina_spirkova_project_gdp_cr_2006_2018 AS 
SELECT * 
FROM t_Arina_Spirkova_project_SQL_secondary_final
WHERE country = 'Czech Republic';

SELECT * 
FROM v_arina_spirkova_project_gdp_cr_2006_2018;

-- 2. VIEW HDP trend - meziroční vývoj
CREATE OR REPLACE VIEW v_arina_spirkova_project_yoy_gdp_trend_diff_cr_2006_2018 AS 
SELECT 
    gdp1.year AS older_year, 
    gdp1.GDP AS older_gdp, 
    gdp2.year AS newer_year, 
    gdp2.GDP AS newer_gdp,
    ROUND((gdp2.GDP - gdp1.GDP) / gdp1.GDP * 100, 2) AS gdp_diff_percentage
FROM v_arina_spirkova_project_gdp_cr_2006_2018 AS gdp1
JOIN v_arina_spirkova_project_gdp_cr_2006_2018 AS gdp2
    ON gdp2.country = gdp1.country
    AND gdp2.year = gdp1.year + 1
GROUP BY gdp1.year;

SELECT * 
FROM v_arina_spirkova_project_yoy_gdp_trend_diff_cr_2006_2018;


-- 3. VIEW Meziroční vývoj Cen potravin, Mezd a HDP v ČR 2006-2018
CREATE OR REPLACE VIEW v_arina_spirkova_project_yoy_foodprice_wages_gdp_trend AS 
SELECT 
    gdp.older_year, 
    gdp.newer_year, 
    fpt.avg_price_diff_percentage, 
    wag.avg_wages_diff_percentage, 
    gdp.gdp_diff_percentage
FROM v_arina_spirkova_project_yoy_gdp_trend_diff_cr_2006_2018 AS gdp
JOIN v_arina_spirkova_project_avg_wages_trend_diff_cr_2006_2018 AS wag
    ON wag.older_year = gdp.older_year
JOIN v_arina_spirkova_project_avg_food_price_trend_diff_cr_2006_2018 AS fpt 
    ON fpt.older_year = gdp.older_year;

SELECT * 
FROM v_arina_spirkova_project_yoy_foodprice_wages_gdp_trend;

-- 4. Průměr meziročního růstu cen, mezd a HDP za celé období
SELECT 
    older_year AS year_from,
    MAX(newer_year) AS year_to,
    ROUND(AVG(avg_price_diff_percentage), 2) AS avg_foodprice_growth_trend_percentage, 
    ROUND(AVG(avg_wages_diff_percentage), 2) AS avg_wages_growth_trend_percentage, 
    ROUND(AVG(gdp_diff_percentage), 2) AS avg_gdp_growth_trend_percentage
FROM v_arina_spirkova_project_yoy_foodprice_wages_gdp_trend;

-- 5. Nárůst za celé období
SELECT 
    older_year AS year_from,
    MAX(newer_year) AS year_to,
    ROUND(SUM(avg_price_diff_percentage), 2) AS avg_foodprice_growth_trend_percentage, 
    ROUND(SUM(avg_wages_diff_percentage), 2) AS avg_wages_growth_trend_percentage, 
    ROUND(SUM(gdp_diff_percentage), 2) AS avg_gdp_growth_trend_percentage
FROM v_arina_spirkova_project_yoy_foodprice_wages_gdp_trend;

-- 
Na základě analýzy průměrného růstu cen potravin, mezd a HDP v letech 2006–2018 nelze s jistotou potvrdit ani odmitnout daný předpoklad. Nejsem odborník na ekonomii,
ale výše HDP nezdá se mí, že ma přímý vliv na změny cen potravin nebo mezd. Průměrné ceny potravin a mzdy mohou růst nebo klesat nezávisle na vývoji HDP.