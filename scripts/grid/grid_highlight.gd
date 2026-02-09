extends Node2D

var grid_manager: GridManager

var reachable_cells: Array[Vector2i] = []
var path_cells: Array[Vector2i] = []
var hover_cell := Vector2i(-1, -1)
var enemy_cells: Array[Vector2i] = []
var attack_target_cells: Array[Vector2i] = []

const COLOR_REACHABLE := Color(0.3, 0.5, 1.0, 0.3)
const COLOR_PATH := Color(1.0, 0.9, 0.1, 0.4)
const COLOR_HOVER := Color(1.0, 1.0, 1.0, 0.25)
const COLOR_ENEMY := Color(1.0, 0.2, 0.2, 0.35)

const OUTLINE_REACHABLE := Color(0.3, 0.5, 1.0, 0.8)
const OUTLINE_PATH := Color(1.0, 0.9, 0.1, 0.9)
const OUTLINE_HOVER := Color(1.0, 1.0, 1.0, 0.7)
const OUTLINE_ENEMY := Color(1.0, 0.2, 0.2, 0.8)

const COLOR_ATTACK_TARGET := Color(1.0, 0.6, 0.0, 0.4)
const OUTLINE_ATTACK_TARGET := Color(1.0, 0.6, 0.0, 0.9)

const DIAMOND_INSET := 0.92

func _ready() -> void:
	grid_manager = get_tree().get_first_node_in_group("grid_manager") as GridManager

func _draw() -> void:
	if grid_manager == null:
		return

	for cell in reachable_cells:
		_draw_diamond(cell, COLOR_REACHABLE, OUTLINE_REACHABLE)

	for cell in path_cells:
		_draw_diamond(cell, COLOR_PATH, OUTLINE_PATH)

	for cell in enemy_cells:
		_draw_diamond(cell, COLOR_ENEMY, OUTLINE_ENEMY)

	for cell in attack_target_cells:
		_draw_diamond(cell, COLOR_ATTACK_TARGET, OUTLINE_ATTACK_TARGET)

	if grid_manager.is_cell_valid(hover_cell):
		_draw_diamond(hover_cell, COLOR_HOVER, OUTLINE_HOVER)

func _draw_diamond(cell: Vector2i, fill_color: Color, outline_color: Color) -> void:
	var center := grid_manager.grid_to_world(cell)
	var half_w := float(grid_manager.tile_size.x) / 2.0 * DIAMOND_INSET
	var half_h := float(grid_manager.tile_size.y) / 2.0 * DIAMOND_INSET

	var points := PackedVector2Array([
		center + Vector2(0, -half_h),
		center + Vector2(half_w, 0),
		center + Vector2(0, half_h),
		center + Vector2(-half_w, 0),
	])
	draw_colored_polygon(points, fill_color)

	for i in range(points.size()):
		draw_line(points[i], points[(i + 1) % points.size()], outline_color, 2.0)

func set_reachable(cells: Array[Vector2i]) -> void:
	reachable_cells = cells
	queue_redraw()

func set_path(cells: Array[Vector2i]) -> void:
	path_cells = cells
	queue_redraw()

func set_hover(cell: Vector2i) -> void:
	hover_cell = cell
	queue_redraw()

func set_enemies(cells: Array[Vector2i]) -> void:
	enemy_cells = cells
	queue_redraw()

func set_attack_targets(cells: Array[Vector2i]) -> void:
	attack_target_cells = cells
	queue_redraw()

func clear_all() -> void:
	reachable_cells = []
	path_cells = []
	hover_cell = Vector2i(-1, -1)
	enemy_cells = []
	attack_target_cells = []
	queue_redraw()
