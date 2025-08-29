extends Node2D

# 预加载角色场景
const hero_scene = preload("res://scene/hero.tscn")
const hero_class = preload("res://script/hero.gd")

@onready var arena: PlayArea = %arena
@onready var bench: PlayArea = %bench
@onready var shop: PlayArea = %shop
@onready var arena_unit_grid: UnitGrid = $ArenaUnitGrid
@onready var bench_unit_grid: UnitGrid = $BenchUnitGrid

@onready var debug_handler: DebugHandler = %debug_handler
@onready var hero_mover: HeroMover = %hero_mover
@onready var shop_handler: ShopHandler = %shop_handler
@onready var faction_bonus_manager: FactionBonusManager = %faction_bonus_manager

@onready var remain_coins_label: Label = $remain_coins_label
@onready var current_shop_level: Label = $current_shop_level
@onready var population_label: Label = $population_label

@onready var game_start_button: Button = $game_start_button
@onready var game_restart_button: Button = $game_restart_button
@onready var shop_refresh_button: Button = $shop_refresh_button
@onready var shop_freeze_button: Button = $shop_freeze_button
@onready var shop_upgrade_button: Button = $shop_upgrade_button

@onready var hero_order_hp_high: Button = $hero_order_control/hero_order_hp_high
@onready var hero_order_hp_low: Button = $hero_order_control/hero_order_hp_low
@onready var hero_order_near_center: Button = $hero_order_control/hero_order_near_center
@onready var hero_order_far_center: Button = $hero_order_control/hero_order_far_center

@onready var battle_meter: BattleMeter = $battle_meter
@onready var hero_information: HeroInformation = $hero_information

var hero_data: Dictionary  # Stores hero stats loaded from JSON
var hero_data_array: Dictionary
enum Team { TEAM1, TEAM2, TEAM1_FULL, TEAM2_FULL}
enum HeroActiveOrder { HIGH_HP, LOW_HP, NEAR_CENTER, FAR_CENTER }
var current_team: Team
var active_hero
var team_chars
var team_dict: Dictionary = {
	Team.TEAM1: [],
	Team.TEAM2: [],
	Team.TEAM1_FULL: [],
	Team.TEAM2_FULL: []
}

var hero_serial := 1000

var current_hero_active_order := HeroActiveOrder.HIGH_HP
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

var saved_arena_team = {}
var appearance_tween

var is_game_turn_start := false

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

const RARITY_COUNTS = {
	"Common": 50,
	"Uncommon": 40,
	"Rare": 30,
	"Epic": 20,
	"Legendary": 10
}

signal game_finished
signal hero_appearance_finished
signal game_turn_started
signal game_turn_finished

var cursor_texture = preload("res://asset/cursor/cursors/cursor1.png")

func _ready():
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
	game_turn_started.connect(
		func():
			game_start_button.disabled = true
			hero_order_hp_high.disabled = true
			hero_order_hp_low.disabled = true
			hero_order_near_center.disabled = true
			hero_order_far_center.disabled = true
			is_game_turn_start = true
			for node in get_tree().get_nodes_in_group("hero_group"):
				if node is Hero:
					node.drag_handler.dragging_enabled =  false
	)
	game_turn_finished.connect(
		func():
			game_start_button.disabled = false
			hero_order_hp_high.disabled = false
			hero_order_hp_low.disabled = false
			hero_order_near_center.disabled = false
			hero_order_far_center.disabled = false
			is_game_turn_start = false
			for node in get_tree().get_nodes_in_group("hero_group"):
				if node is Hero:
					node.drag_handler.dragging_enabled =  true
	)
	game_start_button.pressed.connect(new_round_prepare_end)
	game_restart_button.pressed.connect(start_new_game)
	shop_refresh_button.pressed.connect(shop_handler.shop_manual_refresh)
	shop_freeze_button.pressed.connect(shop_handler.shop_freeze)
	shop_upgrade_button.pressed.connect(shop_handler.shop_upgrade)
	hero_order_hp_high.pressed.connect(
		func():
			current_hero_active_order = HeroActiveOrder.HIGH_HP
	)
	hero_order_hp_low.pressed.connect(
		func():
			current_hero_active_order = HeroActiveOrder.LOW_HP
	)
	hero_order_near_center.pressed.connect(
		func():
			current_hero_active_order = HeroActiveOrder.NEAR_CENTER
	)
	hero_order_far_center.pressed.connect(
		func():
			current_hero_active_order = HeroActiveOrder.FAR_CENTER
	)

	shop_handler.coins_increased.connect(
		func(value, reason):
			remain_coins_label.text = "Remaining Coins    = " + str(shop_handler.remain_coins)
			if shop_handler.remain_coins >= shop_handler.shop_upgrade_price:
				shop_refresh_button.disabled = false
	)
	shop_handler.coins_decreased.connect(
		func(value, reason):
			remain_coins_label.text = "Remaining Coins = " + str(shop_handler.remain_coins)
			if shop_handler.remain_coins < shop_handler.shop_upgrade_price:
				shop_refresh_button.disabled = true
	)
	shop_handler.shop_upgraded.connect(
		func(value):
			current_shop_level.text = "Current Shop Level is :" + str(value)
	)
	hero_appearance_finished.connect(
		func(play_area):
			if play_area == arena:
				start_new_turn()
	)
	hero_mover.hero_moved.connect(
		func(hero: Hero, play_area: PlayArea, tile: Vector2i):
			var current_population := 0
			for node in get_tree().get_nodes_in_group("hero_group"):
				if node is Hero and node.current_play_area == node.play_areas.playarea_arena and node.team == 1:
					current_population += 1
			var max_population = shop_handler.shop_level + 2
			population_label.text = str(current_population)	+ "/" + str(max_population)
			if current_population > max_population:
				population_label.color = Color.RED
			elif current_population == max_population:
				population_label.color = Color.YELLOW
			else:
				population_label.color = Color.GREEN
			faction_bonus_manager.bonus_refresh()
	)

	center_point = Vector2(tile_size.x * grid_count / 2, tile_size.y * grid_count / 2)

	shop_handler.shop_refresh()
	current_round = 0
	
	debug_handler.write_log("LOG", "Game Start.")
	
	start_new_game()


func start_new_game() -> void:
	clear_play_area(arena)
	clear_play_area(shop)
	clear_play_area(bench)

	hero_serial = 1000

	battle_meter.battle_data = {}

	current_round = 0
	won_rounds = 0
	lose_rounds = 0

	shop_handler.shop_init()
	new_round_prepare_start()

func new_round_prepare_start():
	

	if not shop_handler.is_shop_frozen:
		shop_handler.shop_refresh()

	game_turn_finished.emit()

	clear_play_area(arena)
	if saved_arena_team.size() != 0:
		load_arena_team()
	hero_mover.setup_before_turn_start()
	current_round += 1
	shop_handler.turn_start_income(current_round)

func new_round_prepare_end():
	battle_meter.battle_data = {}
	#if saved_arena_team.size() == 0:
	team_dict[Team.TEAM1_FULL] = []
	for node in get_tree().get_nodes_in_group("hero_group"):
		if node is Hero and node.current_play_area == node.play_areas.playarea_arena and node.team == 1:
			team_dict[Team.TEAM1_FULL].append(node)
	save_arena_team()
	generate_enemy(current_round * 300)

	connect_hero_signals()

	hero_appearance(arena)

func start_new_turn():
	# if start new turn, it will be fully auto.
	game_turn_started.emit()
	print("Start new round.")
	var team1_alive_cnt = 0
	var team2_alive_cnt = 0
	team_dict[Team.TEAM1] = []
	team_dict[Team.TEAM2] = []
	for hero_index in team_dict[Team.TEAM1_FULL]:
		if is_instance_valid(hero_index):
			if hero_index.status != hero_class.STATUS.DIE and hero_index.current_play_area == hero_index.play_areas.playarea_arena:
				team_dict[Team.TEAM1].append(hero_index)
				team1_alive_cnt += 1
	for hero_index in team_dict[Team.TEAM2_FULL]:
		if is_instance_valid(hero_index):
			if hero_index.status != hero_class.STATUS.DIE and hero_index.current_play_area == hero_index.play_areas.playarea_arena:
				team_dict[Team.TEAM2].append(hero_index)
				team2_alive_cnt += 1
			
	if team1_alive_cnt == 0:
		game_finished.emit("team2")
		return
	elif team2_alive_cnt == 0:
		game_finished.emit("team1")
		return
		
	# current_team = [Team.TEAM1, Team.TEAM2][randi() % 2]
	
	current_team = Team.TEAM1

	start_hero_turn(current_team)

func start_hero_turn(team: Team):
	team_chars = sort_characters(team, current_hero_active_order)
	var current_hero = team_chars.pop_front()
	if hero_mover._get_play_area_for_position(current_hero.global_position) == 0:
		process_character_turn(current_hero)
	else:
		active_hero = current_hero
		active_hero.is_active = true
		#active_hero.start_turn()
		# 连接信号等待行动完成
		active_hero.action_finished.connect(_on_character_action_finished)
		_on_character_action_finished(active_hero.hero_name)

func process_character_turn(hero: Hero):
	active_hero = hero
	active_hero.is_active = true
	active_hero.action_finished.connect(_on_character_action_finished)
	active_hero.start_turn()
	# 连接信号等待行动完成

func _on_character_action_finished(hero: Hero):
	active_hero.is_active = false
	active_hero.action_finished.disconnect(_on_character_action_finished)

	if current_team == Team.TEAM1 and team_dict[Team.TEAM2].size() != 0:
		current_team = Team.TEAM2
		start_hero_turn(current_team)
		return
	elif current_team == Team.TEAM2 and team_dict[Team.TEAM1].size() != 0:
		current_team = Team.TEAM1
		start_hero_turn(current_team)
		return
	elif team_dict[Team.TEAM2].size() != 0 or team_dict[Team.TEAM1].size() != 0:
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

func sort_characters(team: Team, mode: HeroActiveOrder) -> Array:
	var heroes_team = team_dict[team]
	match mode:
		HeroActiveOrder.HIGH_HP:
			heroes_team.sort_custom(func(a, b): return a.max_hp > b.max_hp)
		HeroActiveOrder.LOW_HP:
			heroes_team.sort_custom(func(a, b): return a.max_hp < b.max_hp)
		HeroActiveOrder.NEAR_CENTER:
			heroes_team.sort_custom(func(a, b): 
				return a.position.distance_to(center_point) < b.position.distance_to(center_point))
		HeroActiveOrder.FAR_CENTER:
			heroes_team.sort_custom(func(a, b): 
				return a.position.distance_to(center_point) > b.position.distance_to(center_point))
	return heroes_team
	
func generate_enemy(difficulty : int) -> void:
	team_dict[Team.TEAM2_FULL] = []
	for node in get_tree().get_nodes_in_group("hero_group"):
		if node is Hero and node.current_play_area == node.play_areas.playarea_arena and node.team != 1:
			node.queue_free()
	var current_difficulty := 0
	var current_enemy_cnt := 0

	while current_difficulty < difficulty and current_enemy_cnt <= arena.unit_grid.size.x * arena.unit_grid.size.y / 2:
		var rand_x = randi_range(arena.unit_grid.size.x / 2, arena.unit_grid.size.x - 1)
		var rand_y = randi_range(0, arena.unit_grid.size.y - 1)
		if not arena.unit_grid.is_tile_occupied(Vector2(rand_x, rand_y)):
			var character = hero_scene.instantiate()
			character.team = 2
			character.arena = arena
			character.bench = bench
			character.shop = shop
			var rand_character_result = generate_random_hero()
			character.faction = rand_character_result[0]
			character.hero_name = rand_character_result[1]
			character.hero_serial = get_next_serial()
			# character.faction = hero_data.keys()[randi_range(0, hero_data.keys().size() - 2)] # remove villager
			# character.hero_name = get_random_character(character.faction)
			add_child(character)
			debug_handler.connect_to_hero_signal(character)
			hero_mover.setup_hero(character)
			hero_mover._move_hero(character, arena, Vector2(rand_x, rand_y))
			hero_information.setup_hero(character)
			current_difficulty += character.max_hp
			current_enemy_cnt += 1
			team_dict[Team.TEAM2_FULL].append(character)
			
	
func get_random_character(faction_name: String) -> String:
	if not hero_data.has(faction_name):
		return ""
	
	var candidates = []
	var weights = []
	
	# Prepare candidate list and weight list
	for hero_name_index in hero_data[faction_name]:
		var rarity = hero_data[faction_name][hero_name_index]["rarity"]
		if RARITY_WEIGHTS[shop_handler.shop_level].has(rarity) and hero_data[faction_name][hero_name_index]["spd"] != 0:
			candidates.append(hero_name_index)
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
	if saved_arena_team.size() != 0:
		for tile_index in saved_arena_team.keys():
			if saved_arena_team[tile_index]:
				var character = hero_scene.instantiate()
				character.faction = saved_arena_team[tile_index][0]
				character.hero_name = saved_arena_team[tile_index][1]
				character.team = 1
				character.arena = arena
				character.bench = bench
				character.shop = shop
				character.hero_serial = get_next_serial()
				add_child(character)
				debug_handler.connect_to_hero_signal(character)
				hero_mover._move_hero(character, arena, tile_index) 
				team_dict[Team.TEAM1_FULL].append(character)
		
func save_arena_team():
	saved_arena_team = {}
	for hero_index in arena.unit_grid.units.keys():
		if not is_instance_valid(arena.unit_grid.units[hero_index]):
			arena.unit_grid.units[hero_index] = null
		elif arena.unit_grid.units[hero_index] is Hero:
			saved_arena_team[hero_index] = [arena.unit_grid.units[hero_index].faction, arena.unit_grid.units[hero_index].hero_name]

# Generates random hero based on shop level and rarity weights
func generate_random_hero():
	# --- Rarity Selection Phase ---
	# Calculate total weight for current shop level
	var total_rarity_weight := 0
	for weight in RARITY_WEIGHTS[shop_handler.shop_level].values():
		total_rarity_weight += weight
	
	# Get random value within weight range
	var random_rarity_threshold := randi_range(0, total_rarity_weight - 1)
	
	# Determine selected rarity tier
	var accumulated_rarity_weight := 0
	var selected_rarity: String
	for rarity_type in RARITY_WEIGHTS[shop_handler.shop_level]:
		accumulated_rarity_weight += RARITY_WEIGHTS[shop_handler.shop_level][rarity_type]
		if accumulated_rarity_weight > random_rarity_threshold:
			selected_rarity = rarity_type
			break

	# --- Existing Heroes Tracking ---
	# Count existing hero instances (faction+name pairs)
	var existing_hero_counts := {}
	for node in get_tree().get_nodes_in_group("hero_group"):
		if node is Hero:
			var composite_key = "%s_%s" % [node.faction, node.hero_name]
			existing_hero_counts[composite_key] = existing_hero_counts.get(composite_key, 0) + 1

	# --- Eligible Heroes Filtering ---
	var candidate_heroes := []
	var total_weight_pool := 0
	
	# Pre-process all eligible heroes with calculated weights
	for faction in hero_data:
		# Skip special faction
		if faction == "villager":
			continue
			
		for hero_name in hero_data[faction]:
			var hero_attributes = hero_data[faction][hero_name]
			
			# Validation checks
			if hero_attributes["spd"] == 0 || hero_attributes["rarity"] != selected_rarity:
				continue
				
			# Calculate dynamic weight with duplicate penalty
			var hero_identifier = "%s_%s" % [faction, hero_name]
			var base_weight = RARITY_WEIGHTS[shop_handler.shop_level][hero_attributes["rarity"]]
			var duplicate_penalty = existing_hero_counts.get(hero_identifier, 0)
			var final_weight = max(base_weight - duplicate_penalty, 1)  # Ensure minimum weight
			
			# Register candidate hero
			total_weight_pool += final_weight
			candidate_heroes.append({
				"faction": faction,
				"name": hero_name,
				"weight": final_weight,
				"cumulative_weight": total_weight_pool
			})

	# --- Weighted Random Selection ---
	if candidate_heroes.size() == 0:
		push_warning("No eligible heroes found for rarity: %s" % selected_rarity)
		return ["human", "ShieldMan"]  # Fallback
	
	var random_hero_point := randi_range(0, total_weight_pool - 1)
	for hero in candidate_heroes:
		if hero["cumulative_weight"] > random_hero_point:
			return [hero["faction"], hero["name"]]
	
	# Should never reach here if candidates exist
	return ["human", "ShieldMan"]

func connect_hero_signals() -> void:

	for hero_index in team_dict[Team.TEAM1_FULL]:
		hero_index.damage_taken.connect(battle_meter.get_damage_data)
		hero_index.is_died.connect(
			func(hero):
				if team_dict[Team.TEAM1].has(hero):
					team_dict[Team.TEAM1].erase(hero)
				if team_dict[Team.TEAM1_FULL].has(hero):
					team_dict[Team.TEAM1_FULL].erase(hero)
		)

	for hero_index in team_dict[Team.TEAM2_FULL]:
		hero_index.damage_taken.connect(battle_meter.get_damage_data)
		hero_index.is_died.connect(
			func(hero):
				if team_dict[Team.TEAM2].has(hero):
					team_dict[Team.TEAM2].erase(hero)
				if team_dict[Team.TEAM2_FULL].has(hero):
					team_dict[Team.TEAM2_FULL].erase(hero)
		)

func hero_appearance(play_area: PlayArea):

	var area_hero_count = 0
	var current_hero_count := 0
	var before_appreance_height := 999

	for hero_index in team_dict[Team.TEAM1_FULL]:
		area_hero_count += 1
		hero_index.visible = false
	for hero_index in team_dict[Team.TEAM2_FULL]:
		area_hero_count += 1
		hero_index.visible = false


	if appearance_tween:
		appearance_tween.kill() # Abort the previous animation.
	appearance_tween = create_tween()
	appearance_tween.connect("finished", 
		func():
			if current_hero_count >= area_hero_count or true:
				hero_appearance_finished.emit(play_area)
	)

	for hero_index in team_dict[Team.TEAM1_FULL]:
		current_hero_count += 1
		hero_index._position.y -= before_appreance_height
		hero_index.visible = true
		appearance_tween.tween_property(hero_index, "_position", hero_index._position + Vector2(0, before_appreance_height) , 0.5)

	for hero_index in team_dict[Team.TEAM2_FULL]:
		current_hero_count += 1
		hero_index._position.y -= before_appreance_height
		hero_index.visible = true
		appearance_tween.tween_property(hero_index, "_position", hero_index._position + Vector2(0, before_appreance_height) , 0.5)

	# position_tween.tween_property(self, "_position", target_pos, 0.1)

	
func get_next_serial() -> int:
	hero_serial += 1
	return hero_serial


func summon_hero(summon_hero_faction: String, summon_hero_name: String, team: int, summon_arena: PlayArea, summon_position: Vector2i) -> Hero:

	if not summon_hero_faction in hero_data.keys():
		return null
	if not summon_hero_name in hero_data[summon_hero_faction].keys():
		return null

	var summoned_character = hero_scene.instantiate()
	summoned_character.hero_name = summon_hero_name
	summoned_character.faction = summon_hero_faction
	summoned_character.team = team
	summoned_character.arena = arena
	summoned_character.bench = bench
	summoned_character.shop = shop
	summoned_character.hero_serial = get_next_serial()
	add_child(summoned_character)
	debug_handler.connect_to_hero_signal(summoned_character)
	hero_mover.setup_hero(summoned_character)
	hero_mover._move_hero(summoned_character, summon_arena, summon_position)
	hero_information.setup_hero(summoned_character)
		
	return summoned_character
