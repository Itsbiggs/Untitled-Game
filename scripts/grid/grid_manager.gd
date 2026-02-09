class_name GridManager
extends Node2D

## SIGNALS ##
signal tile_effect_added(cell: Vector2i, effect_type: String)
signal tile_effect_removed(cell: Vector2i, effect_type: String)
signal unit_registered(unit: Node2D, cell: Vector2i)
signal unit_unregistered(unit: Node2D, cell: Vector2i)

## CORE GRID DATA ##
var astar: AStarGrid2D
var ground_layer: TileMapLayer
var valid_cells: Dictionary = {} # Vector2i -> true
var grid_bounds: Rect2i
var tile_size: Vector2i
@export var ground_layer_name: String = "Ground"
@export var walls_layer_name: String = "Walls"

## UNIT TRACKING ##
var occupied_cells: Dictionary = {} # Vector2i -> Unit
var units_by_team: Dictionary = {} # "player" or "enemy" -> Array[Unit]

## TILE EFFECTS SYSTEM ##
# For persistent tile effects like burning tiles, hexes, shield walls
var tile_effects: Dictionary = {} # Vector2i -> Array[TileEffect]
var shield_walls: Dictionary = {} # Vector2i -> ShieldWall (blocks movement/projectiles)

## MOVEMENT COSTS ##
# Different terrain types can have different movement costs
var terrain_costs: Dictionary = {} # Vector2i -> int (default is 1)

## LINE OF SIGHT CACHE ##
# Cache LOS calculations to avoid recalculating every frame
var los_cache: Dictionary = {} # "{from}_{to}" -> bool
var los_cache_max_size: int = 1000

## CONSTANTS ##
const DEFAULT_MOVE_COST: int = 1
const DIAGONAL_MOVE_COST_MULTIPLIER: float = 1.414 # sqrt(2)

## TILE EFFECT TYPES ##
enum TileEffectType {
	BURNING,      # Ember Blade - damages units standing on it
	HEX_SLOW,     # Hexweaver - slows movement
	HEX_WEAKEN,   # Hexweaver - reduces damage
	HEX_SILENCE,  # Hexweaver - prevents ability use
	SHIELD_WALL,  # Bulwark - blocks movement/projectiles
	HEAL_ZONE,    # Support - healing area
	DAMAGE_ZONE,  # Generic damage area
}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("grid_manager")
	ground_layer = get_parent().get_node(ground_layer_name) as TileMapLayer
	tile_size = ground_layer.tile_set.tile_size
	
	_scan_ground()
	_setup_astar()
	_scan_walls()
	_initialize_teams()
	
	# Debug output
	_print_grid_info()

func _initialize_teams() -> void:
	units_by_team["player"] = []
	units_by_team["enemy"] = []

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
	var walls_layer = get_parent().get_node_or_null(walls_layer_name) as TileMapLayer
	if walls_layer == null:
		return
	
	var used := walls_layer.get_used_cells()
	for cell in used:
		if valid_cells.has(cell):
			astar.set_point_solid(cell, true)
			# Optionally add high movement cost instead of blocking
			# terrain_costs[cell] = 999

func _print_grid_info() -> void:
	print("=== GRID MANAGER INITIALIZED ===")
	print("Grid Bounds: ", grid_bounds)
	print("Valid Cells: ", valid_cells.size())
	print("Tile Size: ", tile_size)
	var pos0 := grid_to_world(Vector2i(0, 0))
	var pos1 := grid_to_world(Vector2i(1, 0))
	print("Cell Spacing: ", pos1 - pos0)

# ============================================================================
# COORDINATE CONVERSION
# ============================================================================

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return ground_layer.map_to_local(grid_pos)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return ground_layer.local_to_map(ground_layer.to_local(world_pos))

# ============================================================================
# CELL VALIDATION
# ============================================================================

func is_cell_valid(cell: Vector2i) -> bool:
	return valid_cells.has(cell)

func is_cell_walkable(cell: Vector2i, ignore_units: bool = false) -> bool:
	if not is_cell_valid(cell):
		return false
	
	# Check for shield walls
	if shield_walls.has(cell):
		return false
	
	# Check for units
	if not ignore_units and occupied_cells.has(cell):
		return false
	
	# Check if AStar considers it solid (walls)
	if astar.is_point_solid(cell):
		return false
	
	return true

func is_cell_occupied(cell: Vector2i) -> bool:
	return occupied_cells.has(cell)

func is_cell_blocked_by_wall(cell: Vector2i) -> bool:
	if not is_cell_valid(cell):
		return true
	return astar.is_point_solid(cell)

# ============================================================================
# UNIT REGISTRATION & TRACKING
# ============================================================================

func register_unit(unit: Node2D, cell: Vector2i, team: String = "") -> void:
	if not is_cell_valid(cell):
		push_warning("Attempting to register unit at invalid cell: ", cell)
		return
	
	# Unregister from old position if exists
	for old_cell in occupied_cells.keys():
		if occupied_cells[old_cell] == unit:
			unregister_unit(old_cell)
			break
	
	occupied_cells[cell] = unit
	astar.set_point_solid(cell, true)
	
	# Track by team
	if team != "" and units_by_team.has(team):
		if unit not in units_by_team[team]:
			units_by_team[team].append(unit)
	
	unit_registered.emit(unit, cell)

func unregister_unit(cell: Vector2i) -> void:
	if not occupied_cells.has(cell):
		return
	
	var unit = occupied_cells[cell]
	occupied_cells.erase(cell)
	
	# Only unsolid if it's a valid walkable tile
	if valid_cells.has(cell) and not shield_walls.has(cell):
		astar.set_point_solid(cell, false)
	
	unit_unregistered.emit(unit, cell)

func move_unit(unit: Node2D, from: Vector2i, to: Vector2i) -> void:
	if not occupied_cells.has(from) or occupied_cells[from] != unit:
		push_warning("Attempting to move unregistered unit")
		return
	
	unregister_unit(from)
	
	# Get team from unit if it has the property
	var team := ""
	if unit.has_method("get_team"):
		team = unit.get_team()
	elif unit.get("is_player_unit") != null:
		team = "player" if unit.is_player_unit else "enemy"
	
	register_unit(unit, to, team)

func get_unit_at(cell: Vector2i) -> Node2D:
	return occupied_cells.get(cell, null)

func get_units_by_team(team: String) -> Array:
	return units_by_team.get(team, [])

func get_all_units() -> Array[Node2D]:
	var all_units: Array[Node2D] = []
	for unit in occupied_cells.values():
		if unit not in all_units:
			all_units.append(unit)
	return all_units

func get_unit_position(unit: Node2D) -> Vector2i:
	for cell in occupied_cells.keys():
		if occupied_cells[cell] == unit:
			return cell
	return Vector2i(-9999, -9999) # Invalid position

# ============================================================================
# PATHFINDING & MOVEMENT
# ============================================================================

func get_path_cells(from: Vector2i, to: Vector2i, ignore_unit_at_destination: bool = true) -> Array[Vector2i]:
	if not is_cell_valid(from) or not is_cell_valid(to):
		return []
	
	# Temporarily allow pathfinding to destination even if occupied
	var dest_was_solid := false
	if ignore_unit_at_destination and occupied_cells.has(to):
		dest_was_solid = true
		astar.set_point_solid(to, false)
	
	var id_path := astar.get_id_path(from, to)
	var result: Array[Vector2i] = []
	for p in id_path:
		result.append(Vector2i(p))
	
	# Restore destination state
	if dest_was_solid:
		astar.set_point_solid(to, true)
	
	return result

func get_movement_cost(from: Vector2i, to: Vector2i) -> int:
	var base_cost: float = terrain_costs.get(to, DEFAULT_MOVE_COST)
	
	# Add diagonal cost multiplier
	if abs(to.x - from.x) == 1 and abs(to.y - from.y) == 1:
		base_cost = roundi(base_cost * DIAGONAL_MOVE_COST_MULTIPLIER)
	
	return base_cost

func get_reachable_cells(origin: Vector2i, max_distance: int, use_movement_cost: bool = false) -> Array[Vector2i]:
	var reachable: Array[Vector2i] = []
	var visited: Dictionary = {} # cell -> total_cost
	var queue: Array = [[origin, 0]]
	visited[origin] = 0
	
	while queue.size() > 0:
		var current = queue.pop_front()
		var cell: Vector2i = current[0]
		var cost: int = current[1]
		
		if cell != origin:
			reachable.append(cell)
		
		if cost >= max_distance:
			continue
		
		for neighbor in _get_neighbors(cell):
			if not is_cell_walkable(neighbor):
				continue
			
			var move_cost := 1
			if use_movement_cost:
				move_cost = get_movement_cost(cell, neighbor)
			
			var new_cost := cost + move_cost
			
			if new_cost > max_distance:
				continue
			
			# Only visit if we haven't seen this cell, or found a cheaper path
			if not visited.has(neighbor) or new_cost < visited[neighbor]:
				visited[neighbor] = new_cost
				queue.append([neighbor, new_cost])
	
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

# ============================================================================
# LINE OF SIGHT & ATTACK RANGE
# ============================================================================

func has_line_of_sight(from: Vector2i, to: Vector2i, ignore_units: bool = true) -> bool:
	# Check cache first
	var cache_key := str(from) + "_" + str(to)
	if los_cache.has(cache_key):
		return los_cache[cache_key]
	
	var has_los := _calculate_line_of_sight(from, to, ignore_units)
	
	# Cache result
	los_cache[cache_key] = has_los
	if los_cache.size() > los_cache_max_size:
		# Simple cache cleanup - remove random entries
		var keys := los_cache.keys()
		los_cache.erase(keys[0])
	
	return has_los

func _calculate_line_of_sight(from: Vector2i, to: Vector2i, ignore_units: bool) -> bool:
	# Use Bresenham's line algorithm to check each cell in the line
	var cells := get_line_cells(from, to)
	
	for i in range(1, cells.size() - 1): # Skip start and end
		var cell := cells[i]
		
		# Check for walls/solid tiles
		if is_cell_blocked_by_wall(cell):
			return false
		
		# Check for shield walls
		if shield_walls.has(cell):
			return false
		
		# Optionally check for units
		if not ignore_units and is_cell_occupied(cell):
			return false
	
	return true

func get_line_cells(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	# Bresenham's line algorithm
	var cells: Array[Vector2i] = []
	var x0 := from.x
	var y0 := from.y
	var x1 := to.x
	var y1 := to.y
	
	var dx: int = abs(x1 - x0)
	var dy: int = abs(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err: int = dx - dy
	
	while true:
		cells.append(Vector2i(x0, y0))
		
		if x0 == x1 and y0 == y1:
			break
		
		var e2 := 2 * err
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy
	
	return cells

func clear_los_cache() -> void:
	los_cache.clear()

# ============================================================================
# SPATIAL QUERIES (AOE, SHAPES, PATTERNS)
# ============================================================================

func get_cells_in_radius(center: Vector2i, radius: int, only_walkable: bool = false) -> Array[Vector2i]:
	"""Get all cells within a circular radius"""
	var cells: Array[Vector2i] = []
	
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var cell := Vector2i(x, y)
			if not is_cell_valid(cell):
				continue
			
			var distance := get_grid_distance(center, cell)
			if distance <= radius:
				if only_walkable and not is_cell_walkable(cell, true):
					continue
				cells.append(cell)
	
	return cells

func get_cells_in_square(center: Vector2i, size: int) -> Array[Vector2i]:
	"""Get all cells in a square area (size x size)"""
	var cells: Array[Vector2i] = []
	var half := size / 2
	
	for y in range(center.y - half, center.y + half + 1):
		for x in range(center.x - half, center.x + half + 1):
			var cell := Vector2i(x, y)
			if is_cell_valid(cell):
				cells.append(cell)
	
	return cells

func get_cells_in_cone(origin: Vector2i, direction: Vector2i, skillrange: int, cone_width: int) -> Array[Vector2i]:
	"""Get cells in a cone shape (for abilities like breath weapons)"""
	var cells: Array[Vector2i] = []
	
	# Normalize direction
	var dir := Vector2(direction).normalized()
	
	for y in range(grid_bounds.position.y, grid_bounds.end.y):
		for x in range(grid_bounds.position.x, grid_bounds.end.x):
			var cell := Vector2i(x, y)
			if not is_cell_valid(cell) or cell == origin:
				continue
			
			var to_cell := Vector2(cell - origin)
			var distance := to_cell.length()
			
			if distance > skillrange:
				continue
			
			# Check if cell is within cone angle
			var angle := to_cell.normalized().dot(dir)
			var cone_angle := 1.0 - (cone_width / 10.0) # Convert width to angle threshold
			
			if angle >= cone_angle:
				cells.append(cell)
	
	return cells

func get_cells_in_cross(center: Vector2i, arm_length: int) -> Array[Vector2i]:
	"""Get cells in a + pattern"""
	var cells: Array[Vector2i] = []
	
	# Horizontal
	for x in range(center.x - arm_length, center.x + arm_length + 1):
		var cell := Vector2i(x, center.y)
		if is_cell_valid(cell):
			cells.append(cell)
	
	# Vertical
	for y in range(center.y - arm_length, center.y + arm_length + 1):
		var cell := Vector2i(center.x, y)
		if is_cell_valid(cell) and cell not in cells:
			cells.append(cell)
	
	return cells

func get_adjacent_cells(cell: Vector2i, include_diagonals: bool = true) -> Array[Vector2i]:
	"""Get all adjacent cells"""
	var adjacent: Array[Vector2i] = []
	var offsets: Array[Vector2i]
	
	if include_diagonals:
		offsets = [
			Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1),
		]
	else:
		offsets = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	
	for offset in offsets:
		var adj := cell + offset
		if is_cell_valid(adj):
			adjacent.append(adj)
	
	return adjacent

func get_grid_distance(from: Vector2i, to: Vector2i) -> int:
	"""Manhattan distance between two cells"""
	return abs(to.x - from.x) + abs(to.y - from.y)

func get_euclidean_distance(from: Vector2i, to: Vector2i) -> float:
	"""Straight-line distance"""
	var diff := to - from
	return sqrt(diff.x * diff.x + diff.y * diff.y)

# ============================================================================
# UNITS IN RANGE QUERIES
# ============================================================================

func get_units_in_radius(center: Vector2i, radius: int, team: String = "") -> Array[Node2D]:
	"""Get all units within radius of a cell"""
	var units: Array[Node2D] = []
	var cells := get_cells_in_radius(center, radius)
	
	for cell in cells:
		var unit := get_unit_at(cell)
		if unit != null:
			if team == "":
				units.append(unit)
			elif unit.has_method("get_team") and unit.get_team() == team:
				units.append(unit)
			elif unit.get("is_player_unit") != null:
				var unit_team := "player" if unit.is_player_unit else "enemy"
				if unit_team == team:
					units.append(unit)
	
	return units

func get_closest_unit(from: Vector2i, team: String = "", max_range: int = 999) -> Node2D:
	"""Find closest unit to a position"""
	var closest: Node2D = null
	var closest_dist := 999999
	
	var units := get_all_units() if team == "" else get_units_by_team(team)
	
	for unit in units:
		var unit_pos := get_unit_position(unit)
		var dist := get_grid_distance(from, unit_pos)
		
		if dist <= max_range and dist < closest_dist:
			closest = unit
			closest_dist = dist
	
	return closest

func get_units_in_line(from: Vector2i, to: Vector2i) -> Array[Node2D]:
	"""Get all units in a line between two points"""
	var units: Array[Node2D] = []
	var cells := get_line_cells(from, to)
	
	for cell in cells:
		var unit := get_unit_at(cell)
		if unit != null and unit not in units:
			units.append(unit)
	
	return units

# ============================================================================
# TILE EFFECTS SYSTEM
# ============================================================================

class TileEffect:
	var type: TileEffectType
	var duration: int # -1 for permanent
	var source_unit: Node2D # Who created this effect
	var damage: int = 0
	var metadata: Dictionary = {} # For custom data
	
	func _init(p_type: TileEffectType, p_duration: int = -1, p_source: Node2D = null):
		type = p_type
		duration = p_duration
		source_unit = p_source

func add_tile_effect(cell: Vector2i, effect: TileEffect) -> void:
	if not is_cell_valid(cell):
		return
	
	if not tile_effects.has(cell):
		tile_effects[cell] = []
	
	tile_effects[cell].append(effect)
	tile_effect_added.emit(cell, TileEffectType.keys()[effect.type])
	
	# Update pathfinding if needed (e.g., shield walls)
	if effect.type == TileEffectType.SHIELD_WALL:
		shield_walls[cell] = effect
		astar.set_point_solid(cell, true)

func remove_tile_effect(cell: Vector2i, effect: TileEffect) -> void:
	if not tile_effects.has(cell):
		return
	
	tile_effects[cell].erase(effect)
	
	if tile_effects[cell].size() == 0:
		tile_effects.erase(cell)
	
	tile_effect_removed.emit(cell, TileEffectType.keys()[effect.type])
	
	# Update pathfinding
	if effect.type == TileEffectType.SHIELD_WALL:
		shield_walls.erase(cell)
		if not is_cell_occupied(cell):
			astar.set_point_solid(cell, false)

func get_tile_effects(cell: Vector2i) -> Array:
	return tile_effects.get(cell, [])

func has_tile_effect_type(cell: Vector2i, effect_type: TileEffectType) -> bool:
	var effects := get_tile_effects(cell)
	for effect in effects:
		if effect.type == effect_type:
			return true
	return false

func clear_tile_effects(cell: Vector2i) -> void:
	if not tile_effects.has(cell):
		return
	
	var effects:Array = tile_effects[cell].duplicate()
	for effect in effects:
		remove_tile_effect(cell, effect)

func process_tile_effects_turn() -> void:
	"""Call this each turn to update tile effect durations"""
	var cells_to_clear: Array[Vector2i] = []
	
	for cell in tile_effects.keys():
		var effects: Array = tile_effects[cell]
		var effects_to_remove: Array = []
		
		for effect in effects:
			if effect.duration > 0:
				effect.duration -= 1
				if effect.duration == 0:
					effects_to_remove.append(effect)
		
		for effect in effects_to_remove:
			remove_tile_effect(cell, effect)
		
		if tile_effects.get(cell, []).size() == 0:
			cells_to_clear.append(cell)
	
	for cell in cells_to_clear:
		tile_effects.erase(cell)

func get_all_burning_tiles() -> Array[Vector2i]:
	"""Helper for Ember Blade abilities"""
	var burning: Array[Vector2i] = []
	for cell in tile_effects.keys():
		if has_tile_effect_type(cell, TileEffectType.BURNING):
			burning.append(cell)
	return burning

func get_all_hex_tiles() -> Array[Vector2i]:
	"""Helper for Hexweaver abilities"""
	var hexed: Array[Vector2i] = []
	for cell in tile_effects.keys():
		var effects := get_tile_effects(cell)
		for effect in effects:
			if effect.type in [TileEffectType.HEX_SLOW, TileEffectType.HEX_WEAKEN, TileEffectType.HEX_SILENCE]:
				hexed.append(cell)
				break
	return hexed

# ============================================================================
# TERRAIN MODIFICATION
# ============================================================================

func set_terrain_cost(cell: Vector2i, cost: int) -> void:
	"""Set custom movement cost for a tile"""
	terrain_costs[cell] = cost

func clear_terrain_cost(cell: Vector2i) -> void:
	terrain_costs.erase(cell)

# ============================================================================
# DEBUG & UTILITIES
# ============================================================================

func get_grid_info() -> Dictionary:
	return {
		"bounds": grid_bounds,
		"valid_cells": valid_cells.size(),
		"occupied_cells": occupied_cells.size(),
		"tile_effects": tile_effects.size(),
		"shield_walls": shield_walls.size(),
		"player_units": units_by_team.get("player", []).size(),
		"enemy_units": units_by_team.get("enemy", []).size(),
	}

func print_grid_state() -> void:
	print("=== GRID STATE ===")
	var info := get_grid_info()
	for key in info.keys():
		print(key, ": ", info[key])

# Optional: Visual debug drawing
func _draw() -> void:
	if not Engine.is_editor_hint() and OS.is_debug_build():
		_debug_draw_tile_effects()

func _debug_draw_tile_effects() -> void:
	for cell in tile_effects.keys():
		var world_pos := grid_to_world(cell)
		var effects := get_tile_effects(cell)
		
		for effect in effects:
			var color := Color.WHITE
			match effect.type:
				TileEffectType.BURNING:
					color = Color.ORANGE_RED
				TileEffectType.HEX_SLOW:
					color = Color.PURPLE
				TileEffectType.SHIELD_WALL:
					color = Color.STEEL_BLUE
				TileEffectType.HEAL_ZONE:
					color = Color.GREEN
			
			draw_circle(world_pos, tile_size.x / 4, color)
