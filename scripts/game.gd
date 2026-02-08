extends Node2D

var grid_manager: GridManager
var grid_cursor: Node2D
var grid_highlight: Node2D
var turn_manager: TurnManager
var turn_label: Label

var selected_unit: Unit = null
var reachable_cells: Array[Vector2i] = []
var player_units: Array[Unit] = []
var enemy_units: Array[Unit] = []

func _ready() -> void:
	turn_manager = $TurnManager as TurnManager
	grid_manager = $BattleMap/GridManager as GridManager
	grid_cursor = $GridCursor
	grid_highlight = $GridHighlight
	turn_label = $UI/TurnLabel

	grid_cursor.grid_manager = grid_manager
	grid_highlight.grid_manager = grid_manager

	grid_cursor.cell_hovered.connect(_on_cell_hovered)
	grid_cursor.cell_clicked.connect(_on_cell_clicked)
	turn_manager.player_turn_started.connect(_on_player_turn_started)
	turn_manager.enemy_turn_started.connect(_on_enemy_turn_started)
	turn_manager.turn_changed.connect(_on_turn_changed)

	_setup_units()

	# Center camera on grid
	var bounds := grid_manager.grid_bounds
	var center_cell := Vector2i(
		bounds.position.x + bounds.size.x / 2,
		bounds.position.y + bounds.size.y / 2
	)
	$Camera2D.position = grid_manager.grid_to_world(center_cell)

	turn_manager.start_game()

func _setup_units() -> void:
	var units_container := $Units
	for child in units_container.get_children():
		if child is Unit:
			child.setup(grid_manager, child.get_meta("start_cell", Vector2i(0, 0)))
			if child.is_player_unit:
				player_units.append(child)
			else:
				enemy_units.append(child)

func _on_cell_hovered(cell: Vector2i) -> void:
	if not turn_manager.is_player_turn():
		return

	grid_highlight.set_hover(cell)

	if selected_unit and cell in reachable_cells:
		grid_manager.unregister_unit(selected_unit.grid_position)
		var path := grid_manager.get_path_cells(selected_unit.grid_position, cell)
		grid_manager.register_unit(selected_unit, selected_unit.grid_position)
		if path.size() > 0:
			path.remove_at(0)
		var typed_path: Array[Vector2i] = []
		typed_path.assign(path)
		grid_highlight.set_path(typed_path)
	else:
		var empty_path: Array[Vector2i] = []
		grid_highlight.set_path(empty_path)

func _on_cell_clicked(cell: Vector2i) -> void:
	if not turn_manager.is_player_turn():
		return

	if selected_unit and cell in reachable_cells:
		_move_selected_unit(cell)
		return

	var unit_at_cell := grid_manager.get_unit_at(cell)
	if unit_at_cell is Unit and unit_at_cell.is_player_unit and not unit_at_cell.has_moved:
		_select_unit(unit_at_cell)
		return

	_deselect_unit()

func _select_unit(unit: Unit) -> void:
	_deselect_unit()
	selected_unit = unit
	selected_unit.modulate = Color(1.2, 1.2, 1.5)

	reachable_cells = grid_manager.get_reachable_cells(unit.grid_position, unit.move_range)
	grid_highlight.set_reachable(reachable_cells)

	var ecells: Array[Vector2i] = []
	for e in enemy_units:
		ecells.append(e.grid_position)
	grid_highlight.set_enemies(ecells)

func _deselect_unit() -> void:
	if selected_unit:
		selected_unit.modulate = Color.WHITE
		selected_unit = null
	reachable_cells = []
	grid_highlight.clear_all()

func _move_selected_unit(target_cell: Vector2i) -> void:
	var unit := selected_unit
	_deselect_unit()

	turn_manager.set_animating()
	grid_cursor.enabled = false

	grid_manager.unregister_unit(unit.grid_position)
	var path := grid_manager.get_path_cells(unit.grid_position, target_cell)
	grid_manager.register_unit(unit, unit.grid_position)

	if path.size() > 0:
		path.remove_at(0)

	unit.movement_finished.connect(_on_player_move_finished.bind(unit), CONNECT_ONE_SHOT)
	unit.move_along_path(path)

func _on_player_move_finished(_unit: Unit) -> void:
	var all_moved := true
	for pu in player_units:
		if not pu.has_moved:
			all_moved = false
			break

	if all_moved:
		turn_manager.end_player_turn()
	else:
		grid_cursor.enabled = true
		turn_manager.current_state = TurnManager.TurnState.PLAYER_TURN

func _on_player_turn_started() -> void:
	grid_cursor.enabled = true
	for pu in player_units:
		pu.reset_turn()

func _on_enemy_turn_started() -> void:
	grid_cursor.enabled = false
	grid_highlight.clear_all()
	_run_enemy_turns()

func _run_enemy_turns() -> void:
	for enemy in enemy_units:
		enemy.reset_turn()
		var typed_players: Array[Unit] = []
		for pu in player_units:
			typed_players.append(pu)
		enemy.take_turn(typed_players)
		await enemy.movement_finished
		await get_tree().create_timer(0.3).timeout

	turn_manager.end_enemy_turn()

func _on_turn_changed(turn_name: String) -> void:
	turn_label.text = turn_name

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("end_turn") and turn_manager.is_player_turn():
		_deselect_unit()
		turn_manager.end_player_turn()
