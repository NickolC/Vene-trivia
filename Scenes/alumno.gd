extends Control

var db : SQLite

func _ready():
	db = SQLite.new()
	db.path = "res://DB/venetrivia.db"
	db.open_db()

#REGISTRO DE ALUMNO	
func _on_loginalumno_pressed() -> void:
	var user = $TextureRect/RegIngresaUsu.text
	var psw = $TextureRect/RegIngresaClv.text
	var confirm = $RegRepiteClv.text
	
		# 1. Validar campos vacíos
	if user == "" or psw == "":
		Alertas.mostrar_alerta("Por favor, llena todos los campos.", 1.0)
		print("Por favor, llena todos los campos.")
		return

	# 2. Validar que las claves coincidan
	if psw != confirm:
		Alertas.mostrar_alerta("Las contraseñas no coinciden.", 1.0)
		print("Las contraseñas no coinciden.")
		return

	# 3. Intentar registrar en SQLite
	var data = {
		"NM_ALUMNO": user,
		"CO_PSW": psw # Nota: En producción, usa hash (SHA256)
	}

	if db.insert_row("Alumnos", data):
		Alertas.mostrar_alerta("Usuario registrado con éxito.", 1.0)
		print("Usuario registrado con éxito.")
		$TextureRect/RegIngresaUsu.text = ""
		$TextureRect/RegIngresaClv.text = ""
		$RegRepiteClv.text = ""
		# Aquí puedes obtener el ID recién creado si lo necesitas
		var user_id = db.last_insert_rowid
	else:
		Alertas.mostrar_alerta("El usuario ya existe.", 1.0)
		print("El usuario ya existe.")
#-------------------------------------------------------------------------------
#INICIAR COMO ALUMNO
func _on_logindocente_pressed() -> void:
	var nombre_ingresado = $TextureRect/IniIngresaUsu.text
	var clave_ingresada = $TextureRect/IniIngresaClv.text
	
	# 1. Validar que no estén vacíos
	if nombre_ingresado == "" or clave_ingresada == "":
		Alertas.mostrar_alerta("Por favor, completa los datos.", 1.0)
		print("Por favor, completa los datos.")
		return

	# 2. Buscar en la base de datos
	# Usamos un query con WHERE para filtrar
	var query = "SELECT * FROM Alumnos WHERE NM_ALUMNO = '%s' AND CO_PSW = '%s'" % [nombre_ingresado, clave_ingresada]
	db.query(query)
	
	if db.query_result.size() > 0:
		var datos = db.query_result[0]
		# --- CARGA EN EL AUTOLOAD ---
		GlobalUsuario.usuario_actual_id = datos["NU_USU"]
		GlobalUsuario.nombre_alumno = datos["NM_ALUMNO"]
		print("Sesión global iniciada para: ", GlobalUsuario.nombre_alumno)
		# Ahora puedes usar el cambio de escena normal y sencillo
		get_tree().change_scene_to_file("res://Scenes/menu-alumno.tscn")
	else:
		Alertas.mostrar_alerta("Usuario o contraseña incorrectos.", 1.0)
		print("Usuario o contraseña incorrectos.")

func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Login.tscn")
	pass # Replace with function body.
