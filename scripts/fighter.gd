extends Unit

@onready var anim_sprite := $AnimatedSprite2D

func _ready() -> void:
	move_range = 4
	is_player_unit = true
	max_hp = 10
	attack_damage = 3
	attack_range = 1
	anim_sprite.play("idle")

func _process(delta: float) -> void:
	if process_oneshot(delta):
		return

	if is_moving:
		if anim_sprite.animation != "walk":
			anim_sprite.play("walk")
	else:
		if anim_sprite.animation != "idle":
			anim_sprite.play("idle")

func _on_combat_anim_start() -> void:
	anim_sprite.visible = false
	_combat_sprite.visible = true

func _on_combat_anim_end() -> void:
	_combat_sprite.visible = false
	anim_sprite.visible = true
