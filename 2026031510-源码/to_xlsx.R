library(dplyr)
library(writexl)
library(tools)

setwd("E:/北语/大创项目/pirls2021/P21_Data_R/Data")

rdata_files <- list.files(pattern = "*.Rdata")

for (file in rdata_files) {
  temp_env <- new.env()
  load(file, envir = temp_env)
  data_objects <- ls(envir = temp_env)
  
  data_list <- list()

  for (obj_name in data_objects) {
    current_data <- get(obj_name, envir = temp_env)
    
    if (is.data.frame(current_data)) {
      data_list[[length(data_list) + 1]] <- current_data
    }
  }
  
  combined_data <- bind_rows(data_list)
  
  excel_filename <- paste0("output_", file_path_sans_ext(file), ".xlsx")
  write_xlsx(list("CombinedData" = combined_data), excel_filename)

  rm(list = ls(envir = temp_env), envir = temp_env)
  rm(list = ls())
  gc()
}