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

/* Popis:
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

/* Tento dotaz filtruje data z pohledu v_arina_spirkova_wages_growth_trend_by_sector_and_year a zobrazuje pouze ty roky a odvětví, kde došlo k poklesu mezd.Data jsou seřazena podle procentuálního poklesu, přičemž na prvních místech jsou 
 * zobrazeny největší poklesy.
 */

-- Výsledkem posledního dotazu je zjištění, že největší meziroční pokles mezd byl zaznamenán v odvětví Peněžnictví a pojišťovnictví, kde průměrná mzda klesla o -8,91 % z 50 254 Kč na 45 775 Kč.
