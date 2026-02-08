class_name Unit
extends Node2D

signal movement_finished

@export var move_range: int = 3
@export var is_player_unit: bool = false

var grid_position: Vector2i
var is_moving: bool = false
var has_moved: bool = false

var grid_manager: GridManager

func setup(gm: GridManager, start_cell: Vector2i) -> void:
	grid_manager = gm
	grid_position = start_cell
	position = grid_manager.grid_to_world(start_cell)
	grid_manager.register_unit(self, start_cell)

func move_along_path(path: Array[Vector2i]) -> void:
	if path.size() == 0:
		movement_finished.emit()
		return

	is_moving = true
	var old_cell := grid_position

	for i in range(path.size()):
		var cell := path[i]
		var target_pos := grid_manager.grid_to_world(cell)
		var tween := create_tween()
		tween.tween_property(self, "position", target_pos, 0.15)
		await tween.finished

	grid_position = path[path.size() - 1]
	grid_manager.move_unit(self, old_cell, grid_position)
	is_moving = false
	has_moved = true
	movement_finished.emit()

func reset_turn() -> void:
	has_moved = false
