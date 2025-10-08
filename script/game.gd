class_name Game
extends Node2D

# 预加载角色场景
const chess_scene = preload("res://scene/chess.tscn")
const obstacle_scene = preload("res://scene/obstacle.tscn")
const chess_class = preload("res://script/chess.gd")
const alternative_choice_scene = preload("res://scene/alternative_choice.tscn")
const skill_tree_scene = preload("res://scene/skill_tree.tscn")

@onready var arena: PlayArea = %arena
@onready var bench: PlayArea = %bench
@onready var shop: PlayArea = %shop
@onready var arena_unit_grid: UnitGrid = $ArenaUnitGrid
@onready var bench_unit_grid: UnitGrid = $BenchUnitGrid

@onready var arena_bound: NinePatchRect = $tilemap/arena/arena_bound
@onready var bench_bound: NinePatchRect = $tilemap/bench/bench_bound
@onready var shop_bound: NinePatchRect = $tilemap/shop/shop_bound



@onready var debug_handler: DebugHandler = %debug_handler
@onready var chess_mover: ChessMover = %chess_mover
@onready var shop_handler: ShopHandler = %shop_handler
@onready var faction_bonus_manager: FactionBonusManager = %faction_bonus_manager
@onready var damage_manager: DamageManager = $damage_manager

@onready var remain_coins_label: Label = $remain_coins_label
@onready var current_shop_level: Label = $current_shop_level
@onready var population_label: Label = $population_label
@onready var current_round_label: Label = $current_round_label
@onready var last_turn_label: Label = $last_turn_label
@onready var won_lose_round_label: Label = $won_lose_round_label

@onready var game_start_button: Button = $game_button_container/game_start_button
@onready var game_restart_button: TextureButton = $game_button_container/game_restart_button
@onready var shop_refresh_button: Button = $game_button_container/shop_refresh_button
@onready var shop_freeze_button: Button = $game_button_container/shop_freeze_button
@onready var shop_upgrade_button: Button = $game_button_container/shop_upgrade_button


@onready var back_button: TextureButton = $back_button
@onready var debug_label: Label = $debug_label
@onready var tips_label: Label = $tips_label
@onready var exclamation_mark: TextureRect = $tilemap/ui/exclamation_mark

@onready var chess_order_hp_high: Button = $chess_order_control/chess_order_hp_high
@onready var chess_order_hp_low: Button = $chess_order_control/chess_order_hp_low
@onready var chess_order_near_center: Button = $chess_order_control/chess_order_near_center
@onready var chess_order_far_center: Button = $chess_order_control/chess_order_far_center

@onready var battle_meter: BattleMeter = $battle_meter
@onready var chess_information: ChessInformation = $chess_information
@onready var arrow: CustomArrowRenderer = $arrow
@onready var game_speed_controller: GameSpeedController = $game_speed_controller
@onready var faction_bonus_button: Button = $tilemap/ui/faction_bonus_button


enum Team { TEAM1, TEAM2, TEAM1_FULL, TEAM2_FULL}
enum ChessActiveOrder { HIGH_HP, LOW_HP, NEAR_CENTER, FAR_CENTER, BUY_SEQ, RE_BUY_SEQ }
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

var current_chess_active_order := ChessActiveOrder.BUY_SEQ
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

const RARITY_WEIGHTS_UPDATE = {
	1: {
		"Common": 100,
		"Uncommon": 100,
		"Rare": 100,
		"Epic": 100,
		"Legendary": 100
	},
	2: {
		"Common": 80,
		"Uncommon": 100,
		"Rare": 100,
		"Epic": 100,
		"Legendary": 100
	},
	3: {
		"Common": 60,
		"Uncommon": 85,
		"Rare": 100,
		"Epic": 100,
		"Legendary": 100
	},
	4: {
		"Common": 45,
		"Uncommon": 75,
		"Rare": 100,
		"Epic": 100,
		"Legendary": 100
	},
	5: {
		"Common": 35,
		"Uncommon": 65,
		"Rare": 90,
		"Epic": 100,
		"Legendary": 100
	},
	6: {
		"Common": 30,
		"Uncommon": 60,
		"Rare": 85,
		"Epic": 95,
		"Legendary": 100
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
var population_record : Array = []

var faction_path_update_template = {
	"elf": {
		"path1" : 0,
		"path2" : 0,
		"path3" : 0
	},
	"human": {
		"path1" : 0,
		"path2" : 0,
		"path3" : 0
	},
	"dwarf": {
		"path1" : 0,
		"path2" : 0,
		"path3" : 0
	}	
}
var faction_path_update: Dictionary

var max_won_rounds_modifier := 0
var max_lose_rounds_modifier := 0
var remain_upgrade_count := 0

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
			game_start_button.global_position.x = -40
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
			game_start_button.global_position.x = 24
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
	game_restart_button.pressed.connect(
		func():
			var alternative_choice = alternative_choice_scene.instantiate()
			alternative_choice.get_node("Label").text = "Restart Game?"
			alternative_choice.get_node("button_container/Button1").text = "Yes"
			alternative_choice.get_node("button_container/Button2").text = "No"
			add_child(alternative_choice)
			await alternative_choice.choice_made
			alternative_choice.visible = false
			if alternative_choice.get_meta("choice") == 1:
				start_new_game()
			elif alternative_choice.get_meta("choice") == 2:
				pass
			alternative_choice.queue_free()		
	)
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
			remain_coins_label.text = "Remaining Coins   : " + str(shop_handler.remain_coins)
			if shop_handler.remain_coins >= shop_handler.get_shop_upgrade_price():
				shop_upgrade_button.disabled = false
				shop_upgrade_button.global_position.x = 24
			else:
				shop_upgrade_button.disabled = true
				shop_upgrade_button.global_position.x = -40
				
	)
	shop_handler.coins_decreased.connect(DataManagerSingleton.handle_coin_spend)
	shop_handler.coins_decreased.connect(
		func(value, reason):
			remain_coins_label.text = "Remaining Coins   : " + str(shop_handler.remain_coins)
			if shop_handler.remain_coins < shop_handler.shop_refresh_price:
				shop_refresh_button.disabled = true
				shop_refresh_button.global_position.x = -40
			else:
				shop_refresh_button.disabled = false
				shop_refresh_button.global_position.x = 24
				
			if shop_handler.remain_coins < shop_handler.get_shop_upgrade_price():
				shop_upgrade_button.disabled = true
				shop_upgrade_button.global_position.x = -40
			else:
				shop_upgrade_button.disabled = false
				shop_upgrade_button.global_position.x = 24
	)
	shop_handler.shop_upgraded.connect(
		func(value):
			var label_value = ""
			match shop_handler.shop_level:
				1:
					label_value = "I"
				2:
					label_value = "II"
				3:
					label_value = "IIII"
				4:
					label_value = "IV"
				5:
					label_value = "V"
				6:
					label_value = "VI"
				7:
					label_value = "VII"
				_:
					label_value = "I"
			current_shop_level.text = label_value
			update_population(true)
	)
	chess_appearance_finished.connect(
		func(play_area):
			if play_area == arena:
				start_new_round()
	)
	chess_mover.chess_moved.connect(
		func(chess: Obstacle, play_area: PlayArea, tile: Vector2i):
			if not is_game_turn_start:
				update_population(false)
				await check_chess_merge()
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
	
	faction_bonus_button.pressed.connect(
		func():
			var skill_tree = skill_tree_scene.instantiate()
			add_child(skill_tree)
			await skill_tree.tree_exiting
			faction_bonus_manager.bonus_refresh()
	)

	player_won_round.connect(DataManagerSingleton.handle_player_won_round)
	player_lose_round.connect(DataManagerSingleton.handle_player_lose_round)
	player_won_game.connect(DataManagerSingleton.handle_player_won_game)
	player_lose_game.connect(DataManagerSingleton.handle_player_lose_game)

	chess_mover.play_areas = [arena, bench, shop]
	#arena.bounds = Rect2i(0, 0, 6, 12)

	center_point = Vector2(tile_size.x * 16 / 2, tile_size.y * 16 / 2)
	
	debug_label.visible = DataManagerSingleton.player_data["debug_mode"]
	tips_label.visible = false
	
	shop_handler.shop_refresh()
	shop_handler.buy_human_count = 0
	current_round = 0
	
	start_new_game()

	last_turn_label.text = '-'

func _process(delta: float) -> void:
	
	var current_playarea_index = get_current_tile(get_global_mouse_position())[0]
	var current_tile = get_current_tile(get_global_mouse_position())[1]
		
	debug_label.text = current_playarea_index.name + " / " + str(current_tile)
	
	if current_playarea_index.is_tile_in_bounds(current_tile) and DataManagerSingleton.check_obstacle_valid(current_playarea_index.unit_grid.units[current_tile]):
		var mouse_position_obstacle = current_playarea_index.unit_grid.units[current_tile]
		debug_label.text += "\n" + mouse_position_obstacle.faction + " / " +  mouse_position_obstacle.chess_name
	
	if remain_upgrade_count > 0:
		exclamation_mark.visible = true
	else:
		exclamation_mark.visible = false

func _input(event: InputEvent) -> void:
	# Handle drag cancellation
	if event.is_action_pressed("refresh"):
		shop_handler.shop_manual_refresh()
	elif event.is_action_pressed("freeze"):
		shop_handler.shop_freeze()
	elif event.is_action_pressed("start"):
		new_round_prepare_end()
	elif event.is_action_pressed("upgrade"):
		shop_handler.shop_upgrade()
		
func start_new_game() -> void:

	arena_bound.visible = false
	bench_bound.visible = false
	shop_bound.visible = false
	
	DataManagerSingleton.load_game_json()
	DataManagerSingleton.in_game_data = DataManagerSingleton.player_data_template.duplicate()

	debug_handler.write_log("LOG", "Game Start.")
	
	await clear_play_area(arena)
	await clear_play_area(shop)
	await clear_play_area(bench)

	saved_arena_team = {}
	
	faction_path_update = faction_path_update_template.duplicate(true)

	team_dict[Team.TEAM1] = []
	team_dict[Team.TEAM2] = []
	team_dict[Team.TEAM1_FULL] = []
	team_dict[Team.TEAM2_FULL] = []

	chess_serial = 1000

	battle_meter.battle_data = {}

	current_round = 0
	DataManagerSingleton.win_lose_round_init()
	remain_upgrade_count = 0
	
	shop_handler.shop_init()
	update_population(true)
	new_round_prepare_start()

func new_round_prepare_start():
	# start shopping
	var label_value = ""
	match shop_handler.shop_level:
		1:
			label_value = "I"
		2:
			label_value = "II"
		3:
			label_value = "IIII"
		4:
			label_value = "IV"
		5:
			label_value = "V"
		6:
			label_value = "VI"
		7:
			label_value = "VII"
		_:
			label_value = "I"
	current_shop_level.text = label_value
	
	current_round += 1
	remain_upgrade_count += 1
	
	current_round_label.text = "Current round : " + str(current_round)
	won_lose_round_label.text = "Won rounds: " + str(DataManagerSingleton.won_rounds) + " | Lose rounds: " + str(DataManagerSingleton.lose_rounds)

	shop_handler.shop_refresh()
	shop_handler.buy_human_count = 0

	game_turn_finished.emit()

	await clear_play_area(arena)
	if saved_arena_team.size() != 0:
		load_arena_team()
		
	update_population(true)
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

	var game_difficulty
	if DataManagerSingleton.player_datas[DataManagerSingleton.current_player].has("difficulty"):
		game_difficulty = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["difficulty"]
	else:
		game_difficulty = "Normal"
		
	match game_difficulty:
		"Easy":
			generate_enemy(mid(player_max_hp_sum, current_round * 200, shop_handler.shop_level * 200))

		"Normal":
			generate_enemy(max(player_max_hp_sum * 1.2, current_round * 200, shop_handler.shop_level * 200))

		"Hard":
			generate_enemy(max(player_max_hp_sum * 1.5, current_round * 300, shop_handler, shop_handler.shop_level * 300))

		_:
			generate_enemy(max(player_max_hp_sum * 1.2, current_round * 200, shop_handler.shop_level * 200))

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
				
	# update_population(true)
			
			
	if team1_alive_cnt == 0 and team2_alive_cnt == 0:
		round_finished.emit("draw")
		return
	elif team1_alive_cnt == 0:
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
			if DataManagerSingleton.check_obstacle_valid(chess_index):
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
		
	elif team_dict[Team.TEAM2_FULL].size() == 0 and team_dict[Team.TEAM1_FULL].size() == 0:
		round_finished.emit("draw")
		
	elif team_dict[Team.TEAM1_FULL].size() == 0:
		round_finished.emit("team2")
		
	elif team_dict[Team.TEAM2_FULL].size() == 0:
		round_finished.emit("team1")

	else:
		start_new_round()

func handle_round_finished(msg):
	
	if msg == "team1":
		DataManagerSingleton.won_rounds += 1
		print("Round %d over, you won!" % current_round)
		last_turn_label.text = 'WON'
		player_won_round.emit()
		add_round_finish_scene.emit('WON')
	elif msg == "team2":
		DataManagerSingleton.lose_rounds += 1
		print("Round %d over, you lose..." % current_round)
		last_turn_label.text = 'LOSE'
		player_lose_round.emit()
		add_round_finish_scene.emit('LOSE')
	elif msg == "draw":
		print("Round %d over,draw..." % current_round)
		last_turn_label.text = 'DRAW'
		add_round_finish_scene.emit('DRAW')


	battle_meter.round_end_data_update() #update to ingame data

	if DataManagerSingleton.won_rounds >= DataManagerSingleton.max_won_rounds + DataManagerSingleton.max_won_rounds_modifier:
		player_won_game.emit()
		handle_game_end()
		return
	elif DataManagerSingleton.lose_rounds >= DataManagerSingleton.max_lose_rounds + DataManagerSingleton.max_lose_rounds_modifier:
		player_lose_game.emit()
		handle_game_end()
		return

	new_round_prepare_start()

func handle_game_end():
	DataManagerSingleton.merge_game_data()
	DataManagerSingleton.current_chess_array = []
	for chess_index in saved_arena_team.values(): #[faction, chess_name]
		DataManagerSingleton.current_chess_array.append([chess_index[0], chess_index[1]])
	
	#Show report
	if battle_meter.battle_array_sliced.size() <= 0:
		DataManagerSingleton.mvp_chess = ""
	else:
		var ally_battle_array = battle_meter.battle_array.filter(
			func(value):
				if value[0][3] == 1:
					return true
				return false			
		)
		if ally_battle_array.size() == 0:
			DataManagerSingleton.mvp_chess = ""
		else:
			DataManagerSingleton.mvp_chess = ally_battle_array[0]
			# Array[[faction, chess_name, serial, team], damage]
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
		ChessActiveOrder.BUY_SEQ:
			chesses_team.sort_custom(func(a, b): return a.chess_serial < b.chess_serial)
		ChessActiveOrder.RE_BUY_SEQ:
			chesses_team.sort_custom(func(a, b): return a.chess_serial > b.chess_serial)
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
			var rand_character_result = generate_random_chess(shop_handler.shop_level, "all")

			var character = summon_chess(rand_character_result[0], rand_character_result[1], 1, 2, arena, Vector2i(rand_x, rand_y))

			current_difficulty += character.max_hp
			current_enemy_cnt += 1
			

func clear_play_area(play_area_to_clear: PlayArea):
	await get_tree().process_frame
	var all_children = play_area_to_clear.unit_grid.get_children()
	for node in all_children:
		if node is Obstacle:
			node.free()
	await get_tree().process_frame

func load_arena_team():
	team_dict[Team.TEAM1_FULL] = []
	if saved_arena_team.size() == 0:
		return
	for tile_index in saved_arena_team.keys():
		if saved_arena_team[tile_index]:
			var character = summon_chess(saved_arena_team[tile_index][0], saved_arena_team[tile_index][1], saved_arena_team[tile_index][2], 1, arena, tile_index)
			character.total_kill_count = saved_arena_team[tile_index][3]
	
func save_arena_team():
	saved_arena_team = {}
	for chess_index in arena.unit_grid.units.keys():
		if not is_instance_valid(arena.unit_grid.units[chess_index]):
			arena.unit_grid.remove_unit(chess_index)
		elif arena.unit_grid.units[chess_index] is Chess:
			var current_obstacle = arena.unit_grid.units[chess_index]
			saved_arena_team[chess_index] = [current_obstacle.faction, current_obstacle.chess_name, current_obstacle.chess_level, current_obstacle.total_kill_count, current_obstacle.chess_serial]

					
# Generates random chess based on shop level and rarity weights
'''func generate_random_chess(generate_level: int, specific_faction: String):'''
func generate_random_chess(generate_level: int, specific_faction: String):
	# --- Rarity Selection Phase ---
	# Calculate total weight for current shop level
	var total_rarity_weight := 0
	for weight in RARITY_WEIGHTS[max(1,min(6,generate_level))].values():
		total_rarity_weight += weight
	
	# Get random value within weight range
	var random_rarity_threshold := randi_range(0, total_rarity_weight - 1)
	
	# Determine selected rarity tier
	var accumulated_rarity_weight := 0
	var selected_rarity: String
	for rarity_type in RARITY_WEIGHTS[max(1,min(6,generate_level))]:
		accumulated_rarity_weight += RARITY_WEIGHTS[max(1,min(6,generate_level))][rarity_type]
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
	for faction in DataManagerSingleton.get_chess_data().keys():
		# Skip special faction
		if DataManagerSingleton.get_chess_data().has(specific_faction) and faction != specific_faction and specific_faction != "all":
			continue # Skip all not specific faction chess

		if (specific_faction == "locked" and DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["player_upgrade"]["faction_locked"][faction]) or (faction == "villager" and specific_faction != "villager"):
			continue # Skip all locked chess and villager
			
		for chess_name in DataManagerSingleton.get_chess_data()[faction]:
			var chess_attributes = DataManagerSingleton.get_chess_data()[faction][chess_name]
			
			# Validation checks
			if (chess_attributes["speed"] == 0 and specific_faction != "villager") or chess_attributes["rarity"] != selected_rarity:
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
		return ["human", "SwordMan"]  # Fallback
	
	var random_chess_point := randi_range(0, total_weight_pool - 1)
	for chess in candidate_chesses:
		if chess["cumulative_weight"] > random_chess_point:
			return [chess["faction"], chess["name"]]
	
	# Should never reach here if candidates exist
	return ["human", "SwordMan"]
'''func generate_random_chess(generate_level: int, specific_faction: String):'''
func generate_random_chess_update(generate_level: int, specific_faction: String):
	# --- Existing Chesses Tracking ---
	# Common: inf; Uncomon: 30; Rare: 20, Epic: 10: Legendary: 10
	# Count existing chess instances (faction+name pairs)

	if not (DataManagerSingleton.get_chess_data().keys() + ["all", "locked"]).has(specific_faction):
		return ["human", "SwordMan"]

	if not [1, 2, 3, 4, 5, 6].has(generate_level):
		return ["human", "SwordMan"]

	var existing_chess_counts := {}
	for chess_index in (arena.unit_grid.get_all_units() + bench.unit_grid.get_all_units()):
		if chess_index is Chess:
			var composite_key = "%s_%s" % [chess_index.faction, chess_index.chess_name]
			existing_chess_counts[composite_key] = existing_chess_counts.get(composite_key, 0) + pow(3, chess_index.chess_level - 1)

	var chess_count_dict = {
		"Uncommon" : 30,
		"Rare" : 20,
		"Epic" : 10,
		"Legendary" : 10
	}

	var common_chess_pool : Array = []
	var other_chess_pool : Array = []
	var forbidden_faction_pool : Array = []
	match specific_faction:
		"all":
			forbidden_faction_pool.append("villager")
		"locked":
			for faction_index in DataManagerSingleton.get_chess_data().keys():
				if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["player_upgrade"]["faction_locked"][faction_index]:
					forbidden_faction_pool.append(faction_index)
			forbidden_faction_pool.append("villager")
		_:
			for faction_index in DataManagerSingleton.get_chess_data().keys():
				if faction_index != specific_faction:
					forbidden_faction_pool.append(faction_index)

	for faction_index in DataManagerSingleton.get_chess_data().keys():
		if forbidden_faction_pool.has(faction_index):
			continue

		for chess_index in DataManagerSingleton.get_chess_data()[faction_index].keys():
			var current_chess = DataManagerSingleton.get_chess_data()[faction_index][chess_index]
			if current_chess["speed"] == 0 and faction_index != "villager":
				continue

			var composite_key = "%s_%s" % [faction_index, chess_index]
			if current_chess["rarity"] == "Common":
				common_chess_pool.append(composite_key)
			else:
				var pool_count = max(0, chess_count_dict[current_chess["rarity"]] - (existing_chess_counts[composite_key] if existing_chess_counts.keys().has(composite_key) else 0))
				for i in range(pool_count):
					other_chess_pool.append(composite_key)

	common_chess_pool.shuffle()
	other_chess_pool.shuffle()

	var current_rarity_weight = RARITY_WEIGHTS_UPDATE[min(generate_level, 6)]
	var current_rarity

	var rand_for_rarity = randi_range(0, 99)
	for rarity_index in current_rarity_weight.keys():
		if rand_for_rarity <= current_rarity_weight[rarity_index]:
			current_rarity = rarity_index
			break
	if current_rarity == "Common":
		return [common_chess_pool.front().split("_", true, 1)[0], common_chess_pool.front().split("_", true, 1)[1]]
	else:
		return [other_chess_pool.front().split("_", true, 1)[0], other_chess_pool.front().split("_", true, 1)[1]]


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


func summon_chess(summon_chess_faction: String, summon_chess_name: String, chess_level: int, team: int, summon_arena: PlayArea, summon_position: Vector2i):

	if not summon_chess_faction in DataManagerSingleton.get_chess_data().keys():
		return null
	if not summon_chess_name in DataManagerSingleton.get_chess_data()[summon_chess_faction].keys():
		return null

	var summoned_character
	if DataManagerSingleton.get_chess_data()[summon_chess_faction][summon_chess_name]["speed"] == 0 and summon_chess_faction != "villager":
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
	summoned_character.chess_level = chess_level
	add_child(summoned_character)
	summoned_character._load_chess_stats()

	debug_handler.connect_to_chess_signal(summoned_character)
	chess_mover.setup_chess(summoned_character)
	chess_mover._move_chess(summoned_character, summon_arena, summon_position)
	chess_information.setup_chess(summoned_character)

	summoned_character.damage_taken.connect(battle_meter.get_damage_data)
	
	summoned_character.deal_damage.connect(damage_manager.damage_handler)

	summoned_character.damage_applied.connect(battle_value_display.bind("damage_applied"))
	summoned_character.critical_damage_applied.connect(battle_value_display.bind("critical_damage_applied"))
	summoned_character.heal_taken.connect(battle_value_display.bind("heal_taken"))
	summoned_character.attack_evased.connect(battle_value_display.bind(0, "attack_evased"))
	summoned_character.is_died.connect(battle_value_display.unbind(1).bind(0, "is_died"))

	summoned_character.is_died.connect(chess_death_handle.unbind(1))
	
	if summoned_character is Chess:
		summoned_character.kill_chess.connect(
			func(obstacle: Obstacle, target: Obstacle):
				if obstacle == target:
					return
				for chess_index in saved_arena_team.values():			
					if chess_index[4] == obstacle.chess_serial and chess_index[0] == obstacle.faction and chess_index[1] == obstacle.chess_name:
						chess_index[3] += 1
						break
		)

	if team == 1 and summon_arena != shop:
		team_dict[Team.TEAM1_FULL].append(summoned_character)
		team_dict[Team.TEAM1].append(summoned_character)
	elif team == 2 and summon_arena != shop:
		team_dict[Team.TEAM2_FULL].append(summoned_character)
		team_dict[Team.TEAM2].append(summoned_character)
		
	return summoned_character

func update_population(forced_update: bool):

	population_record = []

	if is_game_turn_start and not forced_update:
		return

	arena.unit_grid.refresh_units()
		
	current_population = 0
	for chess_index in arena.unit_grid.get_all_units():
		if DataManagerSingleton.check_chess_valid(chess_index) and chess_index.team == 1 and not population_record.has(chess_index):
			current_population += 1
			population_record.append(chess_index)
			
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
	if current_population > max_population:
		game_start_button.disabled = true
		game_start_button.global_position.x = -40
	else:
		game_start_button.disabled = false
		game_start_button.global_position.x = 24
	faction_bonus_manager.bonus_refresh()

func chess_death_handle(obstacle: Obstacle):

	arena.unit_grid.remove_unit(obstacle.get_current_tile(obstacle)[1])
	obstacle.visible = false
	if obstacle.is_active:
		obstacle.action_finished.emit(obstacle)
		
	for team_index in team_dict.values():
		if team_index.has(obstacle):
			team_index.erase(obstacle)

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
	game_speed_controller._set_preset_speed(1.0)
	to_menu_scene.emit()

func battle_value_display(chess: Obstacle, chess2: Obstacle, display_value, signal_name: String):

	if display_value <= 0 and (signal_name == "damage_applied" or signal_name == "critical_damage_applied" or signal_name == "heal_taken"):
		return

	var battle_label = Label.new()
	battle_label.z_index = 25
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

	var old_position

	match signal_name:
		"damage_applied":
			label_settings.font_color = Color.YELLOW
			battle_label.text = str(round(display_value))
			old_position = chess2.global_position + Vector2(8, -8)
		"critical_damage_applied":
			label_settings.font_color = Color.RED
			battle_label.text = "!" + str(round(display_value))
			old_position = chess2.global_position + Vector2(8, -8)
		"heal_taken":
			label_settings.font_color = Color.GREEN
			battle_label.text = str(round(display_value))
			old_position = chess.global_position + Vector2(8, -8)
		"attack_evased":
			label_settings.font_color = Color.CYAN
			battle_label.text = "MISS"
			old_position = chess.global_position + Vector2(8, -8)
		"is_died":
			label_settings.font_color = Color.GRAY
			battle_label.text = "RIP..."
			old_position = chess.global_position + Vector2(8, -8)
		_:
			label_settings.font_color = Color.WHITE
			battle_label.text = ""
			old_position = chess.global_position + Vector2(8, -8)

	battle_label.label_settings = label_settings
	
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


func check_chess_merge():

	if is_game_turn_start:
		return false

	var merge_result:= [false, false]
	for merge_level in [1, 2]:
		var merge_checked := []
		merge_result[merge_level - 1] = false
		for node in arena.unit_grid.get_children() + bench.unit_grid.get_children():
			if not DataManagerSingleton.check_chess_valid(node) or merge_checked.has([node.faction, node.chess_name]) or node.chess_level != merge_level:
				continue
			if node.team != 1:
				continue
				
			if merge_result[merge_level - 1]:
				break

			var merge_count := 0
			var wait_merge := []

			for other_node in arena.unit_grid.get_children() + bench.unit_grid.get_children():
				if not DataManagerSingleton.check_chess_valid(other_node) or merge_checked.has([other_node.faction, other_node.chess_name]) or other_node.chess_level != merge_level:
					continue
				if other_node.team != 1:
					continue

				if node.faction == other_node.faction and node.chess_name == other_node.chess_name:
					var extra_merge_count = 0
					
					extra_merge_count = 1 if other_node.total_kill_count >= 5 else 0

					merge_count += (1 + extra_merge_count)
					wait_merge.append(other_node)
					if merge_count >= 3:
						var merged_chess_faction = other_node.faction
						var merged_chess_name = other_node.chess_name
						var merged_play_area = other_node.get_current_tile(other_node)[0]
						var merged_tile = other_node.get_current_tile(other_node)[1]

						for removed_chess in wait_merge:
							var removed_chess_faction = removed_chess.faction
							var removed_chess_name = removed_chess.chess_name
							var removed_chess_play_area = removed_chess.get_current_tile(removed_chess)[0]
							var removed_chess_tile = removed_chess.get_current_tile(removed_chess)[1]

							#removed_chess_play_area.unit_grid.remove_unit(removed_chess_tile)

							removed_chess.visible = false

						var upgrade_chess 
						var merged_level = merge_level + 1
						var human_path3_level : int
						human_path3_level = min(faction_path_update["human"]["path3"], faction_bonus_manager.get_bonus_level("human", 1))
						var can_upgrade: bool
						match DataManagerSingleton.get_chess_data()[merged_chess_faction][merged_chess_name]["rarity"]:
							"Common":
								if human_path3_level >= 1:
									can_upgrade = true
								else:
									can_upgrade = false
							"Uncommon":
								if human_path3_level >= 2:
									can_upgrade = true
								else:
									can_upgrade = false
							"Rare":
								if human_path3_level >= 3:
									can_upgrade = true
								else:
									can_upgrade = false
							"Epic":
								if human_path3_level >= 4:
									can_upgrade = true
								else:
									can_upgrade = false
							_:
								can_upgrade = false
						
						if can_upgrade:
							
							var alternative_choice = alternative_choice_scene.instantiate()
							alternative_choice.get_node("button_container/Button1").text = "Upgrade"
							alternative_choice.get_node("button_container/Button2").text = "Uplevel"
							add_child(alternative_choice)
							await alternative_choice.choice_made
							alternative_choice.visible = false
							if alternative_choice.get_meta("choice") == 1:
								merged_chess_name = DataManagerSingleton.get_chess_data()[merged_chess_faction][merged_chess_name]["upgrade_chess"]
								merged_level = merge_level
							elif alternative_choice.get_meta("choice") == 2:
								pass
							upgrade_chess= summon_chess(merged_chess_faction, merged_chess_name, merged_level, 1, merged_play_area, merged_tile)
							
							alternative_choice.queue_free()
						else:
							upgrade_chess= summon_chess(merged_chess_faction, merged_chess_name, merged_level, 1, merged_play_area, merged_tile)

						merge_count = 0
						merge_result[merge_level - 1] = true
						merge_checked.append([other_node.faction, other_node.chess_name])
						break

			merge_checked.append([node.faction, node.chess_name])

	for node in arena.unit_grid.get_children() + bench.unit_grid.get_children():
		if node is Chess and node.visible == false:
			if node.is_queued_for_deletion():
				pass
			else:
				node.queue_free()

	await get_tree().process_frame
	
	if merge_result[0] or merge_result[1]:
		update_population(true)


	return merge_result[0] or merge_result[1]

func mid(a: float, b: float, c: float) -> float:
	var total_sum = a + b + c
	var min_val = min(a, min(b, c)) # min() 只能比较两个数，所以需要嵌套
	var max_val = max(a, max(b, c)) # max() 同理
	return total_sum - min_val - max_val
	
func get_current_tile(current_position: Vector2):
	var i = chess_mover._get_play_area_for_position(current_position)
	var current_tile = chess_mover.play_areas[i].get_tile_from_global(current_position)
	return [chess_mover.play_areas[i], current_tile]
