extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite
var nivel_actual: int = GlobalUsuario.nivel_maximo

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	_cargar_usuario_actual()

func _exit_tree() -> void:
	if db:
		SQLiteHelper.close_db_connection(db)
		db = null 

func _on_atras_pressed() -> void:
	Configuracion.change_scene_to_file("res://Scenes/menu-alumno.tscn")


func _cargar_usuario_actual() -> void:
	var query := ""
	if GlobalUsuario.usuario_actual_id > 0:
		query = "SELECT NU_USU, NM_ALUMNO, NU_NIVEL_MAX FROM Alumnos WHERE NU_USU = %d;" % GlobalUsuario.usuario_actual_id
	elif not GlobalUsuario.nombre_alumno.is_empty():
		query = "SELECT NU_USU, NM_ALUMNO, NU_NIVEL_MAX FROM Alumnos WHERE NM_ALUMNO = '%s';" % SQLiteHelper.escape(GlobalUsuario.nombre_alumno)
	else:
		return

	db.query(query)
	if db.query_result.is_empty():
		_mostrar_alerta("No se encontro la sesion del alumno.")
		return

	var resultado: Dictionary = db.query_result[0]
	GlobalUsuario.usuario_actual_id = int(resultado.get("NU_USU", GlobalUsuario.usuario_actual_id))
	GlobalUsuario.nombre_alumno = str(resultado.get("NM_ALUMNO", GlobalUsuario.nombre_alumno))
	GlobalUsuario.nivel_maximo = int(resultado.get("NU_NIVEL_MAX", GlobalUsuario.nivel_maximo))
	print("Sesion iniciada como: ", GlobalUsuario.nombre_alumno)

func _mostrar_alerta(mensaje: String) -> void:
	var alertas := get_node_or_null("/root/Alertas")
	if alertas and alertas.has_method("mostrar_alerta"):
		alertas.mostrar_alerta(mensaje, 1.0)
	print(mensaje)


func _on_level_1_pressed() -> void:
	Configuracion.change_scene_to_file("res://selectorsopaletras.tscn")


func _on_level_2_pressed() -> void:
	Configuracion.change_scene_to_file("res://selectormemoria.tscn")


func _on_level_3_pressed() -> void:
	Configuracion.change_scene_to_file("res://selectorelacioncolumn.tscn")


func _on_level_11_pressed() -> void:
	Configuracion.change_scene_to_file("res://selectorverdfal.tscn")


func _on_level_12_pressed() -> void:
	Configuracion.change_scene_to_file("res://selectorcomfrases.tscn")


func _on_level_13_pressed() -> void:
	Configuracion.change_scene_to_file("res://selectorordenfrases.tscn")
