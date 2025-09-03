extends Node2D

@onready var start_button: Button = $button_container/start_button
@onready var setting_button: Button = $button_container/setting_button
@onready var gallery_button: Button = $button_container/gallery_button
@onready var statistics_button: Button = $button_container/statistics_button
@onready var quit_button: Button = $button_container/quit_button
signal game_started

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	game_started.emit()
	get_parent().get_parent().show_game()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_gallery_button_pressed() -> void:
	get_parent().get_parent().show_gallery()
