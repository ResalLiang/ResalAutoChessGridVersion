extends Control
class_name Main

@onready var menu_container: Control
@onready var game_container: Control  
@onready var transition_layer: ColorRect

# 当前活跃的场景
var current_scene: Node = null

func _ready():
	# 初始化显示主菜单
	show_main_menu()

# 显示主菜单
func show_main_menu():
	_transition_to_scene("res://scenes/menus/MainMenu.tscn", menu_container)

# 显示游戏场景
func show_game():
	_transition_to_scene("res://scenes/Game.tscn", game_container)

# 显示设置菜单
func show_settings():
	_transition_to_scene("res://scenes/menus/SettingsMenu.tscn", menu_container)

# 场景切换核心方法 - 这是自定义方法
func _transition_to_scene(scene_path: String, container: Control):
	# 显示过渡效果
	transition_layer.show()
	var tween = create_tween()
	tween.tween_property(transition_layer, "modulate.a", 1.0, 0.3)
	await tween.finished
	
	# 清理当前场景
	if current_scene:
		current_scene.queue_free()
		await current_scene.tree_exited
	
	# 加载新场景
	var new_scene = load(scene_path).instantiate()
	container.add_child(new_scene)
	current_scene = new_scene
	
	# 隐藏其他容器，显示目标容器
	menu_container.hide()
	game_container.hide()
	container.show()
	
	# 淡出过渡效果
	tween = create_tween()
	tween.tween_property(transition_layer, "modulate:a", 0.0, 0.3)
	await tween.finished
	transition_layer.hide()

extends Node

@onready var pause_menu: Control = $UI/PauseMenu
@onready var settings_menu: Control = $UI/SettingsMenu

func _ready():
	# 设置暂停菜单不受暂停影响
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	settings_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 初始状态隐藏菜单
	pause_menu.hide()
	settings_menu.hide()

func _input(event):
	# ESC键暂停/继续
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	get_tree().paused = true
	pause_menu.show()

func resume_game():
	get_tree().paused = false
	pause_menu.hide()
	settings_menu.hide()

func show_settings():
	pause_menu.hide()
	settings_menu.show()

func back_to_pause_menu():
	settings_menu.hide()
	pause_menu.show()


extends Control
class_name VirtualCursor

signal cursor_clicked(position: Vector2)
signal cursor_moved(position: Vector2)

@onready var cursor_sprite: TextureRect = $CursorSprite
@onready var click_animation: AnimationPlayer = $ClickAnimation

var current_cursor_type: String = "default"
var cursor_textures: Dictionary = {}
var hotspot_offsets: Dictionary = {}
var is_clicking: bool = false

func _ready():
	# Set up the cursor
	setup_cursor_system()
	load_cursor_textures()
	set_cursor_type("default")
	
	# Make sure cursor is always on top
	z_index = 1000
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
	# Update cursor position to follow mouse
	global_position = get_global_mouse_position()
	apply_hotspot_offset()

func setup_cursor_system():
	# Hide system cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	
	# Ensure cursor sprite settings
	cursor_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	cursor_sprite.stretch_mode = TextureRect.STRETCH_KEEP

func load_cursor_textures():
	# Load different cursor textures
	cursor_textures = {
		"default": preload("res://cursors/default.png"),
		"pointer": preload("res://cursors/pointer.png"),
		"grab": preload("res://cursors/grab.png"),
		"grabbing": preload("res://cursors/grabbing.png"),
		"text": preload("res://cursors/text.png"),
		"crosshair": preload("res://cursors/crosshair.png"),
		"loading": preload("res://cursors/loading.png")
	}
	
	# Define hotspot offsets for each cursor type
	hotspot_offsets = {
		"default": Vector2(0, 0),
		"pointer": Vector2(2, 0),
		"grab": Vector2(8, 8),
		"grabbing": Vector2(8, 8),
		"text": Vector2(8, 12),
		"crosshair": Vector2(8, 8),
		"loading": Vector2(8, 8)
	}

func set_cursor_type(type: String):
	if type in cursor_textures:
		current_cursor_type = type
		cursor_sprite.texture = cursor_textures[type]
		apply_hotspot_offset()

func apply_hotspot_offset():
	if current_cursor_type in hotspot_offsets:
		var offset = hotspot_offsets[current_cursor_type]
		cursor_sprite.position = -offset

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_click_animation()
				cursor_clicked.emit(get_global_mouse_position())
			else:
				end_click_animation()
	
	elif event is InputEventMouseMotion:
		cursor_moved.emit(get_global_mouse_position())

func start_click_animation():
	is_clicking = true
	if click_animation and click_animation.has_animation("click"):
		click_animation.play("click")

func end_click_animation():
	is_clicking = false
	if click_animation and click_animation.has_animation("release"):
		click_animation.play("release")

extends Node
class_name CursorManager

static var instance: CursorManager
var virtual_cursor: VirtualCursor
var cursor_scene: PackedScene = preload("res://ui/VirtualCursor.tscn")

func _ready():
	instance = self
	setup_virtual_cursor()

func setup_virtual_cursor():
	# Create virtual cursor instance
	virtual_cursor = cursor_scene.instantiate()
	
	# Add to scene tree at highest level
	get_tree().root.add_child(virtual_cursor)
	virtual_cursor.cursor_clicked.connect(_on_cursor_clicked)
	virtual_cursor.cursor_moved.connect(_on_cursor_moved)

func _on_cursor_clicked(position: Vector2):
	# Handle click events if needed
	print("Cursor clicked at: ", position)

func _on_cursor_moved(position: Vector2):
	# Handle mouse movement if needed
	pass

# Static methods for easy access
static func set_cursor(type: String):
	if instance and instance.virtual_cursor:
		instance.virtual_cursor.set_cursor_type(type)

static func show_cursor():
	if instance and instance.virtual_cursor:
		instance.virtual_cursor.show()

static func hide_cursor():
	if instance and instance.virtual_cursor:
		instance.virtual_cursor.hide()

static func get_cursor_position() -> Vector2:
	if instance and instance.virtual_cursor:
		return instance.virtual_cursor.global_position
	return Vector2.ZERO

extends Node
class_name GameSpeedController

signal speed_changed(new_speed: float)

var default_speed: float = 1.0
var current_speed: float = 1.0:
	set(value):
		if value > 0:
			current_speed = value
		else:
			current_speed = 1.0

func _ready():
	# Ensure initial speed
	Engine.time_scale = default_speed

func _input(event):
	# Debug hotkeys
	if event.is_action_pressed("speed_up"):
		increase_speed()
	elif event.is_action_pressed("speed_down"):
		decrease_speed()
	elif event.is_action_pressed("reset_speed"):
		reset_speed()

# Set game speed
func set_speed(speed: float):
	# Limit speed range
	speed = clampf(speed, 0.0, 5.0)
	
	if speed != current_speed:
		current_speed = speed
		Engine.time_scale = speed
		speed_changed.emit(speed)
		print("Game speed: ", speed)

# Increase speed
func increase_speed(increment: float = 0.25):
	set_speed(current_speed + increment)

# Decrease speed
func decrease_speed(decrement: float = 0.25):
	set_speed(current_speed - decrement)

# Reset speed
func reset_speed():
	set_speed(default_speed)

# Get current speed
func get_current_speed() -> float:
	return current_speed

# Preset speed functions
func apply_slow_motion(duration: float = 2.0):
	set_speed(0.3)
	# Return to normal after duration
	await get_tree().create_timer(duration * Engine.time_scale).timeout
	reset_speed()

func apply_bullet_time(duration: float = 1.0):
	set_speed(0.1)
	await get_tree().create_timer(duration * Engine.time_scale).timeout
	reset_speed()
