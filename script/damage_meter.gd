class_name DamageMeter
extends Node2D

var damage_dict: Dictionary = {}
var damage_meter_array := []

@onready var damage_bars = [
    $DamageBar0,
    $DamageBar1,
    $DamageBar2,
    $DamageBar3,
    $DamageBar4,
    $DamageBar5,
    $DamageBar6,
    $DamageBar7,
    $DamageBar8,
    $DamageBar9,
]

@onready var damage_labels = [
    $DamageLabel0,
    $DamageLabel1,
    $DamageLabel2,
    $DamageLabel3,
    $DamageLabel4,
    $DamageLabel5,
    $DamageLabel6,
    $DamageLabel7,
    $DamageLabel8,
    $DamageLabel9,
]
func init() -> void:
	damage_meter_clear()

func damage_meter_clear() -> void:
	damage_dict = {}
	damage_meter_array = []
	for i in damage_bars:
		i.visible = false
		i.value = 0
		i.max_value = 1
	for i in damage_labels:
		i.visible = false
		i.text = ""

func receive_damage_signal(hero: Hero, damage_value: int, attacker: Hero) -> void :
	if damage_value > 0:
		if damage_dict.has(attacker):
			damage_dict[attacker] += damage_value
		else:
			damage_dict[attacker] = damage_value

# func sort_damage_meter() -> void :
    var damage_array = damage_dict.keys().map(func(key): return [key, dict[key]])
    damage_array.sort_custom(func(a, b): return a[1] > b[1])
    damage_meter_array = damage_array.slice(0, 10)

# func plot_damage_bar() -> void :
	for i in range(damage_meter_array.size()):
		if i >= 10:
			return
		else:
			damage_bars[i].max_value = damage_meter_array[0][1]
			damage_bars[i].value = damage_meter_array[i][1]
			damage_labels[i].text = damage_meter_array[i][0].hero_name + "/" + damage_meter_array[i][1]
			var theme = Theme.new()
			if damage_meter_array[i][0].team == 1:
				theme.set_color("font_color", "ProgressBar", Color.WHITE)
				theme.set_color("fg", "ProgressBar", Color.GREEN)
				theme.set_color("bg", "ProgressBar", Color.GRAY)
				theme.set_font("font", "ProgressBar", "XXX" )
			else:
				theme.set_color("font_color", "ProgressBar", Color.WHITE)
				theme.set_color("fg", "ProgressBar", Color.RED)
				theme.set_color("bg", "ProgressBar", Color.GRAY)
				theme.set_font("font", "ProgressBar", "XXX" )
			damage_bars[i].theme = theme
			damage_bars[i].visible = true

func update_ranking():
	# 清空旧条目
	for child in $VBoxContainer/ItemList.get_children():
		child.queue_free()
	
	# 排序并取前10
	var sorted = damage_data.keys().sort_custom(func(a, b): return damage_data[a] > damage_data[b])
	
	# 生成新条目
	for hero in sorted.slice(0, 9):
		var item = preload("res://RankingItem.tscn").instance()
		$VBoxContainer/ItemList.add_child(item)
		item.init(hero, damage_data[hero])

func init(hero, damage):
    $Sprite.texture = hero.portrait
    $DamageLabel.text = str(damage)
    $ProgressBar.max_value = get_parent().max_damage  # 需在父节点计算最大值
    $ProgressBar.value = damage
