//	===========================================================================         
//	An-Empirical-Study-of-CAPM
// 	Code Part 2 : Fama-French Three Factor model(1993)
//	Author : Kai Ren
//	===========================================================================

//	===========================================================================
//	STEP 1. INSTALL PACKAGE
//	===========================================================================
	ssc install egenmore
	ssc install asreg 
	ssc install tidy

//	===========================================================================
//	STEP 2. CHANGE FILE LOADER
//	===========================================================================
//	***********************************
//	2.1 Raw data loader(read data from it)
//	***********************************
	cd D:\CAPM\Data\Part2_FF_3Factor\Raw
//	***********************************
//	2.2 Target data lodaer(save data to it)
//	***********************************
	global res_path D:\CAPM\Data\Part2_FF_3Factor\Target

//	===========================================================================
//	STEP 3. DATA PRE PROCESS
//	===========================================================================
//	***********************************
//	3.1 generate rf
//	***********************************
	use RiskFreeRates.dta, clear // 无风险利率采用一年期定期存款利率
	gen 交易月份=substr(交易日期, 1, 7) // 生成交易月份变量
	collapse (mean) Rf=月度化无风险利率, by(交易月份) // 转化为月份数据
	save Rf.dta, replace
//	***********************************
//	3.2 generate rm
//	***********************************
	use TotalMarketReturn_month.dta, clear // 采用市值加权平均法计算，考虑现金红利再投资的综合月度市场回报率
	keep if 市场类型==21
	save Rm.dta, replace
//	***********************************
//	3.3 根据日交易数据判断当月是否 ST
//	***********************************
	use ReturenRate_day.dta, clear
	gen 是否ST=inlist(交易状态, 2, 3, 5, 6, 8, 9, 11, 12, 14, 15)
	gen 是否PT=inlist(交易状态, 16)
	gen 是否ST或PT=inlist(交易状态, 2, 3, 5, 6, 8, 9, 11, 12, 14, 15, 16)
	gen 交易月份=substr(交易日期, 1, 7)
	collapse (max) 是否ST 是否PT 是否ST或PT, by(stkcd 交易月份) // 转化为月份数据
	save ST_orNot.dta, replace
//	***********************************
//	3.4
//		GET BE 账面价值是t-1年12月底的账面所有者权益
//		GET ME 市场价值是t-1年12底的市场总值
//	***********************************
	use BalanceSheet.dta, clear
	keep stkcd year 资产总计 所有者权益合计
	save BE.dta, replace

	use ReturenRate_year.dta, clear
	replace 年个股总市值=年个股总市值*1000 // 市值的单位是千元，转化为元
	replace 年个股流通市值=年个股流通市值*1000
	keep stkcd year 年个股流通市值 年个股总市值
	save ME.dta, replace

//	===========================================================================
//	STEP 4. RETURN DATA PROCESS
//	=========================================================================== 
	use ReturenRate_month.dta, clear
	keep stkcd 证券代码 year 交易月份 月个股流通市值 月个股总市值 考虑现金红利再投资的月个股回报率 市场类型
	merge m:1 交易月份 using Rf.dta, nogen keep(1 3)
	merge m:1 交易月份 using Rm.dta, nogen keep(1 3) keepusing(考虑现金红利再投资的综合月市场回报率流通市值加权平均法)
	merge m:1 stkcd using CompanyFile.dta,  nogen keep(1 3) keepusing(上市日期  行业代码C)
	merge 1:1 stkcd 交易月份 using ST_orNot.dta, nogen keep(1 3)
	gen R_Rf=(考虑现金红利再投资的月个股回报率-Rf)*100 // 月超额收益率 百分比
	drop if R_Rf==.
	gen MKT=(考虑现金红利再投资的综合月市场回报率流通市值加权平均法-Rf)*100 // 市场因子 百分比
//	***********************************
// 	选取 t 年 5 月至 t+1 年 4 月作为组合
//	***********************************
	gen m = monthly(交易月份,"ym") 
	format m %tm
	xtset stkcd m
	gen group_year=year(dofm(m-4))
	label var group_year 分组对应的年份

	gen 上市月份= monthly(substr(上市日期, 1, 7),"YM") // 上市月份
	format 上市月份 %tm

	// 中国A股市场所有股票, 包括沪深主板、中小板和创业板
	// 市场类型数值含义： 1=上海A，2=上海B，4=深圳A，8=深圳B,  16=创业板， 32=科创板。
	keep if inlist(市场类型, 1, 4, 16)

	// 选择2000-2019年数据
	keep if year>=2000 & year<=2019

	// 剔除IPO后前6个月的数据（包括上市月）
	gen month_gap=m-上市月份
	drop if month_gap<6

	// 剔除ST、*ST、PT
	drop if 是否ST或PT==1 

	// 剔除金融类股票
	drop if regexm(行业代码C, "J")

	save 收益率数据.dta, replace

//	===========================================================================
//	STEP 5. GENETRAT GROUP DATA
//	=========================================================================== 
	use 收益率数据.dta, clear
	keep stkcd group_year
	duplicates drop stkcd group_year, force
	save temp.dta, replace

	// 匹配市值和账面市值数据
	use BE.dta, clear
	merge m:1 stkcd year using ME.dta, nogen keep(1 3) 

	// 使用上一年末的数据来分组
	replace year = year + 1

	gen 市值=年个股流通市值
	xtset stkcd year
	replace 市值=L.市值 if 市值==.
	gen 账面价值=所有者权益合计

	// 删除账面价值为负的股票
	drop if 账面价值 < 0
	gen 账面市值比=账面价值/市值
	keep stkcd year 市值 账面市值比
	drop if 账面市值比==. | 市值==.
	rename year group_year

	// 剔除没有收益率数据的
	merge 1:1 stkcd group_year using temp.dta, nogen keep(3)
	save 分组数据.dta, replace

//	===========================================================================
//	STEP 6. GROUPING USE ME and BE/ME
//	=========================================================================== 
	use 分组数据.dta, clear

//  剔除市值最小的 30% 的股票 - Optional
// 	egen 市值10等分=xtile(市值), n(10) by(group_year)
// 	drop if 市值10等分<=3

	// 规模的分组点为中位数
	// 前50%为小规模组S
	// 后50%为大规模组B
	egen ME_group=xtile(市值), n(2) by(group_year)
	gen 规模分组="S" if ME_group==1
	replace 规模分组="B" if ME_group==2

	// 账面市值比分组点为第30个和第70个百分位数
	egen BM_group=xtile(账面市值比), n(10) by(group_year)
	gen 账面市值比分组="L" if BM_group<=3
	replace 账面市值比分组="M" if BM_group>3 & BM_group<=7
	replace 账面市值比分组="H" if BM_group>7

	// 分成25组
	egen ME_group5=xtile(市值), n(5) by(group_year)
	egen BM_group5=xtile(账面市值比), n(5) by(group_year)

	keep stkcd group_year 规模分组 账面市值比分组 ME_group5 BM_group5 市值 账面市值比
	save 分组结果.dta, replace


//	===========================================================================
//	STEP 7. CALCULATE AVERGE RETURN OF 25 PORTIFOLIO
//	=========================================================================== 
	// 计算流通市值加权组合收益率
	use 收益率数据.dta, clear
	merge m:1 stkcd group_year using 分组结果.dta, nogen keep(3) 
	bys ME_group5 BM_group5 交易月份: egen 市值比例=pc(市值), prop
	gen 加权组合收益率=R_Rf*市值比例
	collapse (sum) 加权组合收益率, by(ME_group5 BM_group5 交易月份) // 至此就没有个股了
	save data.dta, replace
	
	// 计算总市值比例
	use 收益率数据.dta, clear
	merge m:1 stkcd group_year using 分组结果.dta, nogen keep(3)
	bys 交易月份: egen 月组合市值比例=pc(市值), prop
	collapse (sum) 月组合市值比例, by(ME_group5 BM_group5 交易月份) // 至此就没有个股了
	save data_size_pc.dta, replace
	
	// 计算平均 Size 和 B.E
	use 收益率数据.dta, clear
	merge m:1 stkcd group_year using 分组结果.dta, nogen keep(3)
	collapse (mean) 账面市值比 市值, by(ME_group5 BM_group5 交易月份) // 至此就没有个股了
	save data_average_size_be.dta, replace
	
	// 计算每月总 firm 量
	use 收益率数据.dta, clear
	merge m:1 stkcd group_year using 分组结果.dta, nogen keep(3)
	gen n = 1
	collapse (sum) n , by(ME_group5 BM_group5 交易月份) // 至此就没有个股了
	save data_firm_num.dta, replace
	
	merge 1:1 交易月份 ME_group5 BM_group5 using data.dta, nogen keep(3) 
	merge 1:1 交易月份 ME_group5 BM_group5 using data_size_pc.dta, nogen keep(3)
	merge 1:1 交易月份 ME_group5 BM_group5 using data_average_size_be.dta, nogen keep(3) 
	
	collapse (mean) 加权组合收益率  月组合市值比例  账面市值比 n 市值 , by(ME_group5 BM_group5) // 至此就没有个股了
	
	// 计算 Big Small  Newey-West t检验
	use data.dta, clear
	spread ME_group5 加权组合收益率 

	egen t=group(交易月份)
	xtset BM_group5 t 


	* 滞后项根据 q=4*(240/100)^(2/9)计算
	* di 4*(240/100)^(2/9) 

	* 验证第五组与第一组差异，求newey t值
	gen gap=加权组合收益率5-加权组合收益率1
	forv i=1/5 {
	  qui newey gap if BM_group5==`i', lag(4)
	  est store r1_`i'
	}
	esttab r1_* ,  nogap  replace keep(_cons) b(3) t(3)  star(* 0.1 ** 0.05 *** 0.01)  
	esttab r1_* using $res_path/Newey-West_T检验1.rtf,   nogap  replace keep(_cons) b(3) t(3) star(* 0.1 ** 0.05 *** 0.01)   

//	===========================================================================
//	STEP 8. CONSTRCT FACTOR
//	=========================================================================== 

	use 收益率数据.dta, clear
	merge m:1 stkcd group_year using 分组结果.dta, nogen keep(3) 

	// 将市值和BM两个指标交叉2*3组
	gen 组合=规模分组+账面市值比分组

	// 计算各组合每一期的市值加权平均收益率
	bys 组合 交易月份: egen p1=pc(市值), prop
	bys 组合 交易月份: egen 加权月超额收益率=sum(p1*R_Rf) 
	collapse (mean) 加权月超额收益率 , by(组合 规模分组  账面市值比分组 交易月份 MKT)

	// 生成变量便于计算SMB和HML
	foreach i in SH SM SL BH BM BL {
	  bys 交易月份: egen _`i'=mean(加权月超额收益率) if 组合=="`i'"
	  bys 交易月份: egen `i'=mean(_`i') 
	  drop _`i'
	}

	keep 交易月份 MKT SH SM SL BH BM BL
	duplicates drop 交易月份 MKT SH SM SL BH BM BL, force
	 
	// 计算SMB
	gen SMB=(SH+SM+SL)/3 -(BH+BM+BL)/3
	 
	// 计算HML
	gen HML=(SH+BH)/2- (SL+BL)/2

	keep 交易月份 MKT SMB HML

	save 三因子数据.dta, replace


//	===========================================================================
//	STEP 9. REG 25 PORTIFOLIO
//	===========================================================================

	use data, clear
	merge m:1 交易月份 using 三因子数据.dta, nogen 
	
	// 仅市场因子
	bys ME_group5 BM_group5: asreg 加权组合收益率 MKT , se rmse newey(4)  
	keep ME_group5 BM_group5 _Nobs _rmse _R2 _adjR2 _b_MKT _b_cons _se_MKT _se_cons
	duplicates drop ME_group5 BM_group5 _Nobs _rmse _R2 _adjR2 _b_MKT  _b_cons _se_MKT _se_cons, force
	// 计算t值和p值  标注星号
	foreach i in cons MKT {
		gen t_`i'=_b_`i'/_se_`i'
		gen p_`i'=ttail(_Nobs, abs(t_`i'))*2
		gen star_`i'="*" if p_`i'<0.1
		replace star_`i'="**" if p_`i'<0.05
		replace star_`i'="***" if p_`i'<0.01
	}
	export excel using $res_path/25分组回归结果_仅市场因子.xlsx, firstrow(var) replace
	
	use data, clear
	merge m:1 交易月份 using 三因子数据.dta, nogen 
	// 市值因子和BM因子
	bys ME_group5 BM_group5: asreg 加权组合收益率  SMB HML, se rmse newey(4)  
	keep ME_group5 BM_group5 _Nobs _rmse _R2 _adjR2  _b_SMB _b_HML _b_cons  _se_SMB _se_HML _se_cons
	duplicates drop ME_group5 BM_group5 _Nobs _rmse _R2 _adjR2  _b_SMB _b_HML _b_cons _se_SMB _se_HML _se_cons, force
	// 计算t值和p值  标注星号
	foreach i in cons  SMB HML {
		gen t_`i'=_b_`i'/_se_`i'
		gen p_`i'=ttail(_Nobs, abs(t_`i'))*2
		gen star_`i'="*" if p_`i'<0.1
		replace star_`i'="**" if p_`i'<0.05
		replace star_`i'="***" if p_`i'<0.01
	}

	 export excel using $res_path/25分组回归结果_市值因子和BM.xlsx, firstrow(var) replace
	
	use data, clear
	merge m:1 交易月份 using 三因子数据.dta, nogen 
	// 分组回归计算各组的回归系数，使用Newey-West t统计量
	bys ME_group5 BM_group5: asreg 加权组合收益率 MKT SMB HML, se rmse newey(4)  

	keep ME_group5 BM_group5 _Nobs _rmse _R2 _adjR2 _b_MKT _b_SMB _b_HML _b_cons _se_MKT _se_SMB _se_HML _se_cons
	duplicates drop ME_group5 BM_group5 _Nobs _rmse _R2 _adjR2 _b_MKT _b_SMB _b_HML _b_cons _se_MKT _se_SMB _se_HML _se_cons, force
	// 计算t值和p值  标注星号
	foreach i in cons MKT SMB HML {
		gen t_`i'=_b_`i'/_se_`i'
		gen p_`i'=ttail(_Nobs, abs(t_`i'))*2
		gen star_`i'="*" if p_`i'<0.1
		replace star_`i'="**" if p_`i'<0.05
		replace star_`i'="***" if p_`i'<0.01
	}

	 export excel using $res_path/25分组回归结果_三因子.xlsx, firstrow(var) replace
	 
	 






