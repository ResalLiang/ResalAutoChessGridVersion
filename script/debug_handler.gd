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
	elif DataManagerSingleton.current_player == "debug":
		debug_mode = true
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

func connect_to_chess_signal(chess: Chess):
	if chess.has_signal("is_died"):
		chess.is_died.connect(
			func():
				write_log("LOG", chess.chess_name + " died.")
				if debug_mode:
					print(chess.chess_name + " died.")
		)
	if chess.has_signal("move_started"):
		chess.move_started.connect(
			func(chess, start_position):
				write_log("LOG", chess.chess_name + " started to move from " + str(start_position.x) + "," + str(start_position.y))
				if debug_mode:
					print(chess.chess_name + " started to move from " + str(start_position.x) + "," + str(start_position.y))
		)
	if chess.has_signal("move_finished"):
		chess.move_finished.connect(
			func(chess, end_position):
				write_log("LOG", chess.chess_name + " ended to move from " + str(end_position.x) + "," + str(end_position.y))
				if debug_mode:
					print(chess.chess_name + " ended to move from " + str(end_position.x) + "," + str(end_position.y))
		)
	if chess.has_signal("action_started"):
		chess.action_started.connect(
			func(chess, end_position):
				write_log("LOG", chess.chess_name + " action started.")
				if debug_mode:
					print(chess.chess_name + " action started.")
		)
	if chess.has_signal("action_finished"):
		chess.action_finished.connect(
			func(chess):
				write_log("LOG", chess.chess_name + " action finished.")
				if debug_mode:
					print(chess.chess_name + " action finished.")
		)
	if chess.has_signal("damage_taken"):
		chess.damage_taken.connect(
			func(chess, attacker, damage_value):
				write_log("LOG", chess.chess_name + " has taken " + str(damage_value) + "points damage from " + attacker.chess_name + ".")
				if debug_mode:
					print(chess.chess_name + " has taken " + str(damage_value) + "points damage from " + attacker.chess_name + ".")
		)
	if chess.has_signal("heal_taken"):
		chess.heal_taken.connect(
			func(chess, healer, heal_value):
				write_log("LOG", chess.chess_name + " has taken " + str(heal_value) + "points heal from " + healer.chess_name + ".")
				if debug_mode:
					print(chess.chess_name + " has taken " + str(heal_value) + "points heal from " + healer.chess_name + ".")
		)
	if chess.has_signal("is_hit"):
		chess.is_hit.connect(
			func(chess):
				write_log("LOG", chess.chess_name + " gets hit.")
				if debug_mode:
					print(chess.chess_name + " gets hit.")
		)
	if chess.has_signal("spell_casted"):
		chess.spell_casted.connect(
			func(chess, spell_name):
				write_log("LOG", chess.chess_name + "has casted a spell called " + spell_name + ".")
				if debug_mode:
					print(chess.chess_name + "has casted a spell called " + spell_name + ".")
		)
	if chess.has_signal("ranged_attack_started"):
		chess.ranged_attack_started.connect(
			func(chess):
				write_log("LOG", chess.chess_name + "'s ranged attack has started.")
				if debug_mode:
					print(chess.chess_name + "'s ranged attack has started.")
		)
	if chess.has_signal("melee_attack_started"):
		chess.melee_attack_started.connect(
			func(chess):
				write_log("LOG", chess.chess_name + "'s melee attack has started.")
				if debug_mode:
					print(chess.chess_name + "'s melee attack has started.")
		)
	if chess.has_signal("ranged_attack_finished"):
		chess.ranged_attack_finished.connect(
			func(chess):
				write_log("LOG", chess.chess_name + "'s ranged attack has finished.")
				if debug_mode:
					print(chess.chess_name + "'s ranged attack has finished.")
		)
	if chess.has_signal("melee_attack_finished"):
		chess.melee_attack_finished.connect(
			func(chess):
				write_log("LOG", chess.chess_name + "'s melee attack has finished.")
				if debug_mode:
					print(chess.chess_name + "'s melee attack has finished.")
		)
	if chess.has_signal("damage_applied"):
		chess.damage_applied.connect(
			func(chess, target, damage_value):
				write_log("LOG", chess.chess_name + " has applied damage " + str(damage_value) + " points to " + target.chess_name)
				if debug_mode:
					print(chess.chess_name + " has applied damage " + str(damage_value) + " points to " + target.chess_name)
		)
	if chess.has_signal("critical_damage_applied"):
		chess.critical_damage_applied.connect(
			func(chess, target, damage_value):
				write_log("LOG", chess.chess_name + " has applied CRITICAL damage " + str(damage_value) + " points to " + target.chess_name)
				if debug_mode:
					print(chess.chess_name + " has applied CRITICAL damage " + str(damage_value) + " points to " + target.chess_name)
		)
	if chess.has_signal("heal_applied"):
		chess.heal_applied.connect(
			func(chess, target, heal_value):
				write_log("LOG", chess.chess_name + " has applied heal " + str(heal_value) + " points to " + target.chess_name)
				if debug_mode:
					print(chess.chess_name + " has applied heal " + str(heal_value) + " points to " + target.chess_name)
		)
	if chess.has_signal("animated_sprite_loaded"):
		chess.animated_sprite_loaded.connect(
			func(chess, anim_name):
				write_log("LOG", chess.chess_name + "'s animtion sprtie: " + anim_name + " has loaded.")
				if debug_mode:
					print(chess.chess_name + "'s animtion sprtie: " + anim_name + " has loaded.")
		)
	if chess.has_signal("stats_loaded"):
		chess.stats_loaded.connect(
			func(chess, chess_stats):
				write_log("LOG", chess.chess_name + "'s stats has loaded as belows:")
				if debug_mode:
					print(chess.chess_name + "'s stats has loaded as belows:")
				for i in range(chess_stats.size()):
					write_log("LOG", chess_stats.keys()[i] + " = " + str(chess_stats.values()[i]))
					if debug_mode:
						print(chess_stats.keys()[i] + " = " + str(chess_stats.values()[i]))
		)
	if chess.has_signal("attack_evased"):
		chess.attack_evased.connect(
			func(chess, attacker):
				write_log("LOG", chess.chess_name + " has EVASED " + attacker.chess_name + "'s attack.")
				if debug_mode:
					print(chess.chess_name + " has EVASED " + attacker.chess_name + "'s attack.")
		)
	if chess.has_signal("target_lost"):
		chess.target_lost.connect(
			func(chess):
				write_log("LOG", chess.chess_name + " does not have a target or target lost.")
				if debug_mode:
					print(chess.chess_name + " does not have a target or target lost.")
		)
	if chess.has_signal("target_found"):
		chess.target_found.connect(
			func(chess, target):
				write_log("LOG", chess.chess_name + " has found a new target: " + target.chess_name + ".")
				if debug_mode:
					print(chess.chess_name + " has found a new target: " + target.chess_name + ".")
		)
	if chess.has_signal("tween_moving"):
		chess.tween_moving.connect(
			func(chess, start_pos, target_pos):
				write_log("LOG", chess.chess_name + " starts tweeming move from " + str(start_pos) + " to " + str(target_pos) + ".")
				if debug_mode:
					print(chess.chess_name + " starts tweeming move from " + str(start_pos) + " to " + str(target_pos) + ".")
		)
	if chess.has_signal("projectile_lauched"):
		chess.projectile_lauched.connect(
			func(chess):
				write_log("LOG", chess.chess_name + " has lauched a projectile.")
				if debug_mode:
					print(chess.chess_name + " has lauched a projectile.")
		)
