extends Node
class_name DamageManager

func damage_handler(attacker: Chess, target: Chess, damage_value: int, damage_type: String, affix_array: Array):

	var damage_result = damage_value
	var critical_damage := false
	var life_steal_result := 0

	if damage_result <= 0:
		return

	if not ["Melee_attack", "Ranged_attack", "Magic_attack", "Continuous_effect", "Free_strike"].has(damage_type):
		return

	if not DataManagerSingleton.check_chess_valid(target):
		return

	if target.effect_handler.is_immunity or (damage_type == "Magic_attack" and target.effect_handler.is_spell_immunity):
		return

	if attacker.effect_handler.is_insulation or damage_type == "Continuous_effect":
		attacker.damage_applied.emit(attacker, target, damage_result)
		target.damage_taken.emit(target, attacker, damage_result)
		return	

	if (target.get("evasion_rate") != null and randf() <= target.evasion_rate and not affix_array.has("ignore_evasion") and damage_type != "Magic_attack") or (damage_type == "Free_strike" and target.effect_handler.is_parry):
		target.attack_evased.emit(target, attacker)
		return

	var speller_bonus_level = attacker.faction_bonus_manager.get_bonus_level("speller", attacker.team)

	if (attacker.get("critical_rate") != null and (randf() <= attacker.critical_rate and damage_type != "Magic_attack" and not target.effect_handler.is_critical_immunity)) or affix_array.has("force_critical"):
		damage_result *= attacker.critical_damage
		critical_damage = true
	elif speller_bonus_level > 0 and attacker.role == "speller" and damage_type == "Magic_attack":
		if randf() <= speller_bonus_level * 0.1:
			damage_result *= attacker.critical_damage
			critical_damage = true				

	var elf_bonus_level = attacker.faction_bonus_manager.get_bonus_level("elf", attacker.team)
	var pikeman_bonus_level = attacker.faction_bonus_manager.get_bonus_level("pikeman", attacker.team)

	var min_damage_value = elf_bonus_level if elf_bonus_level > 0 else 1

	if pikeman_bonus_level > 0 and target.role == "knight" and attacker.role == "pikeman":
		damage_result += pikeman_bonus_level


	if target.is_phantom and damage_type != "Magic_attack":
		damage_result *= 2
	elif target.is_phantom and damage_type == "Magic_attack":
		damage_result *= 10

	if attacker.is_phantom:
		damage_result = floor(damage_result / 2)

	var forest_bonus_level := 0
	var vengeance_faction := ""


	if target.faction == "forestProtector":
		forest_bonus_level = get_parent().get_effective_bonus_level("forestProtector", target.team, "path3")

		vengeance_faction = ""
		for effect_index in target.effect_handler.effect_list:
			if effect_index.effect_applier == "ForestProtector path3 Faction Bonus":
				vengeance_faction = effect_index.effect_name.rsplit(" ", true, 1)[1]
				break

		if forest_bonus_level != 0 and attacker.faction == vengeance_faction:
			damage_result -= forest_bonus_level

	if attacker.faction == "forestProtector":
		forest_bonus_level = get_parent().get_effective_bonus_level("forestProtector", target.team, "path3")

		vengeance_faction = ""
		for effect_index in attacker.effect_handler.effect_list:
			if effect_index.effect_applier == "ForestProtector path3 Faction Bonus":
				vengeance_faction = effect_index.effect_name.rsplit(" ", true, 1)[1]
				break

		if forest_bonus_level != 0 and target.faction == vengeance_faction:
			damage_result += forest_bonus_level

	if not affix_array.has("ignore_armor") and damage_type != "Magic_attack":
		damage_result -= target.armor
		# if damage_result < 0:
		# 	return

	damage_result = floor(damage_result)
		
	#====================do not modify damage_result after============================

	damage_result = max(damage_result, min_damage_value)

	if attacker.life_steal_rate > 0 or (attacker.faction == "forestProtector" and attacker.chess_name == "SatyrWarrior"):
		life_steal_result = floor(attacker.life_steal_rate * damage_result) if attacker.life_steal_rate > 0 else floor(damage_result * 0.2 * attacker.chess_level)

	if critical_damage:
		attacker.critical_damage_applied.emit(attacker, target, damage_result)
	else:
		attacker.damage_applied.emit(attacker, target, damage_result)

	target.damage_taken.emit(target, attacker, damage_result)

	if target.reflect_damage > 0:
		attacker.damage_taken.emit(attacker, target, target.reflect_damage)
	
	if life_steal_result > 0:
		attacker._apply_heal(attacker, life_steal_result)
		
	var ghost_nearby = get_parent().arena.unit_grid.get_valid_chess_in_radius(attacker.get_current_tile(attacker)[1], 3).filter(
		func(chess):
			if (chess.chess_name == "Ghost" or chess.chess_name == "Reaper") and chess.team != attacker.team and DataManagerSingleton.check_chess_valid(chess):
				var chess_tile = chess.get_current_tile(chess)[1]
				var attacker_tile = attacker.get_current_tile(attacker)[1]
				if abs(chess_tile.x - attacker_tile.x) + abs(chess_tile.y - attacker_tile.y) <= chess.chess_level + (1 if chess.chess_name == "Reaper" else 0):
					return true
			return false
	)
	if ghost_nearby.size() <= 0: 
		if attacker != target and damage_type != "Magic_attack":
			attacker.gain_mp(1)
		elif attacker != target and damage_type == "Magic_attack" and attacker.chess_name == "ArchMage" and attacker.faction == "human":
			attacker.gain_mp(1)
			
		if attacker != target:
			target.gain_mp(1)

	if attacker.chess_name == "Queen" and attacker.faction == "elf" and damage_type == "Magic_attack":
		attacker.random_heal(damage_result, attacker)
