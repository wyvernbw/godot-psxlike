class_name IdleSpinComponent extends Node3D

@onready var target: Node3D = get_parent() as Node3D
@export var spin_speed := PI/2
@export var bobbing: bool = true
@export var bobbing_dist := 32.0
@export var bobbing_speed := 2.0
@export var bobbing_exponent = 0.01
@export var bobbing_phase := 0.0

@onready var target_position := target.transform.origin

var t := 0.0
func _process(dt: float) -> void:
	if not visible:
		return
	target.rotate_y(spin_speed * dt)
	t += dt
	if bobbing:
		var desired = target_position.y + sin(t * bobbing_speed + bobbing_phase) * bobbing_dist
		target.transform.origin.y -= bobbing_exponent * (target.transform.origin.y - desired)
