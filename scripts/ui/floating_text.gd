class_name FloatingText
extends Node2D

var text: String = ""
var font_size: int = 28
var color: Color = Color.RED

func _ready() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 80, 0.6)
	tween.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.1)
	tween.chain().tween_callback(queue_free)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(font, Vector2(-text_size.x / 2.0, 0), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)
