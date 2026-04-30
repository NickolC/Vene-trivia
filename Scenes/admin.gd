extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite

@onready var input_admin: LineEdit = $"TextureRect/Ini-IngresaUsu"
@onready var input_clave: LineEdit = $"TextureRect/Ini-IngresaClv"

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()

func _exit_tree() -> void:
	SQLiteHelper.close_db_connection(db)

#REGISTRO DE ADMIN
func _on_logindocente_pressed() -> void:
	var admin := input_admin.text.strip_edges()
	var psw := input_clave.text

	# 1. Validar que no estén vacíos
	if admin == "" or psw == "":
		_mostrar_alerta("Por favor, completa los datos.")
		return

	# 2. Buscar en la base de datos
	var query := "SELECT * FROM Admin WHERE NM_ADMIN = '%s' AND CO_PSW = '%s'" % [
		SQLiteHelper.escape(admin),
		SQLiteHelper.escape(psw)
	]
	db.query(query)
	
	if db.query_result.size() > 0:
		var datos: Dictionary = db.query_result[0]
		GlobalUsuario.usuario_actual_id = datos["NU_USU"]
		GlobalUsuario.nombre_alumno = datos["NM_ADMIN"]
		SQLiteHelper.log_activity(db, "docente", admin, "inicio_sesion")
		print("Sesión admin iniciada para: ", GlobalUsuario.nombre_alumno)
		get_tree().change_scene_to_file("res://Scenes/Menu-admin.tscn")
	else:
		_mostrar_alerta("Usuario o contraseña incorrectos.")

func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Login.tscn")

func _mostrar_alerta(mensaje: String) -> void:
	var alertas := get_node_or_null("/root/Alertas")
	if alertas and alertas.has_method("mostrar_alerta"):
		alertas.mostrar_alerta(mensaje, 1.0)
	print(mensaje)
