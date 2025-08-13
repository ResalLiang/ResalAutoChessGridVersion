extends Node2D

# 预加载角色场景
const hero_scene = preload("res://scene/hero.tscn")
const hero_class = preload("res://script/hero.gd")


@export_enum("human", "dwarf", "elf", "forestProtector", "holy", "undead", "demon") var team1_faction := "human"
@export_enum("human", "dwarf", "elf", "forestProtector", "holy", "undead", "demon") var team2_faction := "human"
@onready var arena: PlayArea = $tilemap/arena
@onready var arena_unit_grid: UnitGrid = $ArenaUnitGrid
@onready var bench_unit_grid: UnitGrid = $BenchUnitGrid
@onready var hero_mover: HeroMover = $hero_mover
@onready var game_start_button: Button = $game_start_button

var hero_data: Dictionary  # Stores hero stats loaded from JSON
enum Team { TEAM1, TEAM2, TEAM1_FULL, TEAM2_FULL}
enum SelectionMode { HIGH_HP, LOW_HP, NEAR_CENTER, FAR_CENTER }
var current_team: Team
var active_hero
var team_chars
var team_dict: Dictionary = {
	Team.TEAM1: [],
	Team.TEAM2: [],
	Team.TEAM1_FULL: [],
	Team.TEAM2_FULL: []
}
var center_point: Vector2
var board_width:= 216
var board_height:= 216

var grid_size := 16
var grid_count := 16
var astar_solid_map

var rand_hero_ratio := 0.8
# Define rarity weights dictionary
const RARITY_WEIGHTS = {
	"Common": 50,
	"Uncommon": 30,
	"Rare": 20,
	"Epic": 10,
	"Legendary": 5
}

signal game_finished

func _ready():
	if Engine.is_editor_hint():
		return
	# 棋盘参数
	var tile_size = Vector2(16, 16)
	var rows = 5
	var cols = 4
	
	var file = FileAccess.open("res://script/hero_stats.json", FileAccess.READ)
	if not file:
		push_error("Failed to open hero_stats.json")
		return
	
	var json_text = file.get_as_text()
	hero_data = JSON.parse_string(json_text)
	
	if not hero_data:
		push_error("JSON parsing failed for hero_stats.json")
		return
	
	game_finished.connect(_on_game_finished)

	# 遍历每个格子
	for x in range(0, tile_size.x / 2):
		for y in range(0, tile_size.y):
			if randf() > rand_hero_ratio:
				# 创建角色实例
				var character = hero_scene.instantiate()

				# 计算格子中心位置
				var position = Vector2(
					x * tile_size.x + tile_size.x / 2,
					y * tile_size.y + tile_size.y / 2
				)

				# 设置角色位置
				character._position = position
				character.team = 1
				character.faction = team1_faction
				character.hero_name = get_random_character(team1_faction)
				character.current_play_area = character.play_areas.arena
				team_dict[Team.TEAM1_FULL].append(character)
				arena_unit_grid.add_unit(Vector2(x, y), character)
				# 添加到场景
				arena_unit_grid.add_child(character)
				
	for x in range(tile_size.x / 2, tile_size.x):
		for y in range(0, tile_size.y):
			if randf() > rand_hero_ratio:
				# 创建角色实例
				var character = hero_scene.instantiate()
				
				# 计算格子中心位置
				var position = Vector2(
					x * tile_size.x + tile_size.x / 2,
					y * tile_size.y + tile_size.y / 2
				)
				
				# 设置角色位置
				character._position = position
				character.team = 2
				character.faction = team2_faction
				character.hero_name = get_random_character(team2_faction)
				character.current_play_area = character.play_areas.arena
				team_dict[Team.TEAM2_FULL].append(character)
				arena_unit_grid.add_unit(Vector2(x, y), character)
				# 添加到场景
				arena_unit_grid.add_child(character)
				
	center_point = Vector2(tile_size.x * grid_count / 2, tile_size.y * grid_count / 2)
	hero_mover.setup_before_turn_start()
	
	game_start_button.pressed.connect(start_new_round)
	add_child(game_start_button)
	#start_new_round()

func get_random_character(faction_name: String) -> String:
	if not hero_data.has(faction_name):
		return ""
	
	var candidates = []
	var weights = []
	
	# Prepare candidate list and weight list
	for char_name in hero_data[faction_name]:
		var rarity = hero_data[faction_name][char_name]["rarity"]
		if RARITY_WEIGHTS.has(rarity) and hero_data[faction_name][char_name]["spd"] != 0:
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
	game_start_button.disabled = true
	print("Start new round.")
	var team1_alive_cnt = 0
	var team2_alive_cnt = 0
	for hero1 in team_dict[Team.TEAM1_FULL]:
		team_dict[Team.TEAM1].append(hero1)
		if hero1.stat != hero_class.STATUS.DIE and hero1.current_play_area == hero1.play_areas.arena:
			team1_alive_cnt += 1
	for hero2 in team_dict[Team.TEAM2_FULL]:
		team_dict[Team.TEAM2].append(hero2)
		if hero2.stat != hero_class.STATUS.DIE and hero2.current_play_area == hero2.play_areas.arena:
			team2_alive_cnt += 1
			
	if team1_alive_cnt == 0:
		game_finished.emit("team2")
	elif team2_alive_cnt == 0:
		game_finished.emit("team1")
		
	current_team = [Team.TEAM1, Team.TEAM2][randi() % 2]
	
	start_team_turn(current_team)

func start_team_turn(team: Team):
	team_chars = sort_characters(team, SelectionMode.HIGH_HP)
	var current_hero = team_chars.pop_front()
	if hero_mover._get_play_area_for_position(current_hero.global_position) == 0:
		process_character_turn(current_hero)
	else:
		active_hero = current_hero
		active_hero.is_active = true
		#active_hero.start_turn()
		# 连接信号等待行动完成
		active_hero.action_finished.connect(_on_character_action_finished)
		_on_character_action_finished()

func process_character_turn(hero):
	active_hero = hero
	active_hero.is_active = true
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

func _on_game_finished(msg):
	print("Game over, %s won!" % msg)

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
