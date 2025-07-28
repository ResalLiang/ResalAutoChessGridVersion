extends CharacterBody2D


@export var SPEED = 100.0
@export var JUMP_VELOCITY = -200.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var is_attacking = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	var direction = 0	
	if Input.is_action_pressed("move_left"):
		direction = -1
	elif Input.is_action_pressed("move_right"):
		direction = 1
	else :
		direction = 0
		
	if is_attacking :
		pass
	else:
		if direction != 0:	
			velocity.x = direction * SPEED
			if direction == -1:
				animated_sprite_2d.flip_h = true
			else:
				animated_sprite_2d.flip_h = false
			animated_sprite_2d.play("move")
			move_and_slide()
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			animated_sprite_2d.play("idle")
	

	if Input.is_action_pressed("attack"):
		animated_sprite_2d.play("attack")
		is_attacking = true
		



func _on_animated_sprite_2d_animation_finished() -> void:
	is_attacking =  false # Replace with function body.
