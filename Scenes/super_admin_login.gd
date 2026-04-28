extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite

@onready var input_usuario: LineEdit = $"TextureRect/Ini-IngresaUsu"
@onready var input_clave: LineEdit = $"TextureRect/Ini-IngresaClv"
@onready var label_estado: Label = $TextureRect/Estado

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	SQLiteHelper.ensure_superadmin_table(db)
	label_estado.text = ""

func _exit_tree() -> void:
	SQLiteHelper.close_db_connection(db)

func _on_login_super_admin_pressed() -> void:
	var usuario := input_usuario.text.strip_edges()
	var clave := input_clave.text

	if usuario.is_empty() or clave.is_empty():
		_set_estado("Completa usuario y clave.", Color(0.9, 0.2, 0.2))
		return

	var query := "SELECT * FROM SuperAdmin WHERE NM_SUPERADMIN = '%s' AND CO_PSW = '%s';" % [
		SQLiteHelper.escape(usuario),
		SQLiteHelper.escape(clave)
	]

	if not db.query(query) or db.query_result.is_empty():
		_set_estado("Credenciales invalidas.", Color(0.9, 0.2, 0.2))
		return

	var datos: Dictionary = db.query_result[0]
	GlobalUsuario.usuario_actual_id = int(datos.get("NU_USU", -1))
	GlobalUsuario.nombre_alumno = str(datos.get("NM_SUPERADMIN", usuario))
	SQLiteHelper.log_activity(db, "superadmin", GlobalUsuario.nombre_alumno, "inicio_sesion")
	get_tree().change_scene_to_file("res://Scenes/SuperAdmin.tscn")

func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Login.tscn")

func _set_estado(mensaje: String, color: Color) -> void:
	label_estado.text = mensaje
	label_estado.modulate = color
