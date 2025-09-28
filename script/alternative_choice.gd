extends Node2D

@onready var button_1: Button = $button_container/Button1
@onready var button_2: Button = $button_container/Button2

signal choice_made(button_choice: int)

func _on_button_1_pressed() -> void:
	set_meta("choice", 1)
	await get_tree().process_frame
	choice_made.emit(1)

func _on_button_2_pressed() -> void:
	set_meta("choice", 2)
	await get_tree().process_frame
	choice_made.emit(2)
