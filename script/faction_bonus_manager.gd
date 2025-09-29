class_name FactionBonusManager
extends Node2D
const faction_bonus_bar_scene = preload("res://scene/faction_bonus_bar.tscn")

@onready var arena: PlayArea = %arena
@onready var bench: PlayArea = %bench

@onready var faction_container : VBoxContainer = $faction_container


# bonus_level_list for storing each level need chess count
var bonus_level_list : Dictionary = {
	"elf" : [2, 4, 6],
	"human" : [2, 4, 6],
	"dwarf" : [2, 4, 6],
	"holy" : [3, 6],
	"forestProtector" : [2, 4, 6],
	"undead" : [2, 4, 6],
	"demon" : [2, 4, 6],

	"warrior" : [2, 4, 6],
	"pikeman" : [2, 4, 6],
	"ranger" : [2, 4, 6],
	"knight" : [2, 4, 6],
	"speller" : [2, 4, 6]
}

# player_faction_count for storing players chess name
var player_faction_count_template : Dictionary = {
	1 : {
		"elf" : [],
		"human" : [],
		"dwarf" : [],
		"holy" : [],
		"forestProtector" : [],
		"undead" : [],
		"demon" : [],
	
		"warrior" : [],
		"pikeman" : [],
		"ranger" : [],
		"knight" : [],
		"speller" : []
	},
	2 : {
		"elf" : [],
		"human" : [],
		"dwarf" : [],
		"holy" : [],
		"forestProtector" : [],
		"undead" : [],
		"demon" : [],
	
		"warrior" : [],
		"pikeman" : [],
		"ranger" : [],
		"knight" : [],
		"speller" : []
	}
}

# player_bonus_level_dict for summary player bonus level
var player_bonus_level_dict_template : Dictionary = {
	1 : {
		"elf" : 0,
		"human" : 0,
		"dwarf" : 0,
		"holy" : 0,
		"forestProtector" : 0,
		"undead" : 0,
		"demon" : 0,
	
		"warrior" : 0,
		"pikeman" : 0,
		"ranger" : 0,
		"knight" : 0,
		"speller" : 0
	},
	2 : {
		"elf" : 0,
		"human" : 0,
		"dwarf" : 0,
		"holy" : 0,
		"forestProtector" : 0,
		"undead" : 0,
		"demon" : 0,
	
		"warrior" : 0,
		"pikeman" : 0,
		"ranger" : 0,
		"knight" : 0,
		"speller" : 0
	}
}
var player_bonus_level_dict : Dictionary = {}

func _ready() -> void:
	player_bonus_level_dict = player_bonus_level_dict_template.duplicate()

func bonus_refresh() -> void:

	for node in faction_container.get_children():
		node.queue_free()

	var player_faction_count = player_faction_count_template.duplicate()
	player_bonus_level_dict = player_bonus_level_dict_template.duplicate()

	for chess_index in arena.unit_grid.get_all_units(): #summary all uniqe chess

		if not is_instance_valid(chess_index) or not chess_index is Chess:
			continue

		clean_chess_faction_bonus(chess_index)

		if not player_faction_count[chess_index.team][chess_index.faction].has(chess_index.chess_name):
			player_faction_count[chess_index.team][chess_index.faction].append(chess_index.chess_name)

		if not player_faction_count[chess_index.team][chess_index.role].has(chess_index.chess_name):
			player_faction_count[chess_index.team][chess_index.role].append(chess_index.chess_name)

	for player_index in player_faction_count.keys(): # summary each team, each faction uniqe chess count and bonus level 
		for faction_index in bonus_level_list.keys():
			var bonus_level = 0
			for level_value in bonus_level_list[faction_index]:
				if player_faction_count[player_index][faction_index].size() >= level_value:
					bonus_level += 1
			player_bonus_level_dict[player_index][faction_index] = min(bonus_level, 3)
			if player_index == 1 and player_bonus_level_dict[player_index][faction_index] > 0:
				add_bonus_bar_to_container(faction_index, player_bonus_level_dict[player_index][faction_index])


	for player_index in player_faction_count.keys(): #[1, 2]
		for faction_index in player_bonus_level_dict[player_index].keys():	#apply bonus to each player/faction 
			var curren_bonus_level = player_bonus_level_dict[player_index][faction_index]
			if curren_bonus_level > 0:
				apply_faction_bonus(faction_index, curren_bonus_level, player_index)

func add_bonus_bar_to_container(faction: String, level: int):

	var faction_fill_texture = load(AssetPathManagerSingleton.get_asset_path("faction_bar", faction))

	var faction_bonus_bar = faction_bonus_bar_scene.instantiate()
	var style_box_texture = StyleBoxTexture.new()
	style_box_texture.texture = faction_fill_texture
	faction_bonus_bar.add_theme_stylebox_override("fill", style_box_texture)
	faction_container.add_child(faction_bonus_bar)
	faction_bonus_bar.bonus_bar.value = level
	faction_bonus_bar.bonus_bar.max_value = bonus_level_list[faction].size()
	faction_bonus_bar.label.text = faction
	

func apply_faction_bonus(faction: String, bonus_level: int, applier_team: int) -> void:

	var friendly_faction_chess : Array[Chess]
	var friendly_chess : Array[Chess]
	var enemy_chess : Array[Chess]
	
	for chess_index in arena.unit_grid.units.values():

		if not is_instance_valid(chess_index) or not chess_index is Chess:
			continue

		if chess_index.team != applier_team:
			enemy_chess.append(chess_index)
			
		if chess_index.team == applier_team and chess_index.faction == faction:
			friendly_faction_chess.append(chess_index)
			
		if chess_index.team == applier_team:
			friendly_chess.append(chess_index)


	match faction:

		"elf":
			if friendly_faction_chess.size() <= 0:
				return

			for chess_index in friendly_faction_chess:
				var effect_instance = ChessEffect.new()
				var critical_damage_bonus 
				var critical_rate_bonus 
				match bonus_level:
					1:
						critical_damage_bonus = 0
						critical_rate_bonus = 0.1
					2:
						critical_damage_bonus = 1.0
						critical_rate_bonus = 0.2
					3:
						critical_damage_bonus = 2.5
						critical_rate_bonus = 0.2

				effect_instance.register_buff("critical_rate_modifier", critical_damage_bonus, 999)
				effect_instance.register_buff("critical_damage_modifier", critical_rate_bonus, 999)
				effect_instance.effect_name = "Precise - Level " + str(bonus_level)
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Elf path2 Faction Bonus"
				effect_instance.effect_description = "Friendly elf chesses gain critical rate and critical damage boost."
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)


				effect_instance = ChessEffect.new()
				effect_instance.register_buff("evasion_rate_modifier", bonus_level * 0.1, 999)
				effect_instance.effect_name = "Gentle - Level " + str(bonus_level)
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Elf path3 Faction Bonus"
				effect_instance.effect_description = "Friendly elf chesses gain critical rate boost."
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		"human":
			pass
			# if friendly_chess.size() <= 0:
			# 	return

			# for chess_index in friendly_chess:
			# 	var effect_instance = ChessEffect.new()
			# 	effect_instance.register_buff("duration_only", 0, 999)
			# 	# effect_instance.effect_duration = 999
			# 	effect_instance.effect_name = "Wisdom - Level " + str(bonus_level)
			# 	effect_instance.effect_type = "Faction Bonus"
			# 	effect_instance.effect_applier = "Human Faction Bonus"
			# 	effect_instance.effect_description = "Every 2 times buy human chess, shop will add a villager chess."
			# 	chess_index.effect_handler.add_to_effect_array(effect_instance)
			# 	chess_index.effect_handler.add_child(effect_instance)

		"dwarf":
			pass
			# if friendly_chess.size() <= 0:
			# 	return

			# for chess_index in friendly_chess:
			# 	var effect_instance = ChessEffect.new()
			# 	effect_instance.register_buff("armor_modifier", 5 * bonus_level, 999)
			# 	# effect_instance.armor_modifier = 5 * bonus_level
			# 	# effect_instance.armor_modifier_duration = 999
			# 	effect_instance.effect_name = "Fortress - Level " + str(bonus_level)
			# 	effect_instance.effect_type = "Faction Bonus"
			# 	effect_instance.effect_applier = "Dwarf Faction Bonus"
			# 	effect_instance.effect_description = "Friendly chesses continuously gain armor boost."
			# 	chess_index.effect_handler.add_to_effect_array(effect_instance)
			# 	chess_index.effect_handler.add_child(effect_instance)

		"holy":
			if friendly_faction_chess.size() <= 0:
				return

			for chess_index in friendly_faction_chess:
				var effect_instance = ChessEffect.new()
				effect_instance.register_buff("immunity", 0, bonus_level)
				# effect_instance.immunity_duration = bonus_level
				effect_instance.effect_name = "HolyShield - Level " + str(bonus_level)
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Holy Warrior Faction Bonus"
				effect_instance.effect_description = "Friendly faction chesses gain immunity."
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)


		"forestProtector":
			if friendly_chess.size() <= 0:
				return

			for chess_index in friendly_chess:
				var effect_instance = ChessEffect.new()
				effect_instance.register_buff("continuous_hp_modifier", 20 * bonus_level, 999)
				# effect_instance.continuous_hp_modifier = 20 * bonus_level
				# effect_instance.continuous_hp_modifier_duration = 999
				effect_instance.register_buff("max_hp_modifier", 30 * bonus_level, 999)
				# effect_instance.max_hp_modifier = 30 * bonus_level
				# effect_instance.max_hp_modifier_duration = 999
				effect_instance.effect_name = "Strong - Level " + str(bonus_level)
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Forest Protector Faction Bonus"
				effect_instance.effect_description = "Friendly faction chesses gain Max HP boost."
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		"demon":
			if enemy_chess.size() <= 0:
				return

			for chess_index in enemy_chess:
				var effect_instance = ChessEffect.new()
				effect_instance.register_buff("continuous_hp_modifier", -5 * bonus_level, bonus_level)
				# effect_instance.continuous_hp_modifier = -5 * bonus_level
				# effect_instance.continuous_hp_modifier_duration = bonus_level
				effect_instance.register_buff("silenced", 0, bonus_level)
				# effect_instance.silence_duration = bonus_level
				effect_instance.effect_name = "Doom - Level " + str(bonus_level)
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Demon Faction Bonus"
				effect_instance.effect_description = "Enemy chesses suffer damage each turn."
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		"undead":
			if enemy_chess.size() <= 0:
				return

			for chess_index in enemy_chess:
				var effect_instance = ChessEffect.new()
				effect_instance.register_buff("armor_modifier", -5 * bonus_level, 999)
				# effect_instance.armor_modifier = -5 * bonus_level
				# effect_instance.armor_modifier_duration = 999
				effect_instance.register_buff("speed_modifier", -2, bonus_level)
				# effect_instance.speed_modifier = -2
				# effect_instance.speed_modifier_duration = bonus_level
				effect_instance.effect_name = "Weak - Level " + str(bonus_level)
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Undead Faction Bonus"
				effect_instance.effect_description = "Enemy chesses suffer speed and armor loss."
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		"warrior":
			if friendly_chess.size() <= 0:
				return

			for chess_index in friendly_chess:
				if chess_index.role != "warrior":
					continue
				var effect_instance = ChessEffect.new()
				effect_instance.register_buff("duration_only", 0, 999)
				# effect_instance.effect_duration = 999
				effect_instance.effect_name = "WarriorSkill - Level " + str(bonus_level)
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Warrior Role Bonus"
				effect_instance.effect_description = "Nothing happens."
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		"knight":
			if friendly_chess.size() <= 0:
				return

			for chess_index in friendly_chess:
				if chess_index.role != "knight":
					continue
				var effect_instance = ChessEffect.new()
				effect_instance.register_buff("duration_only", 0, 999)
				# effect_instance.effect_duration = 999
				effect_instance.effect_name = "KnightSkill - Level " + str(bonus_level)
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Knight Role Bonus"
				effect_instance.effect_description = "When moving more than 5 grid, friendly knights will gain damage bonus."
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		"pikeman":
			if friendly_chess.size() <= 0:
				return

			for chess_index in friendly_chess:
				if chess_index.role != "pikeman":
					continue
				var effect_instance = ChessEffect.new()
				effect_instance.register_buff("duration_only", 0, 999)
				# effect_instance.effect_duration = 999
				effect_instance.effect_name = "PikemanSkill - Level " + str(bonus_level)
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Pikeman Role Bonus"
				effect_instance.effect_description = "When B2B with other friendly pikeman, chess gain damage bonus."
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		"speller":
			if friendly_chess.size() <= 0:
				return

			for chess_index in friendly_chess:
				if chess_index.role != "speller":
					continue
				var effect_instance = ChessEffect.new()
				effect_instance.register_buff("duration_only", 0, 999)
				# effect_instance.effect_duration = 999
				effect_instance.effect_name = "SpellerSkill - Level " + str(bonus_level)
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Speller Role Bonus"
				effect_instance.effect_description = "Speller gain magic damage bonus."
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		"ranger":
			if friendly_chess.size() <= 0:
				return

			for chess_index in friendly_chess:
				if chess_index.role != "ranger":
					continue
				var effect_instance = ChessEffect.new()
				effect_instance.register_buff("duration_only", 0, 999)
				# effect_instance.effect_duration = 999
				effect_instance.effect_name = "RangerSkill - Level " + str(bonus_level)
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Ranger Role Bonus"
				effect_instance.effect_description = "All ranged ally gain penetration and decline_ratio bonus."
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

func clean_chess_faction_bonus(chess: Obstacle) -> void:
	var chess_effect_list = chess.effect_handler.effect_list.duplicate()
	if chess_effect_list.size() == 0:
		return

	chess.effect_handler.effect_list = []
	for effect_index in chess_effect_list:
		if not effect_index.effect_applier.contains("Faction Bonus"):
			chess.effect_handler.add_to_effect_array(effect_index)

	chess.effect_handler.refresh_effects()


func get_bonus_level(faction: String, team: int) -> int:
	return player_bonus_level_dict[team][faction]
