# Eviction Moratoria and Drug Overdoses

This repository contains the code to clean and conduct analysis in the study:

Rivera Aguirre A, Díaz I, Routhier G, McKay C, Matthay E, Friedman S, Doran K,
Cerdá M. The effect of lifting eviction moratoria on fatal drug overdoses in the
context of the COVID-19 pandemic in the US. Under Review. 2024.


Running the code requires, as noted in the code, requires folder structure as
follows:

*	EvictionMoratoria_OD/
*	|-	code      # Where the scripts are stored
*	|-	data      # Data files organized as follows
*	|	|-	1_raw			# All files as obtained from the source
*		|-	2_intermediate 	# All intermediate dataset
*		|-	3_analytic		# Analytic datasets created
*	|-	Results   # Where results are stored


### The order to run the files in the code folder is:
#### 1. Clean data from various data sources
a) CUSP database
- [Clean CUSP data](code/00a_Clean_CUSP_policydata.ipynb)
This script retrieves CUSP policy data from https://github.com/USCOVIDpolicy/COVID-19-US-State-Policy-Database and creates the file cusp.csv

- [Reformat dates on CUSP dataset to merge with other files](code/00abis_cuspfmtdates.do)
This code reformats date variable, so it can be merged with other datasets. Creates the file: cusp_datesfmt.dta

b) [Append mortality data by county and month from 2017-2021](code/00b_countymortalitydata.R)
This code appends mortality data previously extracted

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
 - [Retrieve indeces data](code/00f_ Retrieve_OxCGRT_index.ipynb)
 - [Clean oxford index](code/00fbis_cleanoxforrdindex.do)

g) [Opioid Dispensing Rate](code/00g_CDC_rxrate.do)

h) [Elections Data](code/00h_electionreturns.do)

i) [Fentanyl Ratio](code/00i_NFLIS2020_2021.do)

j) [Vaccinations and community transmission data]
- [Retrieve data](code/00j_covidhospitalizations_vaccinations_communitytransmission.ipynb)
- [Create monthly data](code/00jbis_vaccination_comtransmission.do)

k) [Substance Use Disorders, Mental Health, Treatment Need](code/00k_NSDUH_publish.do)

l) [Rural/urban classification](code/00l_USDA_rucc2023.do)

#### 2. Create analytic files
a) [Create analytic files](code/01a_mergedatafiles.do)

#### 3. Analytic code


01a_mergedatafiles_publish
