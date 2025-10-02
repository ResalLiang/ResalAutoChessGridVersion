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

# Pixel art texture settings
@export var curve_texture: Texture2D  # Texture for curve segments
@export var arrow_head_texture: Texture2D  # Texture for arrow head (should point upward)
@export var segment_spacing: float = 20.0  # Distance between curve texture segments
@export var texture_scale: float = 1.0  # Scale multiplier for textures

var start_pos: Vector2
var end_pos: Vector2
var is_visible: bool = false

# Animation related variables
var animation_progress: float = 0.0
var is_animating: bool = true

func _ready():
	z_index = 550
	mouse_filter = MouseFilter.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if is_visible:
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
	
	# Calculate actual end position based on animation progress
	var current_end = start_pos.lerp(end_pos, animation_progress)
	
	# Draw curved arrow using textures
	draw_curved_arrow_with_textures(start_pos, current_end)

func draw_curved_arrow_with_textures(from: Vector2, to: Vector2):
	if from.distance_to(to) < 10:
		return
	
	# Calculate bezier curve control point
	var control_point = calculate_bezier_control_point(from, to)
	
	# Generate curve points with higher resolution for better texture placement
	var curve_points = generate_curve_points(from, control_point, to, 50)
	
	# Draw curve segments using textures
	if curve_texture:
		var total_length = calculate_curve_length(curve_points)
		var segment_count = max(1, int(total_length / segment_spacing))
		var actual_spacing = total_length / segment_count  # Calculate even spacing
		
		# Draw curve texture segments with even spacing
		for i in range(segment_count):
			var target_distance = i * actual_spacing
			var position_info = get_position_at_distance(curve_points, target_distance)
			
			if position_info.has("position"):
				var pos = position_info["position"]
				
				# Apply dashed pattern if enabled
				if is_dashed:
					var cycle_length = dash_length + dash_gap
					var cycle_position = fmod(target_distance, cycle_length)
					if cycle_position >= dash_length:
						continue  # Skip this segment (it's in the gap)
				
				# Draw the curve texture segment without rotation
				var texture_size = curve_texture.get_size() * texture_scale
				draw_texture(curve_texture, pos - texture_size * 0.5, arrow_color)
	
	# Draw arrow head when animation is near completion
	if animation_progress >= 0.8 and arrow_head_texture:
		draw_arrow_head_texture(curve_points)

func calculate_bezier_control_point(start: Vector2, end: Vector2) -> Vector2:
	var mid = (start + end) * 0.5
	var direction = (end - start).normalized()
	var perpendicular = Vector2(-direction.y, direction.x)
	
	# Adjust arc height based on distance and angle
	var distance = start.distance_to(end)
	var height = min(curve_height, distance * 0.4)
	
	# Adjust arc direction based on relative position of start and end points
	var angle = direction.angle()
	if abs(angle) > PI * 0.5:  # If it's a leftward arrow
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

func calculate_curve_length(points: PackedVector2Array) -> float:
	var length = 0.0
	for i in range(points.size() - 1):
		length += points[i].distance_to(points[i + 1])
	return length

func get_position_at_distance(curve_points: PackedVector2Array, target_distance: float) -> Dictionary:
	# Find position and direction at specific distance along the curve
	var current_distance = 0.0
	
	for i in range(curve_points.size() - 1):
		var segment_start = curve_points[i]
		var segment_end = curve_points[i + 1]
		var segment_length = segment_start.distance_to(segment_end)
		
		if current_distance + segment_length >= target_distance:
			# The target distance is within this segment
			var remaining_distance = target_distance - current_distance
			var t = remaining_distance / segment_length
			var position = segment_start.lerp(segment_end, t)
			var direction = (segment_end - segment_start).normalized()
			
			return {"position": position, "direction": direction}
		
		current_distance += segment_length
	
	# If we reach here, return the last point
	if curve_points.size() >= 2:
		var last_point = curve_points[curve_points.size() - 1]
		var second_last = curve_points[curve_points.size() - 2]
		var direction = (last_point - second_last).normalized()
		return {"position": last_point, "direction": direction}
	
	return {}

func draw_arrow_head_texture(curve_points: PackedVector2Array):
	if curve_points.size() < 2:
		return
	
	var tip = curve_points[curve_points.size() - 1]
	var direction_point = curve_points[curve_points.size() - 2]
	var direction = (tip - direction_point).normalized()
	
	# Calculate rotation angle (arrow head texture points up by default)
	var angle = direction.angle() + PI / 2  # Add 90 degrees since texture points up
	
	# Draw the arrow head texture
	var texture_size = arrow_head_texture.get_size() * texture_scale

	draw_set_transform(tip, angle, Vector2.ONE)
	draw_texture(arrow_head_texture, -texture_size * 0.5, arrow_color)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# Convenient methods for setting properties
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

func set_texture_properties(curve_tex: Texture2D, arrow_tex: Texture2D, spacing: float = 20.0, scale: float = 1.0):
	curve_texture = curve_tex
	arrow_head_texture = arrow_tex
	segment_spacing = spacing
	texture_scale = scale
	queue_redraw()
