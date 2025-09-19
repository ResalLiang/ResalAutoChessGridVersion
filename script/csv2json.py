import csv
import json
from collections import defaultdict

def csv_to_json(csv_file_path, json_file_path):
    """
    将CSV文件转换为JSON格式
    按faction分组，每个faction包含其下所有chess_name的数据
    """
    # 使用defaultdict来自动创建嵌套结构
    faction_data = defaultdict(dict)
    
    try:
        with open(csv_file_path, 'r', encoding='utf-8') as csvfile:
            # 自动检测CSV方言（分隔符等）
            csv_reader = csv.reader(csvfile)
            
            # 读取表头
            headers = next(csv_reader)
            print(f"检测到的列名: {headers}")
            
            # 确保至少有faction和chess_name两列
            if len(headers) < 2:
                raise ValueError("CSV文件至少需要包含faction和chess_name两列")
            
            # 处理数据行
            for row_num, row in enumerate(csv_reader, start=2):
                # 跳过空行
                if not row or all(cell.strip() == '' for cell in row):
                    continue
                
                # 补齐行数据（如果行数据不够）
                while len(row) < len(headers):
                    row.append('')
                
                faction = row[0].strip()
                chess_name = row[1].strip()
                
                # 跳过faction或chess_name为空的行
                if not faction or not chess_name:
                    print(f"跳过第{row_num}行: faction或chess_name为空")
                    continue
                
                # 构建该棋子的数据对象（从第3列开始）
                chess_data = {}
                has_data = False
                
                for i in range(2, len(headers)):
                    column_name = headers[i].strip()
                    cell_value = row[i].strip() if i < len(row) else ''
                    
                    # 如果单元格不为空，添加到数据中
                    if cell_value:
                        # 尝试转换数字类型
                        try:
                            # 尝试转换为整数
                            if '.' not in cell_value:
                                chess_data[column_name] = int(cell_value)
                            else:
                                # 尝试转换为浮点数
                                chess_data[column_name] = float(cell_value)
                        except ValueError:
                            # 保持字符串格式
                            chess_data[column_name] = cell_value
                        has_data = True
                
                # 只有当有数据时才添加到结果中
                if has_data:
                    faction_data[faction][chess_name] = chess_data
                    print(f"处理: {faction} -> {chess_name}")
                else:
                    print(f"跳过第{row_num}行: {faction}.{chess_name} (无有效数据)")
    
    except FileNotFoundError:
        print(f"错误: 找不到文件 '{csv_file_path}'")
        return False
    except Exception as e:
        print(f"读取CSV文件时出错: {e}")
        return False
    
    # 转换为普通字典（用于JSON序列化）
    result = dict(faction_data)
    
    # 写入JSON文件
    try:
        with open(json_file_path, 'w', encoding='utf-8') as jsonfile:
            json.dump(result, jsonfile, 
                     ensure_ascii=False,  # 支持中文字符
                     indent=2,           # 缩进2个空格
                     separators=(',', ': '))  # 自定义分隔符
        
        print(f"\n✅ 转换完成!")
        print(f"📁 输入文件: {csv_file_path}")
        print(f"📁 输出文件: {json_file_path}")
        print(f"📊 共处理 {len(result)} 个faction")
        
        # 显示统计信息
        total_chess = sum(len(chess_dict) for chess_dict in result.values())
        print(f"🎯 共处理 {total_chess} 个棋子")
        
        return True
        
    except Exception as e:
        print(f"写入JSON文件时出错: {e}")
        return False

def preview_json_structure(json_file_path, max_items=3):
    """
    预览JSON文件结构
    """
    try:
        with open(json_file_path, 'r', encoding='utf-8') as jsonfile:
            data = json.load(jsonfile)
        
        print(f"\n📋 JSON文件结构预览:")
        print("=" * 50)
        
        for faction_name, chess_dict in list(data.items())[:max_items]:
            print(f"🏛️  {faction_name}:")
            for chess_name, chess_data in list(chess_dict.items())[:2]:
                print(f"   ♟️  {chess_name}: {chess_data}")
            if len(chess_dict) > 2:
                print(f"   ... 还有 {len(chess_dict) - 2} 个棋子")
            print()
        
        if len(data) > max_items:
            print(f"... 还有 {len(data) - max_items} 个faction")
            
    except Exception as e:
        print(f"预览JSON文件时出错: {e}")

# 主程序
if __name__ == "__main__":
    # 配置文件路径
    csv_file_path = "s.csv"      # 输入的CSV文件路径
    json_file_path = "output.json"  # 输出的JSON文件路径
    
    print("🚀 开始CSV到JSON转换...")
    print("=" * 50)
    
    # 执行转换
    success = csv_to_json(csv_file_path, json_file_path)
    
    if success:
        # 预览结果
        preview_json_structure(json_file_path)
        
        print("\n" + "=" * 50)
        print("✨ 转换完成! 可以查看生成的JSON文件了。")
    else:
        print("❌ 转换失败，请检查错误信息。")

# 如果你想要自定义文件路径，可以取消下面的注释
# if __name__ == "__main__":
#     import sys
#     
#     if len(sys.argv) != 3:
#         print("使用方法: python script.py <输入CSV文件> <输出JSON文件>")
#         print("例如: python script.py data.csv output.json")
#     else:
#         csv_file = sys.argv[1]
#         json_file = sys.argv[2]
#         csv_to_json(csv_file, json_file)
