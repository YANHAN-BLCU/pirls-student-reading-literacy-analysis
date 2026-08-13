import os
import pandas as pd

# 定义文件夹路径和特定列名
folder_path = 'ASG/ASG_A5R5_solved_v3'
# 替换为你提供的列名
specific_columns = [
    'IDCNTRY',  # 国家代码
    # ASRREA系列 (阅读素养相关)
    'ASRREA01', 'ASRREA02', 'ASRREA03', 'ASRREA04', 'ASRREA05',
    # ASRLIT系列 (文学阅读相关)
    'ASRLIT01', 'ASRLIT02', 'ASRLIT03', 'ASRLIT04', 'ASRLIT05',
    # ASRINF系列 (信息阅读相关)
    'ASRINF01', 'ASRINF02', 'ASRINF03', 'ASRINF04', 'ASRINF05',
    # ASRIIE系列 (信息整合与评价相关)
    'ASRIIE01', 'ASRIIE02', 'ASRIIE03', 'ASRIIE04', 'ASRIIE05',
    # ASRRSI系列 (阅读反应与策略相关)
    'ASRRSI01', 'ASRRSI02', 'ASRRSI03', 'ASRRSI04', 'ASRRSI05',
]

# 初始化一个空的 DataFrame 用于存储合并后的数据
merged_df = pd.DataFrame()

# 检查文件夹是否存在
if not os.path.exists(folder_path):
    print(f"错误：文件夹 {folder_path} 不存在！")
    print(f"当前工作目录：{os.getcwd()}")
    exit(1)

print(f"开始处理文件夹：{folder_path}")
print(f"需要提取的列数：{len(specific_columns)}")

file_count = 0
# 遍历文件夹中的所有文件
for filename in os.listdir(folder_path):
    if filename.endswith(('.csv', '.xlsx')) and not filename.startswith('~$'):  # 跳过临时文件
        file_path = os.path.join(folder_path, filename)
        if os.path.exists(file_path):
            try:
                print(f"正在处理：{filename}...", end=' ')
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
                file_count += 1
                print(f"✓ ({len(df)} 行)")
            except Exception as e:
                print(f"✗ 错误：{str(e)}")
        else:
            print(f"文件 {file_path} 不存在，跳过。")

print(f"\n共处理 {file_count} 个文件")
print(f"合并后总行数：{len(merged_df)}")

# 保存合并后的数据到新文件
output_file = 'newLPA.xlsx'
merged_df.to_excel(output_file, index=False)

print(f"合并后的数据已保存到 {output_file}")
