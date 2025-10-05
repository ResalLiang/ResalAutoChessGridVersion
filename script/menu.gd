extends Node2D
@onready var start_button: TextureButton = $button_container/start_button
@onready var setting_button: TextureButton = $button_container/setting_button
@onready var upgrade_button: TextureButton = $button_container/upgrade_button
@onready var gallery_button: TextureButton = $button_container/gallery_button
@onready var statistics_button: TextureButton = $button_container/statistics_button
@onready var quit_button: TextureButton = $button_container/quit_button
@onready var label: Label = $Node2D/Label
@onready var button_container: HBoxContainer = $button_container

@onready var version: Label = $version
@onready var current_player: Label = $current_player

@onready var cursor_highlight: Node2D = $Node2D/Node2D

signal to_game_scene
signal to_gallery_scene
signal to_upgrade_scene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_player.text = DataManagerSingleton.current_player
	version.text = DataManagerSingleton.version
	setting_button.disabled = true
	statistics_button.disabled = true
	
	for node in button_container.get_children():
		if not node is TextureButton:
			continue
		if node.disabled:
			var new_material = node.material.duplicate()
			new_material.set_shader_parameter("use_monochrome", true)
			new_material.set_shader_parameter("monochrome_color", Color(0.77, 0.77 ,0.77, 1))
			node.material = new_material
	
func _process(delta: float) -> void:
	var button_index: int
	button_index = floor((get_global_mouse_position().x - 43) / 72)
	button_index = max(0, min(button_index, 5))
	cursor_highlight.position.x = 43 + button_index * 72
	match button_index:
		0:
			label.text = "Start Game"
		1:
			label.text = "Setting"
		2:
			label.text = "Upgrade"
		3:
			label.text = "Gallery"
		4:
			label.text = "Statistics"
		5:
			label.text = "Quit"
		_:
			label.text = ""
	

func _on_start_button_pressed() -> void:
	to_game_scene.emit()


func _on_gallery_button_pressed() -> void:
	to_gallery_scene.emit()


func _on_quit_button_pressed() -> void:
	DataManagerSingleton.save_game_json()
	get_tree().quit()


func _on_upgrade_button_pressed() -> void:
	to_upgrade_scene.emit()
