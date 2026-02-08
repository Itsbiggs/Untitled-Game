extends Unit

var _anim_timer := 0.0
const ANIM_SPEED := 0.15
const IDLE_ROW := 3  # North-East row (flipped to North-West via flip_h)

func _ready() -> void:
	move_range = 3
	is_player_unit = false
	$Sprite2D.frame = IDLE_ROW * $Sprite2D.hframes

func _process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= ANIM_SPEED:
		_anim_timer -= ANIM_SPEED
		var sprite := $Sprite2D as Sprite2D
		var col := (sprite.frame % sprite.hframes + 1) % sprite.hframes
		sprite.frame = IDLE_ROW * sprite.hframes + col

func take_turn(player_units: Array[Unit]) -> void:
	if player_units.size() == 0:
		movement_finished.emit()
		return

	var nearest: Unit = null
	var nearest_dist := INF
	for pu in player_units:
		var dist := _grid_distance(grid_position, pu.grid_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = pu

	if nearest == null:
		movement_finished.emit()
		return

	grid_manager.unregister_unit(grid_position)
	var target_cell := nearest.grid_position
	grid_manager.unregister_unit(target_cell)

	var full_path := grid_manager.get_path_cells(grid_position, target_cell)

	grid_manager.register_unit(nearest, target_cell)
	grid_manager.register_unit(self, grid_position)

	if full_path.size() <= 1:
		movement_finished.emit()
		return

	var move_path: Array[Vector2i] = []
	for i in range(1, full_path.size()):
		if move_path.size() >= move_range:
			break
		var cell := full_path[i]
		if grid_manager.get_unit_at(cell) != null:
			break
		move_path.append(cell)

	if move_path.size() == 0:
		movement_finished.emit()
		return

	move_along_path(move_path)

func _grid_distance(a: Vector2i, b: Vector2i) -> float:
	return maxf(absf(a.x - b.x), absf(a.y - b.y))
