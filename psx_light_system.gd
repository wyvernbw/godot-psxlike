# autoload: PsxLightSystem
@tool
extends Node

const LIGHT_COUNT := 16
const BUFFER_SIZE := LIGHT_COUNT * LightData.SIZE

class LightData:
	const SIZE := 12 * 3
	const DIRECTIONAL := 0.0
	const POINT := 1.0

	var meta := Vector3.ZERO
	var direction_or_world_pos := Vector3.DOWN
	var light_color := Vector3.ONE

	func write(buf: PackedByteArray, cursor: int) -> int:
		cursor = PsxLightSystem.write_value(buf, cursor, self.meta)
		cursor = PsxLightSystem.write_value(buf, cursor, self.direction_or_world_pos)
		cursor = PsxLightSystem.write_value(buf, cursor, self.light_color)
		return cursor

	static func from_directional(light: DirectionalLight3D) -> LightData:
		var data := LightData.new()
		data.meta.x = DIRECTIONAL
		data.meta.y = light.visible as float
		data.direction_or_world_pos = light.global_basis.z
		data.light_color.x = light.light_color.r
		data.light_color.y = light.light_color.g
		data.light_color.z = light.light_color.b
		data.light_color *= light.light_energy
		return data

	static func from_point(light: OmniLight3D) -> LightData:
		var data := LightData.new()
		data.meta.x = POINT
		data.meta.y = light.visible as float
		data.meta.z = light.omni_range
		data.direction_or_world_pos = light.global_position
		data.light_color.x = light.light_color.r
		data.light_color.y = light.light_color.g
		data.light_color.z = light.light_color.b
		data.light_color *= light.light_energy
		return data
				
func write_value(buf: PackedByteArray, cursor: int, val: Variant) -> int:
	var value := var_to_bytes(val)
	for i in range(4, value.size()): # skip type tag
		buf[cursor] = value[i]
		cursor += 1
	return cursor


var buffer := PackedByteArray()

func _process(_dt: float) -> void:
	var lights := get_tree().get_nodes_in_group("psx_light")
	buffer.resize(BUFFER_SIZE)
	var cursor = 0
	var light_count := 0
	for light in lights:
		var data: LightData
		if light is DirectionalLight3D:
			data = LightData.from_directional(light)
		if light is OmniLight3D:
			data = LightData.from_point(light)
		if not data:
			continue
		light_count += 1
		cursor = data.write(buffer, cursor)

	var data_image := Image.create_from_data(BUFFER_SIZE / 12, 1, false, Image.FORMAT_RGBF, buffer)
	var tex := ImageTexture.create_from_image(data_image)

	RenderingServer.global_shader_parameter_set("light_count", light_count)
	RenderingServer.global_shader_parameter_set("lights", tex)
