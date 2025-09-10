extends Control
class_name VirtualCursor

signal cursor_clicked(position: Vector2)
signal cursor_moved(position: Vector2)

# 移除 @onready，在 _ready() 中初始化
var cursor_sprite: TextureRect
var click_animation: AnimationPlayer

var current_cursor_type: String = "default"
var cursor_textures: Dictionary = {}
var hotspot_offsets: Dictionary = {}
var is_clicking: bool = false

func _ready():
	# 先获取节点引用
	cursor_sprite = get_node_or_null("cursor_sprite")
	click_animation = get_node_or_null("click_animation")
	
	# 检查关键节点是否存在
	if not cursor_sprite:
		push_error("VirtualCursor: cursor_sprite node not found! Check node name and path.")
		# 创建一个临时的 TextureRect 作为备用
		cursor_sprite = TextureRect.new()
		add_child(cursor_sprite)
		cursor_sprite.name = "FallbackCursorSprite"
	
	# 初始化系统
	load_cursor_textures()
	set_cursor_type("default")
	setup_cursor_system()
	
	# 设置显示属性
	z_index = 999
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta):
	if not cursor_sprite:
		return
	# Update cursor position to follow mouse
	global_position = get_global_mouse_position()
		
	if global_position.x <= 0 or global_position.x >= 576 or global_position.y <= 0 or global_position.y >= 324:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		
	apply_hotspot_offset()

func setup_cursor_system():
	# Hide system cursor

	
	# Ensure cursor sprite settings
	if cursor_sprite:
		cursor_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		cursor_sprite.stretch_mode = TextureRect.STRETCH_KEEP
		cursor_sprite.show()
	else:
		push_error("cursor_sprite is null in setup_cursor_system")

func load_cursor_textures():
	# Load different cursor textures
	cursor_textures = {
		"default": preload("res://asset/cursor/cursors/cursor1.png"),
		"pointer": preload("res://asset/cursor/cursors/cursor1.png"),
		"grab": preload("res://asset/cursor/cursors/cursor1.png"),
		"grabbing": preload("res://asset/cursor/cursors/cursor1.png"),
		"text": preload("res://asset/cursor/cursors/cursor1.png"),
		"crosshair": preload("res://asset/cursor/cursors/cursor1.png"),
		"loading": preload("res://asset/cursor/color/cursors__15.png")
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
	if not cursor_sprite:
		push_error("cursor_sprite is null in set_cursor_type")
		return
		
	if type in cursor_textures:
		current_cursor_type = type
		cursor_sprite.texture = cursor_textures[type]
		apply_hotspot_offset()

func apply_hotspot_offset():
	if not cursor_sprite:
		return
		
	if current_cursor_type in hotspot_offsets:
		var offset = hotspot_offsets[current_cursor_type]
		cursor_sprite.position = -offset

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_click_animation()
				cursor_clicked.emit(get_global_mouse_position())
			else:
				end_click_animation()
	
	elif event is InputEventMouseMotion:
		cursor_moved.emit(get_global_mouse_position())
		
	# 确保暂停按键能够被处理
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()

func start_click_animation():
	is_clicking = true
	if click_animation and click_animation.has_animation("click"):
		click_animation.play("click")
	elif click_animation:
		push_warning("click_animation has no 'click' animation")

func end_click_animation():
	is_clicking = false
	if click_animation and click_animation.has_animation("release"):
		click_animation.play("release")
	elif click_animation:
		push_warning("click_animation has no 'release' animation")
