# Hero character class with movement, dragging functionality and state management
class_name Hero
extends Node2D


# ========================
# Constants and Enums
# ========================
# Character states
enum STATUS {IDLE, MOVE, MELEE_ATTACK, RANGED_ATTACK, JUMP, HIT, DIE, SPELL}
enum TARGET_CHOICE {CLOSE, FAR, STRONG, WEAK, ALLY, SELF}

const MAX_SEARCH_RADIUS = 3
const projectile_scene = preload("res://scene/projectile.tscn")
# ========================
# Exported Variables
# ========================
# Character faction with property observer
@export_enum("human", "dwarf", "elf", "forestProtector", "holy", "demon", "undead", "villager") var faction := "human":
	set(value):
		faction = value

# Hero name with property observer
@export var hero_name := "ShieldMan":
	set(value):
		hero_name = value
		if not Engine.is_editor_hint():
			return
		# Load animation resource in editor mode
		if ResourceLoader.exists("res://asset/animation/" + faction + "/" + faction + hero_name + ".tres"):
			animated_sprite_2d.sprite_frames = ResourceLoader.load("res://asset/animation/" + faction + "/" + faction + hero_name + ".tres")
		_load_hero_stats()

var base_max_hp := 100  # Maximum health points
var base_max_mp := 50   # Maximum magic points
var base_spd := 8      # Movement speed (pixels/second)
var base_damage := 20   # Attack damage
var base_attack_spd := 1 # Attack speed (attacks per second)
var base_attack_range := 20 # Attack range (pixels)
@export var team: int      # 0 for player, 1~7 for AI enemy
@export var dragging_enabled: bool = true # Enable/disable dragging
var sprite_frames: SpriteFrames  # Custom sprite frames
@export var line_visible:= false

var arena: PlayArea
var bench: PlayArea
var shop: PlayArea

var evasion_rate := 0.10
var critical_rate := 0.10

var base_evasion_rate := 0.10
var base_critical_rate := 0.10

var armor := 0
var base_armor := 0

var spd = base_spd
var max_hp = base_max_hp
var max_mp = base_max_mp
var damage = base_damage
var attack_spd = base_attack_spd
var attack_range = base_attack_range
var remain_attack_count

var taunt_range := 70

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var melee_attack_animation: AnimationPlayer = $melee_attack_animation
@onready var ranged_attack_animation: AnimationPlayer = $ranged_attack_animation


# ========================
# Node References
# ========================
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D
@onready var idle_timer: Timer = $idle_timer
@onready var attack_target_line: Line2D = $attack_target_line  # Attack range indicator
@onready var spell_target_line: Line2D = $spell_target_line  # Spell range indicator
@onready var drag_handler: Node2D = $drag_handler
@onready var move_timer: Timer = $move_timer
@onready var action_timer: Timer = $action_timer

@onready var debug_handler: DebugHandler = %debug_handler

@onready var area_effect_handler: AreaEffectHandler = $area_effect_handler
# ========================
# Member Variables
# ========================
var hp: int                # Current health points
var mp: int                # Current magic points
var hero_target_choice := TARGET_CHOICE.CLOSE  # Target selection strategy
var hero_target: Hero  # Current attack target
var hero_spell_target_choice := TARGET_CHOICE.CLOSE  # Target selection strategy
var hero_spell_target: Hero # Current spell target
var status := STATUS.IDLE         # Current character state

var skill_name := "Place holder."
var skill_description := "Place holder."


var hero_data: Dictionary  # Stores hero stats loaded from JSON
var rng = RandomNumberGenerator.new() # Random number generator

#Astar navigation related
var move_path: PackedVector2Array
var position_id := Vector2i.ZERO
var _position := Vector2.ZERO:
	set(value):
		_position = value
		position = _position
		position_id = Vector2i(
			snap(value.x, 16),
			snap(value.y, 16)
		)
var astar_grid
var position_tween

var is_active: bool = false
var grid_offset =Vector2(8, 8)
var remain_step:= 0

var astar_grid_region = Rect2i(0, 0, 16, 16)
# ========================
# Signal Definitions
# ========================

signal attack_landed(target: Hero, damage: int)  # Emitted when attack hits target
signal is_died                                      # Emitted when die
signal turn_finished

signal move_started
signal move_finished
signal action_started
signal action_finished

signal damage_taken
signal heal_taken

signal is_hit
signal spell_casted
signal ranged_attack_started
signal melee_attack_started
signal ranged_attack_finished
signal melee_attack_finished

signal critical_damage_applied
signal damage_applied
signal heal_applied
signal attack_evased #attack_evased.emit(self, attacker.hero_name)
signal projectile_lauched

signal animated_sprite_loaded
signal stats_loaded
signal target_lost	#target_lost.emit(self)
signal target_found	#target_found.emit(self, hero_target.hero_name)
signal tween_moving	#tween_moving.emit(self, _position, target_pos)

# ========================
# Projectile Properties
# ========================
var projectile_speed: float = 300.0  # Projectile speed
var projectile_damage: int = 15  # Projectile damage
var projectile_penetration: int = 3  # Number of enemies projectile can penetrate
var ranged_attack_threshold: float = 32.0  # Minimum distance for ranged attack
var projectile

@export var melee_range: float = 16.0  # Melee attack range
@onready var hp_bar: ProgressBar = $hp_bar
@onready var mp_bar: ProgressBar = $mp_bar

var buff_handler = Buff_handler.new()
var debuff_handler = Debuff_handler.new()

enum play_areas {playarea_arena, playarea_bench, playarea_shop}
var current_play_area = play_areas.playarea_arena

# ========================
# Initialization
# ========================
func _ready():
		
	drag_handler.dragging_enabled = dragging_enabled
	

	# Load animations
	_load_animations()

	# Validate node references before proceeding
	if not _validate_node_references():
		push_error("Hero node setup is invalid!")
		return
	
	
	# Connect signals
	idle_timer.timeout.connect(_on_idle_timeout)
	move_timer.timeout.connect(_handle_action)
	action_timer.timeout.connect(_handle_action_timeout)
	
	drag_handler.drag_started.connect(_handle_dragging_state)
	drag_handler.drag_canceled.connect(_handle_dragging_state)
	drag_handler.drag_dropped.connect(_handle_dragging_state)

	
	damage_taken.connect(_on_damage_taken)

	is_died.connect(_on_died)
	
	# Initialize random number generator
	rng.randomize()
	idle_timer.set_wait_time(rng.randf_range(1.0,3.0))
	idle_timer.start()  # Start idle state timer
	
	# Play idle animation
	#animated_sprite_2d.play("idle")
	
	if team == 2:
		animated_sprite_2d.flip_h = true
		
	# Add to hero group for targeting
	add_to_group("hero_group")
	
	# Configure attack indicator line
	attack_target_line.width = 0.5
	if hero_target_choice == TARGET_CHOICE.ALLY:
		attack_target_line.default_color = Color(0, 1, 0)
	else:
		attack_target_line.default_color = Color(1, 0, 0)
	attack_target_line.visible = true
	
	# Configure attack indicator line
	spell_target_line.width = 0.5
	spell_target_line.default_color = Color(0, 0, 1)
	spell_target_line.visible = false
	
	# Load hero stats from JSON
	_load_hero_stats()
	
	# Initialize character properties
	hp = max_hp
	mp = 0

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
# ========================
# Process Functions
# ========================
func _process(delta: float) -> void:
	
	# Skip processing in editor mode
	if Engine.is_editor_hint():
		return

	hp_bar.value = hp
	mp_bar.value = mp

	hp_bar.visible = hp != max_hp
		
	# Update attack indicator line
	if hero_target and line_visible:
		attack_target_line.points = [Vector2.ZERO, to_local(hero_target.global_position)]
		attack_target_line.visible = true
		
	# Update attack indicator line
	if hero_spell_target and line_visible:
		spell_target_line.points = [Vector2.ZERO, to_local(hero_spell_target.global_position)]
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

	if status == STATUS.HIT:			
		if is_active:
			new_material.set_shader_parameter("outline_color", Color(1, 0, 0, 1))
		else:
			new_material.set_shader_parameter("outline_color", Color(1, 0, 0, 0.33))

	animated_sprite_2d.material = new_material

	if is_active:
		drag_handler.dragging_enabled = false
	else:
		drag_handler.dragging_enabled = dragging_enabled
		
	if hero_target:
		if (hero_target.position_id - position_id)[0] >= 0:
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

# Load appropriate animations for the hero
func _load_animations():
	var path = "res://asset/animation/%s/%s%s.tres" % [faction, faction, hero_name]
	if ResourceLoader.exists(path):
		var frames = ResourceLoader.load(path)
		for anim_name in frames.get_animation_names():
			# 根据需求设置不同循环条件
			if anim_name == "move" or anim_name == "jump":
				frames.set_animation_loop(anim_name, true)
			else:
				frames.set_animation_loop(anim_name, false)
			frames.set_animation_speed(anim_name, 8.0)
			animated_sprite_loaded.emit(self, anim_name)
		animated_sprite_2d.sprite_frames = frames
	else:
		push_error("Animation resource not found: " + path)

# Load hero stats from JSON file
func _load_hero_stats():
	var file = FileAccess.open("res://script/hero_stats.json", FileAccess.READ)
	if not file:
		push_error("Failed to open hero_stats.json")
		return
	
	var json_text = file.get_as_text()
	hero_data = JSON.parse_string(json_text)
	
	if not hero_data:
		push_error("JSON parsing failed for hero_stats.json")
		return
	
	# Safely retrieve stats if available
	if hero_data.has(faction) and hero_data[faction].has(hero_name):
		var stats = hero_data[faction][hero_name]
		base_spd = stats.get("spd", base_spd)
		base_max_hp = stats.get("hp", base_max_hp)
		base_attack_range = stats.get("attack_range", base_attack_range)
		base_attack_spd = stats.get("attack_speed", base_attack_spd)
		skill_name = stats.get("skill_name", skill_name)
		skill_description = stats.get("skill_description", skill_description)
		stats_loaded.emit(self, stats)
	else:
		push_error("Stats not found for %s/%s" % [faction, hero_name])

func start_turn():
	if status == STATUS.DIE:
		visible = false
		action_timer.start()
		return

	update_solid_map()
	await get_tree().process_frame

	update_buff_debuff()

	remain_attack_count = attack_spd

	if not hero_target or hero_target.status == STATUS.DIE:
		target_lost.emit(self)
		_handle_targeting()
		
	if hero_target and hero_target.status != STATUS.DIE:
		target_found.emit(self, hero_target)
		_handle_movement()
	else:
		action_timer.start()

func _handle_movement():

	move_started.emit(self, position_id)

	animated_sprite_2d.play("move")

	if global_position.distance_to(hero_target.global_position) <= attack_range or debuff_handler.is_stunned:
		move_finished.emit(self, position_id)
		move_timer.start()
	else:
		astar_grid.set_point_solid(position_id, false)
		#astar_grid.set_point_solid(hero_target.position_id, false)
		var solid_sum = 0
		for y in range(-8, 8, 1):
			for x in range(-8, 8, 1):
				var solid_result = 1 if astar_grid.is_point_solid(Vector2i(x, y)) else 0
				solid_sum += solid_result
		await get_tree().process_frame
		await get_tree().process_frame
		await get_tree().process_frame
		move_path = astar_grid.get_point_path(position_id, hero_target.position_id)
			
		if move_path.is_empty():
			move_path = get_safe_path(position_id, hero_target.position_id)
		if move_path.is_empty():
			astar_grid.set_point_solid(hero_target.position_id, true)
			move_finished.emit(self, position_id)
			move_timer.start()
		else:
			var move_steps = min(spd, move_path.size() - 1)
			if position_tween:
				position_tween.kill() # Abort the previous animation.
			position_tween = create_tween()
			position_tween.connect("finished", _on_move_completed)
			remain_step = move_steps
			for current_step in range(move_steps):
				var target_pos = move_path[current_step + 1] + grid_offset
				if !astar_grid.is_point_solid(target_pos):
					position_tween.tween_property(self, "_position", target_pos, 0.1)
					tween_moving.emit(self, _position, target_pos)
					remain_step -= 1

func _on_move_completed():
	remain_step -= 1
	if remain_step <= 0 or global_position.distance_to(hero_target.global_position) <= attack_range:
		position_tween.pause()
		position_tween.kill()
		astar_grid.set_point_solid(position_id, true)
		astar_grid.set_point_solid(hero_target.position_id, true)
		move_finished.emit(self, _position)
		move_timer.start()
						
func _handle_action():
	move_timer.stop()
	action_started.emit(self)
	astar_grid.set_point_solid(position_id, true)

	if mp >= max_mp and animated_sprite_2d.sprite_frames.has_animation("spell") and (!debuff_handler.is_silenced or !debuff_handler.is_stunned):
		if hero_spell_target_choice == TARGET_CHOICE.SELF:
			status = STATUS.SPELL
			animated_sprite_2d.play("spell")
			_cast_spell(self)
			return
		if !hero_spell_target:
			hero_spell_target = _find_new_target(hero_spell_target_choice)
		if hero_spell_target:
			status = STATUS.SPELL
			animated_sprite_2d.play("spell")
			_cast_spell(hero_spell_target)
			return

	if !hero_target or !is_instance_valid(hero_target):
		target_lost.emit(self)
		action_timer.start()
		return
	else:
		_handle_attack()

func _handle_attack():
	var current_distance_to_target = global_position.distance_to(hero_target.global_position)
	remain_attack_count -= 1
	if current_distance_to_target <= attack_range and (!debuff_handler.is_stunned or !debuff_handler.is_disarmed):
		if current_distance_to_target >= ranged_attack_threshold and animated_sprite_2d.sprite_frames.has_animation("ranged_attack"):
			status = STATUS.RANGED_ATTACK
			if ResourceLoader.exists("res://asset/animation/%s/%s%s_projectile.tres" % [faction, faction, hero_name]):
				animated_sprite_2d.play("ranged_attack")
				ranged_attack_started.emit(self)
				var hero_projectile = _launch_projectile(hero_target)
				projectile_lauched.emit(self)
				hero_projectile.projectile_vanished.connect(_on_animated_sprite_2d_animation_finished)
				hero_projectile.projectile_vanished.connect(
					func(hero_name):
						debug_handler.write_log("LOG", hero_name + "'s projectile has vanished.")
				)
				return
			elif animated_sprite_2d.sprite_frames.has_animation("ranged_attack"):
				ranged_attack_animation.play("ranged_attack")
				ranged_attack_started.emit(self)
				return
			action_timer.start()
			return
		elif current_distance_to_target < ranged_attack_threshold:
			if animated_sprite_2d.sprite_frames.has_animation("melee_attack"):
				status = STATUS.MELEE_ATTACK
				melee_attack_animation.play("melee_attack")
				melee_attack_started.emit(self)
				return
			elif animated_sprite_2d.sprite_frames.has_animation("attack"):
				status = STATUS.MELEE_ATTACK
				animated_sprite_2d.play("attack")
				melee_attack_started.emit(self)
				hero_target.take_damage(damage, self)	
				return
			action_timer.start()
			return
		else:
			status = STATUS.IDLE
			action_timer.start()
	else:
		status = STATUS.IDLE
		action_timer.start()

func _handle_action_timeout():
	# animated_sprite_2d.play("idle")
	status = STATUS.IDLE
	action_finished.emit(self)
	action_timer.stop()

# Handle target selection and tracking
func _handle_targeting():
	# Clear invalid targets (dead or invalid instances)
	if !hero_target or hero_target.status == STATUS.DIE:
		attack_target_line.visible = false
		hero_target = _find_new_target(hero_target_choice)
		
# Find a new target based on selection strategy
func _find_new_target(tgt) -> Hero:
	var new_target
	var all_heroes = get_tree().get_nodes_in_group("hero_group").filter(
		func(node): 
			return (node is Hero and 
				   node.status != STATUS.DIE and 
				   node.current_play_area == play_areas.playarea_arena)
	)

	var enemy_heroes = all_heroes.filter(
		func(hero): return hero != self and hero.team != team
	)
	var ally_heroes = all_heroes.filter(
		func(hero): return hero != self and hero.team == team
	)
	
	# Select target based on strategy
	match tgt:
		TARGET_CHOICE.FAR:
			if enemy_heroes.size() > 0:
				enemy_heroes.sort_custom(func(a, b): return _compare_distance)
				new_target = enemy_heroes.front()  # Farthest enemy
		
		TARGET_CHOICE.CLOSE:
			if enemy_heroes.size() > 0:
				enemy_heroes.sort_custom(func(a, b): return _compare_distance)
				new_target = enemy_heroes.back() # Closest enemy
		
		TARGET_CHOICE.STRONG:
			if enemy_heroes.size() > 0:
				# Sort by max HP descending
				enemy_heroes.sort_custom(_compare_hp)
				new_target = enemy_heroes.front()  # Strongest enemy
		
		TARGET_CHOICE.WEAK:
			if enemy_heroes.size() > 0:
				# Sort by max HP ascending
				enemy_heroes.sort_custom(_compare_hp)
				new_target = enemy_heroes.back()  # Weakest enemy
		
		TARGET_CHOICE.ALLY:
			if ally_heroes.size() > 0:
				ally_heroes.sort_custom(_compare_hp)
				new_target = ally_heroes.front()  # Strongest ally
	
	if new_target:
		return new_target 
	else:
		return null  # No valid target found

func _compare_distance(a: Hero, b: Hero) -> bool:

	# handling taunt
	if (a.buffer_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range) and (not b.buffer_handler.is_taunt or b.global_position.distance_to(global_position) > taunt_range):
		return true
	if (not a.buffer_handler.is_taunt or a.global_position.distance_to(global_position) > taunt_range) and (b.buffer_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range):
		return false
		
	# handling stealth hero
	if a.buffer_handler.is_stealth and not b.buffer_handler.is_stealth:
		return false
	if not a.buffer_handler.is_stealth and b.buffer_handler.is_stealth:
		return true
	
	return a.global_position.distance_to(global_position) > b.global_position.distance_to(global_position)

func _compare_hp(a: Hero, b: Hero) -> bool:

	# handling taunt
	if (a.buffer_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range) and (not b.buffer_handler.is_taunt or b.global_position.distance_to(global_position) > taunt_range):
		return true
	if (not a.buffer_handler.is_taunt or a.global_position.distance_to(global_position) > taunt_range) and (b.buffer_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range):
		return false
		
	# handling stealth hero
	if a.buffer_handler.is_stealth and not b.buffer_handler.is_stealth:
		return false
	if not a.buffer_handler.is_stealth and b.buffer_handler.is_stealth:
		return true
	
	return a.max_hp > b.max_hp

func _compare_damage(a: Hero, b: Hero) -> bool:

	# handling taunt
	if (a.buffer_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range) and (not b.buffer_handler.is_taunt or b.global_position.distance_to(global_position) > taunt_range):
		return true
	if (not a.buffer_handler.is_taunt or a.global_position.distance_to(global_position) > taunt_range) and (b.buffer_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range):
		return false
		
	# handling stealth hero
	if a.buffer_handler.is_stealth and not b.buffer_handler.is_stealth:
		return false
	if not a.buffer_handler.is_stealth and b.buffer_handler.is_stealth:
		return true
	
	return a.damage > b.damage

# Handle idle timer timeout
func _on_idle_timeout():
	if status == STATUS.IDLE:
		animated_sprite_2d.play("idle")


# Launch projectile at target
func _launch_projectile(target: Hero):
	
	
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
	

	projectile_damage = damage

	# Configure projectile properties
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.penetration = projectile_penetration
	projectile.is_active = true
	
	
	return projectile

# Add damage handling method
func take_damage(damage_value: int, attacker: Hero):
	if rng.randf() > evasion_rate or !buff_handler.is_immunity:
		var real_damage_value = damage_value - armor
		hp -= max(0, real_damage_value)
		attacker.mp += real_damage_value
		damage_taken.emit(self, real_damage_value, attacker)
	else:
		attack_evased.emit(self, attacker)


func take_heal(heal_value: int, healer: Hero):
		hp += max(0, heal_value)
		healer.mp += heal_value
		heal_taken.emit(self, heal_value, healer)


func _cast_spell(spell_tgt: Hero) -> bool:
	var cast_spell_result := false

	if hero_name == "Mage" and faction == "human":
		cast_spell_result = human_mage_taunt(2)
	elif hero_name == "ArchMage" and faction == "human":
		cast_spell_result = human_archmage_heal(2, 20)
	elif hero_name == "Queen" and faction == "elf":
		cast_spell_result = elf_queen_stun(2, 5)
	elif hero_name == "Mage" and faction == "elf":
		cast_spell_result = elf_mage_damage(spell_tgt, 0.2, 10, 80)
	elif spell_tgt !=  self:
		cast_spell_result = true

	if cast_spell_result:
		spell_casted.emit(self, skill_name)
		mp = 0

	return cast_spell_result


func _apply_damage(damage_target: Hero = hero_target, damage_value: int = damage):
	if hero_target:
		if rng.randf() <= critical_rate:
			var real_damage_value =  damage * 2
			hero_target.take_damage(real_damage_value, self)
			critical_damage_applied.emit(self, damage_target)
		else:
			var real_damage_value =  damage
			hero_target.take_damage(real_damage_value, self)
			damage_applied.emit(self, damage_target)		

func _apply_heal(heal_target: Hero = hero_spell_target, heal_value: int = damage):
	if heal_target:
		heal_target.take_heal(heal_value, self)
		heal_applied.emit(self, heal_value, heal_target)
		
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

func _on_damage_taken(taker: Hero, damage_value: int, attacker: Hero):
	if hp <= 0:
		status = STATUS.DIE
		animated_sprite_2d.stop()
		animated_sprite_2d.play("die")
		return
	else:
		status = STATUS.HIT
		animated_sprite_2d.play("hit")
	
func _on_died():
	self.visible = false

func update_solid_map():

	astar_grid.fill_solid_region(astar_grid_region, false)
	astar_grid.update()

	for node in get_tree().get_nodes_in_group("hero_group"):
		if node.status != STATUS.DIE and current_play_area == play_areas.playarea_arena:
			astar_grid.set_point_solid(node.position_id, true)

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
		# action_timer.start()
		
func update_buff_debuff():
	
	buff_handler.start_turn_update()
	debuff_handler.start_turn_update()

	critical_rate = base_critical_rate + max(0, buff_handler.critical_rate_modifier) + min(0, debuff_handler.critical_rate_modifier)
	evasion_rate = base_evasion_rate + max(0, buff_handler.evasion_rate_modifier) + min(0, debuff_handler.evasion_rate_modifier)

	_apply_heal(self, max(0, buff_handler.continuous_hp_modifier))
	_apply_damage(self, max(0, debuff_handler.continuous_hp_modifier))

	mp += max(0, buff_handler.continuous_hp_modifier) - max(0, debuff_handler.continuous_hp_modifier)
	mp = max(0, mp)

	armor = base_armor + max(0, buff_handler.armor_modifier) - max(0, debuff_handler.armor_modifier)
	spd = base_spd + max(0, buff_handler.spd_modifier) - max(0, debuff_handler.spd_modifier)
	damage = base_damage + max(0, buff_handler.attack_dmg_modifier) - max(0, debuff_handler.attack_dmg_modifier)
	attack_range = base_attack_range + max(0, buff_handler.attack_rng_modifier) - max(0, debuff_handler.attack_rng_modifier)
	attack_spd = base_attack_spd + max(0, buff_handler.attack_spd_modifier) - max(0, debuff_handler.attack_spd_modifier)

	max_hp = base_max_hp + max(0, buff_handler.max_hp_modifier) - max(0, debuff_handler.max_hp_modifier)
	hp = min(hp, max_hp)
	
	return

func _on_animated_sprite_2d_animation_finished() -> void:
	if status == STATUS.DIE:
		
		is_died.emit(self)
		arena.unit_grid.remove_unit(position_id)

		await get_tree().process_frame

		queue_free()

	elif status == STATUS.HIT:
		is_hit.emit(self)
		status = STATUS.IDLE

	elif status == STATUS.SPELL:
		action_timer.start()
		
	elif status == STATUS.RANGED_ATTACK:
		if remain_attack_count <= 0:
			#if ResourceLoader.exists("res://asset/animation/%s/%s%s_projectile.tres" % [faction, faction, hero_name]):
				#pass
			#else:
			action_timer.start()
			ranged_attack_finished.emit(self)
		elif hero_target and hero_target.status != STATUS.DIE:
			_handle_attack()
		else:
			hero_target = _find_new_target(TARGET_CHOICE.CLOSE)
			_handle_attack()

	elif status == STATUS.MELEE_ATTACK:
		if remain_attack_count <= 0:
			melee_attack_finished.emit(self)
			action_timer.start()
		elif hero_target and hero_target.status != STATUS.DIE:
			_handle_attack()
		else:
			hero_target = _find_new_target(TARGET_CHOICE.CLOSE)
			_handle_attack()

func _on_melee_attack_animation_animation_finished(anim_name: StringName) -> void:
	_on_animated_sprite_2d_animation_finished()


func _on_ranged_attack_animation_animation_finished(anim_name: StringName) -> void:
	_on_animated_sprite_2d_animation_finished()

func human_mage_taunt(spell_duration: int) -> bool:
	var hero_affected := false
	buff_handler.taunt_duration = spell_duration
	var arena_unitgrid = arena.unit_grid.units
	var affected_index_array = area_effect_handler.find_affected_units(position_id, 0, area_effect_handler.human_mage_taunt_template)
	if affected_index_array.size() != 0:
		for affected_index in affected_index_array:
			if arena_unitgrid.has(affected_index) and is_instance_valid(arena_unitgrid[affected_index]):
				if arena_unitgrid[affected_index] is Hero and arena_unitgrid[affected_index].team != team:
					arena_unitgrid[affected_index].target = self
					hero_affected = true
	return hero_affected

func human_archmage_heal(spell_duration: int, heal_value: int) -> bool:
	var hero_affected := false
	var arena_unitgrid = arena.unit_grid.units
	var affected_index_array = area_effect_handler.find_affected_units(position_id, 0, area_effect_handler.human_archmage_heal_template)
	if affected_index_array.size() != 0:
		for affected_index in affected_index_array:
			if arena_unitgrid.has(affected_index) and is_instance_valid(arena_unitgrid[affected_index]):
				if arena_unitgrid[affected_index] is Hero and arena_unitgrid[affected_index].team != team:
					arena_unitgrid[affected_index].buff_handler.continuous_hp_modifier = heal_value
					arena_unitgrid[affected_index].buff_handler.continuous_hp_modifier_duration = spell_duration
					hero_affected =  true
	return hero_affected

func elf_queen_stun(spell_duration: int, damage_value: int) -> bool:
	var hero_affected := false
	var arena_unitgrid = arena.unit_grid.units
	var affected_index_array = area_effect_handler.find_affected_units(position_id, 0, area_effect_handler.human_archmage_heal_template)
	if affected_index_array.size() != 0:
		for affected_index in affected_index_array:
			if arena_unitgrid.has(affected_index) and  is_instance_valid(arena_unitgrid[affected_index]):
				if arena_unitgrid[affected_index] is Hero and arena_unitgrid[affected_index].team != team:
					arena_unitgrid[affected_index].debuff_handler.stunned_duration  = spell_duration
					_apply_damage(arena_unitgrid[affected_index], damage_value)
					hero_affected =  true
	return hero_affected

func elf_mage_damage(spell_target:Hero, damage_threshold: float, min_damage_value: int, spell_range: int) -> bool:
	var hero_affected := false
	if spell_target.status != STATUS.DIE and spell_target.team != team and spell_target.global_position.distance_to(global_position) <= spell_range:

		if spell_target.hp <= spell_target.max_hp * damage_threshold:
			_apply_damage(spell_target, spell_target.hp)
			
		else:
			_apply_damage(spell_target, min_damage_value)

		hero_affected = true

	return hero_affected
