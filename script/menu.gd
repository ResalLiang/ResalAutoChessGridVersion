extends Node2D

@onready var start_button: Button = $button_container/start_button
@onready var setting_button: Button = $button_container/setting_button
@onready var gallery_button: Button = $button_container/gallery_button
@onready var statistics_button: Button = $button_container/statistics_button
@onready var quit_button: Button = $button_container/quit_button
@onready var version: Label = $version
@onready var current_player: Label = $current_player

signal to_game_scene
signal to_gallery_scene
signal to_upgrade_scene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_player.text = DataManagerSingleton.current_player
	version.text = DataManagerSingleton.version
	setting_button.disabled = true
	statistics_button.disabled = true

func _on_start_button_pressed() -> void:
	to_game_scene.emit()


func _on_gallery_button_pressed() -> void:
	to_gallery_scene.emit()


func _on_quit_button_pressed() -> void:
	DataManagerSingleton.save_game_json()
	get_tree().quit()


func _on_upgrade_button_pressed() -> void:
	to_upgrade_scene.emit()
