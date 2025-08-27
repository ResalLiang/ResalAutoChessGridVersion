class_name DamageMeter
extends VBoxContainer

const damage_meter_bar_scene = preload("res://scene/damage_meter_bar.tscn")

enum DAMAGE_TYPE {DAMAGE_APPLIED, DAMAGE_TAKEN, HEAL_APPLIED, HEAL_TAKEN}

var battle_data: Dictionary = {}
var damage_meter_type := DAMAGE_TYPE.DAMAGE_APPLIED


func get_damage_data(hero: Hero, value: int, attacker: Hero):
	var attacker_index = [attacker.faction, attacker.hero_name, attacker.hero_serial]
	var hero_index = [hero.faction, hero.hero_name, hero.hero_serial]

	if battle_data.has(attacker_index):
		battle_data[attacker_index][0] += value
	else:
		battle_data[attacker_index] = [0, 0, 0, 0] #[damage_applied, damage_taken, heal_applied, heal_taken]
		battle_data[attacker_index][0] += value

	if battle_data.has(hero_index):
		battle_data[hero_index][1] += value
	else:
		battle_data[hero_index] = [0, 0, 0, 0]
		battle_data[hero_index][1] += value

	update_ranking()

func get_heal_data(hero: Hero, heal_value: int, healer: Hero):
	var healer_index = [healer.faction, healer.hero_name, healer.hero_serial]
	var hero_index = [hero.faction, hero.hero_name, hero.hero_serial]

	if battle_data.has(healer_index):
		battle_data[healer_index][2] += value
	else:
		battle_data[healer_index] = [0, 0, 0, 0] #[damage_applied, damage_taken, heal_applied, heal_taken]
		battle_data[healer_index][2] += value

	if battle_data.has(hero_index):
		battle_data[hero_index][3] += value
	else:
		battle_data[hero_index] = [0, 0, 0, 0]
		battle_data[hero_index][3] += value

	update_ranking()

func update_ranking():

	for child in get_children():
		child.queue_free()
	
	var battle_array = []

	if damage_meter_type = DAMAGE_TYPE.DAMAGE_APPLIED:
		battle_array = battle_data.keys().map(func(key): return [key, battle_data[key][0]])
	elif damage_meter_type = DAMAGE_TYPE.DAMAGE_TAKEN:
		battle_array = battle_data.keys().map(func(key): return [key, battle_data[key][1]])
	elif damage_meter_type = DAMAGE_TYPE.HEAL_APPLIED:
		battle_array = battle_data.keys().map(func(key): return [key, battle_data[key][2]])
	elif damage_meter_type = DAMAGE_TYPE.HEAL_TAKEN:
		battle_array = battle_data.keys().map(func(key): return [key, battle_data[key][3]])

	battle_array.sort_custom(func(a, b): return a[1] > b[1])
	var battle_array_sliced = battle_array.slice(0, min(10, battle_array.size()))
	
	for hero in battle_array_sliced:
		var item = damage_meter_bar_scene.instantiate()
		item.init(hero[0], hero[1], battle_array_sliced[0][1], hero[1])
		add_child(item)
