class_name TurnManager
extends Node

signal player_turn_started
signal enemy_turn_started
signal turn_changed(turn_name: String)

enum TurnState { PLAYER_TURN, ENEMY_TURN, ANIMATING }

var current_state: TurnState = TurnState.PLAYER_TURN
var turn_count: int = 0

func start_game() -> void:
	turn_count = 1
	_set_state(TurnState.PLAYER_TURN)

func _set_state(new_state: TurnState) -> void:
	current_state = new_state
	match new_state:
		TurnState.PLAYER_TURN:
			turn_changed.emit("Player Turn")
			player_turn_started.emit()
		TurnState.ENEMY_TURN:
			turn_changed.emit("Enemy Turn")
			enemy_turn_started.emit()
		TurnState.ANIMATING:
			pass

func set_animating() -> void:
	current_state = TurnState.ANIMATING

func end_player_turn() -> void:
	_set_state(TurnState.ENEMY_TURN)

func end_enemy_turn() -> void:
	turn_count += 1
	_set_state(TurnState.PLAYER_TURN)

func is_player_turn() -> bool:
	return current_state == TurnState.PLAYER_TURN

func is_animating() -> bool:
	return current_state == TurnState.ANIMATING
