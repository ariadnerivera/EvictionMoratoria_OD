## Repository for Eviction Moratoria and Overdoses project


### The order to run the files is:

#### 1. Clean data from various data sources
a) [Clean CUSP data](code/00a_Clean_CUSP_policydata.ipynb)
b) [Append mortality data by county and month](code/00b_countymortalitydata.R)
c) [Clean ACS County level data](code/00c_ACSCounydata.ipynb)
e) [Reformat dates on CUSP dataset to merge with other files](code/00d_cuspfmtdates.do)
f) [Add covid cases and death data by county & month](code/00e_covid19casesdeaths.do)

#### 2. Create analytic files
a) [Create analytic files](code/01a_mergedatafiles.do)
