class_name Game
extends Node2D

# 预加载角色场景
const chess_scene = preload("res://scene/chess.tscn")
const obstacle_scene = preload("res://scene/obstacle.tscn")
const chess_class = preload("res://script/chess.gd")

@onready var arena: PlayArea = %arena
@onready var bench: PlayArea = %bench
@onready var shop: PlayArea = %shop
@onready var arena_unit_grid: UnitGrid = $ArenaUnitGrid
@onready var bench_unit_grid: UnitGrid = $BenchUnitGrid

@onready var debug_handler: DebugHandler = %debug_handler
@onready var chess_mover: ChessMover = %chess_mover
@onready var shop_handler: ShopHandler = %shop_handler
@onready var faction_bonus_manager: FactionBonusManager = %faction_bonus_manager

@onready var remain_coins_label: Label = $remain_coins_label
@onready var current_shop_level: Label = $current_shop_level
@onready var population_label: Label = $population_label
@onready var current_round_label: Label = $current_round_label
@onready var last_turn_label: Label = $last_turn_label

@onready var game_start_button: Button = $game_start_button
@onready var game_restart_button: Button = $game_restart_button
@onready var shop_refresh_button: Button = $shop_refresh_button
@onready var shop_freeze_button: Button = $shop_freeze_button
@onready var shop_upgrade_button: Button = $shop_upgrade_button
@onready var back_button: Button = $back_button

@onready var chess_order_hp_high: Button = $chess_order_control/chess_order_hp_high
@onready var chess_order_hp_low: Button = $chess_order_control/chess_order_hp_low
@onready var chess_order_near_center: Button = $chess_order_control/chess_order_near_center
@onready var chess_order_far_center: Button = $chess_order_control/chess_order_far_center

@onready var battle_meter: BattleMeter = $battle_meter
@onready var chess_information: ChessInformation = $chess_information
@onready var arrow: CustomArrowRenderer = $arrow


enum Team { TEAM1, TEAM2, TEAM1_FULL, TEAM2_FULL}
enum ChessActiveOrder { HIGH_HP, LOW_HP, NEAR_CENTER, FAR_CENTER }
var current_team: Team
var active_chess
var team_chars
var team_dict: Dictionary = {
	Team.TEAM1: [],
	Team.TEAM2: [],
	Team.TEAM1_FULL: [],
	Team.TEAM2_FULL: []
}

var chess_serial := 1000

var current_chess_active_order := ChessActiveOrder.HIGH_HP
var center_point: Vector2
var board_width:= 216
var board_height:= 216

var current_round := 1

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

var player_name := "player1"

var save_datas : Dictionary

var current_population := 0
var max_population := 3

signal round_finished
signal chess_appearance_finished
signal game_turn_started
signal game_turn_finished
signal player_won_round
signal player_lose_round
signal player_won_game
signal player_lose_game

signal to_menu_scene
signal add_round_finish_scene
signal to_game_finish_scene

func _ready():

	var tile_size = arena.unit_grid.size
	
	round_finished.connect(handle_round_finished)
	game_turn_started.connect(
		func():
			game_start_button.disabled = true
			chess_order_hp_high.disabled = true
			chess_order_hp_low.disabled = true
			chess_order_near_center.disabled = true
			chess_order_far_center.disabled = true
			is_game_turn_start = true
			for node in get_tree().get_nodes_in_group("obstacle_group"):
				if node is Obstacle:
					node.dragging_enabled =  false
	)
	game_turn_finished.connect(
		func():
			game_start_button.disabled = false
			chess_order_hp_high.disabled = false
			chess_order_hp_low.disabled = false
			chess_order_near_center.disabled = false
			chess_order_far_center.disabled = false
			is_game_turn_start = false
			for node in get_tree().get_nodes_in_group("obstacle_group"):
				if node is Obstacle:
					node.dragging_enabled =  true
	)
	game_start_button.pressed.connect(new_round_prepare_end)
	game_restart_button.pressed.connect(start_new_game)
	shop_refresh_button.pressed.connect(shop_handler.shop_manual_refresh)
	shop_refresh_button.pressed.connect(
		func():
			control_shaker(remain_coins_label)
	)
	shop_freeze_button.pressed.connect(shop_handler.shop_freeze)
	shop_upgrade_button.pressed.connect(shop_handler.shop_upgrade)
	chess_order_hp_high.pressed.connect(
		func():
			current_chess_active_order = ChessActiveOrder.HIGH_HP
	)
	chess_order_hp_low.pressed.connect(
		func():
			current_chess_active_order = ChessActiveOrder.LOW_HP
	)
	chess_order_near_center.pressed.connect(
		func():
			current_chess_active_order = ChessActiveOrder.NEAR_CENTER
	)
	chess_order_far_center.pressed.connect(
		func():
			current_chess_active_order = ChessActiveOrder.FAR_CENTER
	)

	shop_handler.coins_increased.connect(
		func(value, reason):
			remain_coins_label.text = "Remaining Coins = " + str(shop_handler.remain_coins)
			if shop_handler.remain_coins >= shop_handler.shop_upgrade_price:
				shop_refresh_button.disabled = false
	)
	shop_handler.coins_decreased.connect(DataManagerSingleton.handle_coin_spend)
	shop_handler.coins_decreased.connect(
		func(value, reason):
			remain_coins_label.text = "Remaining Coins = " + str(shop_handler.remain_coins)
			if shop_handler.remain_coins < shop_handler.shop_upgrade_price:
				shop_refresh_button.disabled = true
	)
	shop_handler.shop_upgraded.connect(
		func(value):
			current_shop_level.text = "Current Shop Level is : " + str(shop_handler.shop_level)
			update_population()
	)
	chess_appearance_finished.connect(
		func(play_area):
			if play_area == arena:
				start_new_round()
	)
	chess_mover.chess_moved.connect(
		func(chess: Obstacle, play_area: PlayArea, tile: Vector2i):
			if not is_game_turn_start:
				update_population()
	)
	
	chess_mover.chess_raised.connect(
		func(chess_position, obstacle):
			arrow.is_visible = true
			arrow.start_pos = chess_position
	)
	
	chess_mover.chess_dropped.connect(
		func(obstacle):
			arrow.is_visible = false		
	)

	player_won_round.connect(DataManagerSingleton.handle_player_won_round)
	player_lose_round.connect(DataManagerSingleton.handle_player_lose_round)
	player_won_game.connect(DataManagerSingleton.handle_player_won_game)
	player_lose_game.connect(DataManagerSingleton.handle_player_lose_game)

	chess_mover.play_areas = [arena, bench, shop]

	center_point = Vector2(tile_size.x * 16 / 2, tile_size.y * 16 / 2)

	shop_handler.shop_refresh()
	current_round = 0
	
	start_new_game()

	last_turn_label.text = '-'

func _process(delta: float) -> void:
	pass

func start_new_game() -> void:

	DataManagerSingleton.load_game_json()
	DataManagerSingleton.in_game_data = DataManagerSingleton.player_data.duplicate()

	debug_handler.write_log("LOG", "Game Start.")
	
	clear_play_area(arena)
	clear_play_area(shop)
	clear_play_area(bench)

	saved_arena_team = {}

	team_dict[Team.TEAM1] = []
	team_dict[Team.TEAM2] = []
	team_dict[Team.TEAM1_FULL] = []
	team_dict[Team.TEAM2_FULL] = []

	chess_serial = 1000

	battle_meter.battle_data = {}

	current_round = 0
	DataManagerSingleton.won_rounds = 0
	DataManagerSingleton.lose_rounds = 0

	shop_handler.shop_init()
	new_round_prepare_start()

func new_round_prepare_start():
	# start shopping
	current_shop_level.text = "Current Shop Level is : " + str(shop_handler.shop_level)
	update_population()
	
	current_round += 1
	
	current_round_label.text = "Current round : " + str(current_round)
	
	if not shop_handler.is_shop_frozen:
		shop_handler.shop_refresh()

	game_turn_finished.emit()

	clear_play_area(arena)
	if saved_arena_team.size() != 0:
		load_arena_team()
	chess_mover.setup_before_turn_start()
	shop_handler.turn_start_income(current_round)

func new_round_prepare_end():
	game_turn_started.emit()
	battle_meter.battle_data = {}
	#if saved_arena_team.size() == 0:
	team_dict[Team.TEAM1_FULL] = []
	var player_max_hp_sum = 0
	# for node in get_tree().get_nodes_in_group("chess_group"):
	# 	if node is Obstacle and node.current_play_area == node.play_areas.playarea_arena and node.team == 1:
	# 		team_dict[Team.TEAM1_FULL].append(node)
	# 		player_max_hp_sum += node.max_hp
	for chess_index in arena.unit_grid.get_all_units():
		if chess_index is Chess and chess_index.team == 1:
			team_dict[Team.TEAM1_FULL].append(chess_index)
			player_max_hp_sum += chess_index.max_hp			
	save_arena_team()

	if DataManagerSingleton.difficulty == 1:
		generate_enemy(min(player_max_hp_sum, current_round * 200, shop_handler.shop_level * 200))

	elif DataManagerSingleton.difficulty == 2:
		generate_enemy(max(player_max_hp_sum * 1.2, current_round * 200, shop_handler.shop_level * 200))

	elif DataManagerSingleton.difficulty == 3:
		generate_enemy(max(player_max_hp_sum * 1.5, current_round * 300, shop_handler, shop_handler.shop_level * 300))

	faction_bonus_manager.bonus_refresh()

	chess_appearance(arena)

func start_new_round():
	# if start new turn, it will be fully auto.
	print("Start new round.")
	var team1_alive_cnt = 0
	var team2_alive_cnt = 0
	team_dict[Team.TEAM1] = []
	team_dict[Team.TEAM2] = []
	for chess_index in team_dict[Team.TEAM1_FULL]:
		if is_instance_valid(chess_index):
			if chess_index.status != chess_class.STATUS.DIE:
				team_dict[Team.TEAM1].append(chess_index)
				team1_alive_cnt += 1
	for chess_index in team_dict[Team.TEAM2_FULL]:
		if is_instance_valid(chess_index):
			if chess_index.status != chess_class.STATUS.DIE:
				team_dict[Team.TEAM2].append(chess_index)
				team2_alive_cnt += 1
			
	if team1_alive_cnt == 0:
		round_finished.emit("team2")
		return
	elif team2_alive_cnt == 0:
		round_finished.emit("team1")
		return
		
	# current_team = [Team.TEAM1, Team.TEAM2][randi() % 2]

	
	current_team = Team.TEAM1

	start_chess_turn(current_team)

func start_chess_turn(team: Team) -> bool:
	while team_dict[team].size() > 0:
		team_chars = sort_characters(team, current_chess_active_order)
		var current_chess = team_chars.pop_front()
		if is_instance_valid(current_chess) and current_chess is Obstacle and current_chess.status != current_chess.STATUS.DIE:
			if chess_mover._get_play_area_for_position(current_chess.global_position) == 0:
				process_character_turn(current_chess)
				return true
			elif chess_mover._get_play_area_for_position(current_chess.global_position) == 1:
				active_chess = current_chess
				active_chess.is_active = true
				#active_chess.start_turn()
				# 连接信号等待行动完成
				#active_chess.action_finished.connect(handle_character_action_finished)
				handle_character_action_finished()
				return true
	active_chess = null
	handle_character_action_finished()
	return false

func process_character_turn(chess: Obstacle):
	active_chess = chess
	active_chess.is_active = true
	#active_chess.action_finished.connect(handle_character_action_finished)
	active_chess.start_turn()
	await active_chess.action_finished
	
	handle_character_action_finished()
	# 连接信号等待行动完成

func handle_character_action_finished():
	if active_chess:
		active_chess.is_active = false
		#active_chess.action_finished.disconnect(handle_character_action_finished)

	#refresh chess status

	var new_team_dict: Dictionary = {
		Team.TEAM1: [],
		Team.TEAM2: [],
		Team.TEAM1_FULL: [],
		Team.TEAM2_FULL: []
	}

	for team_index in team_dict.keys():
		for chess_index in team_dict[team_index]:
			if is_instance_valid(chess_index) and chess_index is Obstacle and chess_index.status != chess_index.STATUS.DIE:
				new_team_dict[team_index].append(chess_index)
			else:
				chess_index.queue_free()
		team_dict[team_index] = new_team_dict[team_index]

	if current_team == Team.TEAM1 and team_dict[Team.TEAM2].size() != 0:
		current_team = Team.TEAM2
		start_chess_turn(current_team)
		
	elif current_team == Team.TEAM2 and team_dict[Team.TEAM1].size() != 0:
		current_team = Team.TEAM1
		start_chess_turn(current_team)
		
	elif team_dict[Team.TEAM2].size() != 0 or team_dict[Team.TEAM1].size() != 0:
		start_chess_turn(current_team)

	else:
		start_new_round()

func handle_round_finished(msg):
	
	if msg == "team1":
		DataManagerSingleton.won_rounds += 1
		print("Round %d over, you won!" % current_round)
		player_won_round.emit()
		last_turn_label.text = 'WON'
		add_round_finish_scene.emit('WON')
	elif msg == "team2":
		DataManagerSingleton.lose_rounds += 1
		print("Round %d over, you lose..." % current_round)
		player_lose_round.emit()
		last_turn_label.text = 'LOSE'
		add_round_finish_scene.emit('LOSE')

	print("You have won %d rounds, and lose %d rounds." % [DataManagerSingleton.won_rounds, DataManagerSingleton.lose_rounds])

	battle_meter.round_end_data_update() #update to ingame data

	if DataManagerSingleton.won_rounds >= DataManagerSingleton.max_won_rounds:
		print("You won the game!")
		player_won_game.emit()
		handle_game_end()
		return
	elif DataManagerSingleton.lose_rounds >= DataManagerSingleton.max_lose_rounds:
		print("You lose the game... Try later.")
		player_lose_game.emit()
		handle_game_end()
		return

	new_round_prepare_start()

func handle_game_end():
	DataManagerSingleton.merge_game_data()
	DataManagerSingleton.current_chess_array = []
	for chess_index in saved_arena_team.values(): #[faction, chess_name]
		DataManagerSingleton.current_chess_array.append([chess_index[0], chess_index[1]])

	# DataManagerSingleton.current_chess_array = team_dict[Team.TEAM1_FULL] # TODO, this moment team_dict maybe empty
	#Show report
	to_game_finish_scene.emit()

func sort_characters(team: Team, mode: ChessActiveOrder) -> Array:
	var chesses_team = team_dict[team]
	match mode:
		ChessActiveOrder.HIGH_HP:
			chesses_team.sort_custom(func(a, b): return a.max_hp > b.max_hp)
		ChessActiveOrder.LOW_HP:
			chesses_team.sort_custom(func(a, b): return a.max_hp < b.max_hp)
		ChessActiveOrder.NEAR_CENTER:
			chesses_team.sort_custom(func(a, b): 
				return a.position.distance_to(center_point) < b.position.distance_to(center_point))
		ChessActiveOrder.FAR_CENTER:
			chesses_team.sort_custom(func(a, b): 
				return a.position.distance_to(center_point) > b.position.distance_to(center_point))
	return chesses_team
	
func generate_enemy(difficulty : int) -> void:
	team_dict[Team.TEAM2_FULL] = []
	for node in get_tree().get_nodes_in_group("obstacle_group"):
		if node is Obstacle and node.current_play_area == node.play_areas.playarea_arena and node.team != 1:
			node.queue_free()
	var current_difficulty := 0
	var current_enemy_cnt := 0

	while current_difficulty < difficulty and current_enemy_cnt <= arena.unit_grid.size.x * arena.unit_grid.size.y / 2:
		var rand_x = randi_range(arena.unit_grid.size.x / 2, arena.unit_grid.size.x - 1)
		var rand_y = randi_range(0, arena.unit_grid.size.y - 1)
		if not arena.unit_grid.is_tile_occupied(Vector2(rand_x, rand_y)):
			var rand_character_result = generate_random_chess()

			var character = summon_chess(rand_character_result[0], rand_character_result[1], 2, arena, Vector2i(rand_x, rand_y))

			current_difficulty += character.max_hp
			current_enemy_cnt += 1
			
	
func get_random_character(faction_name: String) -> String:
	if not DataManagerSingleton.get_chess_data().has(faction_name):
		return ""
	
	var candidates = []
	var weights = []
	
	# Prepare candidate list and weight list
	for chess_name_index in DataManagerSingleton.get_chess_data()[faction_name]:
		var rarity = DataManagerSingleton.get_chess_data()[faction_name][chess_name_index]["rarity"]
		if RARITY_WEIGHTS[min(6, shop_handler.shop_level)].has(rarity) and DataManagerSingleton.get_chess_data()[faction_name][chess_name_index]["speed"] != 0:
			candidates.append(chess_name_index)
			weights.append(RARITY_WEIGHTS[min(6, shop_handler.shop_level)][rarity])
	
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
		if node is Obstacle:
			node.queue_free()

func load_arena_team():
	team_dict[Team.TEAM1_FULL] = []
	if saved_arena_team.size() != 0:
		for tile_index in saved_arena_team.keys():
			if saved_arena_team[tile_index]:

				var character = summon_chess(saved_arena_team[tile_index][0], saved_arena_team[tile_index][1], 1, arena, tile_index)
		
func save_arena_team():
	saved_arena_team = {}
	for chess_index in arena.unit_grid.units.keys():
		if not is_instance_valid(arena.unit_grid.units[chess_index]):
			arena.unit_grid.remove_unit(chess_index)
		elif arena.unit_grid.units[chess_index] is Obstacle:
			saved_arena_team[chess_index] = [arena.unit_grid.units[chess_index].faction, arena.unit_grid.units[chess_index].chess_name]

# Generates random chess based on shop level and rarity weights
func generate_random_chess():
	# --- Rarity Selection Phase ---
	# Calculate total weight for current shop level
	var total_rarity_weight := 0
	for weight in RARITY_WEIGHTS[min(6,shop_handler.shop_level)].values():
		total_rarity_weight += weight
	
	# Get random value within weight range
	var random_rarity_threshold := randi_range(0, total_rarity_weight - 1)
	
	# Determine selected rarity tier
	var accumulated_rarity_weight := 0
	var selected_rarity: String
	for rarity_type in RARITY_WEIGHTS[min(6,shop_handler.shop_level)]:
		accumulated_rarity_weight += RARITY_WEIGHTS[min(6,shop_handler.shop_level)][rarity_type]
		if accumulated_rarity_weight > random_rarity_threshold:
			selected_rarity = rarity_type
			break

	# --- Existing Chesses Tracking ---
	# Count existing chess instances (faction+name pairs)
	var existing_chess_counts := {}
	# for node in get_tree().get_nodes_in_group("chess_group"):
	# 	if node is Chess:
	# 		var composite_key = "%s_%s" % [node.faction, node.chess_name]
	# 		existing_chess_counts[composite_key] = existing_chess_counts.get(composite_key, 0) + 1
	for chess_index in (arena.unit_grid.get_all_units() + bench.unit_grid.get_all_units()):
		if chess_index is Chess:
			var composite_key = "%s_%s" % [chess_index.faction, chess_index.chess_name]
			existing_chess_counts[composite_key] = existing_chess_counts.get(composite_key, 0) + 1	

	# --- Eligible Chesses Filtering ---
	var candidate_chesses := []
	var total_weight_pool := 0
	
	# Pre-process all eligible chesses with calculated weights
	for faction in DataManagerSingleton.get_chess_data():
		# Skip special faction
		if faction == "villager":
			continue
			
		for chess_name in DataManagerSingleton.get_chess_data()[faction]:
			var chess_attributes = DataManagerSingleton.get_chess_data()[faction][chess_name]
			
			# Validation checks
			if chess_attributes["speed"] == 0 || chess_attributes["rarity"] != selected_rarity:
				continue
				
			# Calculate dynamic weight with duplicate penalty
			var chess_identifier = "%s_%s" % [faction, chess_name]
			var base_weight = RARITY_WEIGHTS[min(6, shop_handler.shop_level)][chess_attributes["rarity"]]
			var duplicate_penalty = existing_chess_counts.get(chess_identifier, 0)
			var final_weight = max(base_weight - duplicate_penalty, 1)  # Ensure minimum weight
			
			# Register candidate chess
			total_weight_pool += final_weight
			candidate_chesses.append({
				"faction": faction,
				"name": chess_name,
				"weight": final_weight,
				"cumulative_weight": total_weight_pool
			})

	# --- Weighted Random Selection ---
	if candidate_chesses.size() == 0:
		push_warning("No eligible chesses found for rarity: %s" % selected_rarity)
		return ["human", "ShieldMan"]  # Fallback
	
	var random_chess_point := randi_range(0, total_weight_pool - 1)
	for chess in candidate_chesses:
		if chess["cumulative_weight"] > random_chess_point:
			return [chess["faction"], chess["name"]]
	
	# Should never reach here if candidates exist
	return ["human", "ShieldMan"]


func chess_appearance(play_area: PlayArea):

	var area_chess_count = 0
	var current_chess_count := 0
	var before_appreance_height := 999

	for chess_index in team_dict[Team.TEAM1_FULL]:
		area_chess_count += 1
		chess_index.visible = false
	for chess_index in team_dict[Team.TEAM2_FULL]:
		area_chess_count += 1
		chess_index.visible = false


	if appearance_tween:
		appearance_tween.kill() # Abort the previous animation.
	appearance_tween = create_tween()
	appearance_tween.connect("finished", 
		func():
			if current_chess_count >= area_chess_count or true:
				chess_appearance_finished.emit(play_area)
	)

	for chess_index in team_dict[Team.TEAM1_FULL]:
		current_chess_count += 1
		chess_index.global_position.y -= before_appreance_height
		chess_index.visible = true
		appearance_tween.tween_property(chess_index, "global_position", chess_index.global_position + Vector2(0, before_appreance_height) , 0.5)

	for chess_index in team_dict[Team.TEAM2_FULL]:
		current_chess_count += 1
		chess_index.global_position.y -= before_appreance_height
		chess_index.visible = true
		appearance_tween.tween_property(chess_index, "global_position", chess_index.global_position + Vector2(0, before_appreance_height) , 0.5)

	# position_tween.tween_property(self, "global_position", target_pos, 0.1)

	
func get_next_serial() -> int:
	chess_serial += 1
	return chess_serial


func summon_chess(summon_chess_faction: String, summon_chess_name: String, team: int, summon_arena: PlayArea, summon_position: Vector2i):

	if not summon_chess_faction in DataManagerSingleton.get_chess_data().keys():
		return null
	if not summon_chess_name in DataManagerSingleton.get_chess_data()[summon_chess_faction].keys():
		return null

	var summoned_character
	if DataManagerSingleton.get_chess_data()[summon_chess_faction][summon_chess_name]["speed"] == 0:
		summoned_character = obstacle_scene.instantiate()
	else:
		summoned_character = chess_scene.instantiate()

	summoned_character.faction = summon_chess_faction
	summoned_character.chess_name = summon_chess_name
	summoned_character.team = team
	summoned_character.arena = arena
	summoned_character.bench = bench
	summoned_character.shop = shop
	summoned_character.chess_serial = get_next_serial()
	add_child(summoned_character)
	summoned_character._load_chess_stats()

	debug_handler.connect_to_chess_signal(summoned_character)
	chess_mover.setup_chess(summoned_character)
	chess_mover._move_chess(summoned_character, summon_arena, summon_position)
	chess_information.setup_chess(summoned_character)

	summoned_character.damage_taken.connect(battle_meter.get_damage_data)

	summoned_character.damage_applied.connect(battle_value_display.bind("damage_applied"))
	summoned_character.critical_damage_applied.connect(battle_value_display.bind("critical_damage_applied"))
	summoned_character.heal_taken.connect(battle_value_display.bind("heal_taken"))
	summoned_character.attack_evased.connect(battle_value_display.bind(0, "attack_evased"))
	summoned_character.is_died.connect(battle_value_display.bind("is_died"))

	summoned_character.spell_casted.connect(AudioManagerSingleton.play_sfx.bind("spell_casted"))
	summoned_character.ranged_attack_started.connect(AudioManagerSingleton.play_sfx.bind("ranged_attack_started"))
	summoned_character.melee_attack_started.connect(AudioManagerSingleton.play_sfx.bind("melee_attack_started"))
	summoned_character.projectile_lauched.connect(AudioManagerSingleton.play_sfx.bind("projectile_lauched"))
	summoned_character.damage_taken.connect(AudioManagerSingleton.play_sfx.unbind(2).bind("damage_taken"))
	summoned_character.critical_damage_taken.connect(AudioManagerSingleton.play_sfx.unbind(2).bind("critical_damage_taken"))
	summoned_character.heal_taken.connect(AudioManagerSingleton.play_sfx.unbind(2).bind("heal_taken"))
	summoned_character.attack_evased.connect(AudioManagerSingleton.play_sfx.unbind(1).bind("attack_evased"))
	summoned_character.is_died.connect(AudioManagerSingleton.play_sfx.bind("is_died"))

	summoned_character.is_died.connect(DataManagerSingleton.record_death_chess)
	summoned_character.is_died.connect(chess_death_handle)

	if team == 1 and summon_arena != shop:
		team_dict[Team.TEAM1_FULL].append(summoned_character)
		team_dict[Team.TEAM1].append(summoned_character)
	elif team == 2 and summon_arena != shop:
		team_dict[Team.TEAM2_FULL].append(summoned_character)
		team_dict[Team.TEAM2].append(summoned_character)
		
	return summoned_character

func update_population():
	current_population = 0
	# for node in get_tree().get_nodes_in_group("chess_group"):
	# 	if is_instance_valid(node) and node is Chess and node.current_play_area == node.play_areas.playarea_arena and node.team == 1:
	# 		current_population += 1
	for chess_index in arena.unit_grid.get_all_units():
		if is_instance_valid(chess_index) and chess_index is Chess and chess_index.team == 1:
			current_population += 1
	max_population = shop_handler.get_max_population()
	population_label.text = "Population = " + str(current_population)	+ "/" + str(max_population)
	var label_settings = LabelSettings.new()
	if current_population > max_population:
		label_settings.font_color = Color.RED
	elif current_population == max_population:
		label_settings.font_color = Color.YELLOW
	else:
		label_settings.font_color = Color.GREEN
	label_settings.font_size = 4
	population_label.label_settings = label_settings
	faction_bonus_manager.bonus_refresh()

func chess_death_handle(obstacle: Obstacle):

	arena.unit_grid.remove_unit(obstacle.get_current_tile(obstacle)[1])

func control_shaker(control: Control):
	var old_position = control.global_position
	var shake_count = randi_range(4, 6)
	var remain_shake_count = shake_count
	var shake_tween
	if shake_tween:
		shake_tween.kill() # Abort the previous animation.
	shake_tween = create_tween()
	for shake_index in range(shake_count):
		var rand_x = randi_range(-3, 3)
		var rand_y = randi_range(-3, 3)
		shake_tween.tween_property(control, "global_position", old_position + Vector2(rand_x, rand_y), 0.05)
		shake_tween.tween_property(control, "global_position", old_position, 0.1)
		


func _on_back_button_pressed() -> void:
	to_menu_scene.emit()

func battle_value_display(chess: Obstacle, chess2: Obstacle, display_value, signal_name: String):

	if display_value <= 0 and (signal_name == "damage_applied" or signal_name == "critical_damage_applied" or signal_name == "heal_taken"):
		return

	var battle_label = Label.new()
	battle_label.z_index = 6
	arena.add_child(battle_label)

	# Create a new theme
	var new_theme = Theme.new()
	
	# Load font resource
	var font = load("res://asset/font/Everyday_Tiny.ttf") as FontFile
	
	# Set font and size in theme using correct methods
	new_theme.set_font("font", "Label", font)
	
	# Apply theme to label
	battle_label.theme = new_theme
	
	var label_settings = LabelSettings.new()
	label_settings.font_size = 4
	match signal_name:
		"damage_applied":
			label_settings.font_color = Color.YELLOW
			battle_label.text = str(display_value)
		"critical_damage_applied":
			label_settings.font_color = Color.RED
			battle_label.text = "!" + str(display_value)
		"heal_taken":
			label_settings.font_color = Color.GREEN
			battle_label.text = str(display_value)
		"attack_evased":
			label_settings.font_color = Color.CYAN
			battle_label.text = "MISS"
		"is_died":
			label_settings.font_color = Color.GRAY
			battle_label.text = "RIP..."
		_:
			label_settings.font_color = Color.WHITE
			battle_label.text = ""
	battle_label.label_settings = label_settings
	
	var old_position = chess.global_position + Vector2(16, -8)
	battle_label.global_position = old_position

	var damage_tween
	if damage_tween:
		damage_tween.kill() # Abort the previous animation.
	damage_tween = create_tween().set_parallel(true)
	damage_tween.set_ease(Tween.EASE_IN_OUT)
	damage_tween.set_trans(Tween.TRANS_CUBIC)
	damage_tween.tween_property(battle_label, "global_position", old_position + Vector2(0, -16), 1.0)
	damage_tween.tween_property(battle_label,"modulate.a", 0.0, 1.0)
	await damage_tween.finished
	damage_tween.kill()
	battle_label.queue_free()
