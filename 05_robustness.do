/*============================================================================
   SCRIPT 04: NONLINEAR ARDL (NARDL) ASYMMETRY ANALYSIS (TABLE 3)
   - Decomposes GPR into positive and negative partial sums
   - Estimates MG-ARDL on decomposed variables
   - Wald test for long-run symmetry: H0: beta+ = beta-
   ============================================================================*/

clear all
set more off

use "${data}/clean_data_ardl.dta", clear

*------------------------------------------------------------------------------
* PROGRAM: NARDL MEAN GROUP ESTIMATION WITH WALD TEST
*------------------------------------------------------------------------------
capture program drop nardl_mg

program define nardl_mg, rclass
    syntax, outcome(string) sample(varname)

    preserve
    keep if `sample' == 1

    levelsof country_id, local(countries)
    local N : word count `countries'

    * Storage matrices
    tempname phi_mat b_pos b_neg b_ctot b_trade b_corr
    matrix `phi_mat' = J(`N', 1, .)
    matrix `b_pos'   = J(`N', 1, .)
    matrix `b_neg'   = J(`N', 1, .)
    matrix `b_ctot'  = J(`N', 1, .)
    matrix `b_trade' = J(`N', 1, .)
    matrix `b_corr'  = J(`N', 1, .)

    local i = 1
    foreach c of local countries {
        quietly {
            count if country_id == `c' & !missing(d_`outcome', l_`outcome')
            if r(N) < 8 {
                local ++i
                continue
            }

            * NARDL(1,1) error-correction form with decomposed GPR
            reg d_`outcome' l_`outcome' l_gpr_ps l_gpr_ns l_ctot_imf l_trade_openness l_control_corruption_est ///
                d_gpr_ps d_gpr_ns d_ctot_imf d_trade_openness d_control_corruption_est ///
                if country_id == `c'

            if e(N) > 5 & !missing(_b[l_`outcome']) & _b[l_`outcome'] != 0 {
                local phi = _b[l_`outcome']
                matrix `phi_mat'[`i',1] = `phi'

                * Long-run asymmetric coefficients: beta = -theta / phi
                matrix `b_pos'[`i',1]   = -_b[l_gpr_ps] / `phi'
                matrix `b_neg'[`i',1]   = -_b[l_gpr_ns] / `phi'
                matrix `b_ctot'[`i',1]  = -_b[l_ctot_imf] / `phi'
                matrix `b_trade'[`i',1] = -_b[l_trade_openness] / `phi'
                matrix `b_corr'[`i',1]  = -_b[l_control_corruption_est] / `phi'
            }
        }
        local ++i
    }

    * Compute Mean Group statistics for positive GPR
    quietly svmat `b_pos', names(bpos_)
    quietly sum bpos_1 if !missing(bpos_1)
    local mg_pos = r(mean)
    local se_pos = r(sd) / sqrt(r(N))
    local t_pos  = `mg_pos' / `se_pos'
    local p_pos  = 2 * ttail(r(N)-1, abs(`t_pos'))

    * Compute Mean Group statistics for negative GPR
    quietly svmat `b_neg', names(bneg_)
    quietly sum bneg_1 if !missing(bneg_1)
    local mg_neg = r(mean)
    local se_neg = r(sd) / sqrt(r(N))
    local t_neg  = `mg_neg' / `se_neg'
    local p_neg  = 2 * ttail(r(N)-1, abs(`t_neg'))

    * Speed of adjustment
    quietly svmat `phi_mat', names(phi_)
    quietly sum phi_1 if !missing(phi_1)
    local mg_phi = r(mean)
    local se_phi = r(sd) / sqrt(r(N))

    * Wald test for long-run symmetry: H0: beta_pos = beta_neg
    * Implemented as t-test on differences (beta_pos - beta_neg) = 0
    tempname diff_mat
    matrix `diff_mat' = `b_pos' - `b_neg'
    quietly svmat `diff_mat', names(diff_)
    quietly sum diff_1 if !missing(diff_1)
    local mg_diff = r(mean)
    local se_diff = r(sd) / sqrt(r(N))
    local t_diff  = `mg_diff' / `se_diff'
    local p_diff  = 2 * ttail(r(N)-1, abs(`t_diff'))
    local chi2    = `t_diff'^2   // Wald chi2(1)

    * Display Table 3 format
    di _n "============================================================="
    di "TABLE 3: NARDL Mean Group - Asymmetric GPR Effects on Reserves"
    di "============================================================="
    di "Speed of Adjustment (φ): `mg_phi' (SE: `se_phi')"
    di "Long-Run: GPR Positive:   `mg_pos' (SE: `se_pos', t=`t_pos', p=`p_pos')"
    di "Long-Run: GPR Negative:   `mg_neg' (SE: `se_neg', t=`t_neg', p=`p_neg')"
    di "Wald Test (H0: β⁺ = β⁻): χ²(1) = `chi2', p = `p_diff'"
    di "Countries: `N'"
    di "============================================================="

    * Return scalars
    return scalar mg_phi = `mg_phi'
    return scalar se_phi = `se_phi'
    return scalar mg_pos = `mg_pos'
    return scalar se_pos = `se_pos'
    return scalar t_pos  = `t_pos'
    return scalar p_pos  = `p_pos'
    return scalar mg_neg = `mg_neg'
    return scalar se_neg = `se_neg'
    return scalar t_neg  = `t_neg'
    return scalar p_neg  = `p_neg'
    return scalar wald   = `chi2'
    return scalar p_wald = `p_diff'
    return scalar N      = r(N)

    restore
end

*------------------------------------------------------------------------------
* RUN NARDL FOR RESERVES (FULL SAMPLE)
*------------------------------------------------------------------------------
nardl_mg, outcome(reserves_pct_gdp) sample(valid_reserves)

*------------------------------------------------------------------------------
* EXPORT TO FILE
*------------------------------------------------------------------------------
* Capture results for table export
capture log close
capture log using "${tables}/Table3_NARDL_results.txt", text replace
nardl_mg, outcome(reserves_pct_gdp) sample(valid_reserves)
log close

di "NARDL asymmetry analysis complete."
