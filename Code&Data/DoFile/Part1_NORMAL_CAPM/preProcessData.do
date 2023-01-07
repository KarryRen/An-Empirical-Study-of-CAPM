//	===========================================================================
//
//	Final Paper of financial Econometrics
// 	Code 1.1 : pre process data of stocks and index 
//			 After processing, we can get the normal stock data 
//			 stock_id, stock_code, stock_name, trade_date, sp, re, SSE_index
//	Author : Kai Ren
// 
//	===========================================================================

//	===========================================================================
//	STEP 1. NORMAL SETTING
//	===========================================================================
	clear all // clear all in memory
	set mem 500m // adjust memory
	cap log close  // close log file before
	log using preProcess.log, text replace // generate a new log file

//	===========================================================================
//	STEP 2. LOAD STOCK DATA AND PROCESS
//	===========================================================================
	cd "C:\Users\16332\Desktop\FinEcon\FinalPaper\CAPM\Data\Part1_CAPM\Raw"
	use stocks, clear // load stock data
	
	// change name and lable
	rename 股票代码_Stkcd 			stock_code
	label  variable stock_code		"股票代码"
	rename 最新股票名称_Lstknm  	stock_name
	label  variable stock_name		"股票名称"
	rename 日期_Date				trade_date
	label  variable trade_date		"交易日期（月为单位）"
	rename 月收益率_Monret			ri
	label  variable ri				"股票收益率（月收益率）"
	rename 收盘价_ClPr				sp
	label  variable sp				"股票收盘价"
	rename 月无风险收益率_Monrfret 	rf
	label  variable rf				"无风险收益率"
	
	drop if ri == . // drop if return is empty
	gen year = year(trade_date) // generate year of date
	gen month = month(trade_date) // generate month of date
	gen temp_trade_date = ym(year, month) // generate new date
	drop trade_date 		// delete old trade date
	rename temp_trade_date trade_date
	format trade_date %tm 	// set format year-month 
	label  variable trade_date		"交易日期（年-月）"
	
	drop if year < 2000 | year > 2019 // only keep 2000 to 2019
	
	egen stock_id = group(stock_code) // get a simple id to desctribe stocks
	bys stock_id: egen n = nvals(year)
	drop if n < 20 // Just Keep those stocks from 1995 to 2021	27 years
	drop n
	drop stock_id
	egen stock_id = group(stock_code)
	
	cd "C:\Users\16332\Desktop\FinEcon\FinalPaper\CAPM\Data\Part1_CAPM\Target"
	save stock_pro, replace // save data get
	
//	===========================================================================
//	STEP 3. LOAD INDEX DATA AND PROCESS
//	===========================================================================
	cd "C:\Users\16332\Desktop\FinEcon\FinalPaper\CAPM\Data\Part1_CAPM\Raw"
	use SSE_index, clear // load index data
	
	rename 指数代码_IdxCd 			index_code
	label  variable index_code		"指数代码"
	rename 指数名称_IdxNm  			index_name
	label  variable index_name		"指数名称"
	rename 交易日期_TrdDt			trade_date
	label  variable trade_date		"交易日期（月为单位）"
	rename 指数月收益率_IdxMonRet	SSE_return
	label  variable SSE_return		"指数收益率（月收益率）"
	
	drop if SSE_return == . // drop if return is empty
	gen year = year(trade_date) // generate year of date
	gen month = month(trade_date) // generate month of date
	gen temp_trade_date = ym(year, month) // generate new date
	drop if year < 2000 | year > 2019 // only keep 2000 to 2019
	drop trade_date 		// delete old trade date
	drop year month 		// delete temp var
	rename temp_trade_date trade_date
	format trade_date %tm 	// set format year-month 
	
	
	
	cd "C:\Users\16332\Desktop\FinEcon\FinalPaper\CAPM\Data\Part1_CAPM\Target"
	save index_pro, replace // save data

//	===========================================================================
//	STEP 4. MERGE
//	===========================================================================	
	cd "C:\Users\16332\Desktop\FinEcon\FinalPaper\CAPM\Data\Part1_CAPM\Target"
	use stock_pro, clear // load stock data
	merge m:1 trade_date using index_pro  // m:1 use trade_date merge stock and index
	sort stock_id trade_date // sort by stock_id and trade_date
	tab _merge
	keep if _merge==3	// only match record stay
	drop _merge	收盘价_ClPr		// get target data
	drop index_code index_name
	drop sp

//	===========================================================================
//	STEP 5. SAVE AS cnStock
//  ===========================================================================	
	cd "C:\Users\16332\Desktop\FinEcon\FinalPaper\CAPM\Data\Part1_CAPM"
	save cnStock, replace // save data get

	
