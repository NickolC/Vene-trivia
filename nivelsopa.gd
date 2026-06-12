extends Control

# Precargamos recursos esenciales
const CASILLA_ESCENA = preload("res://CasillaLetra.tscn")
const MI_FUENTE_PERSONALIZADA = preload("res://font/Minecraft.ttf")
const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")
const RUTA_ESCENA_NIVEL := "res://Scenes/Minijuegos.tscn"
const RUTA_DATOS_SOPA := "res://Data/minijuegos/sopa.json"

# Recompensas económicas base
const RECOMPENSA_BASE_PUNTOS := 100
const MONEDAS_POR_ESTRELLA := 50

# --- NUEVO DICCIONARIO: TIEMPOS MÁXIMOS POR NIVEL (En segundos, max 8 minutos = 480s) ---
const TIEMPOS_POR_NIVEL: Dictionary = {
	1: 480.0,  # Nivel 1: 8 minutos
	2: 480.0,  # Nivel 2: 7:30 minutos
	3: 480.0,  # Nivel 3: 8 minutos
	4: 480.0,  # Nivel 4: 7 minutos
	5: 480.0,  # ... ajusta cada nivel como gustes sin pasarte de 480.0
	6: 480.0,
	7: 480.0,
	8: 480.0,
	9: 480.0,
	10: 480.0,
	11: 480.0,
	12: 480.0,
	13: 480.0,
	14: 480.0,
	15: 480.0
}

# Nodos de la Cuadrícula e Interfaz del Juego
@onready var cuadracula = $Panel/GridContainer
@onready var lista_palabras_ui = $VBoxContainer
@onready var label_contador = $Label 
@onready var menu_pausa = $Menupausa
@onready var capa_confirmacion = $confrimar

# --- NUEVO NODO VISUAL PARA EL CRONÓMETRO ---
# (Crea un Label en tu escena llamado "LabelTimer" para que se vea el tiempo en pantalla)
@onready var label_timer = get_node_or_null("Label2")

# Nodos del Canvas del Personaje y Diálogos
@onready var sprite_personaje = $capapersonaje/SpritePersonaje
@onready var panel_dialogo = $capapersonaje/PanelContainer
@onready var label_dialogo = $capapersonaje/PanelContainer/MarginContainer/Label

# Nodos de la Pantalla de Resultados
@onready var pantalla_resultados = $PantallaResultados
@onready var label_titulo_resultados = $PantallaResultados/Panel/Label
@onready var label_puntaje_total = $PantallaResultados/Panel/Label2
@onready var contenedor_estrellas = $PantallaResultados/Panel/HBoxContainer
@onready var btn_siguiente = $PantallaResultados/Panel/HBoxContainer2/Button     
@onready var btn_repetir = $PantallaResultados/Panel/HBoxContainer2/Button3    
@onready var btn_selector = $PantallaResultados/Panel/HBoxContainer2/Button4  
@onready var btn_menu_alumno = $PantallaResultados/Panel/HBoxContainer2/Button2

# Recursos Visuales 
var pose_normal = preload("res://GFX/normal.png")
var pose_feliz = preload("res://GFX/Feliz.png")
var pose_preocupado = preload("res://GFX/preocupado.png")
var pose_pensativo = preload("res://GFX/pensativo.png")
var img_estrella_llena = preload("res://GFX/estrella completada.png")
var img_estrella_vacia = preload("res://GFX/estrella vacia.png")

# Variables del Motor de Base de Datos y control de juego
var db: SQLite
var tamaño_tablero: int = 10 
var matriz_letras: Array = [] 
var palabras_objetivo: Array[String] = []
var referencias_lista_ui: Dictionary = {}
var casillas_por_coordenada: Dictionary = {}
var palabras_encontradas: Dictionary = {}

var seleccionando: bool = false
var casillas_seleccionadas: Array[Button] = []
var palabras_encontradas_contador: int = 0
var total_palabras: int = 0 
var numero_de_nivel: int = 1

# --- VARIABLES DEL CRONÓMETRO DINÁMICO ---
var tiempo_maximo_nivel: float = 480.0 # Se sobreescribirá en el ready
var tiempo_restante: float = 480.0
var juego_activo: bool = false

# Banco de datos de los 15 niveles
const BANCO_PALABRAS_NIVELES: Dictionary = {
	1: ["AGUA", "RIO", "LAGO", "MAR", "LLUVIA", "OCEANO", "PEZ", "CORAL"],
	2: ["AMALIVACA", "ORINOCO", "MITO", "TAMANAKU", "CREACION", "INDIGENA"],
	3: ["PERLA", "CUBAGUA", "ISLA", "MARGARITA", "TESORO", "CONCHA", "BUCEO"],
	4: ["PIRATA", "CARIBE", "BARCO", "TESORO", "PARCHE", "SAQUEO", "OCEANO"],
	5: ["MIRANDA", "VIAJERO", "PRECURSOR", "EUROPA", "PROYECTO", "ARCHIVO"],
	6: ["ABRIL", "CARACAS", "CABILDO", "INDEPENDENCIA", "ACTA", "PROVINCIA"],
	7: ["CARABOBO", "BATALLA", "BOLIVAR", "EJERCITO", "CAMPO", "VICTORIA"],
	8: ["HEROINAS", "CACERES", "CACIQUE", "MUJERES", "LUCHA", "VALOR", "PATRIA"],
	9: ["CONGRESO", "ANGOSTURA", "DISCURSO", "ORINOCO", "LEYES", "REPÚBLICA"],
	10: ["ABOLICION", "LIBERTAD", "ESCLAVO", "DECRETO", "IGUALDAD", "DERECHOS"],
	11: ["TREN", "GUZMAN", "VIAS", "ESTACION", "PROGRESO", "VAPOR", "HIERRO"],
	12: ["REVENTON", "PETROLEO", "BARROSO", "ZULIA", "POZO", "CRUDO", "TORRE"],
	13: ["CIUDAD", "UNIVERSIDAD", "UCV", "VILLANUEVA", "AULA", "ARTE", "NUBE"],
	14: ["INVENTOR", "CIENCIA", "VACUNA", "CONVIT", "BIOMEDICINA", "APORTE"],
	15: ["MUNDO", "VENEZUELA", "TALENTO", "PAIS", "BANDERA", "ORQUESTA", "EXITO"]
}

const TIEMPO_TOTAL := 480.0
const LIMITE_3_ESTRELLAS := 300.0
const LIMITE_2_ESTRELLAS := 180.0 

var aviso_3_estrellas_dado: bool = false
var aviso_2_estrellas_dado: bool = false

var banco_palabras_niveles_runtime: Dictionary = BANCO_PALABRAS_NIVELES.duplicate(true)

func _ready() -> void:
	if menu_pausa: 
		menu_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
		if capa_confirmacion:
			capa_confirmacion.process_mode = Node.PROCESS_MODE_ALWAYS
	
	db = SQLiteHelper.open_db_connection()
	_cargar_usuario_actual()
	numero_de_nivel = maxi(1, int(GlobalUsuario.nivel_seleccionado))
	
	# --- ASIGNACIÓN DINÁMICA DEL TIEMPO SEGÚN EL NIVEL ---
	tiempo_maximo_nivel = TIEMPOS_POR_NIVEL.get(numero_de_nivel, 480.0)
	tiempo_restante = tiempo_maximo_nivel
	
	menu_pausa.hide()
	capa_confirmacion.hide()
	pantalla_resultados.hide()
	_ocultar_ui_juego()
	_cargar_banco_sopa_desde_archivo()
	
	_conectar_botones_seguros()

	# Introducción del personaje
	cambiar_pose(pose_normal)
	await decir_mensaje("¡Bienvenido al Nivel %d de Sopa de Letras!" % numero_de_nivel, 2.5)
	
	cambiar_pose(pose_pensativo)
	var min_texto := int(tiempo_maximo_nivel) / 60
	await decir_mensaje("Tienes un límite de %d minutos para hallar las palabras ocultas. ¡A por ello!" % min_texto, 3.0)
	cambiar_pose(pose_normal)
	label_dialogo.get_parent().hide()
	_mostrar_ui_juego()
	
	_cargar_palabras_del_nivel_actual()
	cuadracula.columns = tamaño_tablero
	total_palabras = palabras_objetivo.size() 
	
	inicializar_matriz()
	insertar_palabras_aleatorias()
	rellenar_espacios_vacios()
	dibujar_tablero_en_pantalla()
	crear_lista_palabras_visual()
	actualizar_contador_ui()
	_actualizar_cronometro_visual()
	
	juego_activo = true

func _process(delta: float) -> void:
	if juego_activo and not get_tree().paused:
		tiempo_restante -= delta
		
		# --- NUEVA VALIDACIÓN EN TIEMPO REAL ---
		var tiempo_transcurrido = TIEMPO_TOTAL - tiempo_restante
		
		if tiempo_transcurrido > LIMITE_3_ESTRELLAS and not aviso_3_estrellas_dado:
			aviso_3_estrellas_dado = true
			_mostrar_aviso_tiempo(3)
		elif tiempo_transcurrido > LIMITE_2_ESTRELLAS and not aviso_2_estrellas_dado:
			aviso_2_estrellas_dado = true
			_mostrar_aviso_tiempo(2)
		# ---------------------------------------
		_actualizar_cronometro_visual()
		
		if tiempo_restante <= 0:
			tiempo_restante = 0
			juego_activo = false
			finalizar_nivel()

func _mostrar_aviso_tiempo(estrellas_perdidas: int) -> void:
	cambiar_pose(pose_preocupado)
	await decir_mensaje("¡Oh no, has perdido la oportunidad de conseguir " + str(estrellas_perdidas) + " estrellas!", 3.0)
	cambiar_pose(pose_normal)

# --- NUEVA FUNCIÓN: Formatea y pinta el tiempo en la pantalla (MM:SS) ---
func _actualizar_cronometro_visual() -> void:
	if label_timer != null:
		var minutos := int(tiempo_restante) / 60
		var segundos := int(tiempo_restante) % 60
		label_timer.text = "%02d:%02d" % [minutos, segundos]
		
		# Feedback visual opcional: Si quedan menos de 30 segundos, poner el texto en rojo
		if tiempo_restante <= 30.0:
			label_timer.add_theme_color_override("font_color", Color.RED)
		else:
			label_timer.add_theme_color_override("font_color", Color.WHITE)

func _conectar_botones_seguros() -> void:
	if btn_siguiente and not btn_siguiente.pressed.is_connected(_on_btn_siguiente_pressed): btn_siguiente.pressed.connect(_on_btn_siguiente_pressed)
	if btn_repetir and not btn_repetir.pressed.is_connected(_on_btn_repetir_pressed): btn_repetir.pressed.connect(_on_btn_repetir_pressed)
	if btn_selector and not btn_selector.pressed.is_connected(_on_btn_selector_pressed): btn_selector.pressed.connect(_on_btn_selector_pressed)
	if btn_menu_alumno and not btn_menu_alumno.pressed.is_connected(_on_btn_menu_pressed): btn_menu_alumno.pressed.connect(_on_btn_menu_pressed)
	
	var boton_pausa_visual = get_node_or_null("Buttonpausa") 
	if boton_pausa_visual and boton_pausa_visual is Button:
		if not boton_pausa_visual.pressed.is_connected(_on_boton_pausa_visual_pressed):
			boton_pausa_visual.pressed.connect(_on_boton_pausa_visual_pressed)

func _exit_tree() -> void:
	if db:
		SQLiteHelper.close_db_connection(db)

func _cargar_palabras_del_nivel_actual() -> void:
	var palabras_base: Array = banco_palabras_niveles_runtime.get(numero_de_nivel, ["DISENO", "NODO", "MOTOR"]).duplicate()
	palabras_base.shuffle()
	palabras_objetivo.clear()
	palabras_encontradas.clear()
	for p in palabras_base:
		var normalizada := _normalizar_palabra(str(p))
		if normalizada.is_empty():
			continue
		if palabras_objetivo.has(normalizada):
			continue
		palabras_objetivo.append(normalizada)

func _cargar_banco_sopa_desde_archivo() -> void:
	if not FileAccess.file_exists(RUTA_DATOS_SOPA):
		return
	var archivo := FileAccess.open(RUTA_DATOS_SOPA, FileAccess.READ)
	if archivo == null:
		return
	var parsed: Variant = JSON.parse_string(archivo.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var parsed_dict: Dictionary = parsed

	var nuevo_banco: Dictionary = {}
	for clave in parsed_dict.keys():
		var nivel := int(str(clave))
		if nivel <= 0:
			continue
		var palabras: Array[String] = []
		var palabras_raw: Variant = parsed_dict[clave]
		if typeof(palabras_raw) != TYPE_ARRAY:
			continue
		for palabra in palabras_raw:
			var normalizada := _normalizar_palabra(str(palabra))
			if not normalizada.is_empty() and not palabras.has(normalizada):
				palabras.append(normalizada)
		if not palabras.is_empty():
			nuevo_banco[nivel] = palabras

	if not nuevo_banco.is_empty():
		banco_palabras_niveles_runtime = nuevo_banco

func _cargar_usuario_actual() -> void:
	var query := ""
	if GlobalUsuario.usuario_actual_id > 0:
		query = "SELECT NU_USU, NM_ALUMNO, NU_NIVEL_MAX FROM Alumnos WHERE NU_USU = %d;" % GlobalUsuario.usuario_actual_id
	elif not GlobalUsuario.nombre_alumno.is_empty():
		query = "SELECT NU_USU, NM_ALUMNO, NU_NIVEL_MAX FROM Alumnos WHERE NM_ALUMNO = '%s';" % SQLiteHelper.escape(GlobalUsuario.nombre_alumno)
	else:
		return
	db.query(query)
	if not db.query_result.is_empty():
		var resultado: Dictionary = db.query_result[0]
		GlobalUsuario.usuario_actual_id = int(resultado.get("NU_USU", GlobalUsuario.usuario_actual_id))
		GlobalUsuario.nombre_alumno = str(resultado.get("NM_ALUMNO", GlobalUsuario.nombre_alumno))
		GlobalUsuario.nivel_maximo = int(resultado.get("NU_NIVEL_MAX", GlobalUsuario.nivel_maximo))

func _ocultar_ui_juego() -> void:
	cuadracula.hide()
	$Panel.hide()
	lista_palabras_ui.hide()
	label_contador.hide()
	if label_timer: label_timer.hide()
	var b_pausa = get_node_or_null("Buttonpausa")
	if b_pausa: b_pausa.hide()

func _mostrar_ui_juego() -> void:
	cuadracula.show()
	$Panel.show()
	lista_palabras_ui.show()
	label_contador.show()
	if label_timer: label_timer.show()
	var b_pausa = get_node_or_null("Buttonpausa")
	if b_pausa: b_pausa.show()

func decir_mensaje(texto: String, tiempo: float = 3.0):
	label_dialogo.show() 
	if label_dialogo.get_parent(): label_dialogo.get_parent().show()
	label_dialogo.text = texto
	
	var tween = create_tween()
	panel_dialogo.modulate.a = 0
	panel_dialogo.show()
	tween.tween_property(panel_dialogo, "modulate:a", 1.0, 0.3)
	
	await get_tree().create_timer(tiempo).timeout
	
	var tween_out = create_tween()
	tween_out.tween_property(panel_dialogo, "modulate:a", 0.0, 0.3)
	await tween_out.finished
	panel_dialogo.hide()

func cambiar_pose(nueva_textura):
	if sprite_personaje:
		sprite_personaje.texture = nueva_textura
		var t = create_tween()
		sprite_personaje.scale = Vector2(0.9, 0.9)
		t.tween_property(sprite_personaje, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

func verificar_palabra_formada() -> void:
	var seleccion_lineal := _normalizar_seleccion_lineal(casillas_seleccionadas)
	if seleccion_lineal.is_empty():
		for casilla in casillas_seleccionadas:
			if is_instance_valid(casilla) and not casilla.disabled:
				casilla.modulate = Color.WHITE
		casillas_seleccionadas.clear()
		return

	var palabra_construida := ""
	for casilla in seleccion_lineal:
		palabra_construida += str(casilla.get_node("Label").text)
		
	var palabra_invertida := palabra_construida.reverse()
	var palabra_valida := ""
	
	if palabras_objetivo.has(palabra_construida):
		palabra_valida = palabra_construida
	elif palabras_objetivo.has(palabra_invertida):
		palabra_valida = palabra_invertida

	if not palabra_valida.is_empty():
		for casilla in seleccion_lineal:
			casilla.modulate = Color.GREEN
			casilla.disabled = true
		if not palabras_encontradas.has(palabra_valida):
			palabras_encontradas[palabra_valida] = true
			tachar_palabra_en_lista(palabra_valida)
			palabras_encontradas_contador += 1
		actualizar_contador_ui()
		casillas_seleccionadas.clear()
		
		cambiar_pose(pose_feliz)
		var frases_ok = ["¡Muy bien visto! Encontraste " + palabra_valida + ".", "¡Excelente avance! ¡Vas con buen ritmo!"]
		decir_mensaje(frases_ok.pick_random(), 2.0)
		
		if palabras_encontradas_contador == total_palabras:
			juego_activo = false
			finalizar_nivel()
	else:
		for casilla in seleccion_lineal:
			casilla.modulate = Color.RED
		
		cambiar_pose(pose_preocupado)
		var frases_fail = ["Mmm... esa combinación no es válida.", "¡Sigue buscando, no te rindas!"]
		decir_mensaje(frases_fail.pick_random(), 2.0)
		
		var copia_fallidos = seleccion_lineal.duplicate()
		casillas_seleccionadas.clear()
		await get_tree().create_timer(0.4).timeout
		for casilla in copia_fallidos:
			if is_instance_valid(casilla) and not casilla.disabled:
				casilla.modulate = Color.WHITE

# --- ADAPTACIÓN DE LA LÓGICA DE ESTRELLAS SOLICITADA ---
func finalizar_nivel() -> void:
	juego_activo = false
	_ocultar_ui_juego()
	
	# Calculamos el tiempo que el alumno necesitó para completar la partida
	var tiempo_empleado = tiempo_maximo_nivel - tiempo_restante
	var estrellas_obtenidas := 0
	var mensaje_final := ""
	
	if palabras_encontradas_contador == total_palabras:
		# Regla 1: Menos de 3 minutos (180 segundos) -> 3 Estrellas
		if tiempo_empleado < 180.0:
			estrellas_obtenidas = 3
			cambiar_pose(pose_feliz)
			mensaje_final = "¡Espectacular! Completaste el nivel en un tiempo récord de agilidad mental."
			
		# Regla 2: Menos de 5 minutos y medio (330 segundos) -> 2 Estrellas
		elif tiempo_empleado <= 330.0:
			estrellas_obtenidas = 2
			cambiar_pose(pose_normal)
			mensaje_final = "¡Muy buen trabajo! Lograste resolverlo con una agilidad estupenda."
			
		# Regla 3: Más de 5:30 minutos, pero antes del límite total del nivel -> 1 Estrella
		else:
			estrellas_obtenidas = 1
			cambiar_pose(pose_pensativo)
			mensaje_final = "¡Nivel completado! Pero debes estar pendiente del tiempo y mejorar tu agilidad al encontrar palabras."
	else:
		# Regla 4: No completó las palabras / Se acabó el tiempo -> 0 Estrellas (Repetir Obligatorio)
		estrellas_obtenidas = 0
		cambiar_pose(pose_preocupado)
		mensaje_final = "¡Se acabó el tiempo límite! No lograste completar la sopa de letras."

	await decir_mensaje(mensaje_final, 4.0)
	
	var puntos_totales = palabras_encontradas_contador * RECOMPENSA_BASE_PUNTOS
	var monedas_ganadas = estrellas_obtenidas * MONEDAS_POR_ESTRELLA
	
	# Guardamos el resultado si aprobó (obtuvo estrellas)
	guardar_datos_progreso(puntos_totales, estrellas_obtenidas)
	
	# Configurar UI de Resultados
	label_titulo_resultados.text = "NIVEL %d" % numero_de_nivel
	label_puntaje_total.text = "Puntaje: %d | Monedas: +%d" % [puntos_totales, monedas_ganadas]
	
	var nodos_estrellas = contenedor_estrellas.get_children()
	for i in range(nodos_estrellas.size()):
		if i < estrellas_obtenidas:
			nodos_estrellas[i].texture = img_estrella_llena
		else:
			nodos_estrellas[i].texture = img_estrella_vacia
			
	# REGLA OBLIGATORIA: Si sacó 0 estrellas, ocultamos el botón Siguiente y forzamos reintento
	if estrellas_obtenidas == 0:
		if btn_siguiente: btn_siguiente.hide()
		print("Nivel reprobado con 0 estrellas. El botón de siguiente nivel se bloqueó.")
	else:
		if btn_siguiente:
			if BANCO_PALABRAS_NIVELES.has(numero_de_nivel + 1):
				btn_siguiente.show()
			else:
				btn_siguiente.hide() # Se oculta si es el último nivel total del juego (15)
			
	pantalla_resultados.show()

func guardar_datos_progreso(puntos_totales: int, estrellas: int) -> void:
	if db == null: return

	var id_alumno: int = GlobalUsuario.usuario_actual_id
	var nombre_alumno := SQLiteHelper.escape(GlobalUsuario.nombre_alumno)
	var completado_flag := 1 if estrellas == 3 else 0
	var timestamp := Time.get_datetime_string_from_system().replace("T", " ")

	db.query(
		"INSERT INTO sopa_intentos (NU_USU, NM_ALUMNO, NU_NIVEL, NU_PUNTOS, NU_ESTRELLAS, SW_COM, FE_INTENTO) VALUES (%d, '%s', %d, %d, %d, %d, '%s');" % [id_alumno, nombre_alumno, numero_de_nivel, puntos_totales, estrellas, completado_flag, timestamp]
	)

	if estrellas > 0:
		db.query("SELECT NU_ESTRELLAS FROM sopa_niveles WHERE NU_USU = %d AND NU_NIVEL = %d;" % [id_alumno, numero_de_nivel])
		if db.query_result.is_empty():
			db.query(
				"INSERT INTO sopa_niveles (NU_NIVEL, NU_USU, NM_ALUMNO, NU_PUNTOS, NU_ESTRELLAS, SW_COM) VALUES (%d, %d, '%s', %d, %d, %d);" % [numero_de_nivel, id_alumno, nombre_alumno, puntos_totales, estrellas, completado_flag]
			)
		else:
			var prev := int(db.query_result[0].get("NU_ESTRELLAS", 0))
			if estrellas > prev:
				db.query(
					"UPDATE sopa_niveles SET NU_PUNTOS = %d, NU_ESTRELLAS = %d, SW_COM = %d WHERE NU_NIVEL = %d AND NU_USU = %d;" % [puntos_totales, estrellas, completado_flag, numero_de_nivel, id_alumno]
				)
		var sgte_lvl := numero_de_nivel + 1
		db.query("UPDATE Alumnos SET NU_NIVEL_MAX_SOPA = %d WHERE NU_USU = %d AND NU_NIVEL_MAX_SOPA < %d;" % [sgte_lvl, id_alumno, sgte_lvl])

	SQLiteHelper.mirror_minijuegos_resultados(db, id_alumno, GlobalUsuario.nombre_alumno, "sopa", puntos_totales, estrellas)

	db.query("SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d;" % id_alumno)
	var dinero_total := 0
	if not db.query_result.is_empty():
		dinero_total = int(db.query_result[0].get("NU_DINERO", 0))
	Logros.evaluar_post_nivel(estrellas, puntos_totales, dinero_total)

func _on_btn_siguiente_pressed() -> void:
	var prox = numero_de_nivel + 1
	if BANCO_PALABRAS_NIVELES.has(prox):
		GlobalUsuario.nivel_seleccionado = prox
		get_tree().paused = false
		get_tree().reload_current_scene()

func _on_btn_repetir_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_btn_selector_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://selectorsopaletras.tscn")

func _on_btn_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Minijuegos.tscn")

func crear_lista_palabras_visual() -> void:
	for hijo in lista_palabras_ui.get_children(): hijo.queue_free()
	referencias_lista_ui.clear()
	lista_palabras_ui.add_theme_constant_override("separation", 25) 
	for palabra in palabras_objetivo:
		var nuevo_label = Label.new()
		nuevo_label.text = palabra
		nuevo_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		nuevo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if MI_FUENTE_PERSONALIZADA: nuevo_label.add_theme_font_override("font", MI_FUENTE_PERSONALIZADA)
		nuevo_label.add_theme_font_size_override("font_size", 28) 
		lista_palabras_ui.add_child(nuevo_label)
		referencias_lista_ui[palabra] = nuevo_label

func actualizar_contador_ui() -> void:
	label_contador.text = "Palabras encontradas %d/%d" % [palabras_encontradas_contador, total_palabras]

func _on_casilla_gui_input(event: InputEvent, casilla: Button) -> void:
	if not juego_activo: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			seleccionando = true
			casillas_seleccionadas.clear()
			seleccionar_casilla(casilla)
		else:
			seleccionando = false
			verificar_palabra_formada()
	if event is InputEventMouseMotion and seleccionando:
		var casilla_actual = obtener_casilla_bajo_mouse()
		if casilla_actual and not casillas_seleccionadas.has(casilla_actual):
			seleccionar_casilla(casilla_actual)

func seleccionar_casilla(casilla: Button) -> void:
	casillas_seleccionadas.append(casilla)
	casilla.modulate = Color.YELLOW

func obtener_casilla_bajo_mouse() -> Button:
	for casilla in cuadracula.get_children():
		if casilla is Button and casilla.get_global_rect().has_point(get_global_mouse_position()): return casilla
	return null

func tachar_palabra_en_lista(palabra: String) -> void:
	if referencias_lista_ui.has(palabra):
		var label_nodo: Label = referencias_lista_ui[palabra]
		label_nodo.modulate = Color(0.6, 0.6, 0.6, 1.0)
		var linea_tachado = ColorRect.new()
		linea_tachado.color = Color.RED
		linea_tachado.custom_minimum_size = Vector2(0, 3) 
		label_nodo.add_child(linea_tachado)
		linea_tachado.set_anchors_preset(Control.PRESET_CENTER_LEFT)
		linea_tachado.anchor_left = 0.0
		linea_tachado.anchor_right = 1.0
		linea_tachado.position.y = (label_nodo.size.y / 2) - (linea_tachado.custom_minimum_size.y / 2)

func inicializar_matriz() -> void:
	matriz_letras.clear()
	casillas_por_coordenada.clear()
	for x in range(tamaño_tablero):
		var fila = []
		for y in range(tamaño_tablero): fila.append("-")
		matriz_letras.append(fila)

func insertar_palabras_aleatorias() -> void:
	var direcciones: Array[Vector2i] = [
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(0, 1), Vector2i(0, -1),
		Vector2i(1, 1), Vector2i(-1, -1),
		Vector2i(1, -1), Vector2i(-1, 1)
	]

	var palabras_ordenadas: Array[String] = palabras_objetivo.duplicate()
	palabras_ordenadas.sort_custom(_ordenar_palabras_por_longitud_desc)

	for palabra in palabras_ordenadas:
		if palabra.length() > tamaño_tablero:
			continue

		var mejor_solucion: Dictionary = {}
		var mejor_solape := -1
		for intento in range(220):
			var dir: Vector2i = direcciones.pick_random()
			var rango_x: Vector2i = _rango_inicio(palabra.length(), dir.x)
			var rango_y: Vector2i = _rango_inicio(palabra.length(), dir.y)
			if rango_x.y < rango_x.x or rango_y.y < rango_y.x:
				continue

			var sx: int = randi_range(rango_x.x, rango_x.y)
			var sy: int = randi_range(rango_y.x, rango_y.y)
			var solape: int = _evaluar_colocacion(palabra, sx, sy, dir)
			if solape < 0:
				continue
			if solape > mejor_solape:
				mejor_solape = solape
				mejor_solucion = {"sx": sx, "sy": sy, "dir": dir}
				if mejor_solape >= 2:
					break

		if mejor_solucion.is_empty():
			for dir in direcciones:
				var rango_x: Vector2i = _rango_inicio(palabra.length(), dir.x)
				var rango_y: Vector2i = _rango_inicio(palabra.length(), dir.y)
				for sx in range(rango_x.x, rango_x.y + 1):
					for sy in range(rango_y.x, rango_y.y + 1):
						if _evaluar_colocacion(palabra, sx, sy, dir) >= 0:
							mejor_solucion = {"sx": sx, "sy": sy, "dir": dir}
							break
					if not mejor_solucion.is_empty():
						break
				if not mejor_solucion.is_empty():
					break

		if not mejor_solucion.is_empty():
			var sx: int = int(mejor_solucion["sx"])
			var sy: int = int(mejor_solucion["sy"])
			var dir: Vector2i = mejor_solucion.get("dir", Vector2i(1, 0))
			for i in range(palabra.length()):
				matriz_letras[sx + (dir.x * i)][sy + (dir.y * i)] = palabra[i]

func verificar_espacio_libre(palabra: String, sx: int, sy: int, dir: Vector2i) -> bool:
	for i in range(palabra.length()):
		var cx = sx + (dir.x * i)
		var cy = sy + (dir.y * i)
		if matriz_letras[cx][cy] != "-" and matriz_letras[cx][cy] != palabra[i]: return false
	return true

func _evaluar_colocacion(palabra: String, sx: int, sy: int, dir: Vector2i) -> int:
	var solapes := 0
	for i in range(palabra.length()):
		var cx: int = sx + (dir.x * i)
		var cy: int = sy + (dir.y * i)
		if cx < 0 or cy < 0 or cx >= tamaño_tablero or cy >= tamaño_tablero:
			return -1
		var actual: String = str(matriz_letras[cx][cy])
		if actual == "-":
			continue
		if actual != palabra[i]:
			return -1
		solapes += 1
	return solapes

func _rango_inicio(longitud: int, delta: int) -> Vector2i:
	if delta == 1:
		return Vector2i(0, tamaño_tablero - longitud)
	if delta == -1:
		return Vector2i(longitud - 1, tamaño_tablero - 1)
	return Vector2i(0, tamaño_tablero - 1)

func _ordenar_palabras_por_longitud_desc(a: String, b: String) -> bool:
	return a.length() > b.length()

func rellenar_espacios_vacios() -> void:
	var abecedario = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ"
	for x in range(tamaño_tablero):
		for y in range(tamaño_tablero):
			if matriz_letras[x][y] == "-": matriz_letras[x][y] = abecedario[randi() % abecedario.length()]

func dibujar_tablero_en_pantalla() -> void:
	for hijo in cuadracula.get_children(): hijo.queue_free()
	casillas_por_coordenada.clear()
	for x in range(tamaño_tablero):
		for y in range(tamaño_tablero):
			var nueva_casilla = CASILLA_ESCENA.instantiate() as Button
			cuadracula.add_child(nueva_casilla)
			nueva_casilla.get_node("Label").text = matriz_letras[x][y]
			nueva_casilla.set_meta("coor_x", x)
			nueva_casilla.set_meta("coor_y", y)
			casillas_por_coordenada[_coord_key(x, y)] = nueva_casilla
			nueva_casilla.gui_input.connect(_on_casilla_gui_input.bind(nueva_casilla))

func _coord_key(x: int, y: int) -> String:
	return "%d,%d" % [x, y]

func _obtener_casilla_por_coord(x: int, y: int) -> Button:
	return casillas_por_coordenada.get(_coord_key(x, y), null) as Button

func _normalizar_seleccion_lineal(seleccion: Array[Button]) -> Array[Button]:
	var resultado: Array[Button] = []
	if seleccion.is_empty():
		return resultado
	if seleccion.size() == 1:
		return resultado

	var inicio := seleccion[0]
	var fin := seleccion[seleccion.size() - 1]
	if inicio == null or fin == null:
		return resultado

	var sx: int = int(inicio.get_meta("coor_x", -1))
	var sy: int = int(inicio.get_meta("coor_y", -1))
	var ex: int = int(fin.get_meta("coor_x", -1))
	var ey: int = int(fin.get_meta("coor_y", -1))
	if sx < 0 or sy < 0 or ex < 0 or ey < 0:
		return resultado

	var dx: int = signi(ex - sx)
	var dy: int = signi(ey - sy)
	var dist_x: int = absi(ex - sx)
	var dist_y: int = absi(ey - sy)
	if not (dx == 0 or dy == 0 or dist_x == dist_y):
		return resultado

	var cx := sx
	var cy := sy
	while true:
		var casilla := _obtener_casilla_por_coord(cx, cy)
		if casilla == null:
			resultado.clear()
			return resultado
		resultado.append(casilla)
		if cx == ex and cy == ey:
			break
		cx += dx
		cy += dy

	return resultado

func _normalizar_palabra(texto: String) -> String:
	var t := texto.to_upper().strip_edges().replace(" ", "")
	t = t.replace("Á", "A")
	t = t.replace("É", "E")
	t = t.replace("Í", "I")
	t = t.replace("Ó", "O")
	t = t.replace("Ú", "U")
	return t

# Detectar la tecla de escape o el botón de pausa
func _input(event):
	if event.is_action_pressed("ui_cancel") and not capa_confirmacion.visible:
		gestionar_pausa()

func _on_boton_pausa_visual_pressed():
	# El botón visual hace lo mismo que la tecla ESC
	gestionar_pausa()

func gestionar_pausa():
	var nuevo_estado_pausa = !get_tree().paused # Invierte el estado actual del motor
	get_tree().paused = nuevo_estado_pausa
	
	if menu_pausa:
		menu_pausa.visible = nuevo_estado_pausa
		
	# Si quitamos la pausa (regresamos al juego), nos aseguramos de limpiar las ventanas emergentes
	if not nuevo_estado_pausa:
		if capa_confirmacion:
			capa_confirmacion.hide()

# --- BOTONES DEL MENÚ ---

func _on_continuar_pressed():
	gestionar_pausa()
	get_tree().paused = false

const ESCENA_OPCIONES = preload("res://Opcionesnivel.tscn")

func _on_opciones_pressed():
	# 1. Ocultamos momentáneamente los botones del menú de pausa principal
	$Menupausa/CenterContainer.visible = false
	# 2. Creamos una instancia de la escena de opciones
	var opciones_instancia = ESCENA_OPCIONES.instantiate()
	# 3. Le asignamos un nombre único
	opciones_instancia.name = "MenuOpcionesDinamico"
	
	# ¡IMPORTANTE!: Forzar a la nueva ventana de opciones a procesar en pausa
	opciones_instancia.process_mode = Node.PROCESS_MODE_ALWAYS
	# 4. La añadimos como hija del CanvasLayer de pausa
	$Menupausa.add_child(opciones_instancia)


func _on_salir_pressed():
	# Mostrar el cuadro de confirmación antes de salir
	capa_confirmacion.show()
	
func _on_confirmar_no_quedarme_pressed():
	capa_confirmacion.hide()

# --- LÓGICA DEL MENÚ DE PAUSA ---

func _on_boton_salir_pressed():
	# Al darle a "Salir" en el primer menú, ocultamos la pausa y mostramos confirmación
	menu_pausa.hide()
	capa_confirmacion.show()

# --- LÓGICA DE LA CAPA DE CONFIRMACIÓN ---

func _on_boton_si_confirmar_salir_pressed():
	get_tree().paused = false
	GlobalUsuario.nivel_seleccionado = numero_de_nivel
	get_tree().change_scene_to_file("res://selectorsopaletras.tscn")

func _on_boton_no_cancelar_pressed():
	# Si se arrepiente, cerramos la confirmación y VOLVEMOS al menú de pausa
	capa_confirmacion.hide()
	menu_pausa.show()

func _on_button_4_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://selectorsopaletras.tscn")
