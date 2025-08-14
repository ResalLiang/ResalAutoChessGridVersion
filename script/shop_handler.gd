class_name ShopHandler
extends Node

const max_shop_level := 6

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
	shop_init()

func shop_init():
	remain_coins = game_start_coins
	shop_level = 1
	is_shop_frozen = false
	shop_refresh()

func shop_refresh(shop_level: int) -> void:
	if remain_coins >= shop_refresh_price:
		remain_coins -= shop_refresh_price
		shop_refreshed.emit()

		for node in get_tree().get_nodes_in_group("hero_group"):
			if node is Hero and node.current_play_area == play_areas.shop:
				node.queue_freee()	

		for i in range(shop_level + 2):
			var rand_faction_index = randi_range(0, get_parent.hero_data.keys().size() - 1)
			var rand_faction = get_parent.hero_data.keys()[rand_faction_index]
			var character = get_parent.hero_scene.instantiate()
			character.faction = rand_faction
			character.hero_name = get_parent().get_random_character(rand_faction)
			character.team = 1
			hero_mover._move_hero(character, shop, Vector2(0, i))
	
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
