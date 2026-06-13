import pdfplumber
import os

pdf_path = r'e:\Flutter_project\test1\flutter_application_1\.trae\documents\BDL note4.pdf'

with pdfplumber.open(pdf_path) as pdf:
    print(f'总页数: {len(pdf.pages)}')
    for i, page in enumerate(pdf.pages):
        print(f'\n=== 第 {i+1} 页 ===')
        print(f'页面尺寸: {page.width} x {page.height}')

        text = page.extract_text()
        if text:
            print(f'--- 文本内容 ---')
            print(text)
        else:
            print('(无直接可提取的文本)')

        tables = page.extract_tables()
        if tables:
            print(f'--- 发现 {len(tables)} 个表格 ---')
            for j, table in enumerate(tables):
                print(f'表格 {j+1}:')
                for row in table:
                    print(row)

        images = page.images
        if images:
            print(f'--- 发现 {len(images)} 个图像 ---')
            for img in images:
                print(f'  图像: {img["width"]}x{img["height"]}')
