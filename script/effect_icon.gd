extends Control
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
		
var effect_description: String:
	set(value):
		effect_description = value

func _update_texture():
	if not texture_rect:
		return
		
	var icon_texture: Texture2D

	icon_texture = load(AssetPathManagerSingleton.get_asset_path("effect_icon", _effect_name.get_slice(" ", 0)))
	
	texture_rect.texture = icon_texture

func _ready() -> void:
	
	var game_root_scene = get_parent().get_parent().get_parent().get_parent()
	_update_texture()  # 确保在节点准备好后更新纹理
	z_index = 20
	texture_rect.z_index = 25
	
