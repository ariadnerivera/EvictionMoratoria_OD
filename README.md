# Eviction Moratoria and Drug Overdoses

This repository contains the code to clean and conduct analysis in the study:

Rivera Aguirre A, Díaz I, Routhier G, McKay C, Matthay E, Friedman S, Doran K,
Cerdá M. The effect of lifting eviction moratoria on fatal drug overdoses in the
context of the COVID-19 pandemic in the US. Under Review. 2024.


Running the code requires, as noted in the code, requires folder structure as
follows:

	EvictionMoratoria_OD/
	|-	code      # Where the scripts are stored
	|-	data      # Data files organized as follows
	|	|-	1_raw			# All files as obtained from the source
		|-	2_intermediate 	# All intermediate dataset
		|-	3_analytic		# Analytic datasets created
	|-	results   # Where results are stored
		|-	main
		|-	main_unadjusted
		|-	mtp
		|-	mtp_unadjusted
		|-	caresact
		|-	anymoratoria
		|-	sep2020
		|-	tertiles
		|-	stayslifted



## Dataset list


## Computational Requirements
- Stata (code was last run with version 18)
- R 3.4.2
- Python
  - pandas
  - glob
  - numpy


# Description of the code
- Code beginning with 00 will retrieve and do initial cleaning for needed for merging
- Code beginning with 01 will creates analytic file
- Code beginning with 03 runs analyses
- Code beginning with 04 compiles results


## The order to run the files in the code folder is:

### 0. Data preparation
Download the data files referenced above in the subfolders indicated.

a) CUSP database
- [Clean CUSP data](code/00a_Clean_CUSP_policydata.ipynb)
This script retrieves CUSP policy data from https://github.com/USCOVIDpolicy/COVID-19-US-State-Policy-Database and creates the file cusp.csv

- [Reformat dates on CUSP dataset to merge with other files](code/00abis_cuspfmtdates.do)
This code reformats date variable, so it can be merged with other datasets. Creates the file: cusp_datesfmt.dta

b) [Append mortality data by county and month from 2017-2021](code/00b_countymortalitydata.R)
This code appends mortality data previously extracted. This dataset is restricted due to DUA.
Instructions on how to access these data is outlined above.

c) [Clean ACS County level data](code/00c_ACSCounydata.ipynb)
Census data obtained from socialexplorer.com and stored in data/1_raw/census_acs/

d) [Clean COVID-19 cases and deaths data by county & month](code/00d_covid19casesdeaths.do)
This code creates new COVID-19 cases and deaths by county and month using data from
the COVID-19 Data Repository by the Center for Systems Science and Engineering
(CSSE) at Johns Hopkins University https://github.com/CSSEGISandData/COVID-19

e) Monthly unemployment data and County Economic Impact Index
- [Retrieve county-level unemployment data from BLS](code/00e_retrieveunemploymentdata_bls.ipynb)
- [Clean unemployment and index data](code/00ebis_clean_lausunemp_economiccovidindex.do)

f) Oxford Covid-19 Government Response Tracker (OxCGRT) indeces
 - [Retrieve indeces data](code/00f_Retrieve_OxCGRT_index.ipynb)
 - [Clean oxford index](code/00fbis_cleanoxforrdindex.do)

g) [Opioid Dispensing Rate](code/00g_CDC_rxrate.do)

h) [Elections Data](code/00h_electionreturns.do)

i) [Fentanyl Ratio](code/00i_NFLIS2020_2021.do)

j) [Vaccinations and community transmission data]
- [Retrieve data](code/00j_covidhospitalizations_vaccinations_communitytransmission.ipynb)
- [Create monthly data](code/00jbis_vaccination_comtransmission.do)

k) [Substance Use Disorders, Mental Health, Treatment Need](code/00k_NSDUH.do)

l) [Rural/urban classification](code/00l_USDA_rucc2023.do)

### 1. Create analytic files
a) [Create analytic files](code/01a_mergedatafiles.do)
This code does the final cleaning and creates the analytic file

### 2. Descriptives

### 3. Analyses code
Each of these scripts runs TMLE and SDR models.

#### a) Main analysis
- [ATE adjusted](code/03a_tmle_sdr_main_20240530.R)
- [ATE unadjusted](code/03a_tmle_sdr_main_unadjusted_20240530.R)
- [MTP adjusted](code/03b_tmle_sdr_mtp_20240530.R)
- [MTP unadjusted](code/03b_tmle_sdr_mtp_unadjusted_20240530.R)

#### b) Sensitivity analysis
- [ATE adjusted + CARES Act](code/03c_tmle_sdr_cares_allmonths_20240530.R)
- [Any Moratoria](code/03d_tmle_sdr_anymoratoria_20240530.R)
- [Stratified Before/After Sep 2020](code/03e_tmle_sdr_Sep2020_20240530.R)
- Tertiles using COVID-19 Housing Policy Scorecard
  a) [Tertile 1](code/03f_ltmle_code_tertile1_20240530.R)
  b) [Tertile 2](code/03f_ltmle_code_tertile2_20240530.R)
  b) [Tertile 3](code/03f_ltmle_code_tertile3_20240530.R)
