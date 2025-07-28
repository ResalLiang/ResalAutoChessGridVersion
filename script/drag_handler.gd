extends Node2D

@onready var hero: Hero = $".."
@onready var area_2d: Area2D = $"../Area2D"
@onready var attack_timer: Timer = $"../attack_timer"
@onready var idle_timer: Timer = $"../idle_timer"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"


var dragging := false           # Is character being dragged
var starting_position: Vector2  # Original position before dragging
var offset := Vector2.ZERO      # Drag offset from mouse position

@export var dragging_enabled := true

const CHARACT_Z_INDEX = 2  # Default rendering layer

# ========================
# Signal Definitions
# ========================
# Dragging signals
signal drag_canceled(starting_position: Vector2) # Emitted when drag is canceled
signal drag_started                              # Emitted when drag starts
signal dropped                                   # Emitted when character is dropped

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Connect signals
	area_2d.input_event.connect(_on_target_input_event)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	# Handle dragging if active
	if dragging:
		_handle_dragging()

func _input(event: InputEvent) -> void:
	# Handle drag cancellation
	if dragging and event.is_action_pressed("cancel_dragging"):
		_cancel_dragging()
	# Handle character drop
	elif dragging and event.is_action_pressed("drop"):
		_drop()

# ========================
# Dragging Functions
# ========================
# Start dragging the character
func _start_dragging():
	if not dragging_enabled:
		return
		
	dragging = true
	starting_position = hero.global_position
	add_to_group("dragging")
	hero.z_index = 99  # Bring to front during drag
	offset = hero.global_position - get_global_mouse_position()
	drag_started.emit()
	hero.stat = hero.STATUS.JUMP
	attack_timer.stop()  # Stop attacking during drag

# End dragging (common operations)
func _end_dragging():
	dragging = false
	remove_from_group("dragging")
	z_index = CHARACT_Z_INDEX  # Restore default Z-index
	hero.stat = hero.STATUS.IDLE

# Cancel dragging and return to start position
func _cancel_dragging():
	_end_dragging()
	global_position = starting_position
	drag_canceled.emit(starting_position)
	hero.animated_sprite_2d.play("idle")

# Drop character at current position
func _drop():
	_end_dragging()
	dropped.emit()
	hero.animated_sprite_2d.play("idle")
	idle_timer.start()  # Restart idle timer
	
	
# ========================
# Signal Handlers
# ========================
# Handle input events on the character area
func _on_target_input_event(_viewport, event, _shape_idx):
	if not dragging_enabled:
		return
		
	# Check if another object is being dragged
	if get_tree().get_first_node_in_group("dragging"):
		return
		
	# Start dragging on select input
	if event.is_action_pressed("select") and not dragging:
		_start_dragging()
		


# Handle dragging behavior
func _handle_dragging():
	# Follow mouse position with offset
	hero.global_position = get_global_mouse_position() + offset
	# Play jump animation during drag
	animated_sprite_2d.play("jump")
