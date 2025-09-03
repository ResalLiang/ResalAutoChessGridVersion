extends Control
class_name CustomArrowRenderer

@export var arrow_color: Color = Color.YELLOW
@export var arrow_width: float = 6.0
@export var curve_height: float = 80.0
@export var arrow_head_length: float = 25.0
@export var arrow_head_width: float = 15.0
@export var dash_length: float = 15.0
@export var dash_gap: float = 10.0
@export var is_dashed: bool = true

var start_pos: Vector2
var end_pos: Vector2
var is_visible: bool = false

# 动画相关
var animation_progress: float = 0.0
var is_animating: bool = true

func _ready():
	z_index = 999
	mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if is_visible : #and animation_progress > 0.0:
		visible = true
		end_pos = get_global_mouse_position()
		show_targeting_arrow(start_pos, get_global_mouse_position(), true)
	else:
		visible = false

func show_targeting_arrow(from: Vector2, to: Vector2, animate: bool = true):
	start_pos = from
	end_pos = to
	is_visible = true
	
	if animate:
		animate_arrow_appearance()
	else:
		animation_progress = 1.0
	
	queue_redraw()

func hide_targeting_arrow(animate: bool = true):
	if animate:
		animate_arrow_disappearance()
	else:
		is_visible = false
		animation_progress = 0.0
		queue_redraw()

func animate_arrow_appearance():
	is_animating = true
	var tween = create_tween()
	tween.tween_property(self, "animation_progress", 1.0, 0.3)
	tween.tween_callback(func(): is_animating = false)

func animate_arrow_disappearance():
	is_animating = true
	var tween = create_tween()
	tween.tween_property(self, "animation_progress", 0.0, 0.2)
	tween.tween_callback(func(): 
		is_visible = false
		is_animating = false
		queue_redraw()
	)

func _draw():
	if not is_visible or animation_progress <= 0.0:
		return
	
	# 计算实际的结束位置（基于动画进度）
	var current_end = start_pos.lerp(end_pos, animation_progress)
	
	# 绘制弧形线条
	draw_curved_arrow(start_pos, current_end)

func draw_curved_arrow(from: Vector2, to: Vector2):
	if from.distance_to(to) < 10:
		return
	
	# 计算贝塞尔曲线控制点
	var control_point = calculate_bezier_control_point(from, to)
	
	# 生成曲线点
	var curve_points = generate_curve_points(from, control_point, to, 30)
	
	if is_dashed:
		draw_dashed_curve(curve_points)
	else:
		draw_solid_curve(curve_points)
	
	# 绘制箭头头部
	if animation_progress >= 0.8:  # 只在接近完成时显示箭头头部
		draw_arrow_head(curve_points)

func calculate_bezier_control_point(start: Vector2, end: Vector2) -> Vector2:
	var mid = (start + end) * 0.5
	var direction = (end - start).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	# 根据距离和角度调整弧度
	var distance = start.distance_to(end)
	var height = min(curve_height, distance * 0.4)
	
	# 根据起点和终点的相对位置调整弧度方向
	var angle = direction.angle()
	if abs(angle) > PI * 0.5:  # 如果是向左的箭头
		height = -height
	
	return mid + perpendicular * height

func generate_curve_points(start: Vector2, control: Vector2, end: Vector2, segments: int) -> PackedVector2Array:
	var points = PackedVector2Array()
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var point = quadratic_bezier(start, control, end, t)
		points.append(point)
	
	return points

func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var u = 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2

func draw_solid_curve(points: PackedVector2Array):
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], arrow_color, arrow_width)

func draw_dashed_curve(points: PackedVector2Array):
	var total_length = calculate_curve_length(points)
	var current_length = 0.0
	var is_drawing = true
	var dash_progress = 0.0
	
	for i in range(points.size() - 1):
		var segment_start = points[i]
		var segment_end = points[i + 1]
		var segment_length = segment_start.distance_to(segment_end)
		
		draw_dashed_segment(segment_start, segment_end, current_length, total_length)
		current_length += segment_length

func draw_dashed_segment(start: Vector2, end: Vector2, offset: float, total_length: float):
	var segment_vector = end - start
	var segment_length = segment_vector.length()
	var direction = segment_vector.normalized()
	
	var current_pos = 0.0
	var dash_cycle = dash_length + dash_gap
	var is_dash = (int(offset) % int(dash_cycle)) < dash_length
	
	while current_pos < segment_length:
		var remaining = segment_length - current_pos
		var cycle_pos = int(offset + current_pos) % int(dash_cycle)
		
		if is_dash and cycle_pos < dash_length:
			# 绘制虚线段
			var dash_end = min(current_pos + (dash_length - cycle_pos), segment_length)
			var line_start = start + direction * current_pos
			var line_end = start + direction * dash_end
			draw_line(line_start, line_end, arrow_color, arrow_width)
			current_pos = dash_end
		else:
			# 跳过间隙
			var gap_end = min(current_pos + (dash_cycle - cycle_pos), segment_length)
			current_pos = gap_end
		
		is_dash = not is_dash

func calculate_curve_length(points: PackedVector2Array) -> float:
	var length = 0.0
	for i in range(points.size() - 1):
		length += points[i].distance_to(points[i + 1])
	return length

func draw_arrow_head(curve_points: PackedVector2Array):
	if curve_points.size() < 2:
		return
	
	var tip = curve_points[curve_points.size() - 1]
	var direction_point = curve_points[curve_points.size() - 2]
	var direction = (tip - direction_point).normalized()
	
	# 计算箭头头部的三个顶点
	var perpendicular = Vector2(-direction.y, direction.x)
	var head_base = tip - direction * arrow_head_length
	
	var arrow_points = PackedVector2Array([
		tip,
		head_base + perpendicular * arrow_head_width * 0.5,
		head_base - perpendicular * arrow_head_width * 0.5
	])
	
	draw_colored_polygon(arrow_points, arrow_color)

# 设置属性的便捷方法
func set_arrow_properties(color: Color, width: float, height: float):
	arrow_color = color
	arrow_width = width
	curve_height = height
	queue_redraw()

func set_dashed(dashed: bool, dash_len: float = 15.0, gap_len: float = 10.0):
	is_dashed = dashed
	dash_length = dash_len
	dash_gap = gap_len
	queue_redraw()
