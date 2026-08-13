import os
import pandas as pd

# 定义文件夹路径和特定列名
folder_path = 'ASG_A5R5_solved_v3'
# 替换为你提供的列名
specific_columns = [
    'IDCNTRY', 'IDPOP', 'IDGRADER', 'IDGRADE', 'WAVE', 'IDSCHOOL', 'IDCLASS', 'IDSTUD',
    'ASBG04', 'ASBG05A', 'ASBG05B', 'ASBG05C', 'ASBG05D', 'ASBG05E', 'ASBG05F', 'ASBG05G',
    'ASBR01A', 'ASBR01B', 'ASBR01C', 'ASBR01D', 'ASBR01E', 'ASBR01F', 'ASBR01G', 'ASBR01H',
    'ASBR01I', 'ASBR02A', 'ASBR02B', 'ASBR02C', 'ASBR02D', 'ASBR02E', 'ASBR03A', 'ASBR03B',
    'ASBR03C', 'ASBR04', 'ASBR05', 'ASBR06A', 'ASBR06B', 'ASBR07A', 'ASBR07B', 'ASBR07C',
    'ASBR07D', 'ASBR07E', 'ASBR07F', 'ASBR07G', 'ASBR07H', 'ASBR08A', 'ASBR08B', 'ASBR08C',
    'ASBR08D', 'ASBR08E', 'ASBR08F', 'ASBGSSB', 'ASDGSSB', 'ASBGSB', 'ASDGSB', 'ASBGERL',
    'ASDGERL', 'ASBGDRL', 'ASDGDRL', 'ASBGSLR', 'ASDGSLR', 'ASBGHRL', 'ASDGHRL', 'ASBGSCR',
    'ASDGSCR', 'ASDG05S','ASRIBM01','ASRIBM02','ASRIBM03','ASRIBM04','ASRIBM05'

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
output_file = 'merged_data.xlsx'
merged_df.to_excel(output_file, index=False)

print(f"合并后的数据已保存到 {output_file}")
