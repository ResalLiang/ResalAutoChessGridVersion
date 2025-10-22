extends Node2D
class_name DragHandler

@onready var dragging_item: Node2D = $".."
@onready var area_2d: Area2D = $"../Area2D"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
@onready var drag_timer: Timer = $drag_timer
@onready var drop_timer: Timer = $drop_timer


var dragging := false           # Is character being dragged
var starting_position: Vector2  # Original position before dragging
var offset := Vector2.ZERO      # Drag offset from mouse position

@export var dragging_enabled := true

const CHARACT_Z_INDEX = 50  # Default rendering layer

# ========================
# Signal Definitions
# ========================
# Dragging signals
signal drag_canceled(starting_position: Vector2, action: String) # Emitted when drag is canceled
signal drag_started(starting_position: Vector2, action: String)                              # Emitted when drag starts
signal drag_dropped(starting_position: Vector2, action: String)                                   # Emitted when character is dropped
signal is_clicked() # for chess information show

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	drag_timer.set_wait_time(0.3)
	drag_timer.set_one_shot(true)
	drag_timer.set_autostart(true)
	drag_timer.start()

	drop_timer.set_wait_time(0.3)
	drop_timer.set_one_shot(true)
	drop_timer.set_autostart(true)
	drop_timer.start()

	# Connect signals
	if area_2d.input_event.connect(_on_target_input_event) != OK:
		print("area_2d.input_event connect fail!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print(str(drag_timer.time_left))
	#print(str(drop_timer.time_left))
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
	elif dragging and event.is_action_pressed("select") and get_tree().get_first_node_in_group("dragging"):
		_drop()

# ========================
# Dragging Functions
# ========================
# Start dragging the character
func _start_dragging():
	if not dragging_enabled:
		return
	
	drag_timer.start()
	dragging = true
	starting_position = dragging_item.global_position
	add_to_group("dragging")
	dragging_item.z_index = 500  # Bring to front during drag
	offset = dragging_item.global_position - get_global_mouse_position()
	drag_started.emit(starting_position, "started")

# End dragging (common operations)
func _end_dragging():
	dragging = false
	remove_from_group("dragging")
	dragging_item.z_index = CHARACT_Z_INDEX  # Restore default Z-index
	drop_timer.start()

# Cancel dragging and return to start position
func _cancel_dragging():
	_end_dragging()
	global_position = starting_position
	drag_canceled.emit(starting_position, "canceled")
	dragging_item.global_position = starting_position

# Drop character at current position
func _drop():
	_end_dragging()
	drag_dropped.emit(starting_position, "dropped")
	
	
# ========================
# Signal Handlers
# ========================
# Handle input events on the character area
func _on_target_input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("select"):
		is_clicked.emit(starting_position, "clicked")
	
	if not dragging_enabled or drag_timer.time_left > 0:
		return
		
	# # Check if another object is being dragged
	# if get_tree().get_first_node_in_group("dragging"):
	# 	return
		
	# Start dragging on select input
	if event.is_action_pressed("select") and not dragging and drop_timer.time_left <= 0:
		_start_dragging()

	elif get_tree().get_first_node_in_group("dragging") and dragging and event.is_action_pressed("select"):
		_drop()

# Handle dragging behavior
func _handle_dragging():
	# Follow mouse position with offset
	# dragging_item.global_position = get_global_mouse_position() + offset
	pass
