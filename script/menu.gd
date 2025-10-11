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
@onready var current_player: Button = $current_player

@onready var cursor_highlight: Node2D = $Node2D/Node2D

@onready var change_player: Control = $Node2D/change_player
@onready var new_player_button: TextureButton = $Node2D/change_player/new_player_button
@onready var cancel_new_player: TextureButton = $Node2D/change_player/cancel_new_player

@onready var add_new_player: Control = $Node2D/change_player/add_new_player
@onready var create_new_player_button: TextureButton = $Node2D/change_player/add_new_player/create_new_player_button
@onready var cancel_create_player_button: TextureButton = $Node2D/change_player/add_new_player/cancel_create_player_button
@onready var new_player_edit_line: LineEdit = $Node2D/change_player/add_new_player/new_player_edit_line
@onready var player_name_container: VBoxContainer = $Node2D/change_player/ScrollContainer/player_name_container
@onready var player_template: Button = $Node2D/change_player/ScrollContainer/player_name_container/player_template

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
	
	if DataManagerSingleton.player_datas.size() == 0:
		change_player.visible = true
		change_player.visible = false
	else:
		change_player.visible = false
		change_player.visible = false
	
	refresh_player_list()
	
	current_player.pressed.connect(
		func():
			change_player.visible = true
			add_new_player.visible = false
	)
	new_player_button.pressed.connect(
		func():
			add_new_player.visible = true
	)
	cancel_create_player_button.pressed.connect(
		func():
			add_new_player.visible = false
	)
	create_new_player_button.pressed.connect(
		func():
			var new_player_name : String =  new_player_edit_line.text
			if new_player_name == "" or DataManagerSingleton.player_datas.keys().has(new_player_name):
				return
			DataManagerSingleton.player_datas[new_player_name] = DataManagerSingleton.player_data_template.duplicate(true)
			refresh_player_list()
			DataManagerSingleton.load_player(new_player_name)
			current_player.text = new_player_name
			DataManagerSingleton.save_game_json()
			change_player.visible = false
	)
	cancel_new_player.pressed.connect(
		func():
			DataManagerSingleton.save_game_json()	
			change_player.visible = false	
	)

	if is_past_date():
		for node in button_container.get_children():
			if not node is TextureButton:
				continue
			node.diabled = true

	
func _process(delta: float) -> void:
	if get_global_mouse_position().y > 250 or get_global_mouse_position().y < 120:
		return
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
	for user_index in DataManagerSingleton.player_datas.keys():
		DataManagerSingleton.player_datas[user_index]["debug_mode"] = false
	DataManagerSingleton.save_game_json()
	get_tree().quit()


func _on_upgrade_button_pressed() -> void:
	to_upgrade_scene.emit()

func refresh_player_list() -> void:
	if DataManagerSingleton.player_datas.size() == 0:
		return
		
	for node in player_name_container.get_children():
		if not node.name.contains("template"):
			node.queue_free()
		else:
			node.visible = false
		
	for player_index in DataManagerSingleton.player_datas.keys():
		var player_button = player_template.duplicate(true)
		player_name_container.add_child(player_button)
		player_button.visible = true
		player_button.text = player_index
		player_button.pressed.connect(
			func():
				DataManagerSingleton.load_player(player_index)
				current_player.text = player_index
				change_player.visible = false
		)
		
func is_past_date() -> bool:
	# 获取当前时间戳
	var current_unix_time = Time.get_unix_time_from_system()
	
	# 2025/10/15 00:00:00 的时间戳
	var target_unix_time = DataManagerSingleton.expiration_date
	
	return current_unix_time > target_unix_time
