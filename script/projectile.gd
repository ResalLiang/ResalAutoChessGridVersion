extends Area2D

@export var speed: float = 600.0
@export var damage: float = 20.0
@export var penetration: int = 1  # 穿透次数
@export var max_distance: float = 300.0  # 最大飞行距离
@export var decline_ratio := 3.0

var current_penetration

var direction: Vector2 = Vector2.ZERO:
	set(value):
		direction = value
		animated_sprite_2d.rotation = atan2(value.y, value.x)
		
var traveled_distance: float = 0.0
var source_team: int = -1  # 发射队伍
var initial_flip: bool = false  # 初始翻转状态
var is_active := false
var attacker: Obstacle = null:
	set(value):
		attacker = value
		# Load animation resource in editor mode
		if ResourceLoader.exists("res://asset/animation/" + attacker.faction + "/" + attacker.faction + attacker.chess_name + "_projectile.tres"):
			animated_sprite_2d.sprite_frames = ResourceLoader.load("res://asset/animation/" + attacker.faction + "/" + attacker.faction + attacker.chess_name + "_projectile.tres")
		elif ResourceLoader.exists("res://asset/animation/" + attacker.faction + "/" +  "default_projectile.tres"):
			animated_sprite_2d.sprite_frames = ResourceLoader.load("res://asset/animation/" + attacker.faction + "/" +  "default_projectile.tres")
		else:
			animated_sprite_2d.sprite_frames = ResourceLoader.load("res://asset/animation/default_projectile.tres")


signal projectile_vanished
signal projectile_hit

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _ready():

	# 设置初始朝向
	if initial_flip:
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.rotation_degrees = 180  # 根据实际美术资源调整

	current_penetration = penetration
		
	animated_sprite_2d.play("default")

#func setup(pos: Vector2, dir: Vector2, team: int, is_flipped: bool, chess_attack: Obstacle):
	#global_position = pos
	#direction = dir.normalized()
	#source_team = team
	#initial_flip = is_flipped
	#rotation = dir.angle()  # 根据方向旋转
	#attacker = chess_attack
	#current_damage = chess_attack.ranged_damage

func _physics_process(delta):
	if is_active:
		var movement = direction * speed * delta
		
		position += movement
		
		# 更新飞行距离
		traveled_distance += movement.length()
		
		# 超出最大距离或穿透次数耗尽时消失
		if traveled_distance > max_distance or current_penetration <= 0 or damage < 5:
			projectile_vanished.emit()
			queue_free()

func _on_area_entered(area):
	if area.get_parent().is_in_group("obstacle_group"):
		var obstacle = area.get_parent()
		projectile_hit.emit(obstacle, attacker)
		# 只伤害敌方队伍
		if obstacle.team != source_team and attacker != null:
			obstacle.take_damage(damage, attacker)
			await projectile_damage_display(obstacle, damage)
			current_penetration -= 1  # 减少穿透计数
			damage /= decline_ratio

			# 穿透次数耗尽时消失
			if current_penetration <= 0 or damage < 5:
				projectile_vanished.emit()
				queue_free()

# 处理离开屏幕
func _on_visibility_notifier_screen_exited():
	projectile_vanished.emit()
	queue_free()


func projectile_damage_display(chess: Obstacle, display_value: float):

	if display_value <= 0:
		return

	var battle_label = Label.new()
	battle_label.z_index = 6
	add_child(battle_label)

	# Create a new theme
	var new_theme = Theme.new()
	
	# Load font resource
	var font = load("res://asset/font/Everyday_Tiny.ttf") as FontFile
	
	# Set font and size in theme using correct methods
	new_theme.set_font("font", "Label", font)
	
	# Apply theme to label
	battle_label.theme = new_theme
	
	var label_settings = LabelSettings.new()
	label_settings.font_size = 4

	label_settings.font_color = Color.YELLOW
	battle_label.text = str(display_value)

	battle_label.label_settings = label_settings
	
	var old_position = chess.global_position + Vector2(8, -8)
	battle_label.global_position = old_position

	var damage_tween
	if damage_tween:
		damage_tween.kill() # Abort the previous animation.
	damage_tween = create_tween().set_parallel(true)
	damage_tween.set_ease(Tween.EASE_IN_OUT)
	damage_tween.set_trans(Tween.TRANS_CUBIC)
	damage_tween.tween_property(battle_label, "global_position", old_position + Vector2(0, -16), 1.0)
	damage_tween.tween_property(battle_label,"modulate.a", 0.0, 1.0)
	await damage_tween.finished
	damage_tween.kill()
	battle_label.queue_free()
