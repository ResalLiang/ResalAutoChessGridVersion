class_name ShopHandler
extends Node2D

const max_shop_level := 7
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
var shop_refresh_price := 3
var shop_upgrade_price := 3

var remain_coins := 0
var base_income := 10
var is_shop_frozen := false

var shop_level := 1

signal shop_refreshed
signal shop_freezed
signal shop_unfreezed
signal chess_bought
signal chess_sold
signal coins_increased
signal coins_decreased
signal shop_upgraded


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
			DataManagerSingleton.add_data_to_dict(DataManagerSingleton.in_game_data, ["chess_stat", chess.faction, chess.chess_name, "buy_count"], 1)
	)
	chess_sold.connect(
		func(chess):
			debug_handler.write_log("LOG", chess.chess_name + " is sold.")
			DataManagerSingleton.add_data_to_dict(DataManagerSingleton.in_game_data, ["chess_stat", chess.faction, chess.chess_name, "sell_count"], 1)
	)
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

	if DataManagerSingleton.player_datas[DataManagerSingleton.current_player].has("debug_mode"):
		base_income = 999 if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"] else 10
	else:
		base_income = 10


func shop_init():
	remain_coins = 0 #game_start_coins
	shop_level = 1
	is_shop_frozen = false
	shop_refresh()

func shop_manual_refresh() -> void:
	if remain_coins >= shop_refresh_price:
		remain_coins -= shop_refresh_price
		coins_decreased.emit(shop_refresh_price, "refresh shop")
		shop_refresh()	

func shop_refresh() -> void:

	shop_refreshed.emit()

	is_shop_frozen = false
	shop_unfreezed.emit()

	#for node in get_tree().get_nodes_in_group("obstacle_group"):
	for chess_index in shop.unit_grid.get_all_units():
		if chess_index is Chess:
			DataManagerSingleton.add_data_to_dict(DataManagerSingleton.in_game_data, ["chess_stat", chess_index.faction, chess_index.chess_name, "refresh_count"], 1)
			chess_index.queue_free()	

	for i in range(shop_level + 2):
		var shop_col_index = i % shop.unit_grid.size.x
		var shop_row_index = floor(i / shop.unit_grid.size.x)
		# var rand_faction_index = randi_range(0, get_parent().chess_data.keys().size() - 2) # remove villager
		# var rand_faction = get_parent().chess_data.keys()[rand_faction_index]

		var rand_character_result = get_parent().generate_random_chess(shop_level, "all")
		var character = get_parent().summon_chess(rand_character_result[0], rand_character_result[1], 1, 1, shop, Vector2i(shop_col_index, shop_row_index))

		
	var debug_chess_faction = ["human", "human", "human", "elf", "elf", "dwarf", "dwarf"]
	var debug_chess_name = ["CrossBowMan", "Mage", "ArchMage", "Queen", "Mage", "Demolitionist", "Grenadier"]
	for debug_index in range(debug_chess_faction.size()):

		var shop_col_index = debug_index % shop.unit_grid.size.x
		var shop_row_index = floor(debug_index / shop.unit_grid.size.x) + 1

		var character = get_parent().summon_chess(debug_chess_faction[debug_index],debug_chess_name[debug_index], 1, 1, shop, Vector2i(shop_col_index, shop_row_index))

func shop_freeze() -> void:
	if is_shop_frozen:
		shop_unfreezed.emit()
	else:
		shop_freezed.emit()
	is_shop_frozen = not is_shop_frozen 

func shop_upgrade() -> void:
	var current_upgrade_price = get_shop_upgrade_price()
	if remain_coins >= current_upgrade_price and shop_level < max_shop_level:
		remain_coins -= current_upgrade_price
		coins_decreased.emit(current_upgrade_price, "upgrading shop")
		shop_level += 1
		shop_upgraded.emit(shop_level)
	elif remain_coins < current_upgrade_price:
		get_parent().control_shaker(get_parent().remain_coins_label)
	elif shop_level >= max_shop_level:
		get_parent().control_shaker(get_parent().current_shop_level)

func get_shop_upgrade_price():
	return shop_level + 2 

func get_current_difficulty():
	return shop_level * 200

func get_max_population():
	return 999 if shop_level == 7 else shop_level + 2

func can_pay_chess(chess: Chess) -> bool:
	if get_chess_buy_price(chess) > remain_coins:
		return false
	else:
		return true

func buy_chess(chess: Chess):
	chess_bought.emit(chess)
	remain_coins -= get_chess_buy_price(chess)
	coins_decreased.emit(get_chess_buy_price(chess), "buyinging chess")

func sell_chess(chess: Chess):
	chess_sold.emit(chess)
	remain_coins += get_chess_buy_price(chess)
	coins_increased.emit(get_chess_buy_price(chess), "selling chess")
	chess.queue_free()

func get_chess_buy_price(chess: Chess):
	return shop_buy_price

func get_chess_sell_price(chess: Chess):
	return shop_sell_price

func turn_start_income(current_round: int):
	var play_interest_bonus := 0
	var player_income_bonus := 0

	if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["player_upgrade"].has("interest_bonus"):
		play_interest_bonus = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["player_upgrade"]["interest_bonus"]
	if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["player_upgrade"].has("income_bonus"):
		player_income_bonus = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["player_upgrade"]["income_bonus"]

	var turn_start_interest = floor(remain_coins * (0.2 + play_interest_bonus))
	if turn_start_interest > 0:
		remain_coins += turn_start_interest
		coins_increased.emit(turn_start_interest, "interest")
	remain_coins += current_round - 1 + base_income + player_income_bonus
	coins_increased.emit(current_round - 1 + base_income, "routine income")
