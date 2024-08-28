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

- Restricted-use mortality data.
	-	Access requires research-proposal review and approval by the National Center for Health Statistics (NCHS).
	-	Information on how to apply can be found [here](/https://www.cdc.gov/nchs/nvss/nvss-restricted-data.htm)

-	COVID-19 US State Policy Database
	- Dataset available [here](/https://github.com/USCOVIDpolicy/COVID-19-US-State-Policy-Database/tree/master)

- American Community Survey 5-year ending in 2020 and 2021
	- Demographic and socioeconomic data from the Census for all counties available
	[here](/https://www.socialexplorer.com/reports/socialexplorer/en/report/1e76e30e-e9f5-11ed-aa83-27bbc2272633)

- COVID-19 cases and deaths
	- Data at the county level obtained from the 019 Novel Coronavirus Visual
	Dashboard operated by the Johns Hopkins University Center for Systems Science
	and Engineering (JHU CSSE) can be accessed [here](/https://github.com/CSSEGISandData/COVID-19)

- Unemployment data
	- Monthly unemployment data is obtained from the Bureau of Labor Statistics
	that can be accessed [here](/https://www.bls.gov/lau/)

- County Economic Impact Index
	- Argonne National Laboratory developed the CEII to track near the COVID-19
	impact at the county-level and can be accessed [here](/https://anl.app.box.com/s/q0e8ub9jzjyemg0x1y2clt01hkqxpg76)]

- Oxford Covid-19 Government Response Tracker
	- The Oxford Covid-19 Government Response Tracker (OxCGRT) collected information on which pandemic response measures were enacted by governments, and when [here](/https://github.com/OxCGRT/covid-policy-dataset)

- [County Opioid Dispensing Rate](/https://www.cdc.gov/overdose-prevention/data-research/facts-stats/opioid-dispensing-rate-maps.html)

- Election returns dataset
- Fentanyl dataset
- Vaccination and community transmissions data
- Substance use disorders, mental health, treatment need
- USDA Rural-Urban Continuum Codes 

## Computational Requirements
- Stata (code was last run with version 18)
- R 3.4.2
	- haven 2.5.4
	- tidyverse 2.0.0
	- lmtp 1.3.2, for different covariate sets for treatment and outcome, the
	- SuperLearner 2.0.28.1
	- progressr 0.14.0
	- future 1.33.0
	- foreach 1.5.2
	- doParallel 1.0.17

- Python 3.9.18
	- csv
  - glob 0.7
	- ijason 3.2.3
	- io
	- json 0.9.6
	- matplotlib  3.8.0
  - numpy 1.26.3
	- os
	- pandas  1.3.4
	- plotly 5.6.0
	- prettytable 3.5.0
	- requests 2.31.0
	- seaborn 0.12.2
	- sodapy 2.2.0
	- time

# Description of the code
- Scripts beginning with 00 retrieve and creates intermediate files
- Script beginning with 01 creates analytic file
- Script beginning with 02 creates descriptive graph
- Scripts beginning with 03 run analyses
- Script beginning with 04 compiles results

## The order to run the files in the code folder is:

### 0. Data preparation
Download the data files referenced above in the subfolders indicated.

a) CUSP database
- [Clean CUSP data](code/00a_Clean_CUSP_policydata.ipynb)
This script retrieves CUSP policy data from https://github.com/USCOVIDpolicy/COVID-19-US-State-Policy-Database and creates the file cusp.csv

- [Reformat dates on CUSP dataset to merge with other files](code/00abis_cuspfmtdates.do)
This code reformats date variable, so it can be merged with other datasets. Creates the file: cusp_datesfmt.dta

b) [Append mortality data by county and month from 2017-2021](code/00b_countymortalitydata.R)
This code appends mortality data previously extracted at the monthly level.
This dataset is restricted due to DUA with NHCS. Instructions on how to access
these data is outlined above.

c) [Clean ACS County level data](code/00c_ACSCounydata.ipynb)
Census data obtained from socialexplorer.com and stored in data/1_raw/census_acs/
Make sure to download these county-level variables for ACS 5-year datasets ending
in years 2020 and 2021
	- A00002:Population Density (Per Sq. Mile)
	- B01001:Age (Short Version)
	- A02001:Sex
	- B04001:Hispanic or Latino by Race (Collapsed Version)
	- A10002B:Household Size (Renter-Occupied Housing Units)
	- B12001:Educational Attainment for Population 25 Years and Over (Collapsed Version)
	- A17005:Unemployment Rate for Civilian Population in Labor Force 16 Years and Over
	- A14006:Median Household Income (In 2021 Inflation Adjusted Dollars)
	- A10017:Households with Social Security Income
	- A10014:Households with Public Assistance Income
	- A14028:Gini Index of Income Inequality
	- A10047:Vacancy Status by Type of Vacancy
	- A10062B:Total Population in Renter Occupied Housing Units by Units in Structure
	- A10046B:Occupants Per Room (Renter-Occupied Housing Units)
	- B18002:Residents Paying More Than 30% or at least 50% of Income on Rent
	- A13003B:Poverty Status for Population Age 18 to 64
	- D13004:Ratio of Income to Poverty Level of Families in the Past 12 Months (Summarized - top-coded at 5.00)
	- A20001:Health Insurance

d) [Clean COVID-19 cases and deaths data by county & month](code/00d_covid19casesdeaths.do)
This code creates new COVID-19 cases and deaths by county and month using data from
the COVID-19 Data Repository by the Center for Systems Science and Engineering
(CSSE) at Johns Hopkins University https://github.com/CSSEGISandData/COVID-19

e) Monthly unemployment data and County Economic Impact Index
- [Retrieve county-level unemployment data from BLS](code/00e_retrieveunemploymentdata_bls.ipynb)
- [Clean unemployment and index data](code/00ebis_clean_lausunemp_economiccovidindex.do)

f) Oxford Covid-19 Government Response Tracker (OxCGRT) indices
 - [Retrieve indices data](code/00f_Retrieve_OxCGRT_index.ipynb)
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
