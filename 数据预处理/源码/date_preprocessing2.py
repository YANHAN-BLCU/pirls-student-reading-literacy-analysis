import pandas as pd
import os
from clearn.data_preprocessing import *
import numpy as np
from sklearn.impute import KNNImputer
from sklearn.preprocessing import StandardScaler




def detect_data_type(series):
    """检测数据列的类型"""
    if pd.api.types.is_integer_dtype(series.dropna()):
        if series.nunique() / len(series) < 0.2:
            return 'discrete'
    if pd.api.types.is_float_dtype(series.dropna()):
        if (series.dropna() == series.dropna().round()).mean() > 0.9:
            if series.nunique() / len(series) < 0.3:
                return 'discrete'
    return 'continuous'


def safe_standard_scaler(df, numeric_cols):
    """安全的标准化处理，处理可能的NaN/Inf值"""
    # 替换无穷大值为NaN
    df[numeric_cols] = df[numeric_cols].replace([np.inf, -np.inf], np.nan)

    # 检查是否有全NaN的列
    valid_cols = [col for col in numeric_cols if not df[col].isnull().all()]
    if not valid_cols:
        return None, None, None

    # 只保留有效列
    df_valid = df[valid_cols].copy()

    # 标准化
    scaler = StandardScaler()
    try:
        df_scaled = pd.DataFrame(scaler.fit_transform(df_valid),
                                 columns=valid_cols)
        return df_scaled, scaler, valid_cols
    except Exception as e:
        print(f"标准化失败: {str(e)}")
        return None, None, None


def process_excel_file(input_path, output_folder):
    """处理单个Excel文件"""
    try:
        df = pd.read_excel(input_path)
        if df.empty:
            print(f"文件 {os.path.basename(input_path)} 是空的，跳过处理")
            return

        numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
        if not numeric_cols:
            print(f"文件 {os.path.basename(input_path)} 没有数值列，跳过处理")
            return

        # 安全标准化
        df_scaled, scaler, valid_cols = safe_standard_scaler(df, numeric_cols)
        if df_scaled is None:
            print(f"文件 {os.path.basename(input_path)} 标准化失败，跳过处理")
            return

        # 检测数据类型
        col_types = {col: detect_data_type(df[col]) for col in valid_cols}

        # KNN插补
        imputer = KNNImputer(n_neighbors=min(5, len(df_scaled) - 1))  # 确保邻居数不超过样本数
        try:
            df_imputed = imputer.fit_transform(df_scaled)
        except ValueError as e:
            print(f"KNN插补失败: {str(e)}")
            return

        # 反标准化
        df_imputed = pd.DataFrame(scaler.inverse_transform(df_imputed),
                                  columns=valid_cols,
                                  index=df.index)

        # 调整插补值格式
        for col in valid_cols:
            if col_types.get(col) == 'discrete':
                df_imputed[col] = np.round(df_imputed[col]).astype(int)

        #合并
        cols_to_add = [col for col in df.columns if col not in df_imputed.columns]
        if cols_to_add:
            df_imputed = pd.concat([df_imputed, df[cols_to_add]], axis=1)

        # 保存结果
        output_filename = f"Imputed_{os.path.basename(input_path)}"
        output_path = os.path.join(output_folder, output_filename)
        df_imputed.to_excel(output_path, index=False)
        print(f"成功处理: {output_path}")

    except Exception as e:
        print(f"处理文件 {os.path.basename(input_path)} 时出错: {str(e)}")


def process_all_excel_files(input_folder, output_folder):
    """处理文件夹中的所有Excel文件"""
    os.makedirs(output_folder, exist_ok=True)

    for filename in os.listdir(input_folder):
        if filename.endswith(('.xlsx', '.xls')):
            input_path = os.path.join(input_folder, filename)
            process_excel_file(input_path, output_folder)


# 使用示例
input_folder = r'ASG_A5R5'
output_folder = r'solved_v3'

print("开始处理文件...")
process_all_excel_files(input_folder, output_folder)
print("处理完成!")
