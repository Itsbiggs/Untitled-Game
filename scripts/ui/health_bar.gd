class_name HealthBar
extends Node2D

var current_hp: int = 1
var max_hp: int = 1

const BAR_WIDTH := 60.0
const BAR_HEIGHT := 8.0
const BAR_OFFSET := Vector2(-30, -150)

func update_bar(hp: int, maximum: int) -> void:
	current_hp = hp
	max_hp = maximum
	queue_redraw()

func _draw() -> void:
	var ratio := float(current_hp) / float(max_hp) if max_hp > 0 else 0.0

	# Background
	draw_rect(Rect2(BAR_OFFSET, Vector2(BAR_WIDTH, BAR_HEIGHT)), Color(0.2, 0.2, 0.2, 0.8))

	# Foreground - green to yellow to red
	var bar_color: Color
	if ratio > 0.5:
		bar_color = Color(1.0 - (ratio - 0.5) * 2.0, 1.0, 0.0)
	else:
		bar_color = Color(1.0, ratio * 2.0, 0.0)

	var fill_width := BAR_WIDTH * ratio
	if fill_width > 0:
		draw_rect(Rect2(BAR_OFFSET, Vector2(fill_width, BAR_HEIGHT)), bar_color)

	# Border
	draw_rect(Rect2(BAR_OFFSET, Vector2(BAR_WIDTH, BAR_HEIGHT)), Color(0.0, 0.0, 0.0, 0.9), false, 1.0)
