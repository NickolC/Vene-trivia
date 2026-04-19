extends Control

var db : SQLite
var nivel_actual = GlobalUsuario.nivel_maximo

@onready var contenedor1 = $VBoxContainer/HBoxContainer # Cambia esto a tu contenedor real
@onready var contenedor2 = $VBoxContainer/HBoxContainer2
@onready var contenedor3 = $VBoxContainer/HBoxContainer3

func _ready():
	db = SQLite.new()
	db.path = "res://DB/venetrivia.db"
	db.open_db()
	
	var query = ("SELECT * FROM Alumnos WHERE NM_ALUMNO = '%s';" % GlobalUsuario.nombre_alumno)
	db.query(query)
	
	var resultado = db.query_result # Esto devuelve un Array de Diccionarios
	if resultado.size() > 0:
		# ¡Éxito! El primer elemento [0] tiene nuestro ID
		GlobalUsuario.nombre_alumno = resultado[0]["NM_ALUMNO"]
		print("Sesión iniciada como: ", GlobalUsuario.nombre_alumno)
	else:
		print("El alumno no existe en la base de datos.")
	# 3. Actualizamos la interfaz
	configurar_selector()

func _on_atras_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menu-alumno.tscn")

func configurar_selector():
	# Consultamos el progreso: niveles que tienen al menos 1 estrella
	# Esto nos dirá hasta qué nivel ha llegado el alumno
	var query = "SELECT MAX(NU_NIVEL) as nivel_max FROM niveles WHERE NM_ALUMNO = '%s' AND NU_ESTRELLAS > 0" % GlobalUsuario.nombre_alumno
	db.query(query)
	
	var ultimo_nivel_pasado = 0
	if db.query_result.size() > 0 and db.query_result[0]["nivel_max"] != null:
		ultimo_nivel_pasado = int(db.query_result[0]["nivel_max"])
	
	# El nivel disponible es el siguiente al último pasado
	var nivel_disponible = ultimo_nivel_pasado + 1
	
	# 2. UNIFICAR todos los botones en una sola lista maestra
	var todos_los_botones = []
	todos_los_botones.append_array(contenedor1.get_children())
	todos_los_botones.append_array(contenedor2.get_children())
	todos_los_botones.append_array(contenedor3.get_children())
	
	# 3. Recorrer la lista unificada (del 0 al 14)
	for i in range(todos_los_botones.size()):
		var n_nivel = i + 1 # Esto nos da el número real del nivel (1 al 15)
		var btn = todos_los_botones[i]
		
		# Lógica de desbloqueo
		if n_nivel <= nivel_disponible:
			desbloquear_boton(btn, n_nivel)
		else:
			bloquear_boton(btn)

func desbloquear_boton(btn: Button, num: int):
	btn.disabled = false
	btn.modulate = Color.WHITE
	# Conectamos la señal para que al pulsar nos lleve a la escena del nivel
	if not btn.pressed.is_connected(_ir_al_nivel):
		btn.pressed.connect(_ir_al_nivel.bind(num))
	
	# OPCIONAL: Consultar si ya tiene estrellas para mostrarlas bajo el botón
	var q_estrellas = "SELECT NU_ESTRELLAS FROM niveles WHERE NU_NIVEL = %d AND NU_USU = %d;" % [num, GlobalUsuario.usuario_actual_id]
	db.query(q_estrellas)
	if db.query_result.size() > 0:
		var cant_estrellas = db.query_result[0]["NU_ESTRELLAS"]
		# Aquí podrías llamar a una función para pintar estrellas en el botón
		print("Nivel ", num, " tiene ", cant_estrellas, " estrellas")

func bloquear_boton(btn: Button):
	btn.disabled = true
	btn.modulate = Color(0.3, 0.3, 0.3, 0.8) # Se ve oscuro y no se puede tocar

func _ir_al_nivel(n: int):
	db.close_db() # Cerramos antes de cambiar de escena
	var ruta = "res://Nivel " + str(n) + ".tscn"
	get_tree().change_scene_to_file(ruta)
