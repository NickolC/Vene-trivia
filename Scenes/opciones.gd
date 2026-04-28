extends "res://Scripts/opciones_base.gd"

func _get_return_scene_path() -> String:
	return "res://Scenes/menu-alumno.tscn"

func _get_exit_scene_path() -> String:
	return "res://Scenes/Login.tscn"

func _on_tienda_pressed() -> void:
	get_tree().change_scene_to_file("res://tienda.tscn")
