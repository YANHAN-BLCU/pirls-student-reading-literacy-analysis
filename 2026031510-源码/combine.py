import pandas as pd
import os

input_folder = r'D:\excel_files'

output_file = r'D:\merged_ASAR5.xlsx'

excel_files = [f for f in os.listdir(input_folder) if f.endswith('.xlsx')]

if not excel_files:
    print("没有找到Excel文件，请检查路径是否正确。")
else:
    merged_data = pd.DataFrame()

    for file in excel_files:
        file_path = os.path.join(input_folder, file)

        df = pd.read_excel(file_path)

        merged_data = pd.concat([merged_data, df], ignore_index=True)

    merged_data.to_excel(output_file, index=False)

    print(f"合并完成，文件已保存到 {output_file}")