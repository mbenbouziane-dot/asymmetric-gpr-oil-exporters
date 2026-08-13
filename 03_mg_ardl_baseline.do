/*============================================================================
   SCRIPT 02: DESCRIPTIVE STATISTICS (TABLE 1)
   - Summary statistics by oil-exporter status
   - Mean differences with standard deviations
   ============================================================================*/

clear all
set more off

use "${data}/clean_data_ardl.dta", clear

*------------------------------------------------------------------------------
* TABLE 1: DESCRIPTIVE STATISTICS BY OIL-EXPORTER STATUS
*------------------------------------------------------------------------------
* Using estout for publication-quality tables

estpost summarize gpr_global gdp_growth inflation_cpi reserves_pct_gdp ///
    trade_openness ctot_imf control_corruption_est rule_of_law_est de_facto_peg, detail

* By group: Oil exporters
preserve
keep if oil_exporter == 1
estpost summarize gpr_global gdp_growth inflation_cpi reserves_pct_gdp ///
    trade_openness ctot_imf control_corruption_est rule_of_law_est de_facto_peg, detail
estimates store oil_stats
restore

* By group: Non-oil exporters
preserve
keep if oil_exporter == 0
estpost summarize gpr_global gdp_growth inflation_cpi reserves_pct_gdp ///
    trade_openness ctot_imf control_corruption_est rule_of_law_est de_facto_peg, detail
estimates store nonoil_stats
restore

* Export combined table
esttab oil_stats nonoil_stats using "${tables}/Table1_Descriptive_Stats.rtf", replace ///
    cells("mean(fmt(2) label(Mean)) sd(fmt(2) label(Std)) min(fmt(2) label(Min)) max(fmt(2) label(Max))") ///
    title("Table 1. Descriptive Statistics by Oil-Exporter Status") ///
    mtitles("Oil Exporters (N=23)" "Non-Oil Exporters (N=7)") ///
    nonumber nomtitle

* Alternative: asdoc for quick Word-compatible output
* asdoc sum gpr_global gdp_growth inflation_cpi reserves_pct_gdp trade_openness ///
*     ctot_imf control_corruption_est rule_of_law_est de_facto_peg, ///
*     stat(mean sd min max) by(oil_exporter) save(${tables}/Table1.doc) replace

di "Descriptive statistics complete."
