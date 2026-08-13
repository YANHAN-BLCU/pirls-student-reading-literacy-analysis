import os
import pandas as pd

# 定义文件夹路径和特定列名
folder_path = 'ASG_A5R5_solved_v3'
# 替换为你提供的列名
specific_columns = [
'ASBG06'
]

# 初始化一个空的 DataFrame 用于存储合并后的数据
merged_df = pd.DataFrame()
6
# 遍历文件夹中的所有文件
for filename in os.listdir(folder_path):
    if filename.endswith(('.csv', '.xlsx')) and not filename.startswith('~$'):  # 跳过临时文件
        file_path = os.path.join(folder_path, filename)
        if os.path.exists(file_path):
            if filename.endswith('.csv'):
                df = pd.read_csv(file_path)
            else:
                df = pd.read_excel(file_path)
            # 确保 df 包含所有特定列，若缺失则填充为 NaN
            for col in specific_columns:
                if col not in df.columns:
                    df[col] = pd.NA
            # 只保留特定列，并按指定顺序排列
            df = df[specific_columns]
            # 合并数据
            merged_df = pd.concat([merged_df, df], ignore_index=True)
        else:
            print(f"文件 {file_path} 不存在，跳过。")

# 保存合并后的数据到新文件
output_file = 'merged03_data.xlsx'
merged_df.to_excel(output_file, index=False)

print(f"合并后的数据已保存到 {output_file}")
