extends Camera2D

const PAN_SPEED := 500.0
const ZOOM_MIN := 0.15
const ZOOM_MAX := 1.0
const ZOOM_STEP := 0.05

var _dragging := false
var _drag_start := Vector2.ZERO

func _process(delta: float) -> void:
	var pan_input := Vector2.ZERO
	if Input.is_action_pressed("camera_left"):
		pan_input.x -= 1
	if Input.is_action_pressed("camera_right"):
		pan_input.x += 1
	if Input.is_action_pressed("camera_up"):
		pan_input.y -= 1
	if Input.is_action_pressed("camera_down"):
		pan_input.y += 1

	if pan_input != Vector2.ZERO:
		position += pan_input.normalized() * PAN_SPEED * delta / zoom.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom = Vector2.ONE * clampf(zoom.x + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom = Vector2.ONE * clampf(zoom.x - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = mb.pressed
			_drag_start = mb.position
			get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		position -= motion.relative / zoom.x
		get_viewport().set_input_as_handled()
