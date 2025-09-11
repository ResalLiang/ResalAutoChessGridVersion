extends VBoxContainer
class_name EffectIcon

@onready var texture_rect: TextureRect = $TextureRect

var effect_type: String = "Default"
var effect_name: String:
	set(value):
		var icon_texture: Texture2D
		texture_rect = TextureRect.new()
		match value:
			"Swift":
				icon_texture = preload("res://asset/sprite/icon/swift.png")
			"Wisdom":
				icon_texture = preload("res://asset/sprite/icon/wisdom.png")
			"Fortress":
				icon_texture = preload("res://asset/sprite/icon/fortress.png")
			"Holy Shield":
				icon_texture = preload("res://asset/sprite/icon/holy_shield.png")
			"Strong":
				icon_texture = preload("res://asset/sprite/icon/strong.png")
			"Doom":
				icon_texture = preload("res://asset/sprite/icon/doom.png")
			"Weak":
				icon_texture = preload("res://asset/sprite/icon/weak.png")
			_:
				icon_texture = preload("res://asset/sprite/icon/wisdom.png")
		texture_rect.texture = icon_texture
		effect_name = value
		
# Called when the node enters the scene tree for the first time.
func _ready() -> void:


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
