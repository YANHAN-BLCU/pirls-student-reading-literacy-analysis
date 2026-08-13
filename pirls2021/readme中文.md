User: 除代码字段外全部翻译
Kimi: 以下是翻译后的内容：

# Clust-learn

一个用于通过可解释的聚类分析从大规模高维混合类型数据中提取信息的Python包。

![clust-learn可视化](https://github.com/malgar/clust-learn/blob/v0.0.8/images/visualizations.png?raw=true)

<hr>

## 目录
1. [简介](#user-content-introduction)
2. [总体架构](#user-content-architecture)
3. [实现](#user-content-implementation)
4. [安装](#user-content-install)
5. [版本和许可证信息](#user-content-license)
6. [错误报告和未来工作](#user-content-future)
7. [用户指南 & API](#user-content-api)
	1. [数据处理](#user-content-module-preprocessing)
		1. [数据填充](#user-content-module-preprocessing-imputation)
		2. [异常值](#user-content-module-preprocessing-outliers)
	2. [降维](#user-content-module-dimensionality)
		- [降维类](#DimensionalityReduction_class)
		- [类方法](#DimensionalityReduction_class_methods)
	3. [聚类](#user-content-module-clustering)
		- [聚类类](#Clustering_class)
		- [类方法](#Clustering_class_methods)
	4. [分类器](#user-content-module-classifier)
		- [分类器类](#Classifier_class)
		- [类方法](#Classifier_class_methods)
8. [引用](#user-content-citing)

## 1. 简介

`clust-learn`使用户能够运行端到端的可解释聚类分析，以从大规模高维混合类型数据中提取信息，并通过提供一个框架来指导用户完成数据预处理、降维、聚类和分类过程。它旨在只需要很少的代码行，并且非常注重可解释性。

## 2. 总体架构

`clust-learn`被组织成四个模块，每个模块对应于[此处](#user-content-citing)介绍的方法论框架的一个组件：
* [数据预处理](https://github.com/malgar/clust-learn/tree/master/clearn/data_preprocessing)
* [降维](https://github.com/malgar/clust-learn/tree/master/clearn/dimensionality_reduction)
* [聚类](https://github.com/malgar/clust-learn/tree/master/clearn/clustering)
* [分类器](https://github.com/malgar/clust-learn/tree/master/clearn/classifier)

**图1**展示了包的布局，包括每个模块覆盖的功能、使用的降维技术、可用的可解释性策略，以及封装这些技术和策略的主要函数和类方法。

![clust-learn包结构](https://github.com/malgar/clust-learn/blob/master/images/package_structure.png?raw=true)

## 3. 实现

该包使用Python 3.9实现，并依赖于开源库。它在很大程度上依赖于[pandas](https://pandas.pydata.org/)和[scikit-learn](https://scikit-learn.org/stable/)。在[此处](https://github.com/malgar/clust-learn/blob/master/requirements.txt)阅读完整的需求列表。

它可以通过手动安装或从pip/PyPI安装（参见第4节[安装](#user-content-install)）。

## 4. 安装

该包在[PyPI](https://pypi.org/project/clust-learn/)上。只需运行以下命令：

```
pip install clust-learn
```

## 5. 版本和许可证信息

* 版本：0.2.7
* 作者：Miguel Alvarez-Garcia (malvarez.statistics@gmail.com)
* 许可证：GPLv3

## 6. 错误报告和未来工作

请通过在[此处](https://github.com/malgar/clust-learn/issues)创建新问题来报告错误和提出功能请求。

## 7. 用户指南 & API

`clust-learn`被组织成四个模块：

1. 数据预处理
2. 降维
3. 聚类
4. 分类器

**图1**展示了包的布局，包括每个模块覆盖的功能、使用的降维技术、可用的可解释性策略，以及封装这些技术和策略的主要函数和类方法。

这四个模块被设计成按顺序使用，以确保结果的健壮性和可解释性。然而，它们是独立的，可以根据不同的使用场景单独使用。

### 7.i. 数据预处理

数据预处理是在原始数据用于分析之前对其执行的一系列操作和转换任务。尽管数据质量对于获得健壮和可靠的结果至关重要，但现实世界的数据通常是不完整的、嘈杂的或不一致的。因此，数据预处理是任何分析研究的关键步骤。

### 7.i.a. 数据填充

#### compute_missing()
```
compute_missing(df, normalize=True)
```

计算每列缺失值的百分比/计数。

**参数**

- `df` : `pandas.DataFrame`
- `normalize` : `布尔值`, 默认=`True`

**返回**

- `missing_df` : `pandas.DataFrame`
	- 包含每列缺失值百分比/计数的DataFrame。

#### missing_values_heatmap()
```
missing_values_heatmap(df, output_path=None, savefig_kws=None)
```

绘制热图以可视化缺失值（浅色表示缺失值）。

**参数**

- `df` : `pandas.DataFrame`
   - 包含数据的DataFrame。
- `output_path` : `字符串`, 默认=`None`
   - 保存图像的路径。
- `savefig_kws` : `字典`, 默认=`None`
   - 保存图像的选项。

#### impute_missing_values()
```
impute_missing_values(df, num_vars, cat_vars, num_pair_kws=None, mixed_pair_kws=None, cat_pair_kws=None, graph_thres=0.05, k=8, max_missing_thres=0.33)
```

此函数按照以下步骤填充缺失值：
1. 基于强相关变量的一对一模型填充缺失值。
2. 基于互信息得分高于预定义阈值的变量对构建的无向图*G=(V,E)*的连通分量来确定的聚类的热甲板填充，其中*V*是变量集，*E*是变量对。
3. 丢弃缺失值比例超过预定义阈值的记录，以确保热甲板填充的质量。
4. 考虑所有变量，对剩余的缺失值进行热甲板填充。

**参数**

- `df` : `pandas.DataFrame`
	- 包含潜在缺失值的数据框。
- `num_vars` : `字符串`, `列表`, `pandas.Series`，或`numpy.array`
	- 数值变量名。
- `cat_vars` : `字符串`, `列表`, `pandas.Series`，或`numpy.array`
	- 分类变量名。
- `{num,mixed,cat}_pair_kws` : `字典`, 默认=`None`
	- 传递给一对一模型填充计算填充对的其他关键字参数，具体如下：
		- 对于数值对，`corr_thres`和`method`用于设置相关系数阈值和方法。默认情况下，`corr_thres=0.7`和`method='pearson'`。
		- 对于混合类型对，`np2_thres`用于设置偏η平方的阈值，以0.14为默认值。
		- 对于分类对，`mi_thres`用于设置互信息分数的阈值。默认情况下，`mi_thres=0.6`。
- `graph_thres` : `浮点数`, 默认=0.05
	- 基于互信息得分确定两个变量是否相似的阈值，从而成为派生变量聚类的图的边。
- `k` : `整数`, 默认=8
	- 热甲板填充中考虑的邻居数量。
- `max_missing_thres`: `浮点数`, 默认=0.33
	- 在最终的通用热甲板填充之前，允许每个观测值的最大缺失值比例——参见缺失值填充方法的第3步。

**返回**

- `final_pairs` : `pandas.DataFrame`
	- 包含高度相关的变量对的DataFrame（`var1`：需要填充值的变量；`var2`：用于模型填充的独立变量），以及变量`var1`和`var2`的缺失值比例。

#### plot_imputation_distribution_assessment()
```
plot_imputation_distribution_assessment(df_prior, df_posterior, imputed_vars, sample_frac=1.0, prior_kws=None, posterior_kws=None, output_path=None, savefig_kws=None)
```

绘制每个填充变量在填充前后的分布比较图。

**参数**

- `df_prior` : `pandas.DataFrame`
	- 填充前的DataFrame。
- `df_posterior` : `pandas.DataFrame`
	- 填充后的DataFrame。
- `imputed_vars` : `列表`
	- 包含填充变量的列表。
- `sample_frac` : 浮点数, 默认=1.0
	- 如果小于1，则对每对变量进行随机抽样并绘制。
- `{prior,posterior}_kws` : `字典`, 默认=`None`
	- 传递给[kdeplot](https://seaborn.pydata.org/generated/seaborn.kdeplot.html)的其他关键字参数。
- `output_path` : `字符串`, 默认=`None`
	- 保存图像的路径。
- `savefig_kws` : `字典`, 默认=`None`
	- 保存图像的选项。

### 7.i.b. 异常值

#### remove_outliers()
```
remove_outliers(df, variables, iforest_kws=None)
```

使用[隔离森林算法](https://scikit-learn.org/stable/modules/generated/sklearn.ensemble.IsolationForest.html)去除异常值。

**参数**

- `df` : `pandas.DataFrame`
	- 包含数据的DataFrame。
- `variables` : `列表`
	- 可能存在异常值的变量。
- `iforest_kws` : `字典`, 默认=`None`
	- 隔离森林算法的超参数。

**返回**

- df_inliers : `pandas.DataFrame`
	- 包含内点（即非异常值的观测值）的DataFrame。
- df_outliers : `pandas.DataFrame`
	- 包含异常值的DataFrame。

### 7.ii. 降维

该模块的所有功能都封装在`DimensionalityReduction`类中，以便原始数据、所用模型的实例以及任何其他相关信息都能自我维护并始终可访问。

#### DimensionalityReduction类
```
dr = DimensionalityReduction(df, num_vars=None, cat_vars=None, num_algorithm='pca', cat_algorithm='mca', num_kwargs=None, cat_kwargs=None)
```

| 参数 | 类型 | 描述 |
|:-|:-|:-|
| `df` | `pandas.DataFrame` | 包含原始变量的原始数据表 |
| `num_vars` | `字符串`, `列表`, `pandas.Series`，或`numpy.array` | 数值变量名 |
| `cat_vars` | `字符串`, `列表`, `pandas.Series`，或`numpy.array` | 分类变量名 |
| `num_algorithm` | `字符串` | 用于数值变量降维的算法。默认使用PCA。当前版本还支持SPCA |
| `cat_algorithm` | `字符串` | 用于分类变量降维的算法。默认使用MCA。当前版本不支持其他算法 |
| `num_kwargs` | `字典` | 传递给数值变量所用模型的其他关键字参数 |
| `cat_kwargs` | `字典` | 传递给分类变量所用模型的其他关键字参数 |
| **属性** | **类型** | **描述** |
| `n_components_` | `整数` | 提取的最终组件数 |
| `min_explained_variance_ratio_` | `浮点数` | 最小解释方差比率。默认为0.5 |
| `num_trans_` | `pandas.DataFrame` | 从数值变量中提取的组件 |
| `cat_trans_` | `pandas.DataFrame` | 从分类变量中提取的组件 |
| `num_components_` | `列表` | 分配给从数值变量中提取的组件的名称列表 |
| `cat_components_` | `列表` | 分配给从分类变量中提取的组件的名称列表 |
| `pca_` | `sklearn.decomposition.PCA` | 用于加速某些计算和比较目的的PCA实例 |

#### DimensionalityReduction类方法

##### transform()
[源码](https://github.com/malgar/clust-learn/blob/f0744a15823c2b7c6b49c278d08d708d05df952a/clearn/dimensionality_reduction/dimensionality_reduction.py#L79)

```
transform(self, n_components=None, min_explained_variance_ratio=0.5)
```

将DataFrame df转换为低维空间。

##### num_main_contributors()
[源码](https://github.com/malgar/clust-learn/blob/f0744a15823c2b7c6b49c278d08d708d05df952a/clearn/dimensionality_reduction/dimensionality_reduction.py#L191)

```
num_main_contributors(self, thres=0.5, n_contributors=None, dim_idx=None, component_description=None, col_description=None, output_path=None)
```

计算与派生变量（以皮尔逊相关系数衡量）关系最强的原始数值变量。

##### cat_main_contributors()
[源码](https://github.com/malgar/clust-learn/blob/f0744a15823c2b7c6b49c278d08d708d05df952a/clearn/dimensionality_reduction/dimensionality_reduction.py#L225)

```
cat_main_contributors(self, thres=0.14, n_contributors=None, dim_idx=None, component_description=None, col_description=None, output_path=None)
```

计算与派生变量（以相关比率衡量）关系最强的原始分类变量。

##### cat_main_contributors_stats()
[源码](https://github.com/malgar/clust-learn/blob/f0744a15823c2b7c6b49c278d08d708d05df952a/clearn/dimensionality_reduction/dimensionality_reduction.py#L259)

```
cat_main_contributors_stats(self, thres=0.14, n_contributors=None, dim_idx=None, output_path=None)
```

对于每个分类变量的值，计算与其（基于相关比率）强烈相关的派生变量的均值和标准差。

##### plot_num_explained_variance()
[源码](https://github.com/malgar/clust-learn/blob/f0744a15823c2b7c6b49c278d08d708d05df952a/clearn/dimensionality_reduction/dimensionality_reduction.py#L286)

```
plot_num_explained_variance(self, thres=0.5, plots='all', output_path=None, savefig_kws=None)
```

绘制数值变量的解释方差（比率、累积和/或归一化）。

##### plot_cat_explained_variance()
[源码](https://github.com/malgar/clust-learn/blob/f0744a15823c2b7c6b49c278d08d708d05df952a/clearn/dimensionality_reduction/dimensionality_reduction.py#L303)

```
plot_cat_explained_variance(self, thres=0.5, plots='all', output_path=None, savefig_kws=None)
```

绘制分类变量的解释方差（比率、累积和/或归一化）。

##### plot_num_main_contributors()
[源码](https://github.com/malgar/clust-learn/blob/f0744a15823c2b7c6b49c278d08d708d05df952a/clearn/dimensionality_reduction/dimensionality_reduction.py#L321)

```
plot_num_main_contributors(self, thres=0.5, n_contributors=5, dim_idx=None, output_path=None, savefig_kws=None)
```

绘制每个派生变量的主要贡献者（与派生变量关系最强的原始变量）。

##### plot_cat_main_contributor_distribution()
[源码](https://github.com/malgar/clust-learn/blob/f0744a15823c2b7c6b49c278d08d708d05df952a/clearn/dimensionality_reduction/dimensionality_reduction.py#L344)

```
plot_cat_main_contributor_distribution(self, thres=0.14, n_contributors=None, dim_idx=None, output_path=None, savefig_kws=None)
```

绘制每个派生变量的主要贡献者（与派生变量关系最强的原始变量）。

### 7.iii. 聚类

`Clustering`类封装了该模块的所有功能，并存储数据、所用算法的实例以及其他相关信息，以便始终可访问。

#### Clustering类
```
cl = Clustering(df, algorithms='kmeans', normalize=False)
```

| 参数 | 类型 | 描述 |
|:-|:-|:-|
| `df` | `pandas.DataFrame` | 包含要聚类的数据的数据框 |
| `algorithms` | 实例或实例列表 | 要用于聚类的算法实例。它们必须实现`fit`和`set_params`方法 |
| `normalize` | `布尔值` | 是否对数据进行归一化以公平比较变量。如果事先进行了降维，则不应进行归一化 |
| **属性** | **类型** | **描述** |
| `dimensions_` | `列表` | 输入数据框的列列表 |
| `instances_` | `字典` | 算法名和其实例的键值对 |
| `metric_` | `字符串` | 使用的聚类验证指标。可用四个指标：['inertia', 'davies_bouldin_score', 'silhouette_score',  'calinski_harabasz_score'] |
| `optimal_config_` | `元组` | 包含聚类的最优配置的元组，包含算法名、聚类数和所选验证指标的值 |
| `scores_` | `字典` | 算法名和所选验证指标值列表的键值对，用于聚类范围 |

#### Clustering类方法

##### compute_clusters()
[源码](https://github.com/malgar/clust-learn/blob/be4a2238670af01023bd419a0f8adaa7f9cee9f6/clearn/clustering/clustering.py#L117)

```
compute_clusters(self, n_clusters=None, metric='inertia', max_clusters=10, prefix=None, weights=None)
```

计算聚类。
如果在类构造函数中传递了多个算法，首先，基于传递给该方法的指标为每个算法计算最优聚类数。其次，选择在相应最优聚类数下表现最佳的算法。
因此，结果展示了基于上述标准计算的聚类，使用表现最佳的算法。

##### describe_clusters()
[源码](https://github.com/malgar/clust-learn/blob/be4a2238670af01023bd419a0f8adaa7f9cee9f6/clearn/clustering/clustering.py#L182)

```
describe_clusters(self, df_ext=None, variables=None, cluster_filter=None, statistics=['mean', 'median', 'std'], output_path=None)
```

基于内部或外部连续变量描述聚类。
对于分类变量，请使用[`describe_clusters_cat()`](#describe_clusters_cat)。

##### describe_clusters_cat()
[源码](https://github.com/malgar/clust-learn/blob/be4a2238670af01023bd419a0f8adaa7f9cee9f6/clearn/clustering/clustering.py#L237)

```
describe_clusters_cat(self, cat_array, cat_name, order=None, normalize=False, use_weights=False, output_path=None)
```

基于外部分类变量描述聚类。结果是一个列联表。
对于连续变量，请使用[`describe_clusters()`](#describe_clusters)。

##### compare_cluster_means_to_global_means()
[源码](https://github.com/malgar/clust-learn/blob/be4a2238670af01023bd419a0f8adaa7f9cee9f6/clearn/clustering/clustering.py#L276)

```
compare_cluster_means_to_global_means(self, df_original=None, output_path=None)
```

对于每个聚类和每个内部变量，聚类内均值与全局均值的相对差异。

##### anova_tests()
[源码](https://github.com/malgar/clust-learn/blob/be4a2238670af01023bd419a0f8adaa7f9cee9f6/clearn/clustering/clustering.py#L303)

```
anova_tests(self, df_test=None, vars_test=None, cluster_filter=None, output_path=None)
```

对给定的一组连续变量（内部或外部）进行方差分析测试，以检验其与聚类的依赖关系。

##### chi2_test()
[源码](https://github.com/malgar/clust-learn/blob/be4a2238670af01023bd419a0f8adaa7f9cee9f6/clearn/clustering/clustering.py#L360)

```
chi2_test(self, cat_array)
```

对给定的分类变量进行卡方检验，以检验其与聚类的依赖关系。

##### plot_score_comparison()
[源码](https://github.com/malgar/clust-learn/blob/be4a2238670af01023bd419a0f8adaa7f9cee9f6/clearn/clustering/clustering.py#L379)

```
plot_score_comparison(self, output_path=None, savefig_kws=None)
```

绘制不同聚类算法性能的比较图。

##### plot_optimal_components_normalized()
[源码](https://github.com/malgar/clust-learn/blob/be4a2238670af01023bd419a0f8adaa7f9cee9f6/clearn/clustering/clustering.py#L400)

```
plot_optimal_components_normalized(self, output_path=None, savefig_kws=None)
```

绘制用于计算最优聚类数的归一化曲线。

##### plot_clustercount()
[源码](https://github.com/malgar/clust-learn/blob/be4a2238670af01023bd419a0f8adaa7f9cee9f6/clearn/clustering/clustering.py#L419)

```
plot_clustercount(self, use_weights=False, output_path=None, savefig_kws=None)
```

绘制聚类计数的条形图。

##### plot_cluster_means_to_global_means_comparison()
[源码](https://github.com/malgar/clust-learn/blob/be4a2238670af01023bd419a0f8adaa7f9cee9f6/clearn/clustering/clustering.py#L432)

```
plot_cluster_means_to_global_means_comparison(self, use_weights= False, df_original=None, xlabel=None, ylabel=None,
                                              levels=[-0.50, -0.32, -0.17, -0.05, 0.05, 0.17, 0.32, 0.50],
                                              output_path=None, savefig_kws=None)
```

绘制用于计算最优聚类数的归一化曲线。

##### plot_distribution_comparison_by_cluster()
[源码](https://github.com/malgar/clust-learn/blob/be4a2238670af01023bd419a0f8adaa7f9cee9f6/clearn/clustering/clustering.py#L469)

```
plot_distribution_comparison_by_cluster(self, df_ext=None, xlabel=None, ylabel=None, output_path=None, savefig_kws=None)
```

绘制每个聚类和感兴趣的连续变量的小提琴图，以理解它们在分布上的差异。

##### plot_clusters_2D()
[源码](https://github.com/malgar/clust-learn/blob/be4a2238670af01023bd419a0f8adaa7f9cee9f6/clearn/clustering/clustering.py#L498)

```
plot_clusters_2D(self, coor1, coor2, use_weights=False, style_kwargs=dict(), output_path=None, savefig_kws=None)
```

绘制两个2D图：
	 - 一个按分类变量`hue`样式化的散点图。
	 - 一个2D图比较聚类中心，可选地比较密度区域。

##### plot_cat_distribution_by_cluster()
[源码](https://github.com/malgar/clust-learn/blob/be4a2238670af01023bd419a0f8adaa7f9cee9f6/clearn/clustering/clustering.py#L545)

```
plot_cat_distribution_by_cluster(self, cat_array, cat_label, order=None, cluster_label=None, use_weights=False, output_path=None, savefig_kws=None)
```

绘制聚类与分类变量的相对列联表作为堆叠条形图。

### 7.iv. 分类器

该模块的功能封装在`Classifier`类中，该类还负责存储原始数据、所用模型的实例以及其他相关信息。

#### Classifier类
```
classifier = Classifier(df, predictor_cols, target, num_cols=None, cat_cols=None)
```

| 参数 | 类型 | 描述 |
|:-|:-|:-|
| `df` | `pandas.DataFrame` | 包含数据的数据框 |
| `predictor_cols` | `字符串`列表 | 要用作预测变量的列列表 |
| `target` | `numpy.array`或`列表` | 目标变量的值 |
| `num_cols` | `列表` | 预测变量中的数值列 |
| `cat_cols` | `列表` | 预测变量中的分类列 |
| **属性** | **类型** | **描述** |
| `filtered_features_` | `列表` | 输入数据框的列列表 |
| `labels_` | `列表` | 类标签列表 |
| `model_` | `sklearn.base`中的`TransformerMixin`和`BaseEstimator`的实例 | 训练好的分类器 |
| `X_train_` | `numpy.array` | 预测变量的训练集 |
| `X_test_` | `numpy.array` | 预测变量的测试集 |
| `y_train_` | `numpy.array` | 目标变量的训练集 |
| `y_test_` | `numpy.array` | 目标变量的测试集 |
| `grid_result_` | `sklearn.model_selection.GridSearchCV` | 超参数调整的拟合估计器实例 |

#### Classifier类方法

##### train_model()
[源码](https://github.com/malgar/clust-learn/blob/5826ef273eb876c961eab7fa4eacb31caff25ef0/clearn/classifier/classifier.py#L52)

```
train_model(self, model=None, feature_selection=True, features_to_keep=[],
			feature_selection_model=None, hyperparameter_tuning=False, param_grid=None,
			train_size=0.8, balance_classes=False)
```

此方法训练一个分类模型。

默认使用XGBoost，但也可以使用任何其他估计器（`scikit-learn.Estimator`的实例）。

构建过程包括三个主要步骤：
 - 特征选择（可选）
 
通过分类模型和SHAP值去除高度相关的变量，以确定保留哪些特征，并对剩余特征进行基于交叉验证的递归特征消除（RFECV）。

 - 超参数调整（可选）
 
运行带有交叉验证的网格搜索进行超参数调整。**注意**必须传递参数网格。

 - 模型训练
 
使用选定的特征和超参数训练分类模型。默认情况下，将训练一个XGBoost分类器。
   
**注意**超参数调整和模型训练都在训练集上进行。训练集和测试集的划分使用`sklearn.model_selection.train_test_split`。

##### hyperparameter_tuning_metrics()
[源码](https://github.com/malgar/clust-learn/blob/5826ef273eb876c961eab7fa4eacb31caff25ef0/clearn/classifier/classifier.py#L134)

```
hyperparameter_tuning_metrics(self, output_path=None)
```

此方法返回超参数调整中每个超参数组合的交叉验证运行的平均值和标准差。

##### confusion_matrix()
[源码](https://github.com/malgar/clust-learn/blob/5826ef273eb876c961eab7fa4eacb31caff25ef0/clearn/classifier/classifier.py#L154)

```
confusion_matrix(self, test=True, sum_stats=True, output_path=None)
```

此方法返回分类模型的混淆矩阵。

##### classification_report()
[源码](https://github.com/malgar/clust-learn/blob/5826ef273eb876c961eab7fa4eacb31caff25ef0/clearn/classifier/classifier.py#L195)

```
classification_report(self, test=True, output_path=None)
```

此方法以`pandas.DataFrame`格式返回`sklearn.metrics.classification_report`。

该报告包含每个类别的内部指标（精确度、召回率和F1分数），以及全局准确率，以及三个内部指标的宏观平均值和加权平均值。

##### plot_shap_importances()
[源码](https://github.com/malgar/clust-learn/blob/5826ef273eb876c961eab7fa4eacb31caff25ef0/clearn/classifier/classifier.py#L225)

```
plot_shap_importances(self, n_top=7, output_path=None, savefig_kws=None)
```

绘制SHAP重要性值，计算为所有类别绝对SHAP值的组合平均值。

##### plot_shap_importances_beeswarm()
[源码](https://github.com/malgar/clust-learn/blob/5826ef273eb876c961eab7fa4eacb31caff25ef0/clearn/classifier/classifier.py#L241)

```
plot_shap_importances_beeswarm(self, class_id, class_name=None, n_top=10, output_path=None, savefig_kws=None)
```

绘制目标变量特定类别的SHAP值摘要。这使用[SHAP小提琴图](https://shap.readthedocs.io/en/latest/example_notebooks/api_examples/plots/beeswarm.html)。

##### plot_confusion_matrix()
[源码](https://github.com/malgar/clust-learn/blob/5826ef273eb876c961eab7fa4eacb31caff25ef0/clearn/classifier/classifier.py#L260)

```
plot_confusion_matrix(self, test=True, sum_stats=True, output_path=None, savefig_kws=None)
```

此函数使用Seaborn热图可视化制作一个漂亮的sklearn混淆矩阵cf图。

##### plot_roc_curves()
[源码](https://github.com/malgar/clust-learn/blob/5826ef273eb876c961eab7fa4eacb31caff25ef0/clearn/classifier/classifier.py#L280)

```
 plot_roc_curves(self, test=True, labels=None, output_path=None, savefig_kws=None)
```

绘制每个类别的ROC曲线。

## 8. 引用

Alvarez-Garcia, M., Ibar-Alonso, R., Arenas-Parra, M. (2024). 一种全面的可解释聚类分析框架。 _信息科学，663_ ，120282，https://doi.org/10.1016/j.ins.2024.120282
