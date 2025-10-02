class_name DataManager
extends Node

var player_datas := {}
var player_data_template : Dictionary = {
	"total_gems": 0,
	"total_experience": 0,
	"enemy_death_count": 0,
	"enemy_death_array": [],
	"ally_death_count": 0,
	"ally_death_array": [],
	"total_won_round": 0,
	"total_lose_round": 0,
	"total_won_game": 0,
	"total_lose_game": 0,
	"total_coin_spend": 0,
	"total_refresh_count" : 0,
	"highest_score" : 0,
	"debug_mode" : false,
	"chess_stat" : {},
	"player_upgrade" : {}
}

var chess_stat_template = {
	"buy_count": 0,
	"sell_count": 0,
	"refresh_count" : 0,
	"max_damage": 0,
	"max_damage_taken": 0,
	"critical_attack_count": 0,
	"evase_attack_count" : 0,
	"cast_spell_count" : 0
}

var player_upgrade_template = {
	"faction_locked": {
		"elf" : false,
		"human" : false,
		"dwarf" : false,
		"holy" : true,
		"forestProtector" : true,
		"undead" : true,
		"demon" : true,
		"villager" : true
	},
	"interest_bonus" : 0.0,
	"income_bonus" : 0.0
}

var in_game_data : Dictionary

var player_data : Dictionary

var last_player : String
var current_player : String
var chess_data : Dictionary

var current_chess_array = []

var difficulty := 1

var won_rounds := 0
const max_won_rounds := 3
var lose_rounds := 0
const max_lose_rounds := 3

var version := "V1.00"

func _ready() -> void:

	in_game_data = player_data_template.duplicate()
	
	if player_datas.keys().size() != 0:
		last_player = player_datas.keys().back()
		current_player = last_player
	else:
		last_player = "Resal"
		current_player = "Resal"

	load_game_json()
	
	load_chess_stats()
	
	if not player_datas[current_player].has("debug_mode"):
		player_datas[current_player]["debug_mode"] = false
		
	if not player_datas[current_player].has("player_upgrade") or player_datas[current_player]["player_upgrade"].keys().size() == 0:
		player_datas[current_player]["player_upgrade"] = player_upgrade_template.duplicate()

# func load_game_binary():
# 	if FileAccess.file_exists("user://gamedata.dat"):
# 		var file = FileAccess.open("user://savegame.dat", FileAccess.READ)
# 		var player_datas = file.get_var(true)
# 		file.close()
# 		if player_datas.keys().has(current_player):
# 			player_data = player_datas[current_player]


func merge_game_data():
	if current_player == "":
		return

	player_datas[current_player] = merge_dictionaries(player_data, in_game_data) 	

# func save_game_binary():
# 	if current_player == "":
# 		return

# 	var file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
# 	file.store_var(player_datas, true)  # true enables full length encoding
# 	file.close()

func save_game_json():
	if current_player == "":
		return

	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	if not file:
		push_error("Failed to create savegame.json")
		return
	
	# 将字典转换为JSON字符串
	var json_string = JSON.stringify(player_datas)
	file.store_string(json_string)
	file.close()

func load_game_json():
	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	if not file:
		push_error("Failed to open savegame.json")
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	# 解析JSON
	player_datas = convert_numbers_to_int(JSON.parse_string(json_text))
	
	if player_datas == null:
		push_error("JSON parsing failed for savegame.json")
		player_datas = {}
		return
		
	if player_datas.keys().has(current_player):
		player_data = player_datas[current_player]

	if not player_datas[current_player].has("player_upgrade") or player_datas[current_player]["player_upgrade"].keys().size() == 0:
		player_datas[current_player]["player_upgrade"] = player_upgrade_template.duplicate()

func convert_numbers_to_int(data):
	if typeof(data) == TYPE_DICTIONARY:
		for key in data:
			data[key] = convert_numbers_to_int(data[key])
	elif typeof(data) == TYPE_ARRAY:
		for i in range(data.size()):
			data[i] = convert_numbers_to_int(data[i])
	elif typeof(data) == TYPE_FLOAT:
		# 如果浮点数实际上是整数
		if data == int(data):
			return int(data)
	return data

func load_chess_stats():
	var file = FileAccess.open("res://script/chess_stats.json", FileAccess.READ)
	if not file:
		push_error("Failed to open chess_stats.json")
		return
	
	var json_text = file.get_as_text()
	chess_data = JSON.parse_string(json_text)
	
	if not chess_data:
		push_error("JSON parsing failed for chess_stats.json")
		return
				
func clean_player_data(player: String = current_player):
	in_game_data = player_data_template.duplicate()

	player_datas[current_player] = player_data_template.duplicate()
	player_datas[current_player]["player_upgrade"] = player_upgrade_template.duplicate()
	save_game_json()
		
func record_death_chess(chess: Obstacle) -> void:

	if not chess is Chess:
		return

	if chess.faction in chess_data.keys() and chess.chess_name in chess_data[chess.faction].keys():
		if chess.team == 1:
			add_data_to_dict(in_game_data, ["ally_death_array"], [chess.faction, chess.chess_name])
			add_data_to_dict(in_game_data, ["ally_death_count"], 1)
		else:
			add_data_to_dict(in_game_data, ["enemy_death_array"], [chess.faction, chess.chess_name])
			add_data_to_dict(in_game_data, ["enemy_death_count"], 1)

func handle_player_won_round():
	add_data_to_dict(in_game_data, ["total_won_round"], 1)

func handle_player_won_game():
	add_data_to_dict(in_game_data, ["total_won_game"], 1)

func handle_player_lose_round():
	add_data_to_dict(in_game_data, ["total_lose_round"], 1)

func handle_player_lose_game():
	add_data_to_dict(in_game_data, ["total_lose_game"], 1)

func handle_chess_bought(chess: Obstacle):
	add_data_to_dict(in_game_data, ["chess_stat", chess.faction, chess.chess_name, "buy_count"], 1)

func handle_chess_kill(attacker: Obstacle, target: Obstacle):
	add_data_to_dict(in_game_data, ["chess_stat", attacker.faction, attacker.chess_name, "kill_count"], 1)

func handle_chess_sold(chess: Obstacle):
	add_data_to_dict(in_game_data, ["chess_stat", chess.faction, chess.chess_name, "sell_count"], 1)

func handle_chess_refreshed(chess: Obstacle):
	add_data_to_dict(in_game_data, ["chess_stat", chess.faction, chess.chess_name, "refresh_count"], 1)

func handle_coin_spend(value: int, reason: String):
	add_data_to_dict(in_game_data, ["total_coin_spend"], max(0, value))

func get_chess_data():
	return chess_data

func add_data_to_dict(dict: Dictionary, key_array: Array[String], value):
	# Navigate through the dictionary following the key array path
	var current_dict = dict
	
	# Traverse all keys except the last one to build the nested structure
	for i in range(key_array.size() - 1):
		var key = key_array[i]
		
		# If the key doesn't exist, create a new dictionary
		if not current_dict.has(key):
			current_dict[key] = {}
		
		# Move to the next level of the dictionary
		current_dict = current_dict[key]
	
	# Get the final key where we'll set the value
	var final_key = key_array[-1]
	
	# Check if the final key already exists
	if current_dict.has(final_key):
		var existing_value = current_dict[final_key]
		if value is int:
			# Handle special cases based on key naming conventions
			if final_key.begins_with("max"):
				# Take the maximum of existing and new value
				current_dict[final_key] = max(existing_value, value)
			elif final_key.begins_with("min"):
				# Take the minimum of existing and new value
				current_dict[final_key] = min(existing_value, value)
			elif final_key.ends_with("count") or final_key.begins_with("total"):
				# Sum the existing and new value
				current_dict[final_key] = existing_value + value
			else:
				# Overwrite with new value for all other cases
				current_dict[final_key] = value
		elif value is bool:
			current_dict[final_key] = existing_value or value
		elif value is Array:
			current_dict[final_key] = existing_value + value
	else:
		# Key doesn't exist, simply set the new value
		current_dict[final_key] = value

## @Check if keys are valid in dictionary
## @dict: Dictionary for key checking
## @keys: Function will trace hicharically from keys array to check if key in dictionary
## @return: bool
func check_key_valid(dict: Dictionary, keys: Array) -> bool:
	# Check if the keys array is empty
	if keys.is_empty():
		return true
	
	# Start with the root dictionary
	var current_dict = dict
	
	# Iterate through each key in the sequence
	for i in range(keys.size()):
		var key = keys[i]
		
		# Check if current level has the required key
		if not current_dict.has(key):
			return false
		
		# If this is the last key, we've successfully found the path
		if i == keys.size() - 1:
			return true
		
		# Move to the next level - check if the value is a dictionary
		var next_value = current_dict[key]
		if not next_value is Dictionary:
			# Path exists but next level is not a dictionary
			return false
		
		# Update current_dict to the next level
		current_dict = next_value
	
	# This should never be reached, but included for completeness
	return false
	
func merge_dictionaries(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
	# Create a copy of the first dictionary to avoid modifying the original
	var result = dict1.duplicate(true)
	
	# Iterate through each key-value pair in the second dictionary
	for key in dict2:
		var value2 = dict2[key]
		
		# If key doesn't exist in result, simply add it
		if not result.has(key):
			result[key] = value2
			continue
		
		var value1 = result[key]
		
		# Handle different value types based on their types
		if typeof(value1) == typeof(value2):
			match typeof(value1):
				TYPE_DICTIONARY:
					# Recursively merge dictionaries
					result[key] = merge_dictionaries(value1, value2)
				TYPE_ARRAY:
					# Concatenate arrays directly
					result[key] = value1 + value2
				TYPE_BOOL:
					# Concatenate arrays directly
					result[key] = value1 or value2
				TYPE_INT, TYPE_FLOAT:
					# Handle numeric values based on key naming conventions
					if key.begins_with("max"):
						result[key] = max(value1, value2)
					elif key.begins_with("min"):
						result[key] = min(value1, value2)
					elif key.ends_with("count"):
						result[key] = value1 + value2
					else:
						# Default behavior: replace with second dictionary's value
						result[key] = value2
				_:
					# For other types, replace with second dictionary's value
					result[key] = value2
		# if (typeof(value1) == TYPE_INT and typeof(value2) == TYPE_FLOAT) or (typeof(value1) == TYPE_FLOAT and typeof(value2) == TYPE_INT):
		# 	# Handle numeric values based on key naming conventions
		# 	if key.begins_with("max"):
		# 		result[key] = max(value1, value2)
		# 	elif key.begins_with("min"):
		# 		result[key] = min(value1, value2)
		# 	elif key.ends_with("count"):
		# 		result[key] = value1 + value2
		# 	else:
		# 		# Default behavior: replace with second dictionary's value
		# 		result[key] = value2		
		else:
			# If types don't match, replace with second dictionary's value
			result[key] = value2
	
	return result

func record_game(score: int, chess_array: Array):
	var current_game_record = []
	var datetime = Time.get_datetime_dict_from_system()
	var today_date = "log_%04d%02d%02d_%02d%02d%02d.txt" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]

	if in_game_data["total_won_game"] > 0:
		current_game_record += ["WON", today_date]
	else:
		current_game_record += ["LOSE", today_date]


	# player_data["final_team"] = []
	for chess_index in chess_array:
		if chess_index is Chess:
			current_chess_array.append([chess_index.faction, chess_index.chess_name])

	current_game_record.append(current_chess_array)

	add_data_to_dict(player_data, ["game_record"], current_game_record)

	add_data_to_dict(player_data, ["total_experience"], score)

func check_obstacle_valid(node):
	if not is_instance_valid(node):
		return false

	if not node:
		return false

	if not node is Obstacle:
		return false

	if node.visible == false:
		return false

	if node.status == node.STATUS.DIE:
		return false
		
	if node.is_queued_for_deletion():
		return false

	return true

func check_chess_valid(node):
	if not is_instance_valid(node):
		return false

	if not node:
		return false

	if not node is Chess:
		return false

	if node.visible == false:
		return false

	if node.status == node.STATUS.DIE:
		return false
		
	if node.is_queued_for_deletion():
		return false

	return true

func battle_meter_data_update(battle_data):
	for data_index in battle_data.keys():
		if data_index[3] != 1:
			continue

		add_data_to_dict(in_game_data, ["chess_stat", data_index[0], data_index[1], "max_damage"], battle_data[data_index][0])
		add_data_to_dict(in_game_data, ["chess_stat", data_index[0], data_index[1], "max_damage_taken"], battle_data[data_index][1])
		add_data_to_dict(in_game_data, ["chess_stat", data_index[0], data_index[1], "max_heal"], battle_data[data_index][2])
		add_data_to_dict(in_game_data, ["chess_stat", data_index[0], data_index[1], "max_heal_taken"], battle_data[data_index][3])
