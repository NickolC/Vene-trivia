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
	if db:
		SQLiteHelper.close_db_connection(db)
		db = null 

func _on_atras_pressed() -> void:
	Configuracion.change_scene_to_file("res://Scenes/menu-alumno.tscn")

func configurar_selector() -> void:
	var nivel_disponible := maxi(1, int(GlobalUsuario.nivel_maximo))
	nivel_actual = nivel_disponible
	
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

	# OPCIONAL: Consultar si ya tiene estrellas para mostrarlas bajo el botón
	var q_estrellas := ""
	if GlobalUsuario.usuario_actual_id > 0:
		q_estrellas = "SELECT NU_ESTRELLAS FROM niveles WHERE NU_NIVEL = %d AND NU_USU = %d LIMIT 1;" % [num, GlobalUsuario.usuario_actual_id]
	else:
		q_estrellas = "SELECT NU_ESTRELLAS FROM niveles WHERE NU_NIVEL = %d AND NM_ALUMNO = '%s' LIMIT 1;" % [num, SQLiteHelper.escape(GlobalUsuario.nombre_alumno)]
	db.query(q_estrellas)
	if db.query_result.size() > 0:
		var cant_estrellas = db.query_result[0]["NU_ESTRELLAS"]
		# Aquí podrías llamar a una función para pintar estrellas en el botón
		print("Nivel ", num, " tiene ", cant_estrellas, " estrellas")

func bloquear_boton(btn: Button):
	btn.disabled = true
	btn.modulate = Color(0.3, 0.3, 0.3, 0.8)

func _ir_al_nivel(n: int) -> void:
	GlobalUsuario.nivel_seleccionado = n
	if db:
		SQLiteHelper.close_db_connection(db)
		db = null 
	Configuracion.change_scene_to_file("res://Nivel 1.tscn")

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
