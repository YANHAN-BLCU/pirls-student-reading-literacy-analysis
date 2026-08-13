import pandas as pd
import os

current_dir = os.getcwd()
folder_path = os.path.join(current_dir, 'A5R5')
file_names = input("请输入要合并的 Excel 文件名，用逗号分隔（例如：file1.xlsx,file2.xlsx）：").split(',')
merged_file_name = input("请输入合并后的 Excel 文件名（例如：merged.xlsx）：")
merged_df = pd.DataFrame()

for file_name in file_names:
    file_path = os.path.join(folder_path, file_name.strip())
    if os.path.exists(file_path):
        df = pd.read_excel(file_path)
        merged_df = pd.concat([merged_df, df], ignore_index=True)
    else:
        print(f"文件 {file_path} 不存在，请检查文件名。")

merged_file_path = os.path.join(folder_path, merged_file_name)
merged_df.to_excel(merged_file_path, index=False)

print(f"合并完成，合并后的文件已保存到 {merged_file_path}")
