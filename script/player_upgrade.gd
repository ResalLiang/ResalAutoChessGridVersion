extends Node2D
class_name PlayerUpgrade

@onready var faction_lock_container : VBoxContainer = $faction_lock_container
# 修改成一个HBoxContainer = label + CheckButton的格式
@onready var holy_faction_lock : CheckButton = $faction_lock_container/holy_faction_lock
@onready var forestProtector_faction_lock : CheckButton = $faction_lock_container/forestProtector_faction_lock
@onready var undead_faction_lock : CheckButton = $faction_lock_container/undead_faction_lock
@onready var demon_faction_lock : CheckButton = $faction_lock_container/demon_faction_lock


var current_player_upgrade : Dictionary

func _ready():
	current_player_upgrade = DataManagerSingleton[DataManagerSingleton.current_player]["player_upgrade"]
	for button_index in faction_lock_container.get_children():
		var faction_name = button_index.get_name().replace("_faction_lock", "")
		button_index.button_pressed = not current_player_upgrade["faction_locked"][faction_name]
		button_index.pressed.connect(faction_lock_button_pressed.bind(button_index))


func faction_lock_button_pressed(button_index: CheckButton):
	# button_index.button_pressed = not button_index.button_pressed
	var faction_name = button_index.get_name().replace("_faction_lock", "")
	current_player_upgrade["faction_locked"][faction_name] = button_index.button_pressed
