class_name DebugHandler
extends Node2D

var debug_mode := false

# File handler and path configuration
var log_file : FileAccess
var log_path = "user://logs/"

func _ready():
	_init_log_file()

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

func connect_to_hero_signal(hero: Hero):
	hero.died.connect(
		func(hero_name):
			write_log("LOG", hero_name + " died.")
	)
	hero.move_started.connect(
		func(hero_name, start_position):
			write_log("LOG", hero_name + " started to move from " + str(start_position.x) + "," + str(start_position.y))
	)
	hero.move_finished.connect(
		func(hero_name, end_position):
			write_log("LOG", hero_name + " ended to move from " + str(end_position.x) + "," + str(end_position.y))
	)
	hero.action_started.connect(
		func(hero_name, end_position):
			write_log("LOG", hero_name + " action started.")
	)
	#hero.action_finished.connect(
		#func(hero_name):
			#write_log("LOG", hero_name + " action finished.")
	#)
	hero.damage_taken.connect(
		func(hero_name, damage_value, attacker_name):
			write_log("LOG", hero_name + " has taken " + str(damage_value) + "points damage from " + attacker_name + ".")
	)
	hero.heal_taken.connect(
		func(hero_name, heal_value, healer_name):
			write_log("LOG", hero_name + " has taken " + str(heal_value) + "points heal from " + healer_name + ".")
	)
	hero.is_hit.connect(
		func(hero_name):
			write_log("LOG", hero_name + " gets hit.")
	)
	hero.spell_casted.connect(
		func(hero_name, spell_name):
			write_log("LOG", hero_name + "has casted a spell called " + spell_name + ".")
	)
	hero.ranged_attack_started.connect(
		func(hero_name):
			write_log("LOG", hero_name + "'s ranged attack has started.")
	)
	hero.melee_attack_started.connect(
		func(hero_name):
			write_log("LOG", hero_name + "'s melee attack has started.")
	)
	hero.ranged_attack_finished.connect(
		func(hero_name):
			write_log("LOG", hero_name + "'s ranged attack has finished.")
	)
	hero.melee_attack_finished.connect(
		func(hero_name):
			write_log("LOG", hero_name + "'s melee attack has finished.")
	)
	hero.damage_applied.connect(
		func(hero_name, damage_value, target_name):
			write_log("LOG", hero_name + " has applied damage " + str(damage_value) + " points to " + target_name)
	)
	hero.critical_damage_applied.connect(
		func(hero_name, damage_value, target_name):
			write_log("LOG", hero_name + " has applied CRITICAL damage " + str(damage_value) + " points to " + target_name)
	)
	hero.heal_applied.connect(
		func(hero_name, heal_value, target_name):
			write_log("LOG", hero_name + " has applied heal " + str(heal_value) + " points to " + target_name)
	)
	hero.animated_sprite_loaded.connect(
		func(hero_name, anim_name):
			write_log("LOG", hero_name + "'s animtion sprtie: " + anim_name + " has loaded.")
	)
	hero.stats_loaded.connect(
		func(hero_name, hero_stats):
			write_log("LOG", hero_name + "'s stats has loaded as belows:")
			for i in range(hero_stats.size()):
				write_log("LOG", hero_stats.keys()[i] + " = " + hero_stats.values()[i])
	)
	hero.attack_evased.connect(
		func(hero_name, attacker_name):
			write_log("LOG", hero_name + " has EVASED " + attacker_name + "'s attack.")
	)
	hero.target_lost.connect(
		func(hero_name):
			write_log("LOG", hero_name + "does not have a target or target lost.")
	)
	hero.target_found.connect(
		func(hero_name, target_name):
			write_log("LOG", hero_name + " has found a new target: " + target_name + ".")
	)
	hero.tween_moving.connect(
		func(hero_name, start_pos, target_pos):
			write_log("LOG", hero_name + " starts tweeming move from " + str(start_pos) + " to " + str(target_pos) + ".")
	)
	hero.projectile_lauched.connect(
		func(hero_name):
			write_log("LOG", hero_name + " has lauched a projectile.")
	)
