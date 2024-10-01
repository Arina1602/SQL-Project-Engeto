/* Primary table number 1
 * Tabulka pro data mezd a cen potravin za Českou republiku sjednocených na totožné porovnatelné období – společné roky
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