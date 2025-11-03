extends Node
class_name DamageManager

func damage_handler(attacker: Obstacle, target: Obstacle, damage_value: float, damage_type: String, affix_array: Array):

	var damage_result = damage_value
	var critical_damage := false
	var life_steal_result := 0

	if damage_result <= 0:
		return

	if not ["Melee_attack", "Ranged_attack", "Magic_attack", "Continuous_effect", "Free_strike"].has(damage_type):
		return

	if not is_instance_valid(target) or target.visible == false or not target is Obstacle or target.status == target.STATUS.DIE:
		return

	if target.effect_handler.is_immunity or (damage_type == "Magic_attack" and target.effect_handler.is_spell_immunity):
		return

	if target is Chess:
		if (target.get("evasion_rate") != null and randf() <= target.evasion_rate and not affix_array.has("ignore_evasion")) or (damage_type == "Free_strike" and target.effect_handler.is_parry):
			target.attack_evased.emit(target, attacker)
			return

	var speller_bonus_level = attacker.faction_bonus_manager.get_bonus_level("speller", attacker.team) if attacker is Chess else 0

	if attacker is Chess:
		if attacker.get("critical_rate") != null and (randf() <= attacker.critical_rate and damage_type != "Magic_attack" and not target.effect_handler.is_critical_immunity):
			damage_result *= attacker.critical_damage
			critical_damage = true
		elif speller_bonus_level > 0 and attacker is Chess and attacker.role == "speller" and damage_type == "Magic_attack":
			if randf() <= speller_bonus_level * 0.1:
				damage_result *= attacker.critical_damage
				critical_damage = true				

			
	var elf_bonus_level = attacker.faction_bonus_manager.get_bonus_level("elf", attacker.team) if attacker is Chess else 0
	var pikeman_bonus_level = attacker.faction_bonus_manager.get_bonus_level("pikeman", attacker.team) if attacker is Chess else 0

	var min_damage_value = elf_bonus_level if elf_bonus_level > 0 else 1

	if pikeman_bonus_level > 0 and target is Chess and target.role == "knight" and attacker is Chess and attacker.role == "pikeman":
		damage_result += (5 * pikeman_bonus_level)

	if not affix_array.has("ignore_armor") and damage_type != "Magic_attack":
		damage_result -= target.armor
		if damage_result < 0:
			return

	if target is Chess and target.is_phantom and damage_type != "Magic_attack":
		damage_result *= 2.5
	elif target is Chess and target.is_phantom and damage_type == "Magic_attack":
		damage_result *= 10.0

	if attacker is Chess and attacker.is_phantom:
		damage_result /= 2.5

	var forest_bonus_level := 0
	var vengeance_faction := ""


	if target.faction == "forestProtector":
		forest_bonus_level = 0
		match target.team:
			1:
				forest_bonus_level = min(target.faction_bonus_manager.get_bonus_level("forestProtector", target.team), get_parent().faction_path_upgrade["forestProtector"]["path3"])
			2:
				forest_bonus_level = target.faction_bonus_manager.get_bonus_level("forestProtector", target.team)

		vengeance_faction = ""
		for effect_index in target.effect_handler.effect_list:
			if effect_index.effect_applier == "ForestProtector path3 Faction Bonus":
				vengeance_faction = effect_index.effect_name.rsplit(" ", true, 1)[1]
				break

		if forest_bonus_level != 0 and attacker.faction == vengeance_faction:
			damage_result *= (1 - 0.1 * forest_bonus_level)

	if attacker.faction == "forestProtector":
		forest_bonus_level = 0
		match attacker.team:
			1:
				forest_bonus_level = min(attacker.faction_bonus_manager.get_bonus_level("forestProtector", attacker.team), get_parent().faction_path_upgrade["forestProtector"]["path3"])
			2:
				forest_bonus_level = attacker.faction_bonus_manager.get_bonus_level("forestProtector", attacker.team)

		vengeance_faction = ""
		for effect_index in attacker.effect_handler.effect_list:
			if effect_index.effect_applier == "ForestProtector path3 Faction Bonus":
				vengeance_faction = effect_index.effect_name.rsplit(" ", true, 1)[1]
				break

		if forest_bonus_level != 0 and target.faction == vengeance_faction:
			damage_result *= (1 + 0.1 * forest_bonus_level)

	damage_result = floor(damage_result)
		
	#====================do not modify damage_result after============================

	damage_result = max(damage_result, min_damage_value)

	if (attacker is Chess and attacker.life_steal_rate > 0) or (attacker.faction == "forestProtector" and attacker.chess_name == "SatyrWarrior"):
		life_steal_result = (attacker.life_steal_rate * damage_result) if attacker.life_steal_rate > 0 else (damage_result * 0.2 * attacker.chess_level)

	if critical_damage:
		attacker.critical_damage_applied.emit(attacker, target, damage_result)
	else:
		attacker.damage_applied.emit(attacker, target, damage_result)

	target.damage_taken.emit(target, attacker, damage_result)

	if target is Chess and target.reflect_damage > 0:
		attacker.damage_taken.emit(attacker, target, target.reflect_damage)
	
	if life_steal_result > 0:
		attacker._apply_heal(attacker, life_steal_result)
		# attacker.take_heal(life_steal_result, attacker)
		
	#if attacker != target and damage_type != "Magic_attack" and attacker is Chess:
		#attacker.gain_mp(damage_result)
	#elif attacker != target and damage_type == "Magic_attack" and attacker is Chess and attacker.chess_name == "ArchMage" and attacker.faction == "human":
		#attacker.gain_mp(damage_result * 0.15 * attacker.chess_level)
		
	if attacker != target and damage_type != "Magic_attack" and attacker is Chess:
		attacker.gain_mp(damage_result)
	elif attacker != target and damage_type == "Magic_attack" and attacker is Chess and attacker.chess_name == "ArchMage" and attacker.faction == "human":
		attacker.gain_mp(damage_result * 0.3 * attacker.chess_level)
		
	if attacker != target and target is Chess:
		target.gain_mp(damage_result)

	if attacker.chess_name == "Queen" and attacker.faction == "elf" and damage_type == "Magic_attack":
		attacker.random_heal(damage_result, attacker)
