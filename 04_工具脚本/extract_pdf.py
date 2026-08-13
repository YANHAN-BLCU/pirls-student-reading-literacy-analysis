from pypdf import PdfReader

# 打开PDF文件
pdf_path = r"E:\BLCU\DC24\二期\全球儿童阅读态度对阅读素养的影响研究——基于PIRLS_2021面板数据分析_胡晓艳.pdf"
reader = PdfReader(pdf_path)

# 提取前15页的文本
text = ""
for i in range(min(15, len(reader.pages))):
    page = reader.pages[i]
    text += f"\n--- 第{i+1}页 ---\n"
    text += page.extract_text()

# 输出文本
print(text)

# 也保存到文件
with open(r"E:\BLCU\DC24\论文内容.txt", "w", encoding="utf-8") as f:
    f.write(text)

print("\n\n文本已保存到论文内容.txt")

