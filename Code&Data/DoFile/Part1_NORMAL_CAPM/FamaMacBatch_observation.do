//	===========================================================================  
//	An-Empirical-Study-of-CAPM
// 	Code 1.3 : observe some result
//	Author : Kai Ren
//	===========================================================================
	
	clear all // clear all in memory
	set more off // set more off

//	===========================================================================
//	MATA FUNCTION
//
//	Format	:	beta_quant
//	Purpose	:	This function creates 19 quantiles corresponding to 5%, 10%, ..., 95%.
//	Input	:	var_x - variable
//	Output	:	bq, 19x1 matrix
//
//	Format	:	rho_mean
//	Purpose	:	Ljung-Box statistic (demeaned)
//	Input	:	var_x - variable
//	Output	:	r1 - autocorrelation coefficient with lag 1, scalar
//				q1 - Ljung-Box statistic, scalar
//
//	Format	:	rho_zero
//	Purpose	:	Ljung-Box statistic (zero mean assumption)
//	Input	:	var_x - variable
//	Output	:	r1 - autocorrelation coefficient with lag 1, scalar
//				q1 - Ljung-Box statistic, scalar
//	===========================================================================
	mata:

	void beta_quant(string scalar var_x) {
		real colvector x,xq
	
		x = st_matrix(var_x)
		xq = mm_quantile(x,1,(0.05\0.1\0.15\0.2\0.25\0.3\0.35\0.4\0.45\0.5\0.55\0.6\0.65\0.7\0.75\0.8\0.85\0.9\0.95))
		st_matrix("bq",xq)

	}

	void rho_mean(string scalar var_x) {
		real colvector x,x0,x1
		real scalar t,m1,m0,r1,q1
		
		st_view(x=.,.,(var_x)) // Tx1
		t = rows(x) // scalar
		x0 = x[2..t] // x(t), (T-1)x1
		x1 = x[1..t-1] // x(t-1), (T-1)x1
		m1 = sum((x0:-mean(x0)):*(x1:-mean(x1))) // sum(mx(t),mx(t-1)), scalar
		m0 = sum((x:-mean(x)):^2) // sum(mx(t)^2), scalar
		r1 = m1/m0 // autocorrelation coefficient with lag 1
		q1 = t*(t+2)*(r1^2/(t-1)) // Ljung-Box test statistic
		st_numscalar("rmean",r1)
		st_numscalar("lbmean",q1)
	
	}

	void rho_zero(string scalar var_x) {
		real colvector x,x0,x1
		real scalar t,m1,m0,r1,q1
		
		st_view(x=.,.,(var_x)) // Tx1
		t = rows(x) // scalar
		x0 = x[2..t] // x(t), (T-1)x1
		x1 = x[1..t-1] // x(t-1), (T-1)x1
		m1 = sum(x0:*x1) // sum(x(t),x(t-1)), scalar
		m0 = sum(x:^2) // sum(x(t)^2), scalar
		r1 = m1/m0 // autocorrelation coefficient with lag 1
		q1 = t*(t+2)*(r1^2/(t-1)) // Ljung-Box test statistic
		st_numscalar("rzero",r1)
		st_numscalar("lbzero",q1)
	
	}

	end	

//	===========================================================================
//	LOG AND DATA
//	===========================================================================

	cd "D:\CAPM\Data\Part1_CAPM"
	use "cnstock.dta", clear // load dataset
	rename year yid
	rename month mid
	rename trade_date tid
	rename stock_id nid
	rename SSE_return rm
	tsset nid tid, monthly // declare panel data. panel data declaration makes operation of variable easier.
	
//	===========================================================================
//	GENERATE VARIABLES
//	===========================================================================	
	ge period = . // generate testing period index
	replace period = 1 if (yid >= 2009) & (yid <= 2012) // impose 1 on the period of 2009 -- 2012
	replace period = 2 if (yid >= 2013) & (yid <= 2016) // impose 2 on the period of 2013 -- 2016
	replace period = 3 if (yid >= 2017) & (yid<= 2019) // impose 3 on the period of 2017 -- 2019
	
	ge beta = . // generate beta estimate
	ge sig_beta = . // generate standard deviation of beta
	ge r = . // generate r2 of (Rp and Rm)
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
	forvalues i = 0/0 { // just see the first year
		forvalues j = 1/724 { // looping for 724 firms
			qui reg ri rm if (yid >= 2004) & (yid <= 2008+`i') & (nid == `j') // perform regression for the period of 2004 -- 2009+i
			matrix bi = e(b) // coefficient matrix
			qui replace beta = bi[1,1] if (yid == 2009+`i') & (nid == `j') // update beta estimates for 2009+i
			matrix vi = e(V) // v matrix
			qui replace sig_beta = vi[1,1] if (yid == 2009+`i') & (nid == `j') // update beta div estimates for 2009+i
			matrix ri = e(r2) // r_squre matrix
			qui replace r = ri[1,1] if (yid == 2009+`i') & (nid == `j') // update beta div estimates for 2009+i
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
	forvalues i = 0/0 { // just see the first year
		forvalues j = 1/724 { // looping for 724 firms
			qui reg ri rm if (yid >= 2004) & (yid <= 2012+`i') & (nid == `j') // perform regression for the period of 2004 -- 2009+i
			matrix bi = e(b) // coefficient matrix
			qui replace beta = bi[1,1] if (yid == 2013+`i') & (nid == `j') // update beta estimates for 2009+i
			matrix vi = e(V) // v matrix
			qui replace sig_beta = vi[1,1] if (yid == 2013+`i') & (nid == `j') // update beta div estimates for 2009+i
			matrix ri = e(r2) // r_squre matrix
			qui replace r = ri[1,1] if (yid == 2013+`i') & (nid == `j') // update beta div estimates for 2009+i
			qui predict ei, resid // create residuals
			qui sum ei // summarize residuals
			qui replace sig = r(sd) if (yid == 2013+`i') & (nid == `j') // update the standard deviation of residuals for 2009+i and firm j
			drop ei // delete residuals
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
		forvalues i = 0/0 { // just see the first year
		forvalues j = 1/724 { // looping for 724 firms
			qui reg ri rm if (yid >= 2004) & (yid <= 2016+`i') & (nid == `j') // perform regression for the period of 2004 -- 2009+i
			matrix bi = e(b) // coefficient matrix
			qui replace beta = bi[1,1] if (yid == 2017+`i') & (nid == `j') // update beta estimates for 2009+i
			matrix vi = e(V) // v matrix
			qui replace sig_beta = vi[1,1] if (yid == 2017+`i') & (nid == `j') // update beta div estimates for 2009+i
			matrix ri = e(r2) // r_squre matrix
			qui replace r = ri[1,1] if (yid == 2017+`i') & (nid == `j') // update beta div estimates for 2009+i
			qui predict ei, resid // create residuals
			qui sum ei // summarize residuals
			qui replace sig = r(sd) if (yid == 2017+`i') & (nid == `j') // update the standard deviation of residuals for 2009+i and firm j
			drop ei // delete residuals
		}
	}
	
	replace pid = pid0 if (yid >= 2017) & (yid <= 2019)
	drop pid0
	
	keep if (yid == 2017) | (yid == 2013) | (yid == 2009)
	
//	===========================================================================
//	CONSTRUCT PORTFOLIO VARIABLES
//	(a) construct portfolio return: r_p = r_1 + ... + r_n
//	(b) construct portfolio beta: beta_p = beta_1 + ... + beta_n
//	(c) construct portfolio stadard deviation: s_p = s_1 + ... + s_n
//	===========================================================================

	collapse (mean) ri rm rf beta sig_beta r sig mid, by(period pid tid) // create average variables
	