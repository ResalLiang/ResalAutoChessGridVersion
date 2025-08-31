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
	for hero_index in arena.unit_grid.units.values():

		if not is_instance_valid(hero_index) or not hero_index is Hero:
			continue

		clean_hero_faction_bonus(hero_index)

		if not player_faction_count[hero_index.team][hero_index.faction].has(hero_index.hero_name):
			player_faction_count[hero_index.team][hero_index.faction].append(hero_index.hero_name)

	for player_index in player_faction_count.keys():
		for faction_index in bonus_level_list.keys():
			var bonus_level = 0
			for level_value in bonus_level_list[faction_index]:
				if player_faction_count[player_index][faction_index].size() >= level_value:
					bonus_level += 1
			player_bonus_level_dict[player_index][faction_index] = min(bonus_level, 3)

	for hero_index in arena.unit_grid.units.values():
		if not is_instance_valid(hero_index) or not hero_index is Hero:
			continue

		var current_bonus_level
		for player_index in player_faction_count.keys():
			if hero_index.team == 1 and player_bonus_level_dict[hero_index.team][hero_index.faction] > 0:
				apply_faction_bonus(hero_index, player_bonus_level_dict[hero_index.team][hero_index.faction])

func apply_faction_bonus(faction: String, bonus_level: int, applier_team: 1) -> void:

	for hero_index in arena.unit_grid.units.values():
		var friendly_faction_hero : Array[Hero]
		var friendly_hero : Array[Hero]
		var enemy_hero : Array[Hero]

		if not is_instance_valid(hero_index) or not hero_index is Hero:
			continue

		if hero_index.team != applier_team:
			enemy_hero.append(hero_index)
		elif hero_index.team == applier_team and hero_index.faction = faction:
			friendly_faction_hero.append(hero_index)
		elif hero_index.team == applier_team:
			friendly_hero.append(hero_index)


	match hero.faction:

		"elf":
			if friendly_faction_hero.size() <= 0:
				return

			for hero_index in friendly_faction_hero:
				var effect_instance = ChessEffect.new()
				effect_instance.evasion_rate_modifier = 0.1 * bonus_level
				effect_instance.evasion_rate_modifier_duration = 999
				effect_instance.critical_rate_modifier = 0.1 * bonus_level
				effect_instance.critical_rate_modifier_duration = 999
				effect_instance.effect_name = "Swift"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Elf Faction Bonus"
				hero_index.effect_handler.effect_list.add_to_effect_array(effect_instance)
				hero_index.effect_handler.add_child(effect_instance)

		"human":
			if friendly_hero.size() <= 0:
				return

			for hero_index in friendly_hero:
				var effect_instance = ChessEffect.new()
				effect_instance.continuous_mp_modifier = 20 * bonus_level
				effect_instance.continuous_mp_modifier_duration = 999
				effect_instance.effect_name = "Wisdom"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Human Faction Bonus"
				hero_index.effect_handler.effect_list.add_to_effect_array(effect_instance)
				hero_index.effect_handler.add_child(effect_instance)

		"dwarf":
			if friendly_hero.size() <= 0:
				return

			for hero_index in friendly_hero:
				var effect_instance = ChessEffect.new()
				effect_instance.armor_modifier = 5 * bonus_level
				effect_instance.armor_modifier_duration = 999
				effect_instance.effect_name = "Fortress"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Dwarf Faction Bonus"
				hero_index.effect_handler.effect_list.add_to_effect_array(effect_instance)
				hero_index.effect_handler.add_child(effect_instance)

		"holy":
			if friendly_faction_hero.size() <= 0:
				return

			for hero_index in friendly_faction_hero:
				var effect_instance = ChessEffect.new()
				effect_instance.immunity_duration = bonus_level
				effect_instance.effect_name = "Holy Shield"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Holy Warrior Faction Bonus"
				hero_index.effect_handler.effect_list.add_to_effect_array(effect_instance)
				hero_index.effect_handler.add_child(effect_instance)


		"forestProtector":
			if friendly_hero.size() <= 0:
				return

			for hero_index in friendly_hero:
				var effect_instance = ChessEffect.new()
				effect_instance.continuous_hp_modifier = 20 * bonus_level
				effect_instance.continuous_hp_modifier_duration = 999
				effect_instance.max_hp_modifier = 30 * bonus_level
				effect_instance.max_hp_modifier_duration = 999
				effect_instance.effect_name = "Strong"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Forest Protector Faction Bonus"
				hero_index.effect_handler.effect_list.add_to_effect_array(effect_instance)
				hero_index.effect_handler.add_child(effect_instance)

		"demon":
			match level:
			if enemy_hero.size() <= 0:
				return

			for hero_index in enemy_hero:
				var effect_instance = ChessEffect.new()
				effect_instance.continuous_hp_modifier = -5 * bonus_level
				effect_instance.continuous_hp_modifier_duration = bonus_level
				effect_instance.silence_duration = bonus_level
				effect_instance.effect_name = "Doom"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Demon Faction Bonus"
				hero_index.effect_handler.effect_list.add_to_effect_array(effect_instance)
				hero_index.effect_handler.add_child(effect_instance)

		"undead":
			match level:
			if enemy_hero.size() <= 0:
				return

			for hero_index in enemy_hero:
				var effect_instance = ChessEffect.new()
				effect_instance.armor_modifier = -5 * bonus_level
				effect_instance.armor_modifier_duration = 999
				effect_instance.spd_modifier = -2
				effect_instance.spd_modifier_modifier_duration = bonus_level
				effect_instance.effect_name = "Weak"
				effect_instance.effect_type = "Faction Bonus"
				effect_instance.effect_applier = "Elf Faction Bonus"
				hero_index.effect_handler.effect_list.add_to_effect_array(effect_instance)
				hero_index.effect_handler.add_child(effect_instance)

func clean_hero_faction_bonus(hero: Hero) -> void:
	var hero_effect_list = hero.effect_handler.effect_list.duplicate()
	if hero_effect_list.size() == 0:
		return

	hero.effect_handler.effect_list = []
	for effect_index in hero_effect_list:
		if not effect_index.effect_applier = "Faction Bonus":
			hero.effect_handler.add_to_effect_array(effect_index)
