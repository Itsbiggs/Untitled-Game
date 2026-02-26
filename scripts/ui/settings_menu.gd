extends Control

signal back_pressed

@onready var volume_slider: HSlider = %VolumeSlider


func _ready() -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	var current_db := AudioServer.get_bus_volume_db(bus_index)
	volume_slider.value = db_to_linear(current_db)


func _on_volume_slider_value_changed(value: float) -> void:
	var bus_index := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))


func _on_back_button_pressed() -> void:
	back_pressed.emit()
