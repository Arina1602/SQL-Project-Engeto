/* Secondary TABLE numer 2
 * Tabulka pro dodatečná data o dalších evropských státech
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