extends Control

@onready var menu_buttons: VBoxContainer = %MenuButtons
@onready var settings_menu: Control = %SettingsMenu


func _ready() -> void:
	settings_menu.visible = false
	settings_menu.back_pressed.connect(_on_settings_back)


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_settings_pressed() -> void:
	menu_buttons.visible = false
	settings_menu.visible = true


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_settings_back() -> void:
	settings_menu.visible = false
	menu_buttons.visible = true
