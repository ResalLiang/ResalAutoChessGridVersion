extends Area2D

@export var speed: float = 600.0
@export var damage: int = 20
@export var penetration: int = 1  # 穿透次数
@export var max_distance: float = 300.0  # 最大飞行距离

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
		
	animated_sprite_2d.play("default")

func setup(pos: Vector2, dir: Vector2, team: int, is_flipped: bool, chess_attack: Obstacle):
	global_position = pos
	direction = dir.normalized()
	source_team = team
	initial_flip = is_flipped
	rotation = dir.angle()  # 根据方向旋转
	attacker = chess_attack

func _physics_process(delta):
	if is_active:
		var movement = direction * speed * delta
		
		position += movement
		
		# 更新飞行距离
		traveled_distance += movement.length()
		
		# 超出最大距离或穿透次数耗尽时消失
		if traveled_distance > max_distance || penetration <= 0:
			projectile_vanished.emit()
			queue_free()

func _on_area_entered(area):
	if area.get_parent().is_in_group("obstacle_group"):
		var obstacle = area.get_parent()
		projectile_hit.emit(obstacle, attacker)
		# 只伤害敌方队伍
		if obstacle.team != source_team and attacker != null:
			obstacle.take_damage(damage, attacker)
			penetration -= 1  # 减少穿透计数
			
			# 穿透次数耗尽时消失
			if penetration <= 0:
				projectile_vanished.emit()
				queue_free()

# 处理离开屏幕
func _on_visibility_notifier_screen_exited():
	projectile_vanished.emit()
	queue_free()
