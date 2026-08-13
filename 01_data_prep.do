/*============================================================================
   MASTER SCRIPT: Asymmetric Geopolitical Risk and Macroeconomic Resilience
   Energy Economics Replication Package
   Author: Benbouziane Mohamed
   Date: August 2026
   ============================================================================*/

clear all
set more off
set matsize 11000

/*----------------------------------------------------------------------------
   0. SET WORKING DIRECTORY  (EDIT THIS PATH)
   ----------------------------------------------------------------------------*/
global root "C:/your/path/to/replication_package"

global data    "${root}/data"
global code    "${root}/code"
global output  "${root}/output"
global tables  "${output}/tables"
global figures "${output}/figures"

* Create output folders if they don't exist
capture mkdir "${output}"
capture mkdir "${tables}"
capture mkdir "${figures}"

/*----------------------------------------------------------------------------
   1. INSTALL REQUIRED PACKAGES (RUN ONCE)
   ----------------------------------------------------------------------------*/
* Uncomment the lines below on first run:
* ssc install estout, replace
* ssc install outreg2, replace

/*----------------------------------------------------------------------------
   2. RUN ANALYSIS SCRIPTS IN SEQUENCE
   ----------------------------------------------------------------------------*/

do "${code}/01_data_prep.do"
do "${code}/02_descriptive_stats.do"
do "${code}/03_mg_ardl_baseline.do"
do "${code}/04_nardl_asymmetry.do"
do "${code}/05_robustness.do"
do "${code}/06_gdp_inflation_channels.do"

di "All scripts completed successfully. Outputs saved to ${output}."
