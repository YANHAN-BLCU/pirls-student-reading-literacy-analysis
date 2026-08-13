# PIRLS 2021 潜在剖面分析（LPA）
# 文件: 04_latent_profile_analysis.R
# 说明: 基于newLPA.xlsx数据，以国家为样本单位进行LPA分析
#       - 四个子领域（ASRLIT, ASRINF, ASRRSI, ASRIIE）作为LPA分类变量
#       - ASRREA作为阅读素养成绩变量（结果变量）

# 确保中文正确显示
Sys.setenv(LANG = "zh_CN.UTF-8")

suppressMessages({
  library(tidyverse)
  library(tidyLPA)
  library(mice)
  library(openxlsx)
  library(MplusAutomation)
})

# 确保tidyLPA的函数可用
if (!exists("get_data") || !is.function(get_data)) {
  get_data <- function(x) {
    # 处理不同的tidyLPA对象结构
    if (inherits(x, "tidyLPA")) {
      if ("dff" %in% names(x)) {
        return(x$dff)
      } else if ("model" %in% names(x) && "dff" %in% names(x$model)) {
        return(x$model$dff)
      }
    } else if (is.list(x)) {
      if ("dff" %in% names(x)) {
        return(x$dff)
      } else if ("model" %in% names(x) && is.list(x$model) && "dff" %in% names(x$model)) {
        return(x$model$dff)
      } else if (length(x) > 0 && is.list(x[[1]]) && "dff" %in% names(x[[1]])) {
        return(x[[1]]$dff)
      }
    }
    return(NULL)
  }
}

# HTML实体解码函数
html_unescape <- function(text) {
  if (is.null(text) || is.na(text)) return(text)
  text <- as.character(text)
  # 解码HTML实体（如 &#21335; -> 对应的中文字符）
  html_entities <- c(
    "&#21335;" = "南", "&#22467;" = "埃", "&#25705;" = "摩", "&#32422;" = "约",
    "&#20013;" = "中", "&#22269;" = "国", "&#21488;" = "台", "北" = "北",
    "&#20026;" = "于", "&#22303;" = "土", "&#32819;" = "耳", "&#20854;" = "其",
    "&#21046;" = "韩", "&#22269;" = "国", "&#29790;" = "瑞", "&#20856;" = "典",
    "&#33521;" = "英", "&#22269;" = "国", "&#32654;" = "美", "&#22269;" = "国",
    "&#27850;" = "新", "&#21152;" = "加", "&#22369;" = "坡", "&#22307;" = "俄",
    "&#32599;" = "罗", "&#26031;" = "斯", "&#27865;" = "法", "&#22269;" = "国",
    "&#24503;" = "德", "&#22269;" = "国", "&#24847;" = "意", "&#22823;" = "大",
    "&#21033;" = "利", "&#35199;" = "西", "&#29677;" = "班", "&#29273;" = "牙",
    "&#33655;" = "葡", "&#33691;" = "萄", "&#29273;" = "牙", "&#21253;" = "保",
    "&#21152;" = "利", "&#21033;" = "亚", "&#26725;" = "捷", "&#20811;" = "克",
    "&#33655;" = "斯", "&#32599;" = "洛", "&#20271;" = "伐克", "&#40614;" = "黑",
    "&#23612;" = "山", "&#20811;" = "克", "&#22350;" = "罗", "&#20195;" = "地",
    "&#20135;" = "亚", "&#39134;" = "马", "&#21050;" = "来", "&#35199;" = "西",
    "&#20122;" = "亚", "&#21335;" = "南", "&#38750;" = "非", "&#22622;" = "乌",
    "&#20872;" = "克", "&#21704;" = "哈", "&#33832;" = "萨", "&#20811;" = "克",
    "&#22303;" = "土", "&#32819;" = "库", "&#20811;" = "斯", "&#22374;" = "坦",
    "&#38463;" = "阿", "&#25289;" = "拉", "&#20234;" = "伊", "&#20302;" = "朗",
    "&#25991;" = "文", "&#33655;" = "莱", "&#38463;" = "阿", "&#33988;" = "联",
    "&#21516;" = "合", "&#22612;" = "酋", "&#38271;" = "长", "&#22269;" = "国",
    "&#38024;" = "卡", "&#22612;" = "塔", "&#23572;" = "尔", "&#32511;" = "黎",
    "&#33014;" = "巴", "&#25973;" = "嫩", "&#20122;" = "约", "&#22372;" = "旦",
    "&#24052;" = "巴", "&#26519;" = "勒", "&#26031;" = "斯", "&#22495;" = "坦",
    "&#38463;" = "埃", "&#21450;" = "及", "&#33832;" = "摩", "&#21512;" = "洛哥",
    "&#30340;" = "的", "&#20234;" = "伊", "&#25252;" = "拉", "&#20811;" = "克",
    "&#33832;" = "沙", "&#29305;" = "特", "&#38463;" = "阿", "&#25289;" = "伯",
    "&#20234;" = "以", "#21017;" = "色", "&#21033;" = "列", "&#22303;" = "土",
    "&#20857;" = "耳", "&#20845;" = "其", "&#28595;" = "澳", "&#38376;" = "大",
    "&#21017;" = "利", "&#20122;" = "新", "&#35199;" = "西", "&#20848;" = "兰",
    "&#21152;" = "加", "&#25343;" = "拿", "&#22823;" = "大", "&#32654;" = "美",
    "&#22269;" = "国", "&#22303;" = "墨", "&#35199;" = "哥", "&#24052;" = "巴",
    "&#35199;" = "西", "&#38463;" = "阿", "&#26681;" = "根", "&#22362;" = "廷",
    "&#20008;" = "智", "&#21069;" = "利", "&#21704;" = "哥", "&#20262;" = "伦",
    "&#27604;" = "亚", "&#21028;" = "斯", "&#29575;" = "黎", "&#24052;" = "利",
    "&#32905;" = "墨", "&#35199;" = "非", "&#22320;" = "地", "&#28023;" = "海",
    "&#40065;" = "卡", "#塔尔" = "塔", "&#23572;" = "尔", "&#22320;" = "中",
    "&#22269;" = "国", "&#21512;" = "香", "&#28207;" = "港", "&#29305;" = "特",
    "&#21035;" = "别", "&#34892;" = "行", "&#25919;" = "政", "&#21306;" = "区",
    "&#28450;" = "澳", "&#38376;" = "门"
  )
  
  # 遍历替换
  for (ent in names(html_entities)) {
    text <- gsub(ent, html_entities[ent], text, fixed = TRUE)
  }
  
  # 使用正则表达式替换 &#数字; 格式
  text <- gsub("&#([0-9]+);", "", text)
  
  return(text)
}

# 简化的HTML实体解码函数（处理常见的HTML数字实体）
decode_html_entities <- function(text) {
  if (is.null(text) || length(text) == 0) return(text)
  text <- as.character(text)
  
  # 查找所有 &#数字; 格式的实体
  entities <- regmatches(text, gregexpr("&#[0-9]+;", text))
  
  if (length(entities[[1]]) > 0) {
    for (ent in unique(entities[[1]])) {
      # 提取数字
      num <- as.integer(gsub("&#([0-9]+);", "\\1", ent))
      # 转换为字符
      char <- intToUtf8(num)
      text <- gsub(ent, char, text, fixed = TRUE)
    }
  }
  
  return(text)
}

cat("\n========== 第4步：潜在剖面分析（LPA）==========\n\n")

# ============================================
# 设置项目根目录（绝对路径）
# ============================================

base_dir <- "F:/BLCU/DC24/国际中文"

# ============================================
# 4.1 读取数据
# ============================================

cat("读取数据文件 newLPA.xlsx...\n")

# 读取Excel文件（使用绝对路径）
data_file <- file.path(base_dir, "newLPA.xlsx")
if (!file.exists(data_file)) {
  stop(sprintf("错误：找不到数据文件 %s", data_file))
}

lpa_data <- read.xlsx(data_file, sheet = 1)

cat(sprintf("数据读取成功：%d 行，%d 列\n", nrow(lpa_data), ncol(lpa_data)))
cat(sprintf("列名：%s\n\n", paste(names(lpa_data), collapse = ", ")))

# ============================================
# 4.2 检查必需变量
# ============================================

cat("检查必需变量...\n")

# 检查IDCNTRY列
if (!"IDCNTRY" %in% names(lpa_data)) {
  # 如果第一列不是IDCNTRY，假设第一列是IDCNTRY
  if (ncol(lpa_data) > 0) {
    names(lpa_data)[1] <- "IDCNTRY"
    cat("将第一列重命名为IDCNTRY\n")
  } else {
    stop("错误：数据文件为空或格式不正确")
  }
}

# 解码IDCNTRY列中的HTML实体
if (any(grepl("&#", lpa_data$IDCNTRY[1]))) {
  cat("检测到HTML实体编码，进行解码...\n")
  lpa_data$IDCNTRY <- sapply(lpa_data$IDCNTRY, decode_html_entities)
}

# 检查合理值变量
pv_vars <- list(
  REA = paste0("ASRREA", sprintf("%02d", 1:5)),
  LIT = paste0("ASRLIT", sprintf("%02d", 1:5)),
  INF = paste0("ASRINF", sprintf("%02d", 1:5)),
  RSI = paste0("ASRRSI", sprintf("%02d", 1:5)),
  IIE = paste0("ASRIIE", sprintf("%02d", 1:5))
)

# 检查每个变量组是否存在
available_vars <- list()
for (var_type in names(pv_vars)) {
  vars <- pv_vars[[var_type]]
  available <- vars[vars %in% names(lpa_data)]
  if (length(available) > 0) {
    available_vars[[var_type]] <- available
    cat(sprintf("  %s: 找到 %d/%d 个变量\n", var_type, length(available), length(vars)))
  } else {
    cat(sprintf("  %s: 未找到变量\n", var_type))
  }
}

# 检查必需的变量
if (length(available_vars$LIT) == 0 || length(available_vars$INF) == 0 || 
    length(available_vars$RSI) == 0 || length(available_vars$IIE) == 0) {
  stop("错误：缺少必需的四个子领域变量（ASRLIT, ASRINF, ASRRSI, ASRIIE）")
}

if (length(available_vars$REA) == 0) {
  stop("错误：缺少整体阅读素养变量（ASRREA）")
}

cat("\n")

# ============================================
# 4.3 数据预处理
# ============================================

cat("数据预处理...\n")

# 计算每个子领域的均值（5个合理值的均值）
lpa_data <- lpa_data %>%
  mutate(
    # 四个子领域得分（LPA分类变量）
    LIT_SCORE = if(length(available_vars$LIT) > 0) {
      rowMeans(select(., all_of(available_vars$LIT)), na.rm = TRUE)
    } else NA,
    INF_SCORE = if(length(available_vars$INF) > 0) {
      rowMeans(select(., all_of(available_vars$INF)), na.rm = TRUE)
    } else NA,
    RSI_SCORE = if(length(available_vars$RSI) > 0) {
      rowMeans(select(., all_of(available_vars$RSI)), na.rm = TRUE)
    } else NA,
    IIE_SCORE = if(length(available_vars$IIE) > 0) {
      rowMeans(select(., all_of(available_vars$IIE)), na.rm = TRUE)
    } else NA,
    # 整体阅读素养得分（结果变量）
    REA_SCORE = if(length(available_vars$REA) > 0) {
      rowMeans(select(., all_of(available_vars$REA)), na.rm = TRUE)
    } else NA
  )

# 筛选有效数据：四个子领域和整体阅读素养都不为NA
lpa_data <- lpa_data %>%
  filter(
    !is.na(LIT_SCORE),
    !is.na(INF_SCORE),
    !is.na(RSI_SCORE),
    !is.na(IIE_SCORE),
    !is.na(REA_SCORE)
  )

cat(sprintf("有效数据：%d 行\n", nrow(lpa_data)))

# 检查国家数
country_count <- length(unique(lpa_data$IDCNTRY))
cat(sprintf("国家数：%d\n", country_count))

if (country_count < 5) {
  warning(sprintf("警告：国家数过少（%d < 5），LPA分析可能不稳定", country_count))
}

cat("\n")

# ============================================
# 4.4 按国家汇总数据（以国家为样本单位）
# ============================================

cat("按国家汇总数据（以国家为样本单位）...\n")

# 按国家计算均值（每个国家作为一个样本）
country_level_data <- lpa_data %>%
  group_by(IDCNTRY) %>%
  summarise(
    LIT_SCORE = mean(LIT_SCORE, na.rm = TRUE),
    INF_SCORE = mean(INF_SCORE, na.rm = TRUE),
    RSI_SCORE = mean(RSI_SCORE, na.rm = TRUE),
    IIE_SCORE = mean(IIE_SCORE, na.rm = TRUE),
    REA_SCORE = mean(REA_SCORE, na.rm = TRUE),
    n_rows = n(),  # 每个国家的原始行数
    .groups = 'drop'
  )

cat(sprintf("国家样本数：%d\n", nrow(country_level_data)))
cat(sprintf("每个国家的平均行数：%.1f\n", mean(country_level_data$n_rows)))
cat("\n")

# 提取用于LPA的四个子领域得分
lpa_vars <- c("LIT_SCORE", "INF_SCORE", "RSI_SCORE", "IIE_SCORE")
lpa_data_country <- country_level_data %>%
  select(all_of(lpa_vars))

# ============================================
# 4.5 多重插补（如果需要）
# ============================================

cat("检查缺失值...\n")
missing_count <- sum(is.na(lpa_data_country))
cat(sprintf("缺失值数量：%d\n", missing_count))

if (missing_count > 0) {
  cat("进行多重插补...\n")
  imputed <- mice(lpa_data_country, m = 5, maxit = 10, seed = 123, printFlag = FALSE)
  lpa_data_country <- complete(imputed, action = 1)
  cat("插补完成\n")
} else {
  cat("无缺失值，跳过插补\n")
}
cat("\n")

# ============================================
# 4.6 LPA分析（1-5个剖面）- 使用Mplus进行准确计算
# ============================================

cat("╔════════════════════════════════════════╗\n")
cat("║  开始LPA分析（1-5个剖面）- 使用Mplus  ║\n")
cat("╚════════════════════════════════════════╝\n\n")

# 检查Mplus是否可用
mplus_available <- FALSE
mplus_command <- "mplus"
if (nchar(Sys.which("mplus")) > 0 || nchar(Sys.which("mplus.exe")) > 0) {
  mplus_available <- TRUE
  if (nchar(Sys.which("mplus.exe")) > 0) {
    mplus_command <- "mplus.exe"
  }
  cat(sprintf("Mplus已找到：%s\n", mplus_command))
} else {
  cat("警告：未找到Mplus，将尝试使用tidyLPA作为备选方案\n")
  cat("提示：请安装Mplus并确保其在系统PATH中\n")
}

# 创建Mplus临时目录
mplus_temp_dir <- file.path(base_dir, "analysis_code", "mplus_temp")
if (!dir.exists(mplus_temp_dir)) {
  dir.create(mplus_temp_dir, recursive = TRUE)
}

all_models <- list()
model_comparison <- data.frame()

# 拟合1-5个剖面的模型
for (n_prof in 1:5) {
  cat(sprintf("拟合 %d 个剖面...", n_prof))
  
  tryCatch({
    if (n_prof == 1) {
      # 单组模型：直接计算统计量
      n_obs <- nrow(lpa_data_country)
      n_vars <- ncol(lpa_data_country)
      
      # 计算基本统计量
      log_lik <- sum(apply(lpa_data_country, 1, function(x) {
        -0.5 * sum((x - mean(x, na.rm = TRUE))^2, na.rm = TRUE)
      }), na.rm = TRUE)
      
      n_params <- n_vars * 2  # 均值和方差参数
      
      model_fit <- list(
        model = "Single Group",
        n_profiles = 1,
        AIC = -2 * log_lik + 2 * n_params,
        BIC = -2 * log_lik + log(n_obs) * n_params,
        aBIC = -2 * log_lik + log((n_obs + 2) / 24) * n_params,
        Entropy = NA,  # 单组模型没有Entropy
        LMRtp = NA,
        BLRtp = NA
      )
      
      all_models[[n_prof]] <- model_fit
      cat(" ✓ (单组模型)\n")
      
    } else {
      # 多剖面模型：优先使用Mplus
      if (mplus_available) {
        # 使用Mplus进行LPA分析
        cat(" (Mplus)")
        
        # 准备Mplus数据文件（使用空格分隔，无列名，缺失值用-999）
        mplus_data_file <- file.path(mplus_temp_dir, sprintf("lpa_data_%d_%d.dat", nrow(lpa_data_country), n_prof))
        # 将NA替换为-999
        lpa_data_for_mplus <- lpa_data_country
        lpa_data_for_mplus[is.na(lpa_data_for_mplus)] <- -999
        write.table(lpa_data_for_mplus, file = mplus_data_file, 
                   row.names = FALSE, col.names = FALSE, sep = " ", quote = FALSE)
        
        # 构建Mplus语法
        var_names <- names(lpa_data_country)
        n_vars <- length(var_names)
        
        # 直接生成Mplus输入文件（避免mplusObject的自动处理导致重复）
        model_name <- sprintf("lpa_model_%d_%d", nrow(lpa_data_country), n_prof)
        mplus_inp_file <- file.path(mplus_temp_dir, paste0(model_name, ".inp"))
        
        # 构建完整的Mplus语法（注意：使用%%转义百分号）
        mplus_syntax <- paste0("TITLE: LPA Model with ", n_prof, " Profiles

DATA:
FILE = ", basename(mplus_data_file), ";

VARIABLE:
NAMES = ", paste(var_names, collapse = " "), ";
USEVARIABLES = ", paste(var_names, collapse = " "), ";
CLASSES = c(", n_prof, ");
MISSING = .;

ANALYSIS:
TYPE = MIXTURE;
ESTIMATOR = MLR;
STARTS = 200 50;
LRTSTARTS = 0 0 0 0;
LRTBOOTSTRAP = 2000;
PROCESSORS = 4;

MODEL:
%OVERALL%
[", paste(var_names, collapse = " "), "];
", paste(sprintf("%s (v);", var_names), collapse = "\n"), "
", paste(sprintf("%%C#%d%%\n[%s];", 1:n_prof, paste(var_names, collapse = " ")), collapse = "\n"), "

OUTPUT:
TECH1 TECH11 TECH14;

SAVEDATA:
FILE = lpa_results_", nrow(lpa_data_country), "_", n_prof, ".dat;
SAVE = CPROBABILITIES;
")
        
        # 写入.inp文件
        writeLines(mplus_syntax, mplus_inp_file)
        
        # 运行Mplus模型
        old_wd <- getwd()
        setwd(mplus_temp_dir)
        
        mplus_result <- tryCatch({
          # 直接调用Mplus
          system(sprintf('"%s" %s', mplus_command, basename(mplus_inp_file)), 
                 ignore.stdout = TRUE, ignore.stderr = TRUE)
          
          # 读取输出文件
          out_file <- file.path(mplus_temp_dir, paste0(model_name, ".out"))
          if (!file.exists(out_file)) {
            cat(" Mplus输出文件不存在\n")
            return(NULL)
          }
          
          out_content <- readLines(out_file, warn = FALSE)
          
          # 检查是否有错误
          if (any(grepl("\\*\\*\\* ERROR", out_content, ignore.case = TRUE))) {
            error_lines <- grep("\\*\\*\\* ERROR", out_content, ignore.case = TRUE, value = TRUE)
            # 只显示前3个错误
            error_msg <- paste(error_lines[seq_len(min(3, length(error_lines)))], collapse = "; ")
            cat(sprintf(" Mplus错误: %s\n", substr(error_msg, 1, 100)))  # 限制错误信息长度
            return(NULL)
          }
          
          # 检查是否成功完成
          if (!any(grepl("THE MODEL ESTIMATION TERMINATED NORMALLY", out_content))) {
            # 检查是否有警告
            warnings <- grep("WARNING", out_content, ignore.case = TRUE, value = TRUE)
            if (length(warnings) > 0) {
              cat(sprintf(" Mplus警告: %s\n", substr(warnings[1], 1, 80)))
            } else {
              cat(" Mplus未正常完成\n")
            }
            return(NULL)
          }
          
          # 直接解析Mplus输出文件提取结果
          tryCatch({
            # 先尝试使用readModels
            result <- readModels(out_file, what = "all")
            
            # 如果readModels返回的对象结构不对，直接解析.out文件
            if (is.null(result) || 
                (inherits(result, "mplus.model") && is.null(result$results)) ||
                (is.list(result) && !"results" %in% names(result))) {
              
              # 直接解析.out文件
              out_lines <- readLines(out_file, warn = FALSE)
              
              # 提取AIC、BIC、aBIC（从MODEL FIT INFORMATION部分）
              fit_section_start <- grep("MODEL FIT INFORMATION", out_lines)
              if (length(fit_section_start) > 0) {
                fit_section <- out_lines[fit_section_start[1]:min(fit_section_start[1] + 20, length(out_lines))]
                aic_line <- grep("Akaike \\(AIC\\)", fit_section, value = TRUE)
                bic_line <- grep("Bayesian \\(BIC\\)", fit_section, value = TRUE)
                abic_line <- grep("Sample-Size Adjusted BIC", fit_section, value = TRUE)
              } else {
                aic_line <- character(0)
                bic_line <- character(0)
                abic_line <- character(0)
              }
              
              # 提取Entropy（从TECH14输出，格式：Entropy 0.997）
              # Entropy可能在TECH14部分，也可能在MODEL FIT INFORMATION之后
              entropy_line <- character(0)
              
              # 方法1：从TECH14部分提取
              tech14_start <- grep("TECHNICAL 14 OUTPUT", out_lines)
              if (length(tech14_start) > 0) {
                tech14_section <- out_lines[tech14_start[1]:min(tech14_start[1] + 50, length(out_lines))]
                entropy_line <- grep("^\\s*Entropy\\s+[0-9]", tech14_section, value = TRUE)
              }
              
              # 方法2：如果TECH14中没有，在整个文件中搜索
              if (length(entropy_line) == 0) {
                entropy_line <- grep("^\\s*Entropy\\s+[0-9]+\\.", out_lines, value = TRUE)
              }
              
              # 方法3：搜索包含Entropy和数字的行
              if (length(entropy_line) == 0) {
                entropy_candidates <- grep("Entropy", out_lines, value = TRUE, ignore.case = TRUE)
                entropy_line <- entropy_candidates[grep("[0-9]+\\.[0-9]+", entropy_candidates)]
              }
              
              # 提取LMR和BLRT p值（从TECH11输出）
              tech11_start <- grep("TECHNICAL 11 OUTPUT", out_lines)
              tech11_end <- grep("TECHNICAL 14 OUTPUT|TECHNICAL 1 OUTPUT", out_lines)
              if (length(tech11_start) > 0 && length(tech11_end) > 0) {
                tech11_lines <- out_lines[tech11_start[1]:min(tech11_end[tech11_end > tech11_start[1]][1], length(out_lines))]
              } else {
                tech11_lines <- character(0)
              }
              
              # 构建结果对象
              result <- list(
                results = list(
                  summaries = list(
                    AIC = if (length(aic_line) > 0) {
                      as.numeric(gsub(".*?([0-9]+\\.[0-9]+).*", "\\1", aic_line[1]))
                    } else NA,
                    BIC = if (length(bic_line) > 0) {
                      as.numeric(gsub(".*?([0-9]+\\.[0-9]+).*", "\\1", bic_line[1]))
                    } else NA,
                    AICC = if (length(abic_line) > 0) {
                      as.numeric(gsub(".*?([0-9]+\\.[0-9]+).*", "\\1", abic_line[1]))
                    } else NA,
                    Entropy = if (length(entropy_line) > 0) {
                      # 提取Entropy值（格式：Entropy 0.997）
                      # 尝试多种正则表达式模式
                      entropy_val <- NA
                      
                      # 模式1：Entropy后面直接跟数字
                      match1 <- regmatches(entropy_line[1], regexpr("Entropy\\s+([0-9]+\\.[0-9]+)", entropy_line[1], ignore.case = TRUE))
                      if (length(match1) > 0) {
                        entropy_val <- as.numeric(gsub("Entropy\\s+", "", match1[1], ignore.case = TRUE))
                      }
                      
                      # 模式2：提取行中的第一个数字
                      if (is.na(entropy_val)) {
                        match2 <- regmatches(entropy_line[1], regexpr("[0-9]+\\.[0-9]+", entropy_line[1]))
                        if (length(match2) > 0) {
                          entropy_val <- as.numeric(match2[1])
                        }
                      }
                      
                      # 验证Entropy值在合理范围内（0-1）
                      if (!is.na(entropy_val) && entropy_val >= 0 && entropy_val <= 1) {
                        entropy_val
                      } else {
                        NA
                      }
                    } else NA
                  ),
                  tech11 = NULL,  # 稍后解析
                  savedata = NULL  # 稍后从.dat文件读取
                )
              )
              
              # 解析TECH11获取LMR和BLRT
              tech11_start_idx <- grep("TECHNICAL 11 OUTPUT", out_lines)
              lmr_pval <- NA
              blrt_pval <- NA
              
              if (length(tech11_start_idx) > 0) {
                # 查找TECH11部分
                tech11_end_idx <- grep("TECHNICAL 14 OUTPUT|TECHNICAL 1 OUTPUT", out_lines)
                tech11_end <- if (length(tech11_end_idx) > 0 && tech11_end_idx[1] > tech11_start_idx[1]) {
                  tech11_end_idx[1]
                } else {
                  min(tech11_start_idx[1] + 150, length(out_lines))
                }
                tech11_section <- out_lines[tech11_start_idx[1]:tech11_end]
                
                # 查找LMR p值（格式：P-Value 0.0397）
                lmr_header <- grep("LO-MENDELL-RUBIN|LMR", tech11_section, ignore.case = TRUE)
                if (length(lmr_header) > 0) {
                  # 在LMR标题后查找P-Value行
                  lmr_section <- tech11_section[lmr_header[1]:min(lmr_header[1] + 10, length(tech11_section))]
                  pval_line <- grep("P-Value", lmr_section, value = TRUE, ignore.case = TRUE)
                  if (length(pval_line) > 0) {
                    lmr_pval <- as.numeric(gsub(".*?P-Value\\s+([0-9]+\\.[0-9]+).*", "\\1", pval_line[1]))
                    if (is.na(lmr_pval)) {
                      # 尝试其他格式
                      lmr_pval <- as.numeric(gsub(".*?([0-9]+\\.[0-9]+).*", "\\1", pval_line[1]))
                    }
                  }
                }
                
                # 查找BLRT p值（格式：Approximate P-Value 0.0000）
                # BLRT在"PARAMETRIC BOOTSTRAPPED LIKELIHOOD RATIO TEST"部分
                blrt_header <- grep("PARAMETRIC BOOTSTRAPPED|BOOTSTRAP.*LIKELIHOOD|BLRT", tech11_section, ignore.case = TRUE)
                if (length(blrt_header) > 0) {
                  # 扩大搜索范围，确保找到P-Value行
                  blrt_section <- tech11_section[blrt_header[1]:min(blrt_header[1] + 15, length(tech11_section))]
                  
                  # 查找包含P-Value的行（优先查找"Approximate P-Value"）
                  pval_lines <- grep("Approximate P-Value|P-Value", blrt_section, value = TRUE, ignore.case = TRUE)
                  
                  if (length(pval_lines) > 0) {
                    # 提取第一个P-Value行的数值
                    pval_line <- pval_lines[1]
                    
                    # 检查Successful Bootstrap Draws数量
                    bootstrap_draws_line <- grep("Successful Bootstrap Draws", blrt_section, value = TRUE, ignore.case = TRUE)
                    bootstrap_draws <- NA
                    if (length(bootstrap_draws_line) > 0) {
                      draws_match <- regmatches(bootstrap_draws_line[1], regexpr("[0-9]+", bootstrap_draws_line[1]))
                      if (length(draws_match) > 0) {
                        bootstrap_draws <- as.numeric(draws_match[1])
                      }
                    }
                    
                    # 尝试多种提取方式
                    # 方式1：P-Value后面跟数字（使用更精确的正则）
                    match1 <- regmatches(pval_line, regexpr("P-Value\\s+([0-9]+\\.[0-9]+)", pval_line, ignore.case = TRUE))
                    if (length(match1) > 0) {
                      blrt_pval <- as.numeric(gsub(".*?([0-9]+\\.[0-9]+).*", "\\1", match1[1]))
                    } else {
                      # 方式2：提取行中的所有数字，取最后一个（通常是p值）
                      numbers <- regmatches(pval_line, gregexpr("[0-9]+\\.[0-9]+", pval_line))[[1]]
                      if (length(numbers) > 0) {
                        # 取最后一个数字（通常是p值）
                        blrt_pval <- as.numeric(numbers[length(numbers)])
                      } else {
                        blrt_pval <- NA
                      }
                    }
                    
                    # 验证p值在合理范围内（0-1）
                    if (!is.na(blrt_pval) && (blrt_pval < 0 || blrt_pval > 1)) {
                      blrt_pval <- NA
                    }
                    
                    # 检查BLRT是否有效运行
                    # 如果bootstrap draws太少（< 100），BLRT可能不可靠
                    if (!is.na(blrt_pval) && blrt_pval == 0 && !is.na(bootstrap_draws)) {
                      if (bootstrap_draws < 100) {
                        cat(sprintf(" 警告：模型%d的BLRT bootstrap draws过少（%d < 100），p值可能不可靠\n", 
                                   n_prof, bootstrap_draws))
                        # 如果bootstrap draws太少，0.0000可能不准确，但保留原值
                        # 注意：这可能是由于Mplus默认的bootstrap设置导致的
                      }
                      # 如果bootstrap draws >= 100，0.0000是有效的（p值非常小）
                    } else if (!is.na(blrt_pval) && blrt_pval == 0 && is.na(bootstrap_draws)) {
                      # 如果无法获取bootstrap draws信息，但p值是0，可能是真的（p值非常小）
                      # 或者可能是提取错误，但保留原值
                    }
                  } else {
                    blrt_pval <- NA
                  }
                } else {
                  blrt_pval <- NA
                }
                
                result$results$tech11 <- data.frame(
                  LMR_PValue = lmr_pval,
                  BLRT_PValue = blrt_pval
                )
              }
              
              # 读取SAVEDATA文件获取剖面分配
              savedata_file <- file.path(mplus_temp_dir, sprintf("lpa_results_%d_%d.dat", nrow(lpa_data_country), n_prof))
              if (file.exists(savedata_file)) {
                savedata <- tryCatch({
                  read.table(savedata_file, header = FALSE, stringsAsFactors = FALSE)
                }, error = function(e) NULL)
                
                if (!is.null(savedata)) {
                  # 根据SAVEDATA格式解析（最后几列是CPROB，最后一列是C）
                  n_cols <- ncol(savedata)
                  if (n_cols >= n_prof + 1) {
                    # 最后一列是类别分配
                    result$results$savedata <- data.frame(C = savedata[, n_cols])
                  }
                }
              }
            }
            
            result
          }, error = function(e) {
            cat(sprintf(" Mplus结果读取错误: %s\n", conditionMessage(e)))
            NULL
          })
  }, error = function(e) {
          cat(sprintf(" Mplus运行错误: %s\n", conditionMessage(e)))
          NULL
        })
        
        setwd(old_wd)
        
        # 从Mplus结果中提取拟合指标
        if (!is.null(mplus_result)) {
          # 处理不同的结果对象结构
          if (inherits(mplus_result, "mplus.model") && !is.null(mplus_result$results)) {
            results <- mplus_result$results
          } else if (is.list(mplus_result) && "results" %in% names(mplus_result)) {
            results <- mplus_result$results
          } else if (is.list(mplus_result) && "summaries" %in% names(mplus_result)) {
            # 如果results字段不存在，但summaries存在，构建results对象
            results <- mplus_result
          } else {
            results <- NULL
          }
          
          if (!is.null(results)) {
          
          # 提取基本信息（安全提取，处理NA值）
          summaries <- results$summaries
          aic <- if (!is.null(summaries) && "AIC" %in% names(summaries) && 
                     !is.na(summaries$AIC) && !is.infinite(summaries$AIC)) summaries$AIC else NA
          bic <- if (!is.null(summaries) && "BIC" %in% names(summaries) && 
                     !is.na(summaries$BIC) && !is.infinite(summaries$BIC)) summaries$BIC else NA
          aic_corrected <- if (!is.null(summaries) && "AICC" %in% names(summaries) && 
                                !is.na(summaries$AICC) && !is.infinite(summaries$AICC)) summaries$AICC else NA
          
          # Entropy：多剖面模型（n_prof > 1）必须有值，单组模型（n_prof == 1）为NA
          # Entropy衡量分类清晰度，多剖面模型必须计算
          entropy <- if (n_prof > 1) {
            entropy_val <- NA
            
            # 方法1：从summaries中提取
            if (!is.null(summaries) && "Entropy" %in% names(summaries)) {
              entropy_val <- summaries$Entropy
            }
            
            # 方法2：如果summaries中没有，尝试从results的其他部分提取
            if ((is.na(entropy_val) || entropy_val < 0 || entropy_val > 1) && 
                !is.null(results$tech14)) {
              # TECH14可能包含Entropy信息
              tech14 <- results$tech14
              if (is.data.frame(tech14) && "Entropy" %in% names(tech14)) {
                entropy_val <- tech14$Entropy[1]
              }
            }
            
            # 方法3：如果仍然没有，尝试从Mplus输出文件中直接解析
            if ((is.na(entropy_val) || entropy_val < 0 || entropy_val > 1)) {
              out_file <- file.path(mplus_temp_dir, paste0(model_name, ".out"))
              if (file.exists(out_file)) {
                out_content <- readLines(out_file, warn = FALSE)
                # 查找Entropy行（格式：Entropy 0.997）
                entropy_lines <- grep("^\\s*Entropy\\s+[0-9]", out_content, value = TRUE)
                if (length(entropy_lines) > 0) {
                  entropy_match <- regmatches(entropy_lines[1], regexpr("[0-9]+\\.[0-9]+", entropy_lines[1]))
                  if (length(entropy_match) > 0) {
                    entropy_val <- as.numeric(entropy_match[1])
                  }
                }
              }
            }
            
            # 验证Entropy值（必须在0-1之间）
            if (!is.na(entropy_val) && entropy_val >= 0 && entropy_val <= 1) {
              entropy_val
            } else {
              # 如果仍然为NA，输出警告（多剖面模型应该有Entropy）
              cat(sprintf(" 警告：模型%d的Entropy无法提取，设为NA（多剖面模型应该有Entropy值）\n", n_prof))
              NA
            }
          } else {
            NA  # 单组模型没有Entropy
          }
          
          # 提取LMR和BLRT p值
          # 注意：LMR和BLRT用于比较k类与k-1类模型，所以：
          # - 模型1（单组）：LMR和BLRT为NA（没有k-1类模型可比较）
          # - 模型2及以上：应该有LMR和BLRT值（用于比较k类与k-1类模型）
          lmr_p <- NA
          blrt_p <- NA
          
          if (n_prof > 1) {
            # 方法1：从tech11中提取
            if (!is.null(results$tech11)) {
              tech11 <- results$tech11
              # LMR p值（尝试多种可能的列名）
              if (is.data.frame(tech11)) {
                # 尝试所有可能的列名
                lmr_cols <- c("pval", "LMR_PValue", "PVAL", "LMR", "lmr_p", "LMR_p")
                for (col in lmr_cols) {
                  if (col %in% names(tech11) && !is.na(tech11[[col]][1])) {
                    val <- tech11[[col]][1]
                    if (is.numeric(val) && val >= 0 && val <= 1) {
                      lmr_p <- val
                      break
                    }
                  }
                }
                
                # BLRT p值（尝试多种可能的列名）
                blrt_cols <- c("BLRT_PValue", "BLRT_PVAL", "BLRT", "blrt_p", "BLRT_p", "Bootstrap_PValue")
                for (col in blrt_cols) {
                  if (col %in% names(tech11) && !is.na(tech11[[col]][1])) {
                    val <- tech11[[col]][1]
                    if (is.numeric(val) && val >= 0 && val <= 1) {
                      blrt_p <- val
                      break
                    }
                  }
                }
              } else if (is.list(tech11)) {
                # 如果是列表结构，尝试提取
                if ("LMR_PValue" %in% names(tech11)) {
                  lmr_p <- tech11$LMR_PValue
                }
                if ("BLRT_PValue" %in% names(tech11)) {
                  blrt_p <- tech11$BLRT_PValue
                }
              }
            }
            
            # 方法2：如果tech11中没有，从Mplus输出文件中直接解析
            if (is.na(lmr_p) || is.na(blrt_p)) {
              out_file <- file.path(mplus_temp_dir, paste0(model_name, ".out"))
              if (file.exists(out_file)) {
                out_content <- readLines(out_file, warn = FALSE)
                
                # 提取LMR p值
                if (is.na(lmr_p)) {
                  lmr_section <- grep("LO-MENDELL-RUBIN|LMR", out_content, ignore.case = TRUE)
                  if (length(lmr_section) > 0) {
                    lmr_lines <- out_content[lmr_section[1]:min(lmr_section[1] + 10, length(out_content))]
                    pval_line <- grep("P-Value", lmr_lines, value = TRUE, ignore.case = TRUE)
                    if (length(pval_line) > 0) {
                      pval_match <- regmatches(pval_line[1], regexpr("[0-9]+\\.[0-9]+", pval_line[1]))
                      if (length(pval_match) > 0) {
                        lmr_p <- as.numeric(pval_match[1])
                      }
                    }
                  }
                }
                
                # 提取BLRT p值
                if (is.na(blrt_p)) {
                  blrt_section <- grep("PARAMETRIC BOOTSTRAPPED|BOOTSTRAP.*LIKELIHOOD", out_content, ignore.case = TRUE)
                  if (length(blrt_section) > 0) {
                    blrt_lines <- out_content[blrt_section[1]:min(blrt_section[1] + 15, length(out_content))]
                    
                    # 检查Successful Bootstrap Draws数量
                    bootstrap_draws_line <- grep("Successful Bootstrap Draws", blrt_lines, value = TRUE, ignore.case = TRUE)
                    bootstrap_draws <- NA
                    if (length(bootstrap_draws_line) > 0) {
                      draws_match <- regmatches(bootstrap_draws_line[1], regexpr("[0-9]+", bootstrap_draws_line[1]))
                      if (length(draws_match) > 0) {
                        bootstrap_draws <- as.numeric(draws_match[1])
                      }
                    }
                    
                    pval_line <- grep("Approximate P-Value|P-Value", blrt_lines, value = TRUE, ignore.case = TRUE)
                    if (length(pval_line) > 0) {
                      # 提取最后一个数字（通常是p值）
                      numbers <- regmatches(pval_line[1], gregexpr("[0-9]+\\.[0-9]+", pval_line[1]))[[1]]
                      if (length(numbers) > 0) {
                        blrt_p <- as.numeric(numbers[length(numbers)])
                        # 验证p值范围
                        if (blrt_p < 0 || blrt_p > 1) {
                          blrt_p <- NA
                        }
                        
                        # 如果p值是0.0000且bootstrap draws太少，输出警告
                        if (!is.na(blrt_p) && blrt_p == 0 && !is.na(bootstrap_draws) && bootstrap_draws < 100) {
                          cat(sprintf(" 警告：模型%d的BLRT bootstrap draws过少（%d < 100），p值0.0000可能不可靠\n", 
                                     n_prof, bootstrap_draws))
                        }
                      }
                    }
                  }
                }
              }
            }
            
            # 验证：多剖面模型（n_prof > 1）应该有LMR和BLRT值
            if (is.na(lmr_p)) {
              cat(sprintf(" 警告：模型%d的LMRtp无法提取（多剖面模型应该有LMR值）\n", n_prof))
            }
            if (is.na(blrt_p)) {
              cat(sprintf(" 警告：模型%d的BLRtp无法提取（多剖面模型应该有BLRT值）\n", n_prof))
            }
          }
          
          # 计算aBIC（如果未提供）
          if (is.na(aic_corrected) || is.infinite(aic_corrected)) {
            if (!is.na(aic) && !is.na(bic) && !is.infinite(aic) && !is.infinite(bic)) {
              n_obs <- nrow(lpa_data_country)
              n_params <- n_prof * n_vars * 2
              aic_corrected <- aic + (log((n_obs + 2) / 24) - 2) * n_params / 2
            }
          }
          
          # 提取剖面分配
          profile_assignment <- NULL
          if (!is.null(results$savedata) && is.data.frame(results$savedata)) {
            if ("C" %in% names(results$savedata)) {
              profile_assignment <- results$savedata$C
            } else if ("CPROB" %in% names(results$savedata)) {
              # 如果没有C列，尝试从CPROB中提取
              profile_assignment <- apply(results$savedata[, grep("CPROB", names(results$savedata))], 
                                         1, which.max)
            }
          }
          
          # 计算类别数量（各剖面的国家数，格式：数量1,数量2,数量3）
          category_counts <- ""
          if (!is.null(profile_assignment) && length(profile_assignment) > 0) {
            count_table <- table(profile_assignment)
            # 按剖面编号排序（1, 2, 3...）
            sorted_profiles <- sort(as.numeric(names(count_table)))
            category_counts <- paste(count_table[as.character(sorted_profiles)], collapse = ",")
          }
          
          model_fit <- list(
            model = mplus_result,
        n_profiles = n_prof,
            AIC = aic,
            BIC = bic,
            aBIC = aic_corrected,
            Entropy = entropy,
            LMRtp = lmr_p,
            BLRtp = blrt_p,
            profile_assignment = profile_assignment,
            category_counts = category_counts
          )
          
          all_models[[n_prof]] <- model_fit
          cat(" ✓\n")
          
          # 输出该模型的剖面分类详情
          if (n_prof > 1 && !is.null(model_fit$profile_assignment)) {
            cat(sprintf("  模型%d的剖面分类详情：\n", n_prof))
            
            # 将剖面分配与国家数据合并
            temp_country_data <- country_level_data[, c("IDCNTRY", "LIT_SCORE", "INF_SCORE", "RSI_SCORE", "IIE_SCORE", "REA_SCORE")]
            temp_country_data$profile <- model_fit$profile_assignment[seq_len(min(nrow(temp_country_data), length(model_fit$profile_assignment)))]
            
            # 按剖面分组输出
            profile_detail <- temp_country_data %>%
              group_by(profile) %>%
              summarise(
                countries = paste(sort(as.character(decode_html_entities(IDCNTRY))), collapse = "、"),
                n = n(),
                .groups = 'drop'
              )
            
            for (j in seq_len(nrow(profile_detail))) {
              cat(sprintf("    剖面%d（%d个国家）：%s\n", 
                          profile_detail$profile[j], 
                          profile_detail$n[j],
                          profile_detail$countries[j]))
            }
            cat("\n")
          }
          
          } else {
            # results为空，使用tidyLPA作为备选
            cat(" (Mplus结果解析失败，使用tidyLPA)")
            # 继续执行tidyLPA代码
          }
          
        } else {
          # Mplus运行失败，使用tidyLPA作为备选
          cat(" (Mplus失败，使用tidyLPA)")
          lpa_result <- estimate_profiles(
            lpa_data_country,
            n_profiles = n_prof,
            variances = "equal",
            covariances = "zero",
            package = "mclust"
          )
          
          fit_indices <- get_fit(lpa_result)
          
          # 提取剖面分配（tidyLPA返回的是列表）
          profile_assignment_tidy <- NULL
          tryCatch({
            # tidyLPA返回的是列表，需要提取第一个模型的结果
            if (is.list(lpa_result) && length(lpa_result) > 0) {
              best_tidy_model <- lpa_result[[1]]
              if (!is.null(best_tidy_model)) {
                # 尝试多种方法提取剖面分配
                profile_data <- NULL
                
                # 方法1：使用get_data函数（如果可用）
                if (is.function(get_data)) {
                  tryCatch({
                    profile_data <- get_data(best_tidy_model)
                  }, error = function(e) {
                    # get_data失败，继续尝试其他方法
                  })
                }
                
                # 方法2：直接从对象结构中提取
                if (is.null(profile_data)) {
                  if (is.list(best_tidy_model)) {
                    if ("dff" %in% names(best_tidy_model)) {
                      profile_data <- best_tidy_model$dff
                    } else if ("model" %in% names(best_tidy_model) && is.list(best_tidy_model$model)) {
                      if ("dff" %in% names(best_tidy_model$model)) {
                        profile_data <- best_tidy_model$model$dff
                      }
                    }
                  } else if (is.data.frame(best_tidy_model)) {
                    profile_data <- best_tidy_model
                  }
                }
                
                # 从profile_data中提取Class
                if (!is.null(profile_data) && is.data.frame(profile_data)) {
                  if ("Class" %in% names(profile_data)) {
                    profile_assignment_tidy <- profile_data$Class
                  } else if (any(grepl("CPROB", names(profile_data)))) {
                    cprob_cols <- grep("CPROB", names(profile_data))
                    if (length(cprob_cols) > 0) {
                      profile_assignment_tidy <- apply(profile_data[, cprob_cols, drop = FALSE], 1, which.max)
                    }
                  }
                }
              }
            }
          }, error = function(e) {
            # 如果提取失败，记录错误但继续
            cat(sprintf(" 提取剖面分配失败: %s\n", conditionMessage(e)))
          })
          
          # 计算类别数量（各剖面的国家数，格式：数量1,数量2,数量3）
          category_counts_tidy <- ""
          if (!is.null(profile_assignment_tidy) && length(profile_assignment_tidy) > 0) {
            count_table <- table(profile_assignment_tidy)
            # 按剖面编号排序（1, 2, 3...）
            sorted_profiles <- sort(as.numeric(names(count_table)))
            category_counts_tidy <- paste(count_table[as.character(sorted_profiles)], collapse = ",")
          }
          
          model_fit <- list(
            model = lpa_result,
            n_profiles = n_prof,
            AIC = fit_indices$AIC[1],
            BIC = fit_indices$BIC[1],
            aBIC = fit_indices$AIC[1] + (log(nrow(lpa_data_country)) - 2) * 
                   (fit_indices$BIC[1] - fit_indices$AIC[1]) / (2 * log(nrow(lpa_data_country))),
            Entropy = fit_indices$Entropy[1],
            LMRtp = NA,
            BLRtp = NA,
            profile_assignment = profile_assignment_tidy,
            category_counts = category_counts_tidy
          )
          
          if (is.na(model_fit$aBIC) || is.infinite(model_fit$aBIC)) {
            n_obs <- nrow(lpa_data_country)
            n_params <- n_prof * ncol(lpa_data_country) * 2
            model_fit$aBIC <- model_fit$AIC + (log((n_obs + 2) / 24) - 2) * n_params / 2
          }
          
          all_models[[n_prof]] <- model_fit
          cat(" ✓ (tidyLPA备选)\n")
          
          # 输出该模型的剖面分类详情
          if (n_prof > 1 && !is.null(model_fit$profile_assignment)) {
            cat(sprintf("  模型%d的剖面分类详情：\n", n_prof))
            
            # 将剖面分配与国家数据合并
            temp_country_data <- country_level_data[, c("IDCNTRY", "LIT_SCORE", "INF_SCORE", "RSI_SCORE", "IIE_SCORE", "REA_SCORE")]
            temp_country_data$profile <- model_fit$profile_assignment[seq_len(min(nrow(temp_country_data), length(model_fit$profile_assignment)))]
            
            # 按剖面分组输出
            profile_detail <- temp_country_data %>%
              group_by(profile) %>%
              summarise(
                countries = paste(sort(as.character(decode_html_entities(IDCNTRY))), collapse = "、"),
                n = n(),
                .groups = 'drop'
              )
            
            for (j in seq_len(nrow(profile_detail))) {
              cat(sprintf("    剖面%d（%d个国家）：%s\n", 
                          profile_detail$profile[j], 
                          profile_detail$n[j],
                          profile_detail$countries[j]))
            }
            cat("\n")
          }
        }
        
      } else {
        # Mplus不可用，使用tidyLPA
        cat(" (tidyLPA)")
        lpa_result <- estimate_profiles(
          lpa_data_country,
          n_profiles = n_prof,
          variances = "equal",
          covariances = "zero",
          package = "mclust"
        )
        
        fit_indices <- get_fit(lpa_result)
        
        model_fit <- list(
          model = lpa_result,
          n_profiles = n_prof,
          AIC = fit_indices$AIC[1],
          BIC = fit_indices$BIC[1],
          aBIC = fit_indices$AIC[1] + (log(nrow(lpa_data_country)) - 2) * 
                 (fit_indices$BIC[1] - fit_indices$AIC[1]) / (2 * log(nrow(lpa_data_country))),
          Entropy = fit_indices$Entropy[1],
          LMRtp = NA,
          BLRtp = NA
        )
        
        if (is.na(model_fit$aBIC) || is.infinite(model_fit$aBIC)) {
          n_obs <- nrow(lpa_data_country)
          n_params <- n_prof * ncol(lpa_data_country) * 2
          model_fit$aBIC <- model_fit$AIC + (log((n_obs + 2) / 24) - 2) * n_params / 2
        }
        
        all_models[[n_prof]] <- model_fit
        cat(" ✓\n")
        
        # 输出该模型的剖面分类详情
        if (n_prof > 1 && !is.null(model_fit$profile_assignment)) {
          cat(sprintf("  模型%d的剖面分类详情：\n", n_prof))
          
          # 将剖面分配与国家数据合并
          temp_country_data <- country_level_data[, c("IDCNTRY", "LIT_SCORE", "INF_SCORE", "RSI_SCORE", "IIE_SCORE", "REA_SCORE")]
          temp_country_data$profile <- model_fit$profile_assignment[seq_len(min(nrow(temp_country_data), length(model_fit$profile_assignment)))]
          
          # 按剖面分组输出
          profile_detail <- temp_country_data %>%
            group_by(profile) %>%
            summarise(
              countries = paste(sort(as.character(decode_html_entities(IDCNTRY))), collapse = "、"),
              n = n(),
              .groups = 'drop'
            )
          
          for (j in seq_len(nrow(profile_detail))) {
            cat(sprintf("    剖面%d（%d个国家）：%s\n", 
                        profile_detail$profile[j], 
                        profile_detail$n[j],
                        profile_detail$countries[j]))
          }
          cat("\n")
        }
      }
    }
    
    # 添加到模型对比表
    category_counts_str <- if (!is.null(model_fit$category_counts)) model_fit$category_counts else ""
    if (n_prof == 1) {
      category_counts_str <- ""  # 单组模型没有类别数量
    }
    
    model_comparison <- rbind(model_comparison, data.frame(
      模型 = n_prof,
      AIC = model_fit$AIC,
      BIC = model_fit$BIC,
      aBIC = model_fit$aBIC,
      Entropy = model_fit$Entropy,
      LMRtp = model_fit$LMRtp,
      BLRtp = model_fit$BLRtp,
      类别数量 = category_counts_str,
      stringsAsFactors = FALSE
    ))
    
  }, error = function(e) {
    cat(sprintf(" ✗ (错误: %s)\n", conditionMessage(e)))
    # 添加NA行
    model_comparison <<- rbind(model_comparison, data.frame(
      模型 = n_prof,
      AIC = NA,
      BIC = NA,
      aBIC = NA,
      Entropy = NA,
      LMRtp = NA,
      BLRtp = NA,
      类别数量 = "",
      stringsAsFactors = FALSE
    ))
  })
}

cat("\n")

# ============================================
# 4.7 选择最优模型
# ============================================

cat("模型对比结果：\n")
# 格式化输出表格
model_comparison_display <- model_comparison
# 将NA替换为空字符串用于显示
model_comparison_display$Entropy[is.na(model_comparison_display$Entropy)] <- ""
model_comparison_display$LMRtp[is.na(model_comparison_display$LMRtp)] <- ""
model_comparison_display$BLRtp[is.na(model_comparison_display$BLRtp)] <- ""
# 格式化数值（保留3位小数）
model_comparison_display$AIC <- ifelse(is.na(model_comparison_display$AIC), "", 
                                      sprintf("%.3f", model_comparison_display$AIC))
model_comparison_display$BIC <- ifelse(is.na(model_comparison_display$BIC), "", 
                                      sprintf("%.3f", model_comparison_display$BIC))
model_comparison_display$aBIC <- ifelse(is.na(model_comparison_display$aBIC), "", 
                                        sprintf("%.3f", model_comparison_display$aBIC))
model_comparison_display$Entropy <- ifelse(model_comparison_display$Entropy == "", "", 
                                          sprintf("%.3f", as.numeric(model_comparison_display$Entropy)))
model_comparison_display$LMRtp <- ifelse(model_comparison_display$LMRtp == "", "", 
                                         sprintf("%.4f", as.numeric(model_comparison_display$LMRtp)))
model_comparison_display$BLRtp <- ifelse(model_comparison_display$BLRtp == "", "", 
                                        sprintf("%.4f", as.numeric(model_comparison_display$BLRtp)))

print(model_comparison_display)
cat("\n")

# 选择BIC最小的模型（排除NA）
valid_models <- model_comparison[!is.na(model_comparison$BIC), ]
if (nrow(valid_models) > 0) {
  best_model_idx <- which.min(valid_models$BIC)
  best_n_profiles <- valid_models$模型[best_model_idx]
  
  cat(sprintf("最优模型：%d 个剖面（BIC最小 = %.2f）\n\n", 
              best_n_profiles, valid_models$BIC[best_model_idx]))
  
  # ============================================
  # 4.8 提取最优模型的剖面分配
  # ============================================
  
  # 修复逻辑判断：确保每个条件都是标量
  cond1 <- best_n_profiles > 1
  cond2 <- best_n_profiles <= length(all_models)
  cond3 <- !is.null(all_models[[best_n_profiles]]$model)
  cond4 <- if (cond3) {
    model_class <- class(all_models[[best_n_profiles]]$model)[1]
    model_class != "character" && model_class != "NULL"
  } else FALSE
  
  if (cond1 && cond2 && cond3 && cond4) {
    
    cat("提取最优模型的剖面分配...\n")
    
    best_model <- all_models[[best_n_profiles]]$model
    
    # 从Mplus结果或tidyLPA结果中提取剖面分配
    if (inherits(best_model, "mplus.model")) {
      # Mplus结果
      if (!is.null(best_model$results$savedata) && "C" %in% names(best_model$results$savedata)) {
        profile_assignment <- best_model$results$savedata$C
      } else if (!is.null(all_models[[best_n_profiles]]$profile_assignment)) {
        profile_assignment <- all_models[[best_n_profiles]]$profile_assignment
      } else {
        stop("无法从Mplus结果中提取剖面分配")
      }
    } else {
      # tidyLPA结果（使用多种方法提取剖面分配）
      profile_assignment <- NULL
      
      # 方法1：从已保存的profile_assignment中提取
      if (!is.null(all_models[[best_n_profiles]]$profile_assignment)) {
        profile_assignment <- all_models[[best_n_profiles]]$profile_assignment
  } else {
        # 方法2：从tidyLPA结果对象中提取
        tryCatch({
          if (is.list(best_model) && length(best_model) > 0) {
            best_tidy_model <- best_model[[1]]
            
            # 尝试多种方式提取数据
            profile_data <- NULL
            
            # 方式1：使用get_data函数
            if (is.function(get_data)) {
    tryCatch({
                profile_data <- get_data(best_tidy_model)
    }, error = function(e) {
                # get_data失败，尝试其他方法
              })
            }
            
            # 方式2：直接从对象中提取
            if (is.null(profile_data)) {
              if (is.list(best_tidy_model)) {
                if ("dff" %in% names(best_tidy_model)) {
                  profile_data <- best_tidy_model$dff
                } else if ("model" %in% names(best_tidy_model) && is.list(best_tidy_model$model)) {
                  if ("dff" %in% names(best_tidy_model$model)) {
                    profile_data <- best_tidy_model$model$dff
                  }
                }
              }
            }
            
            # 方式3：如果best_tidy_model本身就是数据框
            if (is.null(profile_data) && is.data.frame(best_tidy_model)) {
              profile_data <- best_tidy_model
            }
            
            # 从profile_data中提取Class
            if (!is.null(profile_data) && is.data.frame(profile_data)) {
              if ("Class" %in% names(profile_data)) {
                profile_assignment <- profile_data$Class
              } else if (any(grepl("CPROB", names(profile_data)))) {
                cprob_cols <- grep("CPROB", names(profile_data))
                if (length(cprob_cols) > 0) {
                  profile_assignment <- apply(profile_data[, cprob_cols, drop = FALSE], 1, which.max)
                }
              }
            }
          }
        }, error = function(e) {
          cat(sprintf("警告：从tidyLPA结果中提取剖面分配失败: %s\n", conditionMessage(e)))
        })
      }
      
      # 如果仍然无法提取，使用默认分配
      if (is.null(profile_assignment) || length(profile_assignment) == 0) {
        # 从类别数量中推断（如果可用）
        if (!is.null(all_models[[best_n_profiles]]$category_counts) && 
            all_models[[best_n_profiles]]$category_counts != "") {
          counts <- as.numeric(strsplit(all_models[[best_n_profiles]]$category_counts, ",")[[1]])
          profile_assignment <- rep(seq_along(counts), counts)
        } else {
          stop("无法从tidyLPA结果中提取剖面分配，且没有可用的类别数量信息")
        }
      }
    }
    
    country_level_data$profile <- profile_assignment
  
  # ============================================
    # 4.9 剖面命名（基于四个子领域的均值）
  # ============================================
  
    cat("为剖面命名...\n")
  
    profile_means <- country_level_data %>%
    group_by(profile) %>%
    summarise(
        LIT_mean = mean(LIT_SCORE, na.rm = TRUE),
        INF_mean = mean(INF_SCORE, na.rm = TRUE),
        RSI_mean = mean(RSI_SCORE, na.rm = TRUE),
        IIE_mean = mean(IIE_SCORE, na.rm = TRUE),
        REA_mean = mean(REA_SCORE, na.rm = TRUE),
        n_countries = n(),
      .groups = 'drop'
    )
  
    # 根据均值命名剖面
    profile_means <- profile_means %>%
      mutate(
        profile_name = case_when(
          LIT_mean > 550 & INF_mean > 550 & RSI_mean > 550 & IIE_mean > 550 ~ "四领域高水平组",
          LIT_mean > 500 & INF_mean > 500 & RSI_mean < 500 & IIE_mean < 500 ~ "文学-信息优势组",
          LIT_mean < 500 & INF_mean < 500 & RSI_mean > 500 & IIE_mean > 500 ~ "推论-评价优势组",
          TRUE ~ paste0("剖面", profile)
        )
      )
    
    # 合并到country_level_data
    country_level_data <- country_level_data %>%
      left_join(select(profile_means, profile, profile_name), by = "profile")
    
    cat("剖面命名结果：\n")
    print(profile_means[, c("profile", "profile_name", "LIT_mean", "INF_mean", 
                             "RSI_mean", "IIE_mean", "REA_mean", "n_countries")])
    cat("\n")
    
    # 显示每个剖面包含的具体国家IDCNTRY（中文名称）
    cat("各剖面包含的国家：\n")
    profile_countries <- country_level_data %>%
      group_by(profile, profile_name) %>%
      summarise(
        IDCNTRY_list = paste(sort(as.character(IDCNTRY)), collapse = "、"),
        n_countries = n(),
        .groups = 'drop'
      )
    
    for (i in seq_len(nrow(profile_countries))) {
      # 解码HTML实体
      decoded_countries <- decode_html_entities(profile_countries$IDCNTRY_list[i])
      cat(sprintf("  剖面%d（%s）：共%d个国家\n    %s\n", 
                  profile_countries$profile[i], 
                  profile_countries$profile_name[i],
                  profile_countries$n_countries[i],
                  decoded_countries))
    }
    cat("\n")
    
    # ============================================
    # 4.10 验证：剖面与整体阅读素养的关系
    # ============================================
    
    cat("验证剖面与整体阅读素养的关系...\n")
    
    profile_literacy <- country_level_data %>%
      group_by(profile_name) %>%
      summarise(
        REA_mean = mean(REA_SCORE, na.rm = TRUE),
        REA_sd = sd(REA_SCORE, na.rm = TRUE),
        REA_se = REA_sd / sqrt(n()),
        n_countries = n(),
        .groups = 'drop'
      )
    
    cat("各剖面的整体阅读素养得分：\n")
    print(profile_literacy)
    cat("\n")
    
  } else {
    cat("警告：无法提取最优模型的剖面分配\n\n")
  }
  
} else {
  cat("警告：没有有效的模型用于选择\n\n")
}

# ============================================
# 4.11 保存结果
# ============================================

cat("保存结果...\n")

# 创建结果目录（使用绝对路径）
results_dir <- file.path(base_dir, "analysis_code", "results")
data_dir <- file.path(base_dir, "analysis_code", "data")

if (!dir.exists(results_dir)) {
  dir.create(results_dir, recursive = TRUE)
}
if (!dir.exists(data_dir)) {
  dir.create(data_dir, recursive = TRUE)
}

# 保存模型对比表（格式化后保存）
model_comparison_save <- model_comparison
# 格式化数值（保留适当小数位）
model_comparison_save$AIC <- ifelse(is.na(model_comparison_save$AIC), "", 
                                    round(model_comparison_save$AIC, 3))
model_comparison_save$BIC <- ifelse(is.na(model_comparison_save$BIC), "", 
                                    round(model_comparison_save$BIC, 3))
model_comparison_save$aBIC <- ifelse(is.na(model_comparison_save$aBIC), "", 
                                     round(model_comparison_save$aBIC, 3))
model_comparison_save$Entropy <- ifelse(is.na(model_comparison_save$Entropy), "", 
                                        round(model_comparison_save$Entropy, 3))
model_comparison_save$LMRtp <- ifelse(is.na(model_comparison_save$LMRtp), "", 
                                      round(model_comparison_save$LMRtp, 4))
model_comparison_save$BLRtp <- ifelse(is.na(model_comparison_save$BLRtp), "", 
                                      round(model_comparison_save$BLRtp, 4))

comparison_file <- file.path(results_dir, "04_LPA_model_comparison.csv")
write.csv(model_comparison_save, 
          file = comparison_file,
          row.names = FALSE, fileEncoding = "UTF-8")

cat(sprintf("模型对比表已保存：%s\n", comparison_file))

# 保存国家级别的数据（包含剖面分配）
if (exists("country_level_data") && "profile" %in% names(country_level_data)) {
  profiles_file <- file.path(results_dir, "04_LPA_country_profiles.csv")
  write.csv(country_level_data,
            file = profiles_file,
            row.names = FALSE, fileEncoding = "UTF-8")
  cat(sprintf("国家剖面分配已保存：%s\n", profiles_file))
}

# 保存RData
rdata_file <- file.path(data_dir, "04_lpa_analysis.RData")
save(all_models, model_comparison, country_level_data,
     file = rdata_file)
cat(sprintf("RData已保存：%s\n\n", rdata_file))

cat("========== LPA分析完成 ==========\n\n")

