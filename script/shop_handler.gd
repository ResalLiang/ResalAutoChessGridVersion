class_name ShopHandler
extends Node2D

const max_shop_level := 6

@onready var hero_mover: HeroMover = %hero_mover
@onready var shop: PlayArea = %shop
@onready var debug_handler: DebugHandler = %debug_handler


var shop_buy_price := 3
var shop_refresh_price := 3
var shop_upgrade_price := 3

var remain_coins := 0
var game_start_coins := 999
var is_shop_frozen := false

var shop_level := 1

signal shop_refreshed
signal shop_freezed
signal shop_unfreezed
signal hero_bought
signal hero_sold
signal coins_increased
signal coins_decreased
signal shop_upgraded


func _ready():
	shop_refreshed.connect(
		func():
			debug_handler.write_log("Shop refreshed.")
	)
	shop_freezed.connect(
		func():
			debug_handler.write_log("Shop freezed.")
	)
	shop_unfreezed.connect(
		func():
			debug_handler.write_log("Shop unfreezed.")
	)
	hero_bought.connect(
		func(hero_name):
			debug_handler.write_log(hero_name + " is bought.")
	)
	hero_sold.connect(
		func(hero_name):
			debug_handler.write_log(hero_name + " is sold.")
	)
	coins_increased.connect(
		func(value, reason):
			debug_handler.write_log("Coins increase by " + value + " because of " + reason + ".")
	)
	coins_decreased.connect(
		func(value, reason):
			debug_handler.write_log("Coins decrease by " + value + " because of " + reason + ".")
	)
	shop_upgraded.connect(
		func(value):
			debug_handler.write_log("Shop upgrade to level: " + value + ".")
	)

func shop_init():
	remain_coins = game_start_coins
	shop_level = 1
	is_shop_frozen = false
	shop_refresh()

func shop_refresh() -> void:
	if remain_coins >= shop_refresh_price:
		remain_coins -= shop_refresh_price
		shop_refreshed.emit()

		for node in get_tree().get_nodes_in_group("hero_group"):
			if node is Hero and node.current_play_area == node.play_areas.shop:
				node.queue_free()	

		for i in range(shop_level + 2):
			var shop_col_index = i % shop.unit_grid.size.x
			var shop_row_index = floor(i / shop.unit_grid.size.x)
			# var rand_faction_index = randi_range(0, get_parent().hero_data.keys().size() - 2) # remove villager
			# var rand_faction = get_parent().hero_data.keys()[rand_faction_index]
			var character = get_parent().hero_scene.instantiate()
			# character.faction = rand_faction
			# character.hero_name = get_parent().get_random_character(rand_faction)
			[character.faction, character.hero_name] = get_parent().generate_random_hero()
			character.team = 1
			add_child(character)
			debug_handler.connect_to_hero_signal(character)
			hero_mover.setup_hero(character)
			hero_mover._move_hero(character, get_parent().shop, Vector2(shop_col_index, shop_row_index))
			
		var debug_hero_faction = ["human", "human", "human", "human", "demon"]
		var debug_hero_name = ["ArcherMan", "CrossBowMan", "Mage", "ArchMage", "FireImp"]
		for debug_index in range(debug_hero_faction.size()):
			var character = get_parent().hero_scene.instantiate()
			character.faction = debug_hero_faction[debug_index]
			character.hero_name = debug_hero_name[debug_index]
			character.team = 1
			add_child(character)
			debug_handler.connect_to_hero_signal(character)
			hero_mover.setup_hero(character)
			hero_mover._move_hero(character, get_parent().shop, Vector2(debug_index, 3))
	
func shop_freeze() -> void:
	if is_shop_frozen:
		get_parent().shop_refresh_button.disabled = false
		shop_unfreezed.emit()
	else:
		get_parent().shop_refresh_button.disabled = true
		shop_freezed.emit()
	is_shop_frozen = not is_shop_frozen 

func shop_upgrade() -> void:
	if remain_coins >= shop_upgrade_price and shop_level < max_shop_level:
		remain_coins -= shop_upgrade_price
		coins_decreased.emit(shop_upgrade_price, "upgrading shop")
		shop_level += 1
		shop_upgraded.emit(shop_level)
		shop_upgrade_price += 3

func can_pay_hero(hero: Hero) -> bool:
	if get_hero_price(hero) > remain_coins:
		return false
	else:
		return true

func buy_hero(hero: Hero):
	hero_bought.emit(hero.hero_name)
	remain_coins -= get_hero_price(hero)
	coins_decreased.emit(get_hero_price(hero), "buyinging hero")

func sell_hero(hero: Hero):
	hero_sold.emit(hero.hero_name)
	remain_coins += get_hero_price(hero)
	coins_increased.emit(get_hero_price(hero), "selling hero")

func get_hero_price(hero: Hero):
	return shop_buy_price

func turn_start_income(current_round: int):
	turn_start_interest = floor(remain_coins / 5)
	remain_coins += turn_start_interest
	coins_increased.emit(turn_start_interest, "interest")
	remain_coins += current_round + 2
	coins_increased.emit(current_round + 2, "routine income")
