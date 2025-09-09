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
	"demon" : [2, 4, 6]	
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
var player_bonus_level_dict_template : Dictionary = {
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

	for node in faction_container.get_children():
		node.queue_free()

	var player_faction_count = player_faction_count_template.duplicate()
	var player_bonus_level_dict = player_bonus_level_dict_template.duplicate()

	for chess_index in arena.unit_grid.units.values(): #summary all uniqe chess

		if not is_instance_valid(chess_index) or not chess_index is Chess:
			continue

		clean_chess_faction_bonus(chess_index)

		if not player_faction_count[chess_index.team][chess_index.faction].has(chess_index.chess_name):
			player_faction_count[chess_index.team][chess_index.faction].append(chess_index.chess_name)

	for player_index in player_faction_count.keys(): # summary each team, each faction uniqe chess count and bonus level 
		for faction_index in bonus_level_list.keys():
			var bonus_level = 0
			for level_value in bonus_level_list[faction_index]:
				if player_faction_count[player_index][faction_index].size() >= level_value:
					bonus_level += 1
			player_bonus_level_dict[player_index][faction_index] = min(bonus_level, 3)
			if player_index == 1 and player_bonus_level_dict[player_index][faction_index] > 0:
				add_bonus_bar_to_container(faction_index, player_bonus_level_dict[player_index][faction_index])

	for faction_index in player_bonus_level_dict[1].keys():	#apply bonus to each player/faction 
		for player_index in player_faction_count.keys(): #[1, 2]
			var curren_bonus_level = player_bonus_level_dict[player_index][faction_index]
			if curren_bonus_level > 0:
				apply_faction_bonus(faction_index, curren_bonus_level, player_index)

func add_bonus_bar_to_container(faction: String, level: int):

	var faction_fill_texture
	match faction:
		"elf":
			faction_fill_texture = preload("res://asset/sprite/icon/elf_bonus_fill.png")
		"human":
			faction_fill_texture = preload("res://asset/sprite/icon/human_bonus_fill.png")
		"dwarf":
			faction_fill_texture = preload("res://asset/sprite/icon/dwarf_bonus_fill.png")
		"holy":
			faction_fill_texture = preload("res://asset/sprite/icon/holy_bonus_fill.png")
		"forestProtector":
			faction_fill_texture = preload("res://asset/sprite/icon/forestProtector_bonus_fill.png")
		"demon":
			faction_fill_texture = preload("res://asset/sprite/icon/elf_bonus_fill.png")
		"undead":
			faction_fill_texture = preload("res://asset/sprite/icon/elf_bonus_fill.png")
		_:
			faction_fill_texture = preload("res://asset/sprite/icon/elf_bonus_fill.png")

	var faction_bonus_bar = faction_bonus_bar_scene.instantiate()
	var style_box_texture = StyleBoxTexture.new()
	style_box_texture.texture = faction_fill_texture
	faction_bonus_bar.add_theme_stylebox_override("fill", style_box_texture)
	faction_container.add_child(faction_bonus_bar)
	faction_bonus_bar.bonus_bar.value = level
	faction_bonus_bar.bonus_bar.max_value = bonus_level_list[faction].size()
	faction_bonus_bar.label.text = faction
	

	# var fill_style = StyleBoxTexture.new()
	# fill_style.texture = faction_fill_texture
	# fill_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	# fill_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT

	# var progress_bar = ProgressBar.new()
	# var max_level = bonus_level_list[faction].back()
	# var current_level = max(0, min(max_level, level))

	# progress_bar.max_value = max_level
	# progress_bar.value = current_level
	# progress_bar.step = 1
	# progress_bar.add_theme_stylebox_override("fill", fill_style)
	# progress_bar.custom_minimum_size = Vector2(64, 8)
	# faction_container.add_child(progress_bar)



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
