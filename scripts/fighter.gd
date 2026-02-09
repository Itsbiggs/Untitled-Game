extends Unit

@onready var sprite := $AnimatedSprite2D
var _anim_timer := 0.0
const ANIM_SPEED := 0.05

func _ready() -> void:
	move_range = 4
	is_player_unit = true
	sprite.play("idle")  # Start playing idle

func _process(delta: float) -> void:
	# Example: switch to walk when moving
	if is_moving:
		if sprite.animation != "walk":
			sprite.play("walk")
	else:
		if sprite.animation != "idle":
			sprite.play("idle")
