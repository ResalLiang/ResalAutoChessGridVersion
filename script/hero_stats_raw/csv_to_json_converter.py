
import csv
import json
from collections import defaultdict

def convert_csv_to_godot_json(csv_path, json_path):
    faction_dict = defaultdict(dict)
    
    with open(csv_path, mode='r', encoding='utf-8') as csv_file:
        reader = csv.DictReader(csv_file)
        for row in reader:
            faction = row.pop('faction')
            hero_name = row.pop('hero_name')
            processed_data = {}
            for key, value in row.items():
                try:
                    processed_data[key] = int(value)
                except ValueError:
                    try:
                        processed_data[key] = float(value)
                    except ValueError:
                        processed_data[key] = value
            
            faction_dict[faction][hero_name] = processed_data
    
    # 添加indent参数实现格式化输出
    with open(json_path, 'w', encoding='utf-8') as json_file:
        json.dump(faction_dict, json_file, 
                 ensure_ascii=False, 
                 indent=2,  # 2空格缩进
                 separators=(',', ': '))  # 冒号后加空格

if __name__ == '__main__':
    convert_csv_to_godot_json('D:\LearningGodot\ResalAutoChess\script\hero_stats_raw\hero_stats.csv', 'D:\LearningGodot\ResalAutoChess\script\hero_stats_raw\hero_stats.json')
