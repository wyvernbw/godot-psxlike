@tool
extends EditorPlugin

const PSX_LIGHT_SYSTEM := "PsxLightSystem"
var shader_globals := [
	{
		"name": "ambient_light",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_COLOR,
		"default": Color.BLACK
	},
	{
		"name": "fog_color",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_COLOR,
		"default": Color.LIGHT_GRAY
	},
	{
		"name": "fog_enabled",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_BOOL,
		"default": false
	},
	{
		"name": "fog_far_plane",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_FLOAT,
		"default": 10.0
	},
	{
		"name": "fog_near_plane",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_FLOAT,
		"default": 1.0
	},
	{
		"name": "fog_kind",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_INT,
		"default": 1
	},
	{
		"name": "light_count",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_INT,
		"default": 0
	},
	{
		"name": "lights",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D,
		"default": Texture.new()
	},
]

func _enable_plugin() -> void:
	add_autoload_singleton(PSX_LIGHT_SYSTEM, "./psx_light_system.gd")
	for uniform in shader_globals:
		RenderingServer.global_shader_parameter_add(uniform.name, uniform.kind, uniform.default)


func _disable_plugin() -> void:
	remove_autoload_singleton(PSX_LIGHT_SYSTEM)
	for uniform in shader_globals:
		RenderingServer.global_shader_parameter_remove(uniform.name)
	pass


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass
