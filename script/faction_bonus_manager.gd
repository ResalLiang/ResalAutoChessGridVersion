class_name FactionBonusManager
extends Node2D
const faction_bonus_bar_scene = preload("res://scene/faction_bonus_bar.tscn")

@onready var arena: PlayArea = %arena
@onready var bench: PlayArea = %bench
@onready var shop: PlayArea = %shop

@onready var faction_container : HBoxContainer = $faction_container
@onready var v_box_container_1: VBoxContainer = $faction_container/VBoxContainer1
@onready var v_box_container_2: VBoxContainer = $faction_container/VBoxContainer2
@onready var v_box_container_3: VBoxContainer = $faction_container/VBoxContainer3


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
	"speller" : [2, 4, 6],
	"satyr" : [1, 2, 3],
	"skeleton" : [1, 2, 3],
	"zombie" : [1, 2, 3],
	"warlock" : [1, 2, 3]
}

# player_faction_count for storing players chess name
var player_faction_count

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
		"speller" : [],
		"satyr" : [],
		"skeleton" : [],
		"zombie" : [],
		"warlock" : []
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
		"speller" : [],
		"satyr" : [],
		"skeleton" : [],
		"zombie" : [],
		"warlock" : []
	}
}

# player_bonus_level_dict for summary player bonus level
var player_bonus_level_dict : Dictionary = {}

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
		"speller" : 0,
		"satyr" : 0,
		"skeleton" : 0,
		"zombie" : 0,
		"warlock" : 0
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
		"speller" : 0,
		"satyr" : 0,
		"skeleton" : 0,
		"zombie" : 0,
		"warlock" : 0
	}
}

func _ready() -> void:
	player_faction_count = player_faction_count_template.duplicate(true)
	player_bonus_level_dict = player_bonus_level_dict_template.duplicate(true)

func bonus_refresh() -> void:
	
	#remove all bench and shgp faction bonus
	for chess_index in bench.unit_grid.get_all_units():
		if not is_instance_valid(chess_index) or not chess_index is Chess:
			continue
			
		clean_chess_faction_bonus(chess_index)
		
	for chess_index in shop.unit_grid.get_all_units():
		if not is_instance_valid(chess_index) or not chess_index is Chess:
			continue
			
		clean_chess_faction_bonus(chess_index)

	for node in faction_container.get_children():
		for effect_node in node.get_children():
			effect_node.queue_free()

	player_faction_count = player_faction_count_template.duplicate(true)
	player_bonus_level_dict = player_bonus_level_dict_template.duplicate(true)

	for chess_index in arena.unit_grid.get_all_units(): #summary all uniqe chess

		if not is_instance_valid(chess_index) or not chess_index is Chess:
			continue

		clean_chess_faction_bonus(chess_index)

		if not player_faction_count[chess_index.team][chess_index.faction].has([chess_index.faction, chess_index.chess_name]):
			player_faction_count[chess_index.team][chess_index.faction].append([chess_index.faction, chess_index.chess_name])

		if not player_faction_count[chess_index.team][chess_index.role].has([chess_index.faction, chess_index.chess_name]):
			player_faction_count[chess_index.team][chess_index.role].append([chess_index.faction, chess_index.chess_name])

	var bonus_count := 0
	for player_index in player_faction_count.keys(): # summary each team, each faction uniqe chess count and bonus level 
		for faction_index in bonus_level_list.keys():
			var bonus_level = 0
			for level_value in bonus_level_list[faction_index]:
				if player_faction_count[player_index][faction_index].size() >= level_value:
					bonus_level += 1
			player_bonus_level_dict[player_index][faction_index] = min(bonus_level, 3)
			if player_index == 1 and player_bonus_level_dict[player_index][faction_index] > 0:
				add_bonus_bar_to_container(faction_index, player_bonus_level_dict[player_index][faction_index], bonus_count)
				bonus_count += 1
				
	for player_index in player_faction_count.keys(): #[1, 2]
		for faction_index in player_bonus_level_dict[player_index].keys():	#apply bonus to each player/faction 
			var curren_bonus_level = player_bonus_level_dict[player_index][faction_index]
			if curren_bonus_level > 0:
				apply_faction_bonus(faction_index, curren_bonus_level, player_index)

func add_bonus_bar_to_container(faction: String, level: int, bonus_count: int):


	var faction_bonus_bar = faction_bonus_bar_scene.instantiate().duplicate()
	
	if bonus_count < 4:
		v_box_container_1.add_child(faction_bonus_bar)
	elif bonus_count < 8:
		v_box_container_2.add_child(faction_bonus_bar)
	elif bonus_count < 12:
		v_box_container_3.add_child(faction_bonus_bar)
	var bar_color : Color
	match faction:
		"elf":
			faction_bonus_bar.bar_color = Color.GREEN
			faction_bonus_bar.frame_color = "Silver"
		"human":
			faction_bonus_bar.bar_color = Color.BLUE
			faction_bonus_bar.frame_color = "Iron"
		"dwarf":
			faction_bonus_bar.bar_color = Color.RED
			faction_bonus_bar.frame_color = "Copper"
		"forestProtector":
			faction_bonus_bar.bar_color = Color.GREEN
			faction_bonus_bar.frame_color = "Iron"
		"warrior":
			faction_bonus_bar.bar_color = Color.YELLOW
			faction_bonus_bar.frame_color = "Copper"
		"ranger":
			faction_bonus_bar.bar_color = Color.GREEN
			faction_bonus_bar.frame_color = "Copper"
		"speller":
			faction_bonus_bar.bar_color = Color.BLUE
			faction_bonus_bar.frame_color = "Silver"
		"pikeman":
			faction_bonus_bar.bar_color = Color.RED
			faction_bonus_bar.frame_color = "Silver"
		"satyr":
			faction_bonus_bar.bar_color = Color.BLUE
			faction_bonus_bar.frame_color = "Copper"
		"warlock":
			faction_bonus_bar.bar_color = Color.RED
			faction_bonus_bar.frame_color = "Iron"
		"placeholder2":
			faction_bonus_bar.bar_color = Color.YELLOW
			faction_bonus_bar.frame_color = "Silver"
		_:
			faction_bonus_bar.bar_color = Color.YELLOW
			faction_bonus_bar.frame_color = "Iron"
			
	faction_bonus_bar.bar_value = bonus_level_list[faction][level - 1]
	faction_bonus_bar.label.text = faction
	

	var max_player_upgrade_level := 0
	if DataManagerSingleton.get_chess_data().keys().has(faction):
		for i in get_parent().faction_path_upgrade[faction].values():
			if i > max_player_upgrade_level:
				max_player_upgrade_level = i

		if level > max_player_upgrade_level:
			var new_material = faction_bonus_bar.frame_texture_rect.material.duplicate()
			new_material.set_shader_parameter("use_monochrome", true)
			new_material.set_shader_parameter("monochrome_color", Color(0.77, 0.77 ,0.77, 1))
			faction_bonus_bar.frame_texture_rect.material = new_material
	

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
				var effect_instance
				var effect_instance2
				
				var path2_bonus_level: int
				if applier_team == 1:
					path2_bonus_level = min(bonus_level, get_parent().faction_path_upgrade[faction]["path2"])
				elif applier_team == 2:
					path2_bonus_level = bonus_level
				
				if path2_bonus_level > 0:
					effect_instance = ChessEffect.new()
					var critical_damage_bonus 
					var critical_rate_bonus 
					match path2_bonus_level:
						1:
							critical_damage_bonus = 0
							critical_rate_bonus = 0.1
						2:
							critical_damage_bonus = 1
							critical_rate_bonus = 0.2
						3:
							critical_damage_bonus = 3
							critical_rate_bonus = 0.2

					effect_instance.register_buff("critical_rate_modifier", critical_damage_bonus, 999)
					effect_instance.register_buff("critical_damage_modifier", critical_rate_bonus, 999)
					effect_instance.effect_name = "Precise - Level " + str(path2_bonus_level)
					effect_instance.effect_type = "Faction Bonus"
					effect_instance.effect_applier = "Elf path2 Faction Bonus"
					effect_instance.effect_description = "Friendly elf chesses gain critical rate and critical damage boost."
					chess_index.effect_handler.add_to_effect_array(effect_instance)
					chess_index.effect_handler.add_child(effect_instance)
				
				var path3_bonus_level: int
				if applier_team == 1:
					path3_bonus_level = min(bonus_level, get_parent().faction_path_upgrade[faction]["path3"])
				elif applier_team == 2:
					path3_bonus_level = bonus_level
				
				if path3_bonus_level > 0:
					effect_instance2 = ChessEffect.new()
					effect_instance2.register_buff("evasion_rate_modifier", bonus_level * 0.1, 999)
					effect_instance2.effect_name = "Gentle - Level " + str(path3_bonus_level)
					effect_instance2.effect_type = "Faction Bonus"
					effect_instance2.effect_applier = "Elf path3 Faction Bonus"
					effect_instance2.effect_description = "Friendly elf chesses gain evasion rate boost."
					chess_index.effect_handler.add_to_effect_array(effect_instance2)
					chess_index.effect_handler.add_child(effect_instance2)

		"human":
			pass

		"dwarf":
			pass

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
				
			var path2_bonus_level: int
			if applier_team == 1:
				path2_bonus_level = min(bonus_level, get_parent().faction_path_upgrade[faction]["path2"])
			elif applier_team == 2:

				path2_bonus_level = bonus_level
			
			if path2_bonus_level > 0:
				var effect_instance
				for chess_index in friendly_chess:
					effect_instance = ChessEffect.new()
					effect_instance.register_buff("continuous_hp_modifier", path2_bonus_level, 999)
					# effect_instance.continuous_hp_modifier = 20 * bonus_level
					# effect_instance.continuous_hp_modifier_duration = 999
					effect_instance.register_buff("max_hp_modifier", path2_bonus_level, 999)
					# effect_instance.max_hp_modifier = 30 * bonus_level
					# effect_instance.max_hp_modifier_duration = 999
					effect_instance.effect_name = "Strong - Level " + str(path2_bonus_level)
					effect_instance.effect_type = "Faction Bonus"
					effect_instance.effect_applier = "Forest Protector path2 Faction Bonus"
					effect_instance.effect_description = "Friendly faction chesses gain Max HP boost."
					chess_index.effect_handler.add_to_effect_array(effect_instance)
					chess_index.effect_handler.add_child(effect_instance)

		"demon":
			if enemy_chess.size() <= 0:
				return

			for chess_index in enemy_chess:
				var effect_instance = ChessEffect.new()
				effect_instance.register_buff("continuous_hp_modifier", -bonus_level, bonus_level)
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
				effect_instance.register_buff("armor_modifier", -bonus_level, 999)
				effect_instance.register_buff("speed_modifier", -2, bonus_level)
				effect_instance.effect_name = "Weak - Level " + str(bonus_level)
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Undead path1 Faction Bonus"
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
				effect_instance.effect_description = "Warriors gain accumulative melee attack damage bonus when attacking the same target."
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

		"satyr":
			if friendly_chess.size() <= 0:
				return

			for chess_index in friendly_chess:
				if chess_index.role != "satyr":
					continue
				var effect_instance = ChessEffect.new()
				effect_instance.register_buff("duration_only", 0, 999)
				# effect_instance.effect_duration = 999
				effect_instance.effect_name = "SatyrSkill - Level " + str(bonus_level)
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Ranger Role Bonus"
				effect_instance.effect_description = "Satyr will disseminate healing effect when got healing."
				chess_index.effect_handler.add_to_effect_array(effect_instance)
				chess_index.effect_handler.add_child(effect_instance)

		_:
			pass
			
func clean_chess_faction_bonus(chess: Obstacle) -> void:
	var chess_effect_list = chess.effect_handler.effect_list.duplicate()
	if chess_effect_list.size() == 0:
		return

	chess.effect_handler.effect_list = []
	for effect_index in chess_effect_list:
		if not effect_index.effect_type.contains("Faction Bonus"):
			chess.effect_handler.add_to_effect_array(effect_index)

	chess.effect_handler.refresh_effects()


func get_bonus_level(faction: String, team: int) -> int:
	return player_bonus_level_dict[team][faction]
