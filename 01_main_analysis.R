/*============================================================================
   SCRIPT 06: GDP GROWTH AND INFLATION CHANNELS (TABLE 2, COLUMNS 4-7)
   - MG-ARDL for GDP growth (full sample and oil exporters)
   - MG-ARDL for Inflation (full sample and oil exporters)
   ============================================================================*/

clear all
set more off

use "${data}/clean_data_ardl.dta", clear

*------------------------------------------------------------------------------
* REUSE MG-ARDL PROGRAM FROM SCRIPT 03 (ensure 03 is run first, or copy program here)
* For standalone execution, the program definition is assumed available.
* If running independently, uncomment the program block below:
*------------------------------------------------------------------------------
/*
capture program drop mg_ardl_est
program define mg_ardl_est, rclass
    syntax varlist(min=2), outcome(string) sample(varname)
    gettoken y xvars : varlist
    preserve
    keep if `sample' == 1
    levelsof country_id, local(countries)
    local N : word count `countries'
    tempname b_long b_short phi_mat
    local k : word count `xvars'
    matrix `b_long' = J(`N', `k', .)
    matrix `b_short' = J(`N', `k', .)
    matrix `phi_mat' = J(`N', 1, .)
    local i = 1
    foreach c of local countries {
        quietly {
            count if country_id == `c' & !missing(d_`outcome', l_`outcome')
            if r(N) < 8 {
                local ++i
                continue
            }
            reg d_`outcome' l_`outcome' l_`xvars' d_`xvars' if country_id == `c'
            if e(N) > 5 & !missing(_b[l_`outcome']) & _b[l_`outcome'] != 0 {
                matrix `phi_mat'[`i',1] = _b[l_`outcome']
                local j = 1
                foreach x of local xvars {
                    local theta = _b[l_`x']
                    local phi   = _b[l_`outcome']
                    local beta_lr = -`theta' / `phi'
                    matrix `b_long'[`i',`j'] = `beta_lr'
                    matrix `b_short'[`i',`j'] = _b[d_`x']
                    local ++j
                }
            }
        }
        local ++i
    }
    local j = 1
    foreach x of local xvars {
        quietly svmat `b_long', names(long_)
        quietly sum long_`j' if !missing(long_`j')
        local mg_lr_mean = r(mean)
        local mg_lr_se   = r(sd) / sqrt(r(N))
        local mg_lr_t    = `mg_lr_mean' / `mg_lr_se'
        local mg_lr_p    = 2 * ttail(r(N)-1, abs(`mg_lr_t'))
        quietly svmat `b_short', names(short_)
        quietly sum short_`j' if !missing(short_`j')
        local mg_sr_mean = r(mean)
        local mg_sr_se   = r(sd) / sqrt(r(N))
        local mg_sr_t    = `mg_sr_mean' / `mg_sr_se'
        local mg_sr_p    = 2 * ttail(r(N)-1, abs(`mg_sr_t'))
        di "`outcome' - `x': LR=`mg_lr_mean' (p=`mg_lr_p'), SR=`mg_sr_mean' (p=`mg_sr_p')"
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
    quietly svmat `phi_mat', names(phi_)
    quietly sum phi_1 if !missing(phi_1)
    return scalar mg_phi = r(mean)
    return scalar se_phi = r(sd) / sqrt(r(N))
    return scalar N_countries = r(N)
    restore
end
*/

*------------------------------------------------------------------------------
* (4) GDP GROWTH - FULL SAMPLE
*------------------------------------------------------------------------------
mg_ardl_est gdp_growth gpr_global ctot_imf trade_openness control_corruption_est, ///
    outcome(gdp_growth) sample(valid_growth)

* (5) GDP GROWTH - OIL EXPORTERS
preserve
keep if oil_exporter == 1
mg_ardl_est gdp_growth gpr_global ctot_imf trade_openness control_corruption_est, ///
    outcome(gdp_growth) sample(valid_growth)
restore

*------------------------------------------------------------------------------
* (6) INFLATION - FULL SAMPLE
*------------------------------------------------------------------------------
mg_ardl_est inflation_cpi gpr_global ctot_imf trade_openness control_corruption_est, ///
    outcome(inflation_cpi) sample(valid_inflation)

* (7) INFLATION - OIL EXPORTERS
preserve
keep if oil_exporter == 1
mg_ardl_est inflation_cpi gpr_global ctot_imf trade_openness control_corruption_est, ///
    outcome(inflation_cpi) sample(valid_inflation)
restore

di "GDP and inflation channel estimates complete."
