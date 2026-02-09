class_name GridManager
extends Node2D

var astar: AStarGrid2D
var occupied_cells: Dictionary = {} # Vector2i -> Unit
var ground_layer: TileMapLayer
var valid_cells: Dictionary = {} # Vector2i -> true
var grid_bounds: Rect2i
var tile_size: Vector2i

func _ready() -> void:
	add_to_group("grid_manager")
	ground_layer = get_parent().get_node("Ground") as TileMapLayer
	tile_size = ground_layer.tile_set.tile_size
	_scan_ground()
	_setup_astar()
	_scan_walls()

	# Debug: verify cell spacing vs tile_size
	var pos0 := grid_to_world(Vector2i(0, 0))
	var pos1 := grid_to_world(Vector2i(1, 0))
	print("tile_size: ", tile_size, " | cell spacing: ", pos1 - pos0)

func _scan_ground() -> void:
	var used := ground_layer.get_used_cells()
	var min_x := 99999
	var min_y := 99999
	var max_x := -99999
	var max_y := -99999
	for cell in used:
		valid_cells[cell] = true
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
		max_x = maxi(max_x, cell.x)
		max_y = maxi(max_y, cell.y)
	grid_bounds = Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _setup_astar() -> void:
	astar = AStarGrid2D.new()
	astar.region = grid_bounds
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	astar.cell_size = Vector2(1, 1)
	astar.update()

	# Mark all cells outside the valid set as solid
	for y in range(grid_bounds.position.y, grid_bounds.end.y):
		for x in range(grid_bounds.position.x, grid_bounds.end.x):
			var cell := Vector2i(x, y)
			if not valid_cells.has(cell):
				astar.set_point_solid(cell, true)

func _scan_walls() -> void:
	var walls_layer = get_parent().get_node_or_null("Walls") as TileMapLayer
	if walls_layer == null:
		return
	var used := walls_layer.get_used_cells()
	for cell in used:
		if valid_cells.has(cell):
			astar.set_point_solid(cell, true)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return ground_layer.map_to_local(grid_pos)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return ground_layer.local_to_map(ground_layer.to_local(world_pos))

func is_cell_valid(cell: Vector2i) -> bool:
	return valid_cells.has(cell)

func is_cell_walkable(cell: Vector2i) -> bool:
	if not is_cell_valid(cell):
		return false
	if occupied_cells.has(cell):
		return false
	return true

func get_reachable_cells(origin: Vector2i, max_distance: int) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var visited: Dictionary = {}
	var queue: Array = [[origin, 0]]
	visited[origin] = true

	while queue.size() > 0:
		var current = queue.pop_front()
		var cell: Vector2i = current[0]
		var dist: int = current[1]

		if cell != origin:
			reachable.append(cell)

		if dist >= max_distance:
			continue

		for neighbor in _get_neighbors(cell):
			if visited.has(neighbor):
				continue
			if not is_cell_walkable(neighbor):
				continue
			visited[neighbor] = true
			queue.append([neighbor, dist + 1])

	return reachable

func _get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, -1),
		Vector2i(1, -1), Vector2i(-1, 1),
	]
	for offset in offsets:
		var n := cell + offset
		if is_cell_valid(n):
			neighbors.append(n)
	return neighbors

func get_path_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if not is_cell_valid(from) or not is_cell_valid(to):
		return []
	var id_path := astar.get_id_path(from, to)
	var result: Array[Vector2i] = []
	for p in id_path:
		result.append(Vector2i(p))
	return result

func register_unit(unit: Node2D, cell: Vector2i) -> void:
	occupied_cells[cell] = unit
	astar.set_point_solid(cell, true)

func unregister_unit(cell: Vector2i) -> void:
	occupied_cells.erase(cell)
	if valid_cells.has(cell):
		astar.set_point_solid(cell, false)

func move_unit(unit: Node2D, from: Vector2i, to: Vector2i) -> void:
	unregister_unit(from)
	register_unit(unit, to)

func get_unit_at(cell: Vector2i) -> Node2D:
	return occupied_cells.get(cell, null)

func get_adjacent_units(cell: Vector2i, asking_unit: Node2D) -> Array[Unit]:
	var result: Array[Unit] = []
	var offsets: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, -1),
		Vector2i(1, -1), Vector2i(-1, 1),
	]
	for offset in offsets:
		var neighbor := cell + offset
		var unit = occupied_cells.get(neighbor, null)
		if unit is Unit and unit.is_player_unit != (asking_unit as Unit).is_player_unit:
			result.append(unit)
	return result
