extends OmniLight3D

@export var width := 3.0
@export var enabled := false

func _ready() -> void:
	if enabled:
		owner.record_gif()

var t := 0.0
func _process(dt: float) -> void:
	t += dt
	global_position.x = sin(t - PI/2) * width
