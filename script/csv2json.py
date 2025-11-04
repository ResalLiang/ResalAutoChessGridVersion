import csv
import json
from collections import defaultdict

def csv_to_json(csv_file_path, json_file_path):
    """
    将CSV文件转换为JSON格式
    第一级key是faction，第二级key是chess_name，其他列在第三级
    """
    # 使用defaultdict来自动创建嵌套结构
    faction_data = defaultdict(dict)
    
    try:
        with open(csv_file_path, 'r', encoding='utf-8') as csvfile:
            # 读取CSV文件
            csv_reader = csv.reader(csvfile)
            
            # 读取表头
            headers = [header.strip() for header in next(csv_reader)]
            print(f"检测到的列名: {headers}")
            
            # 确保有足够的列
            if len(headers) < 3:
                raise ValueError("CSV文件需要至少包含faction、chess_name和其他数据列")
            
            # 重新映射表头：假设第一列是faction，第二列是chess_name，其他列是数据
            faction_col = 0  # 第一列是faction
            chess_name_col = 1  # 第二列是chess_name
            data_start_col = 2  # 从第三列开始是数据
            
            print(f"识别列结构:")
            print(f"  - faction列: 第{faction_col + 1}列 ('{headers[faction_col]}')")
            print(f"  - chess_name列: 第{chess_name_col + 1}列 ('{headers[chess_name_col]}')")
            print(f"  - 数据列: 第{data_start_col + 1}列到第{len(headers)}列")
            
            # 处理数据行
            for row_num, row in enumerate(csv_reader, start=2):
                # 跳过空行
                if not row or all(cell.strip() == '' for cell in row):
                    continue
                
                # 补齐行数据（如果行数据不够）
                while len(row) < len(headers):
                    row.append('')
                
                # 提取faction和chess_name
                faction = row[faction_col].strip()
                chess_name = row[chess_name_col].strip()
                
                # 跳过faction或chess_name为空的行
                if not faction or not chess_name:
                    print(f"跳过第{row_num}行: faction或chess_name为空")
                    continue
                
                # 构建该棋子的数据对象（从数据列开始）
                chess_data = {}
                
                for i in range(data_start_col, len(headers)):
                    if i < len(headers):
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
                
                # 添加到结果中（即使chess_data为空也添加）
                faction_data[faction][chess_name] = chess_data
                print(f"处理: {faction} -> {chess_name} -> {chess_data}")
    
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

def preview_json_structure(json_file_path, max_factions=2, max_chess=2):
    """
    预览JSON文件结构
    """
    try:
        with open(json_file_path, 'r', encoding='utf-8') as jsonfile:
            data = json.load(jsonfile)
        
        print(f"\n📋 JSON文件结构预览:")
        print("=" * 50)
        
        faction_count = 0
        for faction_name, chess_dict in data.items():
            if faction_count >= max_factions:
                break
                
            print(f"🏛️  第一级 - faction: '{faction_name}'")
            chess_count = 0
            
            for chess_name, chess_data in chess_dict.items():
                if chess_count >= max_chess:
                    break
                    
                print(f"   ♟️  第二级 - chess_name: '{chess_name}'")
                if chess_data:
                    for key, value in chess_data.items():
                        print(f"      📊 第三级 - {key}: {value}")
                else:
                    print(f"      ⚠ 第三级: 无额外数据")
                print()
                chess_count += 1
            
            if len(chess_dict) > max_chess:
                print(f"   ... 还有 {len(chess_dict) - max_chess} 个棋子")
            print()
            faction_count += 1
        
        if len(data) > max_factions:
            print(f"... 还有 {len(data) - max_factions} 个faction")
            
    except Exception as e:
        print(f"预览JSON文件时出错: {e}")

def validate_json_structure(json_file_path):
    """
    验证JSON结构是否符合要求
    """
    try:
        with open(json_file_path, 'r', encoding='utf-8') as jsonfile:
            data = json.load(jsonfile)
        
        print(f"\n🔍 验证JSON结构:")
        print("=" * 30)
        
        structure_ok = True
        total_factions = len(data)
        total_chess = 0
        
        for faction, chess_dict in data.items():
            print(f"✓ 第一级: faction = '{faction}'")
            total_chess += len(chess_dict)
            
            for chess_name, chess_data in chess_dict.items():
                print(f"  ✓ 第二级: chess_name = '{chess_name}'")
                
                # 检查第三级是否包含其他列
                if chess_data:
                    for key, value in chess_data.items():
                        print(f"    ✓ 第三级: {key} = {value}")
                else:
                    print(f"    ⚠ 第三级: 无额外数据")
        
        print(f"\n📊 统计:")
        print(f"  - 总faction数: {total_factions}")
        print(f"  - 总棋子数: {total_chess}")
        print(f"✅ JSON结构验证通过!")
        return True
        
    except Exception as e:
        print(f"❌ JSON结构验证失败: {e}")
        return False

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
        
        # 验证结构
        validate_json_structure(json_file_path)
        
        print("\n" + "=" * 50)
        print("✨ 转换完成! 可以查看生成的JSON文件了。")
        
        # 显示最终的文件结构说明
        print(f"\n📁 最终JSON结构:")
        print("第一级: faction (派系)")
        print("第二级: chess_name (棋子名称)") 
        print("第三级: 其他所有数据列")
        
    else:
        print("❌ 转换失败，请检查错误信息。")

# 命令行用法
if __name__ == "__main__":
    import sys
    
    if len(sys.argv) == 3:
        csv_file = sys.argv[1]
        json_file = sys.argv[2]
        csv_to_json(csv_file, json_file)
    elif len(sys.argv) > 1:
        print("使用方法: python script.py <输入CSV文件> <输出JSON文件>")
        print("例如: python script.py data.csv output.json")
