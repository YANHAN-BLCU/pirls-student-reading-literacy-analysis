import os
import pandas as pd
import re

# 定义文件夹路径
A5_folder = r'D:\ePIRLS\unsolved\ATG\ATGA5'
R5_folder = r'D:\ePIRLS\unsolved\ATG\ATGR5'
output_folder = r'D:\ePIRLS\solved_v1'

# 创建输出文件夹
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

# 获取A5和R5文件夹中的所有文件
A5_files = os.listdir(A5_folder)
R5_files = os.listdir(R5_folder)

# 遍历A5文件夹中的文件
for A5_file in A5_files:
    if A5_file.endswith('.xlsx'):
        # 提取文件名中的XXX部分
        match = re.search(r'output_ATG(\w+)A5', A5_file)
        if match:
            xxx = match.group(1)
            # 构建对应的R5文件名
            R5_file = f'output_ATG{xxx}R5.xlsx'
            if R5_file in R5_files:
                # 读取A5和R5文件
                A5_path = os.path.join(A5_folder, A5_file)
                R5_path = os.path.join(R5_folder, R5_file)
                df_A5 = pd.read_excel(A5_path)
                df_R5 = pd.read_excel(R5_path)

                # 合并两个DataFrame
                merged_df = pd.concat([df_A5, df_R5], ignore_index=True)

                # 构建输出文件名
                output_file = os.path.join(output_folder, f'{xxx}.xlsx')

                # 保存合并后的文件
                merged_df.to_excel(output_file, index=False)
