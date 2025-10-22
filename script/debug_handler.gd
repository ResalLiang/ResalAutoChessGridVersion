class_name DebugHandler
extends Node2D

var debug_mode := true

# File handler and path configuration
var log_file : FileAccess
var log_path = "user://logs/"

func _ready():
	_init_log_file()
	if DataManagerSingleton.player_datas[DataManagerSingleton.current_player].keys().has("debug_mode"):
		debug_mode = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"]
	else:
		DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"] = false
		debug_mode = false

# Initialize log file with timestamp
func _init_log_file():
	var dir = DirAccess.open("user://")
	if dir != null:
		dir.make_dir_recursive(log_path)
		
	var datetime = Time.get_datetime_dict_from_system()
	var filename = "log_%04d%02d%02d_%02d%02d%02d.txt" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	
	log_file = FileAccess.open(log_path + filename, FileAccess.WRITE)

# Write message with timestamp to log file
func write_log(log_type: String, message: String):
	if log_file.is_open():
		var time = Time.get_datetime_dict_from_system()
		log_file.store_string("[%02d:%02d:%02d] [%s]: %s\n" % [
			time.hour, time.minute, time.second, log_type, message])
		log_file.flush()

func connect_to_chess_signal(obstacle: Obstacle):
	if obstacle.has_signal("is_died"):
		obstacle.is_died.connect(
			func():
				write_log("LOG", obstacle.chess_name + " died.")
				if debug_mode:
					print(obstacle.chess_name + " died.")
		)
	if obstacle.has_signal("move_started"):
		obstacle.move_started.connect(
			func(obstacle, start_position):
				write_log("LOG", obstacle.chess_name + " started to move from " + str(start_position.x) + "," + str(start_position.y))
				if debug_mode:
					print(obstacle.chess_name + " started to move from " + str(start_position.x) + "," + str(start_position.y))
		)
	if obstacle.has_signal("move_finished"):
		obstacle.move_finished.connect(
			func(obstacle, end_position):
				write_log("LOG", obstacle.chess_name + " ended to move from " + str(end_position.x) + "," + str(end_position.y))
				if debug_mode:
					print(obstacle.chess_name + " ended to move from " + str(end_position.x) + "," + str(end_position.y))
		)
	if obstacle.has_signal("action_started"):
		obstacle.action_started.connect(
			func(obstacle, end_position):
				write_log("LOG", obstacle.chess_name + " action started.")
				if debug_mode:
					print(obstacle.chess_name + " action started.")
		)
	if obstacle.has_signal("action_finished"):
		obstacle.action_finished.connect(
			func(obstacle):
				write_log("LOG", obstacle.chess_name + " action finished.")
				if debug_mode:
					print(obstacle.chess_name + " action finished.")
		)
	if obstacle.has_signal("damage_taken"):
		obstacle.damage_taken.connect(
			func(obstacle, attacker, damage_value):
				write_log("LOG", obstacle.chess_name + " has taken " + str(damage_value) + "points damage from " + attacker.chess_name + ".")
				if debug_mode:
					print(obstacle.chess_name + " has taken " + str(damage_value) + "points damage from " + attacker.chess_name + ".")
		)
	if obstacle.has_signal("heal_taken"):
		obstacle.heal_taken.connect(
			func(obstacle, healer, heal_value):
				write_log("LOG", obstacle.chess_name + " has taken " + str(heal_value) + "points heal from " + healer.chess_name + ".")
				if debug_mode:
					print(obstacle.chess_name + " has taken " + str(heal_value) + "points heal from " + healer.chess_name + ".")
		)
	if obstacle.has_signal("is_hit"):
		obstacle.is_hit.connect(
			func(obstacle):
				write_log("LOG", obstacle.chess_name + " gets hit.")
				if debug_mode:
					print(obstacle.chess_name + " gets hit.")
		)
	if obstacle.has_signal("spell_casted"):
		obstacle.spell_casted.connect(
			func(obstacle, spell_name):
				write_log("LOG", obstacle.chess_name + "has casted a spell called " + spell_name + ".")
				if debug_mode:
					print(obstacle.chess_name + "has casted a spell called " + spell_name + ".")
		)
	if obstacle.has_signal("ranged_attack_started"):
		obstacle.ranged_attack_started.connect(
			func(obstacle):
				write_log("LOG", obstacle.chess_name + "'s ranged attack has started.")
				if debug_mode:
					print(obstacle.chess_name + "'s ranged attack has started.")
		)
	if obstacle.has_signal("melee_attack_started"):
		obstacle.melee_attack_started.connect(
			func(obstacle):
				write_log("LOG", obstacle.chess_name + "'s melee attack has started.")
				if debug_mode:
					print(obstacle.chess_name + "'s melee attack has started.")
		)
	if obstacle.has_signal("ranged_attack_finished"):
		obstacle.ranged_attack_finished.connect(
			func(obstacle):
				write_log("LOG", obstacle.chess_name + "'s ranged attack has finished.")
				if debug_mode:
					print(obstacle.chess_name + "'s ranged attack has finished.")
		)
	if obstacle.has_signal("melee_attack_finished"):
		obstacle.melee_attack_finished.connect(
			func(obstacle):
				write_log("LOG", obstacle.chess_name + "'s melee attack has finished.")
				if debug_mode:
					print(obstacle.chess_name + "'s melee attack has finished.")
		)
	if obstacle.has_signal("damage_applied"):
		obstacle.damage_applied.connect(
			func(obstacle, target, damage_value):
				write_log("LOG", obstacle.chess_name + " has applied damage " + str(damage_value) + " points to " + target.chess_name)
				if debug_mode:
					print(obstacle.chess_name + " has applied damage " + str(damage_value) + " points to " + target.chess_name)
		)
	if obstacle.has_signal("critical_damage_applied"):
		obstacle.critical_damage_applied.connect(
			func(obstacle, target, damage_value):
				write_log("LOG", obstacle.chess_name + " has applied CRITICAL damage " + str(damage_value) + " points to " + target.chess_name)
				if debug_mode:
					print(obstacle.chess_name + " has applied CRITICAL damage " + str(damage_value) + " points to " + target.chess_name)
		)
	if obstacle.has_signal("heal_applied"):
		obstacle.heal_applied.connect(
			func(obstacle, target, heal_value):
				write_log("LOG", obstacle.chess_name + " has applied heal " + str(heal_value) + " points to " + target.chess_name)
				if debug_mode:
					print(obstacle.chess_name + " has applied heal " + str(heal_value) + " points to " + target.chess_name)
		)
	if obstacle.has_signal("animated_sprite_loaded"):
		obstacle.animated_sprite_loaded.connect(
			func(obstacle, anim_name):
				write_log("LOG", obstacle.chess_name + "'s animtion sprtie: " + anim_name + " has loaded.")
				if debug_mode:
					print(obstacle.chess_name + "'s animtion sprtie: " + anim_name + " has loaded.")
		)
	if obstacle.has_signal("stats_loaded"):
		obstacle.stats_loaded.connect(
			func(obstacle, chess_stats):
				write_log("LOG", obstacle.chess_name + "'s stats has loaded as belows:")
				if debug_mode:
					print(obstacle.chess_name + "'s stats has loaded as belows:")
				for i in range(chess_stats.size()):
					write_log("LOG", chess_stats.keys()[i] + " = " + str(chess_stats.values()[i]))
					if debug_mode:
						print(chess_stats.keys()[i] + " = " + str(chess_stats.values()[i]))
		)
	if obstacle.has_signal("attack_evased"):
		obstacle.attack_evased.connect(
			func(obstacle, attacker):
				write_log("LOG", obstacle.chess_name + " has EVASED " + attacker.chess_name + "'s attack.")
				if debug_mode:
					print(obstacle.chess_name + " has EVASED " + attacker.chess_name + "'s attack.")
		)
	if obstacle.has_signal("target_lost"):
		obstacle.target_lost.connect(
			func(obstacle):
				write_log("LOG", obstacle.chess_name + " does not have a target or target lost.")
				if debug_mode:
					print(obstacle.chess_name + " does not have a target or target lost.")
		)
	if obstacle.has_signal("target_found"):
		obstacle.target_found.connect(
			func(obstacle, target):
				write_log("LOG", obstacle.chess_name + " has found a new target: " + target.chess_name + ".")
				if debug_mode:
					print(obstacle.chess_name + " has found a new target: " + target.chess_name + ".")
		)
	if obstacle.has_signal("tween_moving"):
		obstacle.tween_moving.connect(
			func(obstacle, start_pos, target_pos):
				write_log("LOG", obstacle.chess_name + " starts tweeming move from " + str(start_pos) + " to " + str(target_pos) + ".")
				if debug_mode:
					print(obstacle.chess_name + " starts tweeming move from " + str(start_pos) + " to " + str(target_pos) + ".")
		)
	if obstacle.has_signal("projectile_lauched"):
		obstacle.projectile_lauched.connect(
			func(obstacle):
				write_log("LOG", obstacle.chess_name + " has lauched a projectile.")
				if debug_mode:
					print(obstacle.chess_name + " has lauched a projectile.")
		)
