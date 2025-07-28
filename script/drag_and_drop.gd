class_name DragAndDrop
extends Node

signal drag_canceled(staring_postion: Vector2)
signal drag_started
signal dropped(starting_position: Vector2)

@export var enabled: bool = true
@export var target: Area2D
@onready var grid_highlight: AnimatedSprite2D = %grid_highlight
@onready var node_2d: Node2D = %Node2D

var starting_position: Vector2
var offset := Vector2.ZERO
var dragging := false

func _ready() -> void:
	assert(target, "No target set for DragAndDrop Component!")
	target.input_event.connect(_on_target_input_event.unbind(1))

func _process(_delta: float) -> void:
	if dragging and target:
		target.global_position = target.get_global_mouse_position() + offset
		node_2d.position = Vector2(
			snap(target.get_global_mouse_position().x, 16),
			snap(target.get_global_mouse_position().y, 16)
		)
		
func _input(event: InputEvent) -> void:
	if dragging and event.is_action_pressed("cancel_dragging"):
		_cancel_dragging()
	elif dragging and event.is_action_released("ui_accept"):
		_drop()
		
func _end_dragging() -> void:
	dragging = false
	target.remove_from_group("dragging")
	target.z_index = 1
	
func _cancel_dragging() -> void:
	_end_dragging()
	drag_canceled.emit(starting_position)
	grid_highlight.visible = false
	
func _starting_dragging() -> void:
	dragging = true
	grid_highlight.visible = true
	starting_position = target.global_position
	target.add_to_group("dragging")
	target.z_index = 99
	offset = target.global_position - target.get_global_mouse_position()
	drag_started.emit()
	
func _drop() -> void:
	_end_dragging()
	dropped.emit()
	grid_highlight.visible = false
	
func _on_target_input_event(_viewport: Node, event: InputEvent) -> void:
	if not enabled:
		return
		
	var dragging_object := get_tree().get_first_node_in_group("dragging")
	
	if not dragging and dragging_object:
		return
		

	if not dragging and event.is_action_pressed("select"):
		_starting_dragging()

func snap(value: float, grid_size: int) -> float:
	return floor(value / grid_size) * grid_size
