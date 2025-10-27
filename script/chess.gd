class_name Chess
extends Obstacle

const emoji_bubble_scene = preload("res://scene/emoji_bubble.tscn")
# ========================
# Constants and Enums
# ========================
# Character states
#enum STATUS {IDLE, MOVE, MELEE_ATTACK, RANGED_ATTACK, JUMP, HIT, DIE, SPELL}
enum TARGET_CHOICE {CLOSE, FAR, STRONG, WEAK, ALLY, SELF}

#enum play_areas {playarea_arena, playarea_bench, playarea_shop, playarea_grave}

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
@onready var reference_rect: ReferenceRect = $Area2D/ReferenceRect

# ========================
# Exported Variables
# ========================
# Character faction with property observer
#@export_enum("human", "dwarf", "elf", "forestProtector", "holy", "demon", "undead", "villager") var faction := "human"

# Chess name with property observer
#@export var chess_name := "SwordMan"
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
var base_melee_damage := 20.0   # Attack damage
var base_ranged_damage := 20.0   # Attack damage
var base_attack_speed := 1 # Attack speed (attacks per turn)
var base_attack_range := 20.0 # Attack range (pixels)
var base_evasion_rate := 0.10
var base_critical_rate := 0.10
var base_critical_damage := 2.0
var base_life_steal_rate := 0.0
var base_reflect_damage := 0.0
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

var role: String
var speed = base_speed
var melee_damage = base_melee_damage
var ranged_damage = base_ranged_damage
var damage
var attack_speed = base_attack_speed
var attack_range = base_attack_range
var evasion_rate := 0.10
var critical_rate := 0.10
var critical_damage := 2.0
var life_steal_rate := 0.0
var reflect_damage := base_reflect_damage
#var armor := 0
var decline_ratio := 3.0
var chess_rarity := "Common" #	"Common", "Uncommon", "Rare", "Epic", "Legendary"

var remain_attack_count
var total_movement := 0
var is_phantom := false

var target_changed := false

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
#var grave: PlayArea

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

var passive_ability: String = ""

#var taunt_range := 70

# Projectile Related
#var projectile_speed: float = 300.0  # Projectile speed
#var projectile_damage: int = 15  # Projectile damage
#var projectile_penetration: int = 3  # Number of enemies projectile can penetrate
#var ranged_attack_threshold: float = 32.0  # Minimum distance for ranged attack
#var projectile

var demon_bonus_level := 0
var dwarf_bonus_level := 0
var elf_bonus_level := 0
var forestProtector_bonus_level := 0
var holy_bonus_level := 0
var human_bonus_level := 0
var undead_bonus_level := 0
var villager_bonus_level := 0
var warrior_bonus_level := 0
var knight_bonus_level := 0
var ranger_bonus_level := 0
var speller_bonus_level := 0
var pikeman_bonus_level := 0

var faction_bonus_manager

var total_kill_count := 0

var record_global_position := Vector2.ZERO
var game_root_scene

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

# signal is_died(obstacle: Obstacle, attacker: Obstacle) # for audio player and display


# ========================
# Initialization
# ========================
func _ready():
	
	chess_mover = arena.get_parent().get_parent().chess_mover
		
	drag_handler.dragging_enabled = dragging_enabled
	
	effect_handler = EffectHandler.new()
	add_child(effect_handler)
	
	game_root_scene = arena.get_parent().get_parent()
	
	faction_bonus_manager = game_root_scene.faction_bonus_manager
	
	# Load animations
	_load_animations()

	# Validate node references before proceeding
	if not _validate_node_references():
		push_error("Chess node setup is invalid!")
		return
		
		
	#var effect_instance = ChessEffect.new()
	#effect_instance.register_buff("duration_only", 0, 999)
	#effect_instance.effect_name = "KillCount"
	#effect_instance.effect_type = "PermanentBuff"
	#effect_instance.effect_applier = "System"
	#if effect_instance.get_meta("kill_count") == null:
		#effect_instance.set_meta("kill_count", 0)
	#effect_instance.effect_description = "Total kill: " + str(effect_instance.get_meta("kill_count"))
	#effect_handler.add_to_effect_array(effect_instance)
	#effect_handler.add_child(effect_instance)
	
	# Connect signals
	if idle_timer.timeout.connect(_on_idle_timeout) != OK:
		print("idle_timer.timeout connect fail: " + str(idle_timer.timeout.connect(_on_idle_timeout)))
	if move_timer.timeout.connect(_handle_action) != OK:
		print("move_timer.timeout connect fail!")
	if action_timer.timeout.connect(_handle_action_timeout) != OK:
		print("action_timer.timeout connect fail!")
	
	if drag_handler.drag_started.connect(_handle_dragging_state) != OK:
		print("drag_handler.drag_started connect fail!")

	if drag_handler.drag_canceled.connect(_handle_dragging_state) != OK:
		print("drag_handler.drag_canceled connect fail!")
	if drag_handler.drag_dropped.connect(_handle_dragging_state) != OK:
		print("drag_handler.drag_dropped connect fail!")
	if damage_taken.connect(take_damage) != OK:
		print("damage_taken connect fail!")

	if spell_casted.connect(AudioManagerSingleton.play_sfx.bind("spell_casted")) != OK:
		print("spell_casted connect fail!")
	if ranged_attack_started.connect(AudioManagerSingleton.play_sfx.bind("ranged_attack_started")) != OK:
		print("ranged_attack_started connect fail!")
	if melee_attack_started.connect(AudioManagerSingleton.play_sfx.bind("melee_attack_started")) != OK:
		print("melee_attack_started connect fail!")
	if projectile_lauched.connect(AudioManagerSingleton.play_sfx.bind("projectile_lauched")) != OK:
		print("projectile_lauched connect fail!")
	if damage_taken.connect(AudioManagerSingleton.play_sfx.unbind(2).bind("damage_taken")) != OK:
		print("damage_taken connect fail!")
	if critical_damage_taken.connect(AudioManagerSingleton.play_sfx.unbind(2).bind("critical_damage_taken")) != OK:
		print("critical_damage_taken connect fail!")
	if heal_taken.connect(AudioManagerSingleton.play_sfx.unbind(2).bind("heal_taken")) != OK:
		print("heal_taken connect fail!")
	if attack_evased.connect(AudioManagerSingleton.play_sfx.unbind(1).bind("attack_evased")) != OK:
		print("attack_evased connect fail!")
	if is_died.connect(AudioManagerSingleton.play_sfx.bind(self, "is_died")) != OK:
		print("is_died connect fail!")
	
	kill_chess.connect(
		func(attacker, target):
			if attacker == target:
				return
			total_kill_count += 1
			if target is Chess and target.faction == "forestProtector":

				var effect_instance = ChessEffect.new()
				effect_instance.register_buff("duration_only", 0, 999)
				effect_instance.effect_name = "Vengeance - "+ str(attacker.faction)
				effect_instance.effect_type = "PermanentBuff"
				effect_instance.effect_applier = "ForestProtector path3 Faction Bonus"
				effect_instance.effect_description = "ForestProtector gain damage and resistance againt who kills them."
				effect_handler.add_to_effect_array(effect_instance)
				effect_handler.add_child(effect_instance)
	)

	kill_chess.connect(
		func(attacker: Obstacle, target: Obstacle):
			if attacker == target:
				return
			if attacker.faction == "dwarf":
				match attacker.chess_name:
					"BearRider":
						attacker.take_heal(target.max_hp * 0.1 * attacker.chess_level,self)
					"ArmoredBearRider":
						attacker.take_heal(target.max_hp * 0.2 * attacker.chess_level,self)
					_:
						pass
			elif attacker.faction == "forestProtector":
				if min(faction_bonus_manager.get_bonus_level("forestProtector", 1), game_root_scene.faction_path_upgrade["forestProtector"]["path2"]) == 0 and attacker.team == 1:
					return

				if faction_bonus_manager.get_bonus_level("forestProtector", 2) == 0 and attacker.team == 2:
					return

				var current_bonus_level
				if attacker.team == 1:
					current_bonus_level = min(faction_bonus_manager.get_bonus_level("forestProtector", 1), game_root_scene.faction_path_upgrade["forestProtector"]["path2"])
				elif attacker.team == 2:
					current_bonus_level = faction_bonus_manager.get_bonus_level("forestProtector", 2)

				if current_bonus_level < 2:
					return

				var forestProtector_path2_effect

				for effect_index in attacker.effect_handler.effect_list:
					if effect_index.effect_applier == "Forest Protector path2 Faction Bonus":
						forestProtector_path2_effect = effect_index
						break

				match current_bonus_level:
					2:
						forestProtector_path2_effect.buff_dict["continuous_hp_modifier"] += 5
						forestProtector_path2_effect.buff_dict["max_hp_modifier"] += 20
					3:
						forestProtector_path2_effect.buff_dict["continuous_hp_modifier"] += 10
						forestProtector_path2_effect.buff_dict["max_hp_modifier"] += 35
					_:
						pass
	)			

	
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
	if line_visible:
		attack_target_line.visible = true
	
	# Configure attack indicator line
	spell_target_line.width = 0.5
	spell_target_line.default_color = Color(0, 0, 1)
	
	spell_target_line.visible = false
	
	# Load chess stats from JSON
	_load_chess_stats()
	
	# Initialize character properties
	hp = max_hp
	mp = max_mp if DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"] else 0

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
	

	area_effect_handler.arena = arena

	connect_to_data_manager()
	
	line_visible = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"]
# ========================
# Process Functions
# ========================


func _process(delta: float) -> void:
				
	record_global_position = global_position
	
	hp_bar.value = hp
	mp_bar.value = mp

	hp_bar.max_value = max_hp
	mp_bar.max_value = max_mp

		
	#if get_current_tile(self)[0] != arena:
		#hp_bar.visible = false
		#mp_bar.visible = false
	#else:
		#hp_bar.visible = true
		#if not animated_sprite_2d.sprite_frames.has_animation("spell") :
			#mp_bar.visible = false		
				
	if get_current_tile(self)[0].name != "arena":
		hp_bar.visible = false
		mp_bar.visible = false
	else:
		hp_bar.visible = true
		if not animated_sprite_2d.sprite_frames.has_animation("spell") :
			mp_bar.visible = false
		else:
			mp_bar.visible = true
	
	if chess_level > 1:
		level_label.text = "I".repeat(chess_level)
		level_label.visible = true
	else:
		level_label.text = "I"
		level_label.visible = false
		
		
	# Update attack indicator line
	if DataManagerSingleton.check_obstacle_valid(chess_target) and line_visible:
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
	
	if is_phantom:
		new_material.set_shader_parameter("monochrome_color", Color(0.18, 0.765, 1.0, 1.0))
		new_material.set_shader_parameter("use_monochrome", true)

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

	if randf() < 0.00005:
		var emoji_bubble = emoji_bubble_scene.instantiate()
		add_child(emoji_bubble)
		emoji_bubble.z_index = 60
		var emoji_offset := Vector2.ZERO
		match emoji_bubble.bubble_index:
			1:
				emoji_offset = Vector2(-15, -43)
			2:
				emoji_offset = Vector2(-7, -43)
			3:
				emoji_offset = Vector2(-22, -43)
			4:
				emoji_offset = Vector2(-16, 6)
			5:
				emoji_offset = Vector2(-7, 6)
			6:
				emoji_offset = Vector2(-24, 6)
			7:
				emoji_offset = Vector2(8, -19)
			8:
				emoji_offset = Vector2(8, -27)
			9:
				emoji_offset = Vector2(8, -10)
			_:
				emoji_offset = Vector2(-15, -43)
		emoji_bubble.position += emoji_offset
		
	reference_rect.visible = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"]
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
			if anim_name == "move" or anim_name == "jump" or anim_name == "fly":
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
		role = stats["role"]
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
			decline_ratio = 100.0
			projectile_penetration = 1
		else:
			base_melee_damage = stats["melee_attack_damage"]
			base_ranged_damage = stats["ranged_attack_damage"]
			decline_ratio = stats["decline_ratio"]
			projectile_penetration = stats["projectile_penetration"]

		if stats.keys().has("max_mana"):
			base_max_mp = stats["max_mana"]
		else:
			base_max_mp = 0

		match chess_level:
			1:
				pass
			2:
				base_max_hp *= 1.2
				base_melee_damage *= 1.2
				base_ranged_damage *= 1.2
			3:
				base_speed += 1
				base_max_hp *= 1.5
				base_melee_damage *= 1.5
				base_ranged_damage *= 1.5
			
		if stats.keys().has("skill_name"):
			skill_name = stats["skill_name"]
			skill_description = stats["skill_description"]
			
		if stats.keys().has("passive_ability"):
			passive_ability = stats["passive_ability"]
			
		chess_rarity = stats["rarity"]
		stats_loaded.emit(self, stats)
	else:
		push_error("Stats not found for %s/%s" % [faction, chess_name])

func start_turn():

	total_movement = 0
	target_changed = false
	
	#Placeholder for chess passive ability on start turn
	if status == STATUS.DIE:
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()
		return

	update_solid_map()
	await get_tree().process_frame
	
	_load_chess_stats()

	dwarf_path2_bonus()

	dwarf_path3_bonus()

	update_effect()

	remain_attack_count = attack_speed

	#if not chess_target or not is_instance_valid(chess_target) or chess_target.status == STATUS.DIE:
	if not DataManagerSingleton.check_obstacle_valid(chess_target):
		target_lost.emit(self)
		_handle_targeting()
		
	if DataManagerSingleton.check_obstacle_valid(chess_target):
		target_found.emit(self, chess_target)
		await _handle_movement()
	else:
		action_timer.start()

func _handle_movement():
	#Placeholder for chess passive ability on movement

	if status == STATUS.DIE:
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()
		return

	var current_tile = get_current_tile(self)[1]
	var chess_target_tile = get_current_tile(self)[1]


	if faction_bonus_manager.get_bonus_level("dwarf", team) > 0:
		astar_grid.diagonal_mode = 0
	else:
		astar_grid.diagonal_mode = 1

	move_started.emit(self, current_tile)
	
	
	if global_position.distance_to(chess_target.global_position) <= attack_range or effect_handler.is_stunned:
		move_finished.emit(self, current_tile)
		move_timer.set_wait_time(move_timer_wait_time)			
		move_timer.start()
		return
		
	#if current_play_area == play_areas.playarea_arena:
	if arena.unit_grid.get_all_units().has(self):
		arena.unit_grid.remove_unit(current_tile)

	var pegasus_rider_movement_result := false
	if faction == "elf" and chess_name == "PegasusRider":
		pegasus_rider_movement_result = await pegasus_rider_movement()
		
	if not pegasus_rider_movement_result:

		animated_sprite_2d.play("move")


		astar_grid.set_point_solid(current_tile, false)
		astar_grid.set_point_solid(get_current_tile(chess_target)[1], false)

		await get_tree().process_frame

		move_path = astar_grid.get_point_path(current_tile, get_current_tile(chess_target)[1])
			
		if move_path.is_empty():
			move_path = get_safe_path(current_tile, get_current_tile(chess_target)[1])

		if move_path.is_empty():
			astar_grid.set_point_solid(get_current_tile(chess_target)[1], true)
			move_finished.emit(self, current_tile)
			move_timer.set_wait_time(move_timer_wait_time)
			move_timer.start()
			return

		var chess_target_marked = chess_target.effect_handler.effect_list.any(
			func(effect_index):
				var result := false
				if effect_index.effect_duration >= 1 and effect_index.effect_name == "HunterMark":
					result = true
				return result
		)
		var move_steps = min(speed + (1 if chess_target_marked else 0), move_path.size() - 1)

		remain_step = move_steps
		for current_step in range(move_steps):
			if (remain_step >= 2) and (move_path[current_step + 1] - move_path[current_step]).dot(move_path[current_step + 1] - move_path[current_step]) == 0:
				remain_step -= 1
				total_movement += 1
				continue
			var target_pos = move_path[current_step + 1] + grid_offset
			var target_tile = arena.get_tile_from_global(target_pos + get_parent().global_position)
			if arena.unit_grid.is_tile_occupied(target_tile) or astar_grid.is_point_solid(target_pos) or remain_step <= 0 or global_position.distance_to(chess_target.global_position) <= attack_range:
				break

			var previous_tile = get_current_tile(self)[1]

			var neighbor_chess
			for tile_offset_index in [Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)]:

				if not arena.is_tile_in_bounds(previous_tile + tile_offset_index):
					continue

				if not DataManagerSingleton.check_chess_valid(arena.unit_grid.units[previous_tile + tile_offset_index]):
					continue

				neighbor_chess = arena.unit_grid.units[previous_tile + tile_offset_index]

				if neighbor_chess.team == team:
					continue

				if not neighbor_chess.animated_sprite_2d.sprite_frames.has_animation("melee_attack"):
					continue

				if position.distance_to(neighbor_chess.position) <= min(neighbor_chess.attack_range, ranged_attack_threshold) and target_pos.distance_to(neighbor_chess.position) > min(neighbor_chess.attack_range, ranged_attack_threshold):
					if DataManagerSingleton.check_chess_valid(neighbor_chess):
						await neighbor_chess.handle_free_strike(self) #leave attack range free strike

				if neighbor_chess.role == "pikeman" and faction_bonus_manager.get_bonus_level("pikeman", neighbor_chess.team) > 0:
					if position.distance_to(neighbor_chess.position) > min(neighbor_chess.attack_range, ranged_attack_threshold) and target_pos.distance_to(neighbor_chess.position) <= min(neighbor_chess.attack_range, ranged_attack_threshold):
						if DataManagerSingleton.check_chess_valid(neighbor_chess):
							await neighbor_chess.handle_free_strike(self) #enter attack range free strike

			if DataManagerSingleton.check_obstacle_valid(self):
				await chess_mover.tween_move_chess(self, arena, target_pos)
			else:
				move_finished.emit(self,get_current_tile(self)[1])
				move_timer.set_wait_time(move_timer_wait_time)
				move_timer.start()
				return

			remain_step -= 1
			total_movement += 1

	astar_grid.set_point_solid(get_current_tile(self)[1], true)
	astar_grid.set_point_solid(get_current_tile(chess_target)[1], true)
	#Placeholder for chess passive ability on move finish
	move_finished.emit(self,get_current_tile(self)[1])
	move_timer.set_wait_time(move_timer_wait_time)
	move_timer.start()
						
func _handle_action():

	animated_sprite_2d.stop()

	arena.unit_grid.add_unit(get_current_tile(self)[1], self)

	if status == STATUS.DIE or not visible:
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()
		return

	move_timer.stop()
	action_started.emit(self)

	await dwarf_path1_bonus()
	await elf_path1_bonus()

	var current_tile = get_current_tile(self)[1]
		
	astar_grid.set_point_solid(current_tile, true)
	#Placeholder for chess passive ability on action start
	var cast_spell_result := false

	if not is_phantom and  mp >= max_mp and animated_sprite_2d.sprite_frames.has_animation("spell") and (not effect_handler.is_silenced and not effect_handler.is_stunned):

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

	#if !chess_target or !is_instance_valid(chess_target) or chess_target.status == STATUS.DIE or not chess_target.visible:
	if not DataManagerSingleton.check_obstacle_valid(chess_target):
		target_lost.emit(self)
		action_timer.start()
		return
	else:
		await _handle_attack()

func _handle_attack():
	var rotate_tween = create_tween().set_parallel(false)
	
	if status == STATUS.DIE:
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()
		return

	#if !chess_target or !is_instance_valid(chess_target) or chess_target.status == STATUS.DIE:
	if not DataManagerSingleton.check_obstacle_valid(chess_target) and chess_name != "CrossBowMan":
		target_lost.emit(self)
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()
		return
	elif not DataManagerSingleton.check_obstacle_valid(chess_target) and chess_name == "CrossBowMan" and faction == "human":
		target_lost.emit(self)
		_handle_targeting()
		if not DataManagerSingleton.check_obstacle_valid(chess_target):
			target_lost.emit(self)
			action_timer.set_wait_time(action_timer_wait_time)
			action_timer.start()
			return

	warrior_bonus()

	#Placeholder for chess passive ability on attack
	var current_distance_to_target = global_position.distance_to(chess_target.global_position)
	remain_attack_count -= 1
	if current_distance_to_target <= attack_range and (not effect_handler.is_stunned and not effect_handler.is_disarmed):
		var rotate_vector = chess_target.global_position - global_position
		var rotate_degree := 0.0
		if not animated_sprite_2d.flip_h:
			rotate_degree = atan2(rotate_vector.y, rotate_vector.x)
		elif atan2(rotate_vector.y, rotate_vector.x) < 0:
			rotate_degree = atan2(rotate_vector.y, rotate_vector.x) + PI
		elif atan2(rotate_vector.y, rotate_vector.x) >= 0:
			rotate_degree = atan2(rotate_vector.y, rotate_vector.x) - PI

		rotate_tween.tween_property(animated_sprite_2d, "rotation", rotate_degree, 0.2)
		await rotate_tween.finished		
		if not has_melee_target() and current_distance_to_target >= ranged_attack_threshold and animated_sprite_2d.sprite_frames.has_animation("ranged_attack"):
			status = STATUS.RANGED_ATTACK
			damage = ranged_damage
			if ResourceLoader.exists("res://asset/animation/%s/%s%s_projectile.tres" % [faction, faction, chess_name]):
				
				animated_sprite_2d.play("ranged_attack")
				ranged_attack_started.emit(self)
				var chess_projectile = _launch_projectile_to_target(chess_target)
				projectile_lauched.emit(self)

				# chess_projectile.projectile_vanished.connect(_on_animated_sprite_2d_animation_finished)
				chess_projectile.projectile_vanished.connect(
					func(attacker_name):
						debug_handler.write_log("LOG", attacker_name + "'s projectile has vanished.")
				)
				chess_projectile.projectile_hit.connect(handle_projectile_hit)
				chess_projectile.projectile_hit.connect(handle_special_effect.unbind(1))
				await chess_projectile.projectile_vanished
				

			else:

				ranged_attack_animation.play("ranged_attack")
				ranged_attack_started.emit(self)
				deal_damage.emit(self, chess_target, damage, "Ranged_attack", [])
				if not target_evased_attack:
					await handle_special_effect(chess_target)
					
				animated_sprite_2d.set_animation("idle")
				
				

		elif current_distance_to_target < ranged_attack_threshold or (has_melee_target() is Obstacle and current_distance_to_target >= ranged_attack_threshold and animated_sprite_2d.sprite_frames.has_animation("ranged_attack")):
			
			knight_bonus()

			damage = melee_damage

			if current_distance_to_target >= ranged_attack_threshold:
				change_target_to(has_melee_target()) 


			if animated_sprite_2d.sprite_frames.has_animation("melee_attack"):
				
				if false:
					if DataManagerSingleton.check_chess_valid(chess_target):
						await chess_target.handle_free_strike(self)
				
				target_evased_attack = false
				
				status = STATUS.MELEE_ATTACK
				melee_attack_animation.play("melee_attack")
				melee_attack_started.emit(self)
				await melee_attack_animation.animation_finished
				
				if not target_evased_attack:
					await handle_special_effect(chess_target)
				
				if faction_bonus_manager.get_bonus_level("elf", team) > 1 and target_evased_attack and chess_target.faction == "elf" :
					await elf_path3_bonus()
				elif randf() >= 0.9 and DataManagerSingleton.check_chess_valid(chess_target):
					await chess_target.handle_free_strike(self)
					

			elif animated_sprite_2d.sprite_frames.has_animation("attack"):
				
				if false:
					if DataManagerSingleton.check_chess_valid(chess_target):
						await chess_target.handle_free_strike(self)
					
				status = STATUS.MELEE_ATTACK
				animated_sprite_2d.play("attack")
				melee_attack_started.emit(self)
				deal_damage.emit(self, chess_target, damage, "melee_attack", [])	

				if not target_evased_attack:
					await handle_special_effect(chess_target)
				
				if faction_bonus_manager.get_bonus_level("elf", chess_target.team) > 1 and chess_target.faction == "elf" :
					await elf_path3_bonus()
				elif randf() >= 0.9:
					await chess_target.handle_free_strike(self)

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
		
		rotate_tween = create_tween()
		rotate_tween.tween_property(animated_sprite_2d, "rotation", atan2(0, 0), 0.15)	
		await get_tree().create_timer(0.2).timeout
		rotation = 0.0
		rotate_tween.kill()
		
	else:
		# Out of attack range
		status = STATUS.IDLE
		action_timer.set_wait_time(action_timer_wait_time)
		action_timer.start()

	if not DataManagerSingleton.check_obstacle_valid(chess_target) and chess_name == "CrossBowMan" and faction == "human":
		remain_attack_count += 1
				
	if remain_attack_count > 0 and chess_target.faction != "forestProtector" and chess_target.chess_name != "DryadDeer":
		await get_tree().create_timer(0.2).timeout
		await _handle_attack()
	else:
		
		animated_sprite_2d.set_animation("idle")
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
	change_target_to(_find_new_target(chess_target_choice))
	if line_visible:
		attack_target_line.visible = true
		
# Find a new target based on selection strategy
func _find_new_target(target_choice) -> Obstacle:
	#Placeholder for chess passive ability on find target
	var new_target
	# var all_chesses = get_tree().get_nodes_in_group("obstacle_group").filter(
	var all_chesses = arena.unit_grid.get_all_units()
	var enemy_chesses = all_chesses.filter(
		func(chess): return chess != self and DataManagerSingleton.check_obstacle_valid(chess) and chess.team != team
	)
	var ally_chesses = all_chesses.filter(
		func(chess): return chess != self and DataManagerSingleton.check_obstacle_valid(chess) and chess.team == team
	)

	if chess_name == "Pixie" and faction == "forestProtector":
		var enemy_spellers = enemy_chesses.filter(
			func(chess):
				return chess.role == "speller"
		)
		if enemy_spellers.size() > 0:
			enemy_chesses = enemy_spellers
	
	# Select target based on strategy
	match target_choice:
		TARGET_CHOICE.FAR:
			if enemy_chesses.size() > 0:
				enemy_chesses.sort_custom(func(a, b): return _compare_distance(a, b))
				new_target = enemy_chesses.front()  # Farthest enemy
		
		TARGET_CHOICE.CLOSE:
			if enemy_chesses.size() > 0:
				enemy_chesses.sort_custom(func(a, b): return _compare_distance(a, b))
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

func change_target_to(target: Obstacle):
	if DataManagerSingleton.check_obstacle_valid(chess_target):
		if chess_target.is_died.is_connected(handle_target_death):
			chess_target.is_died.disconnect(handle_target_death)
		if chess_target.attack_evased.is_connected(handle_target_evased_attack):
			chess_target.attack_evased.disconnect(handle_target_evased_attack)
		
	if chess_target != target and not is_active:
		target_changed = true

	if DataManagerSingleton.check_obstacle_valid(target):
		chess_target = target
		if chess_target.has_signal("is_died"):
			if chess_target.is_died.connect(handle_target_death) != OK:
				print("chess_target.is_died connect fail!")
		if chess_target.has_signal("attack_evased"):
			if chess_target.attack_evased.connect(handle_target_evased_attack) != OK:
				print("chess_target.attack_evased connect fail!")
	else:
		chess_target = null
	
func handle_target_evased_attack(target: Obstacle, attacker: Obstacle):
	target_evased_attack = true
	
func _compare_distance(a: Obstacle, b: Obstacle) -> bool:

	# handling taunt
	if (a.effect_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range) and (not b.effect_handler.is_taunt or b.global_position.distance_to(global_position) > taunt_range):
		return true
	if (not a.effect_handler.is_taunt or a.global_position.distance_to(global_position) > taunt_range) and (b.effect_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range):
		return false
		
	# handling stealth chess
	if a.effect_handler.is_stealth and not b.effect_handler.is_stealth:
		return false
	if not a.effect_handler.is_stealth and b.effect_handler.is_stealth:
		return true
	
	return a.global_position.distance_to(global_position) > b.global_position.distance_to(global_position)

func _compare_hp(a: Obstacle, b: Obstacle) -> bool:

	# handling taunt
	if (a.effect_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range) and (not b.effect_handler.is_taunt or b.global_position.distance_to(global_position) > taunt_range):
		return true
	if (not a.effect_handler.is_taunt or a.global_position.distance_to(global_position) > taunt_range) and (b.effect_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range):
		return false
		
	# handling stealth chess
	if a.effect_handler.is_stealth and not b.effect_handler.is_stealth:
		return false
	if not a.effect_handler.is_stealth and b.effect_handler.is_stealth:
		return true
	
	return a.max_hp > b.max_hp

func _compare_damage(a: Obstacle, b: Obstacle) -> bool:

	# handling taunt
	if (a.effect_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range) and (not b.effect_handler.is_taunt or b.global_position.distance_to(global_position) > taunt_range):
		return true
	if (not a.effect_handler.is_taunt or a.global_position.distance_to(global_position) > taunt_range) and (b.effect_handler.is_taunt and a.global_position.distance_to(global_position) <= taunt_range):
		return false
		
	# handling stealth chess
	if a.effect_handler.is_stealth and not b.effect_handler.is_stealth:
		return false
	if not a.effect_handler.is_stealth and b.effect_handler.is_stealth:
		return true
	
	return a.damage > b.damage

# Handle idle timer timeout
func _on_idle_timeout():
	if status == STATUS.IDLE:
		animated_sprite_2d.play("idle")
		idle_timer.set_wait_time(rng.randf_range(1.0,5.0))


# Launch projectile at target
func _launch_projectile_to_target(target: Obstacle):
	
	# Calculate direction to target
	var direction = (target.global_position - global_position).normalized()
	
	# Determine if we need to flip the projectile sprite
	var is_flipped = direction.x < 0
	
	
	projectile = projectile_scene.instantiate()
	
	if not projectile:
		push_error("Projectile scene is not set!")
		return
		
	# Create projectile instance
	add_child(projectile)
	
	
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
	projectile.decline_ratio = decline_ratio
	projectile.is_active = true
	
	return projectile

# Launch projectile at target
func _launch_projectile_to_degree(direction_degree: float):
	
	
	# Determine if we need to flip the projectile sprite
	var is_flipped = direction_degree > 90 and direction_degree < 270
	
	
	projectile = projectile_scene.instantiate()
	
	if not projectile:
		push_error("Projectile scene is not set!")
		return
		
	# Create projectile instance
	add_child(projectile)
	
	
	# Set up projectile
	projectile.global_position = global_position
	projectile.direction_degree = direction_degree
	projectile.source_team = team
	projectile.initial_flip = is_flipped
	projectile.attacker = self
	projectile.projectile_animation = ""
	
	projectile_damage = ranged_damage

	# Configure projectile properties
	projectile.speed = projectile_speed
	projectile.damage = projectile_damage
	projectile.penetration = projectile_penetration
	projectile.decline_ratio = decline_ratio
	projectile.is_active = true
	
	return projectile

# Add damage handling method
func take_damage(target:Obstacle, attacker: Obstacle, damage_value: float):
	#Placeholder for chess passive ability on take damage

	if (-1.0 if animated_sprite_2d.flip_h else 1.0) * (attacker.position - target.position).x > 0 and target.faction == "human" and target.chess_name == "SwordMan":
		if randf() <= target.chess_level * 0.1:
			target.animated_sprite_2d.play("block")
			target.animated_sprite_2d.set_animation("idle")
			target.status = STATUS.IDLE
			return

	target.hp -= damage_value
	target.hp_bar.value = target.hp

	if target.hp <= 0:
		target.status = STATUS.DIE
		target.animated_sprite_2d.stop()
		target.animated_sprite_2d.play("die")
		await target.animated_sprite_2d.animation_finished
		target.visible = false
		_on_died()
		target.is_died.emit()
		game_root_scene.chess_mover._move_chess(target, grave, grave.unit_grid.get_first_empty_tile())
		attacker.kill_chess.emit(attacker, target)
				
	else:
		#Placeholder for chess passive ability on hit
		target.status = STATUS.HIT
		target.animated_sprite_2d.play("hit")
		await target.animated_sprite_2d.animation_finished
		target.animated_sprite_2d.set_animation("idle")
		target.status = STATUS.IDLE


func take_heal(heal_value: float, healer: Obstacle):
	#Placeholder for chess passive ability on take heal
	if heal_value <= 0:
		return

	var satyr_bonus_level = faction_bonus_manager.get_bonus_level("satyr", team)
	if satyr_bonus_level > 0:
		var satyr_array
		match team:
			1:
				satyr_array = get_tree().get_nodes_in_group("ally").filter(func(node): return node.role == "satyr" and DataManagerSingleton.check_obstacle_valid(node))
			2:
				satyr_array = get_tree().get_nodes_in_group("enemy").filter(func(node): return node.role == "satyr" and DataManagerSingleton.check_obstacle_valid(node))

		var averaged_heal_value = heal_value * 0.3 * satyr_bonus_level
		for node in satyr_array:
			if node == self:
				node.hp += heal_value
			else:			
				node.hp += averaged_heal_value

			if healer != node:
				healer.mp += averaged_heal_value
				heal_taken.emit(node, healer, averaged_heal_value)
		return

	hp += max(0, heal_value)

	if healer != self:
		healer.mp += heal_value
		heal_taken.emit(self, healer, heal_value)

func gain_mp(mp_value: float):
	if mp_value <= 0:
		return
	if faction == "forestProtector" and ["Satyr", "SatyrWarrior"].has(chess_name):
		var satyr_druid_array = get_tree().get_nodes_in_group("ally") if team == 1 else get_tree().get_nodes_in_group("enemy")
		
		satyr_druid_array = satyr_druid_array.filter(
			func(node):
				if DataManagerSingleton.check_obstacle_valid(node) and node.faction == "forestProtector" and node.chess_name == "SatyrDruid":
					return true
				return false
		)
		if satyr_druid_array.size() > 0:
			satyr_druid_array.pick_random().mp += mp_value
			return

	mp += mp_value

func _cast_spell(spell_tgt: Obstacle) -> bool:
	#Placeholder for chess passive ability on cast spell
	var cast_spell_result := false

	if chess_name == "Mage" and faction == "human":
		cast_spell_result = await sun_strike(3)
	elif chess_name == "ArchMage" and faction == "human":
		cast_spell_result = freezing_field(20)
	elif chess_name == "Mage" and faction == "elf":
		cast_spell_result = await sun_strike(chess_level)
		# cast_spell_result = elf_mage_damage(spell_tgt, 0.2, 10, 80)
	elif chess_name == "Queen" and faction == "elf":
		cast_spell_result = freezing_field(20)
		# cast_spell_result = elf_queen_stun(2, 5)
	elif chess_name == "Necromancer" and faction == "undead":
		cast_spell_result = await undead_necromancer_summon("Skeleton", 3)
	elif chess_name == "Demolitionist" and faction == "dwarf":
		cast_spell_result = dwarf_demolitionist_placebomb(100)
	elif chess_name == "SpellSword" and faction == "elf":
		cast_spell_result = mana_transfer()
	elif chess_name == "Satyr" and faction == "forestProtector":
		cast_spell_result = await powerful_heal()
	elif chess_name == "SatyrDruid" and faction == "forestProtector":
		cast_spell_result = await shadow_wave(spell_tgt)
	elif chess_name == "TreantGuard" and faction == "forestProtector":
		cast_spell_result = await entangling_roots()
	elif spell_tgt !=  self:
		cast_spell_result = true

	if cast_spell_result:
		spell_casted.emit(self, skill_name)
		mp = 0

	return cast_spell_result


func chess_apply_damage(): # for animation player only
	if not is_active:
		deal_damage.emit(self, chess_target, damage, "Free_strike", [])

	if status == STATUS.RANGED_ATTACK:
		deal_damage.emit(self, chess_target, damage, "Ranged_attack", [])
	elif status == STATUS.MELEE_ATTACK or not is_active:
		deal_damage.emit(self, chess_target, damage, "Melee_attack", [])

func _apply_heal(heal_target: Obstacle = chess_spell_target, heal_value: float = damage):
	if DataManagerSingleton.check_obstacle_valid(heal_target) and heal_value > 0:
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
	if faction == "dwarf":
		var dwarf_king_array = arena.unit_grid.get_all_units().filter(
			func(obstacle):
				var result := false
				if DataManagerSingleton.check_chess_valid(obstacle) and obstacle.team == team and obstacle.faction == "dwarf" and obstacle.chess_name == "KingMan":
					result = true
				return result
		)
		if dwarf_king_array.size() == 0:
			return
		for king_index in dwarf_king_array:
			var current_dwarf_death_count
			if king_index.get_meta("dwarf_death_count", 0) == 0:
				king_index.set_meta("dwarf_death_count", 1)
			else:
				current_dwarf_death_count = king_index.get_meta("dwarf_death_count", 0)
				king_index.set_meta("dwarf_death_count", current_dwarf_death_count + 1)

			current_dwarf_death_count = king_index.get_meta("dwarf_death_count", 0)
			var effect_instance = ChessEffect.new()
			king_index.effect_handler.add_child(effect_instance)
			effect_instance.register_buff("melee_attack_damage_modifier", current_dwarf_death_count * (2 + king_index.chess_level), 999)
			effect_instance.register_buff("armor_modifier",  current_dwarf_death_count * (4 + king_index.chess_level), 999)
			effect_instance.effect_name = "Avatar"
			effect_instance.effect_type = "Buff"
			effect_instance.effect_description = "Gains damage and armor when allied Dwarves die."
			effect_instance.effect_applier = "Dwarf King Passive Effect"
			king_index.effect_handler.add_to_effect_array(effect_instance)
			await king_index.effect_animation_display("DwarfKingPassive", arena, get_current_tile(king_index)[1], "RightTop")
			king_index.effect_handler.refresh_effects()	

	elif chess_name == "Pixie" and faction == "forestProtector":
		var enemy_spellers = arena.unit_grid.get_all_units().filter(
			func(obstacle):
				if DataManagerSingleton.check_chess_valid(obstacle) and obstacle.role == "speller" and obstacle.team != team:
					if global_position.distance_to(obstacle.global_position) <= 50:
						return true
				return false
		)
		if enemy_spellers.size() > 0:
			for chess_index in enemy_spellers:
				chess_index.mp *= (1 - 0.3 * chess_level)
	
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
		if DataManagerSingleton.check_obstacle_valid(chess_index):
			astar_grid.set_point_solid(get_current_tile(chess_index)[1], true)

	
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
	critical_damage = base_critical_damage + effect_handler.critical_damage_modifier
	evasion_rate = base_evasion_rate + effect_handler.evasion_rate_modifier
	life_steal_rate = base_life_steal_rate + effect_handler.life_steal_rate_modifier
	reflect_damage = base_reflect_damage + effect_handler.reflect_damage_modifier

	if effect_handler.continuous_hp_modifier >= 0:
		_apply_heal(self, max(0, effect_handler.continuous_hp_modifier))
	else:
		# _apply_damage(self, max(0, effect_handler.continuous_hp_modifier))
		deal_damage.emit(self, self, max(0, effect_handler.continuous_hp_modifier), "Continuous_effect", [])

	mp += effect_handler.continuous_mp_modifier

	armor = base_armor + effect_handler.armor_modifier
	speed = base_speed + effect_handler.speed_modifier
	melee_damage = base_melee_damage + effect_handler.melee_attack_damage_modifier
	ranged_damage = base_ranged_damage + effect_handler.ranged_attack_damage_modifier
	attack_range = base_attack_range + effect_handler.attack_rng_modifier
	attack_speed = base_attack_speed + effect_handler.attack_speed_modifier

	max_hp = base_max_hp + effect_handler.max_hp_modifier
	max_mp = base_max_mp + effect_handler.max_mp_modifier

		

func handle_projectile_hit(obstacle:Obstacle, projectile: Projectile):

	var damage_type := "Ranged_attack"
	if obstacle.team != team  and DataManagerSingleton.check_obstacle_valid(obstacle):
		if projectile.animated_sprite_2d.sprite_frames.has_animation("die"):
			var damage_finished = false
			var die_animation = AnimatedSprite2D.new()
			obstacle.add_child(die_animation)
			die_animation.z_index = 60
			die_animation.global_position = obstacle.global_position
			die_animation.sprite_frames = projectile.animated_sprite_2d.sprite_frames.duplicate()
			die_animation.play("die")
		
			var obstacle_tile = obstacle.get_current_tile(obstacle)[1]
			for pos_offset in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
				if obstacle.arena.unit_grid.units.has(obstacle_tile + pos_offset) and obstacle.arena.unit_grid.units[obstacle_tile + pos_offset] is Obstacle:
					var indirect_obstacle = obstacle.arena.unit_grid.units[obstacle_tile + pos_offset]
					if indirect_obstacle.status == indirect_obstacle.STATUS.DIE or indirect_obstacle.visible == false:
						continue
					# await indirect_obstacle.take_damage(damage, attacker)
					deal_damage.emit(self, indirect_obstacle, projectile.damage, damage_type, [])
			damage_finished = true
				
		# await obstacle.take_damage(damage, attacker)
		deal_damage.emit(self, obstacle, projectile.damage, damage_type, [])

func handle_target_death():
	if status == STATUS.RANGED_ATTACK or status == STATUS.MELEE_ATTACK:
		chess_target = null
		attack_target_line.visible = false
		chess_target = _find_new_target(TARGET_CHOICE.CLOSE)
	else:
		chess_target = null
		attack_target_line.visible = false
		chess_target = _find_new_target(chess_target_choice)

	if chess_target:
		if chess_target.is_died.connect(handle_target_death) != OK:
			print("chess_target.is_died connect fail!")
		if line_visible:
			attack_target_line.visible = true

func handle_spell_target_death():
	chess_spell_target = null
	spell_target_line.visible = false

func handle_special_effect(target: Obstacle):
	#Placeholder for chess passive ability on special attack effect
	if is_phantom:
		return
		
	if chess_name == "KingMan" and faction == "human" and is_active and not target.is_phantom:
		var max_attempt_summon_count := 10
		var attempt_summon_count := 0
		var current_summon_count := 0
		while current_summon_count < chess_level and attempt_summon_count < max_attempt_summon_count:
			var tile_offset_array = [Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)]
			tile_offset_array.shuffle()
			var tile_offset_index = tile_offset_array.front()
			var current_tile = get_current_tile(self)[1]
			if arena.is_tile_in_bounds(current_tile + tile_offset_index) and not arena.unit_grid.is_tile_occupied(current_tile + tile_offset_index):					
				var summoned_character = game_root_scene.summon_chess(faction, chess_name, 1, team, arena, current_tile + tile_offset_index)

				summoned_character.is_phantom = true

				if summoned_character.animated_sprite_2d.sprite_frames.has_animation("rise") :
					summoned_character.animated_sprite_2d.play("rise")
					await summoned_character.animated_sprite_2d.animation_finished
				else:
					summoned_character.animated_sprite_2d.play_backwards("die")
					await summoned_character.animated_sprite_2d.animation_finished
					summoned_character.animated_sprite_2d.set_animation("idle")
				current_summon_count += 1
			attempt_summon_count += 1


	elif chess_name == "PrinceMan" and faction == "human" and is_active and target is Chess and not target.is_phantom:
		var max_attempt_summon_count := 10
		var attempt_summon_count := 0
		var current_summon_count := 0
		while current_summon_count < chess_level and attempt_summon_count < max_attempt_summon_count:
			var tile_offset_array = [Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1)]
			tile_offset_array.shuffle()
			var tile_offset_index = tile_offset_array.front()
			var current_tile = get_current_tile(self)[1]
			if arena.is_tile_in_bounds(current_tile + tile_offset_index) and not arena.unit_grid.is_tile_occupied(current_tile + tile_offset_index):					
				var summoned_character = game_root_scene.summon_chess(target.faction, target.chess_name, 1, team, arena, current_tile + tile_offset_index)

				summoned_character.is_phantom = true

				if summoned_character.animated_sprite_2d.sprite_frames.has_animation("rise") :
					summoned_character.animated_sprite_2d.play("rise")
					await summoned_character.animated_sprite_2d.animation_finished
				else:
					summoned_character.animated_sprite_2d.play_backwards("die")
					await summoned_character.animated_sprite_2d.animation_finished
					summoned_character.animated_sprite_2d.set_animation("idle")
				current_summon_count += 1
			attempt_summon_count += 1

	elif chess_name == "Hunter" and faction == "dwarf":
		var effect_instance = ChessEffect.new()
		target.effect_handler.add_child(effect_instance)
		effect_instance.register_buff("duration_only", 0, chess_level)
		effect_instance.effect_name = "HunterMark"
		effect_instance.effect_type = "Debuff"
		effect_instance.effect_applier = chess_name
		effect_instance.effect_description = "Hunter's Mark increases move speed by 1/2/3 towards marked targets."
		target.effect_handler.add_to_effect_array(effect_instance)
		await target.effect_animation_display("DwarfHunterMark", arena, get_current_tile(target)[1], "Center")
		#target.effect_handler.refresh_effects()
		
	elif chess_name == "ShieldBreaker" and faction == "dwarf":
		if randf() <= 0.15 * chess_level:
			var effect_instance = ChessEffect.new()
			target.effect_handler.add_child(effect_instance)
			effect_instance.register_buff("stunned_duration", 0, 1)
			effect_instance.effect_name = "ShieldBreakerKnock"
			effect_instance.effect_type = "Debuff"
			effect_instance.effect_applier = chess_name
			effect_instance.effect_description = "Cannot move, attck or cast spell while stunned."
			target.effect_handler.add_to_effect_array(effect_instance)
			await target.effect_animation_display("ShieldBreakerKnock", arena, get_current_tile(target)[1], "RightTop")
			#target.effect_handler.refresh_effects()			

	elif faction == "forestProtector" and chess_name == "DryadHuntress":
		var target_buff_list = target.effect_handler.effect_list.filter(
			func(effect_index):
				if effect_index.effect_type == "Buff":
					return true
				return false
		)
		if target_buff_list.size() > 0:
			var random_buff = target_buff_list.pick_random()
			target.effect_handler.effect_list.erase(random_buff)
			target.effect_handler.refresh_effects()
			await target.effect_animation_display("ShieldBreakerKnock", arena, get_current_tile(target)[1], "Center")

func connect_to_data_manager():
	# DataManagerSingleton.add_data_to_dict(DataManagerSingleton.in_game_data, ["XX"], value)
	attack_evased.connect(
		func(chess, attacker):
			if chess.team == 1:
				DataManagerSingleton.add_data_to_dict(DataManagerSingleton.in_game_data, ["chess_stat", chess.faction, chess.chess_name, "evase_attack_count"], 1)
	)

	critical_damage_applied.connect(
		func(chess, attacker, damage_value):
			if chess.team == 1:
				DataManagerSingleton.add_data_to_dict(DataManagerSingleton.in_game_data, ["chess_stat", chess.faction, chess.chess_name, "critical_attack_count"], 1)
	)

	spell_casted.connect(
		func(chess, spell_name):
			if chess.team == 1:
				DataManagerSingleton.add_data_to_dict(DataManagerSingleton.in_game_data, ["chess_stat", chess.faction, chess.chess_name, "cast_spell_count"], 1)
	)

	if is_died.connect(DataManagerSingleton.record_death_chess.bind(self)) != OK:
		print("is_died connect fail!")
	if kill_chess.connect(DataManagerSingleton.handle_chess_kill) != OK:
		print("kill_chess connect fail!")

func get_current_tile(obstacle : Obstacle):
	force_update_transform()
	var i = chess_mover._get_play_area_for_position(obstacle.get_global_position())
	var current_tile = chess_mover.play_areas[i].get_tile_from_global(obstacle.global_position)
	return [chess_mover.play_areas[i], current_tile]
	
func has_melee_target():
	if faction == "elf" and chess_name == "ArcaneArcher":
		return null

	for x_index in range(-1, 1):
		for y_index in range(-1, 1):
			if not arena.unit_grid.has_valid_chess(get_current_tile(self)[1] + Vector2i(x_index, y_index)) or not arena.is_tile_in_bounds(get_current_tile(self)[1] + Vector2i(x_index, y_index)):
				continue

			var current_chess = arena.unit_grid.units[get_current_tile(self)[1] + Vector2i(x_index, y_index)]
			if current_chess.team != team:
				return current_chess

	return null

# # Load appropriate animations for the chess
# func effect_animation_display(effect_name):
# 	var effect_animation = AnimatedSprite2D.new()
# 	var effect_animation_path = AssetPathManagerSingleton.get_asset_path("effect_animation", effect_name)
# 	if ResourceLoader.exists(effect_animation_path):
# 		var frames = ResourceLoader.load(effect_animation_path)
# 		for anim_name in frames.get_animation_names():
# 			frames.set_animation_loop(anim_name, false)
# 			frames.set_animation_speed(anim_name, 8.0)
# 		effect_animation.sprite_frames = frames
# 	else:
# 		push_error("Animation resource not found: " + path)
# 	add_child(effect_animation)
# 	effect_animation.z_index = 6
# 	effect_animation.play("default")
# 	await effect_animation.animation_finished
# 	effect_animation.queue_free()

func handle_free_strike(target: Obstacle):
	if status == STATUS.DIE:
		await get_tree().process_frame
		return

	var previous_target = null
	if DataManagerSingleton.check_obstacle_valid(chess_target):
		previous_target	 = chess_target
		
	change_target_to(target) 

	var free_strike_count := 1

	for i in range(free_strike_count):

		if animated_sprite_2d.sprite_frames.has_animation("melee_attack"):
			status = STATUS.MELEE_ATTACK
			melee_attack_animation.play("melee_attack")
			melee_attack_started.emit(self)
			await melee_attack_animation.animation_finished
			if DataManagerSingleton.check_obstacle_valid(target):
				await handle_special_effect(target)

		elif animated_sprite_2d.sprite_frames.has_animation("attack"):
			status = STATUS.MELEE_ATTACK
			animated_sprite_2d.play("attack")
			melee_attack_started.emit(self)
			deal_damage.emit(self, target, damage, "Melee_attack", [])	

			if DataManagerSingleton.check_obstacle_valid(target):
				await handle_special_effect(target)

		else:
			# No required attack animation

			await get_tree().process_frame

		await get_tree().create_timer(0.2).timeout

	status = STATUS.IDLE
	change_target_to(previous_target)
	return
	
func elf_path1_bonus():
	var bonus_level : int
	
	if team ==1:
		bonus_level = faction_bonus_manager.get_bonus_level("elf", team)
		bonus_level = min(bonus_level, game_root_scene.faction_path_upgrade["elf"]["path1"])
	elif team == 2:
		bonus_level = faction_bonus_manager.get_bonus_level("elf", team)

	if  bonus_level > 0 and faction == "elf":

		var effect_instance = ChessEffect.new()
		effect_handler.add_child(effect_instance)
		effect_instance.register_buff("melee_attack_damage_modifier", -1.0 * (base_melee_damage/(bonus_level + 1)), 999)
		effect_instance.register_buff("ranged_attack_damage_modifier", -1.0 * (base_ranged_damage/(bonus_level + 1)), 999)
		effect_instance.register_buff("attack_speed_modifier", bonus_level, 999)
		effect_instance.effect_name = "Swift - Level " + str(bonus_level)
		effect_instance.effect_type = "Faction Bonus"
		effect_instance.effect_applier = "Elf path1 Faction Bonus"
		effect_instance.effect_description = "Elf allies gain attack speed bonus, and attack damage decreased."
		effect_handler.add_to_effect_array(effect_instance)
		await effect_animation_display("ElfSwift", arena, get_current_tile(self)[1], "RightTop")
		effect_handler.refresh_effects()

func elf_path3_bonus():
	var bonus_level : int
	
	if chess_target.team == 1:
		bonus_level = faction_bonus_manager.get_bonus_level("elf", chess_target.team)
		bonus_level = min(bonus_level, game_root_scene.faction_path_upgrade["elf"]["path3"])
	elif chess_target.team == 2:
		bonus_level = faction_bonus_manager.get_bonus_level("elf", chess_target.team)

	if bonus_level == 2 and randf() >= 0.5 and target_evased_attack:
		if DataManagerSingleton.check_chess_valid(chess_target):
			await chess_target.handle_free_strike(self)
	elif bonus_level == 3 and randf() >= 0.5:
		if DataManagerSingleton.check_chess_valid(chess_target):
			await chess_target.handle_free_strike(self)


func dwarf_path1_bonus():
	var bonus_level : int
	
	if team ==1:
		bonus_level = faction_bonus_manager.get_bonus_level("dwarf", team)
		bonus_level = min(bonus_level, game_root_scene.faction_path_upgrade["dwarf"]["path1"])
	elif team == 2:
		bonus_level = faction_bonus_manager.get_bonus_level("dwarf", team)
		
		
	#var bonus_level = faction_bonus_manager.get_bonus_level("dwarf", team)
	var b2b_ally_dwarf := false

	if not (faction == "dwarf" and bonus_level > 0):
		return

	for offset_index in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		if arena.is_tile_in_bounds(offset_index + get_current_tile(self)[1]) and DataManagerSingleton.check_chess_valid(arena.unit_grid.units[offset_index + get_current_tile(self)[1]]):
			var neighbor_chess = arena.unit_grid.units[offset_index + get_current_tile(self)[1]]
			if neighbor_chess.team == team and neighbor_chess.faction == "dwarf":
				b2b_ally_dwarf = true
				break
	var armor_bonus = 0
	armor_bonus += (2 * bonus_level)

	if b2b_ally_dwarf:
		armor_bonus += 2

	if total_movement == 0:
		armor_bonus += 2

	var effect_instance = ChessEffect.new()
	effect_instance.register_buff("armor_modifier", armor_bonus , 1)
	effect_instance.register_buff("refelect_damage_modifier", (bonus_level * 5 if bonus_level > 1 else 0) , 1)
	effect_instance.effect_name = "Fortress - Level " + str(bonus_level)
	effect_instance.effect_type = "Faction Bonus"
	effect_instance.effect_applier = "Dwarf path1 Faction Bonus"
	effect_instance.effect_description = "Dwarves gain armor bonus, relect damage and extra armor bonus when base to base with another ally dwarf."
	effect_handler.add_to_effect_array(effect_instance)
	effect_handler.add_child(effect_instance)
	await effect_animation_display("DwarfFortress", arena, get_current_tile(self)[1], "Center")
	effect_handler.refresh_effects()

func dwarf_path2_bonus():
	var bonus_level : int
	
	if team ==1:
		bonus_level = faction_bonus_manager.get_bonus_level("dwarf", team)
		bonus_level = min(bonus_level, game_root_scene.faction_path_upgrade["dwarf"]["path2"])
	elif team == 2:
		bonus_level = faction_bonus_manager.get_bonus_level("dwarf", team)
		
	#var bonus_level = faction_bonus_manager.get_bonus_level("dwarf", team)

	if not (faction == "dwarf" and bonus_level > 0):
		return

	var damage_bonus = 0
	var armor_bonus = 0
	var life_steal_bonus = 0

	damage_bonus += (bonus_level + 2)

	if hp <= 0.33 * max_hp:
		match bonus_level:
			2:
				damage_bonus += (armor * 0.5)
				armor_bonus = -(armor * 0.5)
				life_steal_bonus = 0.5
			3:
				damage_bonus += armor
				armor_bonus = -armor
				life_steal_bonus = 1.0

	var effect_instance = ChessEffect.new()
	effect_instance.register_buff("melee_attack_damage_modifier", damage_bonus, 1)
	effect_instance.register_buff("armor_modifier", armor_bonus, 999)
	effect_instance.register_buff("life_steal_rate_modifier", life_steal_bonus, 1)
	# effect_instance.stunned_duration = spell_duration
	effect_instance.effect_name = "Berserker - Level " + str(bonus_level)
	effect_instance.effect_type = "Faction Bonus"
	effect_instance.effect_applier = "Dwarf path2 Faction Bonus"
	effect_instance.effect_description = "Dwarf will give up armor and gain attack damage."
	effect_handler.add_to_effect_array(effect_instance)
	effect_handler.add_child(effect_instance)
	await effect_animation_display("DwarfBerserker", arena, get_current_tile(self)[1], "RightTop")

func dwarf_path3_bonus():
	var bonus_level : int
	
	if team ==1:
		bonus_level = faction_bonus_manager.get_bonus_level("dwarf", team)
		bonus_level = min(bonus_level, game_root_scene.faction_path_upgrade["dwarf"]["path3"])
	elif team == 2:
		bonus_level = faction_bonus_manager.get_bonus_level("dwarf", team)

	if bonus_level > 0 and faction == "dwarf":
		var effect_instance = ChessEffect.new()
		effect_instance.register_buff("speed_modifier", bonus_level, 1)
		# effect_instance.stunned_duration = spell_duration
		effect_instance.effect_name = "March - Level " + str(bonus_level)
		effect_instance.effect_type = "Faction Bonus"
		effect_instance.effect_applier = "Dwarf path3 Faction Bonus"
		effect_instance.effect_description = "Dwarf allied gain speed bonus at first turn."
		effect_handler.add_to_effect_array(effect_instance)
		effect_handler.add_child(effect_instance)
		await effect_animation_display("DwarfMarch", arena, get_current_tile(self)[1], "RightTop")

func warrior_bonus():
	var bonus_level = faction_bonus_manager.get_bonus_level("warrior", team)
	
	if bonus_level <= 0 or role != "warrior":
		return

	if target_changed:
		set_meta("warrior_damage_bonus", 0)
		return

	if get_meta("warrior_damage_bonus") == null:
		set_meta("warrior_damage_bonus", 0)
	else:
		var current_warrior_damage_bonus = get_meta("warrior_damage_bonus", 0)
		current_warrior_damage_bonus += bonus_level
		set_meta("warrior_damage_bonus", current_warrior_damage_bonus)

	melee_damage += get_meta("warrior_damage_bonus")


func knight_bonus():
	var bonus_level = faction_bonus_manager.get_bonus_level("knight", team)
	
	if bonus_level <= 0 or role != "knight":
		return

	if total_movement >=5:
		melee_damage *= (1 + 0.15 * bonus_level)

func pegasus_rider_movement():
	var fly_result := false
	animated_sprite_2d.play("fly")
	for x_index in [-1, 0, 1]:
		for y_index in [-1, 0, 1]:
			var current_tile = Vector2i(x_index, y_index) + get_current_tile(chess_target)[1]
			var chess_target_tile = chess_target.get_current_tile(chess_target)[1]
			if arena.is_tile_in_bounds(current_tile) and not arena.unit_grid.is_tile_occupied(current_tile) and max((current_tile - chess_target_tile).x, (current_tile - chess_target_tile).y) <= speed:
				var target_pos = arena.get_global_from_tile(current_tile) - get_parent().global_position
				await chess_mover.tween_move_chess(self, arena, target_pos)
				fly_result = true
				total_movement = max((current_tile - chess_target_tile).x, (current_tile - chess_target_tile).y)
				return fly_result
	return fly_result

func sun_strike(strike_count: int) -> bool:
	var chess_affected := true
	var remain_strike_count = strike_count
	var arena_size = arena.unit_grid.size
	var rand_x
	var rand_y
	var damage_count:= 0
	var rand_f : float
	#while(remain_strike_count > 0 and damage_count < 3):
		#
		#rand_x = randi_range(0, arena_size.x - 1)
		#rand_y = randi_range(0, arena_size.y - 1)
		#await effect_animation_display("FireBeam", arena, Vector2i(rand_x, rand_y))
#
		#if DataManagerSingleton.check_obstacle_valid(arena.unit_grid.units[Vector2i(rand_x, rand_y)]):
			#var current_spell_target = arena.unit_grid.units[Vector2i(rand_x, rand_y)]
			#deal_damage.emit(self, current_spell_target, 50, "Magic_attack", [])
			#damage_count += 1
			#
		#strike_count -= 1
	
	var offset_possible : Dictionary

	match chess_level:
		1:
			offset_possible = 	{
				0.4 : Vector2i(0, 0),
				0.5 : Vector2i(-1, 0),
				0.6 : Vector2i(1, 0),
				0.7 : Vector2i(0, -1),
				0.8 : Vector2i(0, 1),
				0.85 : Vector2i(-1, -1),
				0.9 : Vector2i(-1, 1),
				0.95 : Vector2i(1, -1),
				1 : Vector2i(1, 1)
				}
		2:
			offset_possible = 	{
				0.5 : Vector2i(0, 0),
				0.575 : Vector2i(-1, 0),
				0.65 : Vector2i(1, 0),
				0.725 : Vector2i(0, -1),
				0.8 : Vector2i(0, 1),
				0.85 : Vector2i(-1, -1),
				0.9 : Vector2i(-1, 1),
				0.95 : Vector2i(1, -1),
				1 : Vector2i(1, 1)
				}
		3:
			offset_possible = 	{
				0.6 : Vector2i(0, 0),
				0.7 : Vector2i(-1, 0),
				0.8 : Vector2i(1, 0),
				0.9 : Vector2i(0, -1),
				1.0 : Vector2i(0, 1)
				}
	
	var arena_units = arena.unit_grid.get_all_units()
	for i in range(strike_count):
		if randf() > 0.5:
			continue
		for obstacle_index in arena_units:
			if obstacle_index.team == team:
				continue
			var current_tile = obstacle_index.get_current_tile(obstacle_index)[1]
			rand_f = randf()
			for offset_index in offset_possible.keys():
				if rand_f <= offset_index:
					current_tile = current_tile + offset_possible[offset_index]
					break
			await effect_animation_display("FireBeam", arena, current_tile, "Bottom")
			if not arena.unit_grid.units.has(current_tile):
				continue
				
			if DataManagerSingleton.check_obstacle_valid(arena.unit_grid.units[current_tile]):
				var current_spell_target = arena.unit_grid.units[current_tile]
				deal_damage.emit(self, current_spell_target, 15 + 5 * chess_level, "Magic_attack", [])

		
	#var current_strike
	#for i in range(strike_count):
		#var current_strike_count = randi_range(3, 5)
		#for j in range(current_strike_count):
			#rand_x = randi_range(0, arena_size.x - 1)
			#rand_y = randi_range(0, arena_size.y - 1)			
			#current_strike = await effect_animation_display("FireBeam", arena, Vector2i(rand_x, rand_y))
			#if DataManagerSingleton.check_obstacle_valid(arena.unit_grid.units[Vector2i(rand_x, rand_y)]):
				#var current_spell_target = arena.unit_grid.units[Vector2i(rand_x, rand_y)]
				#deal_damage.emit(self, current_spell_target, 50, "Magic_attack", [])		

	return chess_affected

func freezing_field(arrow_count: int) -> bool:
	var chess_affected := true
	var arraow_degree_interval = 360.0 / arrow_count
	var arraow_degree := 0.0
	for i in range(arrow_count):
		var spell_projectile = _launch_projectile_to_degree(arraow_degree)
		spell_projectile.projectile_animation = "Ice"
		spell_projectile.damage = 5 + 5 * chess_level
		spell_projectile.damage_type = "Magic_attack"
		spell_projectile.projectile_hit.connect(
			func(obstacle, projectile):
				deal_damage.emit(self, obstacle, spell_projectile.damage, "Magic_attack", [])
				if DataManagerSingleton.check_obstacle_valid(obstacle):
					var effect_instance = ChessEffect.new()
					obstacle.effect_handler.add_child(effect_instance)
					effect_instance.register_buff("speed_modifier", -1, 2)
					# effect_instance.speed_modifier = -1
					# effect_instance.speed_modifier_duration = 2
					effect_instance.register_buff("armor_modifier", -3, 2)
					# effect_instance.armor_modifier = -3
					# effect_instance.armor_modifier_duration = 2
					effect_instance.effect_name = "SpellFreezing"
					effect_instance.effect_type = "Debuff"
					effect_instance.effect_applier = "Human ArchMage Spell Freezing"
					effect_instance.effect_description = "Chess hit speed and armor will reduced."
					obstacle.effect_handler.add_to_effect_array(effect_instance)
		)
		arraow_degree += arraow_degree_interval

	return chess_affected
	 
func mana_transfer() -> bool:
	var chess_affected := false
	var all_chesses = arena.unit_grid.get_all_units()
	var all_ally = all_chesses.filter(func(obstacle): return (DataManagerSingleton.check_chess_valid(obstacle) and obstacle != self and obstacle.team == team and obstacle.animated_sprite_2d.sprite_frames.has_animation("spell")))
	if all_ally.size() == 0:
		chess_affected = false
	elif all_ally.size() == 1:
		all_ally[0].gain_mp(mp * 0.3 * chess_level)
		chess_affected =  true
	else:
		all_ally.sort_custom(
			func(a, b):
				return a.mp >= b.mp			
		)
		all_ally.front().gain_mp(mp * 0.2 * chess_level)
		chess_affected =  true
	return chess_affected
	
func random_heal(value: float, healer: Obstacle):
	if not (chess_name == "Queen" and faction == "elf"):
		return
	var all_chesses = arena.unit_grid.get_all_units()
	var all_ally = all_chesses.filter(func(obstacle): return (DataManagerSingleton.check_chess_valid(obstacle) and obstacle.team == team))
	if all_ally.size() == 0:
		return	
	all_ally.shuffle()
	all_ally.front().take_heal(value * 0.3 * healer.chess_level, healer)

func powerful_heal():
	if not (chess_name == "Satyr" and faction == "forestProtector"):
		return
	var all_chesses = arena.unit_grid.get_all_units()
	var all_ally = all_chesses.filter(func(obstacle): return (DataManagerSingleton.check_chess_valid(obstacle) and obstacle.team == team))
	all_ally.sort_custom(
		func(a, b):
			return (a.max_hp - a.hp) >= (b.max_hp - b.hp)
	)
	if all_ally.size() < 0:
		return false
	var heal_target = all_ally.pop_front()
	_apply_heal(heal_target, (25 + 25 * chess_level) * (2 if heal_target.role == "satyr" else 1))
	return true

func shadow_wave(spell_target: Obstacle) -> bool:
	var spell_projectile = _launch_projectile_to_target(spell_target)
	spell_projectile.projectile_animation = "Ice"
	spell_projectile.penetration = 999
	spell_projectile.damage = 999
	spell_projectile.max_distance = 999000
	var max_jump_count := 2 + chess_level
	var current_jump_count = max_jump_count
	var obstacle_affect := []
	spell_projectile.projectile_hit.connect(
		func(obstacle, projectile):
			if obstacle_affect.has(obstacle):
				return
			if obstacle.team == team:
				_apply_heal(obstacle, 5 * chess_level)
			else:
				deal_damage.emit(self, obstacle, 5 * chess_level, "Magic_attack", [])
			obstacle_affect.append(obstacle)
			current_jump_count -= 1
			if current_jump_count <= 0:
				await get_tree().create_timer(0.5).timeout
				projectile.queue_free()
				return
			else:
				var all_chesses = arena.unit_grid.get_all_units().filter(
					func(obstacle1): 
						if obstacle_affect.has(obstacle1):
							return false
						if obstacle1.global_position.distance_to(obstacle.global_position) > 100:
							return false
						return true
				)
				var new_target = all_chesses.pick_random()
				spell_projectile.direction = (new_target - obstacle).normalized()
	)
	return true

func entangling_roots() -> bool:
	var all_chesses = arena.unit_grid.get_all_units()
	var all_enemy = all_chesses.filter(func(obstacle): return (DataManagerSingleton.check_chess_valid(obstacle) and obstacle.team != team))
	var enemy_nearby = all_enemy.filter(
		func(node):
			return node.global_position.distance_to(global_position) < 50 * chess_level
	)
	if enemy_nearby.size() <= 0:
		return false
	for chess_index in enemy_nearby:
		var effect_instance = ChessEffect.new()
		chess_index.effect_handler.add_child(effect_instance)
		effect_instance.register_buff("speed_modifier", -2, 2)
		effect_instance.effect_name = "EntaglingRoots"
		effect_instance.effect_type = "Debuff"
		effect_instance.effect_applier = "ForestProtector TreantGuard Spell EntaglingRoots"
		effect_instance.effect_description = "The Treant's roots erupt, snaring nearby enemies and slowing their movement."
		chess_index.effect_handler.add_to_effect_array(effect_instance)	
		chess_index.damage_taken.connect(
			func(target, attacker):
				target._apply_heal(self, target.max_hp * 0.05 * chess_level)
		)
	return true

func human_mage_taunt(spell_duration: int) -> bool:
	var chess_affected := true

	var effect_instance = ChessEffect.new()
	effect_instance.register_buff("taunt", 0, spell_duration)
	# effect_instance.taunt_duration = spell_duration
	effect_instance.effect_name = "Taunt"
	effect_instance.effect_type = "Buff"
	effect_instance.effect_applier = "Human Mage Spell Taunt"
	effect_instance.effect_description = "Taunt chess will be set as target before other chesses."
	effect_handler.add_to_effect_array(effect_instance)
	effect_handler.add_child(effect_instance)

	var arena_unitgrid = arena.unit_grid.units
	# var affected_index_array = area_effect_handler.find_affected_units(position_id, 0, area_effect_handler.human_mage_taunt_template)
	var affected_index_array = area_effect_handler.find_affected_units(get_current_tile(self)[1], 0, area_effect_handler.default_template)
	
	if affected_index_array.size() == 0:
		return false

	for affected_index in affected_index_array:
			if arena_unitgrid.has(affected_index) and is_instance_valid(arena_unitgrid[affected_index]):
				if arena_unitgrid[affected_index] is Chess and arena_unitgrid[affected_index].team != team:
					arena_unitgrid[affected_index].change_target_to(self)
					chess_affected = true
	return chess_affected

func human_archmage_heal(spell_duration: int, heal_value: float) -> bool:
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
					effect_instance.register_buff("continuous_hp_modifier", heal_value, spell_duration)
					# effect_instance.continuous_hp_modifier = heal_value
					# effect_instance.continuous_hp_modifier_duration = spell_duration
					effect_instance.effect_name = "Heal"
					effect_instance.effect_type = "Buff"
					effect_instance.effect_applier = chess_name
					effect_instance.effect_description = "Continuously heal."
					arena_unitgrid[affected_index].effect_handler.add_to_effect_array(effect_instance)
					arena_unitgrid[affected_index].effect_handler.add_child(effect_instance)

					chess_affected =  true
	return chess_affected

func elf_queen_stun(spell_duration: int, damage_value: float) -> bool:
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
				effect_instance.register_buff("stunned", 0, spell_duration)
				# effect_instance.stunned_duration = spell_duration
				effect_instance.effect_name = "Stun"
				effect_instance.effect_type = "Debuff"
				effect_instance.effect_applier = chess_name
				effect_instance.effect_description = "Cannot move, attck or cast spell while stunned."
				arena_unitgrid[affected_index].effect_handler.add_to_effect_array(effect_instance)
				arena_unitgrid[affected_index].effect_handler.add_child(effect_instance)

				# _apply_damage(arena_unitgrid[affected_index], damage_value)
				deal_damage.emit(self, arena_unitgrid[affected_index], damage_value, "Magic_attack", [])

				chess_affected =  true
	return chess_affected

func elf_mage_damage(spell_target:Obstacle, damage_threshold: float, min_damage_value: int, spell_range: int) -> bool:
	var chess_affected := false
	if spell_target.status != STATUS.DIE and spell_target.team != team and spell_target.global_position.distance_to(global_position) <= spell_range:

		if spell_target.hp <= spell_target.max_hp * damage_threshold:
			# _apply_damage(spell_target, spell_target.hp)
			deal_damage.emit(self, spell_target, spell_target.hp, "Magic_attack", [])
			
		else:
			# _apply_damage(spell_target, min_damage_value)
			deal_damage.emit(self, spell_target, min_damage_value, "Magic_attack", [])

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
					var summoned_character = game_root_scene.summon_chess("undead", summoned_chess_name, 1, team, arena, Vector2i(rand_x, rand_y))

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
					var summoned_character = game_root_scene.summon_chess("dwarf", "Bomb", 1, team, arena, Vector2i(rand_x, rand_y))	
					summoned_character.obstacle_counter = 2
					summoned_character.obstacle_level = 1 + chess_level

					return true				
	return false	

func get_temp_copy() -> Chess:
	var temp_copy = Chess.new()
	temp_copy.faction = faction
	temp_copy.chess_name = chess_name
	return temp_copy
