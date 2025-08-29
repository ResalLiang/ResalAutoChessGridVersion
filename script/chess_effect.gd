class_name ChessEffect
extends Node

var effect_name := "Effect Name Placeholder":
	set(value):
		effect_name = values
		# Placeholder for icon load
var effect_icon : Texture2D
var effect_type : String # Buff/Debuff/Passive
var effect_applier : String

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

var spd_modifier := 0
var spd_modifier_duration := 0
		set(value):
			spd_modifier_duration = value
			if value <= 0:
				spd_modifier = 0

var attack_rng_modifier := 0
var attack_rng_modifier_duration := 0
		set(value):
			attack_rng_modifier_duration = value
			if value <= 0:
				attack_rng_modifier = 0

var attack_spd_modifier := 0
var attack_spd_modifier_duration := 0
		set(value):
			attack_spd_modifier_duration = value
			if value <= 0:
				attack_spd_modifier = 0

var attack_dmg_modifier := 0
var attack_dmg_modifier_duration := 0
		set(value):
			attack_dmg_modifier_duration = value
			if value <= 0:
				attack_dmg_modifier = 0

var continuous_hp_modifier := 0
var continuous_hp_modifier_duration := 0
		set(value):
			continuous_hp_modifier_duration = value
			if value <= 0:
				continuous_hp_modifier = 0

var continuous_mp_modifier := 0
var continuous_mp_modifier_duration := 0
		set(value):
			continuous_mp_modifier_duration = value
			if value <= 0:
				continuous_mp_modifier = 0

var armor_modifier := 0
var armor_modifier_duration := 0
		set(value):
			armor_modifier_duration = value
			if value <= 0:
				armor_modifier = 0

var max_mp_modifier := 0
var max_mp_modifier_duration := 0
		set(value):
			max_mp_modifier_duration = value
			if value <= 0:

var max_hp_modifier := 0
var max_hp_modifier_duration := 0
		set(value):
			max_hp_modifier_duration = value
			if value <= 0:
				max_hp_modifier = 0

var critical_rate_modifier := 0.0
var critical_rate_modifier_duration := 0
		set(value):
			critical_rate_modifier_duration = value
			if value <= 0:
				critical_rate_modifier = 0

var evasion_rate_modifier := 0.0
var evasion_rate_modifier_duration := 0
		set(value):
			evasion_rate_modifier_duration = value
			if value <= 0:
				evasion_rate_modifier = 0

func check_effect_timeout() -> bool:
	
	if immunity_duration > 0:
		return true
	
	if spell_immunity_duration > 0:
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

	if spd_modifier_duration > 0 and spd_modifier != 0:
		return true

	if attack_rng_modifier_duration > 0 and attack_rng_modifier != 0:
		return true

	if attack_spd_modifier_duration > 0 and attack_spd_modifier != 0:
		return true

	if attack_dmg_modifier_duration > 0 and attack_dmg_modifier != 0:
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

	if spd_modifier_duration > 0 and spd_modifier != 0:
		return true

func start_turn_update():

	immunity_duration = max(0, immunity_duration - 1)
	spell_immunity_duration = max(0, spell_immunity_duration - 1)
	silence_duration = max(0, silence_duration - 1)
	disarmed_duration = max(0, disarmed_duration - 1)
	stunned_duration = max(0, stunned_duration - 1)
	taunt_duration = max(0, taunt_duration - 1)
	stealth_duration = max(0, stealth_duration - 1)


	spd_modifier_duration = max(0, spd_modifier_duration - 1)
	attack_rng_modifier_duration = max(0, attack_rng_modifier_duration - 1)
	attack_spd_modifier_duration = max(0, attack_spd_modifier_duration - 1)
	attack_dmg_modifier_duration = max(0, attack_dmg_modifier_duration - 1)
	continuous_hp_modifier_duration = max(0, continuous_hp_modifier_duration - 1)
	continuous_mp_modifier_duration = max(0, continuous_mp_modifier_duration - 1)
	armor_modifier_duration = max(0, armor_modifier_duration - 1)
	max_mp_modifier_duration = max(0, max_mp_modifier_duration - 1)
	max_hp_modifier_duration = max(0, max_hp_modifier_duration - 1)
	critical_rate_modifier_duration = max(0, critical_rate_modifier_duration - 1)
	evasion_rate_modifier_duration = max(0, evasion_rate_modifier_duration - 1)
