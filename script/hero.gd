# Hero character class with movement, dragging functionality and state management
#@tool
class_name Hero
extends Node2D

# ========================
# Constants and Enums
# ========================
# Character states
enum STATUS {IDLE, MOVE, MELEE_ATTACK, RANGE_ATTACK, JUMP, HIT, DIE}
enum TARGET_CHOICE {CLOSE, FAR, STRONG, WEAK, ALLY}

const DEFAULT_ATTACK_INTERVAL := 1.0  # Default attack interval (seconds)

# ========================
# Exported Variables
# ========================
# Character faction with property observer
@export_enum("human", "dwarf", "elf", "forestProtector", "holy") var faction := "human":
	set(value):
		faction = value
		_update_hero_name_options()  # Update hero name options when faction changes

# Hero name with property observer
@export var hero_name := "ShieldMan":
	set(value):
		hero_name = value
		if not Engine.is_editor_hint():
			return
		# Load animation resource in editor mode
		if ResourceLoader.exists("res://asset/animation/" + faction + "/" + faction + hero_name + ".tres"):
			animated_sprite_2d.sprite_frames = ResourceLoader.load("res://asset/animation/" + faction + "/" + faction + hero_name + ".tres")
		_update_hero_stat()

@export var max_hp := 100  # Maximum health points
@export var max_mp := 50   # Maximum magic points
@export var spd := 80      # Movement speed (pixels/second)
@export var damage := 20   # Attack damage
@export var attack_spd := 1 # Attack speed (attacks per second)
@export var attack_range := 20 # Attack range (pixels)
@export var team: int      # 0 for player, 1~7 for AI enemy
@export var dragging_enabled: bool = true # Enable/disable dragging
@export var sprite_frames: SpriteFrames  # Custom sprite frames
@export var line_visible:= false

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var melee_attack_animation: AnimationPlayer = $melee_attack_animation


# ========================
# Node References
# ========================
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_2d: Area2D = $Area2D
@onready var idle_timer: Timer = $idle_timer
@onready var attack_timer: Timer = $attack_timer
@onready var line := $Line2D  # Attack range indicator
@onready var drag_handler: Node2D = $drag_handler
@onready var target_timer: Timer = $target_timer

# ========================
# Member Variables
# ========================
var hp: int                # Current health points
var mp: int                # Current magic points
var hero_target_choice := TARGET_CHOICE.CLOSE  # Target selection strategy
var hero_target: Array[Hero] = []  # Current attack target
var hero_spell_target_count := 1
var hero_spell_target_choice := TARGET_CHOICE.CLOSE  # Target selection strategy
var hero_spell_target: Array[Hero] = [] # Current spell target

var smooth_velocity := Vector2.ZERO  # Smoothed movement velocity
var smooth_factor := 0.1  # Velocity smoothing factor

var stat := STATUS.IDLE         # Current character state

var skill_name := "Place holder."
var skill_description := "Place holder."

# Dictionary mapping factions to available hero names
var faction_hero_dict = {
	"human": ["ArchMage", "ArcherMan", "CavalierMan", "CrossBowMan", "HalberMan", "HorseMan", "KingMan", "Mage", "PrinceMan", "ShieldMan", "SpearMan"],
	"dwarf": ["ArmoredBearRider", "BearRider", "Demolitionist", "Grenade", "Grenadier", "Hunter", "King", "Miner", "Rifleman", "Shieldbreaker", "Warrior"],
	"elf": ["ArcaneArcher", "Archer", "HorseMan", "Mage", "PegasusRider", "Queen", "SpearMan", "SpellSword", "SwordMan", "Warden"],
	"forestProtector": ["DryadDeer", "DryadEnchantress", "DryadHuntress", "Fairy", "Pixie", "SatyrDruid", "SatyrWarrior", "Treant", "TreantGuard", "Satyr", "YoungDryad"],
	"holy": ["Angel", "ArchAngel", "BattlePriest", "Crusader", "CrusaderArcher", "CrusaderCaptain", "CrusaderCaptainFlagless", "CrusaderFlag", "CrusaderHorseMan", "HighPriestess", "Paladin1", "Paladin2", "Paladin3", "Priest"]
}

var hero_data: Dictionary  # Stores hero stats loaded from JSON
var rng = RandomNumberGenerator.new() # Random number generator

var move_path: PackedVector2Array
var move_speed: float = 200.0
var is_moving: bool = false

# ========================
# Signal Definitions
# ========================

signal attack_landed(target: Hero, damage: int)  # Emitted when attack hits target
signal died                                      # Emitted when die
signal turn_finished

# ========================
# Projectile Properties
# ========================
@export var projectile_scene: PackedScene  # Projectile scene for ranged attacks
@export var projectile_speed: float = 100.0  # Projectile speed
@export var projectile_damage: int = 15  # Projectile damage
@export var projectile_penetration: int = 1  # Number of enemies projectile can penetrate
@export var ranged_attack_threshold: float = 32.0  # Minimum distance for ranged attack
@export var melee_range: float = 16.0  # Melee attack range
@onready var hp_bar: ProgressBar = $hp_bar
@onready var mp_bar: ProgressBar = $mp_bar

# ========================
# Initialization
# ========================
func _ready():
	# Skip initialization in editor mode
	if Engine.is_editor_hint():
		return
		
	drag_handler.dragging_enabled = dragging_enabled
	
	# Validate node references before proceeding
	if not _validate_node_references():
		push_error("Hero node setup is invalid!")
		return
	
	# Load animations
	_load_animations()
	
	# Connect signals
	idle_timer.timeout.connect(_on_idle_timeout)
	attack_timer.timeout.connect(_on_attack_timeout)
	
	
	# Initialize random number generator
	rng.randomize()
	idle_timer.start()  # Start idle state timer
	
	# Play idle animation
	if animated_sprite_2d.sprite_frames.has_animation("idle"):
		animated_sprite_2d.play("idle")
	
	if team == 2:
		animated_sprite_2d.flip_h = true
		
	# Add to hero group for targeting
	add_to_group("hero_group")
	
	# Configure attack indicator line
	line.width = 0.5
	line.default_color = Color(1, 0, 0)
	line.visible = false
	
	# Load hero stats from JSON
	_load_hero_stats()
	
	# Initialize character properties
	hp = max_hp
	mp = 0
	# Set attack timer interval based on attack speed
	attack_timer.wait_time = 1.0 / attack_spd if attack_spd > 0 else DEFAULT_ATTACK_INTERVAL
	# print("%s's attack timer wait time = %d." % [hero_name, attack_timer.wait_time])

	hp_bar.min_value = 0
	hp_bar.max_value = max_hp
	mp_bar.min_value = 0
	mp_bar.max_value = max_mp
	hp_bar.value = max_hp
	mp_bar.value = 0
	
	
	var new_material = animated_sprite_2d.material.duplicate()
	match team:
		1:
			new_material.set_shader_parameter("outline_color", Color(1, 1, 0, 1))
		2:
			new_material.set_shader_parameter("outline_color", Color(1, 0, 1, 1))
		3:
			new_material.set_shader_parameter("outline_color", Color(0, 1, 1, 1))
		_:
			new_material.set_shader_parameter("outline_color", Color(1, 1, 1, 1))
	animated_sprite_2d.material = new_material
# ========================
# Process Functions
# ========================
func _process(delta: float) -> void:
	return
	# Skip processing in editor mode
	if Engine.is_editor_hint():
		return
		
	# Wait if in idle state
	#if idle_timer.time_left > 0:
		#return
	
	# Handle target selection and tracking
	_handle_targeting()
	
	# Handle state transitions and actions
	_handle_state()
	
	hp_bar.value = hp
	mp_bar.value = mp

func _physics_process(delta):
	return
	# Skip physics in editor mode
	if Engine.is_editor_hint():
		return

	# Handle movement toward target
	elif hero_target != [null] and hero_target != [] and stat == STATUS.MOVE:
		_handle_movement(delta)
	
	# Apply physics-based movement
	# move_and_slide()

# ========================
# Input Handling
# ========================
func _input(event):
	# Skip input processing in editor mode
	if Engine.is_editor_hint():
		return


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
	
	if not attack_timer:
		push_error("AttackTimer reference is missing!")
		valid = false
	
	return valid

# Load appropriate animations for the hero
func _load_animations():
	# Use custom sprite frames if provided
	if sprite_frames != null:
		animated_sprite_2d.sprite_frames = sprite_frames
	else:
		# Build path to default animation resource
		var path = "res://asset/animation/%s/%s%s.tres" % [faction, faction, hero_name]
		if ResourceLoader.exists(path):
			animated_sprite_2d.sprite_frames = ResourceLoader.load(path)
		else:
			push_error("Animation resource not found: " + path)

# Load hero stats from JSON file
func _load_hero_stats():
	var file = FileAccess.open("res://script/hero_stats_raw/hero_stats.json", FileAccess.READ)
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
		spd = stats.get("spd", spd)
		max_hp = stats.get("hp", max_hp)
		attack_range = stats.get("attack_range", attack_range)
		attack_spd = stats.get("attack_speed", attack_spd)
		skill_name = stats.get("skill_name", skill_name)
		skill_description = stats.get("skill_description", skill_description)
		print("Loaded stats for %s: spd=%d, hp=%d, range=%d, atk_speed=%d" % 
			[hero_name, spd, max_hp, attack_range, attack_spd])
	else:
		push_error("Stats not found for %s/%s" % [faction, hero_name])

# Handle target selection and tracking
func _handle_targeting():
	# Clear invalid targets (dead or invalid instances)
	if (hero_target == [null] or hero_target == []) or (not is_instance_valid(hero_target[0]) or hero_target[0].stat == STATUS.DIE):
		hero_target = [null]
		line.visible = false
	
	# Find new target if needed
	if hero_target == [null] or hero_target == []:
		hero_target = _find_new_target(hero_target_choice, 1)
	
	# Update attack indicator line
	if hero_target != [null] and hero_target != [] and line_visible:
		line.points = [Vector2.ZERO, to_local(hero_target[0].global_position)]
		line.visible = true
		


# Handle state transitions and actions
func _handle_state():

# died -> return
# !target -> idle
# mp == max_mp and target -> spell, reduce mp
# target and target in range and range >= ranged_criteria -> ranged_attack
# target and target in range and range < ranged_criteria -> melee_attack
# target and target not in range -> move
#

	if stat == STATUS.DIE:
		died.emit()
		queue_free()
		return


	if hero_target == [null] or hero_target == []:
		# Enter idle state if no targets available
		target_timer.stop()
		stat = STATUS.IDLE
		if animated_sprite_2d.sprite_frames.has_animation("idle"):
			animated_sprite_2d.play("idle")
		# Start idle timer with random duration
		#idle_timer.start(rng.randf_range(0.5, 1.0))
		#idle_timer.start(0.1)
		pass
 
		
	if mp >= max_mp:
		var spell_target =  _find_new_target(hero_spell_target_choice, hero_spell_target_count)
		if spell_target:
			for spell_target_member in spell_target:
				_cast_spell(spell_target_member)
		mp = 0
		return
		
	# Calculate distance to target
	if hero_target != [null] and hero_target != []:
		var distance = global_position.distance_to(hero_target[0].global_position)
	
			# Update character facing direction
		animated_sprite_2d.flip_h = (hero_target[0].global_position - global_position).x < 0
		
		# Transition to attack state if in range
		if distance <= attack_range:
			if stat != STATUS.MELEE_ATTACK or stat != STATUS.RANGE_ATTACK:
				if distance > ranged_attack_threshold and attack_range >= 32:
					stat = STATUS.RANGE_ATTACK
					if animated_sprite_2d.sprite_frames.has_animation("ranged_attack"):
						animated_sprite_2d.play("ranged_attack")
				else:
					stat = STATUS.MELEE_ATTACK
					if animated_sprite_2d.sprite_frames.has_animation("melee_attack"):
						#animated_sprite_2d.play("melee_attack")
						melee_attack_animation.play("melee_attack")
					elif animated_sprite_2d.sprite_frames.has_animation("attack"):
						animated_sprite_2d.play("attack")
			if attack_timer.is_stopped():
				attack_timer.start() # Start attack sequence
		# Transition to move state if out of range
		else:
			if stat != STATUS.MOVE:
				stat = STATUS.MOVE
				if animated_sprite_2d.sprite_frames.has_animation("move"):
					animated_sprite_2d.play("move")
				attack_timer.stop()  # Stop attacking


# Handle movement toward target
func _handle_movement(delta):
	if hero_target == [null] or hero_target == []:
		return
	
	if stat == STATUS.MELEE_ATTACK or stat == STATUS.RANGE_ATTACK:
		return
	


# Find a new target based on selection strategy
func _find_new_target(tgt, cnt: int) -> Array[Hero]:
	# Get all heroes in the scene
	var all_heroes: Array[Hero] = []
	for node in get_tree().get_nodes_in_group("hero_group"):
		if node is Hero:
			all_heroes.append(node)
	var enemy_heroes: Array[Hero] = []
	var ally_heroes: Array[Hero] = []
	var new_target: Array[Hero] = []
	var new_target_count = cnt
	var new_target_choice = tgt
	
	# Classify heroes as enemies or allies
	for hero in all_heroes:
		if hero == self:  # Skip self
			continue
		if hero.team == team:
			ally_heroes.append(hero as Hero)
		else:
			enemy_heroes.append(hero as Hero)
	
	# Select target based on strategy
	match new_target_choice:
		TARGET_CHOICE.FAR:
			if enemy_heroes.size() > 0:
				enemy_heroes.sort_custom(_compare_distance)
				new_target = enemy_heroes.slice(0, new_target_count) as Array[Hero]  # Farthest enemy
		
		TARGET_CHOICE.CLOSE:
			if enemy_heroes.size() > 0:
				enemy_heroes.sort_custom(_compare_distance)
				new_target = enemy_heroes.slice(-new_target_count) as Array[Hero] # Closest enemy
		
		TARGET_CHOICE.STRONG:
			if enemy_heroes.size() > 0:
				# Sort by max HP descending
				enemy_heroes.sort_custom(func(a, b): return a.max_hp > b.max_hp)
				new_target = enemy_heroes.slice(0, new_target_count) as Array[Hero]  # Strongest enemy
		
		TARGET_CHOICE.WEAK:
			if enemy_heroes.size() > 0:
				# Sort by max HP ascending
				enemy_heroes.sort_custom(func(a, b): return a.max_hp < b.max_hp)
				new_target = enemy_heroes.slice(-new_target_count) as Array[Hero]  # Weakest enemy
		
		TARGET_CHOICE.ALLY:
			if ally_heroes.size() > 0:
				new_target = ally_heroes.slice(0, new_target_count) as Array[Hero]  # First ally
	
	if new_target != [] and new_target != []:
		target_timer.start()
		return new_target as Array[Hero]
	else:
		return [] as Array[Hero]  # No valid target found

# Comparator for sorting by distance
func _compare_distance(a: Node2D, b: Node2D) -> bool:
	return a.global_position.distance_to(global_position) < b.global_position.distance_to(global_position)


# Handle idle timer timeout
func _on_idle_timeout():
	# End idle state and search for targets
	# _handle_targeting()
	# idle_timer.stop()
	pass

# ========================
# Attack Methods
# ========================
func _on_attack_timeout():
	# Validate target exists
	if hero_target == [null] or hero_target == [] or not is_instance_valid(hero_target[0]):
		attack_timer.stop()
		return
	
	# Calculate distance to target
	var distance = global_position.distance_to(hero_target[0].global_position)
	
	# Use ranged attack if beyond thresholds
	if distance > melee_range && distance > ranged_attack_threshold:
		_launch_projectile(hero_target[0])
	else:
		# Melee attack
		hero_target[0].take_damage(damage, self)
		emit_signal("attack_landed", hero_target, damage)
	
	# Handle target death
	if hero_target[0].hp <= 0:
		hero_target[0].stat = STATUS.DIE
		hero_target = [null]
		attack_timer.stop()

# Launch projectile at target
func _launch_projectile(target: Hero):
	return
	if not projectile_scene:
		push_error("Projectile scene is not set!")
		return
	
	# Create projectile instance
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	
	# Calculate direction to target
	var direction = (target.global_position - global_position).normalized()
	
	# Determine if we need to flip the projectile sprite
	var is_flipped = direction.x < 0
	
	# Set up projectile
	projectile.setup(
		global_position, 
		direction,
		team,
		is_flipped,
		self
	)
	
	# Configure projectile properties
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.penetration = projectile_penetration

# Add damage handling method
func take_damage(damage_value: int, attacker: Hero):
	hp -= damage_value
	if hp <= 0:
		# Handle death logic
		stat = STATUS.DIE
	attacker.mp += damage

# ========================
# Editor Helper Functions
# ========================
# Update hero name options when faction changes (editor only)
func _update_hero_name_options():
	if not Engine.is_editor_hint():
		return
		
	# Get valid names for current faction
	var valid_names = faction_hero_dict.get(faction, [])
	var hint_string = ",".join(valid_names)
	
	# Notify editor of property changes
	notify_property_list_changed()
	
	# Ensure hero name is valid for current faction
	if not hero_name in valid_names and valid_names.size() > 0:
		hero_name = valid_names[0]

# Update hero stats (editor only)
func _update_hero_stat():
	pass  # Placeholder for editor-specific stat updates


func _cast_spell(spell_tgt: Hero):
	print("%s casts a spell : %s." % [hero_name, skill_name])
	print("\"%s\"" % skill_description)
	pass


func _apply_damage():
	if hero_target != [null] and hero_target != []:
		hero_target[0].take_damage(damage, self)
