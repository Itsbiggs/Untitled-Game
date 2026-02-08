extends Node2D

signal cell_hovered(cell: Vector2i)
signal cell_clicked(cell: Vector2i)

var grid_manager: GridManager
var current_cell := Vector2i(-1, -1)
var enabled := true

func _ready() -> void:
	grid_manager = get_tree().get_first_node_in_group("grid_manager") as GridManager

func _process(_delta: float) -> void:
	if not enabled or grid_manager == null:
		return
	var mouse_pos := get_global_mouse_position()
	var cell := grid_manager.world_to_grid(mouse_pos)
	if cell != current_cell:
		current_cell = cell
		cell_hovered.emit(cell)

func _unhandled_input(event: InputEvent) -> void:
	if not enabled or grid_manager == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var mouse_pos := get_global_mouse_position()
			var cell := grid_manager.world_to_grid(mouse_pos)
			cell_clicked.emit(cell)
			get_viewport().set_input_as_handled()
