import pandas as pd

# 读取文件
excel_file = pd.ExcelFile('P21Br_Codebook.xlsx')

# 获取所有表名
sheet_names = excel_file.sheet_names

for sheet_name in sheet_names:
    # 获取指定工作表中的数据
    df = excel_file.parse(sheet_name)

    # 初始化列表
    num_vars = []
    cat_vars = []

    # 遍历指定列
    for index, row in df.iterrows():
        variable = row['Variable']
        level = row.get('Level')
        # 检查 level 是否为空
        if pd.isna(level):
            print(f"在工作表 {sheet_name} 中，第 {index} 行的 'Level' 列为空，跳过该行。")
            continue
        if level in ['Nominal', 'Ordinal']:
            cat_vars.append(variable)
        elif level in ['Ratio', 'Scale']:
            num_vars.append(variable)
        # 若 level 为 'Not Defined' 则跳过
        elif level == 'Not Defined':
            continue

    # 将列表转换为字符串
    num_vars_str = "['" + "', '".join(num_vars) + "']"
    cat_vars_str = "['" + "', '".join(cat_vars) + "']"

    # 输出结果到文本文件，文件名使用工作表名
    txt_filename = f"{sheet_name}.txt"
    with open(txt_filename, 'w', encoding='utf-8') as file:
        file.write(f"num_vars={num_vars_str}\n")
        file.write(f"cat_vars={cat_vars_str}\n")

    print(f"工作表 {sheet_name} 处理完成，结果已保存到 {txt_filename} 文件中。")