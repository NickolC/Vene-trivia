extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite

@onready var input_registro_usuario: LineEdit = $TextureRect/RegIngresaUsu
@onready var input_registro_clave: LineEdit = $TextureRect/RegIngresaClv
@onready var input_registro_confirmar: LineEdit = $RegRepiteClv
@onready var input_login_usuario: LineEdit = $TextureRect/IniIngresaUsu
@onready var input_login_clave: LineEdit = $TextureRect/IniIngresaClv

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()

func _exit_tree() -> void:
	SQLiteHelper.close_db_connection(db)

#REGISTRO DE ALUMNO	
func _on_loginalumno_pressed() -> void:
	var user := input_registro_usuario.text.strip_edges()
	var psw := input_registro_clave.text
	var confirm := input_registro_confirmar.text
	
	# 1. Validar campos vacíos
	if user == "" or psw == "":
		_mostrar_alerta("Por favor, llena todos los campos.")
		return

	# 2. Validar que las claves coincidan
	if psw != confirm:
		_mostrar_alerta("Las contraseñas no coinciden.")
		return

	# 3. Intentar registrar en SQLite
	var data := {
		"NM_ALUMNO": user,
		"CO_PSW": psw
	}

	if db.insert_row("Alumnos", data):
		SQLiteHelper.log_activity(db, "alumno", user, "registro")
		_mostrar_alerta("Usuario registrado con exito.")
		input_registro_usuario.text = ""
		input_registro_clave.text = ""
		input_registro_confirmar.text = ""
	else:
		_mostrar_alerta("El usuario ya existe.")

#-------------------------------------------------------------------------------
#INICIAR COMO ALUMNO
func _on_logindocente_pressed() -> void:
	var nombre_ingresado := input_login_usuario.text.strip_edges()
	var clave_ingresada := input_login_clave.text
	
	# 1. Validar que no estén vacíos
	if nombre_ingresado == "" or clave_ingresada == "":
		_mostrar_alerta("Por favor, completa los datos.")
		return

	# 2. Buscar en la base de datos
	var query := "SELECT * FROM Alumnos WHERE NM_ALUMNO = '%s' AND CO_PSW = '%s'" % [
		SQLiteHelper.escape(nombre_ingresado),
		SQLiteHelper.escape(clave_ingresada)
	]
	db.query(query)
	
	if db.query_result.size() > 0:
		var datos: Dictionary = db.query_result[0]
		GlobalUsuario.usuario_actual_id = datos["NU_USU"]
		GlobalUsuario.nombre_alumno = datos["NM_ALUMNO"]
		GlobalUsuario.nivel_maximo = int(datos.get("NU_NIVEL_MAX", 1))
		SQLiteHelper.log_activity(db, "alumno", nombre_ingresado, "inicio_sesion")
		print("Sesión global iniciada para: ", GlobalUsuario.nombre_alumno)
		get_tree().change_scene_to_file("res://Scenes/menu-alumno.tscn")
	else:
		_mostrar_alerta("Usuario o contraseña incorrectos.")

func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Login.tscn")

func _mostrar_alerta(mensaje: String) -> void:
	var alertas := get_node_or_null("/root/Alertas")
	if alertas and alertas.has_method("mostrar_alerta"):
		alertas.mostrar_alerta(mensaje, 1.0)
	print(mensaje)
