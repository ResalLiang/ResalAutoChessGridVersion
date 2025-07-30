extends Node2D

# 预加载角色场景
const hero_scene = preload("res://scene/hero.tscn")
@onready var floor_tile: TileMapLayer = $tilemap/floor

@export_enum("human", "dwarf", "elf", "forestProtector", "holy", "undead", "demon") var team1_faction := "human"
@export_enum("human", "dwarf", "elf", "forestProtector", "holy", "undead", "demon") var team2_faction := "human"

var hero_data: Dictionary  # Stores hero stats loaded from JSON
enum Team { TEAM1, TEAM2 }
enum SelectionMode { HIGH_HP, LOW_HP, NEAR_CENTER, FAR_CENTER }
var current_team: Team
var active_hero: Hero
var team_chars
var team_dict: Dictionary = {
	Team.TEAM1: [],
	Team.TEAM2: []
}
var center_point: Vector2
var board_width:= 216
var board_height:= 216

var astar_grid
var astar_grid_region
var grid_size := 16
var grid_count := 16
var current_id:= Vector2i.ZERO

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
	
	astar_grid = AStarGrid2D.new()
	

	astar_grid_region = Rect2i(-8, -8, grid_count, grid_count)
	#astar_grid_region = Rect2i(tile_size.x / 2, tile_size.y / 2, tile_size.x / 2 + tile_size.x * (grid_count - 1), tile_size.y / 2 + tile_size.y * (grid_count - 1))
	astar_grid.region = astar_grid_region
	astar_grid.cell_size = Vector2(grid_size, grid_size)
	# 遍历每个格子
	for x in range(0, tile_size.x / 2):
		for y in range(tile_size.y):
			# 随机决定是否生成角色(50%概率)
			if randf() > 0.9:
				# 创建角色实例
				var character = hero_scene.instantiate()

				# 计算格子中心位置
				var position = Vector2(
					x * tile_size.x + tile_size.x / 2,
					y * tile_size.y + tile_size.y / 2
				) + floor_tile.global_position

				# 设置角色位置
				character._position = position
				character.team = 1
				character.faction = team1_faction
				character.hero_name = get_random_character(team1_faction)
				team_dict[Team.TEAM1].append(character)
				current_id = Vector2i(x, y)
				astar_grid.set_point_solid(current_id, true)
				# 添加到场景
				add_child(character)
				
	for x in range(tile_size.x / 2, tile_size.x):
		for y in range(tile_size.y):
			# 随机决定是否生成角色(50%概率)
			if randf() > 0.9:
				# 创建角色实例
				var character = hero_scene.instantiate()
				
				# 计算格子中心位置
				var position = Vector2(
					x * tile_size.x + tile_size.x / 2,
					y * tile_size.y + tile_size.y / 2
				) + floor_tile.global_position
				
				# 设置角色位置
				character._position = position
				character.team = 2
				character.faction = team2_faction
				character.hero_name = get_random_character(team2_faction)
				team_dict[Team.TEAM2].append(character)
				current_id = Vector2i(x, y)
				astar_grid.set_point_solid(current_id, true)
				# 添加到场景
				add_child(character)
				
	center_point = Vector2(tile_size.x * grid_count / 2, tile_size.y * grid_count / 2)
	
	start_new_round()

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

func start_new_round():
	current_team = [Team.TEAM1, Team.TEAM2][randi() % 2]
	
	start_team_turn(current_team)

func start_team_turn(team: Team):
	team_chars = sort_characters(team, SelectionMode.HIGH_HP)
	refresh_solid_point()
	process_character_turn(team_chars.pop_front())

func process_character_turn(hero: Hero):
	active_hero = hero
	active_hero.is_active = true
	refresh_solid_point()
	astar_grid.set_point_solid(active_hero.position_id)
	await get_tree().process_frame
	
	astar_grid.update()
	
	await get_tree().process_frame
	active_hero.start_turn()
	# 连接信号等待行动完成
	active_hero.action_finished.connect(_on_character_action_finished)

func _on_character_action_finished():
	active_hero.is_active = false
	active_hero.action_finished.disconnect(_on_character_action_finished)
		
	var opposing_team = Team.TEAM2 if current_team == Team.TEAM1 else Team.TEAM1
	if team_dict[opposing_team] != []:
		start_team_turn(opposing_team)
		var backup_team = opposing_team
		opposing_team = current_team
		current_team = backup_team
		#opposing_team, current_team = current_team, opposing_team
	elif team_dict[opposing_team] == [] and team_dict[current_team] != []:
		start_team_turn(current_team)
	else:
		start_new_round()

func sort_characters(team: Team, mode: SelectionMode) -> Array:
	var heroes_team = team_dict[team]
	match mode:
		SelectionMode.HIGH_HP:
			heroes_team.sort_custom(func(a, b): return a.hp > b.hp)
		SelectionMode.LOW_HP:
			heroes_team.sort_custom(func(a, b): return a.hp < b.hp)
		SelectionMode.NEAR_CENTER:
			heroes_team.sort_custom(func(a, b): 
				return a.position.distance_to(center_point) < b.position.distance_to(center_point))
		SelectionMode.FAR_CENTER:
			heroes_team.sort_custom(func(a, b): 
				return a.position.distance_to(center_point) > b.position.distance_to(center_point))
	return heroes_team


func refresh_solid_point():
	astar_grid.fill_solid_region(astar_grid_region, false)

	for hero1 in team_dict[Team.TEAM1]:
		astar_grid.set_point_solid(hero1.position_id, true)

	for hero2 in team_dict[Team.TEAM2]:
		astar_grid.set_point_solid(hero2.position_id, true)
