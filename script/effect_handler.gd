class_name EffectHandler
extends Node

var effect_list : Array

var is_immunity := false
var is_spell_immunity := false
var is_critical_immunity := false
var is_taunt := false
var is_stealth := false
var is_silenced := false
var is_disarmed := false
var is_stunned := false
var is_parry := false

var speed_modifier := 0
var attack_rng_modifier := 0
var attack_speed_modifier := 0
var melee_attack_damage_modifier := 0
var ranged_attack_damage_modifier := 0
var continuous_hp_modifier := 0
var continuous_mp_modifier := 0
var armor_modifier := 0
var max_mp_modifier := 0
var max_hp_modifier := 0
var critical_rate_modifier := 0.0
var critical_damage_modifier := 0.0
var evasion_rate_modifier := 0.0
var life_steal_rate_modifier := 0.0
var reflect_damage_modifier := 0.0

signal effect_list_updated

func _ready() -> void:
	if effect_list_updated.connect(refresh_effects) != OK:
		print("effect_list_updated connect fail!")

func search_effect(search_effect_name: String) -> ChessEffect:
	if effect_list.size() > 0:
		for effect_index in effect_list:
			if effect_index.effect_name == search_effect_name:
				return effect_index
			else:
				continue
	else:
		return null

func add_to_effect_array(chess_effect: ChessEffect) -> void:
	if not chess_effect.check_effect_timeout():
		return
		
	for effect_index in effect_list:

		if chess_effect.effect_name == effect_index.effect_name or chess_effect.effect_name.get_slice(" ", 0) == effect_index.effect_name.get_slice(" ", 0):
			effect_list.erase(effect_index)
							
	effect_list.append(chess_effect)
	effect_list_updated.emit()

func turn_start_timeout_check() -> void:
	if effect_list.size() != 0:
		var new_effect_list = effect_list.duplicate()
		effect_list = []
		for effect_index in new_effect_list:
			if not effect_index.check_effect_timeout():
				pass
				#new_effect_list.queue_free()
			else:
				add_to_effect_array(effect_index)
				effect_index.start_turn_update()

	refresh_effects()

func refresh_effects() -> void:

	is_immunity = false
	is_spell_immunity = false
	is_critical_immunity = false
	is_silenced = false
	is_disarmed = false
	is_stunned =  false
	is_taunt = false
	is_stealth = false
	is_parry = false

	speed_modifier = 0
	attack_rng_modifier = 0
	attack_speed_modifier = 0
	melee_attack_damage_modifier = 0
	ranged_attack_damage_modifier = 0
	continuous_hp_modifier = 0
	continuous_mp_modifier = 0
	armor_modifier = 0
	max_mp_modifier = 0
	max_hp_modifier = 0
	critical_rate_modifier = 0
	critical_damage_modifier = 0
	evasion_rate_modifier = 0
	life_steal_rate_modifier = 0
	reflect_damage_modifier = 0

	if effect_list.size() == 0:
		return

	for effect_index in effect_list:

		active_single_effect(effect_index)

func effect_clean() -> void:

	var new_effect_list := []
	if effect_list.size() != 0:
		for effect_index in effect_list:
			if effect_index.effect_applier.contains("Faction Bonus"):
				new_effect_list.append(effect_index.duplicate())
				
	effect_list = new_effect_list

	refresh_effects()

func active_single_effect(chess_effect: ChessEffect) -> void:

	is_immunity = is_immunity or chess_effect.buff_dict["is_immunity"]
	is_spell_immunity = is_spell_immunity or chess_effect.buff_dict["is_spell_immunity"]
	is_critical_immunity = is_critical_immunity or chess_effect.buff_dict["is_critical_immunity"]
	is_silenced = false if is_spell_immunity else is_silenced or chess_effect.buff_dict["is_silenced"]
	is_disarmed = false if is_spell_immunity else is_disarmed or chess_effect.buff_dict["is_disarmed"]
	is_stunned = false if is_spell_immunity else is_stunned or chess_effect.buff_dict["is_stunned"]
	is_taunt = is_taunt or chess_effect.buff_dict["is_taunt"] 
	is_stealth = is_stealth or chess_effect.buff_dict["is_stealth"]
	is_parry = is_parry or chess_effect.buff_dict["is_parry"]

	speed_modifier = speed_modifier + (max(0, chess_effect.buff_dict["speed_modifier"]) if is_spell_immunity 
		else chess_effect.buff_dict["speed_modifier"])
	attack_rng_modifier = attack_rng_modifier + (max(0, chess_effect.buff_dict["attack_rng_modifier"]) if is_spell_immunity 
		else chess_effect.buff_dict["attack_rng_modifier"])
	attack_speed_modifier = attack_speed_modifier + (max(0, chess_effect.buff_dict["attack_speed_modifier"]) if is_spell_immunity 
		else chess_effect.buff_dict["attack_speed_modifier"])
	melee_attack_damage_modifier = melee_attack_damage_modifier + (max(0, chess_effect.buff_dict["melee_attack_damage_modifier"]) if is_spell_immunity 
		else chess_effect.buff_dict["melee_attack_damage_modifier"])
	ranged_attack_damage_modifier = ranged_attack_damage_modifier + (max(0, chess_effect.buff_dict["ranged_attack_damage_modifier"]) if is_spell_immunity 
		else chess_effect.buff_dict["ranged_attack_damage_modifier"])
	continuous_hp_modifier = continuous_hp_modifier + (max(0, chess_effect.buff_dict["continuous_hp_modifier"]) if is_immunity or is_spell_immunity 
		else chess_effect.buff_dict["continuous_hp_modifier"])
	continuous_mp_modifier = continuous_mp_modifier + (max(0, chess_effect.buff_dict["continuous_mp_modifier"]) if is_spell_immunity 
		else chess_effect.buff_dict["continuous_mp_modifier"])
	armor_modifier = armor_modifier + (max(0, chess_effect.buff_dict["armor_modifier"]) if is_spell_immunity 
		else chess_effect.buff_dict["armor_modifier"])
	max_mp_modifier = max_hp_modifier + (max(0, chess_effect.buff_dict["max_mp_modifier"]) if is_immunity or is_spell_immunity 
		else chess_effect.buff_dict["max_mp_modifier"])
	max_hp_modifier = max_hp_modifier + (max(0, chess_effect.buff_dict["max_hp_modifier"]) if is_immunity or is_spell_immunity 
		else chess_effect.buff_dict["max_hp_modifier"])
	critical_rate_modifier = critical_rate_modifier + (max(0, chess_effect.buff_dict["critical_rate_modifier"]) if is_spell_immunity 
		else chess_effect.buff_dict["critical_rate_modifier"])
	critical_damage_modifier = critical_damage_modifier + (max(0, chess_effect.buff_dict["critical_damage_modifier"]) if is_spell_immunity 
		else chess_effect.buff_dict["critical_damage_modifier"])
	evasion_rate_modifier = evasion_rate_modifier + (max(0, chess_effect.buff_dict["evasion_rate_modifier"]) if is_spell_immunity 
		else chess_effect.buff_dict["evasion_rate_modifier"])
	life_steal_rate_modifier = life_steal_rate_modifier + (max(0, chess_effect.buff_dict["life_steal_rate_modifier"]) if is_spell_immunity 
		else chess_effect.buff_dict["life_steal_rate_modifier"])
	reflect_damage_modifier = reflect_damage_modifier + (max(0, chess_effect.buff_dict["reflect_damage_modifier"]) if is_spell_immunity 
		else chess_effect.buff_dict["reflect_damage_modifier"])

	chess_effect.extra_func_called.emit(get_parent())
