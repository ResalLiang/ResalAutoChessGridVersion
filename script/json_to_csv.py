import json
import csv
import sys
from collections import defaultdict

def json_to_csv(json_file_path, csv_file_path):
	"""
	将嵌套JSON字典转换为CSV格式
	
	参数:
		json_file_path: JSON文件路径
		csv_file_path: 输出的CSV文件路径
	"""
	
	# 读取JSON文件
	try:
		with open(json_file_path, 'r', encoding='utf-8') as json_file:
			data = json.load(json_file)
	except Exception as e:
		print(f"读取JSON文件失败: {e}")
		return
	
	# 收集所有可能的属性字段
	all_fields = set(['faction', 'chess_name'])
	
	# 第一遍遍历：收集所有可能的属性字段
	for faction, chess_dict in data.items():
		for chess_name, attributes in chess_dict.items():
			if isinstance(attributes, dict):
				all_fields.update(attributes.keys())
	
	# 将字段转换为有序列表
	field_list = ['faction', 'chess_name'] + [field for field in sorted(all_fields) if field not in ['faction', 'chess_name']]
	
	# 写入CSV文件
	try:
		with open(csv_file_path, 'w', newline='', encoding='utf-8') as csv_file:
			writer = csv.DictWriter(csv_file, fieldnames=field_list)
			
			# 写入表头
			writer.writeheader()
			
			# 第二遍遍历：写入数据行
			for faction, chess_dict in data.items():
				for chess_name, attributes in chess_dict.items():
					row_data = {
						'faction': faction,
						'chess_name': chess_name
					}
					
					# 添加属性数据
					if isinstance(attributes, dict):
						for key, value in attributes.items():
							row_data[key] = value
					
					writer.writerow(row_data)
		
		print(f"转换完成！CSV文件已保存至: {csv_file_path}")
		print(f"共找到 {len(field_list)} 个属性字段")
		
	except Exception as e:
		print(f"写入CSV文件失败: {e}")

def main():
	# 使用方法说明
	if len(sys.argv) != 3:
		print("使用方法: python json_to_csv.py <输入json文件> <输出csv文件>")
		print("示例: python json_to_csv.py chess_data.json chess_data.csv")
		return
	
	input_file = sys.argv[1]
	output_file = sys.argv[2]
	
	# 执行转换
	json_to_csv(input_file, output_file)

# 如果直接运行脚本，使用示例
if __name__ == "__main__":
	# 如果没有提供命令行参数，可以使用硬编码的路径
	if len(sys.argv) == 1:
		# 在这里修改为您的实际文件路径
		input_json = "input.json"
		output_csv = "output.csv"
		json_to_csv(input_json, output_csv)
	else:
		main()