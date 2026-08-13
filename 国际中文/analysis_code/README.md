# PIRLS 2021 潜在剖面分析（LPA）

基于 `newLPA.xlsx` 数据，以国家为样本单位进行潜在剖面分析。

## 📋 数据说明

数据文件：`newLPA.xlsx`

**数据结构**：
- **第一列**：`IDCNTRY`（国家ID），相同IDCNTRY的行构成一个国家
- **整体阅读素养**：`ASRREA01-05`（5个合理值）
- **四个子领域**（LPA分类变量）：
  - `ASRLIT01-05`：文学体验（Literary）
  - `ASRINF01-05`：获取及使用信息（Informational）
  - `ASRRSI01-05`：检索与直接推论（Retrieving & Straightforward Inferencing）
  - `ASRIIE01-05`：解释、整合与评价（Interpreting, Integrating & Evaluating）

## 🚀 快速开始

### 方法1：一键运行（推荐）

```r
source("analysis_code/quick_start.R")
source("E:/BLCU/DC24/国际中文/analysis_code/quick_start.R")
```

### 方法2：分步运行

```r
# 步骤0：初始化环境
source("analysis_code/00_init_environment.R")

# 步骤4：LPA分析
source("analysis_code/04_latent_profile_analysis.R")
```

## 📊 分析流程

1. **数据读取**：从 `newLPA.xlsx` 读取数据
2. **数据预处理**：
   - 计算每个子领域的均值（5个合理值的均值）
   - 筛选有效数据
3. **国家汇总**：按国家计算均值（每个国家作为一个样本）
4. **LPA分析**：拟合1-5个剖面的模型
5. **模型选择**：基于BIC选择最优模型
6. **剖面命名**：根据四个子领域的均值命名剖面
7. **结果验证**：验证剖面与整体阅读素养（ASRREA）的关系

## 📁 输出文件

运行完成后，结果保存在：

```
analysis_code/
├── results/
│   ├── 04_LPA_model_comparison.csv      # 模型对比表（AIC, BIC, aBIC, Entropy, LMRtp, BLRtp）
│   └── 04_LPA_country_profiles.csv      # 国家剖面分配结果
└── data/
    └── 04_lpa_analysis.RData            # 完整分析结果（R格式）
```

## 📈 模型对比指标

- **AIC**：Akaike信息准则
- **BIC**：Bayesian信息准则
- **aBIC**：调整后的BIC
- **Entropy**：分类质量（0-1，越接近1越好）
- **LMRtp**：Lo-Mendell-Rubin检验p值
- **BLRtp**：Bootstrap似然比检验p值

## 🔧 依赖包

- `tidyverse`：数据处理
- `tidyLPA`：LPA分析
- `mice`：多重插补
- `openxlsx`：Excel读写

所有包会在首次运行时自动安装。

## ⚠️ 注意事项

1. 确保 `newLPA.xlsx` 文件在项目根目录下
2. 首次运行需要安装R包，可能需要10-20分钟
3. 如果国家数少于5个，LPA分析可能不稳定

## 📝 分析逻辑

- **样本单位**：国家（每个国家是一个样本）
- **LPA变量**：四个子领域得分（LIT_SCORE, INF_SCORE, RSI_SCORE, IIE_SCORE）
- **结果变量**：整体阅读素养得分（REA_SCORE）
- **模型数量**：1-5个剖面
- **选择标准**：BIC最小

## 🎯 剖面命名规则

- **四领域高水平组**：所有子领域均值 > 550
- **文学-信息优势组**：LIT和INF > 500，RSI和IIE < 500
- **推论-评价优势组**：LIT和INF < 500，RSI和IIE > 500
- **其他**：自动命名为"剖面1"、"剖面2"等

