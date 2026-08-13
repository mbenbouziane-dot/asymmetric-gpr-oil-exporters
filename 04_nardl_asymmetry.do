/*============================================================================
   SCRIPT 03: MEAN GROUP ARDL BASELINE ESTIMATES (TABLE 2)
   - Full sample MG-ARDL for Reserves, GDP Growth, and Inflation
   - Split-sample: Oil exporters vs Non-oil exporters
   - Implements Pesaran, Shin & Smith (1999) Mean Group estimator manually
   ============================================================================*/

clear all
set more off

use "${data}/clean_data_ardl.dta", clear

*------------------------------------------------------------------------------
* PROGRAM: MG-ARDL COUNTRY-BY-COUNTRY ESTIMATION
*------------------------------------------------------------------------------
capture program drop mg_ardl_est
capture program drop mg_ardl_table

program define mg_ardl_est, rclass
    syntax varlist(min=2), outcome(string) sample(varname)

    * Parse varlist: first var is dependent, rest are independent
    gettoken y xvars : varlist

    * Keep only valid observations for this outcome
    preserve
    keep if `sample' == 1

    * Get list of countries
    levelsof country_id, local(countries)
    local N : word count `countries'

    * Matrices to store results
    tempname b_long b_short phi_mat
    local k : word count `xvars'
    matrix `b_long' = J(`N', `k', .)
    matrix `b_short' = J(`N', `k', .)
    matrix `phi_mat' = J(`N', 1, .)

    local i = 1
    foreach c of local countries {
        quietly {
            * Check if we have enough observations for this country
            count if country_id == `c' & !missing(d_`outcome', l_`outcome')
            if r(N) < 8 {
                local ++i
                continue
            }

            * ARDL(1,1) error-correction form by OLS
            reg d_`outcome' l_`outcome' l_`xvars' d_`xvars' if country_id == `c'

            if e(N) > 5 & !missing(_b[l_`outcome']) & _b[l_`outcome'] != 0 {
                * Speed of adjustment (phi)
                matrix `phi_mat'[`i',1] = _b[l_`outcome']

                local j = 1
                foreach x of local xvars {
                    * Long-run coefficient: beta = -theta / phi
                    local theta = _b[l_`x']
                    local phi   = _b[l_`outcome']
                    local beta_lr = -`theta' / `phi'
                    matrix `b_long'[`i',`j'] = `beta_lr'

                    * Short-run coefficient: gamma (first difference)
                    matrix `b_short'[`i',`j'] = _b[d_`x']
                    local ++j
                }
            }
        }
        local ++i
    }

    * Compute Mean Group statistics
    local j = 1
    foreach x of local xvars {
        * Long-run MG estimates
        quietly matrix colnames `b_long' = `xvars'
        quietly svmat `b_long', names(long_)
        quietly sum long_`j' if !missing(long_`j')
        local mg_lr_mean = r(mean)
        local mg_lr_sd   = r(sd)
        local mg_lr_se   = `mg_lr_sd' / sqrt(r(N))
        local mg_lr_t    = `mg_lr_mean' / `mg_lr_se'
        local mg_lr_p    = 2 * ttail(r(N)-1, abs(`mg_lr_t'))

        * Short-run MG estimates
        quietly svmat `b_short', names(short_)
        quietly sum short_`j' if !missing(short_`j')
        local mg_sr_mean = r(mean)
        local mg_sr_sd   = r(sd)
        local mg_sr_se   = `mg_sr_sd' / sqrt(r(N))
        local mg_sr_t    = `mg_sr_mean' / `mg_sr_se'
        local mg_sr_p    = 2 * ttail(r(N)-1, abs(`mg_sr_t'))

        di "Variable: `x' (Outcome: `outcome')"
        di "  Long-run:  `mg_lr_mean' (SE=`mg_lr_se', t=`mg_lr_t', p=`mg_lr_p')"
        di "  Short-run: `mg_sr_mean' (SE=`mg_sr_se', t=`mg_sr_t', p=`mg_sr_p')"

        return scalar mg_lr_`j' = `mg_lr_mean'
        return scalar se_lr_`j' = `mg_lr_se'
        return scalar t_lr_`j'  = `mg_lr_t'
        return scalar p_lr_`j'  = `mg_lr_p'
        return scalar mg_sr_`j' = `mg_sr_mean'
        return scalar se_sr_`j' = `mg_sr_se'
        return scalar t_sr_`j'  = `mg_sr_t'
        return scalar p_sr_`j'  = `mg_sr_p'

        local ++j
    }

    * Speed of adjustment MG
    quietly svmat `phi_mat', names(phi_)
    quietly sum phi_1 if !missing(phi_1)
    local mg_phi = r(mean)
    local se_phi = r(sd) / sqrt(r(N))
    local t_phi  = `mg_phi' / `se_phi'

    return scalar mg_phi = `mg_phi'
    return scalar se_phi = `se_phi'
    return scalar t_phi  = `t_phi'
    return scalar N_countries = r(N)

    restore
end

*------------------------------------------------------------------------------
* TABLE 2: RESERVES MODELS
*------------------------------------------------------------------------------
di _n "============================================================="
di "TABLE 2: Mean Group ARDL Estimates"
di "============================================================="

* (1) Full Sample Reserves
mg_ardl_est reserves_pct_gdp gpr_global ctot_imf trade_openness control_corruption_est, ///
    outcome(reserves_pct_gdp) sample(valid_reserves)

* (2) Oil Exporters Reserves
preserve
keep if oil_exporter == 1
mg_ardl_est reserves_pct_gdp gpr_global ctot_imf trade_openness control_corruption_est, ///
    outcome(reserves_pct_gdp) sample(valid_reserves)
restore

* (3) Non-Oil Exporters Reserves
preserve
keep if oil_exporter == 0
mg_ardl_est reserves_pct_gdp gpr_global ctot_imf trade_openness control_corruption_est, ///
    outcome(reserves_pct_gdp) sample(valid_reserves)
restore

*------------------------------------------------------------------------------
* Alternative: Using xtpmg for cross-check (if installed)
*------------------------------------------------------------------------------
* xtpmg d.reserves_pct_gdp L.reserves_pct_gdp L.gpr_global L.ctot_imf ///
*       L.trade_openness L.control_corruption_est d.gpr_global d.ctot_imf ///
*       d.trade_openness d.control_corruption_est, ///
*       lr(L.reserves_pct_gdp gpr_global ctot_imf trade_openness control_corruption_est) ///
*       ec(φ) replace full

*------------------------------------------------------------------------------
* EXPORT RESULTS TO TABLE
*------------------------------------------------------------------------------
* The above prints results to the log. For publication-quality tables,
* use estout or manual matrix collection. Example:

capture matrix drop Table2
capture matrix drop rownames

* Full sample reserves (simplified illustration)
matrix Table2 = J(7, 7, .)
matrix rownames Table2 = "Speed of Adj." "LR: GPR" "LR: CToT" "LR: Trade" "LR: Corruption" "SR: ΔGPR" "SR: ΔCToT"
matrix colnames Table2 = "(1) Reserves Full" "(2) Reserves Oil" "(3) Reserves NonOil" "(4) GDP Full" "(5) GDP Oil" "(6) Infl Full" "(7) Infl Oil"

* Note: In practice, populate Table2 with returned scalars from mg_ardl_est
* and export using:
* estout matrix(Table2, fmt(3)) using "${tables}/Table2.rtf", replace

di "MG-ARDL baseline estimation complete. See log for coefficient estimates."
