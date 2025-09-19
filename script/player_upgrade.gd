extends Node2D
class_name PlayerUpgrade

@onready var faction_lock_container : VBoxContainer = $faction_lock_container

@onready var holy_lock_container: HBoxContainer = $faction_lock_container/holy_lock_container
@onready var label: Label = $faction_lock_container/holy_lock_container/Label
@onready var holy_faction_lock: CheckButton = $faction_lock_container/holy_lock_container/holy_faction_lock
@onready var forest_protector_lock_container: HBoxContainer = $faction_lock_container/forestProtector_lock_container
@onready var forest_protector_faction_lock: CheckButton = $faction_lock_container/forestProtector_lock_container/forestProtector_faction_lock
@onready var undead_lock_container: HBoxContainer = $faction_lock_container/undead_lock_container
@onready var undead_faction_lock: CheckButton = $faction_lock_container/undead_lock_container/undead_faction_lock
@onready var demon_lock_container: HBoxContainer = $faction_lock_container/demon_lock_container
@onready var demon_faction_lock: CheckButton = $faction_lock_container/demon_lock_container/demon_faction_lock
@onready var debug_mode_button: CheckButton = $faction_lock_container/debug_container/debug_mode_button

@onready var back_button: Button = $back_button
#TODO: add debug button
signal to_menu_scene

var current_player_upgrade : Dictionary

func _ready():
	current_player_upgrade = DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["player_upgrade"]
	for button_index in faction_lock_container.get_children():

			
		for node in button_index.get_children():
			if not node is CheckButton:
				continue
				
			if node.get_name() == "debug_mode_button":
				node.set_pressed(DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"])
				node.toggled.connect(faction_lock_button_toggled.bind(node))
				continue
				
			var faction_name = node.get_name().replace("_faction_lock", "")
			node.set_pressed(current_player_upgrade["faction_locked"][faction_name])
			node.toggled.connect(faction_lock_button_toggled.bind(node))


func faction_lock_button_toggled(toggled_on: bool, button_index: CheckButton):
	if button_index.get_name() == "debug_mode_button":
		DataManagerSingleton.player_datas[DataManagerSingleton.current_player]["debug_mode"] = toggled_on
	else:
		var faction_name = button_index.get_name().replace("_faction_lock", "")
		current_player_upgrade["faction_locked"][faction_name] = toggled_on


func _on_back_button_pressed() -> void:
	DataManagerSingleton.save_game_json()
	to_menu_scene.emit()
