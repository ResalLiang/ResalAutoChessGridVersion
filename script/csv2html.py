import pandas as pd
import os

def csv_to_wiki_html_table(csv_file_path, output_txt_path):
    """
    生成专门用于Wiki的HTML表格代码（仅表格部分），按照指定列顺序，防止文本换行
    """
    
    # 读取CSV文件
    df = pd.read_csv(csv_file_path)
    
    # 定义指定的列顺序
    specified_columns = [
        "faction", "chess_name", "rarity", "role", "upgrade_chess",
        "max_health", "max_mana", "speed", "armor", "target_priority",
        "attack_range", "attack_speed", "melee_attack_damage", "passive_ability",
        "skill_description", "skill_name", "spell_target_priority",
        "ranged_attack_damage", "decline_ratio", "projectile_penetration"
    ]
    
    # 检查CSV文件中是否包含所有指定列
    missing_columns = [col for col in specified_columns if col not in df.columns]
    if missing_columns:
        print(f"警告: CSV文件中缺少以下列: {missing_columns}")
        print("将使用CSV文件中的现有列")
        # 使用CSV中存在的列，按照指定顺序排列
        available_columns = [col for col in specified_columns if col in df.columns]
        # 添加CSV中其他不在指定顺序中的列
        other_columns = [col for col in df.columns if col not in specified_columns]
        final_columns = available_columns + other_columns
    else:
        final_columns = specified_columns
    
    # 重新排列DataFrame的列顺序
    df = df[final_columns]
    
    # 定义需要添加Wiki链接的列索引（0-based）
    wiki_link_columns = [0, 1, 4]  # faction, chess_name, upgrade_chess
    
    # 开始生成Wiki专用的HTML表格代码
    html_content = '<table border="1" style="border-collapse: collapse; width: 100%; font-size: 12px; table-layout: fixed;">\n'
    
    # 添加表头（按照指定顺序）
    html_content += '    <thead>\n        <tr style="background-color: #f2f2f2;">\n'
    for col in final_columns:
        html_content += f'            <th style="border: 1px solid #ddd; padding: 6px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">[[{col}]]</th>\n'
    html_content += '        </tr>\n    </thead>\n    <tbody>\n'
    
    # 处理表格数据
    current_faction = None
    faction_rowspan = 0
    faction_start_index = 0
    
    # 计算每个faction的行数
    faction_counts = df.iloc[:, 0].value_counts().to_dict()
    
    for index, row in df.iterrows():
        html_content += '        <tr>\n'
        
        # 处理第一列（faction）的合并
        faction_value = str(row.iloc[0]) if pd.notna(row.iloc[0]) else ""
        
        if faction_value != current_faction:
            current_faction = faction_value
            faction_rowspan = faction_counts.get(faction_value, 1)
            faction_start_index = index
        
        # 如果是当前faction的第一行，添加rowspan
        if index == faction_start_index:
            wiki_faction = f"[[{faction_value}]]" if faction_value else ""
            html_content += f'            <td style="border: 1px solid #ddd; padding: 6px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" rowspan="{faction_rowspan}">{wiki_faction}</td>\n'
        
        # 处理其他列（从第二列开始）
        for col_idx, value in enumerate(row.iloc[1:], start=1):
            str_value = str(value) if pd.notna(value) else ""
            
            # 检查是否需要添加Wiki链接
            if col_idx in wiki_link_columns and str_value:
                cell_content = f"[[{str_value}]]"
            else:
                cell_content = str_value
            
            html_content += f'            <td style="border: 1px solid #ddd; padding: 6px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">{cell_content}</td>\n'
        
        html_content += '        </tr>\n'
    
    html_content += '    </tbody>\n</table>'
    
    # 保存为文本文件
    with open(output_txt_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print(f"Wiki专用HTML表格代码已生成: {output_txt_path}")
    print(f"表格列顺序: {final_columns}")
    return html_content

def csv_to_wiki_html_table_with_tooltip(csv_file_path, output_txt_path):
    """
    生成带有悬停提示的表格版本（完整文本在悬停时显示）
    """
    
    # 读取CSV文件
    df = pd.read_csv(csv_file_path)
    
    # 定义指定的列顺序
    specified_columns = [
        "faction", "chess_name", "rarity", "role", "upgrade_chess",
        "max_health", "max_mana", "speed", "armor", "target_priority",
        "attack_range", "attack_speed", "melee_attack_damage", "passive_ability",
        "skill_description", "skill_name", "spell_target_priority",
        "ranged_attack_damage", "decline_ratio", "projectile_penetration"
    ]
    
    # 检查CSV文件中是否包含所有指定列
    missing_columns = [col for col in specified_columns if col not in df.columns]
    if missing_columns:
        print(f"警告: CSV文件中缺少以下列: {missing_columns}")
        available_columns = [col for col in specified_columns if col in df.columns]
        other_columns = [col for col in df.columns if col not in specified_columns]
        final_columns = available_columns + other_columns
    else:
        final_columns = specified_columns
    
    # 重新排列DataFrame的列顺序
    df = df[final_columns]
    
    # 定义需要添加Wiki链接的列索引（0-based）
    wiki_link_columns = [0, 1, 3, 4]  # faction, chess_name, upgrade_chess
    
    # 开始生成带有悬停提示的表格代码
    html_content = '<table border="1" style="border-collapse: collapse; width: 100%; font-size: 12px; table-layout: fixed;">\n'
    
    # 添加表头
    html_content += '    <thead>\n        <tr style="background-color: #f2f2f2;">\n'
    for col in final_columns:
        html_content += f'            <th style="border: 1px solid #ddd; padding: 6px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" title="{col}">[[{col}]]</th>\n'
    html_content += '        </tr>\n    </thead>\n    <tbody>\n'
    
    # 处理表格数据
    current_faction = None
    faction_rowspan = 0
    faction_start_index = 0
    
    # 计算每个faction的行数
    faction_counts = df.iloc[:, 0].value_counts().to_dict()
    
    for index, row in df.iterrows():
        html_content += '        <tr>\n'
        
        # 处理第一列（faction）的合并
        faction_value = str(row.iloc[0]) if pd.notna(row.iloc[0]) else ""
        
        if faction_value != current_faction:
            current_faction = faction_value
            faction_rowspan = faction_counts.get(faction_value, 1)
            faction_start_index = index
        
        # 如果是当前faction的第一行，添加rowspan
        if index == faction_start_index:
            wiki_faction = f"[[{faction_value}]]" if faction_value else ""
            html_content += f'            <td style="border: 1px solid #ddd; padding: 6px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;" rowspan="{faction_rowspan}" title="{faction_value}">{wiki_faction}</td>\n'
        
        # 处理其他列
        for col_idx, value in enumerate(row.iloc[1:], start=1):
            str_value = str(value) if pd.notna(value) else ""
            
            # 检查是否需要添加Wiki链接
            if col_idx in wiki_link_columns and str_value:
                cell_content = f"[[{str_value}]]"
            else:
                cell_content = str_value
            
            # 添加title属性用于悬停提示
            title_attr = f' title="{str_value}"' if len(str_value) > 20 else ''
            html_content += f'            <td style="border: 1px solid #ddd; padding: 6px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;"{title_attr}>{cell_content}</td>\n'
        
        html_content += '        </tr>\n'
    
    html_content += '    </tbody>\n</table>'
    
    # 保存为文本文件
    output_tooltip_path = output_txt_path.replace('.txt', '_with_tooltip.txt')
    with open(output_tooltip_path, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print(f"带悬停提示的表格代码已生成: {output_tooltip_path}")
    return html_content

def create_sample_csv():
    """
    创建示例CSV文件（如果不存在）
    """
    sample_data = """faction,chess_name,rarity,role,upgrade_chess,max_health,max_mana,speed,armor,target_priority,attack_range,attack_speed,melee_attack_damage,passive_ability,skill_description,skill_name,spell_target_priority,ranged_attack_damage,decline_ratio,projectile_penetration
human,SwordMan,Common,warrior,ShieldMan,100,0,4,0,CLOSE,25,1,15,,,,
human,SpearMan,Common,pikeman,HalberMan,100,0,4,0,CLOSE,35,1,15,,,,
human,ArcherMan,Common,ranger,CrossBowMan,100,0,4,0,CLOSE,60,1,10,,,,15,3,3
human,HorseMan,Rare,knight,CavalierMan,120,0,6,0,CLOSE,25,1,20,,,,
human,Mage,Rare,speller,ArchMage,90,100,4,0,CLOSE,60,1,10,,PlaceHolder,PlaceHolder,SELF,20,2.2,3
human,PrinceMan,Common,warrior,KingMan,110,0,4,0,CLOSE,25,1,20,,,,
human,ShieldMan,Common,warrior,,100,0,4,0,CLOSE,25,1,15,Chance to block damage from frontal attacks,,,
human,HalberMan,Uncommon,pikeman,,100,0,4,0,CLOSE,35,1,20,,,,
human,CrossBowMan,Uncommon,ranger,,100,0,4,0,CLOSE,70,2,10,Gains an extra attack after defeating an enemy,,,15,1,3
human,CavalierMan,Epic,knight,,130,0,6,10,CLOSE,25,1,25,,,,
human,ArchMage,Epic,speller,,90,100,4,0,CLOSE,60,1,10,Restores mana when dealing magic damage,PlaceHolder,PlaceHolder,SELF,25,2.2,3
human,KingMan,Legendary,warrior,,110,0,4,0,STRONG,25,1,20,Summons 1/2/3 phantoms after hit,,,"""
    
    with open('chess_data.csv', 'w', encoding='utf-8') as f:
        f.write(sample_data)
    print("示例CSV文件已创建: chess_data.csv")

# 主程序
if __name__ == "__main__":
    # 输入文件路径
    csv_file = "chess_stats.csv"
    
    # 如果CSV文件不存在，创建示例文件
    if not os.path.exists(csv_file):
        print("未找到CSV文件，创建示例文件...")
        create_sample_csv()
    
    # 输出文件路径
    output_txt = "wiki_table_code.txt"
    
    try:
        # 生成基础版本（不换行，文本截断）
        table_code = csv_to_wiki_html_table(csv_file, output_txt)
        
        # 生成带悬停提示的版本
        tooltip_code = csv_to_wiki_html_table_with_tooltip(csv_file, output_txt)
        
        print("\n转换完成！")
        print(f"基础版本: {output_txt}")
        print(f"带悬停提示版本: wiki_table_code_with_tooltip.txt")
        
        print("\n样式说明：")
        print("1. white-space: nowrap - 防止文本换行")
        print("2. overflow: hidden - 隐藏超出部分")
        print("3. text-overflow: ellipsis - 超出部分显示省略号")
        print("4. table-layout: fixed - 固定表格布局")
        print("5. 带悬停提示版本：鼠标悬停时显示完整文本")
        
        print("\n使用方法：")
        print("1. 选择适合的版本（基础版或带悬停提示版）")
        print("2. 打开对应的 .txt 文件")
        print("3. 复制 ALL 内容到Wiki页面")
        
    except Exception as e:
        print(f"转换过程中出现错误: {e}")
        print("请检查CSV文件格式是否正确")
