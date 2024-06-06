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
	|	|-	1_raw	# All files as obtained from the source
		|-	2_intermediate 	# All intermediate dataset
		|-	3_analytic		# Analytic datasets created
  |-	results      # Where the results are stored




### The order to run the files is:

#### 1. Clean data from various data sources
a) [Clean CUSP data](code/00a_Clean_CUSP_policydata.ipynb)

b) [Append mortality data by county and month](code/00b_countymortalitydata.R)

c) [Clean ACS County level data](code/00c_ACSCounydata.ipynb)

d) [Reformat dates on CUSP dataset to merge with other files](code/00d_cuspfmtdates.do)

e) [Add covid cases and death data by county & month](code/00e_covid19casesdeaths.do)

#### 2. Create analytic files
a) [Create analytic files](code/01a_mergedatafiles.do)
