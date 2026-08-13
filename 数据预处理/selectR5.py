import os
import shutil
from pathlib import Path


def find_and_copy_mismatched_files(a5_folder, r5_folder, output_folder):
    """
    查找R5文件夹中没有对应A5文件的Excel文件，并复制到输出目录

    参数:
        a5_folder (str): A5文件夹路径
        r5_folder (str): R5文件夹路径
        output_folder (str): 输出目录路径
    """
    # 创建输出目录（如果不存在）
    Path(output_folder).mkdir(parents=True, exist_ok=True)

    # 获取A5文件夹中的所有xlsx文件名（不带扩展名）
    a5_files = {f.stem for f in Path(a5_folder).glob('*.xlsx')}

    # 获取R5文件夹中的所有xlsx文件
    r5_files = list(Path(r5_folder).glob('*.xlsx'))

    # 查找不匹配的文件
    mismatched_files = []
    for r5_file in r5_files:
        # 尝试将R5替换为A5来查找对应文件
        a5_equivalent = r5_file.stem.replace('R5', 'A5')

        # 检查A5文件夹中是否存在对应文件
        if a5_equivalent not in a5_files:
            mismatched_files.append(r5_file)

    # 复制不匹配的文件到输出目录
    for file in mismatched_files:
        dest_path = Path(output_folder) / file.name
        shutil.copy2(str(file), str(dest_path))
        print(f"已复制: {file.name}")

    # 打印总结
    print(f"\n完成！共找到 {len(mismatched_files)} 个不匹配的文件")
    print(f"已保存到: {output_folder}")


# 使用示例
if __name__ == "__main__":
    # 设置文件夹路径（请替换为你的实际路径）
    a5_dir = r'D:\ePIRLS\unsolved\ATG\ATGA5'  # 包含output_ATGAREA5.xlsx等文件的文件夹
    r5_dir = r'D:\ePIRLS\unsolved\ATG\ATGR5'  # 包含output_ATGARER5.xlsx等文件的文件夹
    output_dir = r'D:\ePIRLS\solved_v1'  # 保存不匹配文件的目录

    find_and_copy_mismatched_files(a5_dir, r5_dir, output_dir)