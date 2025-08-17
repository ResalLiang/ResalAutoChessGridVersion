extends Node2D

# 预加载角色场景
const hero_scene = preload("res://scene/hero.tscn")
const hero_class = preload("res://script/hero.gd")


@export_enum("human", "dwarf", "elf", "forestProtector", "holy", "undead", "demon") var team1_faction := "human"
@export_enum("human", "dwarf", "elf", "forestProtector", "holy", "undead", "demon") var team2_faction := "human"
@onready var arena: PlayArea = $tilemap/arena
@onready var bench: PlayArea = $tilemap/bench
@onready var shop: PlayArea = $tilemap/shop
@onready var arena_unit_grid: UnitGrid = $ArenaUnitGrid
@onready var bench_unit_grid: UnitGrid = $BenchUnitGrid
@onready var game_start_button: Button = $game_start_button
@onready var game_restart_button: Button = $game_restart_button
@onready var shop_refresh_button: Button = $shop_refresh_button
@onready var shop_freeze_button: Button = $shop_freeze_button
@onready var shop_upgrade_button: Button = $shop_upgrade_button

@onready var remain_coins_label: Label = $remain_coins_label
@onready var current_shop_level: Label = $current_shop_level
@onready var hero_mover: HeroMover = %hero_mover
@onready var shop_handler: ShopHandler = %shop_handler
@onready var area_effect_handler: AreaEffectHanlder = %area_effect_handler

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

var is_shop_frozen := false
var remain_coins := 999

var current_round := 1
var won_rounds := 0
const max_won_rounds := 5
var lose_rounds := 0
const max_lose_rounds := 5

var saved_arena_team

# Define rarity weights dictionary
const RARITY_WEIGHTS = {
	1: {
		"Common": 50,
		"Uncommon": 30,
		"Rare": 0,
		"Epic": 0,
		"Legendary": 0
	},
	2: {
		"Common": 50,
		"Uncommon": 30,
		"Rare": 20,
		"Epic": 0,
		"Legendary": 0
	},
	3: {
		"Common": 50,
		"Uncommon": 30,
		"Rare": 20,
		"Epic": 10,
		"Legendary": 0
	},
	4: {
		"Common": 50,
		"Uncommon": 30,
		"Rare": 20,
		"Epic": 10,
		"Legendary": 5
	},
	5: {
		"Common": 50,
		"Uncommon": 30,
		"Rare": 20,
		"Epic": 10,
		"Legendary": 5
	},
	6: {
		"Common": 50,
		"Uncommon": 30,
		"Rare": 20,
		"Epic": 10,
		"Legendary": 5
	}
}

signal game_finished

func _ready():
	if Engine.is_editor_hint():
		return
	# 棋盘参数
	var tile_size = Vector2(16, 16)
	
	var file = FileAccess.open("res://script/hero_stats.json", FileAccess.READ)
	if not file:
		push_error("Failed to open hero_stats.json")
		return
	
	var json_text = file.get_as_text()
	hero_data = JSON.parse_string(json_text)
	
	if not hero_data:
		push_error("JSON parsing failed for hero_stats.json")
		return
	
	game_finished.connect(_on_round_finished)
	
	game_start_button.pressed.connect(new_round_prepare_end)
	game_restart_button.pressed.connect(start_new_game)
	shop_refresh_button.pressed.connect(shop_handler.shop_refresh)
	shop_freeze_button.pressed.connect(shop_handler.shop_freeze)
	shop_upgrade_button.pressed.connect(shop_handler.shop_upgrade)


	center_point = Vector2(tile_size.x * grid_count / 2, tile_size.y * grid_count / 2)

	shop_handler.shop_refresh()
	current_round = 0
	start_new_game()

func _process(delta: float) -> void:
	remain_coins_label.text = "Remaining Coins    = " + str(shop_handler.remain_coins)
	if shop_handler.remain_coins < shop_handler.shop_buy_price:
		shop_refresh_button.disabled = true
	current_shop_level.text = "Current Shop Level is :" + str(shop_handler.shop_level)


func start_new_game() -> void:
	clear_play_area(arena)
	clear_play_area(shop)
	clear_play_area(bench)

	shop_handler.shop_init()
	new_round_prepare_start()

func new_round_prepare_start():
	game_start_button.disabled = false
	clear_play_area(arena)
	if saved_arena_team:
		load_arena_team()
	hero_mover.setup_before_turn_start()
	current_round += 1

func new_round_prepare_end():
	if not saved_arena_team:
		team_dict[Team.TEAM1_FULL] = []
		for node in get_tree().get_nodes_in_group("hero_group"):
			if node is Hero and node.current_play_area == node.play_areas.arena and node.team == 1:
				team_dict[Team.TEAM1_FULL].append(node)
	save_arena_team()
	generate_enemy(current_round * 500)
	start_new_turn()

func start_new_turn():
	# if start new turn, it will be fully auto.
	game_start_button.disabled = true
	print("Start new round.")
	var team1_alive_cnt = 0
	var team2_alive_cnt = 0
	team_dict[Team.TEAM1] = []
	team_dict[Team.TEAM2] = []
	for hero1 in team_dict[Team.TEAM1_FULL]:
		if hero1.stat != hero_class.STATUS.DIE and hero1.current_play_area == hero1.play_areas.arena:
			team_dict[Team.TEAM1].append(hero1)
			team1_alive_cnt += 1
	for hero2 in team_dict[Team.TEAM2_FULL]:
		if hero2.stat != hero_class.STATUS.DIE and hero2.current_play_area == hero2.play_areas.arena:
			team_dict[Team.TEAM2].append(hero2)
			team2_alive_cnt += 1
			
	if team1_alive_cnt == 0:
		game_finished.emit("team2")
		return
	elif team2_alive_cnt == 0:
		game_finished.emit("team1")
		return
		
	current_team = [Team.TEAM1, Team.TEAM2][randi() % 2]
	
	start_hero_turn(current_team)

func start_hero_turn(team: Team):
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
		start_hero_turn(opposing_team)
		var backup_team = opposing_team
		opposing_team = current_team
		current_team = backup_team
		#opposing_team, current_team = current_team, opposing_team
	elif team_dict[opposing_team] == [] and team_dict[current_team] != []:
		start_hero_turn(current_team)
	else:
		start_new_turn()

func _on_round_finished(msg):
	if msg == "team1":
		won_rounds += 1
		print("Round %d over, you won!" % current_round)
	elif msg == "team2":
		lose_rounds += 1
		print("Round %d over, you lose..." % current_round)

	print("You have won %d rounds, and lose %d rounds." % [won_rounds, lose_rounds])

	if won_rounds >= max_won_rounds:
		print("You won the game!")
		return
	elif lose_rounds >= max_lose_rounds:
		print("You lose the game... Try later.")
		return

	new_round_prepare_start()

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
	
func generate_enemy(difficulty : int) -> void:
	team_dict[Team.TEAM2_FULL] = []
	for node in get_tree().get_nodes_in_group("hero_group"):
		if node is Hero and node.current_play_area == node.play_areas.arena and node.team != 1:
			node.queue_free()
	var current_difficulty := 0
	var current_enemy_cnt := 0

	while current_difficulty < difficulty and current_enemy_cnt <= arena.unit_grid.size.x * arena.unit_grid.size.y / 2:
		var rand_x = randi_range(arena.unit_grid.size.x / 2, arena.unit_grid.size.x - 1)
		var rand_y = randi_range(0, arena.unit_grid.size.y - 1)
		if not arena.unit_grid.is_tile_occupied(Vector2(rand_x, rand_y)):
			var character = hero_scene.instantiate()
			character.team = 2
			character.faction = hero_data.keys()[randi_range(0, hero_data.keys().size() - 2)] # remove villager
			character.hero_name = get_random_character(character.faction)
			add_child(character)
			hero_mover.setup_hero(character)
			hero_mover._move_hero(character, arena, Vector2(rand_x, rand_y))
			current_difficulty += character.max_hp
			current_enemy_cnt += 1
			team_dict[Team.TEAM2_FULL].append(character)
			
	
func get_random_character(faction_name: String) -> String:
	if not hero_data.has(faction_name):
		return ""
	
	var candidates = []
	var weights = []
	
	# Prepare candidate list and weight list
	for char_name in hero_data[faction_name]:
		var rarity = hero_data[faction_name][char_name]["rarity"]
		if RARITY_WEIGHTS[shop_handler.shop_level].has(rarity) and hero_data[faction_name][char_name]["spd"] != 0:
			candidates.append(char_name)
			weights.append(RARITY_WEIGHTS[shop_handler.shop_level][rarity])
	
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

func clear_play_area(play_area_to_clear: PlayArea):
	for node in play_area_to_clear.unit_grid.get_children():
		if node is Hero:
			node.queue_free()

func load_arena_team():
	team_dict[Team.TEAM1_FULL] = []
	if saved_arena_team:
		for tile_index in saved_arena_team.keys():
			if saved_arena_team[tile_index]:
				var character = hero_scene.instantiate()
				character.faction = saved_arena_team[tile_index][0]
				character.hero_name = saved_arena_team[tile_index][1]
				character.team = 1
				add_child(character)
				hero_mover._move_hero(character, arena, tile_index) 
				team_dict[Team.TEAM1_FULL].append(character)
		


func save_arena_team():
	saved_arena_team = {}
	for hero_index in arena.unit_grid.units.keys():
		if arena.unit_grid.units[hero_index]:
			saved_arena_team[hero_index] = [arena.unit_grid.units[hero_index].faction, arena.unit_grid.units[hero_index].hero_name]
