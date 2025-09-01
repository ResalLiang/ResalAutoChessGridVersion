class_name FactionBonusManager
extends Node2D

@onready var arena: PlayArea = %arena
@onready var bench: PlayArea = %bench

# bonus_level_list for storing each level need chess count
var bonus_level_list : Dictionary = {
	"elf" : [2, 4, 6],
	"human" : [2, 4, 6],
	"dwarf" : [2, 4, 6],
	"holy" : [3, 6],
	"forestProtector" : [2, 4, 6],
	"undead" : [2, 4, 6],
	"demon" : [2, 4, 6]	
}

# player_faction_count for storing players chess name
var player_faction_count : Dictionary = {
	1 : {
		"elf" : [],
		"human" : [],
		"dwarf" : [],
		"holy" : [],
		"forestProtector" : [],
		"undead" : [],
		"demon" : []
	},
	2 : {
		"elf" : [],
		"human" : [],
		"dwarf" : [],
		"holy" : [],
		"forestProtector" : [],
		"undead" : [],
		"demon" : []
	}
}

# player_bonus_level_dict for summary player bonus level
var player_bonus_level_dict : Dictionary = {
	1 : {
		"elf" : 0,
		"human" : 0,
		"dwarf" : 0,
		"holy" : 0,
		"forestProtector" : 0,
		"undead" : 0,
		"demon" : 0
	},
	2 : {
		"elf" : 0,
		"human" : 0,
		"dwarf" : 0,
		"holy" : 0,
		"forestProtector" : 0,
		"undead" : 0,
		"demon" : 0
	}
}


func bonus_refresh() -> void:
	for chess_index in arena.unit_grid.units.values():

		if not is_instance_valid(chess_index) or not chess_index is Chess:
			continue

		clean_chess_faction_bonus(chess_index)

		if not player_faction_count[chess_index.team][chess_index.faction].has(chess_index.chess_name):
			player_faction_count[chess_index.team][chess_index.faction].append(chess_index.chess_name)

	for player_index in player_faction_count.keys():
		for faction_index in bonus_level_list.keys():
			var bonus_level = 0
			for level_value in bonus_level_list[faction_index]:
				if player_faction_count[player_index][faction_index].size() >= level_value:
					bonus_level += 1
			player_bonus_level_dict[player_index][faction_index] = min(bonus_level, 3)

	for faction_index in player_bonus_level_dict[1].keys():
		for player_index in player_faction_count.keys(): #[1, 2]
			var curren_bonus_level = player_bonus_level_dict[player_index][faction_index]
			if curren_bonus_level > 0:
				apply_faction_bonus(faction_index, curren_bonus_level, player_index)

func apply_faction_bonus(faction: String, bonus_level: int, applier_team: int) -> void:

	var friendly_faction_chess : Array[Chess]
	var friendly_chess : Array[Chess]
	var enemy_chess : Array[Chess]
	
	for chess_index in arena.unit_grid.units.values():

		if not is_instance_valid(chess_index) or not chess_index is Chess:
			continue

		if chess_index.team != applier_team:
			enemy_chess.append(chess_index)
		elif chess_index.team == applier_team and chess_index.faction == faction:
			friendly_faction_chess.append(chess_index)
		elif chess_index.team == applier_team:
			friendly_chess.append(chess_index)


	match faction:

		"elf":
			if friendly_faction_chess.size() <= 0:
				return

			for chess_index in friendly_faction_chess:
				var effect_instance = ChessEffect.new()
				effect_instance.evasion_rate_modifier = 0.1 * bonus_level
				effect_instance.evasion_rate_modifier_duration = 999
				effect_instance.critical_rate_modifier = 0.1 * bonus_level
				effect_instance.critical_rate_modifier_duration = 999
				effect_instance.effect_name = "Swift"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Elf Faction Bonus"
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		"human":
			if friendly_chess.size() <= 0:
				return

			for chess_index in friendly_chess:
				var effect_instance = ChessEffect.new()
				effect_instance.continuous_mp_modifier = 20 * bonus_level
				effect_instance.continuous_mp_modifier_duration = 999
				effect_instance.effect_name = "Wisdom"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Human Faction Bonus"
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		"dwarf":
			if friendly_chess.size() <= 0:
				return

			for chess_index in friendly_chess:
				var effect_instance = ChessEffect.new()
				effect_instance.armor_modifier = 5 * bonus_level
				effect_instance.armor_modifier_duration = 999
				effect_instance.effect_name = "Fortress"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Dwarf Faction Bonus"
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		"holy":
			if friendly_faction_chess.size() <= 0:
				return

			for chess_index in friendly_faction_chess:
				var effect_instance = ChessEffect.new()
				effect_instance.immunity_duration = bonus_level
				effect_instance.effect_name = "Holy Shield"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Holy Warrior Faction Bonus"
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)


		"forestProtector":
			if friendly_chess.size() <= 0:
				return

			for chess_index in friendly_chess:
				var effect_instance = ChessEffect.new()
				effect_instance.continuous_hp_modifier = 20 * bonus_level
				effect_instance.continuous_hp_modifier_duration = 999
				effect_instance.max_hp_modifier = 30 * bonus_level
				effect_instance.max_hp_modifier_duration = 999
				effect_instance.effect_name = "Strong"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Forest Protector Faction Bonus"
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		"demon":
			if enemy_chess.size() <= 0:
				return

			for chess_index in enemy_chess:
				var effect_instance = ChessEffect.new()
				effect_instance.continuous_hp_modifier = -5 * bonus_level
				effect_instance.continuous_hp_modifier_duration = bonus_level
				effect_instance.silence_duration = bonus_level
				effect_instance.effect_name = "Doom"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Demon Faction Bonus"
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		"undead":
			if enemy_chess.size() <= 0:
				return

			for chess_index in enemy_chess:
				var effect_instance = ChessEffect.new()
				effect_instance.armor_modifier = -5 * bonus_level
				effect_instance.armor_modifier_duration = 999
				effect_instance.spd_modifier = -2
				effect_instance.spd_modifier_duration = bonus_level
				effect_instance.effect_name = "Weak"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Elf Faction Bonus"
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

func clean_chess_faction_bonus(chess: Chess) -> void:
	var chess_effect_list = chess.effect_handler.effect_list.duplicate()
	if chess_effect_list.size() == 0:
		return

	chess.effect_handler.effect_list = []
	for effect_index in chess_effect_list:
		if not effect_index.effect_applier == "Faction Bonus":
			chess.effect_handler.add_to_effect_array(effect_index)
