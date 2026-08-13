# PIRLS 2021 分析 - 快速启动脚本
# 文件: quick_start.R
# 说明: 一键运行所有分析步骤

cat("\n")
cat("╔════════════════════════════════════════╗\n")
cat("║  PIRLS 2021 LPA分析 - 快速启动        ║\n")
cat("╚════════════════════════════════════════╝\n\n")

# 设置项目根目录（使用绝对路径）
base_dir <- "E:/BLCU/DC24/国际中文"
setwd(base_dir)

# 检查数据文件
data_file <- file.path(base_dir, "newLPA.xlsx")
if (!file.exists(data_file)) {
  stop(sprintf("错误：找不到数据文件 %s\n请确保文件在项目根目录下", data_file))
}

cat(sprintf("数据文件：%s ✓\n", data_file))
cat(sprintf("工作目录：%s\n", getwd()))
cat("\n")

# 运行分析步骤
cat("开始运行分析...\n\n")

# 步骤0：初始化环境
cat("步骤 0/1: 初始化环境...\n")
source(file.path(base_dir, "analysis_code", "00_init_environment.R"))

# 步骤4：LPA分析
cat("\n步骤 1/1: LPA分析...\n")
source(file.path(base_dir, "analysis_code", "04_latent_profile_analysis.R"))

cat("\n")
cat("╔════════════════════════════════════════╗\n")
cat("║  所有分析完成！                        ║\n")
cat("╚════════════════════════════════════════╝\n\n")

cat("结果文件位置：\n")
cat(sprintf("  - %s\n", file.path(base_dir, "analysis_code", "results", "04_LPA_model_comparison.csv")))
cat(sprintf("  - %s\n", file.path(base_dir, "analysis_code", "results", "04_LPA_country_profiles.csv")))
cat(sprintf("  - %s\n\n", file.path(base_dir, "analysis_code", "data", "04_lpa_analysis.RData")))

