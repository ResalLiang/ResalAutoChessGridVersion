extends Node2D
class_name PlayerUpgrade

@onready var faction_lock_container : VBoxContainer = $faction_lock_container

@onready var holy_lock_container: HBoxContainer = $faction_lock_container/holy_lock_container
@onready var label: Label = $faction_lock_container/holy_lock_container/Label
@onready var holy_faction_lock: CheckBox = $faction_lock_container/holy_lock_container/holy_faction_lock
@onready var forest_protector_lock_container: HBoxContainer = $faction_lock_container/forestProtector_lock_container
@onready var forest_protector_faction_lock: CheckBox = $faction_lock_container/forestProtector_lock_container/forestProtector_faction_lock
@onready var undead_lock_container: HBoxContainer = $faction_lock_container/undead_lock_container
@onready var undead_faction_lock: CheckBox = $faction_lock_container/undead_lock_container/undead_faction_lock
@onready var demon_lock_container: HBoxContainer = $faction_lock_container/demon_lock_container
@onready var demon_faction_lock: CheckBox = $faction_lock_container/demon_lock_container/demon_faction_lock
@onready var debug_mode_button: CheckBox = $faction_lock_container/debug_container/debug_mode_button

@onready var back_button: TextureButton = $back_button

@onready var difficulty_left_arrow: TextureButton = $faction_lock_container/difficulty_container/difficulty_left_arrow
@onready var difficulty_label: Label = $faction_lock_container/difficulty_container/difficulty_label
@onready var difficulty_right_arrow: TextureButton = $faction_lock_container/difficulty_container/difficulty_right_arrow
@onready var line_edit: LineEdit = $LineEdit


#TODO: add debug button
signal to_menu_scene

var current_player_upgrade : Dictionary

var difficulty_array = ["Easy", "Normal", "Hard"]
var current_difficulty_index
var current_difficulty

func _ready():
	current_player_upgrade = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["player_upgrade"]
	for button_index in faction_lock_container.get_children():


		for node in button_index.get_children():
			if not node is CheckBox:
				continue
				
			if node.get_name() == "debug_mode_button":
				node.set_pressed(DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"])
				node.pressed.connect(faction_lock_button_pressed.bind(node))
				continue
				
			var faction_name = node.get_name().replace("_faction_lock", "")
			node.set_pressed(current_player_upgrade["faction_locked"][faction_name])
			node.toggled.connect(faction_lock_button_pressed.bind(node))
	
	
	
	current_difficulty = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["difficulty"]
	if difficulty_array.has(current_difficulty):
		current_difficulty_index = difficulty_array.find(current_difficulty, 0)
	else:
		current_difficulty_index = 1
	difficulty_label.text = difficulty_array[current_difficulty_index]
		
	difficulty_left_arrow.pressed.connect(
		func():
			current_difficulty_index -= 1
			current_difficulty_index = max(0, min(2, current_difficulty_index))
			difficulty_label.text = difficulty_array[current_difficulty_index]
			DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["difficulty"] = difficulty_array[current_difficulty_index]
	)
	
	difficulty_right_arrow.pressed.connect(
		func():
			current_difficulty_index += 1
			current_difficulty_index = max(0, min(2, current_difficulty_index))
			difficulty_label.text = difficulty_array[current_difficulty_index]
			DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["difficulty"] = difficulty_array[current_difficulty_index]
	)
	
func _process(delta: float) -> void:
	if line_edit.text == "maria":
		debug_mode_button.disabled = false
	else:
		debug_mode_button.disabled = true

func faction_lock_button_pressed(button_index: CheckBox):
	if button_index.get_name() == "debug_mode_button":
		DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"] = not DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"]
	else:
		var faction_name = button_index.get_name().replace("_faction_lock", "")
		current_player_upgrade["faction_locked"][faction_name] = not DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"]


func _on_back_button_pressed() -> void:
	DataManagerSingleton.save_game_json()
	to_menu_scene.emit()
