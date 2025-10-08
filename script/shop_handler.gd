class_name ShopHandler
extends Node2D

const max_shop_level := 6
const chess_scene = preload("res://scene/chess.tscn")
const obstacle_scene = preload("res://scene/obstacle.tscn")

@onready var chess_mover: ChessMover = %chess_mover
@onready var arena: PlayArea = %arena
@onready var bench: PlayArea = %bench
@onready var shop: PlayArea = %shop
@onready var debug_handler: DebugHandler = %debug_handler
@onready var chess_information: ChessInformation = $"../chess_information"


var shop_buy_price := 3
var shop_sell_price := 1
var shop_refresh_price := 1
var shop_upgrade_price := 3

var remain_coins := 0
var base_income := 10

var shop_level := 1

var buy_human_count := 0

signal shop_refreshed
signal shop_freezed
signal shop_unfreezed
signal chess_bought
signal chess_sold
signal coins_increased
signal coins_decreased
signal shop_upgraded
signal chess_refreshed

var freeze_dict : Dictionary

func _ready():
	shop_refreshed.connect(
		func():
			debug_handler.write_log("LOG", "Shop refreshed.")
	)
	shop_freezed.connect(
		func():
			debug_handler.write_log("LOG", "Shop freezed.")
	)
	shop_unfreezed.connect(
		func():
			debug_handler.write_log("LOG", "Shop unfreezed.")
	)
	chess_bought.connect(
		func(chess):
			debug_handler.write_log("LOG", chess.chess_name + " is bought.")
	)
	chess_bought.connect(DataManagerSingleton.handle_chess_bought)
	chess_sold.connect(
		func(chess):
			debug_handler.write_log("LOG", chess.chess_name + " is sold.")
			DataManagerSingleton.add_data_to_dict(DataManagerSingleton.in_game_data, ["chess_stat", chess.faction, chess.chess_name, "sell_count"], 1)
	)
	chess_sold.connect(DataManagerSingleton.handle_chess_sold)
	coins_increased.connect(
		func(value, reason):
			debug_handler.write_log("LOG", "Coins increase by " + str(value) + " because of " + reason + ".")
	)
	coins_decreased.connect(
		func(value, reason):
			debug_handler.write_log("LOG", "Coins decrease by " + str(value) + " because of " + reason + ".")
	)
	shop_upgraded.connect(
		func(value):
			debug_handler.write_log("LOG", "Shop upgrade to level: " + str(value) + ".")
	)
	chess_refreshed.connect(DataManagerSingleton.handle_chess_refreshed)

	if DataManagerSingleton.player_datas[DataManagerSingleton.current_player].has("debug_mode"):
		base_income = 999 if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"] else 10
	else:
		base_income = 10
		
	for y in shop.unit_grid.size.y:
		for x in shop.unit_grid.size.x:
			freeze_dict[Vector2i(x,y)] = false
			
	if DataManagerSingleton.player_data["debug_mode"]:
		shop_level = 7


func shop_init():
	remain_coins = 0 #game_start_coins
	if DataManagerSingleton.player_data["debug_mode"]:
		shop_level = 7
	else:
		shop_level = 1
	
	for y in shop.unit_grid.size.y:
		for x in shop.unit_grid.size.x:
			freeze_dict[Vector2i(x,y)] = false
	
	shop_refresh()

func shop_manual_refresh() -> void:
	if remain_coins >= shop_refresh_price:
		remain_coins -= shop_refresh_price
		coins_decreased.emit(shop_refresh_price, "refresh shop")
		shop_refresh()	

func shop_refresh() -> void:

	shop_refreshed.emit()
	
	for tile_index in shop.unit_grid.units.keys():
		if DataManagerSingleton.check_obstacle_valid(shop.unit_grid.units[tile_index]) and not freeze_dict[tile_index]:
			var current_chess = shop.unit_grid.units[tile_index]
			# DataManagerSingleton.add_data_to_dict(DataManagerSingleton.in_game_data, ["chess_stat", chess_index.faction, chess_index.chess_name, "refresh_count"], 1)
			chess_refreshed.emit(current_chess)
			shop.unit_grid.remove_unit(tile_index)
			current_chess.queue_free()	

	for i in range(min(8, shop_level + 2)):
		var shop_col_index = i % min(2, shop.unit_grid.size.x)
		var shop_row_index = floor(i / min(2, shop.unit_grid.size.x))
		if freeze_dict[Vector2i(shop_col_index, shop_row_index)]:
			continue
		# var rand_faction_index = randi_range(0, get_parent().chess_data.keys().size() - 2) # remove villager
		# var rand_faction = get_parent().chess_data.keys()[rand_faction_index]

		var rand_character_result = get_parent().generate_random_chess_update(min(6, shop_level), "all")
		var character = get_parent().summon_chess(rand_character_result[0], rand_character_result[1], 1, 1, shop, Vector2i(shop_col_index, shop_row_index))

	if DataManagerSingleton.player_data["debug_mode"]:
		var debug_chess_faction = ["human", "human", "human", "elf", "elf", "dwarf", "dwarf", "elf"]
		var debug_chess_name = ["CrossBowMan", "Mage", "ArchMage", "Queen", "Mage", "Demolitionist", "Grenadier", "PegasusRider"]
		for debug_index in range(debug_chess_faction.size()):

			var shop_col_index = debug_index % min(2, shop.unit_grid.size.x) + 2
			var shop_row_index = floor(debug_index / min(2, shop.unit_grid.size.x))
			
			if freeze_dict[Vector2i(shop_col_index, shop_row_index)]:
				continue

			var character = get_parent().summon_chess(debug_chess_faction[debug_index],debug_chess_name[debug_index], 3, 1, shop, Vector2i(shop_col_index, shop_row_index))

func shop_freeze() -> void:
	var check_all_freeze := true
	for tile_index in shop.unit_grid.units.keys():
		if freeze_dict[tile_index] == false and DataManagerSingleton.check_obstacle_valid(shop.unit_grid.units[tile_index]):
			check_all_freeze = false
			break
	
	if not check_all_freeze:
		shop_freezed.emit()
		clear_effect_animation()
		for tile_index in shop.unit_grid.units.keys():
			if DataManagerSingleton.check_obstacle_valid(shop.unit_grid.units[tile_index]):
				effect_animation_display("IceFreeze", shop, tile_index)
				freeze_dict[tile_index] = true
			else:
				freeze_dict[tile_index] = false
	else:
		shop_unfreezed.emit()
		clear_effect_animation()
		for tile_index in shop.unit_grid.units.keys():
			if DataManagerSingleton.check_obstacle_valid(shop.unit_grid.units[tile_index]) and freeze_dict[tile_index] == true:
				effect_animation_display("IceUnfreeze", shop, tile_index)
			freeze_dict[tile_index] = false


func shop_upgrade() -> void:
	var current_upgrade_price = get_shop_upgrade_price()
	if remain_coins >= current_upgrade_price and shop_level < (7 if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"] else max_shop_level):
		remain_coins -= current_upgrade_price
		coins_decreased.emit(current_upgrade_price, "upgrading shop")
		shop_level += 1
		shop_upgraded.emit(shop_level)
	elif remain_coins < current_upgrade_price:
		get_parent().control_shaker(get_parent().remain_coins_label)
	elif shop_level >= (7 if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"] else max_shop_level):
		get_parent().control_shaker(get_parent().current_shop_level)

func get_shop_upgrade_price():
	return shop_level + 2 

func get_current_difficulty():
	return shop_level * 200

func get_max_population():
	#var max_population = 999 if (shop_level == 7 and DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"]) else (shop_level + 2 + get_parent().faction_bonus_manager.get_bonus_level("human", 1))
	var max_population: int
	var extra_max_population := 0
	if shop_level == 7 and DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"]:
		max_population = 999
	else:	
		max_population = shop_level + 2
		
	if get_parent().faction_bonus_manager.get_bonus_level("human", 1) > 0:
		extra_max_population = min(get_parent().faction_bonus_manager.get_bonus_level("human", 1), get_parent().faction_path_update["human"]["path1"])

	return (max_population + extra_max_population)

func can_pay_chess(chess: Obstacle) -> bool:
	if get_chess_buy_price(chess) > remain_coins:
		return false
	else:
		return true

func buy_chess(chess: Obstacle):
	chess_bought.emit(chess)
	remain_coins -= get_chess_buy_price(chess)
	coins_decreased.emit(get_chess_buy_price(chess), "buyinging chess")

	var human_bonus_level = get_parent().faction_bonus_manager.get_bonus_level("human", 1)
	human_bonus_level = min(human_bonus_level, get_parent().faction_path_update["human"]["path2"])
	
	if human_bonus_level <= 0:
		return
	
	if chess.faction == "human":
		buy_human_count += 1
		
	var buy_human_spec = 4 - human_bonus_level
		
	if buy_human_count >= buy_human_spec:
		var add_villager_tile := Vector2i(-1, -1)
		for tile_index in shop.unit_grid.units.keys():
			if not DataManagerSingleton.check_obstacle_valid(shop.unit_grid.units[tile_index]):
				add_villager_tile = tile_index
				break
		
		if add_villager_tile != Vector2i(-1, -1):
			var rand_character_result = get_parent().generate_random_chess(human_bonus_level * 2, "villager")
			var character = get_parent().summon_chess(rand_character_result[0], rand_character_result[1], 1, 1, shop, add_villager_tile)
			buy_human_count = 0

func sell_chess(chess: Chess):
	chess_sold.emit(chess)
	remain_coins += get_chess_buy_price(chess)
	coins_increased.emit(get_chess_buy_price(chess), "selling chess")
	chess.queue_free()

func get_chess_buy_price(chess: Obstacle):
	return shop_buy_price

func get_chess_sell_price(chess: Obstacle):
	if chess is Chess:
		return chess.chess_level
	else:
		return 1

func turn_start_income(current_round: int):
	var play_interest_bonus := 0
	var player_income_bonus := 0

	if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["player_upgrade"].has("interest_bonus"):
		play_interest_bonus = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["player_upgrade"]["interest_bonus"]
	if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["player_upgrade"].has("income_bonus"):
		player_income_bonus = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["player_upgrade"]["income_bonus"]

	var turn_start_interest = min(5, floor(remain_coins * (0.1 + play_interest_bonus)))
	if turn_start_interest > 0:
		remain_coins += turn_start_interest
		coins_increased.emit(turn_start_interest, "interest")
	remain_coins += current_round - 1 + base_income + player_income_bonus
	coins_increased.emit(current_round - 1 + base_income, "routine income")


# Load appropriate animations for the chess
func effect_animation_display(effect_name: String, display_play_area: PlayArea, display_tile: Vector2i):
	var effect_animation = AnimatedSprite2D.new()
	var effect_animation_path = AssetPathManagerSingleton.get_asset_path("effect_animation", effect_name)
	var frame_offset = Vector2(0, 0)
	if ResourceLoader.exists(effect_animation_path):
		var frames = ResourceLoader.load(effect_animation_path)
		for anim_name in frames.get_animation_names():
			frames.set_animation_loop(anim_name, false)
			frames.set_animation_speed(anim_name, 16.0)
		effect_animation.sprite_frames = frames
		var frame_texture = frames.get_frame_texture("default", 0)
		frame_offset.x = -(frame_texture.region.size.x - 16) / 2.0 + 8
		frame_offset.y = -(frame_texture.region.size.y - 16) * 1.0 + 8
	else:
		push_error("Animation resource not found: " + effect_animation_path)
	add_child(effect_animation)
	effect_animation.global_position = display_play_area.get_global_from_tile(display_tile) + frame_offset
	effect_animation.z_index = 60
	effect_animation.play("default")
	await effect_animation.animation_finished

func clear_effect_animation():
	for node in get_children():
		if node is AnimatedSprite2D:
			node.queue_free()
