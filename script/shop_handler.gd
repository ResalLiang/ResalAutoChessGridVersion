class_name ShopHandler
extends Node2D

const max_shop_level := 6

@onready var hero_mover: HeroMover = %hero_mover
@onready var shop: PlayArea = %shop


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

func _init():
	#shop_init()
	pass

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
			var rand_faction_index = randi_range(0, get_parent().hero_data.keys().size() - 2) # remove villager
			var rand_faction = get_parent().hero_data.keys()[rand_faction_index]
			var character = get_parent().hero_scene.instantiate()
			character.faction = rand_faction
			character.hero_name = get_parent().get_random_character(rand_faction)
			character.team = 1
			add_child(character)
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
		shop_level += 1

func can_pay_hero() -> bool:
	if shop_buy_price >= remain_coins:
		return false
	else:
		remain_coins -= shop_buy_price
		return true
