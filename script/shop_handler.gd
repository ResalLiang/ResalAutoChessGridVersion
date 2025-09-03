class_name ShopHandler
extends Node2D

const max_shop_level := 7

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
var game_start_coins := 999
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
			DataManagerSingeton.add_data_to_dict(DataManagerSingleton.in_game_data, ["chess_stat", chess.faction, chess.chess_name, "buy_count"], 1)
	)
	chess_sold.connect(
		func(chess):
			debug_handler.write_log("LOG", chess.chess_name + " is sold.")
			DataManagerSingeton.add_data_to_dict(DataManagerSingleton.in_game_data, ["chess_stat", chess.faction, chess.chess_name, "sell_count"], 1)
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

# DataManagerSingeton.add_data_to_dict(DataManagerSingeton.in_game_data, ["chess_stat", chess.faction, chess.chess_name, "evase_attack_count"], 1)
# var chess_stat_sample = {
# 	"buy_count": 0,
# 	"sell_count": 0,
# 	"refresh_count" : 0,
# 	"max_damage": 0,
# 	"max_damage_taken": 0,
# 	"critical_attack_count": 0,
# 	"evase_attack_count" : 0,
# 	"cast_spell_count" : 0

func shop_init():
	remain_coins = game_start_coins
	shop_level = 1
	is_shop_frozen = false
	shop_refresh()

func shop_manual_refresh() -> void:
	if remain_coins >= shop_refresh_price:
		remain_coins -= shop_refresh_price
		shop_refresh()	

func shop_refresh() -> void:

	shop_refreshed.emit()

	is_shop_frozen = false
	shop_unfreezed.emit()

	for node in get_tree().get_nodes_in_group("obstacle_group"):
		if node is Chess and node.current_play_area == node.play_areas.playarea_shop:
			DataManagerSingeton.add_data_to_dict(DataManagerSingeton.in_game_data, ["chess_stat", node.faction, node.chess_name, "refresh_count"], 1)
			node.queue_free()	

	for i in range(shop_level + 2):
		var shop_col_index = i % shop.unit_grid.size.x
		var shop_row_index = floor(i / shop.unit_grid.size.x)
		# var rand_faction_index = randi_range(0, get_parent().chess_data.keys().size() - 2) # remove villager
		# var rand_faction = get_parent().chess_data.keys()[rand_faction_index]
		var character = get_parent().chess_scene.instantiate()
		# character.faction = rand_faction
		# character.chess_name = get_parent().get_random_character(rand_faction)
		var rand_character_result = get_parent().generate_random_chess()
		character.faction = rand_character_result[0]
		character.chess_name = rand_character_result[1]
		character.team = 1
		character.arena = arena
		character.bench = bench
		character.shop = shop
		character.chess_serial = get_parent().get_next_serial()
		add_child(character)
		debug_handler.connect_to_chess_signal(character)
		chess_mover.setup_chess(character)
		chess_mover._move_chess(character, get_parent().shop, Vector2(shop_col_index, shop_row_index))
		chess_information.setup_chess(character)
		
	var debug_chess_faction = ["human", "human", "human", "demon", "elf", "elf", "undead", "dwarf"]
	var debug_chess_name = ["CrossBowMan", "Mage", "ArchMage", "FireImp", "Queen", "Mage", "Necromancer", "Demolitionist"]
	for debug_index in range(debug_chess_faction.size()):
		var character = get_parent().chess_scene.instantiate()
		character.faction = debug_chess_faction[debug_index]
		character.chess_name = debug_chess_name[debug_index]
		character.team = 1
		character.arena = arena
		character.bench = bench
		character.shop = shop
		character.chess_serial = get_parent().get_next_serial()
		add_child(character)
		debug_handler.connect_to_chess_signal(character)
		chess_mover.setup_chess(character)
		chess_information.setup_chess(character)

		var shop_col_index = debug_index % shop.unit_grid.size.x
		var shop_row_index = floor(debug_index / shop.unit_grid.size.x) + 1

		chess_mover._move_chess(character, get_parent().shop, Vector2(shop_col_index, shop_row_index))
	
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
	var turn_start_interest = floor(remain_coins / 5)
	remain_coins += turn_start_interest
	coins_increased.emit(turn_start_interest, "interest")
	remain_coins += current_round + 2
	coins_increased.emit(current_round + 2, "routine income")
