extends Unit

var _anim_timer := 0.0
const ANIM_SPEED := 0.15
const IDLE_ROW := 1  # South-East facing

func _ready() -> void:
	move_range = 4
	is_player_unit = true

func _process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= ANIM_SPEED:
		_anim_timer -= ANIM_SPEED
		var sprite := $Sprite2D as Sprite2D
		var col := (sprite.frame % sprite.hframes + 1) % sprite.hframes
		sprite.frame = IDLE_ROW * sprite.hframes + col
