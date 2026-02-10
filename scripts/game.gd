extends Node2D

enum GamePhase { SELECTING, MOVING, ATTACKING, ENEMY_TURN, GAME_OVER }

var grid_manager: GridManager
var grid_cursor: Node2D
var grid_highlight: Node2D
var turn_manager: TurnManager
var turn_label: Label

var selected_unit: Unit = null
var reachable_cells: Array[Vector2i] = []
var attack_target_cells: Array[Vector2i] = []
var player_units: Array[Unit] = []
var enemy_units: Array[Unit] = []
var phase: GamePhase = GamePhase.SELECTING

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
			child.unit_died.connect(_on_unit_died)
			if child.is_player_unit:
				player_units.append(child)
			else:
				enemy_units.append(child)

func _on_cell_hovered(cell: Vector2i) -> void:
	if phase == GamePhase.GAME_OVER:
		return

	if phase == GamePhase.ATTACKING:
		grid_highlight.set_hover(cell)
		return

	if phase != GamePhase.SELECTING:
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
	if phase == GamePhase.GAME_OVER:
		return

	if phase == GamePhase.ATTACKING:
		_handle_attack_click(cell)
		return

	if phase != GamePhase.SELECTING:
		return

	# Click on selected unit's own cell → skip move, go to attack phase
	if selected_unit and cell == selected_unit.grid_position:
		var unit := selected_unit
		_deselect_unit()
		unit.has_moved = true
		_enter_attack_phase(unit)
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

	# DEBUG: Print what's happening
	print("=== SELECTING UNIT ===")
	print("Unit position: ", unit.grid_position)
	print("Move range: ", unit.move_range)
	
	reachable_cells = grid_manager.get_reachable_cells(unit.grid_position, unit.move_range)
	
	print("Reachable cells found: ", reachable_cells.size())
	print("First 10 cells: ", reachable_cells.slice(0, 10))
	
	grid_highlight.set_reachable(reachable_cells)

func _deselect_unit() -> void:
	if selected_unit:
		selected_unit.modulate = Color.WHITE
		selected_unit = null
	reachable_cells = []
	attack_target_cells = []
	grid_highlight.clear_all()

func _move_selected_unit(target_cell: Vector2i) -> void:
	var unit := selected_unit
	_deselect_unit()

	phase = GamePhase.MOVING
	grid_cursor.enabled = false

	grid_manager.unregister_unit(unit.grid_position)
	var path := grid_manager.get_path_cells(unit.grid_position, target_cell)
	grid_manager.register_unit(unit, unit.grid_position)

	if path.size() > 0:
		path.remove_at(0)

	unit.movement_finished.connect(_on_player_move_finished.bind(unit), CONNECT_ONE_SHOT)
	unit.move_along_path(path)

func _on_player_move_finished(unit: Unit) -> void:
	_enter_attack_phase(unit)

func _enter_attack_phase(unit: Unit) -> void:
	var targets := unit.get_attack_targets()
	if targets.size() == 0:
		_unit_turn_done(unit)
		return

	# Show attack targets
	phase = GamePhase.ATTACKING
	selected_unit = unit
	selected_unit.modulate = Color(1.2, 1.2, 1.5)
	grid_cursor.enabled = true

	attack_target_cells = []
	for t in targets:
		attack_target_cells.append(t.grid_position)

	var typed_targets: Array[Vector2i] = []
	typed_targets.assign(attack_target_cells)
	grid_highlight.set_attack_targets(typed_targets)

func _handle_attack_click(cell: Vector2i) -> void:
	if cell in attack_target_cells:
		var target := grid_manager.get_unit_at(cell) as Unit
		if target:
			var unit := selected_unit
			unit.modulate = Color.WHITE
			selected_unit = null
			grid_highlight.clear_all()
			grid_cursor.enabled = false
			phase = GamePhase.MOVING  # Reuse MOVING to block input during animation

			unit.attack_finished.connect(_on_player_attack_finished.bind(unit), CONNECT_ONE_SHOT)
			unit.play_attack_anim(target)
			return

	# Clicked elsewhere — skip attack
	_skip_attack()

func _skip_attack() -> void:
	var unit := selected_unit
	if unit:
		unit.modulate = Color.WHITE
	selected_unit = null
	attack_target_cells = []
	grid_highlight.clear_all()
	if unit:
		_unit_turn_done(unit)

func _on_player_attack_finished(unit: Unit) -> void:
	_check_game_over()
	if phase == GamePhase.GAME_OVER:
		return
	_unit_turn_done(unit)

func _unit_turn_done(unit: Unit) -> void:
	unit.has_moved = true
	unit.has_attacked = true

	var all_done := true
	for pu in player_units:
		if not pu.has_moved:
			all_done = false
			break

	if all_done:
		phase = GamePhase.SELECTING
		turn_manager.end_player_turn()
	else:
		phase = GamePhase.SELECTING
		grid_cursor.enabled = true
		turn_manager.current_state = TurnManager.TurnState.PLAYER_TURN

func _on_player_turn_started() -> void:
	phase = GamePhase.SELECTING
	grid_cursor.enabled = true
	for pu in player_units:
		pu.reset_turn()

func _on_enemy_turn_started() -> void:
	phase = GamePhase.ENEMY_TURN
	grid_cursor.enabled = false
	grid_highlight.clear_all()
	_run_enemy_turns()

func _run_enemy_turns() -> void:
	# Copy array since enemies may die during their turns (from counter-effects, etc.)
	var enemies_this_turn := enemy_units.duplicate()
	for enemy in enemies_this_turn:
		if not is_instance_valid(enemy):
			continue
		enemy.reset_turn()
		var typed_players: Array[Unit] = []
		for pu in player_units:
			if is_instance_valid(pu):
				typed_players.append(pu)
		enemy.take_turn(typed_players)
		await enemy.movement_finished
		_check_game_over()
		if phase == GamePhase.GAME_OVER:
			return
		await get_tree().create_timer(0.3).timeout

	turn_manager.end_enemy_turn()

func _on_unit_died(unit: Unit) -> void:
	player_units.erase(unit)
	enemy_units.erase(unit)

func _check_game_over() -> void:
	if player_units.size() == 0:
		_game_over(false)
	elif enemy_units.size() == 0:
		_game_over(true)

func _game_over(victory: bool) -> void:
	phase = GamePhase.GAME_OVER
	grid_cursor.enabled = false
	grid_highlight.clear_all()
	if victory:
		turn_label.text = "Victory!"
	else:
		turn_label.text = "Defeat!"

func _on_turn_changed(turn_name: String) -> void:
	if phase != GamePhase.GAME_OVER:
		turn_label.text = turn_name

func _unhandled_input(event: InputEvent) -> void:
	if phase == GamePhase.GAME_OVER:
		return

	if event.is_action_pressed("end_turn") and phase == GamePhase.SELECTING:
		_deselect_unit()
		turn_manager.end_player_turn()

	# Right-click to skip attack
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed and phase == GamePhase.ATTACKING:
			_skip_attack()
			get_viewport().set_input_as_handled()
