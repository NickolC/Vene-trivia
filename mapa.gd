extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite
var nivel_actual: int = GlobalUsuario.nivel_maximo
var niveles_tienda_principal: Array[int] = [11, 12, 13, 14, 15]

const ESTRELLA_LLENA = preload("res://GFX/nivelpasadolleno.png")
const ESTRELLA_VACIA = preload("res://GFX/nivelpasado.png")

# Referencias a los 3 TextureRect que están dentro de tu CanvasLayer de previsualización
# (Ajusta la ruta exacta según cómo se llamen en tu árbol de escenas)
@onready var estrella_1: TextureRect = $PrevNiveles/MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer/TextureRect
@onready var estrella_2: TextureRect = $PrevNiveles/MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer/TextureRect2
@onready var estrella_3: TextureRect = $PrevNiveles/MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer/TextureRect3

# NUEVA VARIABLE: Guardará el nivel que el jugador seleccionó temporalmente
var nivel_seleccionado_temp: int = -1

# Diccionario con los temas de cada nivel para automatizar la previsualización
const TEMAS_NIVELES: Dictionary = {
	1: "Tema: El Reino del Agua",
	2: "Tema: Amalivaca y el Orinoco",
	3: "Tema: Las Perlas de Cubagua",
	4: "Tema: Piratas en el Caribe",
	5: "Tema: Miranda, el Viajero",
	6: "Tema: El 19 de Abril",
	7: "Tema: La Batalla de Carabobo",
	8: "Tema: Las Heroinas",
	9: "Tema: El Congreso de Angostura",
	10: "Tema: La Abolición",
	11: "Tema: El Tren de Guzmán Blanco",
	12: "Tema: El Reventón Petrolero",
	13: "Tema: La Ciudad Universitaria",
	14: "Tema: Inventores Venezolanos",
	15: "Tema: Venezuela en el Mundo"
}

@onready var Prevnivel = $PrevNiveles/Label2
@onready var prevtema = $PrevNiveles/MarginContainer/VBoxContainer/MarginContainer2/Label
# VIS-01: imagen de previsualización temática por nivel
@onready var prev_imagen: TextureRect = $"PrevNiveles/MarginContainer/VBoxContainer/MarginContainer/TextureRect"
@onready var contenedor1: HBoxContainer = $VBoxContainer/HBoxContainer
@onready var contenedor2: HBoxContainer = $VBoxContainer/HBoxContainer2
@onready var contenedor3: HBoxContainer = $VBoxContainer/HBoxContainer3

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	_cargar_usuario_actual()
	$PrevNiveles.hide() # Nos aseguramos de que empiece oculto
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

	# BUG-03: ademas del contador NU_NIVEL_MAX, validamos contra la tabla niveles.
	# Si el docente borra el registro de un nivel, el nivel siguiente vuelve a
	# bloquearse (el desbloqueo exige que el nivel previo tenga un registro real).
	var niveles_completados := _cargar_niveles_completados()

	var todos_los_botones: Array[Node] = []
	todos_los_botones.append_array(contenedor1.get_children())
	todos_los_botones.append_array(contenedor2.get_children())
	todos_los_botones.append_array(contenedor3.get_children())

	for i in range(todos_los_botones.size()):
		var n_nivel := i + 1
		var btn := todos_los_botones[i] as Button
		if btn == null:
			continue

		if n_nivel in niveles_tienda_principal:
			if SQLiteHelper.nivel_principal_comprado(db, GlobalUsuario.usuario_actual_id, n_nivel):
				desbloquear_boton(btn, n_nivel)
			else:
				configurar_boton_nivel_tienda_bloqueado(btn, n_nivel)
		elif n_nivel <= nivel_disponible and (n_nivel == 1 or niveles_completados.has(n_nivel - 1)):
			desbloquear_boton(btn, n_nivel)
		else:
			bloquear_boton(btn)

# BUG-03: devuelve un set {NU_NIVEL: true} de niveles con registro completado
# (estrellas > 0) en la tabla niveles para el alumno actual.
func _cargar_niveles_completados() -> Dictionary:
	var completados: Dictionary = {}
	if db == null:
		return completados
	var q := ""
	if GlobalUsuario.usuario_actual_id > 0:
		q = "SELECT NU_NIVEL FROM niveles WHERE NU_USU = %d AND NU_ESTRELLAS > 0;" % GlobalUsuario.usuario_actual_id
	else:
		q = "SELECT NU_NIVEL FROM niveles WHERE NM_ALUMNO = '%s' AND NU_ESTRELLAS > 0;" % SQLiteHelper.escape(GlobalUsuario.nombre_alumno)
	db.query(q)
	for fila in db.query_result:
		completados[int(fila.get("NU_NIVEL", 0))] = true
	return completados

func desbloquear_boton(btn: Button, num: int) -> void:
	btn.disabled = false
	btn.modulate = Color.WHITE
	_desconectar_senales_boton(btn)
	var callback := Callable(self, "_on_nivel_seleccionado_desde_mapa").bind(num)
	btn.pressed.connect(callback)

func configurar_boton_nivel_tienda_bloqueado(btn: Button, num: int) -> void:
	btn.disabled = false
	btn.modulate = Color(0.4, 0.4, 0.4, 0.9)
	_desconectar_senales_boton(btn)
	var callback := Callable(self, "_on_nivel_principal_bloqueado_tienda_pressed").bind(num)
	btn.pressed.connect(callback)

func bloquear_boton(btn: Button):
	btn.disabled = true
	btn.modulate = Color(0.3, 0.3, 0.3, 0.8)

func _desconectar_senales_boton(btn: Button) -> void:
	for conexion in btn.pressed.get_connections():
		btn.pressed.disconnect(conexion.callable)

func _on_nivel_principal_bloqueado_tienda_pressed(num: int) -> void:
	var pack := "A"
	if num in [13, 14]:
		pack = "B"
	elif num == 15:
		pack = "C"
	_mostrar_alerta("Nivel %d bloqueado. Compra el Pack %s en la tienda (1000 Bs)." % [num, pack])

# NUEVA FUNCIÓN INTERMEDIA: Se activa al tocar cualquier botón de nivel del mapa
func _on_nivel_seleccionado_desde_mapa(num: int) -> void:
	nivel_seleccionado_temp = num # Guardamos el número de nivel
	
	# Buscamos el tema correspondiente en nuestro diccionario o ponemos uno por defecto
	var tema: String = TEMAS_NIVELES.get(num, "Tema Desconocido")
	
	# Cambiamos los textos del panel de previsualización
	Prevnivel.text = "NIVEL " + str(num)
	prevtema.text = tema

	# VIS-01: imagen temática del nivel en la previsualización
	if prev_imagen:
		var ruta_img := "res://GFX/Niveles/%d.png" % num
		if ResourceLoader.exists(ruta_img):
			prev_imagen.texture = load(ruta_img)
	
# 2. CONSULTA SQL: Averiguar cuántas estrellas tiene este nivel específico
	var cant_estrellas: int = 0 # Empezamos asumiendo que tiene 0
	var q_estrellas := ""
	
	if GlobalUsuario.usuario_actual_id > 0:
		q_estrellas = "SELECT NU_ESTRELLAS FROM niveles WHERE NU_NIVEL = %d AND NU_USU = %d LIMIT 1;" % [num, GlobalUsuario.usuario_actual_id]
	else:
		q_estrellas = "SELECT NU_ESTRELLAS FROM niveles WHERE NU_NIVEL = %d AND NM_ALUMNO = '%s' LIMIT 1;" % [num, SQLiteHelper.escape(GlobalUsuario.nombre_alumno)]
	
	db.query(q_estrellas)
	if db.query_result.size() > 0:
		cant_estrellas = int(db.query_result[0]["NU_ESTRELLAS"])
		print("Nivel ", num, " tiene ", cant_estrellas, " estrellas asignadas.")
	
	# 3. CAMBIO VISUAL DE LOS PNG: Evaluamos y asignamos las texturas
	# Estrella 1: Se llena si tiene 1 o más estrellas
	if estrella_1:
		estrella_1.texture = ESTRELLA_LLENA if cant_estrellas >= 1 else ESTRELLA_VACIA
		
	# Estrella 2: Se llena si tiene 2 o más estrellas
	if estrella_2:
		estrella_2.texture = ESTRELLA_LLENA if cant_estrellas >= 2 else ESTRELLA_VACIA
		
	# Estrella 3: Se llena únicamente si tiene las 3 estrellas
	if estrella_3:
		estrella_3.texture = ESTRELLA_LLENA if cant_estrellas == 3 else ESTRELLA_VACIA
		
	$PrevNiveles/MarginContainer.queue_sort()
	# Mostramos el Canvas de previsualización
	$PrevNiveles.show()

# BOTÓN DE COMENZAR (Tu señal original _on_button_pressed)
func _on_button_pressed() -> void:
	if nivel_seleccionado_temp != -1:
		# Si hay un nivel seleccionado en memoria, ejecutamos la carga definitiva del nivel
		_ir_al_nivel(nivel_seleccionado_temp)
	else:
		print("Error: No se ha seleccionado ningún nivel válido.")

# BOTÓN CANCELAR/CERRAR PREVISUALIZACIÓN (Tu señal _on_button_4_pressed)
func _on_button_4_pressed() -> void:
	nivel_seleccionado_temp = -1 # Limpiamos la memoria
	$PrevNiveles.hide()

# FUNCIÓN DEFINITIVA DE CAMBIO DE ESCENA
func _ir_al_nivel(n: int) -> void:
	GlobalUsuario.nivel_seleccionado = n
	if db:
		SQLiteHelper.close_db_connection(db)
		db = null 
	
	# Aquí puedes cambiar la ruta dinámicamente si tus niveles se llaman diferente, 
	# por ahora va a tu archivo fijo "Nivel 1.tscn" como lo tenías programado:
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
