class_name Chess
extends Obstacle


# ========================
# Constants and Enums
# ========================
# Character states
#enum STATUS {IDLE, MOVE, MELEE_ATTACK, RANGED_ATTACK, JUMP, HIT, DIE, SPELL}
enum TARGET_CHOICE {CLOSE, FAR, STRONG, WEAK, ALLY, SELF}

#enum play_areas {playarea_arena, playarea_bench, playarea_shop}

#const MAX_SEARCH_RADIUS = 3
#const projectile_scene = preload("res://scene/projectile.tscn")
#const chess_scene = preload("res://scene/chess.tscn")

@onready var melee_attack_animation: AnimationPlayer = $melee_attack_animation
@onready var ranged_attack_animation: AnimationPlayer = $ranged_attack_animation
#@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
#@onready var area_2d: Area2D = $Area2D
#@onready var idle_timer: Timer = $idle_timer
@onready var attack_target_line: Line2D = $attack_target_line  # Attack range indicator
@onready var spell_target_line: Line2D = $spell_target_line  # Spell range indicator
#@onready var drag_handler: Node2D = $drag_handler
#@onready var move_timer: Timer = $move_timer
#@onready var action_timer: Timer = $action_timer
#@onready var debug_handler: DebugHandler = %debug_handler
#@onready var area_effect_handler: AreaEffectHandler = $area_effect_handler
#@onready var hp_bar: ProgressBar = $hp_bar
#@onready var mp_bar: ProgressBar = $mp_bar

# ========================
# Exported Variables
# ========================
# Character faction with property observer
#@export_enum("human", "dwarf", "elf", "forestProtector", "holy", "demon", "undead", "villager") var faction := "human"

# Chess name with property observer
#@export var chess_name := "ShieldMan"
	#set(value):
		#chess_name = value
		## Load animation resource in editor mode
		#if ResourceLoader.exists("res://asset/animation/" + faction + "/" + faction + chess_name + ".tres"):
			#animated_sprite_2d.sprite_frames = ResourceLoader.load("res://asset/animation/" + faction + "/" + faction + chess_name + ".tres")
		#_load_chess_stats()

#var chess_serial := 1001

#============================================
# Basic attack statics
#============================================
#var is_obstacle := false
#var obstacle_counter := 0
#var obstacle_level := 0
#
#var base_max_hp := 100  # Maximum health points
#var base_max_mp := 50   # Maximum magic points
#var base_speed := 8
var base_melee_damage := 20   # Attack damage
var base_ranged_damage := 20   # Attack damage
var base_attack_speed := 1 # Attack speed (attacks per turn)
var base_attack_range := 20 # Attack range (pixels)
var base_evasion_rate := 0.10
var base_critical_rate := 0.10
#var base_armor := 0
#
#var hp: int = base_max_hp:
	#set(value):
		#hp = min(value, max_hp)
		#hp = max(0, hp)
#var mp: int = 0:
	#set(value):
		#mp = min(value, max_mp)
		#mp = max(0, mp)
#
#var max_hp = base_max_hp:
	#set(value):
		#var update_hp = value * (hp / max_hp)
		#max_hp = value
		#hp = update_hp
#var max_mp = base_max_mp:
	#set(value):
		#var update_mp = value * (mp / max_mp)
		#max_mp = value
		#mp = update_mp

var speed = base_speed
var melee_damage = base_melee_damage
var ranged_damage = base_ranged_damage
var damage
var attack_speed = base_attack_speed
var attack_range = base_attack_range
var evasion_rate := 0.10
var critical_rate := 0.10
#var armor := 0
var chess_rarity := "Common" #	"Common", "Uncommon", "Rare", "Epic", "Legendary"

var remain_attack_count

#var chess_data: Dictionary  # Stores chess stats loaded from JSON
#
#var effect_handler = EffectHandler.new()

#============================================
# Target setting
#============================================
var chess_target_choice := TARGET_CHOICE.CLOSE  # Target selection strategy
var chess_target: Obstacle  # Current attack target
var chess_spell_target_choice := TARGET_CHOICE.CLOSE  # Target selection strategy
var chess_spell_target: Obstacle # Current spell target

#@export var team: int      # 0 for player, 1~7 for AI enemy

#============================================
# Play Area Related
#============================================
#var arena: PlayArea
#var bench: PlayArea
#var shop: PlayArea
#
#var current_play_area = play_areas.playarea_arena

#============================================
# Movement Related
#============================================
var move_path: PackedVector2Array
#var position_id := Vector2i.ZERO
#var _position := Vector2.ZERO:
	#set(value):
		#_position = value
		#position = _position
		#position_id = Vector2i(
			#snap(value.x, 16),
			#snap(value.y, 16)
		#)
var astar_grid
var position_tween
#var is_active: bool = false
#var grid_offset =Vector2(8, 8)
var remain_step:= 0
var astar_grid_region = Rect2i(0, 0, 16, 16)

#var dragging_enabled: bool = true # Enable/disable dragging

#============================================
#Appreance Related
#============================================
@export var line_visible:= false
#var sprite_frames: SpriteFrames  # Custom sprite frames
#var action_timer_wait_time := 0.5
#var move_timer_wait_time := 0.5
#============================================
# Skill or Spell Related
#============================================
#var skill_name := "Place holder."
#var skill_description := "Place holder."

#var taunt_range := 70

# Projectile Related
#var projectile_speed: float = 300.0  # Projectile speed
#var projectile_damage: int = 15  # Projectile damage
#var projectile_penetration: int = 3  # Number of enemies projectile can penetrate
#var ranged_attack_threshold: float = 32.0  # Minimum distance for ranged attack
#var projectile


#var status := STATUS.IDLE         # Current character state

#var rng = RandomNumberGenerator.new() # Random number generator

#============================================
# Signals
#============================================

# signal stats_loaded(obstacle: Obstacle)
# signal animated_sprite_loaded(obstacle: Obstacle)

# signal target_found(obstacle: Obstacle, target: Obstacle)
# signal target_lost(obstacle: Obstacle)

# signal move_started(obstacle: Obstacle, current_position: Vector2i) # for audio player
# signal move_finished(obstacle: Obstacle, current_position: Vector2i) # for audio player
# signal action_started(obstacle: Obstacle)
# signal action_finished(obstacle: Obstacle)

# signal spell_casted(obstacle: Obstacle, spell_name: String) # for audio player
# signal ranged_attack_started(obstacle: Obstacle) # for audio player
# signal ranged_attack_finished(obstacle: Obstacle)
# signal melee_attack_started(obstacle: Obstacle) # for audio player
# signal melee_attack_finished(obstacle: Obstacle)
# signal projectile_lauched(obstacle: Obstacle) # for audio player

# signal damage_applied(obstacle: Obstacle, attack_target: Obstacle, damage_value: float)
# signal critical_damage_applied(obstacle: Obstacle, attack_target: Obstacle, damage_value: float)
# signal heal_applied(obstacle: Obstacle, heal_target: Obstacle, heal_value: float)

# signal damage_taken(obstacle: Obstacle, attacker: Obstacle, damage_value: float) # for audio player and display
# signal critical_damage_taken(obstacle: Obstacle, attacker: Obstacle, damage_value: float) # for audio player and display
# signal heal_taken(obstacle: Obstaclet, healer: Obstacle, heal_value: floa) # for audio player and display
# signal attack_evased(obstacle: Obstacle, attacker: Obstacle) # for audio player and display

# signal is_died(obstacle: Obstacle) # for audio player and display


# ========================
# Initialization
# ========================
func _ready():
	
	chess_mover = arena.get_parent().get_parent().chess_mover
		
	drag_handler.dragging_enabled = dragging_enabled
	

	# Load animations
	_load_animations()

	# Validate node references before proceeding
	if not _validate_node_references():
		push_error("Chess node setup is invalid!")
		return
	
	
	# Connect signals
	idle_timer.timeout.connect(_on_idle_timeout)
	move_timer.timeout.connect(_handle_action)
	action_timer.timeout.connect(_handle_action_timeout)
	
	drag_handler.drag_started.connect(_handle_dragging_state)

	drag_handler.drag_canceled.connect(_handle_dragging_state)
	drag_handler.drag_dropped.connect(_handle_dragging_state)
	

	is_died.connect(_on_died)
	
	# Initialize random number generator
	rng.randomize()
	idle_timer.set_wait_time(rng.randf_range(1.0,3.0))
	idle_timer.start()  # Start idle state timer
	
	# Play idle animation
	animated_sprite_2d.play("idle")
	
	if team == 2:
		animated_sprite_2d.flip_h = true
		
	# Add to chess group for targeting
	add_to_group("chess_group")
	add_to_group("obstacle_group")
	
	# Configure attack indicator line
	attack_target_line.width = 0.5
	if chess_target_choice == TARGET_CHOICE.ALLY:
		attack_target_line.default_color = Color(0, 1, 0)
	else:
		attack_target_line.default_color = Color(1, 0, 0)
	attack_target_line.visible = true
	
	# Configure attack indicator line
	spell_target_line.width = 0.5
	spell_target_line.default_color = Color(0, 0, 1)
	spell_target_line.visible = false
	
	# Load chess stats from JSON
	_load_chess_stats()
	
	# Initialize character properties
	hp = max_hp
	mp = max_mp

	hp_bar.min_value = 0
	hp_bar.max_value = max_hp
	mp_bar.min_value = 0
	mp_bar.max_value = max_mp
	hp_bar.value = max_hp
	mp_bar.value = 0
	
	astar_grid = AStarGrid2D.new()
	#astar_grid_region = Rect2i(tile_size.x / 2, tile_size.y / 2, tile_size.x / 2 + tile_size.x * (grid_count - 1), tile_size.y / 2 + tile_size.y * (grid_count - 1))
	astar_grid.region = astar_grid_region
	astar_grid.cell_size = Vector2(16, 16)
	astar_grid.diagonal_mode = 2
	astar_grid.update()
	
	if not animated_sprite_2d.sprite_frames.has_animation("spell") :
		mp_bar.visible = false
		
	area_effect_handler.arena = arena

	connect_to_data_manager()

# ========================
# Process Functions
# ========================


func _process(delta: float) -> void:
	
	hp_bar.value = hp
	mp_bar.value = mp

	hp_bar.max_value = max_hp
	mp_bar.max_value = max_mp

	hp_bar.visible = true #hp != max_hp
		
	# Update attack indicator line
	if chess_target and line_visible:
		attack_target_line.points = [Vector2.ZERO, to_local(chess_target.global_position)]
		attack_target_line.visible = true
		
	# Update attack indicator line
	if chess_spell_target and line_visible:
		spell_target_line.points = [Vector2.ZERO, to_local(chess_spell_target.global_position)]
		spell_target_line.visible = true
		
	var new_material = animated_sprite_2d.material.duplicate()

	match team:
		1:
			if is_active:
				new_material.set_shader_parameter("outline_color", Color(1, 1, 0, 1))
			else:
				new_material.set_shader_parameter("outline_color", Color(1, 1, 0, 0.33))
		2:
			if is_active:
				new_material.set_shader_parameter("outline_color", Color(1, 0, 1, 1))
			else:
				new_material.set_shader_parameter("outline_color", Color(1, 0, 1, 0.33))
		3:
			if is_active:
				new_material.set_shader_parameter("outline_color", Color(0, 1, 1, 1))
			else:
				new_material.set_shader_parameter("outline_color", Color(0, 1, 1, 0.33))
		_:
			if is_active:
				new_material.set_shader_parameter("outline_color", Color(1, 1, 1, 1))
			else:
				new_material.set_shader_parameter("outline_color", Color(1, 1, 1, 0.33))


	#if current_play_area == play_areas.playarea_shop:
	if shop.unit_grid.get_all_units().has(self):
		match chess_rarity: #"Common", "Uncommon", "Rare", "Epic", "Legendary"
			"Common":
				new_material.set_shader_parameter("outline_color", Color.RED)
			"Uncommon":
				new_material.set_shader_parameter("outline_color", Color.BLUE)
			"Rare":
				new_material.set_shader_parameter("outline_color", Color.GREEN)
			"Epic":
				new_material.set_shader_parameter("outline_color", Color.PURPLE)
			"Legendary":
				new_material.set_shader_parameter("outline_color", Color.YELLOW)

	if status == STATUS.HIT:			
		if is_active:
			new_material.set_shader_parameter("outline_color", Color(1, 0, 0, 1))
		else:
			new_material.set_shader_parameter("outline_color", Color(1, 0, 0, 0.33))

	if drag_handler.dragging:
		new_material.set_shader_parameter("blink_color", Color(1, 1, 1, 1))
		new_material.set_shader_parameter("blink_time_scale ",0.3)
	else:
		new_material.set_shader_parameter("blink_time_scale ",0)


	animated_sprite_2d.material = new_material

	if is_active:
		drag_handler.dragging_enabled = false
	else:
		drag_handler.dragging_enabled = dragging_enabled
		
	if chess_target:
		if (chess_target.global_position - global_position)[0] >= 0:
			animated_sprite_2d.flip_h = false
		else:
			animated_sprite_2d.flip_h = true

# ========================
# Private Functions
# ========================
# Validate all required node references
func _validate_node_references() -> bool:
	var valid = true
	
	if not animated_sprite_2d:
		push_error("AnimatedSprite2D reference is missing!")
		valid = false
	
	if not area_2d:
		push_error("Area2D reference is missing!")
		valid = false
	
	if not idle_timer:
		push_error("IdleTimer reference is missing!")
		valid = false

	if not animated_sprite_2d.sprite_frames.has_animation("move"):
		push_error("Move animation is missing!")
		valid = false

	if not animated_sprite_2d.sprite_frames.has_animation("hit"):
		push_error("Move animation is missing!")
		valid = false

	if not animated_sprite_2d.sprite_frames.has_animation("idle"):
		push_error("Move animation is missing!")
		valid = false

	if not animated_sprite_2d.sprite_frames.has_animation("die"):
		push_error("Move animation is missing!")
		valid = false

	return valid

# Load appropriate animations for the chess
func _load_animations():
	var path = "res://asset/animation/%s/%s%s.tres" % [faction, faction, chess_name]
	if ResourceLoader.exists(path):
		var frames = ResourceLoader.load(path)
		for anim_name in frames.get_animation_names():
			if anim_name == "move" or anim_name == "jump":
				frames.set_animation_loop(anim_name, true)
			else:
				frames.set_animation_loop(anim_name, false)
			frames.set_animation_speed(anim_name, 8.0)
			animated_sprite_loaded.emit(self, anim_name)
		animated_sprite_2d.sprite_frames = frames
	else:
		push_error("Animation resource not found: " + path)

# Load chess stats from JSON file
func _load_chess_stats():

	chess_data = DataManagerSingleton.get_chess_data()
	
	if not chess_data:
		push_error("JSON parsing failed for chess_stats.json")
		return
	
	# Safely retrieve stats if available
	if chess_data.has(faction) and chess_data[faction].has(chess_name):
		var stats = chess_data[faction][chess_name]
		base_speed = stats["speed"]
		base_max_hp = stats["max_health"]
		base_attack_range = stats["attack_range"]
		base_attack_speed = stats["attack_speed"]
		if base_attack_speed == 0:
			base_melee_damage = 0
			base_ranged_damage = 0
		elif (not animated_sprite_2d.sprite_frames.has_animation("melee_attack") and not animated_sprite_2d.sprite_frames.has_animation("attack")) or not stats.keys().has("melee_attack_damage"):
			base_melee_damage = 0
		elif base_attack_range <= 32 or not animated_sprite_2d.sprite_frames.has_animation("ranged_attack") or not stats.keys().has("ranged_attack_damage"):
			base_ranged_damage = 0
		else:
			base_melee_damage = stats["melee_attack_damage"]
			base_ranged_damage = stats["ranged_attack_damage"]
		skill_name = stats["skill_name"]
		skill_description = stats["skill_description"]
		chess_rarity = stats["rarity"]
		stats_loaded.emit(self, stats)
	else:
		push_error("Stats not found for %s/%s" % [faction, chess_name])

func start_turn():
	
	#Placeholder for chess passive ability on start turn
	if status == STATUS.DIE:
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()
		return

	update_solid_map()
	await get_tree().process_frame

	update_effect()

	remain_attack_count = attack_speed

	if not chess_target or not is_instance_valid(chess_target) or chess_target.status == STATUS.DIE:
		target_lost.emit(self)
		_handle_targeting()
		
	if chess_target and chess_target.status != STATUS.DIE:
		target_found.emit(self, chess_target)
		_handle_movement()
	else:
		action_timer.start()

func _handle_movement():
	#Placeholder for chess passive ability on movement
	
	if status == STATUS.DIE:
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()
		return

	var current_tile = get_current_tile(self)[1]

	move_started.emit(self, current_tile)
	#if current_play_area == play_areas.playarea_arena:
	if arena.unit_grid.get_all_units().has(self):
		arena.unit_grid.remove_unit(current_tile)

	animated_sprite_2d.play("move")

	if global_position.distance_to(chess_target.global_position) <= attack_range or effect_handler.is_stunned:
		move_finished.emit(self, current_tile)
		move_timer.set_wait_time(move_timer_wait_time)			
		move_timer.start()
	else:
		astar_grid.set_point_solid(current_tile, false)
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		move_path = astar_grid.get_point_path(current_tile, get_current_tile(chess_target)[1])
			
		if move_path.is_empty():
			move_path = get_safe_path(current_tile, get_current_tile(chess_target)[1])

		if move_path.is_empty():
			astar_grid.set_point_solid(get_current_tile(chess_target)[1], true)
			move_finished.emit(self, current_tile)
			move_timer.set_wait_time(move_timer_wait_time)
			move_timer.start()
		else:
			var move_steps = min(speed, move_path.size() - 1)

			# if position_tween:
			# 	position_tween.kill() # Abort the previous animation.
			# position_tween = create_tween()
			# position_tween.connect("finished", _on_move_completed)

			remain_step = move_steps
			for current_step in range(move_steps):
				var target_pos = move_path[current_step + 1] + grid_offset

				if astar_grid.is_point_solid(target_pos) or remain_step <= 0 or global_position.distance_to(chess_target.global_position) <= attack_range:
					break

				await chess_mover.tween_move_chess(self, arena, target_pos)

				# position_tween.tween_property(self, "_position", target_pos, 0.1)
				# tween_moving.emit(self, _position, target_pos)
				remain_step -= 1

			astar_grid.set_point_solid(get_current_tile(self)[1], true)
			astar_grid.set_point_solid(get_current_tile(chess_target)[1], true)
			#Placeholder for chess passive ability on move finish
			move_finished.emit(self,get_current_tile(self)[1])
			move_timer.set_wait_time(move_timer_wait_time)
			move_timer.start()

# func _on_move_completed():
# 	remain_step -= 1
# 	if remain_step <= 0 or global_position.distance_to(chess_target.global_position) <= attack_range:
# 		position_tween.pause()
# 		position_tween.kill()
# 		astar_grid.set_point_solid(position_id, true)
# 		astar_grid.set_point_solid(chess_target.position_id, true)
# 		if current_play_area == play_areas.playarea_arena:
# 			arena.unit_grid.add_unit(position_id, self)
# 		#Placeholder for chess passive ability on move finish
# 		move_finished.emit(self, _position)
# 		move_timer.set_wait_time(move_timer_wait_time)
# 		move_timer.start()
						
func _handle_action():

	arena.unit_grid.add_unit(get_current_tile(self)[1], self)

	if status == STATUS.DIE:
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()
		return

	move_timer.stop()
	action_started.emit(self)

	var current_tile = get_current_tile(self)[1]
		
	astar_grid.set_point_solid(current_tile, true)
	#Placeholder for chess passive ability on action start
	var cast_spell_result := false

	if mp >= max_mp and animated_sprite_2d.sprite_frames.has_animation("spell") and (not effect_handler.is_silenced and not effect_handler.is_stunned):

		chess_spell_target = _find_new_target(chess_spell_target_choice)

		if chess_spell_target:
			if chess_spell_target_choice == TARGET_CHOICE.SELF:
				status = STATUS.SPELL
				animated_sprite_2d.play("spell")
				cast_spell_result = await _cast_spell(self)
				if not cast_spell_result:
					animated_sprite_2d.stop()
				else:
					await animated_sprite_2d.animation_finished


			if chess_spell_target:
				status = STATUS.SPELL
				animated_sprite_2d.play("spell")
				cast_spell_result = await _cast_spell(chess_spell_target)
				if not cast_spell_result:
					animated_sprite_2d.stop()


			if cast_spell_result:
				action_timer.set_wait_time(action_timer_wait_time)
				action_timer.start()
				return

	if !chess_target or !is_instance_valid(chess_target) or chess_target.status == STATUS.DIE:
		target_lost.emit(self)
		action_timer.start()
		return
	else:
		_handle_attack()

func _handle_attack():

	if status == STATUS.DIE:
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()
		return

	if !chess_target or !is_instance_valid(chess_target) or chess_target.status == STATUS.DIE:
		target_lost.emit(self)
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()
		return

	#Placeholder for chess passive ability on attack
	var current_distance_to_target = global_position.distance_to(chess_target.global_position)
	remain_attack_count -= 1
	if current_distance_to_target <= attack_range and (not effect_handler.is_stunned and not effect_handler.is_disarmed):

		if not has_melee_target() and current_distance_to_target >= ranged_attack_threshold and animated_sprite_2d.sprite_frames.has_animation("ranged_attack"):
			status = STATUS.RANGED_ATTACK
			damage = ranged_damage
			if ResourceLoader.exists("res://asset/animation/%s/%s%s_projectile.tres" % [faction, faction, chess_name]):
				
				animated_sprite_2d.play("ranged_attack")
				ranged_attack_started.emit(self)
				var chess_projectile = _launch_projectile(chess_target)
				projectile_lauched.emit(self)

				# chess_projectile.projectile_vanished.connect(_on_animated_sprite_2d_animation_finished)
				chess_projectile.projectile_vanished.connect(
					func(chess_name):
						debug_handler.write_log("LOG", chess_name + "'s projectile has vanished.")
				)
				chess_projectile.projectile_hit.emit(handle_special_effect)

				await chess_projectile.projectile_vanished

			else:

				ranged_attack_animation.play("ranged_attack")
				ranged_attack_started.emit(self)

				handle_special_effect(chess_target, self)

		elif current_distance_to_target < ranged_attack_threshold or (has_melee_target() is Obstacle and current_distance_to_target >= ranged_attack_threshold and animated_sprite_2d.sprite_frames.has_animation("ranged_attack")):
			damage = melee_damage

			if current_distance_to_target >= ranged_attack_threshold:
				chess_target = has_melee_target()


			if animated_sprite_2d.sprite_frames.has_animation("melee_attack"):
				status = STATUS.MELEE_ATTACK
				melee_attack_animation.play("melee_attack")
				melee_attack_started.emit(self)

				handle_special_effect(chess_target, self)

			elif animated_sprite_2d.sprite_frames.has_animation("attack"):
				status = STATUS.MELEE_ATTACK
				animated_sprite_2d.play("attack")
				melee_attack_started.emit(self)
				chess_target.take_damage(damage, self)	

				handle_special_effect(chess_target, self)

			else:
				# No required attack animation
				status = STATUS.IDLE
				action_timer.set_wait_time(action_timer_wait_time)
				action_timer.start()
				
		else:
			# Long distance but no ranged attack animation
			status = STATUS.IDLE
			action_timer.set_wait_time(action_timer_wait_time)
			action_timer.start()

	else:
		# Out of attack range
		status = STATUS.IDLE
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()

	if remain_attack_count > 0:
		_handle_attack()
	else:
		status = STATUS.IDLE
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()

func _handle_action_timeout():
	#Placeholder for chess passive ability on action finish
	if not status == STATUS.DIE:
		status = STATUS.IDLE
	action_finished.emit(self)
	action_timer.stop()

# Handle target selection and tracking
func _handle_targeting():
	# Clear invalid targets (dead or invalid instances)
	attack_target_line.visible = false
	chess_target = _find_new_target(chess_target_choice)
	if chess_target:
		chess_target.is_died.connect(handle_target_death)
	attack_target_line.visible = true
		
# Find a new target based on selection strategy
func _find_new_target(tgt) -> Obstacle:
	#Placeholder for chess passive ability on find target
	var new_target
	# var all_chesses = get_tree().get_nodes_in_group("obstacle_group").filter(
	var all_chesses = arena.unit_grid.get_all_units()
	var enemy_chesses = all_chesses.filter(
		func(chess): return chess != self and chess.team != team
	)
	var ally_chesses = all_chesses.filter(
		func(chess): return chess != self and chess.team == team
	)
	
	# Select target based on strategy
	match tgt:
		TARGET_CHOICE.FAR:
			if enemy_chesses.size() > 0:
				enemy_chesses.sort_custom(func(a, b): return _compare_distance)
				new_target = enemy_chesses.front()  # Farthest enemy
		
		TARGET_CHOICE.CLOSE:
			if enemy_chesses.size() > 0:
				enemy_chesses.sort_custom(func(a, b): return _compare_distance)
				new_target = enemy_chesses.back() # Closest enemy
		
		TARGET_CHOICE.STRONG:
			if enemy_chesses.size() > 0:
				# Sort by max HP descending
				enemy_chesses.sort_custom(_compare_hp)
				new_target = enemy_chesses.front()  # Strongest enemy
		
		TARGET_CHOICE.WEAK:
			if enemy_chesses.size() > 0:
				# Sort by max HP ascending
				enemy_chesses.sort_custom(_compare_hp)
				new_target = enemy_chesses.back()  # Weakest enemy
		
		TARGET_CHOICE.ALLY:
			if ally_chesses.size() > 0:
				ally_chesses.sort_custom(_compare_hp)
				new_target = ally_chesses.front()  # Strongest ally

		TARGET_CHOICE.SELF:
			new_target = self
	
	if new_target:
		return new_target 
	else:
		return null  # No valid target found

func _compare_distance(a: Obstacle, b: Obstacle) -> bool:

	# handling taunt
	if (a.buffer_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range) and (not b.buffer_handler.is_taunt or b.global_position.distance_to(global_position) > taunt_range):
		return true
	if (not a.buffer_handler.is_taunt or a.global_position.distance_to(global_position) > taunt_range) and (b.buffer_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range):
		return false
		
	# handling stealth chess
	if a.buffer_handler.is_stealth and not b.buffer_handler.is_stealth:
		return false
	if not a.buffer_handler.is_stealth and b.buffer_handler.is_stealth:
		return true
	
	return a.global_position.distance_to(global_position) > b.global_position.distance_to(global_position)

func _compare_hp(a: Obstacle, b: Obstacle) -> bool:

	# handling taunt
	if (a.buffer_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range) and (not b.buffer_handler.is_taunt or b.global_position.distance_to(global_position) > taunt_range):
		return true
	if (not a.buffer_handler.is_taunt or a.global_position.distance_to(global_position) > taunt_range) and (b.buffer_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range):
		return false
		
	# handling stealth chess
	if a.buffer_handler.is_stealth and not b.buffer_handler.is_stealth:
		return false
	if not a.buffer_handler.is_stealth and b.buffer_handler.is_stealth:
		return true
	
	return a.max_hp > b.max_hp

func _compare_damage(a: Obstacle, b: Obstacle) -> bool:

	# handling taunt
	if (a.buffer_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range) and (not b.buffer_handler.is_taunt or b.global_position.distance_to(global_position) > taunt_range):
		return true
	if (not a.buffer_handler.is_taunt or a.global_position.distance_to(global_position) > taunt_range) and (b.buffer_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range):
		return false
		
	# handling stealth chess
	if a.buffer_handler.is_stealth and not b.buffer_handler.is_stealth:
		return false
	if not a.buffer_handler.is_stealth and b.buffer_handler.is_stealth:
		return true
	
	return a.damage > b.damage

# Handle idle timer timeout
func _on_idle_timeout():
	if status == STATUS.IDLE:
		animated_sprite_2d.play("idle")
		idle_timer.set_wait_time(rng.randf_range(1.0,5.0))


# Launch projectile at target
func _launch_projectile(target: Obstacle):
	
	# Calculate direction to target
	var direction = (target.global_position - global_position).normalized()
	
	# Determine if we need to flip the projectile sprite
	var is_flipped = direction.x < 0
	
	
	projectile = projectile_scene.instantiate()
	
	if not projectile:
		push_error("Projectile scene is not set!")
		return
		
	# Create projectile instance
	get_parent().add_child(projectile)
	
	
	# Set up projectile
	projectile.global_position = global_position
	projectile.direction = direction
	projectile.source_team = team
	projectile.initial_flip = is_flipped
	projectile.attacker = self
	
	projectile_damage = ranged_damage

	# Configure projectile properties
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.penetration = projectile_penetration
	projectile.is_active = true
	
	return projectile

# Add damage handling method
func take_damage(damage_value: int, attacker: Obstacle) -> bool:
	#Placeholder for chess passive ability on take damage
	if damage_value <= 0:
		return false

	if rng.randf() > evasion_rate and not effect_handler.is_immunity:
		var real_damage_value = damage_value - armor
		hp -= max(0, real_damage_value)
		hp_bar.value = hp
		if attacker != self:
			attacker.mp += real_damage_value
			damage_taken.emit(self, attacker, real_damage_value)

		if hp <= 0:
			status = STATUS.DIE
			animated_sprite_2d.stop()
			animated_sprite_2d.play("die")
			await animated_sprite_2d.animation_finished
			visible = false
			is_died.emit(self)
					
		else:
			#Placeholder for chess passive ability on hit
			status = STATUS.HIT
			animated_sprite_2d.play("hit")
			await animated_sprite_2d.animation_finished
			status = STATUS.IDLE

		return true

	else:
		attack_evased.emit(self, attacker)
		return false

func take_heal(heal_value: int, healer: Obstacle):
	#Placeholder for chess passive ability on take heal
	if heal_value <= 0:
		return

	hp += max(0, heal_value)

	if herler != self:
		healer.mp += heal_value
		heal_taken.emit(self, healer, heal_value)


func _cast_spell(spell_tgt: Obstacle) -> bool:
	#Placeholder for chess passive ability on cast spell
	var cast_spell_result := false

	if chess_name == "Mage" and faction == "human":
		cast_spell_result = human_mage_taunt(2)
	elif chess_name == "ArchMage" and faction == "human":
		cast_spell_result = human_archmage_heal(2, 20)
	elif chess_name == "Queen" and faction == "elf":
		cast_spell_result = elf_queen_stun(2, 5)
	elif chess_name == "Mage" and faction == "elf":
		cast_spell_result = elf_mage_damage(spell_tgt, 0.2, 10, 80)
	elif chess_name == "Necromancer" and faction == "undead":
		cast_spell_result = await undead_necromancer_summon("Skeleton", 3)
	elif chess_name == "Demolitionist" and faction == "dwarf":
		cast_spell_result = dwarf_demolitionist_placebomb(100)
	elif spell_tgt !=  self:
		cast_spell_result = true

	if cast_spell_result:
		spell_casted.emit(self, skill_name)
		mp = 0

	return cast_spell_result


func _apply_damage(damage_target: Obstacle = chess_target, damage_value: int = damage):
	if chess_target and damage_value > 0:
		#Placeholder for chess passive ability on apply damage
		var applied_damage_value
		var damage_result = false

		if rng.randf() <= critical_rate:
			applied_damage_value =  damage_value * 2
			if chess_target.take_damage(applied_damage_value, self) and chess_target != self:
				damage_applied.emit(self, damage_target, damage_target)	
		else:
			applied_damage_value = damage_value
			if damage_result = chess_target.take_damage(applied_damage_value, self) and chess_target != self:
				critical_damage_applied.emit(self, damage_target, damage_target)	
			

func _apply_heal(heal_target: Obstacle = chess_spell_target, heal_value: int = damage):
	if heal_target and heal_value > 0:
		#Placeholder for chess passive ability on apply heal
		heal_target.take_heal(heal_value, self)
		if heal_target != self:
			heal_applied.emit(self, heal_target, heal_value)
		
func snap(value: float, grid_size: int) -> int:
	return floor(value / grid_size)

func get_safe_path(start, target):
	var base_path = astar_grid.get_point_path(start, target)
	if not base_path.is_empty():
		return base_path
	var min_path_size = 999	
	var best_path = []
	# 渐进式扩大搜索范围
	for radius in range(1, MAX_SEARCH_RADIUS + 1):
		var candidates = get_points_in_radius(target, radius)
		for point in candidates:
			var test_path = astar_grid.get_point_path(start, point)
			
			if not test_path.is_empty():
				if test_path.size() < min_path_size:
					best_path = test_path.duplicate()
					min_path_size = test_path.size()
		if min_path_size != 999:
			return best_path
	return PackedVector2Array()  # 完全无法接近

func get_points_in_radius(target: Vector2i, radius: int) -> Array[Vector2i]:
	var points: Array[Vector2i] = []
	for x in range(target.x - radius, target.x + radius + 1):
		for y in range(target.y - radius, target.y + radius + 1):
			if Vector2i(x,y).distance_to(target) <= radius:
				points.append(Vector2i(x,y))
	return points
	
func _on_died():
	pass
	#Placeholder for chess passive ability on died

func update_solid_map():
		
	astar_grid.fill_solid_region(astar_grid_region, false)
	var block_array = [Rect2i(-1, -1, 1, 16), Rect2i(16, -1, 1, 16), Rect2i(-1, -1, 16, 1), Rect2i(-1, 16, 16, 1)]
	for rect_index in block_array:
		astar_grid.fill_solid_region(rect_index, true)
		
	astar_grid.update()

	# for node in get_tree().get_nodes_in_group("obstacle_group"):
	# 	if node.status != STATUS.DIE and current_play_area == play_areas.playarea_arena:
	# 		astar_grid.set_point_solid(node.position_id, true)

	for chess_index in arena.unit_grid.get_all_units():
		astar_grid.set_point_solid(get_current_tile(chess_index)[1], true)
	
	var test1
	
func _handle_dragging_state(stating_position: Vector2, drag_action: String):
	if !is_active:
		match drag_action:
			"started":
				status = STATUS.JUMP
				animated_sprite_2d.play("jump")
				return
			"dropped":
				status = STATUS.IDLE
			"canceled":
				status = STATUS.IDLE
			_:
				status = STATUS.IDLE
		animated_sprite_2d.play("idle")
		
func update_effect():
	
	effect_handler.turn_start_timeout_check()

	critical_rate = base_critical_rate + effect_handler.critical_rate_modifier
	evasion_rate = base_evasion_rate + effect_handler.evasion_rate_modifier

	if effect_handler.continuous_hp_modifier >= 0:
		_apply_heal(self, max(0, effect_handler.continuous_hp_modifier))
	else:
		_apply_damage(self, max(0, effect_handler.continuous_hp_modifier))

	mp += effect_handler.continuous_mp_modifier

	armor = base_armor + effect_handler.armor_modifier
	speed = base_speed + effect_handler.speed_modifier
	melee_damage = base_melee_damage + effect_handler.melee_attack_damage_modifier
	ranged_damage = base_ranged_damage + effect_handler.ranged_attack_damage_modifier
	attack_range = base_attack_range + effect_handler.attack_rng_modifier
	attack_speed = base_attack_speed + effect_handler.attack_speed_modifier

	max_hp = base_max_hp + effect_handler.max_hp_modifier
	max_mp = base_max_mp + effect_handler.max_mp_modifier
	
	return

func handle_projectile_hit(chess:Obstacle, attacker:Obstacle):
	#Placeholder for chess passive ability on projectile hit
	pass

func handle_target_death(chess: Obstacle):
	if status == STATUS.RANGED_ATTACK or status == STATUS.MELEE_ATTACK:
		chess_target = null
		attack_target_line.visible = false
		chess_target = _find_new_target(TARGET_CHOICE.CLOSE)
	else:
		chess_target = null
		attack_target_line.visible = false
		chess_target = _find_new_target(chess_target_choice)

	if chess_target:
		chess_target.is_died.connect(handle_target_death)
		attack_target_line.visible = true

func handle_spell_target_death():
	chess_spell_target = null
	spell_target_line.visible = false

func handle_special_effect(target: Obstacle, attacker: Obstacle):
	#Placeholder for chess passive ability on special attack effect
	pass

func connect_to_data_manager():
	# DataManagerSingleton.add_data_to_dict(DataManagerSingleton.in_game_data, ["XX"], value)
	attack_evased.connect(
		func(chess, attacker):
			if chess.team == 1:
				DataManagerSingleton.add_data_to_dict(DataManagerSingleton.in_game_data, ["chess_stat", chess.faction, chess.chess_name, "evase_attack_count"], 1)
	)

	critical_damage_applied.connect(
		func(chess, attacker):
			if chess.team == 1:
				DataManagerSingleton.add_data_to_dict(DataManagerSingleton.in_game_data, ["chess_stat", chess.faction, chess.chess_name, "critical_attack_count"], 1)
	)

	spell_casted.connect(
		func(chess, spell_name):
			if chess.team == 1:
				DataManagerSingleton.add_data_to_dict(DataManagerSingleton.in_game_data, ["chess_stat", chess.faction, chess.chess_name, "cast_spell_count"], 1)
	)

func get_current_tile(obstacle : Obstacle):
	var i = chess_mover._get_play_area_for_position(obstacle.global_position)
	var current_tile = chess_mover.play_areas[i].get_tile_from_global(obstacle.global_position)
	return [chess_mover.play_areas[i], current_tile]
	
func has_melee_target():
	for x_index in range(-1, 1):
		for y_index in range(-1, 1):
			if not arena.unit_grid.has_valid_chess(Vector2i(x_index, y_index)):
				continue
			var current_chess = arena.unit_grid.units[Vector2i(x_index, y_index)]
			if current_chess.team != team:
				return current_chess

	return null

func human_mage_taunt(spell_duration: int) -> bool:
	var chess_affected := true

	var effect_instance = ChessEffect.new()
	effect_instance.taunt_duration = spell_duration
	effect_instance.effect_name = "Taunt"
	effect_instance.effect_type = "Buff"
	effect_instance.effect_applier = "Human Mage Spell Taunt"
	effect_handler.add_to_effect_array(effect_instance)
	effect_handler.add_child(effect_instance)

	var arena_unitgrid = arena.unit_grid.units
	# var affected_index_array = area_effect_handler.find_affected_units(position_id, 0, area_effect_handler.human_mage_taunt_template)
	var affected_index_array = area_effect_handler.find_affected_units(get_current_tile(self)[1], 0, area_effect_handler.default_template)
	
	if affected_index_array.size() == 0:
		return false

	for affected_index in affected_index_array:
			if arena_unitgrid.has(affected_index) and is_instance_valid(arena_unitgrid[affected_index]):
				if arena_unitgrid[affected_index] is Obstacle and arena_unitgrid[affected_index].team != team:
					arena_unitgrid[affected_index].chess_target = self
					chess_affected = true
	return chess_affected

func human_archmage_heal(spell_duration: int, heal_value: int) -> bool:
	var chess_affected := true
	var arena_unitgrid = arena.unit_grid.units
	# var affected_index_array = area_effect_handler.find_affected_units(position_id, 0, area_effect_handler.human_archmage_heal_template)
	var affected_index_array = area_effect_handler.find_affected_units(get_current_tile(self)[1], 0, area_effect_handler.default_template)
	
	if affected_index_array.size() == 0:
		return false

	for affected_index in affected_index_array:
			if arena_unitgrid.has(affected_index) and is_instance_valid(arena_unitgrid[affected_index]):
				if arena_unitgrid[affected_index] is Obstacle and arena_unitgrid[affected_index].team == team:

					var effect_instance = ChessEffect.new()
					effect_instance.continuous_hp_modifier = heal_value
					effect_instance.continuous_hp_modifier_duration = spell_duration
					effect_instance.effect_name = "Heal"
					effect_instance.effect_type = "Buff"
					effect_instance.effect_applier = "Human ArchMage Spell Heal"
					arena_unitgrid[affected_index].effect_handler.add_to_effect_array(effect_instance)
					arena_unitgrid[affected_index].effect_handler.add_child(effect_instance)

					chess_affected =  true
	return chess_affected

func elf_queen_stun(spell_duration: int, damage_value: int) -> bool:
	var chess_affected := true
	var arena_unitgrid = arena.unit_grid.units
	# var affected_index_array = area_effect_handler.find_affected_units(position_id, 0, area_effect_handler.human_archmage_heal_template)
	var affected_index_array = area_effect_handler.find_affected_units(get_current_tile(self)[1], 0, area_effect_handler.default_template)

	if affected_index_array.size() == 0:
		return false

	for affected_index in affected_index_array:
		if arena_unitgrid.has(affected_index) and  is_instance_valid(arena_unitgrid[affected_index]):
			if arena_unitgrid[affected_index] is Obstacle and arena_unitgrid[affected_index].team != team:

				var effect_instance = ChessEffect.new()
				effect_instance.stunned_duration = spell_duration
				effect_instance.effect_name = "Stun"
				effect_instance.effect_type = "Debuff"
				effect_instance.effect_applier = "Elf Queen Spell Stun"
				arena_unitgrid[affected_index].effect_handler.add_to_effect_array(effect_instance)
				arena_unitgrid[affected_index].effect_handler.add_child(effect_instance)

				_apply_damage(arena_unitgrid[affected_index], damage_value)

				chess_affected =  true
	return chess_affected

func elf_mage_damage(spell_target:Obstacle, damage_threshold: float, min_damage_value: int, spell_range: int) -> bool:
	var chess_affected := false
	if spell_target.status != STATUS.DIE and spell_target.team != team and spell_target.global_position.distance_to(global_position) <= spell_range:

		if spell_target.hp <= spell_target.max_hp * damage_threshold:
			_apply_damage(spell_target, spell_target.hp)
			
		else:
			_apply_damage(spell_target, min_damage_value)

		chess_affected = true

	return chess_affected

func undead_necromancer_summon(summoned_chess_name: String, summon_unit_count: int) -> bool:
	var chess_affected := false
	var attempt_summon_count := 30
	var summoned_chess_count := 0
	if summoned_chess_name in chess_data["undead"].keys():
		while attempt_summon_count > 0 and summoned_chess_count < summon_unit_count:
			var current_tile = get_current_tile(self)[1]
			var rand_x = randi_range(current_tile.x - 2, current_tile.x + 2)
			var rand_y = randi_range(current_tile.y - 2, current_tile.y + 2)
			if rand_x >=0 and rand_x < arena.unit_grid.size.x and rand_y >=0 and rand_y < arena.unit_grid.size.y:
				attempt_summon_count -= 1
				if not arena.unit_grid.is_tile_occupied(Vector2(rand_x, rand_y)):
					
					var game_root_scene = arena.get_parent().get_parent()
					var summoned_character = game_root_scene.summon_chess("undead", summoned_chess_name, team, arena, Vector2i(rand_x, rand_y))

					if summoned_character.animated_sprite_2d.sprite_frames.has_animation("rise") :
						summoned_character.animated_sprite_2d.play("rise")
						await summoned_character.animated_sprite_2d.animation_finished
					else:
						summoned_character.animated_sprite_2d.play_backwards("die")
						await summoned_character.animated_sprite_2d.animation_finished

					summoned_chess_count += 1
					chess_affected = true
	return chess_affected

func dwarf_demolitionist_placebomb(spell_range: int) -> bool:
	# var chess_affected := false
	var attempt_summon_count := 10
	if chess_spell_target.status != STATUS.DIE and chess_spell_target.team != team and chess_spell_target.global_position.distance_to(global_position) <= spell_range:
		while attempt_summon_count >= 0:
			var current_tile = get_current_tile(self)[1]
			var target_current_tile = chess_spell_target.get_current_tile(self)[1]
			var rand_x = randi_range(target_current_tile.x - 1, target_current_tile.x + 1)
			var rand_y = randi_range(target_current_tile.y - 1, target_current_tile.y + 1)
			if rand_x >=0 and rand_x < arena.unit_grid.size.x and rand_y >=0 and rand_y < arena.unit_grid.size.y:
				attempt_summon_count -= 1
				if not arena.unit_grid.is_tile_occupied(Vector2(rand_x, rand_y)):
					var game_root_scene = arena.get_parent().get_parent()
					var summoned_character = game_root_scene.summon_chess("dwarf", "Bomb", team, arena, Vector2i(rand_x, rand_y))	
					summoned_character.obstacle_counter = 2
					summoned_character.obstacle_level = 1

					return true				
	return false	
