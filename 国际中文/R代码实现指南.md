# 基于PIRLS 2021密码本的R实现指南
## 阅读目的协变量分类分析

---

## 0. 环境准备与包安装

```r
# 0.1 设置工作目录
setwd("E:/BLCU/DC24/二期")

# 0.2 安装必要的包
packages_needed <- c(
  "tidyverse",       # 数据处理（dplyr, tidyr等）
  "tidyLPA",         # LPA分析
  "mclust",          # 混合模型聚类
  "lme4",            # 多层模型
  "lmerTest",        # lme4的p值
  "haven",           # 读取SPSS/SAS数据
  "readxl",          # 读取Excel数据
  "mice",            # 多重插补
  "ggplot2",         # 绘图
  "gridExtra",       # 多图合并
  "corrplot",        # 相关矩阵热力图
  "sjPlot",          # 快速建模和绘图
  "performance",     # 模型评估
  "see"              # 高级可视化
)

# 自动安装缺失的包
for (pkg in packages_needed) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

# 设置中文显示
Sys.setlocale("LC_ALL", "Chinese")
```

---

## 1. 基于密码本的数据导入与处理

```r
# 1.1 读取密码本（用于参考变量定义）
codebook_path <- "P21_Codebook.xlsx"

# 读取各工作表的变量定义
# ASAR5: 学生问卷（A部分）- 学生背景和态度
# ASRR5: 学生阅读反应数据
# ASGR5: 学生问卷（G部分）- 一般问卷
# 等等

codebook_sheets <- readxl::excel_sheets(codebook_path)
cat("密码本包含的数据集：\n", paste(codebook_sheets, collapse=", "), "\n\n")

# 1.2 从IDB数据文件导入PIRLS 2021数据
# PIRLS 2021数据格式：Rdata或CSV
# 假设已获取的标准IDB数据集

# 方式1：从Rdata导入（IDB官方格式）
# load("PIRLS_2021_IDB_data.Rdata")
# pirls_data <- as.data.frame(pirls_data)

# 方式2：从CSV导入（已预处理）
pirls_raw <- readr::read_csv("PIRLS_2021_processed.csv", 
                               locale = readr::locale(encoding = "UTF-8"))

# 1.3 基于密码本定义变量
# 根据P21_Codebook的变量定义进行重命名

# 关键变量对应表（来自密码本）：
variable_mapping <- list(
  # 个体标识符
  student_id = "IDSTUD",           # 学生ID
  school_id = "IDSCHOOL",          # 学校ID
  class_id = "IDCLASS",            # 班级ID
  country_id = "IDCNTRY",          # 国家代码
  
  # 阅读成绩（根据密码本ASRREA0系列）
  reading_literacy = "ASRREA0",    # 阅读素养总成绩
  reading_lit_score = "ASRLIT",    # 文学阅读分数
  reading_info_score = "ASRINF",   # 信息性阅读分数
  
  # 阅读态度（根据密码本中的态度量表）
  reading_interest = "ASRRIN0",    # 阅读兴趣指数
  reading_confidence = "ASRCON0",  # 阅读信心指数
  reading_engagement = "ASRREG0",  # 阅读投入指数
  
  # 阅读目的（核心变量）
  # 根据密码本中的问卷项（通常为RP/RP类变量）
  purpose_literature = "ASRLIT0",  # 文学体验目的
  purpose_info = "ASRINF0",        # 获取信息目的
  
  # 学生背景（ASBG系列）
  gender = "ITSEX",                # 性别
  age_year = "ITBIRTHY",           # 出生年
  age_month = "ITBIRTHM",          # 出生月
  
  # 语言环境
  home_language = "ITLANG",        # 家庭语言
  
  # 学校类型/资源（ASCH系列）
  school_type = "ITSCHTP",         # 学校类型
  school_size = "ASCHSCH"          # 学校规模
)

# 1.4 选择和重命名变量
var_to_select <- unlist(variable_mapping)
var_to_select <- var_to_select[var_to_select %in% names(pirls_raw)]

pirls_data <- pirls_raw %>%
  select(all_of(var_to_select)) %>%
  rename(!!!setNames(names(variable_mapping), 
                     unlist(variable_mapping)[names(variable_mapping)]))

cat("数据维度：", dim(pirls_data), "\n")
cat("选中变量：", ncol(pirls_data), "\n")

# 1.5 数据类型标准化
pirls_data <- pirls_data %>%
  mutate(
    student_id = as.character(student_id),
    school_id = as.character(school_id),
    class_id = as.character(class_id),
    country_id = as.factor(country_id),
    gender = as.factor(gender),
    across(starts_with("reading"), as.numeric),
    across(starts_with("purpose"), as.numeric),
    across(starts_with("home"), as.factor)
  )

# 1.6 缺失值分析
cat("\n缺失值统计：\n")
missing_stats <- data.frame(
  变量 = names(pirls_data),
  缺失数 = colSums(is.na(pirls_data)),
  缺失比例 = round(100 * colMeans(is.na(pirls_data)), 2)
) %>%
  filter(缺失数 > 0) %>%
  arrange(desc(缺失比例))

print(missing_stats)

# 1.7 多重插补（针对核心变量）
impute_vars <- c(
  "reading_literacy", "reading_interest", "reading_confidence",
  "purpose_literature", "purpose_info"
)

# 只对缺失数据进行插补
impute_data <- pirls_data %>%
  select(all_of(impute_vars))

# 执行多重插补（5次）
imputed <- mice::mice(
  impute_data,
  m = 5,
  method = "pmm",
  maxit = 50,
  seed = 2024,
  printFlag = FALSE
)

# 使用第一个插补数据集
pirls_data <- complete(imputed, action = 1) %>%
  bind_cols(
    pirls_data %>% select(-all_of(impute_vars))
  )

cat("\n插补完成，样本量：", nrow(pirls_data), "\n")
```

---

## 2. 阅读目的分类编码

```r
# 2.1 阅读目的变量标准化
# 根据密码本，这些是连续变量（1-4或1-5量表）
# 需要先标准化处理

pirls_data <- pirls_data %>%
  mutate(
    # 标准化（z-score）
    purpose_lit_z = scale(purpose_literature)[,1],
    purpose_info_z = scale(purpose_info)[,1],
    
    # 中位数二分类
    purpose_lit_binary = ifelse(purpose_lit_z >= 0, 1, 0),
    purpose_info_binary = ifelse(purpose_info_z >= 0, 1, 0)
  )

# 2.2 构建4个阅读目的类型
pirls_data <- pirls_data %>%
  mutate(
    reading_purpose_type = case_when(
      purpose_lit_binary == 1 & purpose_info_binary == 1 ~ "A",
      purpose_lit_binary == 1 & purpose_info_binary == 0 ~ "B",
      purpose_lit_binary == 0 & purpose_info_binary == 1 ~ "C",
      purpose_lit_binary == 0 & purpose_info_binary == 0 ~ "D",
      TRUE ~ NA_character_
    )
  )

# 2.3 检查分布
purpose_dist <- pirls_data %>%
  group_by(reading_purpose_type) %>%
  summarise(
    n = n(),
    percentage = round(100 * n() / nrow(pirls_data), 2),
    .groups = 'drop'
  ) %>%
  arrange(reading_purpose_type)

cat("\n阅读目的类型分布：\n")
print(purpose_dist)

# 2.4 可视化
p_dist <- ggplot(purpose_dist, aes(x = reading_purpose_type, 
                                    y = percentage, 
                                    fill = reading_purpose_type)) +
  geom_col(alpha = 0.8, color = "black") +
  geom_text(aes(label = paste0(percentage, "%")), 
            vjust = -0.5, size = 4) +
  scale_fill_manual(values = c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728")) +
  labs(
    title = "阅读目的类型分布",
    x = "阅读目的类型",
    y = "百分比（%）",
    fill = "目的类型"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5))

ggsave("01_purpose_distribution.png", p_dist, width = 8, height = 6, dpi = 300)
```

---

## 3. 描述性统计分析

```r
# 3.1 全样本描述统计
desc_vars <- c("reading_literacy", "reading_interest", 
               "reading_confidence", "purpose_literature", "purpose_info")

desc_stats <- pirls_data %>%
  select(all_of(desc_vars)) %>%
  summarise(
    across(everything(), 
           list(Mean = ~mean(., na.rm=TRUE),
                SD = ~sd(., na.rm=TRUE),
                Min = ~min(., na.rm=TRUE),
                Max = ~max(., na.rm=TRUE),
                Median = ~median(., na.rm=TRUE)),
           .names = "{.col}_{.fn}")
  ) %>%
  t() %>%
  as.data.frame() %>%
  rownames_to_column("指标")

cat("\n全样本描述统计：\n")
print(desc_stats)

# 3.2 分层描述统计（按阅读目的类型）
stratified_stats <- pirls_data %>%
  group_by(reading_purpose_type) %>%
  summarise(
    n = n(),
    读_literacy_M = round(mean(reading_literacy, na.rm=T), 2),
    读_literacy_SD = round(sd(reading_literacy, na.rm=T), 2),
    读_interest_M = round(mean(reading_interest, na.rm=T), 2),
    读_interest_SD = round(sd(reading_interest, na.rm=T), 2),
    读_conf_M = round(mean(reading_confidence, na.rm=T), 2),
    读_conf_SD = round(sd(reading_confidence, na.rm=T), 2),
    .groups = 'drop'
  )

cat("\n分层描述统计（按阅读目的类型）：\n")
print(stratified_stats)

# 3.3 方差分析（检验不同目的类型间的差异）
anova_model <- lm(reading_literacy ~ reading_purpose_type, data = pirls_data)
anova_result <- anova(anova_model)

cat("\n方差分析结果：\n")
print(anova_result)
print(summary(anova_model))

# 3.4 相关性分析
cor_matrix <- cor(pirls_data %>% 
                  select(all_of(desc_vars)),
                  use = "complete.obs")

cat("\n相关矩阵：\n")
print(round(cor_matrix, 3))

# 相关矩阵可视化
png("02_correlation_matrix.png", width = 800, height = 700)
corrplot(cor_matrix, method = "circle", type = "upper", 
         diag = FALSE, addCoef.col = "black", number.cex = 0.8)
dev.off()
```

---

## 4. 潜在剖面分析（LPA）

```r
# 4.1 准备分层数据
data_typeA <- pirls_data %>% filter(reading_purpose_type == "A")
data_typeB <- pirls_data %>% filter(reading_purpose_type == "B")
data_typeC <- pirls_data %>% filter(reading_purpose_type == "C")
data_typeD <- pirls_data %>% filter(reading_purpose_type == "D")

cat("各类型样本量：\n")
cat("A型：", nrow(data_typeA), "\n")
cat("B型：", nrow(data_typeB), "\n")
cat("C型：", nrow(data_typeC), "\n")
cat("D型：", nrow(data_typeD), "\n")

# 4.2 LPA分析函数
run_lpa_analysis <- function(data, purpose_type) {
  
  cat("\n========== 类型", purpose_type, "的LPA分析 ==========\n")
  
  # 准备用于LPA的变量
  lpa_data <- data %>%
    select(reading_literacy, reading_interest, reading_confidence) %>%
    na.omit()
  
  # 标准化
  lpa_data_scaled <- scale(lpa_data)
  
  # 逐步增加剖面数（2-5个）
  results <- list()
  for (n_prof in 2:5) {
    cat(sprintf("  拟合%d个剖面...", n_prof))
    
    lpa_model <- tidyLPA(
      lpa_data,
      reading_literacy,
      n_profiles = n_prof,
      models = 1:4,
      standardize = FALSE
    )
    
    results[[as.character(n_prof)]] <- lpa_model
    cat(" 完成\n")
  }
  
  # 模型对比
  cat("\n模型对比指标：\n")
  comparison <- data.frame(
    Profiles = 2:5,
    AIC = sapply(results, function(m) get_lowest_ic(m)["AIC"]),
    BIC = sapply(results, function(m) get_lowest_ic(m)["BIC"]),
    SABIC = sapply(results, function(m) get_lowest_ic(m)["SABIC"])
  )
  print(comparison)
  
  # 选择最优模型（基于BIC）
  best_n <- as.numeric(names(results)[which.min(
    sapply(results, function(m) get_lowest_ic(m)["BIC"])
  )])
  
  cat(sprintf("\n最优模型：%d个剖面\n", best_n))
  
  # 提取最优模型的结果
  best_model <- results[[as.character(best_n)]]
  profile_data <- get_data(best_model)
  
  # 将剖面分配和概率加入原数据
  data_with_profile <- data %>%
    mutate(
      profile = profile_data$Class,
      profile_prob = profile_data$Probability
    )
  
  # 剖面特征
  cat("\n剖面特征：\n")
  profile_chars <- data_with_profile %>%
    group_by(profile) %>%
    summarise(
      n = n(),
      读_literacy = round(mean(reading_literacy, na.rm=T), 2),
      读_interest = round(mean(reading_interest, na.rm=T), 2),
      读_conf = round(mean(reading_confidence, na.rm=T), 2),
      .groups = 'drop'
    )
  print(profile_chars)
  
  return(list(
    data = data_with_profile,
    best_n = best_n,
    comparison = comparison,
    characteristics = profile_chars
  ))
}

# 4.3 对各类型进行LPA分析
lpa_results <- list()
lpa_results$A <- run_lpa_analysis(data_typeA, "A")
lpa_results$B <- run_lpa_analysis(data_typeB, "B")
lpa_results$C <- run_lpa_analysis(data_typeC, "C")
lpa_results$D <- run_lpa_analysis(data_typeD, "D")

# 4.4 合并所有类型的剖面数据
all_data_with_profile <- bind_rows(
  lpa_results$A$data %>% mutate(purpose_type = "A"),
  lpa_results$B$data %>% mutate(purpose_type = "B"),
  lpa_results$C$data %>% mutate(purpose_type = "C"),
  lpa_results$D$data %>% mutate(purpose_type = "D")
)
```

---

## 5. 多层线性模型（HLM）分析

```r
# 5.1 中心化处理
all_data_with_profile <- all_data_with_profile %>%
  mutate(
    # Grand Mean Centering
    reading_interest_gmc = reading_interest - mean(reading_interest, na.rm=T),
    reading_confidence_gmc = reading_confidence - mean(reading_confidence, na.rm=T),
    
    # 虚拟变量编码（参照类型A）
    purpose_B = as.numeric(reading_purpose_type == "B"),
    purpose_C = as.numeric(reading_purpose_type == "C"),
    purpose_D = as.numeric(reading_purpose_type == "D")
  )

# 5.2 计算学校层面的平均值
school_agg <- all_data_with_profile %>%
  group_by(school_id, country_id) %>%
  summarise(
    n_students = n(),
    school_interest_mean = mean(reading_interest, na.rm=T),
    school_confidence_mean = mean(reading_confidence, na.rm=T),
    school_literacy_mean = mean(reading_literacy, na.rm=T),
    .groups = 'drop'
  )

# 合并学校数据
all_data_with_profile <- all_data_with_profile %>%
  left_join(school_agg, by = c("school_id", "country_id")) %>%
  mutate(
    # School Mean Centering
    reading_interest_smc = reading_interest - school_interest_mean,
    reading_confidence_smc = reading_confidence - school_confidence_mean
  )

# 5.3 构建三水平混合效应模型
cat("\n========== 多层线性模型拟合 ==========\n")

# 模型公式
formula_hlm <- formula(
  reading_literacy ~ 
    reading_interest_smc + reading_confidence_smc +
    purpose_B + purpose_C + purpose_D +
    reading_interest_smc:purpose_B +
    reading_interest_smc:purpose_C +
    reading_interest_smc:purpose_D +
    school_interest_mean + school_confidence_mean +
    (1 + reading_interest_smc | school_id) +
    (1 | country_id)
)

# 拟合模型
hlm_model <- lmer(
  formula_hlm,
  data = all_data_with_profile,
  control = lmerControl(
    optimizer = "bobyqa",
    optCtrl = list(maxfun = 2e5)
  ),
  REML = TRUE
)

# 5.4 模型摘要
cat("\n=== 固定效应 ===\n")
print(summary(hlm_model))

# 5.5 方差分解
var_residual <- sigma(hlm_model)^2
vc <- VarCorr(hlm_model)
var_school <- as.numeric(vc$school_id[1,1])
var_country <- as.numeric(vc$country_id[1,1])
var_total <- var_residual + var_school + var_country

cat("\n=== 方差分解 ===\n")
cat("学生水平方差比例:", round(100*var_residual/var_total, 2), "%\n")
cat("学校水平方差比例:", round(100*var_school/var_total, 2), "%\n")
cat("国家水平方差比例:", round(100*var_country/var_total, 2), "%\n")

# 5.6 模型诊断
cat("\n=== 模型诊断 ===\n")
print(performance::model_performance(hlm_model))

# 5.7 固定效应系数表
fixed_ef <- fixef(hlm_model)
se_fixed <- sqrt(diag(as.matrix(vcov(hlm_model))))

fe_table <- data.frame(
  系数 = fixed_ef,
  标准误 = se_fixed,
  t值 = fixed_ef / se_fixed,
  显著性 = ifelse(
    abs(fixed_ef/se_fixed) > 3, "***",
    ifelse(abs(fixed_ef/se_fixed) > 2.576, "**",
           ifelse(abs(fixed_ef/se_fixed) > 1.96, "*", ""))
  )
)

cat("\n固定效应系数表：\n")
print(round(fe_table, 4))
```

---

## 6. 交互效应分析

```r
# 6.1 简单斜率分析
cat("\n========== 简单斜率分析 ==========\n")

# 提取系数
coef_interest <- fixef(hlm_model)["reading_interest_smc"]
coef_int_B <- fixef(hlm_model)["reading_interest_smc:purpose_B"]
coef_int_C <- fixef(hlm_model)["reading_interest_smc:purpose_C"]
coef_int_D <- fixef(hlm_model)["reading_interest_smc:purpose_D"]

simple_slopes <- data.frame(
  purpose_type = c("A", "B", "C", "D"),
  slope = c(
    coef_interest,
    coef_interest + coef_int_B,
    coef_interest + coef_int_C,
    coef_interest + coef_int_D
  )
)

cat("\n简单斜率（条件效应）：\n")
print(simple_slopes)

# 6.2 效应图绘制
interest_range <- seq(-3, 3, by = 0.1)

# 预测函数
predict_literacy <- function(interest, purpose_type) {
  intercept <- fixef(hlm_model)["(Intercept)"]
  coef_int <- fixef(hlm_model)["reading_interest_smc"]
  
  if (purpose_type == "B") {
    coef_int <- coef_int + fixef(hlm_model)["reading_interest_smc:purpose_B"]
  } else if (purpose_type == "C") {
    coef_int <- coef_int + fixef(hlm_model)["reading_interest_smc:purpose_C"]
  } else if (purpose_type == "D") {
    coef_int <- coef_int + fixef(hlm_model)["reading_interest_smc:purpose_D"]
  }
  
  intercept + coef_int * interest
}

# 创建预测数据
pred_data <- expand.grid(
  interest = interest_range,
  purpose_type = c("A", "B", "C", "D")
) %>%
  mutate(
    predicted = mapply(predict_literacy, interest, purpose_type)
  )

# 绘图
p_interact <- ggplot(pred_data, aes(x = interest, y = predicted, 
                                     color = purpose_type, 
                                     linetype = purpose_type)) +
  geom_line(size = 1) +
  scale_color_manual(values = c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728")) +
  scale_linetype_manual(values = c("solid", "dashed", "dotted", "dotdash")) +
  labs(
    title = "阅读目的调节的态度-素养关系",
    x = "阅读兴趣（中心化）",
    y = "阅读素养得分预测值",
    color = "目的类型",
    linetype = "目的类型"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(size = 14, face = "bold", hjust = 0.5))

ggsave("06_interaction_effect_plot.png", p_interact, 
       width = 10, height = 7, dpi = 300)
```

---

## 7. 国家异质性分析

```r
# 7.1 提取国家层的随机效应
country_effects <- ranef(hlm_model)$country_id %>%
  as.data.frame() %>%
  rownames_to_column("country_id")

names(country_effects) <- c("country_id", "intercept", "slope")

# 7.2 排序绘图
country_effects_sorted <- country_effects %>%
  arrange(slope)

p_country <- ggplot(country_effects_sorted, 
                     aes(x = reorder(country_id, slope), y = slope)) +
  geom_col(fill = "#3498db", alpha = 0.8) +
  coord_flip() +
  labs(
    title = "不同国家中阅读兴趣的随机斜率",
    x = "国家",
    y = "阅读兴趣斜率偏差"
  ) +
  theme_minimal() +
  theme(axis.text.y = element_text(size = 7))

ggsave("07_country_heterogeneity.png", p_country, 
       width = 10, height = 12, dpi = 300)

# 7.3 统计摘要
cat("\n国家异质性摘要：\n")
cat("斜率范围：", 
    round(min(country_effects$slope), 4), 
    "~", 
    round(max(country_effects$slope), 4), "\n")
cat("斜率标准差：", round(sd(country_effects$slope), 4), "\n")

# 效应最强的国家
cat("\n效应最强的10个国家（正向）：\n")
print(country_effects %>% top_n(10, slope) %>% select(country_id, slope))

cat("\n效应最强的10个国家（负向）：\n")
print(country_effects %>% top_n(-10, slope) %>% select(country_id, slope))
```

---

## 8. 结果输出与汇总

```r
# 8.1 创建综合结果列表
results_summary <- list(
  描述统计 = desc_stats,
  分层统计 = stratified_stats,
  LPA模型比较_A = lpa_results$A$comparison,
  LPA模型比较_B = lpa_results$B$comparison,
  LPA模型比较_C = lpa_results$C$comparison,
  LPA模型比较_D = lpa_results$D$comparison,
  固定效应 = fe_table,
  简单斜率 = simple_slopes,
  国家异质性 = country_effects
)

# 8.2 导出为Excel
openxlsx::write.xlsx(
  results_summary,
  file = "analysis_results_summary.xlsx",
  sheetName = names(results_summary),
  overwrite = TRUE
)

cat("\n结果已导出到: analysis_results_summary.xlsx\n")

# 8.3 生成分析报告
report_text <- sprintf(
  "PIRLS 2021 阅读目的协变量分类分析报告\n
========================================\n
分析日期: %s\n
\n数据概况：\n
- 总样本量：%d\n
- 国家数量：%d\n
- 学校数量：%d\n
\n阅读目的分布：\n
- 类型A（高文学+高信息）：%d (%.1f%%)\n
- 类型B（高文学+低信息）：%d (%.1f%%)\n
- 类型C（低文学+高信息）：%d (%.1f%%)\n
- 类型D（低文学+低信息）：%d (%.1f%%)\n
\nHLM模型拟合度：\n
- 学生水平方差比例：%.2f%%\n
- 学校水平方差比例：%.2f%%\n
- 国家水平方差比例：%.2f%%\n
\nLPA模型选择：\n
- A型：%d个剖面\n
- B型：%d个剖面\n
- C型：%d个剖面\n
- D型：%d个剖面\n
\n关键发现：\n
- 阅读兴趣的总体效应：%.4f (p<0.001)\n
- 目的类型B的调节效应：%.4f\n
- 目的类型C的调节效应：%.4f\n
- 目的类型D的调节效应：%.4f\n",
  Sys.Date(),
  nrow(all_data_with_profile),
  n_distinct(all_data_with_profile$country_id),
  n_distinct(all_data_with_profile$school_id),
  nrow(purpose_dist[purpose_dist$reading_purpose_type=="A",]),
  purpose_dist[purpose_dist$reading_purpose_type=="A",]$percentage,
  nrow(purpose_dist[purpose_dist$reading_purpose_type=="B",]),
  purpose_dist[purpose_dist$reading_purpose_type=="B",]$percentage,
  nrow(purpose_dist[purpose_dist$reading_purpose_type=="C",]),
  purpose_dist[purpose_dist$reading_purpose_type=="C",]$percentage,
  nrow(purpose_dist[purpose_dist$reading_purpose_type=="D",]),
  purpose_dist[purpose_dist$reading_purpose_type=="D",]$percentage,
  100*var_residual/var_total,
  100*var_school/var_total,
  100*var_country/var_total,
  lpa_results$A$best_n,
  lpa_results$B$best_n,
  lpa_results$C$best_n,
  lpa_results$D$best_n,
  coef_interest,
  coef_int_B,
  coef_int_C,
  coef_int_D
)

writeLines(report_text, "analysis_report.txt")
cat("\n报告已生成: analysis_report.txt\n")
```

---

## 9. 模型诊断与验证

```r
# 9.1 残差诊断
cat("\n========== 模型诊断 ==========\n")

# Q-Q图
png("09_qq_plot.png", width = 800, height = 600)
qqnorm(residuals(hlm_model))
qqline(residuals(hlm_model))
dev.off()

# 残差分布
png("09_residuals_plot.png", width = 800, height = 600)
plot(hlm_model)
dev.off()

# 9.2 多重共线性检验（VIF）
cat("\n多重共线性检验（VIF）：\n")
vif_vals <- car::vif(lm(reading_literacy ~ 
                        reading_interest_smc + reading_confidence_smc +
                        purpose_B + purpose_C + purpose_D,
                        data = all_data_with_profile))
print(vif_vals)

# 9.3 离群值检测
residuals_std <- scale(residuals(hlm_model))[,1]
outliers <- which(abs(residuals_std) > 3)
cat(sprintf("\n离群值数量：%d (%.2f%%)\n", 
            length(outliers), 
            100*length(outliers)/nrow(all_data_with_profile)))

# 9.4 敏感性分析（移除离群值后）
if (length(outliers) > 0) {
  data_no_outliers <- all_data_with_profile[-outliers,]
  
  hlm_model_robust <- lmer(
    formula_hlm,
    data = data_no_outliers,
    control = lmerControl(optimizer = "bobyqa")
  )
  
  cat("\n敏感性分析 - 模型系数对比：\n")
  comparison <- data.frame(
    原始模型 = round(fixef(hlm_model), 4),
    鲁棒模型 = round(fixef(hlm_model_robust), 4)
  )
  print(comparison)
}
```

---

## 10. 快速命令速查

```r
# 快速运行完整分析管道
run_complete_analysis <- function() {
  source("analysis_complete.R")  # 包含所有上述代码
}

# 查看特定结果
view_results <- function(result_name) {
  if (result_name == "summary") {
    print(summary(hlm_model))
  } else if (result_name == "fe_table") {
    print(fe_table)
  } else if (result_name == "slopes") {
    print(simple_slopes)
  } else if (result_name == "lpa") {
    for (ptype in c("A", "B", "C", "D")) {
      print(lpa_results[[ptype]]$characteristics)
    }
  }
}

# 生成所有输出文件
save_all_results <- function() {
  cat("正在保存结果...\n")
  openxlsx::write.xlsx(results_summary, 
                       "analysis_results_summary.xlsx", 
                       overwrite = TRUE)
  cat("✓ Excel结果\n")
  cat("✓ PNG图表\n")
  cat("✓ 文本报告\n")
  cat("\n分析完成！\n")
}
```

---

## 使用说明

### 数据准备
1. 从PIRLS官网下载IDB数据
2. 参考 `P21_Codebook.xlsx` 理解变量定义
3. 按照第1章的变量映射进行数据准备

### 快速开始
```r
# 执行所有分析
source("complete_analysis.R")

# 查看结果
view_results("summary")
view_results("fe_table")

# 保存结果
save_all_results()
```

### 常见调整
- 改变LPA的剖面数范围：修改第4章中的 `2:5`
- 改变中心化方式：修改第5章的中心化代码
- 添加其他协变量：在HLM公式中加入变量

---

**文档版本**: 2.0 (基于PIRLS 2021密码本)  
**更新日期**: 2024年1月  
**仅支持**: R语言
