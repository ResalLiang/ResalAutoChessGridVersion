class_name GameDataManager
extends Node

var player_datas := {}
var player_data : Dictionary = {
	"gems": 0,
	"experience": 0,
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
	"highest_score" : 0
}

var in_game_data : Dictionary

var last_player : String
var current_player : String
var chess_dict : Dictionary

func _ready() -> void:

	in_game_data = player_data.duplicate()

	load_game_binary()
	if player_datas.size() != 0:
		last_player = player_datas.keys().back()
		current_player = last_player

	load_chess_stats()


func load_game_binary():
	if FileAccess.file_exists("user://savegame.dat"):
		var file = FileAccess.open("user://savegame.dat", FileAccess.READ)
		var player_datas = file.get_var(true)
		file.close()
		if player_datas.keys().has(current_player):
			player_data = player_datas[current_player]


func save_game_binary():

	if current_player == "":
		return

	for in_game_data_index in in_game_data.keys():
		if player_data.has_key(in_game_data_index):
			match in_game_data[in_game_data_index].type:
				String:
					player_data[in_game_data_index].append(in_game_data[in_game_data_index])
				int:
					player_data[in_game_data_index] += in_game_data[in_game_data_index]

	player_datas[current_player] = player_data.duplicate()
	var file = FileAccess.open("user://savegame.dat", FileAccess.WRITE)
	file.store_var(player_datas, true)  # true enables full length encoding
	file.close()

func clean_player_data(player: String = current_player):
	in_game_data = {}
	if player in player_datas.keys():
		player_datas[player] = {}
		save_game_binary()

func load_chess_stats():
	var file = FileAccess.open("res://script/chess_stats.json", FileAccess.READ)
	if not file:
		push_error("Failed to open chess_stats.json")
		return
	
	var json_text = file.get_as_text()
	chess_dict = JSON.parse_string(json_text)
	
	if not chess_dict:
		push_error("JSON parsing failed for chess_stats.json")
		return

func record_death_chess(chess: Obstacle) -> void:

	if not chess is Chess:
		return

	if chess.faction in chess_dict.keys() and chess.chess_name in chess_dict[chess.faction].keys():
		if chess.team == 1:
			in_game_data[current_player]["ally_death_array"].append([chess.faction, chess.chess_name])
			in_game_data[current_player]["ally_death_count"] += 1
		else:
			in_game_data[current_player]["enemy_death_array"].append([chess.faction, chess.chess_name])
			in_game_data[current_player]["enemy_death_count"] += 1

func handle_player_won_round():
	in_game_data[current_player]["total_won_round"] += 1

func handle_player_won_game():
	in_game_data[current_player]["total_won_game"] += 1

func handle_player_lose_round():
	in_game_data[current_player]["total_lose_round"] += 1

func handle_player_lose_game():
	in_game_data[current_player]["total_lose_game"] += 1

func handle_coin_spend(value: int, reason: String):
	in_game_data[current_player]["total_coin_spend"] += max(0, value)
