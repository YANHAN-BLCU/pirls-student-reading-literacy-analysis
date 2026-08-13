import os
import pandas as pd

def calculate_percentages(file_path):
    df = pd.read_excel(file_path)
    fields = ['ASBG06']
    values = [1, 2, 3, 4, 5]
    result = {}
    for field in fields:
        if field in df.columns:
            field_result = {}
            total_count = df[field].count()
            for value in values:
                count = (df[field] == value).sum()
                percentage = (count / total_count) * 100 if total_count > 0 else 0
                field_result[value] = percentage
            result[field] = field_result
        else:
            result[field] = {value: 0 for value in values}
    return result

def process_folder(folder_path):
    all_results = {}
    for root, dirs, files in os.walk(folder_path):
        for file in files:
            if file.endswith(('.xlsx', '.xls')):
                file_path = os.path.join(root, file)
                df_a2 = pd.read_excel(file_path, header=None, nrows=1, skiprows=1)
                a2_value = df_a2.iloc[0, 0]
                results = calculate_percentages(file_path)
                all_results[a2_value] = results
    return all_results

def save_results_to_excel(all_results, output_file):
    data = []
    for file, results in all_results.items():
        for field, percentages in results.items():
            for value, percentage in percentages.items():
                row = [file, field, value, percentage]
                data.append(row)
    columns = ['File', 'Field', 'Value', 'Percentage']
    result_df = pd.DataFrame(data, columns=columns)
    result_df.to_excel(output_file, index=False)

if __name__ == "__main__":
    folder_path = '.'  # 替换为实际的文件夹路径
    output_file = 'output01.xlsx'  # 输出文件的名称
    all_results = process_folder(folder_path)
    save_results_to_excel(all_results, output_file)
