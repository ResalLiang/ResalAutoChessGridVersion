class_name EffectHandler
extends Node

var effect_list : Array

var is_immunity := false
var is_spell_immunity := false
var is_taunt := false
var is_stealth := false
var is_silenced := false
var is_disarmed := false
var is_stunned := false

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
var evasion_rate_modifier := 0.0

signal effect_list_updated

func _ready() -> void:
	effect_list_updated.connect(refresh_effects)

func add_to_effect_array(chess_effect: ChessEffect):
	if not chess_effect.check_effect_timeout():
		return

	if effect_list.size() > 0:
		for effect_index in effect_list:
			if chess_effect.effect_name == effect_index.effect_name:
				effect_index = chess_effect
				return
				
	effect_list.append(chess_effect)
	effect_list_updated.emit()

func turn_start_timeout_check():
	if effect_list.size() != 0:
		var new_effect_list = effect_list.duplicate()
		effect_list = []
		for effect_index in new_effect_list:
			effect_index.start_turn_update()
			if not effect_index.check_effect_timeout():
				pass
				#new_effect_list.queue_free()
			else:
				add_to_effect_array(effect_index)

	refresh_effects()

func refresh_effects():

	is_immunity = false
	is_spell_immunity = false
	is_silenced = false
	is_disarmed = false
	is_stunned =  false
	is_taunt = false
	is_stealth = false

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
	evasion_rate_modifier = 0

	if effect_list.size() == 0:
		return

	for effect_index in effect_list:

		is_immunity = is_immunity or effect_index.is_immunity
		is_spell_immunity = is_spell_immunity or effect_index.is_spell_immunity
		is_silenced = false if is_spell_immunity else is_silenced or effect_index.is_silenced
		is_disarmed = false if is_spell_immunity else is_disarmed or effect_index.is_disarmed
		is_stunned = false if is_spell_immunity else is_stunned or effect_index.is_stunned
		is_taunt = is_taunt or effect_index.is_taunt 
		is_stealth = is_stealth or effect_index.is_stealth

		speed_modifier = speed_modifier + (max(0, effect_index.speed_modifier) if is_spell_immunity 
			else effect_index.speed_modifier)
		attack_rng_modifier = attack_rng_modifier + (max(0, effect_index.attack_rng_modifier) if is_spell_immunity 
			else effect_index.attack_rng_modifier)
		attack_speed_modifier = attack_speed_modifier + (max(0, effect_index.attack_speed_modifier) if is_spell_immunity 
			else effect_index.attack_speed_modifier)
		melee_attack_damage_modifier = melee_attack_damage_modifier + (max(0, effect_index.melee_attack_damage_modifier) if is_spell_immunity 
			else effect_index.melee_attack_damage_modifier)
		ranged_attack_damage_modifier = ranged_attack_damage_modifier + (max(0, effect_index.ranged_attack_damage_modifier) if is_spell_immunity 
			else effect_index.ranged_attack_damage_modifier)
		continuous_hp_modifier = continuous_hp_modifier + (max(0, effect_index.continuous_hp_modifier) if is_immunity or is_spell_immunity 
			else effect_index.continuous_hp_modifier)
		continuous_mp_modifier = continuous_mp_modifier + (max(0, effect_index.continuous_mp_modifier) if is_spell_immunity 
			else effect_index.continuous_mp_modifier)
		armor_modifier = armor_modifier + (max(0, effect_index.armor_modifier) if is_spell_immunity 
			else effect_index.armor_modifier)
		max_mp_modifier = max_hp_modifier + (max(0, effect_index.max_mp_modifier) if is_immunity or is_spell_immunity 
			else effect_index.max_mp_modifier)
		max_hp_modifier = max_hp_modifier + (max(0, effect_index.max_hp_modifier) if is_immunity or is_spell_immunity 
			else effect_index.max_hp_modifier)
		critical_rate_modifier = critical_rate_modifier + (max(0, effect_index.critical_rate_modifier) if is_spell_immunity 
			else effect_index.critical_rate_modifier)
		evasion_rate_modifier = evasion_rate_modifier + (max(0, effect_index.evasion_rate_modifier) if is_spell_immunity 
			else effect_index.evasion_rate_modifier)

		effect_index.extra_func_called.emit(get_parent())

func effect_clean():

	effect_list = []

	refresh_effects()
