class_name ChessEffect
extends Node

var effect_name := "Effect Name Placeholder"
var effect_icon : Texture2D
var effect_description : String
var effect_type : String # Buff/Debuff/Passive/PermanentBuff/PermanentDebuff
var effect_applier : String
var effect_duration := 0

signal extra_func_called

var is_immunity := false
var immunity_duration := 0:
	set(value):
		if value > 0:
			immunity_duration = value
			is_immunity = true
		else:
			is_immunity = false

var is_spell_immunity := false
var spell_immunity_duration := 0:
	set(value):
		if value > 0:
			spell_immunity_duration = value
			is_spell_immunity = true
		else:
			is_spell_immunity = false

var is_critical_immunity := false
var critical_immunity_duration := 0:
	set(value):
		if value > 0:
			critical_immunity_duration = value
			is_critical_immunity = true
		else:
			is_critical_immunity = false

var is_taunt := false
var taunt_duration := 0:
	set(value):
		if value > 0:
			taunt_duration = value
			is_taunt = true
		else:
			is_taunt = false

var is_stealth := false
var stealth_duration := 0:
	set(value):
		if value > 0:
			stealth_duration = value
			is_stealth = true
		else:
			is_stealth = false

var is_silenced := false
var silence_duration := 0:
	set(value):
		if value > 0:
			silence_duration = value
			is_silenced = true

var is_disarmed := false
var disarmed_duration := 0:
	set(value):
		if value > 0:
			disarmed_duration = value
			is_disarmed = true

var is_stunned := false
var stunned_duration := 0:
	set(value):
		if value > 0:
			stunned_duration = value
			is_stunned = true

var speed_modifier := 0
var speed_modifier_duration := 0:
		set(value):
			speed_modifier_duration = value
			if value <= 0:
				speed_modifier = 0

var attack_rng_modifier := 0
var attack_rng_modifier_duration := 0:
		set(value):
			attack_rng_modifier_duration = value
			if value <= 0:
				attack_rng_modifier = 0

var attack_speed_modifier := 0
var attack_speed_modifier_duration := 0:
		set(value):
			attack_speed_modifier_duration = value
			if value <= 0:
				attack_speed_modifier = 0

var melee_attack_damage_modifier := 0
var melee_attack_damage_modifier_duration := 0:
		set(value):
			melee_attack_damage_modifier_duration = value
			if value <= 0:
				melee_attack_damage_modifier = 0

var ranged_attack_damage_modifier := 0
var ranged_attack_damage_modifier_duration := 0:
		set(value):
			ranged_attack_damage_modifier_duration = value
			if value <= 0:
				ranged_attack_damage_modifier = 0

var continuous_hp_modifier := 0
var continuous_hp_modifier_duration := 0:
		set(value):
			continuous_hp_modifier_duration = value
			if value <= 0:
				continuous_hp_modifier = 0

var continuous_mp_modifier := 0
var continuous_mp_modifier_duration := 0:
		set(value):
			continuous_mp_modifier_duration = value
			if value <= 0:
				continuous_mp_modifier = 0

var armor_modifier := 0
var armor_modifier_duration := 0:
		set(value):
			armor_modifier_duration = value
			if value <= 0:
				armor_modifier = 0

var max_mp_modifier := 0
var max_mp_modifier_duration := 0:
		set(value):
			max_mp_modifier_duration = value
			if value <= 0:
				max_mp_modifier = 0

var max_hp_modifier := 0
var max_hp_modifier_duration := 0:
		set(value):
			max_hp_modifier_duration = value
			if value <= 0:
				max_hp_modifier = 0

var critical_rate_modifier := 0.0
var critical_rate_modifier_duration := 0:
		set(value):
			critical_rate_modifier_duration = value
			if value <= 0:
				critical_rate_modifier = 0

var evasion_rate_modifier := 0.0
var evasion_rate_modifier_duration := 0:
		set(value):
			evasion_rate_modifier_duration = value
			if value <= 0:
				evasion_rate_modifier = 0

func _ready() -> void:
	extra_func_called.connect(extra_func)

func check_effect_timeout() -> bool:
	if effect_type == "PermanentBuff" or effect_type == "PermanentDebuff":
		return false
	
	if immunity_duration > 0:
		return true
	
	if spell_immunity_duration > 0:
		return true
	
	if critical_immunity_duration > 0:
		return true

	if taunt_duration > 0:
		return true

	if stealth_duration > 0:
		return true

	if silence_duration > 0:
		return true

	if disarmed_duration > 0:
		return true

	if stunned_duration > 0:
		return true

	if speed_modifier_duration > 0 and speed_modifier != 0:
		return true

	if attack_rng_modifier_duration > 0 and attack_rng_modifier != 0:
		return true

	if attack_speed_modifier_duration > 0 and attack_speed_modifier != 0:
		return true

	if melee_attack_damage_modifier_duration > 0 and melee_attack_damage_modifier != 0:
		return true

	if ranged_attack_damage_modifier_duration > 0 and ranged_attack_damage_modifier != 0:
		return true

	if continuous_hp_modifier_duration > 0 and continuous_hp_modifier != 0:
		return true

	if continuous_mp_modifier_duration > 0 and continuous_mp_modifier != 0:
		return true

	if armor_modifier_duration > 0 and armor_modifier != 0:
		return true

	if max_mp_modifier_duration > 0 and max_mp_modifier != 0:
		return true

	if max_hp_modifier_duration > 0 and max_hp_modifier != 0:
		return true

	if critical_rate_modifier_duration > 0 and critical_rate_modifier != 0:
		return true

	if evasion_rate_modifier_duration > 0 and evasion_rate_modifier != 0:
		return true

	if speed_modifier_duration > 0 and speed_modifier != 0:
		return true

	if effect_duration > 0:
		return true

	return false
	
func start_turn_update():

	effect_duration = max(0, effect_duration - 1)

	immunity_duration = max(0, immunity_duration - 1)
	spell_immunity_duration = max(0, spell_immunity_duration - 1)
	critical_immunity_duration = max(0, critical_immunity_duration - 1)
	silence_duration = max(0, silence_duration - 1)
	disarmed_duration = max(0, disarmed_duration - 1)
	stunned_duration = max(0, stunned_duration - 1)
	taunt_duration = max(0, taunt_duration - 1)
	stealth_duration = max(0, stealth_duration - 1)


	speed_modifier_duration = max(0, speed_modifier_duration - 1)
	attack_rng_modifier_duration = max(0, attack_rng_modifier_duration - 1)
	attack_speed_modifier_duration = max(0, attack_speed_modifier_duration - 1)
	melee_attack_damage_modifier_duration = max(0, melee_attack_damage_modifier_duration - 1)
	ranged_attack_damage_modifier_duration = max(0, ranged_attack_damage_modifier_duration - 1)
	continuous_hp_modifier_duration = max(0, continuous_hp_modifier_duration - 1)
	continuous_mp_modifier_duration = max(0, continuous_mp_modifier_duration - 1)
	armor_modifier_duration = max(0, armor_modifier_duration - 1)
	max_mp_modifier_duration = max(0, max_mp_modifier_duration - 1)
	max_hp_modifier_duration = max(0, max_hp_modifier_duration - 1)
	critical_rate_modifier_duration = max(0, critical_rate_modifier_duration - 1)
	evasion_rate_modifier_duration = max(0, evasion_rate_modifier_duration - 1)

func extra_func(chess: Chess):
	if effect_name.get_slice(" ", 0) == "RangerSkill" and chess.role == "ranger":
		chess.projectile_penetration = max(chess.projectile_penetration, 1 + int(effect_name.get_slice(" ", -1)))
		chess.decline_ratio = min(chess.decline_ratio, 3 - 0.5 * int(effect_name.get_slice(" ", -1)))
