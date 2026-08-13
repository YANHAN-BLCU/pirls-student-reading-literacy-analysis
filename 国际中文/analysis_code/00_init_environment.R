# PIRLS 2021 分析 - 环境初始化
# 文件: 00_init_environment.R

cat("\n========== 初始化R环境 ==========\n\n")

# 设置项目根目录（使用绝对路径）
base_dir <- "E:/BLCU/DC24/国际中文"
setwd(base_dir)

cat(sprintf("工作目录：%s\n\n", getwd()))

# 必需的R包列表
required_packages <- c(
  "tidyverse",        # 数据处理
  "tidyLPA",          # LPA分析（备用）
  "mice",             # 多重插补
  "openxlsx",         # Excel读写
  "MplusAutomation"   # Mplus自动化（用于准确计算LMR/BLRT）
)

# 安装缺失的包
cat("检查并安装必需的R包...\n")
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("安装 %s...\n", pkg))
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  } else {
    cat(sprintf("  %s: 已安装\n", pkg))
  }
}

cat("\n")

# 创建输出目录（使用绝对路径）
base_dir <- "E:/BLCU/DC24/国际中文"
output_dirs <- c(
  file.path(base_dir, "analysis_code", "data"),
  file.path(base_dir, "analysis_code", "results"),
  file.path(base_dir, "analysis_code", "plots")
)

for (dir in output_dirs) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
    cat(sprintf("创建目录：%s\n", dir))
  }
}

cat("\n环境初始化完成\n\n")

