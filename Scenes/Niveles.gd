extends Node

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")
const TOTAL_PREGUNTAS_RONDA := 15
const PUNTOS_RESPUESTA_CORRECTA := 5
const UMBRAL_2_ESTRELLAS := 10
const UMBRAL_1_ESTRELLA := 5
const RUTA_ESCENA_NIVEL := "res://Nivel 1.tscn"
const ANCHO_PREGUNTA_RATIO := 0.50
const ALTO_PREGUNTA_BASE_RATIO := 0.16
const ALTO_PREGUNTA_EXTRA_RATIO := 0.07
const TOP_PREGUNTA_RATIO := 0.50
const ESPACIO_ENTRE_PREGUNTA_Y_RESPUESTAS := 0.02
const ALTO_RESPUESTAS_RATIO := 0.22

var numero_de_nivel: int = 1
var nombre_estudiante: String

var db: SQLite

var estrellas_ganadas: int = 0
var puntaje_total: int = 0
var img_estrella_llena = preload("res://GFX/estrella completada.png")
var img_estrella_vacia = preload("res://GFX/estrella vacia.png")
var textura_boton_respuesta = preload("res://GFX/boton-extras.png")

var todas_las_preguntas: Array = []
var pool_disponible: Array = []
var preguntas_partida_actual: Array = []
var botones_respuesta: Array[Button] = []
var mi_fuente = load("res://GFX/Minecraft.ttf")

var ya_aviso_tiempo_mediano = false
var ya_aviso_tiempo_corto = false # Para que no repita el aviso de 5 segundos

var comodin_usado = false
var comodin_llamada_usado = false
var comodin_publico_usado = false

var stock_mitad: int = 0
var stock_publico: int = 0
var stock_probabilidad: int = 0
var dinero_ganado_ultimo: int = 0

var lista_circulos = [] # Aquí guardaremos los iconos

@onready var sprite_personaje = $capapersonaje/SpritePersonaje
@onready var panel_dialogo = $capapersonaje/PanelContainer
@onready var label_dialogo = $capapersonaje/PanelContainer/MarginContainer/Label

# Cargar tus PNGs (Asegúrate de que las rutas sean correctas)
var pose_normal = preload("res://GFX/normal.png")
var pose_feliz = preload("res://GFX/Feliz.png")
var pose_preocupado = preload("res://GFX/preocupado.png")
var pose_pensativo = preload("res://GFX/pensativo.png")

@onready var contenedor_progreso = $barraprogreso/Control/HBoxContainer
@onready var textura_gris = preload("res://GFX/gris.png")
@onready var textura_verde = preload("res://GFX/verde.png")
@onready var textura_roja = preload("res://GFX/rojo.png")

# Referencia de los nodos de la UI
@onready var contenedor_pregunta = $CanvasLayer2/VBoxContainer/CenterContainer
@onready var fondo_pregunta = $CanvasLayer2/VBoxContainer/CenterContainer/PanelContainer
@onready var label_pregunta = $CanvasLayer2/VBoxContainer/CenterContainer/PanelContainer/MarginContainer/Label
@onready var contenedor_botones = $CanvasLayer2/VBoxContainer/GridContainer
@onready var timer_pregunta = $CanvasLayer2/VBoxContainer/Timer
@onready var barra_tiempo = $CanvasLayer2/VBoxContainer/ProgressBar

@onready var panel_llamada = $CanvasLayer/CenterContainer/PanelContainer
@onready var texto_llamada = $CanvasLayer/CenterContainer/PanelContainer/MarginContainer/HBoxContainer/Label
@onready var timer_llamada = Timer.new()

@onready var menu_pausa = $Menupausa
@onready var capa_confirmacion = $confrimar

@onready var label_puntaje = $Labelpuntaje

var indice_actual = 0
var puntos = 0

var tiempo_inicio: float = 0.0

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
	sprite_personaje.texture = nueva_textura
	var t = create_tween()
	sprite_personaje.scale = Vector2(0.9, 0.9)
	t.tween_property(sprite_personaje, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	menu_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	capa_confirmacion.process_mode = Node.PROCESS_MODE_ALWAYS
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	_ajustar_layout_pregunta()
	$CanvasLayer2/VBoxContainer/CenterContainer/PanelContainer/MarginContainer.queue_sort()
	db = SQLiteHelper.open_db_connection()
	_cargar_usuario_actual()
	numero_de_nivel = _obtener_nivel_actual()
	GlobalUsuario.nivel_seleccionado = numero_de_nivel

	cargar_json()
	if todas_las_preguntas.is_empty():
		push_error("No se pudo cargar el banco de preguntas del nivel %d." % numero_de_nivel)
		return

	$PantallaResultados/Panel/Label.text = "NIVEL %d" % numero_de_nivel

	preparar_nuevo_nivel()
	crear_barra_progreso(TOTAL_PREGUNTAS_RONDA)

	if not timer_pregunta.timeout.is_connected(_on_timer_timeout):
		timer_pregunta.timeout.connect(_on_timer_timeout)

	add_child(timer_llamada)
	timer_llamada.one_shot = true
	if not timer_llamada.timeout.is_connected(_on_terminar_llamada):
		timer_llamada.timeout.connect(_on_terminar_llamada)

	if not $Buttonpausa.pressed.is_connected(_on_boton_pausa_visual_pressed):
		$Buttonpausa.pressed.connect(_on_boton_pausa_visual_pressed)

	menu_pausa.hide()
	capa_confirmacion.hide()
	_ocultar_ui_juego()

	cambiar_pose(pose_normal)
	decir_mensaje("¡Bienvenido! Preparate para este reto.", 2.0)
	await get_tree().create_timer(3.0).timeout

	cambiar_pose(pose_feliz)
	decir_mensaje("¡La ronda comienza ahora! ¡Mucha suerte!", 2.0)
	await get_tree().create_timer(2.0).timeout

	label_dialogo.get_parent().hide()
	_mostrar_ui_juego()
	_actualizar_botones_comodines()
	comenzar_nivel()
	tiempo_inicio = Time.get_ticks_msec() # Inicia el cronómetro al cargar

func _on_viewport_size_changed() -> void:
	_ajustar_layout_pregunta()

func _ajustar_layout_pregunta() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var factor_texto_largo: float = clampf((float(label_pregunta.text.length()) - 90.0) / 120.0, 0.0, 1.0)
	var ancho_minimo: float = minf(640.0, viewport_size.x * 0.90)
	var ancho_pregunta: float = clampf(viewport_size.x * ANCHO_PREGUNTA_RATIO, ancho_minimo, 1040.0)
	var alto_pregunta: float = clampf(
		viewport_size.y * (ALTO_PREGUNTA_BASE_RATIO + ALTO_PREGUNTA_EXTRA_RATIO * factor_texto_largo),
		150.0,
		260.0
	)

	fondo_pregunta.custom_minimum_size = Vector2(ancho_pregunta, alto_pregunta)
	label_pregunta.custom_minimum_size = Vector2(ancho_pregunta - 30.0, alto_pregunta - 30.0)

	var top_pregunta: float = clampf(TOP_PREGUNTA_RATIO - (factor_texto_largo * 0.03), 0.40, 0.52)
	var bottom_pregunta: float = top_pregunta + (alto_pregunta / viewport_size.y)

	contenedor_pregunta.anchor_top = top_pregunta
	contenedor_pregunta.anchor_bottom = bottom_pregunta

	contenedor_botones.anchor_top = clampf(bottom_pregunta + ESPACIO_ENTRE_PREGUNTA_Y_RESPUESTAS, 0.68, 0.78)
	contenedor_botones.anchor_bottom = clampf(contenedor_botones.anchor_top + ALTO_RESPUESTAS_RATIO, 0.90, 0.98)

func _ajustar_fuente_pregunta(texto: String) -> void:
	var longitud := texto.length()
	var tamano_fuente := 28

	if longitud > 180:
		tamano_fuente = 20
	elif longitud > 140:
		tamano_fuente = 22
	elif longitud > 105:
		tamano_fuente = 24
	elif longitud > 80:
		tamano_fuente = 26

	label_pregunta.add_theme_font_size_override("font_size", tamano_fuente)

func _exit_tree() -> void:
	SQLiteHelper.close_db_connection(db)

func _cargar_usuario_actual() -> void:
	var query := ""
	if GlobalUsuario.usuario_actual_id > 0:
		query = "SELECT NU_USU, NM_ALUMNO, NU_NIVEL_MAX, NU_MITAD, NU_PUBLICO, NU_PROBABILIDAD FROM Alumnos WHERE NU_USU = %d;" % GlobalUsuario.usuario_actual_id
	elif not GlobalUsuario.nombre_alumno.is_empty():
		query = "SELECT NU_USU, NM_ALUMNO, NU_NIVEL_MAX, NU_MITAD, NU_PUBLICO, NU_PROBABILIDAD FROM Alumnos WHERE NM_ALUMNO = '%s';" % SQLiteHelper.escape(GlobalUsuario.nombre_alumno)
	else:
		return

	db.query(query)
	if db.query_result.is_empty():
		print("No se pudo validar la sesion del alumno.")
		return

	var resultado: Dictionary = db.query_result[0]
	GlobalUsuario.usuario_actual_id = int(resultado.get("NU_USU", GlobalUsuario.usuario_actual_id))
	GlobalUsuario.nombre_alumno = str(resultado.get("NM_ALUMNO", GlobalUsuario.nombre_alumno))
	GlobalUsuario.nivel_maximo = int(resultado.get("NU_NIVEL_MAX", GlobalUsuario.nivel_maximo))
	_cargar_stock_comodines(resultado)

func _cargar_stock_comodines(fila: Dictionary) -> void:
	stock_mitad = int(fila.get("NU_MITAD", 0))
	stock_publico = int(fila.get("NU_PUBLICO", 0))
	stock_probabilidad = int(fila.get("NU_PROBABILIDAD", 0))

func _actualizar_botones_comodines() -> void:
	$Buttoncomodin.disabled = comodin_usado or stock_mitad <= 0
	$Buttonpublico.disabled = comodin_llamada_usado or stock_publico <= 0
	$Buttonporcentaje.disabled = comodin_publico_usado or stock_probabilidad <= 0

func _ocultar_ui_juego() -> void:
	$CanvasLayer2/VBoxContainer/CenterContainer.hide()
	$CanvasLayer2/VBoxContainer/GridContainer.hide()
	$Buttoncomodin.hide()
	$Buttonpublico.hide()
	$Buttonporcentaje.hide()
	$Buttonpausa.hide()
	$Labelpuntaje.hide()
	$barraprogreso.hide()
	$CanvasLayer2/VBoxContainer/ProgressBar.hide()

func _mostrar_ui_juego() -> void:
	$CanvasLayer2/VBoxContainer/CenterContainer.show()
	$CanvasLayer2/VBoxContainer/GridContainer.show()
	$Buttoncomodin.show()
	$Buttonpublico.show()
	$Buttonporcentaje.show()
	$Buttonpausa.show()
	$Labelpuntaje.show()
	$barraprogreso.show()
	$CanvasLayer2/VBoxContainer/ProgressBar.show()

func crear_barra_progreso(cantidad):
	# Limpiamos por si acaso
	for hijo in contenedor_progreso.get_children():
		hijo.queue_free()
	lista_circulos.clear()
	
	for i in range(cantidad):
		var circulo = TextureRect.new()
		circulo.texture = textura_gris
		circulo.expand_mode = 2
		circulo.custom_minimum_size = Vector2(30, 30) # Tamaño del círculo
		
		contenedor_progreso.add_child(circulo)
		lista_circulos.append(circulo)

# Llamamos a esta función después de cada respuesta
func actualizar_circulo_progreso(fue_correcta: bool):
	if indice_actual < lista_circulos.size():
		if fue_correcta:
			lista_circulos[indice_actual].texture = textura_verde
		else:
			lista_circulos[indice_actual].texture = textura_roja

func dibujar_linea_fondo():
	var linea = $Line2D
	linea.clear_points()
	# Punto inicial (izquierda del contenedor)
	linea.add_point(contenedor_progreso.global_position + Vector2(0, 15)) 
	# Punto final (derecha del contenedor)
	linea.add_point(contenedor_progreso.global_position + Vector2(contenedor_progreso.size.x, 15))

# Detectar la tecla de escape o el botón de pausa
func _input(event):
	if event.is_action_pressed("ui_cancel") and not capa_confirmacion.visible:
		gestionar_pausa()

func _on_boton_pausa_visual_pressed():
	# El botón visual hace lo mismo que la tecla ESC
	gestionar_pausa()
	get_tree().paused = true

func gestionar_pausa():
	var estado_pausa = !get_tree().paused # Invierte el estado actual
	get_tree().paused = estado_pausa
	menu_pausa.visible = estado_pausa
	# Si quitamos la pausa, ocultamos también el cuadro de confirmación
	if not estado_pausa:
		capa_confirmacion.hide()
	

# --- BOTONES DEL MENÚ ---

func _on_continuar_pressed():
	gestionar_pausa()
	get_tree().paused = false

const ESCENA_OPCIONES = preload("res://Opcionesnivel.tscn")

func _on_opciones_pressed():
	get_tree().paused = false
	# 1. Ocultamos momentáneamente los botones del menú de pausa principal
	$Menupausa/CenterContainer.visible = false
	# 2. Creamos una instancia de la escena de opciones
	var opciones_instancia = ESCENA_OPCIONES.instantiate()
	# 3. Le asignamos un nombre único para encontrarla fácilmente después
	opciones_instancia.name = "MenuOpcionesDinamico"
	# 4. La añadimos como hija del CanvasLayer de pausa para que se muestre arriba
	$Menupausa.add_child(opciones_instancia)
	get_tree().paused = true


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
	# Reemplaza con la ruta real de tu escena de mapa
	get_tree().change_scene_to_file("res://Mapa.tscn")

func _on_boton_no_cancelar_pressed():
	# Si se arrepiente, cerramos la confirmación y VOLVEMOS al menú de pausa
	capa_confirmacion.hide()
	menu_pausa.show()

func actualizar_interfaz_puntos():
	# Usamos str() para convertir el número a texto
	label_puntaje.text = str(puntos)
	
	# Animación de "Pop"
	var tween = create_tween()
	# Crece al 120% y vuelve al 100% en 0.2 segundos
	tween.tween_property(label_puntaje, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(label_puntaje, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Nota: Para que el escalado funcione desde el centro, 
	# cambia el 'Pivot Offset' del Label a la mitad de su tamaño.

# === 🌟 MODIFICADO: FUNCIÓN DE LECTURA ADAPTATIVA PARA CARGAR JSON DEL DOCENTE ===
func cargar_json():
	# Si el nivel es >= 16, cargamos el JSON dinámico correspondiente creado por el docente
	var path = "res://Jsons/Preguntas_nivel_%d.json" % numero_de_nivel
	
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_string = file.get_as_text().strip_edges()
		var datos = JSON.parse_string(json_string)
		if datos != null and datos is Array:
			todas_las_preguntas = datos
			pool_disponible = todas_las_preguntas.duplicate()
			pool_disponible.shuffle()
			print("JSON del docente del nivel ", numero_de_nivel, " cargado con éxito.")
		else:
			push_error("Error: El JSON del docente no es válido.")
	else:
		push_error("No existe el archivo de preguntas para el nivel %d" % numero_de_nivel)

func preparar_nuevo_nivel():
	if pool_disponible.size() < TOTAL_PREGUNTAS_RONDA:
		pool_disponible = todas_las_preguntas.duplicate()
		pool_disponible.shuffle()
	preguntas_partida_actual.clear()
	for i in range(TOTAL_PREGUNTAS_RONDA):
		var pregunta_sacada = pool_disponible.pop_front()
		preguntas_partida_actual.append(pregunta_sacada)

func comenzar_nivel():
	indice_actual = 0
	puntos = 0
	mostrar_pregunta()

func mostrar_pregunta():
	cambiar_pose(pose_normal)
	if indice_actual >= preguntas_partida_actual.size():
		finalizar_nivel()
		return

	var datos_pregunta = preguntas_partida_actual[indice_actual]
	label_pregunta.text = datos_pregunta["pregunta"]
	_ajustar_fuente_pregunta(label_pregunta.text)
	_ajustar_layout_pregunta()
	fondo_pregunta.pivot_offset = fondo_pregunta.size / 2

	botones_respuesta.clear()
	for n in contenedor_botones.get_children():
		n.queue_free()
	await get_tree().process_frame

	# Se barajan las opciones para que el docente pueda guardar siempre en la primera sin problemas
	var opciones_originales : Array = datos_pregunta["opciones"].duplicate()
	var indices_barajados := [0, 1, 2, 3]
	indices_barajados.shuffle()

	var correcta_original = datos_pregunta["correcta"]

	for i in range(opciones_originales.size()):
		var idx_mezclado = indices_barajados[i]
		var boton := Button.new()
		var texto_respuesta: String = opciones_originales[idx_mezclado]
		boton.text = texto_respuesta
		
		if texto_respuesta.length() > 25:
			boton.add_theme_font_size_override("font_size", 20)
		else:
			boton.add_theme_font_size_override("font_size", 24)
		
		boton.icon = textura_boton_respuesta
		boton.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boton.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		boton.flat = true
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		boton.custom_minimum_size = Vector2(800, 155) 
		boton.expand_icon = true
		boton.add_theme_font_override("font", mi_fuente)
		
		if texto_respuesta.length() <= 25:
			boton.add_theme_font_size_override("font_size", 28)
		boton.add_theme_color_override("font_color", Color.BLACK)
		
		# 🌟 SOLUCIÓN: Guardamos en los metadatos del botón si este corresponde a la opción correcta original
		var es_esta_correcta = (idx_mezclado == correcta_original)
		boton.set_meta("es_correcta", es_esta_correcta)
		
		# Conectamos únicamente pasando la referencia directa del propio botón presionado
		boton.pressed.connect(_on_respuesta_seleccionada.bind(boton))
		
		contenedor_botones.add_child(boton)
		botones_respuesta.append(boton)
		
	barra_tiempo.max_value = 10
	barra_tiempo.value = 10
	barra_tiempo.self_modulate = Color.GREEN
	timer_pregunta.start(10)
	ya_aviso_tiempo_corto = false
	ya_aviso_tiempo_mediano = false

func configurar_estilo_boton(boton: Button):
	var estilo = StyleBoxTexture.new()
	estilo.texture = load("res://GFX/boton-extras.png")
	# ESTO ES LO MÁS IMPORTANTE: Márgenes de Contenido
	# Estos valores obligan al texto a separarse de los bordes del icono
	estilo.content_margin_left = 30
	estilo.content_margin_right = 30
	estilo.content_margin_top = 20
	estilo.content_margin_bottom = 20
	# Aplicar el estilo a todos los estados del botón
	boton.add_theme_stylebox_override("normal", estilo)
	boton.add_theme_stylebox_override("hover", estilo)
	boton.add_theme_stylebox_override("pressed", estilo)
	boton.add_theme_stylebox_override("disabled", estilo)
	# Eliminar el icono normal para que no estorbe
	boton.icon = null

func _process(_delta):
	if not timer_pregunta.is_stopped():
		var tiempo_restante = timer_pregunta.time_left
		barra_tiempo.value = tiempo_restante
		
		# Calcular la transición de color
		actualizar_color_barra(tiempo_restante)
		
	if timer_pregunta.time_left <= 6.5 and timer_pregunta.time_left > 0:
		if not ya_aviso_tiempo_mediano and not get_tree().paused:
			ya_aviso_tiempo_mediano = true # Bloqueamos futuras repeticiones
			cambiar_pose(pose_pensativo)
			# Usamos una llamada limpia a decir_mensaje
			decir_mensaje("¡Oye! No te quedes pensando tanto, ¡el tiempo corre!", 2.5)
			
		if timer_pregunta.time_left <= 3.0 and timer_pregunta.time_left > 0:
			if not ya_aviso_tiempo_corto and not get_tree().paused:
				ya_aviso_tiempo_corto = true # Bloqueamos futuras repeticiones
				cambiar_pose(pose_preocupado)
				# Usamos una llamada limpia a decir_mensaje
				decir_mensaje("¡Rápido! ¡Solo quedan 3 segundos!", 2.5)

func _on_terminar_llamada():
	panel_llamada.hide()
	timer_pregunta.paused = false # Reanudar el tiempo de la pregunta
	
func actualizar_color_barra(tiempo):
	# Calculamos el porcentaje (de 1.0 a 0.0)
	# Si Max Value es 25, 25/25 = 1.0 (Lleno)
	var porcentaje = tiempo / barra_tiempo.max_value
	
	if porcentaje > 0.5:
		# Mientras sea más de la mitad, se mantiene Verde
		barra_tiempo.self_modulate = Color.WEB_GREEN
	else:
		# Interpolación lineal (lerp) para pasar de Verde a Rojo
		# El peso de la transición se acelera cuando queda menos tiempo
		# Usamos (porcentaje * 2) para que el rango 0.5 a 0.0 se convierta en 1.0 a 0.0
		var peso = porcentaje * 2 
		barra_tiempo.self_modulate = Color.DARK_RED.lerp(Color.WEB_GREEN, peso)

func _on_respuesta_seleccionada(boton_presionado: Button):
	timer_pregunta.stop() 
	label_dialogo.get_parent().show() 
	
	for b in botones_respuesta:
		b.disabled = true
	
	# Leemos de forma automatizada los metadatos de respuesta correcta en el botón seleccionado
	var es_correcto: bool = boton_presionado.get_meta("es_correcta", false)
	
	if es_correcto:
		puntos += PUNTOS_RESPUESTA_CORRECTA
		actualizar_interfaz_puntos()
		print("¡Correcto!")
		cambiar_color_boton(boton_presionado, Color.GREEN)
		actualizar_circulo_progreso(true)
		cambiar_pose(pose_feliz)
		
		# Mostramos la explicación pedagógica del docente
		var exp_pedagogica = preguntas_partida_actual[indice_actual]["explicacion"]
		decir_mensaje("¡Correcto! " + exp_pedagogica, 8.0)
		await get_tree().create_timer(2.5).timeout
	else:
		print("Incorrecto...")
		cambiar_color_boton(boton_presionado, Color.RED)
		
		# Buscamos en pantalla cuál botón tiene la respuesta correcta para pintarlo de Verde
		for b in botones_respuesta:
			if b.get_meta("es_correcta", false):
				cambiar_color_boton(b, Color.GREEN)
				break
				
		actualizar_circulo_progreso(false)
		cambiar_pose(pose_preocupado)
		
		var exp_pedagogica = preguntas_partida_actual[indice_actual]["explicacion"]
		decir_mensaje("¡Incorrecto! " + exp_pedagogica, 8.0)
		await get_tree().create_timer(2.5).timeout
		
	siguiente_pregunta()

func cambiar_color_boton(boton: Button, color: Color):
	# Usamos 'self_modulate' para teñir el icono sin cambiar su textura original
	boton.self_modulate = color


func _on_timer_timeout() -> void:
	# 1. Bloqueamos todos los botones para que el usuario no pueda 
	# hacer clic justo cuando el tiempo termina.
	for b in botones_respuesta:
		b.disabled = true
	
	# 2. Obtenemos el índice de la respuesta correcta desde nuestro JSON
	var id_correcta = preguntas_partida_actual[indice_actual]["correcta"]
	
	# 3. Pintamos el botón de la respuesta correcta en VERDE
	# 'botones_respuesta' es el array donde guardamos los botones al crearlos
	var boton_correcto = botones_respuesta[id_correcta]
	cambiar_color_boton(boton_correcto, Color.GREEN)
	
	print("¡Tiempo agotado! La correcta era: ", boton_correcto.text)
	
	# 4. Esperamos un par de segundos para que el usuario vea cuál era
	# antes de limpiar todo y pasar a la siguiente.
	await get_tree().create_timer(2.0).timeout 
	
	# 5. Llamamos a la función para pasar de pregunta
	siguiente_pregunta()

func siguiente_pregunta():
		# Al pasar de pregunta, mostramos el dato curioso si existe en el JSON
	var datos_actual = preguntas_partida_actual[indice_actual]
	if datos_actual.has("dato_curioso") and not str(datos_actual["dato_curioso"]).is_empty():
		cambiar_pose(pose_pensativo)
		await decir_mensaje("¿Sabías qué? " + str(datos_actual["dato_curioso"]), 4.0)
	
	indice_actual += 1
	if indice_actual >= TOTAL_PREGUNTAS_RONDA:
		finalizar_nivel()
	else:
		# Pequeña pausa opcional antes de la siguiente para que el usuario respire
		await get_tree().create_timer(1.0).timeout 
		mostrar_pregunta()

func finalizar_nivel():
	var tiempo_fin = Time.get_ticks_msec()
	var tiempo_total_seg = (tiempo_fin - tiempo_inicio) / 1000.0
	timer_pregunta.stop()
	if indice_actual >= TOTAL_PREGUNTAS_RONDA:
		_ocultar_ui_juego()
	print("Nivel terminado. Puntos: ", puntos)
	
	if indice_actual >= TOTAL_PREGUNTAS_RONDA:
		var mensaje_final = ""
		if puntos >= 60:
			mensaje_final = "¡Increíble esfuerzo! Has demostrado una maestría total en este nivel."
		elif puntos >= 40:
			mensaje_final = "¡Muy bien hecho! Tu dedicación se nota en cada respuesta."
		else:
			mensaje_final = "¡Buen intento! Con un poco más de práctica serás imparable."

		await get_tree().create_timer(1.5).timeout 
		cambiar_pose(pose_normal)
		await decir_mensaje(mensaje_final, 4.0)

	var total_preguntas := TOTAL_PREGUNTAS_RONDA
	var respuestas_correctas := int(round(float(puntos) / float(PUNTOS_RESPUESTA_CORRECTA)))
	estrellas_ganadas = _calcular_estrellas(respuestas_correctas)
	
	var bono_estrellas := estrellas_ganadas * 150
	var puntos_finales := (respuestas_correctas * 100) + bono_estrellas
	
	guardar_final_nivel(total_preguntas, respuestas_correctas, puntos_finales, estrellas_ganadas)
	_guardar_tiempo_en_db(tiempo_total_seg)
	mostrar_resultados(respuestas_correctas)

func _calcular_estrellas(respuestas_correctas: int) -> int:
	if respuestas_correctas >= TOTAL_PREGUNTAS_RONDA:
		return 3
	if respuestas_correctas >= UMBRAL_2_ESTRELLAS:
		return 2
	if respuestas_correctas >= UMBRAL_1_ESTRELLA:
		return 1
	return 0

func _on_buttoncomodin_pressed() -> void:
	if comodin_usado or indice_actual >= preguntas_partida_actual.size():
		return # No hacer nada si ya se usó o no hay preguntas
	
	var pregunta_actual = preguntas_partida_actual[indice_actual]
	var indice_correcto = pregunta_actual["correcta"]
	
	# Creamos una lista con los índices de las respuestas incorrectas (0, 1, 2, 3 excepto el correcto)
	var indices_incorrectos = []
	for i in range(4):
		if i != indice_correcto:
			indices_incorrectos.append(i)
	
	# Barajamos los incorrectos y elegimos uno para QUE SE QUEDE (el sobreviviente)
	indices_incorrectos.shuffle()
	@warning_ignore("unused_variable")
	var indice_incorrecto_sobreviviente = indices_incorrectos.pop_front()
	
	# Ahora, los que quedan en el array 'indices_incorrectos' son los que debemos ELIMINAR/OCULTAR
	for indice_a_eliminar in indices_incorrectos:
		var boton = botones_respuesta[indice_a_eliminar]
		
		# Opción A: Hacerlo invisible y que no se pueda clickear
		boton.modulate.a = 0 # Transparencia total
		boton.disabled = true
		
		# Opción B (Si quieres que desaparezca el espacio):
		# boton.visible = false 
	
	comodin_usado = true
	stock_mitad -= 1
	db.query("UPDATE Alumnos SET NU_MITAD = NU_MITAD - 1 WHERE NU_USU = %d AND NU_MITAD > 0;" % GlobalUsuario.usuario_actual_id)
	$Buttoncomodin.disabled = true
	$Buttoncomodin.modulate = Color.DARK_GRAY

func generar_respuesta_amigo():
	var pregunta_actual = preguntas_partida_actual[indice_actual]
	var indice_correcto = pregunta_actual["correcta"]
	var opciones = pregunta_actual["opciones"]
	
	# Creamos una lista de opciones incorrectas por si el amigo falla
	var opciones_incorrectas = []
	for i in range(opciones.size()):
		if i != indice_correcto:
			opciones_incorrectas.append(opciones[i])
	opciones_incorrectas.shuffle() # Mezclamos para elegir una al azar
	
	var suerte = randf() # Número entre 0.0 y 1.0
	
	# --- NUEVA LÓGICA DE PROBABILIDADES ---
	
	if suerte > 0.85: # 15% Probabilidad: No sabe nada
		return "¡Hola! Ay... me agarras en frío. No tengo ni la más remota idea, mejor no te arriesgues conmigo."
		
	elif suerte > 0.65: # 20% Probabilidad: DUDA Y SE EQUIVOCA (Nueva)
		var fallo = opciones_incorrectas[0]
		return "Mmm... déjame ver... estoy casi seguro de que es '" + fallo + "', pero no me hagas mucho caso que estoy dudando."
		
	elif suerte > 0.35: # 30% Probabilidad: DUDA PERO ACIERTA
		var acierto = opciones[indice_correcto]
		return "¡Qué difícil! Estaba entre dos opciones... pero pensándolo bien, creo que la correcta es '" + acierto + "'."
		
	else: # 35% Probabilidad: ESTÁ MUY SEGURO (Acierto total)
		var acierto = opciones[indice_correcto]
		return "¡Esa es fácil! La respuesta es '" + acierto + "'. ¡Rápido, márcala antes de que se acabe el tiempo!"

func _on_buttonpublico_pressed() -> void:
	panel_dialogo.hide() # Cierre instantáneo
	$capapersonaje/SpritePersonaje.hide() # Ocultar al presentador
	
	$TimerInactividad.stop() # Detenemos el regaño por inactividad
	
	if comodin_llamada_usado: return
	
	comodin_llamada_usado = true
	stock_publico -= 1
	db.query("UPDATE Alumnos SET NU_PUBLICO = NU_PUBLICO - 1 WHERE NU_USU = %d AND NU_PUBLICO > 0;" % GlobalUsuario.usuario_actual_id)
	$Buttonpublico.disabled = true
	#timer_pregunta.paused = true # Pausamos el tiempo del juego
	
	panel_llamada.show()
	$CanvasLayer.show()
	
	# SIMULACIÓN DE CONVERSACIÓN (Divagando)
	texto_llamada.text = "Llamando..."
	await get_tree().create_timer(1.0).timeout
	
	texto_llamada.text = "Amigo: ¿Hola? ¿Quién habla?"
	await get_tree().create_timer(1.25).timeout
	
	texto_llamada.text = "Amigo: ¡Ah, hola! Espera... déjame leer la pregunta..."
	await get_tree().create_timer(1.5).timeout
	
	# Aquí mostramos el resultado de la probabilidad
	texto_llamada.text = "Amigo: " + generar_respuesta_amigo()
	
	# --- TIEMPO DE LECTURA (5 SEGUNDOS) ---
	# El diálogo se queda fijo 5 segundos para que el usuario lo lea
	await get_tree().create_timer(2.5).timeout
	
	# --- CIERRE AUTOMÁTICO ---
	cerrar_llamada_automaticamente()
	$capapersonaje/SpritePersonaje.show()
	$capapersonaje/PanelContainer/MarginContainer/Label.show()
	
	$TimerInactividad.start() # Lo reiniciamos al terminar

func cerrar_llamada_automaticamente():
	panel_llamada.hide()
	texto_llamada.text = "" # Limpiamos el texto para la próxima vez
	
	# Reanudamos el tiempo de la pregunta donde se quedó
	timer_pregunta.paused = false
	print("Llamada finalizada. El tiempo de juego continúa.")

func generar_votos_publico() -> Dictionary:
	for b in botones_respuesta:
		b.disabled = true
		
	var pregunta_actual = preguntas_partida_actual[indice_actual]
	var correcta = pregunta_actual["correcta"]
	var porcentajes = [0, 0, 0, 0]
	
	var suerte = randf()
	var indice_ganador = correcta # Por defecto, el público elige la correcta
	
	# Determinar quién gana la votación
	if suerte > 0.8: # 20% de probabilidad de que el público se equivoque masivamente
		var incorrectas = []
		for i in range(4): 
			if i != correcta: incorrectas.append(i)
		incorrectas.shuffle()
		indice_ganador = incorrectas[0] # El público vota por una falsa
	
	# Repartir los puntos (Sistema de pesos)
	var puntos_restantes = 100
	
	# El ganador se lleva entre el 40% y 70%
	var votos_ganador = randi_range(40, 70)
	porcentajes[indice_ganador] = votos_ganador
	puntos_restantes -= votos_ganador
	
	# Repartir lo que queda entre los otros 3
	for i in range(4):
		if i == indice_ganador: continue
		if i == 3 or (i == 2 && indice_ganador == 3): # Al último le damos lo que sobre
			porcentajes[i] = puntos_restantes
		else:
			var sorteo = randi_range(0, puntos_restantes)
			porcentajes[i] = sorteo
			puntos_restantes -= sorteo
			
	return {"votos": porcentajes, "ganador": indice_ganador}


func _on_buttonporcentaje_pressed() -> void:
	panel_dialogo.hide() # Cierre instantáneo
	$capapersonaje/SpritePersonaje.hide() # Ocultar al presentador
	
	for b in botones_respuesta:
		b.disabled = true
	
	if comodin_publico_usado: return
	comodin_publico_usado = true
	stock_probabilidad -= 1
	db.query("UPDATE Alumnos SET NU_PROBABILIDAD = NU_PROBABILIDAD - 1 WHERE NU_USU = %d AND NU_PROBABILIDAD > 0;" % GlobalUsuario.usuario_actual_id)
	$Buttonporcentaje.disabled = true
	
	timer_pregunta.paused = true
	$PublicoUI.show()
	
	var resultados = generar_votos_publico()
	var votos = resultados["votos"]
	
	# Mostrar los resultados en las barras (puedes usar un Tween para que suban)
	for i in range(4):
		var barra = get_node("PublicoUI/ProgressBar" + str(i))
		var label_pct = get_node("PublicoUI/Label" + str(i))
		
		if barra != null:
			var tween = create_tween()
			# Importante: tween_property devuelve un PropertyTweener, 
			# nos aseguramos de que 'barra' sea un objeto válido antes de llamar a esto.
			tween.tween_property(barra, "value", votos[i], 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			if label_pct != null:
				label_pct.text = str(votos[i]) + "%"

	# Esperar 15 segundos antes de cerrar automáticamente
	await get_tree().create_timer(3.0).timeout
	cerrar_publico()
	
	$capapersonaje/SpritePersonaje.show()
	$capapersonaje/PanelContainer/MarginContainer/Label.show()

func cerrar_publico():
	$PublicoUI.hide()
	timer_pregunta.paused = false
	
	for b in botones_respuesta:
		b.disabled = false

func _on_timer_inactividad_timeout():
	# Solo hablamos si el juego no está pausado y el presentador no está diciendo otra cosa
	if not get_tree().paused and not panel_dialogo.visible:
		cambiar_pose(pose_pensativo)
		
		# La función decir_mensaje ya se encarga de:
		# 1. Mostrar el panel
		# 2. Poner el texto
		# 3. Esperar el tiempo (4.0 segundos en este caso)
		# 4. Ocultar el panel
		decir_mensaje("¡Oye! No te quedes pensando tanto, ¡el tiempo corre!", 4.0)

func mostrar_resultados(respuestas_correctas: int) -> void:
	puntos = respuestas_correctas * PUNTOS_RESPUESTA_CORRECTA
	estrellas_ganadas = _calcular_estrellas(respuestas_correctas)

	var bono := estrellas_ganadas * 150
	
	puntaje_total = (respuestas_correctas * 100) + bono
	$PantallaResultados/Panel/Label2.text = "Puntaje Total: " + str(puntaje_total)
	
	$PantallaResultados/Panel/LabelDinero.text = "Dinero ganado: %d Bs." % dinero_ganado_ultimo
	actualizar_estrellas_visual(estrellas_ganadas)
	configurar_botones(estrellas_ganadas)

	if indice_actual >= TOTAL_PREGUNTAS_RONDA:
		$PantallaResultados.show()
		

func actualizar_estrellas_visual(cantidad):
	# Supongamos que tienes 3 TextureRect dentro del HBoxContainer
	var estrellas = $PantallaResultados/Panel/HBoxContainer.get_children()
	for i in range(estrellas.size()):
		if i < cantidad:
			# Cambiamos la imagen
			estrellas[i].texture = img_estrella_llena
			
			# Animación de "Pop"
			var tween = create_tween()
			estrellas[i].scale = Vector2(0, 0) # Empieza invisible/pequeña
			# Crece un poco más del 100% y vuelve a su tamaño normal
			tween.tween_property(estrellas[i], "scale", Vector2(1.2, 1.2), 0.2).set_delay(i * 0.3)
			tween.tween_property(estrellas[i], "scale", Vector2(1.0, 1.0), 0.1)
		else:
			estrellas[i].texture = img_estrella_vacia
			estrellas[i].scale = Vector2(1.0, 1.0)

func configurar_botones(estrellas):
	# Condición: Dejar de mostrar "Repetir" si ya tiene 3 estrellas
	if estrellas == 3:
		$PantallaResultados/Panel/HBoxContainer2/Button3.hide()
	else:
		$PantallaResultados/Panel/HBoxContainer2/Button3.show()
		
	if estrellas == 0 or not _hay_siguiente_nivel():
		$PantallaResultados/Panel/HBoxContainer2/Button.hide()
	else:
		$PantallaResultados/Panel/HBoxContainer2/Button.show()
		
func _on_btn_siguiente_pressed():
	var siguiente_nivel := numero_de_nivel + 1
	if _existe_banco_nivel(siguiente_nivel):
		GlobalUsuario.nivel_seleccionado = siguiente_nivel
		Configuracion.change_scene_to_file(RUTA_ESCENA_NIVEL)
	else:
		Configuracion.change_scene_to_file("res://Mapa.tscn")

func _on_btn_repetir_pressed():
	# Reseteamos manualmente las variables críticas antes de recargar
	indice_actual = 0
	puntos = 0
	ya_aviso_tiempo_corto = false
	ya_aviso_tiempo_mediano = false
	# Ahora sí, recargamos
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_btn_mapa_pressed():
	GlobalUsuario.nivel_seleccionado = numero_de_nivel
	Configuracion.change_scene_to_file("res://Mapa.tscn")

func _on_btn_menu_pressed():
	Configuracion.change_scene_to_file("res://Scenes/menu-alumno.tscn")

func guardar_final_nivel(total_preg: int, correctas: int, punto: int, estrellas: int) -> void:
	if db == null:
		print("No hay conexion activa con la DB para guardar resultados.")
		return

	var incorrectas := total_preg - correctas
	var id_actual:int = GlobalUsuario.usuario_actual_id
	var nombre_actual := SQLiteHelper.escape(GlobalUsuario.nombre_alumno)
	var completado_100 := 1 if estrellas == 3 else 0
	var nivel: int = maxi(1, numero_de_nivel)
	var fecha_intento := Time.get_datetime_string_from_system().replace("T", " ")

	var query_intento := "INSERT INTO niveles_intentos " + \
	"(NU_USU, NM_ALUMNO, NU_NIVEL, NU_PREG, NU_RESPC, NU_RESPI, NU_PUNTOS, NU_ESTRELLAS, SW_COM, FE_INTENTO) " + \
	"VALUES (%d, '%s', %d, %d, %d, %d, %d, %d, %d, '%s');" % [
		id_actual, nombre_actual, nivel, total_preg, correctas, incorrectas, punto, estrellas, completado_100, SQLiteHelper.escape(fecha_intento)
	]
	var check_intento := db.query(query_intento)

	var mejor_guardado := _obtener_resultado_mejor_guardado(id_actual, nivel)
	var usar_resultado_actual := true
	if not mejor_guardado.is_empty():
		usar_resultado_actual = _es_mejor_resultado(
			correctas,
			incorrectas,
			punto,
			estrellas,
			int(mejor_guardado.get("NU_RESPC", 0)),
			int(mejor_guardado.get("NU_RESPI", 0)),
			int(mejor_guardado.get("NU_PUNTOS", 0)),
			int(mejor_guardado.get("NU_ESTRELLAS", 0))
		)

	var query_nivel := ""
	if mejor_guardado.is_empty():
		query_nivel = "INSERT INTO niveles " + \
		"(NU_NIVEL, NU_USU, NM_ALUMNO, NU_PREG, NU_RESPC, NU_RESPI, NU_PUNTOS, NU_ESTRELLAS, SW_COM) " + \
		"VALUES (%d, %d, '%s', %d, %d, %d, %d, %d, %d);" % [
			nivel, id_actual, nombre_actual, total_preg, correctas, incorrectas, punto, estrellas, completado_100
		]
	elif usar_resultado_actual:
		query_nivel = "UPDATE niveles SET " + \
		"NM_ALUMNO = '%s', NU_PREG = %d, NU_RESPC = %d, NU_RESPI = %d, NU_PUNTOS = %d, NU_ESTRELLAS = %d, SW_COM = %d " + \
		"WHERE NU_NIVEL = %d AND NU_USU = %d;" % [
			nombre_actual, total_preg, correctas, incorrectas, punto, estrellas, completado_100, nivel, id_actual
		]
	else:
		query_nivel = "UPDATE niveles SET NM_ALUMNO = '%s' WHERE NU_NIVEL = %d AND NU_USU = %d;" % [nombre_actual, nivel, id_actual]

	var check_nivel := db.query(query_nivel)

	var proximo_nivel: int = nivel + 1
	var check_alumno := true
	var estrellas_referencia := estrellas
	if not mejor_guardado.is_empty():
		estrellas_referencia = maxi(estrellas_referencia, int(mejor_guardado.get("NU_ESTRELLAS", 0)))

	if estrellas_referencia > 0:
		var query_alumno := "UPDATE Alumnos SET NU_NIVEL_MAX = %d WHERE NU_USU = %d AND NU_NIVEL_MAX < %d;" % [
			proximo_nivel, id_actual, proximo_nivel
		]
		check_alumno = db.query(query_alumno)

	dinero_ganado_ultimo = correctas * 10 + estrellas * 25
	db.query("UPDATE Alumnos SET NU_DINERO = NU_DINERO + %d WHERE NU_USU = %d;" % [dinero_ganado_ultimo, id_actual])
	db.query("SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d;" % id_actual)
	var dinero_total: int = 0
	if not db.query_result.is_empty():
		dinero_total = int(db.query_result[0].get("NU_DINERO", 0))

	Logros.evaluar_post_nivel(estrellas, punto, dinero_total)
	if check_intento and check_nivel and check_alumno:
		SQLiteHelper.log_activity(db, "alumno", GlobalUsuario.nombre_alumno, "nivel_%d_estrellas_%d_puntos_%d" % [nivel, estrellas, punto])
		if estrellas_referencia > 0:
			GlobalUsuario.nivel_maximo = maxi(GlobalUsuario.nivel_maximo, proximo_nivel)
		print("Nivel guardado:", nivel, " para el ID:", id_actual)
	else:
		print("Error en los queries. Revisa nombres de tablas/columnas.")

func _obtener_resultado_mejor_guardado(usuario_id: int, nivel: int) -> Dictionary:
	var query := "SELECT NU_RESPC, NU_RESPI, NU_PUNTOS, NU_ESTRELLAS FROM niveles WHERE NU_USU = %d AND NU_NIVEL = %d LIMIT 1;" % [usuario_id, nivel]
	if not db.query(query):
		return {}
	if db.query_result.is_empty():
		return {}
	return db.query_result[0]

func _es_mejor_resultado(correctas_actual: int, incorrectas_actual: int, puntos_actual: int, estrellas_actual: int, correctas_previas: int, incorrectas_previas: int, puntos_previos: int, estrellas_previas: int) -> bool:
	if estrellas_actual != estrellas_previas:
		return estrellas_actual > estrellas_previas
	if puntos_actual != puntos_previos:
		return puntos_actual > puntos_previos
	if correctas_actual != correctas_previas:
		return correctas_actual > correctas_previas
	if incorrectas_actual != incorrectas_previas:
		return incorrectas_actual < incorrectas_previas
	return false

func _obtener_nivel_actual() -> int:
	var nivel := maxi(1, int(GlobalUsuario.nivel_seleccionado))
	var scene := get_tree().current_scene
	if scene == null:
		return nivel

	var scene_path := scene.scene_file_path
	if scene_path.is_empty():
		return nivel
	if scene_path == RUTA_ESCENA_NIVEL:
		return nivel

	var nombre := scene_path.get_file()
	var digitos := ""
	for c in nombre:
		if c.is_valid_int():
			digitos += c

	if digitos.is_empty():
		return nivel

	return maxi(1, int(digitos))

func _hay_siguiente_nivel() -> bool:
	return _existe_banco_nivel(numero_de_nivel + 1)

func _existe_banco_nivel(nivel: int) -> bool:
	var path := "res://Jsons/Preguntas_nivel_%d.json" % nivel
	return FileAccess.file_exists(path)

func _guardar_tiempo_en_db(segundos: float) -> void:
	var tipo = "TRIVIA" # O detecta si es un minijuego basado en el nombre de la escena
	var query = "REPLACE INTO tiempos_niveles (NU_USU, TX_TIPO_NIVEL, NU_NIVEL, TIEMPOTOTAL_SEGUNDOS) VALUES (%d, '%s', %d, %f);" % [
		GlobalUsuario.usuario_actual_id, tipo, numero_de_nivel, segundos
	]
	db.query(query)
