extends Node3D


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_select"):
		take_screenshot()
	if event.is_action_pressed("record"):
		record_gif()


func take_screenshot() -> void:
	var image: Image = get_viewport().get_texture().get_image()
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var filename := "screenshot_%s.png" % timestamp
	var save_path := "user://%s" % filename
	var error := image.save_png(save_path)
	
	if error == OK:
		print("Screenshot saved to: ", ProjectSettings.globalize_path(save_path))
	else:
		push_error("Failed to save screenshot: %s" % error)
		

const DURATION := 60 * 4

func record_gif(duration := DURATION) -> void:
	var timestamp := Time.get_datetime_string_from_system().replace(":", "-")
	var base_path = "user://gif_%s" % timestamp
	if DirAccess.make_dir_recursive_absolute(base_path) != OK:
		push_error("Failed to create gif folder")
		return

	for frame_i in duration: # one second
		var image: Image = get_viewport().get_texture().get_image()
		var filename := "frame_%s.png" % frame_i
		var save_path = base_path + "/" + filename
		var error := image.save_png(save_path)
	
		if error == OK:
			print("Screenshot saved to: ", ProjectSettings.globalize_path(save_path))
		else:
			push_error("Failed to save screenshot: %s" % error)

		await get_tree().process_frame

	var gif_dir := ProjectSettings.globalize_path(base_path)
	var output := []
	var input_path := gif_dir + "/" + "frame_%d.png"
	var output_path := "%s.mkv" % gif_dir
	print("running ffmpeg:")
	print("> I: ", input_path)
	print("> O: ", output_path)
	OS.execute("ffmpeg", ["-framerate", "60", "-i", input_path, "-c:v", "libaom-av1", "-crf", "0",  output_path], output, true)
	for line in output:
		print(line)

	OS.execute("mpv", [output_path])
