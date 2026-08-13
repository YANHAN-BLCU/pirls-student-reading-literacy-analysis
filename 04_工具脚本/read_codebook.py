import pandas as pd
import openpyxl

# 读取文件
excel_file = r"E:\BLCU\DC24\二期\P21_Codebook.xlsx"

# 获取所有sheet名称
xls = pd.ExcelFile(excel_file)
print("所有工作表：")
print(xls.sheet_names)
print("\n")

# 读取前几个sheet
for sheet_name in xls.sheet_names[:3]:
    print(f"\n========== {sheet_name} ==========")
    df = pd.read_excel(excel_file, sheet_name=sheet_name, nrows=20)
    print(df.head(20))
    print(f"形状: {df.shape}")

