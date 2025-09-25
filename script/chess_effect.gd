class_name ChessEffect
extends Node

var effect_name := "Effect Name Placeholder"
var effect_icon : Texture2D
var effect_description : String
var effect_type : String # Buff/Debuff/Passive/PermanentBuff/PermanentDebuff
var effect_applier : String
var effect_duration := 0

var buff_type_list = ["immunity", "spell_immunity", "critical_immunity", "taunt", "stealth", "silenced", "disarmed", "stunned", "parry", "speed_modifier", "attack_rng_modifier", "attack_speed_modifier", "melee_attack_damage_modifier", "ranged_attack_damage_modifier", "continuous_hp_modifier", "continuous_mp_modifier", "armor_modifier", "max_mp_modifier", "max_hp_modifier", "critical_rate_modifier", "evasion_rate_modifier"]
var buff_dict: Dictionary

signal extra_func_called

func _init() -> void:
	for buff_type_index in buff_type_list:
		if buff_type_index.contains("modifier"):
			buff_dict[buff_type_index] = 0
			buff_dict[buff_type_index + "duration"] = 0
		else:
			buff_dict["is_" + buff_type_index] = false
			buff_dict[buff_type_index + "duration"] = 0

	extra_func_called.connect(extra_func)

func check_effect_timeout() -> bool:
	if effect_type == "PermanentBuff" or effect_type == "PermanentDebuff":
		return true

	if effect_duration > 0:
		return true

	for buff_index in buff_dict.keys():
		
		if buff_index.contains("duration") and buff_dict[buff_index] > 0:
			return true

	return false
	
func start_turn_update():
	for buff_index in buff_dict.keys():
		if buff_index.contains("duration"):
			buff_dict[buff_index] =  max(0, buff_dict[buff_index] - 1)

	effect_duration = max(0, effect_duration - 1)

func extra_func(chess: Chess):
	if effect_name.get_slice(" ", 0) == "RangerSkill" and chess.role == "ranger":
		chess.projectile_penetration = max(chess.projectile_penetration, 1 + int(effect_name.get_slice(" ", -1)))
		chess.decline_ratio = min(chess.decline_ratio, 3 - 0.5 * int(effect_name.get_slice(" ", -1)))

func register_buff(buff_type: String, buff_value: float, buff_duration: int):

	if buff_type == "duration_only":
		effect_duration = buff_duration
		
	if not buff_type in buff_type_list:
		return
		
	elif buff_type.contains("modifier") and buff_duration > 0 and buff_value != 0:
		buff_dict[buff_type] = buff_value
		buff_dict[buff_type + "duration"] = buff_duration
	elif not buff_type.contains("modifier") and buff_duration > 0:
		buff_dict["is_" + buff_type] = true
		buff_dict[buff_type + "duration"] = buff_duration
