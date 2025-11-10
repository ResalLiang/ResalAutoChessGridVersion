extends Node
class_name AssetPathManager

#var effect_icon_path = {
	#"Swift" = "res://asset/sprite/icon/swift.png",
	#"Wisdom" = "res://asset/sprite/icon/wisdom.png",
	#"Fortress" = "res://asset/sprite/icon/fortress.png",
	#"HolyShield" = "res://asset/sprite/icon/holy_shield.png",
	#"Strong" = "res://asset/sprite/icon/strong.png",
	#"Doom" = "res://asset/sprite/icon/doom.png",
	#"Weak" = "res://asset/sprite/icon/weak.png",
	#"Default" = "res://asset/sprite/icon/wisdom.png"
#}

var effect_icon_path = {
	#"KillCount" = "res://asset/sprite/GandalfHardcore Icons/16x16 Icon11.png",
	"Avatar" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__070.png",
	"HunterMark" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__037.png",
	"ShieldBreakerKnock" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__142.png",
	"SpellFreezing" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__069.png",
	"Taunt" = "res://asset/sprite/GandalfHardcore Icons/16x16 Icon4.png", # temp not use
	"Heal" = "res://asset/sprite/GandalfHardcore Icons/16x16 Icon2.png", # temp not use
	"Stun" = "res://asset/sprite/GandalfHardcore Icons/16x16 Icon96.png", # temp not use
	"Precise" = "res://asset/sprite/[VerArc Stash] Basic_Skills_and_Buffs/Buffs/lucky_boost.png",
	"Gentle" = "res://asset/sprite/[VerArc Stash] Basic_Skills_and_Buffs/Buffs/swiftness.png",
	"Wisdom" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__075.png",
	"Fortress" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__148.png",
	"HolyShield" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__035.png",
	"Strong" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__010.png",
	"Doom" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__137.png",
	"Weak" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__026.png",
	"WarriorSkill" = "res://asset/sprite/[VerArc Stash] Basic_Skills_and_Buffs/Buffs/attack_boost.png",
	"KnightSkill" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__140.png",
	"PikemanSkill" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__096.png",
	"SpellerSkill" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__063.png",
	"RangerSkill" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__088.png",
	"SatyrSkill" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__008.png",
	"WarlockSkill" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__135.png",
	"Swift" = "res://asset/sprite/[VerArc Stash] Basic_Skills_and_Buffs/Buffs/attack_speed_boost.png",
	"Berserker" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__072.png",
	"March" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__138.png",
	"EntaglingRoots" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__002.png",
	"Devolve" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__112.png",
	"Suicide" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__144.png",
	"Default" = "res://asset/sprite/Archive2[skills_buffs_debuffs]/icon__071.png"
}

var faction_bar_path = {
	"elf" = "res://asset/sprite/icon/elf_bonus_fill.png",
	"human" = "res://asset/sprite/icon/human_bonus_fill.png",
	"dwarf" = "res://asset/sprite/icon/dwarf_bonus_fill.png",
	"holy" = "res://asset/sprite/icon/holy_bonus_fill.png",
	"forestProtector" = "res://asset/sprite/icon/forestProtector_bonus_fill.png",
	"demon" = "res://asset/sprite/icon/elf_bonus_fill.png",
	"undead" = "res://asset/sprite/icon/elf_bonus_fill.png",
	"Default" = "res://asset/sprite/icon/elf_bonus_fill.png"
}

var battle_result_path = {
	"remain_health" = "res://asset/sprite/Retro Inventory/Scaled 3x/Hearts_Red_1.png",
	"lose_health" = "res://asset/sprite/Retro Inventory/Scaled 3x/Hearts_Red_5.png",
	"winning_trophy" = "res://asset/sprite/Retro Inventory/Scaled 3x/Hearts_Blue_1.png",
	"Dafault" = "res://asset/sprite/Retro Inventory/Scaled 3x/Hearts_Red_1.png"
}

var effect_animation_path = {
	"FireBeam" = "res://asset/animation/spell_animation/FireBeam.tres",
	"IceFreeze" = "res://asset/animation/spell_animation/IceFreeze.tres",
	"IceUnfreeze" = "res://asset/animation/spell_animation/IceUnfreeze.tres",
	"DwarfBerserker" = "res://asset/animation/spell_animation/DwarfBerserker.tres",
	"DwarfFortress" = "res://asset/animation/spell_animation/DwarfFortress.tres",
	"DwarfHunterMark" = "res://asset/animation/spell_animation/DwarfHunterMark.tres",
	"DwarfKingPassive" = "res://asset/animation/spell_animation/DwarfKingPassive.tres",
	"DwarfMarch" = "res://asset/animation/spell_animation/DwarfMarch.tres",
	"ElfSwift" = "res://asset/animation/spell_animation/ElfSwift.tres",
	"ChessMerge" = "res://asset/animation/spell_animation/ChessMerge.tres",
	"CorpseExplosion" = "res://asset/animation/spell_animation/CorpseExplosion.tres",
	
	"SpeedUp" = "res://asset/animation/spell_animation/buff_debuff/speed_up.tres",
	"SpeedDown" = "res://asset/animation/spell_animation/buff_debuff/speed_down.tres",
	"ArmorUp" = "res://asset/animation/spell_animation/buff_debuff/power_up.tres",
	"ArmorDown" = "res://asset/animation/spell_animation/buff_debuff/power_down.tres",
	
	
	"Default" = "res://asset/animation/spell_animation/FireBeam.tres"
}

var projectile_animation_path = {
	"Ice" = "res://asset/animation/projectile_animation/ice.tres",
	"Default" = "res://asset/animation/projectile_animation/ice.tres"
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func get_asset_path(asset_type: String, asset_name: String) -> String:
	if not ["effect_icon", "faction_bar", "battle_result", "effect_animation", "projectile_animation"].has(asset_type):
		return ""
		
	match  asset_type:
		"effect_icon":
			if effect_icon_path.has(asset_name):
				return effect_icon_path[asset_name]
			else:
				return effect_icon_path["Default"]
		"faction_bar":
			if faction_bar_path.has(asset_name):
				return faction_bar_path[asset_name]
			else:
				return faction_bar_path["Default"]
		"battle_result":
			if battle_result_path.has(asset_name):
				return battle_result_path[asset_name]
			else:
				return battle_result_path["Default"]
		"effect_animation":
			if effect_animation_path.has(asset_name):
				return effect_animation_path[asset_name]
			else:
				return effect_animation_path["Default"]
		"projectile_animation":
			if projectile_animation_path.has(asset_name):
				return projectile_animation_path[asset_name]
			else:
				return projectile_animation_path["Default"]
				
	return ""
