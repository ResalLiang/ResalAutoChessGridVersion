extends Node
class_name DamageManager

func damage_handler(attacker: Obstacle, target: Obstacle, damage_value: float, damage_type: String, affix_array: Array):

	var damage_result = damage_value
	var critical_damage := false

	if damage_result <= 0:
		return

	if not ["Melee_attack", "Ranged_attack", "Magic_attack", "Continuous_effect"].has(damage_type):
		return

	if not is_instance_valid(target) or target.visible == false or not target is Obstacle or target.status == target.STATUS.DIE:
		return

	if target.effect_handler.is_immunity or (damage_type == "Magic_attack" and target.effect_handler.is_spell_immunity):
		return

	if target.get("evasion_rate") != null and randf() <= target.evasion_rate and not affix_array.has("ignore_evasion"):
		target.attack_evased.emit(target, attacker)
		return

	if not attacker.get("critical_rate") and (randf() <= attacker.critical_rate and damage_type != "Magic_attack" and not target.effect_handler.is_critical_immunity):
		damage_result *= 2
		critical_damage = true

	if not affix_array.has("ignore_armor") and damage_type != "Magic_attack":
		damage_result -= target.armor
		if damage_result < 0:
			return
			
	damage_result = max(damage_result, 1)

	if critical_damage:
		attacker.critical_damage_applied.emit(attacker, target, damage_result)
	else:
		attacker.damage_applied.emit(attacker, target, damage_result)

	target.damage_taken.emit(target, attacker, damage_result)
