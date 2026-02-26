class_name Unit
extends Node2D

signal movement_finished
signal unit_died(unit: Unit)
signal attack_finished

@export var move_range: int = 3
@export var is_player_unit: bool = false
@export var max_hp: int = 5
@export var attack_damage: int = 1
@export var attack_range: int = 1

@export var idle_texture: Texture2D
@export var attack_texture: Texture2D
@export var damage_texture: Texture2D
@export var die_texture: Texture2D

var grid_position: Vector2i
var is_moving: bool = false
var has_moved: bool = false
var has_attacked: bool = false
var hp: int

var grid_manager: GridManager
var health_bar: HealthBar
var _combat_sprite: Sprite2D

# Animation state
var _playing_oneshot: bool = false
var _oneshot_hframes: int = 0
var _oneshot_frame: int = 0
var _oneshot_row: int = 0
var _oneshot_timer: float = 0.0
var _oneshot_callback: Callable
var _damage_target: Unit = null
var _damage_frame: int = -1

const ATTACK_HFRAMES := 6
const DAMAGE_HFRAMES := 2
const DIE_HFRAMES := 6
const ONESHOT_SPEED := 0.12

func setup(gm: GridManager, start_cell: Vector2i) -> void:
	grid_manager = gm
	grid_position = start_cell
	position = grid_manager.grid_to_world(start_cell)
	grid_manager.register_unit(self, start_cell)
	hp = max_hp
	_combat_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _combat_sprite:
		idle_texture = _combat_sprite.texture
	_create_health_bar()

func _create_health_bar() -> void:
	health_bar = HealthBar.new()
	add_child(health_bar)
	health_bar.update_bar(hp, max_hp)

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
	has_attacked = false

func get_attack_targets() -> Array[Unit]:
	var targets: Array[Unit] = []
	if grid_manager == null:
		return targets
	var neighbors := grid_manager.get_adjacent_units(grid_position, self)
	for u in neighbors:
		targets.append(u)
	return targets

func play_attack_anim(target: Unit) -> void:
	if attack_texture == null or _combat_sprite == null:
		# No attack texture or no combat sprite, just deal damage directly
		target.take_damage(attack_damage)
		has_attacked = true
		attack_finished.emit()
		return

	_on_combat_anim_start()
	var dir_row := _get_direction_row(target.grid_position)
	_damage_target = target
	_damage_frame = 3  # Deal damage at frame 3 of 6

	_combat_sprite.texture = attack_texture
	_combat_sprite.hframes = ATTACK_HFRAMES
	_combat_sprite.vframes = 5
	_combat_sprite.frame = dir_row * ATTACK_HFRAMES

	_start_oneshot(ATTACK_HFRAMES, dir_row, func():
		_damage_target = null
		_damage_frame = -1
		var saved_row := dir_row
		_combat_sprite.texture = idle_texture
		_combat_sprite.hframes = 8
		_combat_sprite.vframes = 5
		_combat_sprite.frame = saved_row * _combat_sprite.hframes
		_on_combat_anim_end()
		has_attacked = true
		attack_finished.emit()
	)

func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	health_bar.update_bar(hp, max_hp)
	_spawn_floating_text(str(amount))

	if hp <= 0:
		_play_die_anim()
	elif damage_texture != null and _combat_sprite != null:
		_play_damage_anim()

func _play_damage_anim() -> void:
	_on_combat_anim_start()
	var dir_row := _get_current_direction_row()

	_combat_sprite.texture = damage_texture
	_combat_sprite.hframes = DAMAGE_HFRAMES
	_combat_sprite.vframes = 5
	_combat_sprite.frame = dir_row * DAMAGE_HFRAMES

	_start_oneshot(DAMAGE_HFRAMES, dir_row, func():
		var saved_row := dir_row
		_combat_sprite.texture = idle_texture
		_combat_sprite.hframes = 8
		_combat_sprite.vframes = 5
		_combat_sprite.frame = saved_row * _combat_sprite.hframes
		_on_combat_anim_end()
	)

func _play_die_anim() -> void:
	if die_texture == null or _combat_sprite == null:
		_finish_death()
		return

	_on_combat_anim_start()
	var dir_row := _get_current_direction_row()

	_combat_sprite.texture = die_texture
	_combat_sprite.hframes = DIE_HFRAMES
	_combat_sprite.vframes = 5
	_combat_sprite.frame = dir_row * DIE_HFRAMES

	_start_oneshot(DIE_HFRAMES, dir_row, func():
		_finish_death()
	)

func _finish_death() -> void:
	unit_died.emit(self)
	if grid_manager:
		grid_manager.unregister_unit(grid_position)
	queue_free()

func _spawn_floating_text(text: String) -> void:
	var ft := FloatingText.new()
	ft.text = text
	ft.position = Vector2(0, -160)
	get_parent().add_child(ft)
	ft.global_position = global_position + Vector2(0, -160)

func _start_oneshot(hframes: int, row: int, callback: Callable) -> void:
	_playing_oneshot = true
	_oneshot_hframes = hframes
	_oneshot_frame = 0
	_oneshot_row = row
	_oneshot_timer = 0.0
	_oneshot_callback = callback

func process_oneshot(delta: float) -> bool:
	if not _playing_oneshot:
		return false

	_oneshot_timer += delta
	if _oneshot_timer >= ONESHOT_SPEED:
		_oneshot_timer -= ONESHOT_SPEED
		_oneshot_frame += 1

		# Check if we should deal damage this frame
		if _damage_target != null and _oneshot_frame == _damage_frame and is_instance_valid(_damage_target):
			_damage_target.take_damage(attack_damage)

		if _oneshot_frame >= _oneshot_hframes:
			_playing_oneshot = false
			_oneshot_callback.call()
			return false

		if _combat_sprite:
			_combat_sprite.frame = _oneshot_row * _oneshot_hframes + _oneshot_frame

	return true

func _get_direction_row(target_cell: Vector2i) -> int:
	var diff := target_cell - grid_position
	# Map direction to sprite row (0=S, 1=SW, 2=W, 3=NW, 4=N)
	if diff.y > 0 and abs(diff.x) <= abs(diff.y):
		return 0  # South
	elif diff.x < 0 and diff.y > 0:
		return 1  # South-West
	elif diff.x < 0 and abs(diff.y) <= abs(diff.x):
		return 2  # West
	elif diff.x < 0 and diff.y < 0:
		return 3  # North-West
	elif diff.y < 0 and abs(diff.x) <= abs(diff.y):
		return 4  # North
	elif diff.x > 0 and diff.y < 0:
		return 3  # North-East → use NW row with flip
	elif diff.x > 0 and abs(diff.y) <= abs(diff.x):
		return 2  # East → use W row with flip
	elif diff.x > 0 and diff.y > 0:
		return 1  # South-East → use SW row with flip
	return 0

func _get_current_direction_row() -> int:
	if _combat_sprite and _combat_sprite.hframes > 0:
		return _combat_sprite.frame / _combat_sprite.hframes
	return 0

# Virtual methods for subclasses that use AnimatedSprite2D
# Override these to hide/show the AnimatedSprite2D during combat animations
func _on_combat_anim_start() -> void:
	pass

func _on_combat_anim_end() -> void:
	pass
