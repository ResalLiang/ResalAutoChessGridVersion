extends Node2D

@onready var label: Label = $Label
@onready var heart: HBoxContainer = $VBoxContainer/heart
@onready var trophy: HBoxContainer = $VBoxContainer/trophy


var remain_health_pic
var lose_health_pic
var trophy_pic


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#remain_health_pic =	preload("res://asset/sprite/GandalfHardcore Pixel Art Game UI/Single frames/16x16 Slider1.png")
	#lose_health_pic =	preload("res://asset/sprite/GandalfHardcore Pixel Art Game UI/Single frames/16x16 Slider4.png")
	#trophy_pic =		preload("res://asset/sprite/GandalfHardcore Pixel Art Game UI/Single frames/16x16 Slider2.png")
	remain_health_pic =	load(AssetPathManagerSingleton.get_asset_path("battle_result", "remain_health"))
	lose_health_pic =	load(AssetPathManagerSingleton.get_asset_path("battle_result", "lose_health"))
	trophy_pic =		load(AssetPathManagerSingleton.get_asset_path("battle_result", "winning_trophy"))
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	set_round_result()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func set_round_result():
	
	for child in heart.get_children():
		child.queue_free()
		
	for child in trophy.get_children():
		child.queue_free()
		
	for health_index in range(DataManagerSingleton.max_lose_rounds - DataManagerSingleton.lose_rounds):
		var remain_health_icon = TextureRect.new()
		remain_health_icon.texture = remain_health_pic
		heart.add_child(remain_health_icon)
		
	for health_index in range(DataManagerSingleton.lose_rounds):
		var lose_health_icon = TextureRect.new()
		lose_health_icon.texture = lose_health_pic
		heart.add_child(lose_health_icon)
		
	for trophy_index in range(DataManagerSingleton.won_rounds):
		var trophy_icon = TextureRect.new()
		trophy_icon.texture = trophy_pic
		trophy.add_child(trophy_icon)

func _on_timer_timeout() -> void:
	get_tree().paused = false
	queue_free() # Replace with function body.
