/* Otazka číslo 2
Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období v dostupných datech cen a mezd?
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

