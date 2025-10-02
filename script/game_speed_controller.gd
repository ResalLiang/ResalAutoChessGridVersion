extends Control
class_name GameSpeedController
#
#@onready var speed_slider: HSlider = $VBox/SpeedSlider
#@onready var speed_label: Label = $VBox/SpeedLabel
#@onready var preset_buttons: HBoxContainer = $VBox/PresetButtons
#
#@onready var slow_button: Button = $VBox/PresetButtons/SlowButton
#@onready var normal_button: Button = $VBox/PresetButtons/NormalButton
#@onready var fast_button: Button = $VBox/PresetButtons/FastButton


@onready var preset_buttons: HBoxContainer = $VBox/preset_buttons
@onready var slow_button: Button = $VBox/preset_buttons/slow_button
@onready var normal_button: Button = $VBox/preset_buttons/normal_button
@onready var fast_button: Button = $VBox/preset_buttons/fast_button
@onready var speed_slider: HSlider = $VBox/speed_slider
@onready var speed_label: Label = $VBox/speed_label



func _ready():
	# 设置滑条范围
	speed_slider.min_value = 0.1
	speed_slider.max_value = 5.0
	speed_slider.step = 0.1
	speed_slider.value = 1.0
	
	# 连接信号
	speed_slider.value_changed.connect(_on_speed_slider_changed)
	slow_button.pressed.connect(func(): _set_preset_speed(0.5))
	normal_button.pressed.connect(func(): _set_preset_speed(1.0))
	fast_button.pressed.connect(func(): _set_preset_speed(2.0))
	
	_update_speed_label(1.0)

func _on_speed_slider_changed(value: float):
	Engine.time_scale = value
	_update_speed_label(value)

func _set_preset_speed(speed: float):
	speed_slider.value = speed
	Engine.time_scale = speed
	_update_speed_label(speed)

func _update_speed_label(speed: float):
	speed_label.text = "Game Speed: %.1fx" % speed
