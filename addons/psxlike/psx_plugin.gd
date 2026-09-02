@tool
extends EditorPlugin

const PSX_LIGHT_SYSTEM := "PsxLightSystem"
var shader_globals := [
	{
		"name": "ambient_light",
		"type": "color",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_COLOR,
		"default": Color.BLACK
	},
	{
		"name": "fog_color",
		"type": "color",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_COLOR,
		"default": Color.LIGHT_GRAY
	},
	{
		"name": "fog_enabled",
		"type": "bool",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_BOOL,
		"default": false
	},
	{
		"name": "fog_far_plane",
		"type": "float",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_FLOAT,
		"default": 10.0
	},
	{
		"name": "fog_near_plane",
		"type": "float",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_FLOAT,
		"default": 1.0
	},
	{
		"name": "fog_kind",
		"type": "int",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_INT,
		"default": 1
	},
	{
		"name": "light_count",
		"type": "int",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_INT,
		"default": 0
	},
	{
		"name": "lights",
		"type": "sampler2D",
		"kind": RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D,
		"default": ""
	},
]

func _enable_plugin() -> void:
	add_autoload_singleton(PSX_LIGHT_SYSTEM, "./psx_light_system.gd")
	for uniform in shader_globals:
		var setting = "shader_globals/%s" % uniform.name
		var data := {
			"type": uniform.type,
			"value": uniform.default,
		}
		ProjectSettings.set_setting(setting, data)
	ProjectSettings.save()


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
