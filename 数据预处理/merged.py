import os
import pandas as pd
import re

# 读取idcountry.md文件，获取国家名字和对应的数字编号
def read_idcountry(file_path):
    country_dict = {}
    with open(file_path, 'r', encoding='utf-8') as file:
        lines = file.readlines()
        for line in lines:
            line = line.strip()
            if line:
                parts = line.rsplit(' ', 1)
                country = parts[0]
                code = parts[1]
                country_dict[code] = country
    return country_dict

# 过滤文件名中的非法字符
def clean_filename(filename):
    # 定义非法字符的正则表达式
    illegal_chars = r'[\\/*?:"<>|]'
    # 使用正则表达式替换非法字符为空字符串
    return re.sub(illegal_chars, '', filename)

# 遍历指定目录下的所有 Excel 文件，并根据 A2 单元格的值和国家映射重命名
def rename_excel_files(folder_path, country_dict):
    for filename in os.listdir(folder_path):
        if filename.endswith(('.xlsx', '.xls')):
            file_path = os.path.join(folder_path, filename)
            try:
                # 读取 Excel 文件
                df = pd.read_excel(file_path, header=None)
                # 获取 A2 单元格的数据
                a2_value = df.iloc[1, 0]
                if str(a2_value) in country_dict:
                    country = country_dict[str(a2_value)]
                    if "R5" in filename:
                        new_file_name = f"ASG_{country}_R5"
                    else:
                        new_file_name = f"ASG_{country}_A5R5"
                    file_extension = os.path.splitext(filename)[1]
                    # 过滤新文件名中的非法字符
                    new_file_name = clean_filename(new_file_name) + file_extension
                    new_file_path = os.path.join(folder_path, new_file_name)
                    # 重命名文件
                    os.rename(file_path, new_file_path)
                    print(f"文件 {filename} 已重命名为 {new_file_name}")
                else:
                    print(f"未找到 {a2_value} 对应的国家代码，跳过文件 {filename}")
            except Exception as e:
                print(f"处理文件 {filename} 时出错: {e}")

if __name__ == "__main__":
    # idcountry.md文件的路径，使用相对路径
    idcountry_file_path = 'idcountry.md'
    # A5R5目录的路径，使用相对路径
    a5r5_directory = 'A5R5'
    print(f"尝试读取文件: {idcountry_file_path}")
    print(f"尝试访问目录: {a5r5_directory}")
    try:
        # 读取国家代码映射
        country_dict = read_idcountry(idcountry_file_path)
        # 重命名 Excel 文件
        rename_excel_files(a5r5_directory, country_dict)
    except FileNotFoundError:
        print("文件或目录未找到，请检查路径是否正确")
    except PermissionError:
        print("没有足够的权限，请检查文件和目录的权限")
    except Exception as e:
        print(f"发生未知错误: {e}")
