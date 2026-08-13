import os
import pandas as pd

# 定义文件夹路径
folder_path = 'A5R5'
# 定义日志文件路径
log_file = os.path.join(folder_path, 'rename_log.csv')

if os.path.exists(log_file):
    # 读取日志文件
    log_df = pd.read_csv(log_file, header=None)
    for index, row in log_df[::-1].iterrows():
        old_filename = row[0]
        new_filename = row[1]
        old_file_path = os.path.join(folder_path, old_filename)
        new_file_path = os.path.join(folder_path, new_filename)
        if os.path.exists(new_file_path):
            try:
                # 撤销重命名
                os.rename(new_file_path, old_file_path)
                print(f"文件 {new_filename} 已撤销重命名为 {old_filename}")
            except Exception as e:
                print(f"撤销文件 {new_filename} 重命名时出错: {e}")
    # 删除日志文件
    os.remove(log_file)
else:
    print("未找到重命名日志文件，无法撤销重命名。")
