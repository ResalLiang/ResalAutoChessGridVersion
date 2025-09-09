extends TextureRect
@onready var effect_icon: VBoxContainer = $".."
@onready var texture_rect: TextureRect = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
const chess_scene = preload("res://scene/chess.tscn")
