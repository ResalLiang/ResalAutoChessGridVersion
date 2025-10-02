extends VBoxContainer
class_name EffectIcon

@onready var texture_rect: TextureRect = $TextureRect

var effect_type: String = "Default"
var _effect_name: String  # 私有变量存储实际值
var effect_name: String:
	set(value):
		_effect_name = value
		_update_texture()
	get:
		return _effect_name

func _update_texture():
	if not texture_rect:
		return
		
	var icon_texture: Texture2D

	icon_texture = load(AssetPathManagerSingleton.get_asset_path("effect_icon", _effect_name.get_slice(" ", 0)))

	#match _effect_name:
		#"Swift":
			#icon_texture = preload("res://asset/sprite/icon/swift.png")
		#"Wisdom":
			#icon_texture = preload("res://asset/sprite/icon/wisdom.png")
		#"Fortress":
			#icon_texture = preload("res://asset/sprite/icon/fortress.png")
		#"HolyShield":
			#icon_texture = preload("res://asset/sprite/icon/holy_shield.png")
		#"Strong":
			#icon_texture = preload("res://asset/sprite/icon/strong.png")
		#"Doom":
			#icon_texture = preload("res://asset/sprite/icon/doom.png")
		#"Weak":
			#icon_texture = preload("res://asset/sprite/icon/weak.png")
		#_:
			#icon_texture = preload("res://asset/sprite/icon/wisdom.png")
	
	texture_rect.texture = icon_texture

func _ready() -> void:
	_update_texture()  # 确保在节点准备好后更新纹理
	z_index = 20
	texture_rect.z_index = 25
