class_name BattleMeter
extends VBoxContainer

const battle_meter_bar_scene = preload("res://scene/battle_meter_bar.tscn")

enum DAMAGE_TYPE {DAMAGE_APPLIED, DAMAGE_TAKEN, HEAL_APPLIED, HEAL_TAKEN}

var battle_data: Dictionary = {}
var battle_meter_type := DAMAGE_TYPE.DAMAGE_APPLIED


func get_damage_data(obstacle: Obstacle, value: int, attacker: Obstacle):
	var attacker_index = [attacker.faction, attacker.chess_name, attacker.chess_serial, attacker.team]
	var chess_index = [obstacle.faction, obstacle.chess_name, obstacle.chess_serial, obstacle.team]

	if battle_data.has(attacker_index):
		battle_data[attacker_index][0] += value
	else:
		battle_data[attacker_index] = [0, 0, 0, 0] #[damage_applied, damage_taken, heal_applied, heal_taken]
		battle_data[attacker_index][0] += value

	if battle_data.has(chess_index):
		battle_data[chess_index][1] += value
	else:
		battle_data[chess_index] = [0, 0, 0, 0]
		battle_data[chess_index][1] += value

	update_ranking()

func get_heal_data(obstacle: Obstacle, value: int, healer: Obstacle):
	var healer_index = [healer.faction, healer.chess_name, healer.chess_serial, healer.team]
	var chess_index = [obstacle.faction, obstacle.chess_name, obstacle.chess_serial, obstacle.team]

	if battle_data.has(healer_index):
		battle_data[healer_index][2] += value
	else:
		battle_data[healer_index] = [0, 0, 0, 0] #[damage_applied, damage_taken, heal_applied, heal_taken]
		battle_data[healer_index][2] += value

	if battle_data.has(chess_index):
		battle_data[chess_index][3] += value
	else:
		battle_data[chess_index] = [0, 0, 0, 0]
		battle_data[chess_index][3] += value

	update_ranking()

func update_ranking():

	for child in get_children():
		child.queue_free()
	
	var battle_array = []

	if battle_meter_type == DAMAGE_TYPE.DAMAGE_APPLIED:
		battle_array = battle_data.keys().map(func(key): return [key, battle_data[key][0]])
	elif battle_meter_type == DAMAGE_TYPE.DAMAGE_TAKEN:
		battle_array = battle_data.keys().map(func(key): return [key, battle_data[key][1]])
	elif battle_meter_type == DAMAGE_TYPE.HEAL_APPLIED:
		battle_array = battle_data.keys().map(func(key): return [key, battle_data[key][2]])
	elif battle_meter_type == DAMAGE_TYPE.HEAL_TAKEN:
		battle_array = battle_data.keys().map(func(key): return [key, battle_data[key][3]])

	battle_array.sort_custom(func(a, b): return a[1] > b[1])
	var battle_array_sliced = battle_array.slice(0, min(10, battle_array.size()))
	
	for chess in battle_array_sliced:
		if chess[1] > 0:
			var item = battle_meter_bar_scene.instantiate()
			item.init(chess[0][0], chess[0][1], chess[0][3], battle_array_sliced[0][1], chess[1])
			add_child(item)
