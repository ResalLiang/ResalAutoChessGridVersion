class_name AreaEffectHanlder
extends Node

func find_affected_units(origin: Vector2i, rotate_index: int, unit_grid: Dictionary, template: Array) -> Array:
	var affected = []
	var template = _rotated_templates[template, rotate_index % 4]

	var template_rows = template.size()
	var template_row_ceneter = ceil(template_rows / 2)
	var template_cols = template[0].size()
	var template_col_ceneter = ceil(template_cols / 2)
	
	for y in range(template_rows):
		for x in range(template_cols):
			if template[y - template_row_ceneter][x - template_col_ceneter] == 1:
				var result_pos = origin + Vector2i(x, y) - Vector2i(template_col_ceneter, template_row_ceneter)
				if unit_grid.has(result_pos):
					affected.append(result_pos)
	return affected

func _rotate_template(template: Array, times: int) -> Array:
	var rotated = template.duplicate(1)
	for _i in range(times):
		rotated = _rotate_90(rotated)
	return rotated

func _rotate_90(matrix: Array) -> Array:
	var n = matrix.size()
	var result = []
	for x in range(n):
		var row = []
		for y in range(n - 1, -1, -1):
			row.append(matrix[y][x])
		result.append(row)
	return result

var template1 := [
	[0,	0,	0,	0,	1,	0,	0,	0,	0],	
	[0,	0,	0,	0,	1,	0,	0,	0,	0],	
	[0,	0,	0,	0,	1,	0,	0,	0,	0],	
	[0,	0,	0,	0,	1,	0,	0,	0,	0],	
	[1,	1,	1,	1,	1,	1,	1,	1,	1],	
	[0,	0,	0,	0,	1,	0,	0,	0,	0],	
	[0,	0,	0,	0,	1,	0,	0,	0,	0],	
	[0,	0,	0,	0,	1,	0,	0,	0,	0],	
	[0,	0,	0,	0,	1,	0,	0,	0,	0]
	]

var template2 := [
	[0,	1,	0,	1,	0,	1,	0,	1,	0],	
	[1,	0,	1,	0,	1,	0,	1,	0,	1],	
	[0,	1,	0,	1,	0,	1,	0,	1,	0],	
	[1,	0,	1,	0,	1,	0,	1,	0,	1],	
	[0,	1,	0,	1,	0,	1,	0,	1,	0],	
	[1,	0,	1,	0,	1,	0,	1,	0,	1],	
	[0,	1,	0,	1,	0,	1,	0,	1,	0],	
	[1,	0,	1,	0,	1,	0,	1,	0,	1],	
	[0,	1,	0,	1,	0,	1,	0,	1,	0]
	]

