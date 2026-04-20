extends Control

var db : SQLite

func _ready():
	db = SQLite.new()
	db.path = "res://DB/venetrivia.db"
	db.open_db()

#REGISTRO DE ADMIN
func _on_logindocente_pressed() -> void:
	var admin = $"TextureRect/Ini-IngresaUsu".text
	var psw = $"TextureRect/Ini-IngresaClv".text

	# 1. Validar que no estén vacíos
	if admin == "" or psw == "":
		print("Por favor, completa los datos.")
		return

	# 2. Buscar en la base de datos
	# Usamos un query con WHERE para filtrar
	var query = "SELECT * FROM Admin WHERE NM_ADMIN = '%s' AND CO_PSW = '%s'" % [admin, psw]
	db.query(query)
	
	if db.query_result.size() > 0:
		var datos = db.query_result[0]
		# --- CARGA EN EL AUTOLOAD ---
		GlobalUsuario.usuario_actual_id = datos["NU_USU"]
		GlobalUsuario.nombre_alumno = datos["NM_ADMIN"]
		print("Sesión admin iniciada para: ", GlobalUsuario.nombre_alumno)
		# Ahora puedes usar el cambio de escena normal y sencillo
		get_tree().change_scene_to_file("res://Scenes/Menu-admin.tscn")
	else:
		print("Usuario o contraseña incorrectos.")



func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Login.tscn")
	pass # Replace with function body.
