import os
import pandas as pd
from pathlib import Path


def replace_specific_numbers(folder_path, output_folder=None):
    """
    批量替换Excel文件中所有列的特定数值(9, 99, 999, 9999, 999999, 9999999999)为空值

    参数:
        folder_path (str): 包含Excel文件的文件夹路径
        output_folder (str, optional): 输出文件夹路径，None则覆盖原文件
    """
    # 定义要替换的特定数值
    numbers_to_replace = [9, 99, 999, 9999, 99999, 999999, 9999999999, 6]

    # 确保输出目录存在
    if output_folder:
        Path(output_folder).mkdir(parents=True, exist_ok=True)

    # 获取所有xlsx文件
    excel_files = list(Path(folder_path).glob('*.xlsx'))
    for file in excel_files:
        try:
        # 读取Excel文件
            df = pd.read_excel(file)

        # 记录原始形状
            original_shape = df.shape

        # 在所有列中替换特定数值
            for col in df.columns:
            # 只处理数值型列
                if pd.api.types.is_numeric_dtype(df[col]):
                    df[col] = df[col].replace(numbers_to_replace, pd.NA)

        # 确定输出路径
            output_path = Path(output_folder) / file.name if output_folder else file

        # 保存文件
            df.to_excel(output_path, index=False)
            print(f"已处理: {file.name} (原始行数: {original_shape[0]}, 列数: {original_shape[1]})")

        except Exception as e:
            print(f"处理文件 {file.name} 时出错: {str(e)}")

        print("\n处理完成！")


# 使用示例
if __name__ == "__main__":
    # 配置参数
    input_folder = 'A5R5'  # 替换为你的Excel文件所在文件夹
    output_folder = r'ASG_A5R5'  # 替换为输出文件夹，或设为None覆盖原文件

    # 执行处理
    replace_specific_numbers(
        folder_path=input_folder,
        output_folder=output_folder
    )