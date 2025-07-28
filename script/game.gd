extends Node2D

# 预加载角色场景
const hero_scene = preload("res://scene/hero.tscn")
@onready var floor_tile: TileMapLayer = $tilemap/floor

@export_enum("human", "dwarf", "elf", "forestProtector", "holy", "undead", "demon") var team1_faction := "human"
@export_enum("human", "dwarf", "elf", "forestProtector", "holy", "undead", "demon") var team2_faction := "human"

var hero_data: Dictionary  # Stores hero stats loaded from JSON

# Define rarity weights dictionary
const RARITY_WEIGHTS = {
	"Common": 50,
	"Uncommon": 30,
	"Rare": 20,
	"Epic": 10,
	"Legendary": 5
}

func _ready():
	if Engine.is_editor_hint():
		return
	# 棋盘参数
	var tile_size = Vector2(16, 16)
	var rows = 5
	var cols = 4
	
	var file = FileAccess.open("res://script/hero_stats_raw/hero_stats.json", FileAccess.READ)
	if not file:
		push_error("Failed to open hero_stats.json")
		return
	
	var json_text = file.get_as_text()
	hero_data = JSON.parse_string(json_text)
	
	if not hero_data:
		push_error("JSON parsing failed for hero_stats.json")
		return
	
	
	# 遍历每个格子
	for x in range(0, 4):
		for y in range(rows):
			# 随机决定是否生成角色(50%概率)
			if randf() > 0.65:
				# 创建角色实例
				var character = hero_scene.instantiate()
				
				# 计算格子中心位置
				var position = Vector2(
					x * tile_size.x + tile_size.x / 2,
					y * tile_size.y + tile_size.y / 2
				) + floor_tile.global_position
				
				# 设置角色位置
				character.position = position
				character.team = 1
				character.faction = team1_faction
				character.hero_name = get_random_character(team1_faction)
				
				# 添加到场景
				add_child(character)
				
				
	for x in range(4, 8):
		for y in range(rows):
			# 随机决定是否生成角色(50%概率)
			if randf() > 0.65:
				# 创建角色实例
				var character = hero_scene.instantiate()
				
				# 计算格子中心位置
				var position = Vector2(
					x * tile_size.x + tile_size.x / 2,
					y * tile_size.y + tile_size.y / 2
				) + floor_tile.global_position
				
				# 设置角色位置
				character.position = position
				character.team = 2
				character.faction = team2_faction
				character.hero_name = get_random_character(team2_faction)
				# 添加到场景
				add_child(character)

func get_random_character(faction_name: String) -> String:
	if not hero_data.has(faction_name):
		return ""
	
	var candidates = []
	var weights = []
	
	# Prepare candidate list and weight list
	for char_name in hero_data[faction_name]:
		var rarity = hero_data[faction_name][char_name]["rarity"]
		if RARITY_WEIGHTS.has(rarity) and hero_data[faction_name][char_name]["move_speed"] != 0:
			candidates.append(char_name)
			weights.append(RARITY_WEIGHTS[rarity])
	
	if candidates.size() == 0:
		return ""
	
	# Perform weighted random selection
	var total_weight = 0
	for w in weights:
		total_weight += w
	
	var random_value = randi() % total_weight
	var weight_sum = 0
	
	for i in range(candidates.size()):
		weight_sum += weights[i]
		if random_value < weight_sum:
			return candidates[i]
	
	return candidates[0] # Default return first one (shouldn't reach here)
