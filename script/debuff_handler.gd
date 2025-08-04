class_name Debuff_handler

var is_silenced := false
var silence_duration := 0

var is_disarmed := false
var disarmed_duration := 0

var is_stunned := false
var stunned_duration := 0

var spd_modifier := 0
var spd_modifier_duration := 0

var attack_rng_modifier := 0
var attack_rng_modifier_duration := 0

var attack_spd_modifier := 0
var attack_spd_modifier_duration := 0

var attack_dmg_modifier := 0
var attack_dmg_modifier_duration := 0

var continuous_hp_modifier := 0
var continuous_hp_modifier_duration := 0

var continuous_mp_modifier := 0
var continuous_mp_modifier_duration := 0

var armor_modifier := 0
var armor_modifier_duration := 0

var max_hp_modifier := 0
var max_hp_modifier_duration := 0

var critical_rate_modifier := 0.0
var critical_rate_modifier_duration := 0

var evasion_rate_modifier := 0.0
var evasion_rate_modifier_duration := 0


func start_turn_update():
	silence_duration = max(0, silence_duration - 1)
	is_silenced = silence_duration > 0

	disarmed_duration = max(0, disarmed_duration - 1)
	is_disarmed = disarmed_duration > 0

	stunned_duration = max(0, stunned_duration - 1)
	is_stunned = stunned_duration > 0

	spd_modifier_duration = max(0, spd_modifier_duration - 1)
	spd_modifier = 0 if spd_modifier_duration <= 0 else spd_modifier

	attack_rng_modifier_duration = max(0, attack_rng_modifier_duration - 1)
	attack_rng_modifier = 0 if attack_rng_modifier_duration <= 0 else attack_rng_modifier

	attack_spd_modifier_duration = max(0, attack_spd_modifier_duration - 1)
	attack_spd_modifier = 0 if attack_spd_modifier_duration <= 0 else attack_spd_modifier

	attack_dmg_modifier_duration = max(0, attack_dmg_modifier_duration - 1)
	attack_dmg_modifier = 0 if attack_dmg_modifier_duration <= 0 else attack_dmg_modifier

	continuous_hp_modifier_duration = max(0, continuous_hp_modifier_duration - 1)
	continuous_hp_modifier = o if continuous_hp_modifier_duration <= 0 else continuous_hp_modifier_duration

	continuous_mp_modifier_duration = max(0, continuous_mp_modifier_duration - 1)
	continuous_mp_modifier = o if continuous_mp_modifier_duration <= 0 else continuous_mp_modifier_duration

	armor_modifier_duration = max(0, armor_modifier_duration - 1)
	armor_modifier = 0 if armor_modifier_duration <= 0 else armor_modifier_duration

	max_hp_modifier_duration = max(0, max_hp_modifier_duration - 1)
	max_hp_modifier = 0 if max_hp_modifier_duration <= 0 lese max_hp_modifier_duration

	critical_rate_modifier_duration = max(0, critical_rate_modifier_duration - 1)
	critical_rate_modifier = 0.0 if critical_rate_modifier_duration <= 0 else critical_rate_modifier_duration

	evasion_rate_modifier_duration = max(0, evasion_rate_modifier_duration - 1)
	evasion_rate_modifier = 0.0 if evasion_rate_modifier_duration <= 0 else evasion_rate_modifier_duration

func debuff_clean():
	silence_duration = 0
	disarmed_duration = 0
	stunned_duration = 0
	spd_modifier_duration = 0
	attack_rng_modifier_duration = 0
	attack_spd_modifier_duration = 0
	attack_dmg_modifier_duration = 0
	continuous_hp_modifier_duration = 0
	continuous_mp_modifier_duration = 0
	armor_modifier_duration = 0
	max_hp_modifier_duration = 0
	critical_rate_modifier_duration = 0
	evasion_rate_modifier_duration = 0
	turn_update()
