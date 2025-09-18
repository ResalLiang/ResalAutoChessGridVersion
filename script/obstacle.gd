# Chess character class with movement, dragging functionality and state management
class_name Obstacle
extends Node2D


# ========================
# Constants and Enums
# ========================
# Character states
enum STATUS {IDLE, MOVE, MELEE_ATTACK, RANGED_ATTACK, JUMP, HIT, DIE, SPELL}
enum play_areas {playarea_arena, playarea_bench, playarea_shop}

const MAX_SEARCH_RADIUS = 3
const projectile_scene = preload("res://scene/projectile.tscn")
const chess_scene = preload("res://scene/chess.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D
@onready var idle_timer: Timer = $idle_timer
@onready var drag_handler: Node2D = $drag_handler
@onready var move_timer: Timer = $move_timer
@onready var action_timer: Timer = $action_timer
@onready var debug_handler: DebugHandler = %debug_handler
@onready var area_effect_handler: AreaEffectHandler = $area_effect_handler
@onready var hp_bar: ProgressBar = $hp_bar
@onready var mp_bar: ProgressBar = $mp_bar
@onready var level_label: Label = $level_label


# ========================
# Exported Variables
# ========================
# Character faction with property observer
@export_enum("human", "dwarf", "elf", "forestProtector", "holy", "demon", "undead", "villager") var faction := "human"

# Chess name with property observer
@export var chess_name := "ShieldMan"
	#set(value):
		#chess_name = value
		## Load animation resource in editor mode
		#if ResourceLoader.exists("res://asset/animation/" + faction + "/" + faction + chess_name + ".tres"):
			#animated_sprite_2d.sprite_frames = ResourceLoader.load("res://asset/animation/" + faction + "/" + faction + chess_name + ".tres")
		#_load_chess_stats()

var chess_serial := 1001

#============================================
# Basic attack statics
#============================================
var is_obstacle := true
var obstacle_counter := 1
var obstacle_level := 1

var chess_level := 1

var base_max_hp := 100.0  # Maximum health points
var base_max_mp := 50.0   # Maximum magic points
var base_speed := 0
var base_armor := 0

var hp: float = base_max_hp:
	set(value):
		hp = min(value, max_hp)
		hp = max(0, hp)
var mp: float = 0:
	set(value):
		mp = min(value, max_mp)
		mp = max(0, mp)

var max_hp = base_max_hp:
	set(value):
		var update_hp = value * (1.0 * hp / max_hp)
		max_hp = value
		hp = update_hp
var max_mp = base_max_mp:
	set(value):
		var update_mp = value * (1.0 * mp / max_mp)
		max_mp = value
		mp = update_mp

var armor := 0

var chess_data: Dictionary  # Stores chess stats loaded from JSON

var effect_handler = EffectHandler.new()

@export var team: int      # 0 for player, 1~7 for AI enemy

#============================================
# Play Area Related
#============================================
var arena: PlayArea
var bench: PlayArea
var shop: PlayArea

var current_play_area = play_areas.playarea_arena

#============================================
# Movement Related
#============================================
# var position_id := Vector2i.ZERO
# var _position := Vector2.ZERO:
# 	set(value):
# 		_position = value
# 		position = _position
# 		position_id = Vector2i(
# 			snap(value.x, 16),
# 			snap(value.y, 16)
# 		)
var chess_mover
var is_active: bool = false
var grid_offset =Vector2(8, 8)

var dragging_enabled: bool = true # Enable/disable dragging

#============================================
#Appreance Related
#============================================
var sprite_frames: SpriteFrames  # Custom sprite frames
var action_timer_wait_time := 1
var move_timer_wait_time := 0.5
#============================================
# Skill or Spell Related
#============================================
var skill_name := "Place holder."
var skill_description := "Place holder."

var taunt_range := 70

# Projectile Related
var projectile_speed: float = 300.0  # Projectile speed
var projectile_damage: int = 15  # Projectile damage
var projectile_penetration: int = 3  # Number of enemies projectile can penetrate
var ranged_attack_threshold: float = 32.0  # Minimum distance for ranged attack
var projectile


var status := STATUS.IDLE         # Current character state

var rng = RandomNumberGenerator.new() # Random number generator

#============================================
# Signals
#============================================

signal stats_loaded(obstacle: Obstacle)
signal animated_sprite_loaded(obstacle: Obstacle)

signal target_found(obstacle: Obstacle, target: Obstacle)
signal target_lost(obstacle: Obstacle)

signal move_started(obstacle: Obstacle, current_position: Vector2i) # for audio player
signal move_finished(obstacle: Obstacle, current_position: Vector2i) # for audio player
signal action_started(obstacle: Obstacle)
signal action_finished(obstacle: Obstacle)

signal spell_casted(obstacle: Obstacle, spell_name: String) # for audio player
signal ranged_attack_started(obstacle: Obstacle) # for audio player
signal ranged_attack_finished(obstacle: Obstacle)
signal melee_attack_started(obstacle: Obstacle) # for audio player
signal melee_attack_finished(obstacle: Obstacle)
signal projectile_lauched(obstacle: Obstacle) # for audio player

signal damage_applied(obstacle: Obstacle, attack_target: Obstacle, damage_value: float)
signal critical_damage_applied(obstacle: Obstacle, attack_target: Obstacle, damage_value: float)
signal heal_applied(obstacle: Obstacle, heal_target: Obstacle, heal_value: float)

signal damage_taken(obstacle: Obstacle, attacker: Obstacle, damage_value: float) # for audio player and display
signal critical_damage_taken(obstacle: Obstacle, attacker: Obstacle, damage_value: float) # for audio player and display
signal heal_taken(obstacle: Obstacle, healer: Obstacle, heal_value: float) # for audio player and display
signal attack_evased(obstacle: Obstacle, attacker: Obstacle) # for audio player and display

signal is_died(obstacle: Obstacle) # for audio player and display

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
	#animated_sprite_2d.play("idle")
	
	if team == 2:
		animated_sprite_2d.flip_h = true
		
	# Add to chess group for targeting
	add_to_group("obstacle_group")
	
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
	
	
	if not animated_sprite_2d.sprite_frames.has_animation("spell") :
		mp_bar.visible = false
		
	area_effect_handler.arena = arena

# ========================
# Process Functions
# ========================

func _process(delta: float) -> void:
	
	hp_bar.value = hp
	mp_bar.value = mp

	hp_bar.max_value = max_hp
	mp_bar.max_value = max_mp

	hp_bar.visible = true #hp != max_hp
		
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
		skill_name = stats["skill_name"]
		skill_description = stats["skill_description"]
		stats_loaded.emit(self, stats)
	else:
		push_error("Stats not found for %s/%s" % [faction, chess_name])

func start_turn():
	
	#Placeholder for chess passive ability on start turn
	if status == STATUS.DIE:
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()
		return

	#update_solid_map()
	#await get_tree().process_frame

	update_effect()

	_handle_action()

						
func _handle_action():
	
	if status == STATUS.DIE:
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()
		return

	action_started.emit(self)

	handle_obstacle_action()
	status = STATUS.IDLE
	action_timer.set_wait_time(action_timer_wait_time)
	action_timer.start()

func _handle_action_timeout():
	#Placeholder for chess passive ability on action finish
	status = STATUS.IDLE
	action_finished.emit(self)
	action_timer.stop()

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
	
	projectile_damage = 20

	# Configure projectile properties
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.penetration = projectile_penetration
	projectile.is_active = true
	
	
	return projectile

# Add damage handling method
func take_damage(damage_value: float, attacker: Obstacle) -> bool:
	#Placeholder for chess passive ability on take damage
	if damage_value <= 0:
		return false

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


func take_heal(heal_value: float, healer: Obstacle):
	#Placeholder for chess passive ability on take heal
	if heal_value <= 0:
		return

	hp += max(0, heal_value)

	if healer != self:
		healer.mp += heal_value
		heal_taken.emit(self, healer, heal_value)

func _apply_damage(damage_target: Obstacle, damage_value: float):
	if damage_target and damage_value > 0:
		#Placeholder for chess passive ability on apply damage
		var applied_damage_value
		var damage_result = false


		applied_damage_value = damage_value
		if await damage_target.take_damage(applied_damage_value, self) and damage_target != self:
			critical_damage_applied.emit(self, damage_target, damage_target)	
			

func _apply_heal(heal_target: Obstacle, heal_value: float):
	if heal_target and heal_value > 0:
		#Placeholder for chess passive ability on apply heal
		heal_target.take_heal(heal_value, self)
		if heal_target != self:
			heal_applied.emit(self, heal_target, heal_value)

		
func snap(value: float, grid_size: int) -> int:
	return floor(value / grid_size)
	
func _on_died():
	#Placeholder for chess passive ability on died
	pass

func _handle_dragging_state(stating_position: Vector2, drag_action: String):
	if !is_active:
		match drag_action:
			"started":
				status = STATUS.IDLE
			"dropped":
				status = STATUS.IDLE
			"canceled":
				status = STATUS.IDLE
			_:
				status = STATUS.IDLE
		animated_sprite_2d.play("idle")
		
func update_effect():
	
	effect_handler.turn_start_timeout_check()

	if effect_handler.continuous_hp_modifier >= 0:
		_apply_heal(self, max(0, effect_handler.continuous_hp_modifier))
	else:
		_apply_damage(self, max(0, effect_handler.continuous_hp_modifier))

	mp += effect_handler.continuous_mp_modifier

	armor = base_armor + effect_handler.armor_modifier

	max_hp = base_max_hp + effect_handler.max_hp_modifier
	max_mp = base_max_mp + effect_handler.max_mp_modifier

func handle_projectile_hit(chess:Obstacle, attacker:Obstacle):
	#Placeholder for chess passive ability on projectile hit
	pass

func handle_obstacle_action() -> void:
	if obstacle_counter <= 0:
		if chess_name == "Bomb" and faction == "dwarf":
			dwarf_bomb_boom()
	else:
		obstacle_counter -= 1

func get_current_tile(obstacle : Obstacle):
	var i = chess_mover._get_play_area_for_position(obstacle.global_position)
	var current_tile = chess_mover.play_areas[i].get_tile_from_global(obstacle.global_position)
	return [chess_mover.play_areas[i], current_tile]
	
func dwarf_bomb_boom():
	for x in range(-obstacle_level, obstacle_level):
		for y in range(-obstacle_level, obstacle_level):
			if x >=0 and x < arena.unit_grid.size.x and y >=0 and y < arena.unit_grid.size.y:
				var target_area_chess = arena.unit_grid.units[get_current_tile(self)[1] + Vector2i(x, y)]
				if is_instance_valid(target_area_chess) and target_area_chess is Obstacle and target_area_chess.status != STATUS.DIE:
					_apply_damage(target_area_chess, 50 * obstacle_level)
	is_died.emit(self)		
	action_finished.emit(self)
