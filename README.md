# [基于中国A股数据的资本资产定价模型实证研究](https://arxiv.org/ftp/arxiv/papers/2305/2305.04838.pdf)

<center>任凯</center>

## 核心内容介绍

本报告使用中国A股市场2000年到2019年的交易数据，对资本资产定价模型进行实证分析。首先，采用Fama-MacBetch回归对标准CAPM 进行检验，尽管结果成功验证了三个核心假设，但是得到的 $\beta$ 风险对收益率影响并不显著。其次，又分析了Fama-French三因子模型，该模型综合使用市场因子、规模因子和价值因子进行资本资产定价，结果显示其能够捕捉到A股市场收益率的绝大部分变动，对所构建25个投资组合回归得到调整后 $R^2$ 均大于0.88。最后，报告考虑了中国股市特有的IPO监管造成的“壳价值污染”问题，通过剔除市值最低30%部分的股票来尽量削减其影响，这使得三因子模型中的部分异常结果得到有效修正。本报告在数据选取上有针对性，且对数据处理与回归分析过程做了细致呈现，这1）阐释了资本资产定价模型在中国市场中的适用情况；2）为资本资产定价模型的基础学习提供了一套[开源资料](https://github.com/KarryRen/An-Empirical-Study-of-CAPM)。

**关键词**：中国A股市场数据 资本资产定价模型 Fama-French三因子模型

### 采用Fama-MacBatch回归验证标准CAPM

<img src="https://github.com/KarryRen/An-Empirical-Study-of-CAPM/blob/main/Images/Fig2.svg" alt="图2.采用Fama-MacBatch回归检验标准CAPM方法框架图" width="70%" height="70%"/>
<center>图2. 采用 Fama-MacBatch 回归验证标准 CAPM 方法框架图（以2000到2012年数据区间为例）</center>



### Fama-French 三因子模型

<img src="https://github.com/KarryRen/An-Empirical-Study-of-CAPM/blob/main/Images/Fig3.svg" alt="图3. Fama-French 三因子模型的时间序列回归数据构建框架图" width="70%" height="70%"/>
<center>图3. Fama-French 三因子模型的时间序列回归数据构建框架图</center>



## 环境要求

本文所有代码均在 `Stata16` 上调试运行，部分需要添加的包均在代码文件中说明，您只需要运行命令安装即可。注意代码文件中相关路径的修改，您可以将本项目直接下载到本地，然后修改绝对路径前缀即可。例如：

```apl
"D:\CAPM\Data\Part1_CAPM" ====>"your path \DataFile\Part1_NORMAL_CAPM"
```



## 项目结构介绍

`Code&Data` 文件夹内为本文所构建项目的代码和数据

```apl
├── DoFile "Do 文件夹，也即代码文件夹"
    ├── Part1_NORMAL_CAPM "验证标准CAPM” 所用代码"
        ├── preProcessData.do "数据预处理代码"
        ├── FamaMacBatch.do "模型回归代码"
        └── FamaMacBatch_observation.do "中间结果的统计代码"
    ├── Part2_FF_3FACTOR "分析Fama-French 三因子模型所用代码文件夹"
        └── FF_3Factor.do "该部分整体代码"
		
├── DataFile "数据文件夹"
    ├── Part1_NORMAL_CAPM "验证标准CAPM所用数据"
        ├── Raw "源数据文件夹"
            ├── stocks.dta "原始股票交易数据"
            └── SSE_index.dta "原始上证综合指数交易数据"
        └── Target "处理后数据文件夹"
            ├── index_pro.dta "处理后的上证综合指数交易数据"
            ├── stock_pro.dta "处理后的股票交易数据"
            └── cnStock.dta "拼接完成后可直接分析的最终数据"
    └── Part2_FF_3FACTOR "分析Fama-French 三因子模型所用的数据"
        ├── Raw "所有的源数据文件"
            ├── 分组结果.dta "按照规模和账面市值比分组后的结果"
            ├── 分组数据.dta "按照规模和账面市值比分组前的数据"
            ├── CompanyFile.dta "上市公司的基本文件信息"
            ├── ReturenRate_month.zip "处理后的月度个股收益率"
            ├── 三因子数据.dta "计算得到的三因子数据"
            ├── ST_orNot.dta "股票状态标识数据"
            ├── RiskFreeRates.dta "各月的无风险利率"
            ├── BalanceSheet.zip "上市公司的资产负债表信息"
            ├── TotalMarketReturn_month.dta "计算得到的市场组合回报率"
            ├── BE.dta "账面市值比数据"
            ├── data.dta "处理完成的数据结果"
            ├── data_average_size_be.dta "中间结果：组合的平均规模和BE"
            ├── data_firm_num.dta "中间结果：组合的月平均公司数"
            ├── data_size_pc.dta "中间结果：组合的月市值占比"
            ├── ME.dta "规模数据"
            ├── Rf.dta "无风险收益率"
            └── Rm.dta "市场组合收益率"
        └── Result "所有的回归结果"
            ├── 结果整理_不剔除30%.xlsx "所有数据的回归结果"
            └── 结果整理_剔除30%.xlsx "考虑剔除最低市值30%股票的结果"

```

## 联系我们

如果您对本项目有任何问题，可直接通过（KarryRenKai@outlook.com）联系我们

## 补充信息：

均值方差假设：投资者通过观察一段时间内证券组合的收益率和标准差来评判证券组合，若标准差相同，投资者将选择具有较高收益率的证券组合，若预期收益率等同，投资者将选择具有较低标准差的证券组合。

投资者一致假设：市场中所有投资者计划的投资时点和投资期限相同，组成各个投资组合的证券数目相同，投资者对证券的收益率、标准差、协方差看法相同，投资者选择不同投资组合的原因只是风险偏好不同。

完全市场假设：市场不存在交易成本和税收，所有资产完全可分割、可交易，市场是完全竞争的，信息成本为零，所有市场参与者同时接受信息，且都是理性的。
