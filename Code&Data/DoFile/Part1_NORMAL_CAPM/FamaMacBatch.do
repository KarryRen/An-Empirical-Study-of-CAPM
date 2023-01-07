//	===========================================================================
//	                  
//	Final Paper of financial Econometrics
// 	Code Part 1.2 : do the Fama-MacBeth (1973) to test NORMAL_CAPM
//	Author : Kai Ren
//	===========================================================================
	clear all // clear all in memory
	set more off // set more off

//	===========================================================================
//   TEST OF THE MAJOR HYPOTHESES OF THE TWO-PARAMETER MODEL TRADITIONAL CAPM
//	===========================================================================
//		H1 (LINEARITY) E[gamma2] = 0
//		H2 (NO SYSTEMATIC EFFECTS OF NON-BETA RISK) E[gamma3] = 0
//		H3 (POSITIVE EXPECTED RETURN-RISK TRADEOFF) E[gamma1] = E[Rm-R0] > 0
//		H4 (SL) E[gamma0] = rf
//	===========================================================================

//	===========================================================================
//	MATA FUNCTION
//
//	Format	:	beta_quant
//	Purpose	:	This function creates 19 quantiles corresponding to 5%, 10%, ..., 95%.
//	Input	:	var_x - variable
//	Output	:	bq, 19x1 matrix
//	===========================================================================
	mata:

	void beta_quant(string scalar var_x) {
		real colvector x,xq
	
		x = st_matrix(var_x)
		xq = mm_quantile(x,1,(0.05\0.1\0.15\0.2\0.25\0.3\0.35\0.4\0.45\0.5\0.55\0.6\0.65\0.7\0.75\0.8\0.85\0.9\0.95))
		st_matrix("bq",xq)

	}

	end	

//	===========================================================================
//	STEP 1. LOG AND DATA
//	===========================================================================
	log using "Fama-MacBeth.log", replace // open log file
	cd "C:\Users\16332\Desktop\FinEcon\FinalPaper\CAPM\Data\Part1_CAPM"
	use "cnstock.dta", clear // load dataset
	rename year yid
	rename month mid
	rename trade_date tid
	rename stock_id nid
	rename SSE_return rm
	tsset nid tid, monthly // declare panel data. panel data declaration makes operation of variable easier.
	
//	===========================================================================
//	STEP 2. GENERATE VARIABLES
//	===========================================================================	
	ge period = . // generate testing period index
	replace period = 1 if (yid >= 2009) & (yid <= 2012) // impose 1 on the period of 2009 -- 2012
	replace period = 2 if (yid >= 2013) & (yid <= 2016) // impose 2 on the period of 2013 -- 2016
	replace period = 3 if (yid >= 2017) & (yid<= 2019) // impose 3 on the period of 2017 -- 2019
	
	ge beta = . // generate beta estimate
	ge sig = . // generate standard deviation of residuals
	ge pid = . // generate portfolio id

//	***********************************
//	RETURNS
//	use ri rf and SSE_return directly 
//  no need other operation
//	***********************************
	
//	===========================================================================
//	PERIOD I: 2009 - 2012
//	===========================================================================

//	***********************************
//	portfolio formation period: 2000 - 2003 (48 months)	
//	***********************************
	ge beta0 = . // beta estimates
	ge pid0 = . // portfolio id
	
	forvalues i = 1/724 { // looping for 724 firms
		qui reg ri rm if (yid >= 2000) & (yid <= 2003) & (nid == `i') // perform regression for the period of 2000 -- 2003
		matrix bi = e(b) // coefficient matrix
		matrix b = (nullmat(b)\bi[1,1]) // beta coefficient matrix
		qui replace beta0 = bi[1,1] if (yid >= 2004) & (yid <= 2012) & (nid == `i') // update beta estimates for the period of 1989 -- 1997
	}
	mata: beta_quant("b") // generate 19 percentiles of beta such as 5%, 10%, 15%, ..., 95%
	qui replace pid0 = 20 if (beta0 < bq[1,1]) & (yid >= 2004) & (yid <= 2012) // P1: beta < beta(5%)
	qui replace pid0 = 19 if (beta0 >= bq[1,1]) & (beta0 < bq[2,1]) & (yid >= 2004) & (yid <= 2012) // P2: beta(5%) <= beta < beta(10%)
	qui replace pid0 = 18 if (beta0 >= bq[2,1]) & (beta0 < bq[3,1]) & (yid >= 2004) & (yid <= 2012) // P3: beta(10%) <= beta < beta(15%)
	qui replace pid0 = 17 if (beta0 >= bq[3,1]) & (beta0 < bq[4,1]) & (yid >= 2004) & (yid <= 2012) // P4: beta(15%) <= beta < beta(20%)
	qui replace pid0 = 16 if (beta0 >= bq[4,1]) & (beta0 < bq[5,1]) & (yid >= 2004) & (yid <= 2012) // P5: beta(20%) <= beta < beta(25%)
	qui replace pid0 = 15 if (beta0 >= bq[5,1]) & (beta0 < bq[6,1]) & (yid >= 2004) & (yid <= 2012) // P6: beta(25%) <= beta < beta(30%)
	qui replace pid0 = 14 if (beta0 >= bq[6,1]) & (beta0 < bq[7,1]) & (yid >= 2004) & (yid <= 2012) // P7: beta(30%) <= beta < beta(35%)
	qui replace pid0 = 13 if (beta0 >= bq[7,1]) & (beta0 < bq[8,1]) & (yid >= 2004) & (yid <= 2012) // P8: beta(35%) <= beta < beta(40%)
	qui replace pid0 = 12 if (beta0 >= bq[8,1]) & (beta0 < bq[9,1]) & (yid >= 2004) & (yid <= 2012) // P9: beta(40%) <= beta < beta(45%)
	qui replace pid0 = 11 if (beta0 >=  bq[9,1]) & (beta0 < bq[10,1]) & (yid >= 2004) & (yid <= 2012) // P10: beta(45%) <= beta < beta(50%)
	qui replace pid0 = 10 if (beta0 >= bq[10,1]) & (beta0 < bq[11,1]) & (yid >= 2004) & (yid <= 2012) // P11: beta(50%) <= beta < beta(55%)
	qui replace pid0 = 9 if (beta0 >= bq[11,1]) & (beta0 < bq[12,1]) & (yid >= 2004) & (yid <= 2012) // P12: beta(55%) <= beta < beta(60%)
	qui replace pid0 = 8 if (beta0 >= bq[12,1]) & (beta0 < bq[13,1]) & (yid >= 2004) & (yid <= 2012) // P13: beta(60%) <= beta < beta(65%)
	qui replace pid0 = 7 if (beta0 >= bq[13,1]) & (beta0 < bq[14,1]) & (yid >= 2004) & (yid <= 2012) // P14: beta(65%) <= beta < beta(70%)
	qui replace pid0 = 6 if (beta0 >= bq[14,1]) & (beta0 < bq[15,1]) & (yid >= 2004) & (yid <= 2012) // P15: beta(70%) <= beta < beta(75%)
	qui replace pid0 = 5 if (beta0 >= bq[15,1]) & (beta0 < bq[16,1]) & (yid >= 2004) & (yid <= 2012) // P16: beta(75%) <= beta < beta(80%)
	qui replace pid0 = 4 if (beta0 >= bq[16,1]) & (beta0 < bq[17,1]) & (yid >= 2004) & (yid <= 2012) // P17: beta(80%) <= beta < beta(85%)
	qui replace pid0 = 3 if (beta0 >= bq[17,1]) & (beta0 < bq[18,1]) & (yid >= 2004) & (yid <= 2012) // P18: beta(85%) <= beta < beta(90%)
	qui replace pid0 = 2 if (beta0 >= bq[18,1]) & (beta0 < bq[19,1]) & (yid >= 2004) & (yid <= 2012) // P19: beta(90%) <= beta < beta(95%)
	qui replace pid0 = 1 if (beta0 >= bq[19,1]) & (yid >= 2004) & (yid <= 2012) // P20: beta(95%) <= beta
	
	drop beta0 // delete variable 'beta0'
	matrix drop b bi bq // delete matrix 'b' 'bi' 'bq'
	
//	***********************************
//	initial estimation period: 2004 - 2008 (60 months)
//	testing  period: 2009 - 2012 (48 months)
//	***********************************
	forvalues i = 0/3 { // looping for four periods
		forvalues j = 1/724 { // looping for 724 firms
			qui reg ri rm if (yid >= 2004) & (yid <= 2008+`i') & (nid == `j') // perform regression for the period of 2004 -- 2009+i
			matrix bi = e(b) // coefficient matrix
			qui replace beta = bi[1,1] if (yid == 2009+`i') & (nid == `j') // update beta estimates for 2009+i
			qui predict ei, resid // create residuals
			qui sum ei // summarize residuals
			qui replace sig = r(sd) if (yid == 2009+`i') & (nid == `j') // update the standard deviation of residuals for 2009+i and firm j
			drop ei // delete residuals
		}
	}
	replace pid = pid0 if (yid >= 2009) & (yid <= 2012) // replace portfolio id for the period of 2009 -- 2012
	drop pid0 // delete variable 'pid0'

//	===========================================================================
//	PERIOD II: 2013 - 2016
//	===========================================================================

//	***********************************
//	portfolio formation period: 2001 - 2007 (84 months)	
//	***********************************
	ge beta0 = . // beta estimates
	ge pid0 = . // portfolio id
	
	forvalues i = 1/724 {
		qui reg ri rm if (yid >= 2001) & (yid <= 2007) & (nid == `i')
		matrix bi = e(b)
		matrix b = (nullmat(b)\bi[1,1])
		qui replace beta0 = bi[1,1] if (yid >= 2008) & (yid <= 2016) & (nid == `i')
	}
	mata: beta_quant("b") // generate 19 percentiles of beta such as 5%, 10%, 15%, ..., 95%
	qui replace pid0 = 20 if (beta0 < bq[1,1]) & (yid >= 2008) & (yid <= 2016) // P1: beta < beta(5%)
	qui replace pid0 = 19 if (beta0 >= bq[1,1]) & (beta0 < bq[2,1]) &(yid >= 2008) & (yid <= 2016) // P2: beta(5%) <= beta < beta(10%)
	qui replace pid0 = 18 if (beta0 >= bq[2,1]) & (beta0 < bq[3,1]) & (yid >= 2008) & (yid <= 2016) // P3: beta(10%) <= beta < beta(15%)
	qui replace pid0 = 17 if (beta0 >= bq[3,1]) & (beta0 < bq[4,1]) & (yid >= 2008) & (yid <= 2016) // P4: beta(15%) <= beta < beta(20%)
	qui replace pid0 = 16 if (beta0 >= bq[4,1]) & (beta0 < bq[5,1]) & (yid >= 2008) & (yid <= 2016) // P5: beta(20%) <= beta < beta(25%)
	qui replace pid0 = 15 if (beta0 >= bq[5,1]) & (beta0 < bq[6,1]) & (yid >= 2008) & (yid <= 2016) // P6: beta(25%) <= beta < beta(30%)
	qui replace pid0 = 14 if (beta0 >= bq[6,1]) & (beta0 < bq[7,1]) & (yid >= 2008) & (yid <= 2016) // P7: beta(30%) <= beta < beta(35%)
	qui replace pid0 = 13 if (beta0 >= bq[7,1]) & (beta0 < bq[8,1]) & (yid >= 2008) & (yid <= 2016) // P8: beta(35%) <= beta < beta(40%)
	qui replace pid0 = 12 if (beta0 >= bq[8,1]) & (beta0 < bq[9,1]) &(yid >= 2008) & (yid <= 2016) // P9: beta(40%) <= beta < beta(45%)
	qui replace pid0 = 11 if (beta0 >= bq[9,1]) & (beta0 < bq[10,1]) & (yid >= 2008) & (yid <= 2016) // P10: beta(45%) <= beta < beta(50%)
	qui replace pid0 = 10 if (beta0 >= bq[10,1]) & (beta0 < bq[11,1]) & (yid >= 2008) & (yid <= 2016) // P11: beta(50%) <= beta < beta(55%)
	qui replace pid0 = 9 if (beta0 >= bq[11,1]) & (beta0 < bq[12,1]) & (yid >= 2008) & (yid <= 2016) // P12: beta(55%) <= beta < beta(60%)
	qui replace pid0 = 8 if (beta0 >= bq[12,1]) & (beta0 < bq[13,1]) & (yid >= 2008) & (yid <= 2016) // P13: beta(60%) <= beta < beta(65%)
	qui replace pid0 = 7 if (beta0 >= bq[13,1]) & (beta0 < bq[14,1]) & (yid >= 2008) & (yid <= 2016) // P14: beta(65%) <= beta < beta(70%)
	qui replace pid0 = 6 if (beta0 >= bq[14,1]) & (beta0 < bq[15,1]) & (yid >= 2008) & (yid <= 2016) // P15: beta(70%) <= beta < beta(75%)
	qui replace pid0 = 5 if (beta0 >= bq[15,1]) & (beta0 < bq[16,1]) & (yid >= 2008) & (yid <= 2016) // P16: beta(75%) <= beta < beta(80%)
	qui replace pid0 = 4 if (beta0 >= bq[16,1]) & (beta0 < bq[17,1]) & (yid >= 2008) & (yid <= 2016) // P17: beta(80%) <= beta < beta(85%)
	qui replace pid0 = 3 if (beta0 >= bq[17,1]) & (beta0 < bq[18,1]) & (yid >= 2008) & (yid <= 2016) // P18: beta(85%) <= beta < beta(90%)
	qui replace pid0 = 2 if (beta0 >= bq[18,1]) & (beta0 < bq[19,1]) &(yid >= 2008) & (yid <= 2016) // P19: beta(90%) <= beta < beta(95%)
	qui replace pid0 = 1 if (beta0 >= bq[19,1]) & (yid >= 2008) & (yid <= 2016) // P20: beta(95%) <= beta
	
	drop beta0
	matrix drop b bi bq
	
//	***********************************
//	initial estimation period: 2008 - 2012 (60 months)
//	testing  period: 2013 - 2016 (48 months)
//	***********************************
	forvalues i = 0/3 {
		forvalues j = 1/724 {
			qui reg ri rm if (yid >= 2008) & (yid <= 2012+`i') & (nid == `j')
			matrix bi = e(b)
			qui replace beta = bi[1,1] if (yid == 2013+`i') & (nid == `j')
			qui predict ei, resid
			qui sum ei
			qui replace sig = r(sd) if (yid == 2013+`i') & (nid == `j')
			drop ei 
		}
	}
	
	replace pid = pid0 if (yid >= 2013) & (yid <= 2016)
	drop pid0

//	===========================================================================
//	PERIOD III: 2017 - 2019
//	===========================================================================

//	***********************************
//	portfolio formation period: 2005 - 2011 (48 months)	
//	***********************************
	ge beta0 = . // beta estimates
	ge pid0 = . // portfolio id
	
	forvalues i = 1/724 {
		qui reg ri rm if (yid >= 2005) & (yid <= 2011) & (nid == `i')
		matrix bi = e(b)
		matrix b = (nullmat(b)\bi[1,1])
		qui replace beta0 = bi[1,1] if (yid >= 2012) & (yid <= 2019) & (nid == `i')
	}
	mata: beta_quant("b") // generate 19 percentiles of beta such as 5%, 10%, 15%, ..., 95%
	qui replace pid0 = 20 if (beta0 < bq[1,1]) & (yid >= 2012) & (yid <= 2019) // P1: beta < beta(5%)
	qui replace pid0 = 19 if (beta0 >= bq[1,1]) & (beta0 < bq[2,1]) & (yid >= 2012) & (yid <= 2019) // P2: beta(5%) <= beta < beta(10%)
	qui replace pid0 = 18 if (beta0 >= bq[2,1]) & (beta0 < bq[3,1]) & (yid >= 2012) & (yid <= 2019) // P3: beta(10%) <= beta < beta(15%)
	qui replace pid0 = 17 if (beta0 >= bq[3,1]) & (beta0 < bq[4,1]) &(yid >= 2012) & (yid <= 2019) // P4: beta(15%) <= beta < beta(20%)
	qui replace pid0 = 16 if (beta0 >= bq[4,1]) & (beta0 < bq[5,1]) & (yid >= 2012) & (yid <= 2019) // P5: beta(20%) <= beta < beta(25%)
	qui replace pid0 = 15 if (beta0 >= bq[5,1]) & (beta0 < bq[6,1]) &(yid >= 2012) & (yid <= 2019) // P6: beta(25%) <= beta < beta(30%)
	qui replace pid0 = 14 if (beta0 >= bq[6,1]) & (beta0 < bq[7,1]) & (yid >= 2012) & (yid <= 2019) // P7: beta(30%) <= beta < beta(35%)
	qui replace pid0 = 13 if (beta0 >= bq[7,1]) & (beta0 < bq[8,1]) & (yid >= 2012) & (yid <= 2019) // P8: beta(35%) <= beta < beta(40%)
	qui replace pid0 = 12 if (beta0 >= bq[8,1]) & (beta0 < bq[9,1]) & (yid >= 2012) & (yid <= 2019) // P9: beta(40%) <= beta < beta(45%)
	qui replace pid0 = 11 if (beta0 >= bq[9,1]) & (beta0 < bq[10,1]) & (yid >= 2012) & (yid <= 2019) // P10: beta(45%) <= beta < beta(50%)
	qui replace pid0 = 10 if (beta0 >= bq[10,1]) & (beta0 < bq[11,1]) &(yid >= 2012) & (yid <= 2019) // P11: beta(50%) <= beta < beta(55%)
	qui replace pid0 = 9 if (beta0 >= bq[11,1]) & (beta0 < bq[12,1]) & (yid >= 2012) & (yid <= 2019) // P12: beta(55%) <= beta < beta(60%)
	qui replace pid0 = 8 if (beta0 >= bq[12,1]) & (beta0 < bq[13,1]) & (yid >= 2012) & (yid <= 2019) // P13: beta(60%) <= beta < beta(65%)
	qui replace pid0 = 7 if (beta0 >= bq[13,1]) & (beta0 < bq[14,1]) & (yid >= 2012) & (yid <= 2019) // P14: beta(65%) <= beta < beta(70%)
	qui replace pid0 = 6 if (beta0 >= bq[14,1]) & (beta0 < bq[15,1]) & (yid >= 2012) & (yid <= 2019) // P15: beta(70%) <= beta < beta(75%)
	qui replace pid0 = 5 if (beta0 >= bq[15,1]) & (beta0 < bq[16,1]) & (yid >= 2012) & (yid <= 2019) // P16: beta(75%) <= beta < beta(80%)
	qui replace pid0 = 4 if (beta0 >= bq[16,1]) & (beta0 < bq[17,1]) & (yid >= 2012) & (yid <= 2019) // P17: beta(80%) <= beta < beta(85%)
	qui replace pid0 = 3 if (beta0 >= bq[17,1]) & (beta0 < bq[18,1]) &(yid >= 2012) & (yid <= 2019) // P18: beta(85%) <= beta < beta(90%)
	qui replace pid0 = 2 if (beta0 >= bq[18,1]) & (beta0 < bq[19,1]) & (yid >= 2012) & (yid <= 2019) // P19: beta(90%) <= beta < beta(95%)
	qui replace pid0 = 1 if (beta0 >= bq[19,1]) &(yid >= 2012) & (yid <= 2019) // P20: beta(95%) <= beta
	
	drop beta0
	matrix drop b bi bq
	
//	***********************************
//	initial estimation period: 2012 - 2016 (60 months)
//	testing  period: 2017 - 2019 (36 months)
//	***********************************
	forvalues i = 0/2 {
		forvalues j = 1/724 {
			qui reg ri rm if (yid >= 2012) & (yid <= 2016+`i') & (nid == `j')
			matrix bi = e(b)
			qui replace beta = bi[1,1] if (yid == 2017+`i') & (nid == `j')
			qui predict ei, resid
			qui sum ei
			qui replace sig = r(sd) if (yid == 2017+`i') & (nid == `j')
			drop ei 
		}
	}
	
	replace pid = pid0 if (yid >= 2017) & (yid <= 2019)
	drop pid0
	
	keep if (yid >= 2009) & (yid <= 2019)
	
//	===========================================================================
//	STEP 3. CONSTRUCT PORTFOLIO VARIABLES
//	(a) construct portfolio return: r_p = r_1 + ... + r_n
//	(b) construct portfolio beta: beta_p = beta_1 + ... + beta_n
//	(c) construct portfolio stadard deviation: s_p = s_1 + ... + s_n
//	===========================================================================
	collapse (mean) ri rm rf beta sig, by(period pid tid) // create average variables
	tsset pid tid, monthly	// define a monthly panel dataset 
	rename ri rp // return of portfolio
	ge betasq = beta^2 // create the square of beta variables

	preserve // preserve data for the full-sample analysis. 
	// 'restore' commands will recover the original dataset. 
	// so, you can use the original data for other analysis after this analysis.
	
//	=======================================================================
//	STEP 4. FULL SAMPLE ESTIMATION: 2009 - 2019
//	=======================================================================
	by pid: ge tid2 = _n // generate tid2 which contains time-series id such as 1,2,...,T. 
	ge gamma10 = . // generate empty coeffiecient variables for the model 1 (gamma0) 
	ge gamma11 = . // generate empty coeffiecient variables for the model 1 (gamma1) 
	ge gamma20 = . // generate empty coeffiecient variables for the model 2 (gamma0) 
	ge gamma21 = . // generate empty coeffiecient variables for the model 2 (gamma1) 
	ge gamma22 = . // generate empty coeffiecient variables for the model 2 (gamma2) 
	ge gamma30 = . // generate empty coeffiecient variables for the model 3 (gamma0) 
	ge gamma31 = . // generate empty coeffiecient variables for the model 3 (gamma1) 
	ge gamma33 = . // generate empty coeffiecient variables for the model 3 (gamma2) 
	ge gamma40 = . // generate empty coeffiecient variables for the model 4 (gamma0) 
	ge gamma41 = . // generate empty coeffiecient variables for the model 4 (gamma1) 
	ge gamma42 = . // generate empty coeffiecient variables for the model 4 (gamma2) 
	ge gamma43 = .  // generate empty coeffiecient variables for the model 4 (gamma3) 
	ge rsq1 = . // generate empty r-square variables for the model 1 
	ge rsq2 = . // generate empty r-square variables for the model 2 
	ge rsq3 = . // generate empty r-square variables for the model 3 
	ge rsq4 = . // generate empty r-square variables for the model 4 
	
	forvalues i = 1/132 { // looping for 132 months
			
//		*******************************
//		MODEL 1
//		r(p,t) = r0(t) + r1(t)*beta(p,t-1) + xi(p,t)
//		*******************************
		qui reg rp beta if tid2 == `i' // perform regression for time index i.
		matrix b = e(b) // coefficient vector
		qui replace gamma10 = b[1,2] if tid2 == `i' // update gamma0 for time index i
		qui replace gamma11 = b[1,1] if tid2 == `i'	// update gamma1 for time index i 
		matrix rsq = e(r2) // R2 matrix
		qui replace rsq1 = rsq[1,1] if tid2 == `i' // update R2 for time index i
  	
//		*******************************
//		MODEL 2
//		r(p,t) = r0(t) + r1(t)*beta(p,t-1) + r2(t)*beta(p,t-1)^2 + xi(p,t)
//		!!! SEE COMMAND DESCRIPTIONS FOR MODEL 1 !!!
//		*******************************	
		qui reg rp beta betasq if tid2 == `i'
		matrix b = e(b)
		qui replace gamma20 = b[1,3] if tid2 == `i'
		qui replace gamma21 = b[1,1] if tid2 == `i'	
		qui replace gamma22 = b[1,2] if tid2 == `i'
		matrix rsq = e(r2)
		qui replace rsq2 = rsq[1,1] if tid2 == `i'
		
//		*******************************
//		MODEL 3
//		r(p,t) = r0(t) + r1(t)*beta(p,t-1) + r3(t)*sig(p,t-1) + xi(p,t)
//		!!! SEE COMMAND DESCRIPTIONS FOR MODEL 1 !!!
//		*******************************	
		qui reg rp beta sig if tid2 == `i'
		matrix b = e(b)
		qui replace gamma30 = b[1,3] if tid2 == `i'
		qui replace gamma31 = b[1,1] if tid2 == `i'	
		qui replace gamma33 = b[1,2] if tid2 == `i'
		matrix rsq = e(r2)
		qui replace rsq3 = rsq[1,1] if tid2 == `i'
		
//		*******************************
//		MODEL 4
//		r(p,t) = r0(t) + r1(t)*beta(p,t-1) + r2(t)*beta(p,t-1)^2 + r3(t)*sig(p,t-1) + xi(p,t)
//		!!! SEE COMMAND DESCRIPTIONS FOR MODEL 1 !!!
//		********************************	
		qui reg rp beta betasq sig if tid2 == `i'
		matrix b = e(b)
		qui replace gamma40 = b[1,4] if tid2 == `i'
		qui replace gamma41 = b[1,1] if tid2 == `i'	
		qui replace gamma42 = b[1,2] if tid2 == `i'	
		qui replace gamma43 = b[1,3] if tid2 == `i'
		matrix rsq = e(r2)
		qui replace rsq4 = rsq[1,1] if tid2 == `i'					
	}
	
	qui collapse (mean) gamma* rsq* rm rf, by(tid) // create the mean of variables which have been sorted by time index.
	gen date = dofm(tid)
	gen year = year(date) // generate year
	drop date
	save data, replace

//	***********************************
//	TEST H1 (LINEARITY) E[gamma2] = 0
//	***********************************	
	ttest gamma22 = 0 // model 2
	ttest gamma42 = 0 // model 4

//	***********************************
//	TEST H2 (NO SYSTEMATIC EFFECTS OF NON-BETA RISK) E[gamma3] = 0
//	***********************************
	ttest gamma33 = 0 // model 3
	ttest gamma43 = 0 // model 4

//	***********************************
//	TEST H3 (POSITIVE EXPECTED RETURN-RISK TRADEOFF) E[gamma1] > 0
//	***********************************
	ttest gamma11 = 0 // model 1
	ttest gamma21 = 0 // model 2
	ttest gamma31 = 0 // model 3
	ttest gamma41 = 0 // model 4
	qui ge mktpm1 = rm - gamma10 // create market premium, model 1
	qui ge mktpm2 = rm - gamma20 // create market premium, model 2
	qui ge mktpm3 = rm - gamma30 // create market premium, model 3
	qui ge mktpm4 = rm - gamma40 // create market premium, model 4
	ttest gamma11 = mktpm1 // model 1
	ttest gamma21 = mktpm2 // model 2
	ttest gamma31 = mktpm3 // model 3
	ttest gamma41 = mktpm4 // model 4
	
//	***********************************
//	TEST H4 SL
//	***********************************
	ttest gamma10 = rf // model 1
	ttest gamma10 = rf if year >= 2009 & year <= 2012
	ttest gamma10 = rf if year >= 2013 & year <= 2016
	ttest gamma10 = rf if year >= 2017 & year <= 2019
	ttest gamma20 = rf // model 2
	ttest gamma20 = rf if year >= 2009 & year <= 2012
	ttest gamma20 = rf if year >= 2013 & year <= 2016
	ttest gamma20 = rf if year >= 2017 & year <= 2019
	ttest gamma30 = rf // model 3
	ttest gamma30 = rf if year >= 2009 & year <= 2012
	ttest gamma30 = rf if year >= 2013 & year <= 2016
	ttest gamma30 = rf if year >= 2017 & year <= 2019
	ttest gamma40 = rf // model 4
	ttest gamma40 = rf if year >= 2009 & year <= 2012
	ttest gamma40 = rf if year >= 2013 & year <= 2016
	ttest gamma40 = rf if year >= 2017 & year <= 2019
//	===========================================================================		
	restore // recover the original dataset.
	
//	reserve
//	===========================================================================
//	SUBPERIOD ANALYSIS
//		REPLICATE THE FULL-SAMPLE ANALYSIS FOR THE SUB-SAMPLE
//	===========================================================================	
//	restore

	mata
	mata clear
	end
	
log close

