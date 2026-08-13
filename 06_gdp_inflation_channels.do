/*============================================================================
   SCRIPT 05: ROBUSTNESS CHECKS (Section 6.5)
   1. Driscoll-Kraay standard errors (cross-sectional dependence)
   2. De facto peg interaction
   3. Pre-2020 sample (exclude 2020-2024)
   4. Country-specific GPR (where available)
   ============================================================================*/

clear all
set more off

use "${data}/clean_data_ardl.dta", clear

*------------------------------------------------------------------------------
* 1. DRISCOLL-KRAAY STANDARD ERRORS (Pooled FE with time clusters)
*------------------------------------------------------------------------------
* Note: Driscoll-Kraay is for pooled estimators; MG-ARDL uses cross-section SE.
* Here we show a pooled FE with DK SE as a robustness check on the interaction.

* Install xtscc if not already installed
capture which xtscc
if _rc {
    ssc install xtscc, replace
}

xtscc reserves_pct_gdp c.gpr_global##i.oil_exporter ctot_imf trade_openness control_corruption_est, ///
    fe lag(2)
estimates store robust_dk

outreg2 using "${tables}/Table_Robustness.rtf", replace ctitle("Driscoll-Kraay") ///
    addstat(Countries, e(N_clust)) dec(3) label

*------------------------------------------------------------------------------
* 2. DE FACTO PEG INTERACTION
*------------------------------------------------------------------------------
xtreg reserves_pct_gdp c.gpr_global##i.oil_exporter c.gpr_global##i.de_facto_peg ///
    ctot_imf trade_openness control_corruption_est i.year, ///
    fe cluster(country_id)
estimates store robust_peg

outreg2 using "${tables}/Table_Robustness.rtf", append ctitle("Peg Interaction") ///
    addstat(Countries, e(N_clust)) dec(3) label

*------------------------------------------------------------------------------
* 3. PRE-2020 SAMPLE (Truncate at 2019)
*------------------------------------------------------------------------------
preserve
keep if year <= 2019
xtreg reserves_pct_gdp c.gpr_global##i.oil_exporter ctot_imf trade_openness control_corruption_est i.year, ///
    fe cluster(country_id)
estimates store robust_pre2020

outreg2 using "${tables}/Table_Robustness.rtf", append ctitle("Pre-2020") ///
    addstat(Countries, e(N_clust)) dec(3) label
restore

*------------------------------------------------------------------------------
* 4. COUNTRY-SPECIFIC GPR (where available)
*------------------------------------------------------------------------------
* Check if gpr_country is available and has sufficient coverage
capture confirm variable gpr_country
if !_rc {
    count if !missing(gpr_country)
    if r(N) > 100 {
        xtreg reserves_pct_gdp c.gpr_country##i.oil_exporter ctot_imf trade_openness control_corruption_est i.year, ///
            fe cluster(country_id)
        estimates store robust_country_gpr

        outreg2 using "${tables}/Table_Robustness.rtf", append ctitle("Country GPR") ///
            addstat(Countries, e(N_clust)) dec(3) label
    }
    else {
        di "Note: Country-specific GPR has insufficient coverage. Skipping robustness check 4."
    }
}
else {
    di "Note: Country-specific GPR variable (gpr_country) not found. Skipping robustness check 4."
}

*------------------------------------------------------------------------------
* 5. ALTERNATIVE: SYSTEM GMM (Blundell & Bond 1998)
*------------------------------------------------------------------------------
* Uncomment if xtabond2 is installed:
* ssc install xtabond2
* xtabond2 reserves_pct_gdp L.reserves_pct_gdp gpr_global ctot_imf trade_openness ///
*       control_corruption_est, gmm(L.reserves_pct_gdp) iv(gpr_global ctot_imf) ///
*       robust twostep nodiffsargan

di "Robustness checks complete. Results saved to ${tables}/Table_Robustness.rtf"
