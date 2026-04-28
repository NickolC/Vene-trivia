extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite
var nivel_actual: int = GlobalUsuario.nivel_maximo

@onready var contenedor1: HBoxContainer = $VBoxContainer/HBoxContainer
@onready var contenedor2: HBoxContainer = $VBoxContainer/HBoxContainer2
@onready var contenedor3: HBoxContainer = $VBoxContainer/HBoxContainer3

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	_cargar_usuario_actual()
	configurar_selector()

func _exit_tree() -> void:
	SQLiteHelper.close_db_connection(db)

func _on_atras_pressed() -> void:
	SQLiteHelper.close_db_connection(db)
	get_tree().change_scene_to_file("res://Scenes/menu-alumno.tscn")

func configurar_selector() -> void:
	var query := ""
	if GlobalUsuario.usuario_actual_id > 0:
		query = "SELECT MAX(NU_NIVEL) AS nivel_max FROM niveles WHERE NU_USU = %d AND NU_ESTRELLAS > 0" % GlobalUsuario.usuario_actual_id
	else:
		query = "SELECT MAX(NU_NIVEL) AS nivel_max FROM niveles WHERE NM_ALUMNO = '%s' AND NU_ESTRELLAS > 0" % SQLiteHelper.escape(GlobalUsuario.nombre_alumno)

	db.query(query)
	
	var ultimo_nivel_pasado := 0
	if db.query_result.size() > 0 and db.query_result[0]["nivel_max"] != null:
		ultimo_nivel_pasado = int(db.query_result[0]["nivel_max"])
	
	var nivel_disponible := ultimo_nivel_pasado + 1
	nivel_actual = max(nivel_actual, nivel_disponible)
	
	var todos_los_botones: Array[Node] = []
	todos_los_botones.append_array(contenedor1.get_children())
	todos_los_botones.append_array(contenedor2.get_children())
	todos_los_botones.append_array(contenedor3.get_children())
	
	for i in range(todos_los_botones.size()):
		var n_nivel := i + 1
		var btn := todos_los_botones[i] as Button
		if btn == null:
			continue
		
		if n_nivel <= nivel_disponible:
			desbloquear_boton(btn, n_nivel)
		else:
			bloquear_boton(btn)

func desbloquear_boton(btn: Button, num: int) -> void:
	btn.disabled = false
	btn.modulate = Color.WHITE
	var callback := Callable(self, "_ir_al_nivel").bind(num)
	if not btn.pressed.is_connected(callback):
		btn.pressed.connect(callback)
	
func bloquear_boton(btn: Button) -> void:
	btn.disabled = true
	btn.modulate = Color(0.3, 0.3, 0.3, 0.8)

func _ir_al_nivel(n: int) -> void:
	var ruta := "res://Nivel %d.tscn" % n
	if not ResourceLoader.exists(ruta):
		_mostrar_alerta("El nivel %d aun no esta disponible." % n)
		return

	SQLiteHelper.close_db_connection(db)
	get_tree().change_scene_to_file(ruta)

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
