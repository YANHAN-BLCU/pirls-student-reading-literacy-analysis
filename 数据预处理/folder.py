import os
import shutil
import re

# 定义文件夹路径
A5_folder = 'A5'
R5_folder = 'R5'
output_folder = 'A5R5'

# 创建输出文件夹
if not os.path.exists(output_folder):
    os.makedirs(output_folder)

# 获取A5和R5文件夹中的所有文件
A5_files = os.listdir(A5_folder)
R5_files = os.listdir(R5_folder)

# 记录A5文件中提取的XXX部分
a5_xxx_set = set()
for A5_file in A5_files:
    if A5_file.endswith('.xlsx'):
        match = re.search(r'output_ASG(\w+)A5', A5_file)
        if match:
            xxx = match.group(1)
            a5_xxx_set.add(xxx)

# 处理R5文件
for R5_file in R5_files:
    if R5_file.endswith('.xlsx'):
        match = re.search(r'output_ASG(\w+)R5', R5_file)
        if match:
            xxx = match.group(1)
            if xxx in a5_xxx_set:
                # 若R5文件的XXX部分与A5文件匹配，将其复制到输出文件夹
                R5_path = os.path.join(R5_folder, R5_file)
                output_path = os.path.join(output_folder, f'{xxx}.xlsx')
                shutil.copy2(R5_path, output_path)
            else:
                # 若不匹配，直接复制到输出文件夹
                R5_path = os.path.join(R5_folder, R5_file)
                output_path = os.path.join(output_folder, R5_file)
                shutil.copy2(R5_path, output_path)