import streamlit as st
import pandas as pd
import numpy as np
import plotly.express as px
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.linear_model import LinearRegression
from sklearn.svm import SVR
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.impute import SimpleImputer
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
import os
from dotenv import load_dotenv

# 尝试导入 XGBoost（可选）
try:
    from xgboost import XGBRegressor
    XGB_AVAILABLE = True
except ImportError:
    XGB_AVAILABLE = False

# --- 页面配置（必须是第一个 Streamlit 命令）---
st.set_page_config(
    page_title="数据导向的教育决策多元动态洞察系统",
    page_icon="📊",
    layout="wide"
)

# --- 环境配置 ---
load_dotenv()

# --- 初始化语言状态 ---
if "language" not in st.session_state:
    st.session_state.language = "中文"

# --- 多语言文本字典 ---
TEXTS = {
    "中文": {
        "title": "📊 数据导向的教育决策多元动态洞察系统",
        "sidebar_header": "分析设置",
        "x_axis_label": "选择X轴指标",
        "y_axis_label": "选择Y轴指标（可多选）",
        "filter_header": "数据筛选",
        "country_select": "选择国家/地区",
        "scatter_subheader": "国家/地区维度分析：{x} vs {y}",
        "raw_data_expander": "查看原始数据",
        "download_button": "📥 下载分析结果",
        "model_expander": "📈 数据挖掘模型分析（回归）",
        "target_select": "选择目标变量（待预测）",
        "feature_select": "选择特征变量（可多选）",
        "model_select": "选择模型",
        "train_button": "训练模型",
        "importance_plot": "特征重要性 / 系数绝对值",
        "model_performance": "模型性能",
        "r2_score": "R² 分数",
        "mae": "平均绝对误差 (MAE)",
        "mse": "均方误差 (MSE)",
        "no_features_warning": "请至少选择一个特征变量。",
        "dt_model": "决策树回归",
        "rf_model": "随机森林回归",
        "lr_model": "线性回归",
        "svr_model": "支持向量回归",
        "gb_model": "梯度提升回归",
        "xgb_model": "XGBoost回归",
        "xgb_not_installed": "⚠️ XGBoost 未安装，请运行 `pip install xgboost` 后使用。",
        "importance_note": "值越大，对目标变量的影响越显著",
        "language_select": "🌐 Language / 语言",
        "param_C": "正则化参数 C",
        "param_gamma": "核系数 gamma",
        "param_max_depth": "最大深度",
        "param_n_estimators": "树的数量",
        "param_learning_rate": "学习率",
        "param_subsample": "子采样比例",
        "test_size": "测试集比例",
        "random_state": "随机种子",
    },
    "English": {
        "title": "📊 Data-Driven Educational Decision Multi-Dynamic Insight System",
        "sidebar_header": "Analysis Settings",
        "x_axis_label": "Select X-axis Indicator",
        "y_axis_label": "Select Y-axis Indicator(s)",
        "filter_header": "Data Filter",
        "country_select": "Select Country/Region",
        "scatter_subheader": "Country/Region Analysis: {x} vs {y}",
        "raw_data_expander": "View Raw Data",
        "download_button": "📥 Download Analysis Results",
        "model_expander": "📈 Data Mining Model Analysis (Regression)",
        "target_select": "Select Target Variable",
        "feature_select": "Select Feature Variables",
        "model_select": "Select Model",
        "train_button": "Train Model",
        "importance_plot": "Feature Importance / Coefficient Magnitude",
        "model_performance": "Model Performance",
        "r2_score": "R² Score",
        "mae": "Mean Absolute Error (MAE)",
        "mse": "Mean Squared Error (MSE)",
        "no_features_warning": "Please select at least one feature variable.",
        "dt_model": "Decision Tree Regressor",
        "rf_model": "Random Forest Regressor",
        "lr_model": "Linear Regression",
        "svr_model": "Support Vector Regression",
        "gb_model": "Gradient Boosting Regressor",
        "xgb_model": "XGBoost Regressor",
        "xgb_not_installed": "⚠️ XGBoost not installed. Run `pip install xgboost` to use it.",
        "importance_note": "Larger value indicates stronger influence on the target.",
        "language_select": "🌐 Language / 语言",
        "param_C": "Regularization C",
        "param_gamma": "Kernel Coefficient gamma",
        "param_max_depth": "Max Depth",
        "param_n_estimators": "Number of Estimators",
        "param_learning_rate": "Learning Rate",
        "param_subsample": "Subsample Ratio",
        "test_size": "Test Set Ratio",
        "random_state": "Random Seed",
    }
}

# --- 指标中英文映射 ---
INDICATOR_MAPPING = {
    "中文": {
        "reading_score": "阅读成绩",
        "literary_purpose": "文学体验目的",
        "info_purpose": "信息获取目的",
        "integration_process": "理解整合能力",
        "inference_process": "检索推理能力",
        "reading_level": "阅读量级",
        "weekly_reading_hours": "每周阅读时长",
        "interest_reading_freq": "兴趣阅读频率",
        "reading_time_outside": "课外阅读时间",
        "home_books": "家庭藏书量",
        "children_book_count": "儿童书籍数量",
        "study_space_count": "家庭学习空间数",
        "guardian_a_education": "监护人A教育程度",
        "guardian_b_education": "监护人B教育程度",
        "child_education_expect": "孩子教育期望",
        "teaching_days_per_year": "每年教学天数",
        "teaching_hours_per_week": "每周教学时长",
        "computer_count": "学校计算机数量",
        "class_library_books": "班级图书馆藏书量",
        "teaching_years": "教师教龄",
        "provide_materials_freq": "教材提供频率",
        "encourage_comprehension_freq": "鼓励理解频率"
    },
    "English": {
        "reading_score": "Reading Score",
        "literary_purpose": "Literary Purpose",
        "info_purpose": "Informational Purpose",
        "integration_process": "Integration Process",
        "inference_process": "Inference Process",
        "reading_level": "Reading Level",
        "weekly_reading_hours": "Weekly Reading Hours",
        "interest_reading_freq": "Interest Reading Frequency",
        "reading_time_outside": "Reading Time Outside School",
        "home_books": "Home Books",
        "children_book_count": "Children's Book Count",
        "study_space_count": "Study Space Count",
        "guardian_a_education": "Guardian A Education",
        "guardian_b_education": "Guardian B Education",
        "child_education_expect": "Child Education Expectation",
        "teaching_days_per_year": "Teaching Days per Year",
        "teaching_hours_per_week": "Teaching Hours per Week",
        "computer_count": "Computer Count",
        "class_library_books": "Class Library Books",
        "teaching_years": "Teaching Years",
        "provide_materials_freq": "Provide Materials Frequency",
        "encourage_comprehension_freq": "Encourage Comprehension Frequency"
    }
}


# --- 数据加载（缓存）---
@st.cache_data
def load_data():
    # 请根据实际路径修改
    return pd.read_csv("education_data.csv")


# --- 预处理函数：用于模型训练 ---
def preprocess_for_model(df, target_col, feature_cols, scale_features=True):
    """
    准备模型训练数据：
    - 处理缺失值（数值列用中位数，分类列用众数）
    - 编码分类变量
    - 可选的标准化（对SVR、线性模型等有益）
    """
    data = df[[target_col] + feature_cols].copy()

    # 分离数值和分类列
    num_cols = data.select_dtypes(include=np.number).columns.tolist()
    cat_cols = data.select_dtypes(include="object").columns.tolist()

    # 缺失值填充
    if num_cols:
        num_imputer = SimpleImputer(strategy="median")
        data[num_cols] = num_imputer.fit_transform(data[num_cols])
    if cat_cols:
        cat_imputer = SimpleImputer(strategy="most_frequent")
        data[cat_cols] = cat_imputer.fit_transform(data[cat_cols])

    # 标签编码分类变量
    label_encoders = {}
    for col in cat_cols:
        le = LabelEncoder()
        data[col] = le.fit_transform(data[col].astype(str))
        label_encoders[col] = le

    X = data[feature_cols]
    y = data[target_col]

    # 标准化特征（对某些模型有帮助）
    if scale_features:
        scaler = StandardScaler()
        X_scaled = scaler.fit_transform(X)
        X = pd.DataFrame(X_scaled, columns=feature_cols)

    return X, y, label_encoders


# --- 主程序 ---
def main():
    lang = st.session_state.language
    texts = TEXTS[lang]
    indicator_map = INDICATOR_MAPPING[lang]

    st.title(texts["title"])
    df = load_data()

    # --- 侧边栏控件 ---
    with st.sidebar:
        # 语言切换
        selected_lang = st.radio(
            texts["language_select"],
            options=["中文", "English"],
            index=0 if st.session_state.language == "中文" else 1,
            horizontal=True,
            key="lang_radio"
        )
        if selected_lang != st.session_state.language:
            st.session_state.language = selected_lang
            st.rerun()

        st.header(texts["sidebar_header"])

        # X/Y轴指标选择
        x_axis = st.selectbox(
            texts["x_axis_label"],
            options=list(indicator_map.keys()),
            format_func=lambda x: indicator_map[x]
        )

        y_axes = st.multiselect(
            texts["y_axis_label"],
            options=list(indicator_map.keys()),
            format_func=lambda x: indicator_map[x],
            default=["teaching_hours_per_week"]
        )

        # 数据筛选
        st.subheader(texts["filter_header"])
        selected_countries = st.multiselect(
            texts["country_select"],
            options=df["IDCNTRY"].unique()
        )

    # --- 数据预处理（可视化用）---
    vis_df = df.copy()
    if selected_countries:
        vis_df = vis_df[vis_df["IDCNTRY"].isin(selected_countries)]

    group_by = "IDCNTRY"
    agg_df = vis_df.groupby(group_by).agg(
        **{f"avg_{x_axis}": (x_axis, "mean")},
        **{f"avg_{y}": (y, "mean") for y in y_axes}
    ).reset_index()

    # --- 散点图可视化 ---
    st.subheader(
        texts["scatter_subheader"].format(
            x=indicator_map[x_axis],
            y=" / ".join([indicator_map[y] for y in y_axes])
        )
    )

    fig = px.scatter(
        agg_df,
        x=f"avg_{x_axis}",
        y=[f"avg_{y}" for y in y_axes],
        color=group_by,
        hover_name=group_by,
        labels={
            "value": "指标平均值" if lang == "中文" else "Average Value",
            "variable": "指标类型" if lang == "中文" else "Indicator Type",
            f"avg_{x_axis}": f"{'平均' if lang == '中文' else 'Average '}{indicator_map[x_axis]}",
            "IDCNTRY": "国家/地区" if lang == "中文" else "Country/Region"
        },
        height=600
    )

    if len(y_axes) > 1:
        for i, y in enumerate(y_axes[1:]):
            fig.add_scatter(
                x=agg_df[f"avg_{x_axis}"],
                y=agg_df[f"avg_{y}"],
                name=indicator_map[y],
                mode="markers",
                marker=dict(symbol=i + 2, size=12),
                yaxis=f"y{i + 2}"
            )
        fig.update_layout(
            yaxis2=dict(
                title=indicator_map[y_axes[1]],
                overlaying="y",
                side="right"
            )
        )

    fig.update_layout(
        hoverlabel=dict(bgcolor="white", font_size=12),
        legend=dict(
            title="国家" if lang == "中文" else "Country",
            orientation="h",
            yanchor="bottom",
            y=1.02
        ),
        xaxis=dict(
            title=f"{'平均' if lang == '中文' else 'Average '}{indicator_map[x_axis]}",
            showgrid=True
        ),
        yaxis=dict(title=indicator_map[y_axes[0]], showgrid=True)
    )
    st.plotly_chart(fig, use_container_width=True)

    # --- 原始数据展示与下载 ---
    with st.expander(texts["raw_data_expander"]):
        styled_df = agg_df.style.format(
            "{:.2f}",
            subset=pd.IndexSlice[:, agg_df.select_dtypes(include='number').columns]
        )
        st.dataframe(styled_df, height=300)

    st.download_button(
        label=texts["download_button"],
        data=agg_df.to_csv(index=False).encode("utf-8"),
        file_name="country_analysis.csv",
        mime="text/csv"
    )

    # ==================== 数据挖掘模型分析模块 ====================
    st.divider()
    with st.expander(texts["model_expander"], expanded=False):
        col_left, col_right = st.columns([1.2, 2])

        with col_left:
            # 目标变量
            target_var = st.selectbox(
                texts["target_select"],
                options=list(indicator_map.keys()),
                format_func=lambda x: indicator_map[x],
                index=list(indicator_map.keys()).index("reading_score")
                if "reading_score" in indicator_map else 0
            )

            # 特征变量（排除目标变量）
            feature_options = [k for k in indicator_map.keys() if k != target_var]
            default_features = [
                "home_books", "teaching_hours_per_week", "guardian_a_education"
            ]
            default_features = [f for f in default_features if f in feature_options]

            feature_vars = st.multiselect(
                texts["feature_select"],
                options=feature_options,
                format_func=lambda x: indicator_map[x],
                default=default_features
            )

            # 模型选择列表
            model_options = [texts["lr_model"], texts["svr_model"],
                             texts["dt_model"], texts["rf_model"],
                             texts["gb_model"]]
            if XGB_AVAILABLE:
                model_options.append(texts["xgb_model"])
            else:
                st.caption(texts["xgb_not_installed"])

            selected_model_name = st.selectbox(
                texts["model_select"],
                options=model_options
            )

            # 测试集比例和随机种子（通用参数）
            test_size = st.slider(texts["test_size"], 0.1, 0.5, 0.2, 0.05)
            random_state = st.number_input(texts["random_state"], value=42, step=1)

            st.markdown("---")
            st.markdown("**模型超参数**")

            # 根据所选模型动态显示参数输入（使用 session_state 保留值）
            params = {}

            if selected_model_name in [texts["lr_model"], "Linear Regression"]:
                # 线性回归无关键超参数可调，可选正则化 C（但 sklearn 的 LinearRegression 无 C，这里跳过）
                st.info("线性回归无关键超参数。" if lang == "中文" else "Linear regression has no key hyperparameters to tune.")

            elif selected_model_name in [texts["svr_model"], "Support Vector Regression"]:
                C = st.number_input(texts["param_C"], value=1.0, min_value=0.01, step=0.1, format="%.2f")
                gamma = st.selectbox(texts["param_gamma"], options=["scale", "auto"], index=0)
                params = {"C": C, "gamma": gamma}

            elif selected_model_name in [texts["dt_model"], "Decision Tree Regressor"]:
                max_depth = st.slider(texts["param_max_depth"], 1, 30, 5)
                params = {"max_depth": max_depth}

            elif selected_model_name in [texts["rf_model"], "Random Forest Regressor"]:
                n_estimators = st.slider(texts["param_n_estimators"], 10, 300, 100, step=10)
                max_depth = st.slider(texts["param_max_depth"], 1, 30, 10)
                params = {"n_estimators": n_estimators, "max_depth": max_depth}

            elif selected_model_name in [texts["gb_model"], "Gradient Boosting Regressor"]:
                n_estimators = st.slider(texts["param_n_estimators"], 10, 300, 100, step=10)
                learning_rate = st.slider(texts["param_learning_rate"], 0.01, 0.5, 0.1, step=0.01)
                max_depth = st.slider(texts["param_max_depth"], 1, 15, 3)
                params = {"n_estimators": n_estimators, "learning_rate": learning_rate, "max_depth": max_depth}

            elif selected_model_name in [texts["xgb_model"], "XGBoost Regressor"]:
                n_estimators = st.slider(texts["param_n_estimators"], 10, 300, 100, step=10)
                learning_rate = st.slider(texts["param_learning_rate"], 0.01, 0.5, 0.1, step=0.01)
                max_depth = st.slider(texts["param_max_depth"], 1, 15, 6)
                subsample = st.slider(texts["param_subsample"], 0.5, 1.0, 0.8, step=0.05)
                params = {"n_estimators": n_estimators, "learning_rate": learning_rate,
                          "max_depth": max_depth, "subsample": subsample}

            train_clicked = st.button(texts["train_button"], type="primary")

        with col_right:
            if train_clicked:
                if not feature_vars:
                    st.warning(texts["no_features_warning"])
                else:
                    with st.spinner("训练模型中..." if lang == "中文" else "Training model..."):
                        # 数据预处理（对SVR和线性模型进行标准化）
                        scale = selected_model_name in [texts["svr_model"], texts["lr_model"],
                                                        "Support Vector Regression", "Linear Regression"]
                        X, y, _ = preprocess_for_model(df, target_var, feature_vars, scale_features=scale)

                        # 划分数据集
                        X_train, X_test, y_train, y_test = train_test_split(
                            X, y, test_size=test_size, random_state=int(random_state)
                        )

                        # 初始化模型
                        if selected_model_name in [texts["lr_model"], "Linear Regression"]:
                            model = LinearRegression()
                        elif selected_model_name in [texts["svr_model"], "Support Vector Regression"]:
                            model = SVR(**params)
                        elif selected_model_name in [texts["dt_model"], "Decision Tree Regressor"]:
                            model = DecisionTreeRegressor(random_state=int(random_state), **params)
                        elif selected_model_name in [texts["rf_model"], "Random Forest Regressor"]:
                            model = RandomForestRegressor(random_state=int(random_state), n_jobs=-1, **params)
                        elif selected_model_name in [texts["gb_model"], "Gradient Boosting Regressor"]:
                            model = GradientBoostingRegressor(random_state=int(random_state), **params)
                        elif selected_model_name in [texts["xgb_model"], "XGBoost Regressor"]:
                            model = XGBRegressor(random_state=int(random_state), **params)
                        else:
                            st.error("未知模型")
                            return

                        # 训练
                        model.fit(X_train, y_train)
                        y_pred = model.predict(X_test)

                        # 计算性能指标
                        r2 = r2_score(y_test, y_pred)
                        mae = mean_absolute_error(y_test, y_pred)
                        mse = mean_squared_error(y_test, y_pred)

                        # 展示指标
                        metric_cols = st.columns(3)
                        metric_cols[0].metric(texts["r2_score"], f"{r2:.3f}")
                        metric_cols[1].metric(texts["mae"], f"{mae:.3f}")
                        metric_cols[2].metric(texts["mse"], f"{mse:.3f}")

                        # 提取特征重要性或系数
                        importance_values = None
                        if hasattr(model, "feature_importances_"):
                            importance_values = model.feature_importances_
                            importance_label = "重要性" if lang == "中文" else "Importance"
                        elif hasattr(model, "coef_"):
                            # 线性模型、SVR（线性核）有系数，取绝对值作为重要性参考
                            if len(model.coef_.shape) == 1:
                                importance_values = np.abs(model.coef_)
                            else:
                                importance_values = np.abs(model.coef_[0])
                            importance_label = "系数绝对值" if lang == "中文" else "Coefficient Magnitude"
                        else:
                            st.info("该模型不提供特征重要性或系数。" if lang == "中文" else "This model does not provide feature importance or coefficients.")

                        if importance_values is not None:
                            imp_df = pd.DataFrame({
                                "Feature": [indicator_map[f] for f in feature_vars],
                                importance_label: importance_values
                            }).sort_values(importance_label, ascending=True)

                            fig_imp = px.bar(
                                imp_df,
                                x=importance_label,
                                y="Feature",
                                orientation="h",
                                title=texts["importance_plot"],
                                labels={
                                    importance_label: importance_label,
                                    "Feature": "特征" if lang == "中文" else "Feature"
                                }
                            )
                            fig_imp.update_layout(yaxis=dict(autorange="reversed"))
                            st.plotly_chart(fig_imp, use_container_width=True)
                            st.caption(texts["importance_note"])


if __name__ == "__main__":
    main()