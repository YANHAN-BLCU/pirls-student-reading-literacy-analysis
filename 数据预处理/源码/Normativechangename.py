import os
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

# 遍历指定目录下的所有文件，并根据规则重命名
def rename_files(directory, country_dict):
    renamed_count = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            old_file_path = os.path.join(root, file)
            file_name_without_ext = os.path.splitext(file)[0]
            if file_name_without_ext in country_dict:
                country = country_dict[file_name_without_ext]
                if "R5" in file:
                    new_file_name = f"ASG_{country}_R5"
                else:
                    new_file_name = f"ASG_{country}_A5R5"
                file_extension = os.path.splitext(file)[1]
                # 过滤新文件名中的非法字符
                new_file_name = clean_filename(new_file_name) + file_extension
                new_file_path = os.path.join(root, new_file_name)
                try:
                    os.rename(old_file_path, new_file_path)
                    renamed_count += 1
                    print(f"重命名成功: {old_file_path} -> {new_file_path}")
                except Exception as e:
                    print(f"重命名 {old_file_path} 时出错: {e}")
    return renamed_count

if __name__ == "__main__":
    # idcountry.md文件的路径，使用相对路径
    idcountry_file_path = 'idcountry.md'
    # A5R5目录的路径，使用相对路径
    a5r5_directory = 'A5R5'
    print(f"尝试读取文件: {idcountry_file_path}")
    print(f"尝试访问目录: {a5r5_directory}")
    try:
        country_dict = read_idcountry(idcountry_file_path)
        renamed_count = rename_files(a5r5_directory, country_dict)
        if renamed_count > 0:
            print("文件重命名完成")
        else:
            print("未找到需要重命名的文件")
    except FileNotFoundError:
        print("文件或目录未找到，请检查路径是否正确")
    except PermissionError:
        print("没有足够的权限，请检查文件和目录的权限")
    except Exception as e:
        print(f"发生未知错误: {e}")
