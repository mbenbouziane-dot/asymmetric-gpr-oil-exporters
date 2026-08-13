/*============================================================================
   SCRIPT 01: DATA PREPARATION
   - Load raw CSV data
   - Create identifiers and panel structure
   - Generate first differences, lags, and NARDL partial sums
   - Create oil_exporter dummy
   - Save cleaned dataset
   ============================================================================*/

clear all
set more off

*------------------------------------------------------------------------------
* 1. LOAD DATA
*------------------------------------------------------------------------------
import delimited "${data}/main_data.csv", clear

*------------------------------------------------------------------------------
* 2. PANEL SETUP
*------------------------------------------------------------------------------
encode country, gen(country_id)
xtset country_id year

*------------------------------------------------------------------------------
* 3. CREATE OIL EXPORTER DUMMY (if not already in CSV)
*------------------------------------------------------------------------------
* The CSV already contains oil_exporter; verify it
tab oil_exporter

*------------------------------------------------------------------------------
* 4. GENERATE FIRST DIFFERENCES AND LAGS (for ARDL error-correction form)
*------------------------------------------------------------------------------
sort country_id year
by country_id: gen d_reserves    = D.reserves_pct_gdp
by country_id: gen d_gdp_growth   = D.gdp_growth
by country_id: gen d_inflation    = D.inflation_cpi
by country_id: gen d_gpr          = D.gpr_global
by country_id: gen d_ctot         = D.ctot_imf
by country_id: gen d_trade        = D.trade_openness
by country_id: gen d_corruption   = D.control_corruption_est

* Lags of levels (for error-correction term)
by country_id: gen l_reserves    = L.reserves_pct_gdp
by country_id: gen l_gdp_growth  = L.gdp_growth
by country_id: gen l_inflation   = L.inflation_cpi
by country_id: gen l_gpr         = L.gpr_global
by country_id: gen l_ctot        = L.ctot_imf
by country_id: gen l_trade       = L.trade_openness
by country_id: gen l_corruption  = L.control_corruption_est

*------------------------------------------------------------------------------
* 5. NARDL PARTIAL SUM DECOMPOSITION (Shin, Yu & Greenwood-Nimmo 2014)
*------------------------------------------------------------------------------
* Positive and negative partial sums of GPR changes
by country_id: gen d_gpr_pos = d_gpr if d_gpr > 0
by country_id: gen d_gpr_neg = d_gpr if d_gpr < 0
replace d_gpr_pos = 0 if missing(d_gpr_pos)
replace d_gpr_neg = 0 if missing(d_gpr_neg)

* Cumulative partial sums (levels for long-run NARDL)
by country_id: gen gpr_ps = sum(d_gpr_pos)   // positive partial sum
by country_id: gen gpr_ns = sum(d_gpr_neg)   // negative partial sum

* Lags of NARDL partial sums
by country_id: gen l_gpr_ps = L.gpr_ps
by country_id: gen l_gpr_ns = L.gpr_ns

*------------------------------------------------------------------------------
* 6. SAMPLE BALANCING FLAGS
*------------------------------------------------------------------------------
* Flag countries with sufficient observations for MG-ARDL (need >= 10 obs after diff/lag)
by country_id: egen count_obs_reserves = count(d_reserves)
by country_id: egen count_obs_growth    = count(d_gdp_growth)
by country_id: egen count_obs_inflation = count(d_inflation)

gen valid_reserves  = (count_obs_reserves >= 10)
gen valid_growth    = (count_obs_growth >= 10)
gen valid_inflation = (count_obs_inflation >= 10)

*------------------------------------------------------------------------------
* 7. LABEL VARIABLES
*------------------------------------------------------------------------------
label var d_reserves      "Δ Foreign Reserves (% GDP)"
label var d_gdp_growth    "Δ Real GDP Growth"
label var d_inflation     "Δ CPI Inflation"
label var d_gpr           "Δ Global GPR"
label var d_ctot          "Δ Commodity Terms of Trade"
label var d_trade         "Δ Trade Openness"
label var d_corruption    "Δ Control of Corruption"
label var l_reserves      "Lagged Reserves (% GDP)"
label var l_gpr           "Lagged Global GPR"
label var gpr_ps          "GPR Positive Partial Sum"
label var gpr_ns          "GPR Negative Partial Sum"
label var oil_exporter    "Oil Exporter Dummy"
label var de_facto_peg    "De Facto Peg Dummy"

*------------------------------------------------------------------------------
* 8. SAVE CLEANED DATASET
*------------------------------------------------------------------------------
save "${data}/clean_data_ardl.dta", replace

di "Data preparation complete. Cleaned dataset saved."
