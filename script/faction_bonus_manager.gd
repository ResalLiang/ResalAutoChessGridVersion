class_name FactionBonusManager
extends Node2D

var elf_bonus := false
var human_bonus := false
var dwarf_bonus := false
var holy_bonus := false
var forestProtector_bonus := false
var undead_bonus := false
var demon_bonus := false

var faction_list = ["elf", "human", "dwarf", "holy", "forestProtector", "undead", "demon"]

var bonus_level_list : Dictionary = {
	"elf" : [2, 4, 6],
	"human" : [2, 4, 6],
	"dwarf" : [2, 4, 6],
	"holy" : [2, 4, 6],
	"forestProtector" : [2, 4, 6],
	"undead" : [2, 4, 6],
	"demon" : [2, 4, 6]	
}

var bonus_level_dict : Dictionary = {
	"player" : {
		"elf" : 0,
		"human" : 0,
		"dwarf" : 0,
		"holy" : 0,
		"forestProtector" : 0,
		"undead" : 0,
		"demon" : 0
	},
	"ai" : {
		"elf" : 0,
		"human" : 0,
		"dwarf" : 0,
		"holy" : 0,
		"forestProtector" : 0,
		"undead" : 0,
		"demon" : 0}
	}
}

var faction_count : Dictionary = {
	"player" : {
		"elf" : [],
		"human" : [],
		"dwarf" : [],
		"holy" : [],
		"forestProtector" : [],
		"undead" : [],
		"demon" : []
	},
	"ai" : {
		"elf" : [],
		"human" : [],
		"dwarf" : [],
		"holy" : [],
		"forestProtector" : [],
		"undead" : [],
		"demon" : []
	}
}


func bonus_refresh():
	for hero_index in arena.unit_grid.values():

		if not (is_instance_valid(hero_index) and hero_index is Hero):
			continue

		if hero_index.team == 1:
			if not faction_count["player"][hero_index.faction].has(hero_index.hero_name):
				faction_count["player"][hero_index.faction].append(hero_index.hero_name)
		elif hero_index.team == 2:
			if not faction_count["ai"][hero_index.faction].has(hero_index.hero_name):
				faction_count["ai"][hero_index.faction].append(hero_index.hero_name)

	for player_index in ["player", "ai"]:
		for faction_index in bonus_level_list.keys():
			var bonus_level = 0
			for level_value in bonus_level_list[faction_index]:
				if faction_count[player_index][faction_index].size() >= level_value:
					bonus_level += 1
			bonus_level_dict[player_index][faction_index] = min(bonus_level, 3)

func apply_bonus():
	for player_index in ["player", "ai"]:
		for faction_index in bonus_level_list.keys():
			var current_faction_bonus_level = bonus_level_dict[player_index][faction_index]
			if current_faction_bonus_level > 0:
				apply_faction_bonus(1, faction_index, current_faction_bonus_level)


func apply_faction_bonus(team: int, faction: String, level: int):
	match faction:
		"elf":
			pass
		"human":
			pass
