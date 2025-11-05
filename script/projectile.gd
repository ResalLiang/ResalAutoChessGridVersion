extends Area2D
class_name Projectile

@export var speed: float = 600.0
@export var damage: float = 2
@export var penetration: int = 1  # 穿透次数
@export var max_distance: float = 1000.0  # 最大飞行距离
@export var decline_ratio := 1

var current_penetration

var direction: Vector2:
	set(value):
		direction = value
		animated_sprite_2d.rotation = atan2(value.y, value.x)

var direction_degree: float:
	set(value):
		direction_degree = value
		animated_sprite_2d.rotation = deg_to_rad(direction_degree)
		direction = Vector2.from_angle(deg_to_rad(value))
		
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

var projectile_animation: String:
	set(value):
		projectile_animation = value
		if ResourceLoader.exists(AssetPathManagerSingleton.get_asset_path("projectile_animation", value)):
			animated_sprite_2d.sprite_frames = ResourceLoader.load(AssetPathManagerSingleton.get_asset_path("projectile_animation", value))
		else:
			animated_sprite_2d.sprite_frames = ResourceLoader.load(AssetPathManagerSingleton.get_asset_path("projectile_animation", "Default"))


var damage_finished := false
var die_animation

var damage_type := "Ranged_attack"

var hit_record := []
var projectile_disabled := false
var affect_ally := false

signal projectile_vanished
signal projectile_hit

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready():

	# 设置初始朝向
	if initial_flip:
		animated_sprite_2d.flip_h = true
		animated_sprite_2d.rotation_degrees = 180  # 根据实际美术资源调整

	current_penetration = penetration
		
	animated_sprite_2d.play("move")

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
		if traveled_distance > max_distance:
			projectile_vanished.emit()
			queue_free()

func _on_area_entered(area):
	var obstacle = area.get_parent()
	if DataManagerSingleton.check_obstacle_valid(obstacle) and not projectile_disabled:
		
		if obstacle == attacker:
			return
		if not affect_ally and attacker.team == obstacle.team:
			return
		if hit_record.has(obstacle):
			return
		projectile_hit.emit(obstacle, self)
		hit_record.append(obstacle)

		current_penetration -= 1  # 减少穿透计数
		damage -= decline_ratio
		
		# 穿透次数耗尽时消失
		if current_penetration <= 0 or damage < 5:
			projectile_disabled = true
			visible = false
			# projectile_vanished.emit()
			# queue_free()

# 处理离开屏幕
func _on_visibility_notifier_screen_exited():
	projectile_vanished.emit()
	queue_free()


func _on_animated_sprite_2d_animation_finished() -> void:
	die_animation.queue_free()
