to_xlsx.R:用于将原本的Rdata数据转化为对应的excel文件
classify.py:用于分类合并有相同前缀的A5和。R5文件并保存
selectR5.py:用于选出没有对应A5文件的R5文件单独保存
date_preprocessing1.py:用于原始数据的处理，将其中所有的标识缺失值统一替换成缺失值‘ ’并保存
date_preprocessing2.py:用于利用热卡插补空缺值，并根据列中大部分数据类型选择插补的是连续值还是离散值
combine.py:用于物理合并路径下所有的文件，辅助作用，有需要可以使用
datapandas.py:读取 Excel 文件中所有工作表的数据，遍历各工作表每一行，根据 Level 列的值将 Variable 列的变量分别归类到数值型变量列表 num_vars 和类别型变量列表 cat_vars 中，然后将列表转换为字符串并保存到以工作表名命名的文本文件中，便于数据插补。
idchangename.py:读取 idcountry.md 文件获取国家名和对应数字编号的映射，遍历目录下的文件，根据文件名中的编号替换为国家名并按规则添加前缀重命名文件。
merge_excel.py:合并同类excel文件。
Normativechangename.py:文件标准化重命名。
partcomb.py:单独对同类文件的指定列进行合并。
Pie Chart.py:遍历指定文件夹下的所有文件，计算每个文件中特定分类型字段值的百分比，将结果按文件中的特定值（国家代码）存储，最后将所有结果保存到一个新的 Excel 文件中。
samecountrycombine.py:对同一国家的不同城市或地区的编号进行统一处理。
visualize_cloud.py:在云端运行的streamlit自助图表系统。
app.py:在云端运行的爬虫系统。
ai.html:小助理静态前端页面。
index.html:系统主页静态前端页面。
data-self.html:自主图表系统前端静态页面。
vue-charts.html:可视化分析前端静态页面。
education_dashboard.html:嵌入式可视化分析动态图表。