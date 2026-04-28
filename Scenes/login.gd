extends Control

func _on_login_docente_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Admin.tscn")

func _on_login_alumno_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Alumno.tscn")

func _on_super_admin_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/SuperAdminLogin.tscn")
