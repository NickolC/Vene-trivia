extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")
const RUTA_ESCENA_SELECCION := "res://Scenes/Minijuegos.tscn"
const RUTA_DATOS_VERDFAL := "res://Data/minijuegos/verdadero_falso.json"

# --- RUTAS DE RECURSOS VISUALES ---
const RUTA_FUENTE = "res://font/Minecraft.ttf"
const RUTA_FONDO_BTN = "res://GFX/boton-extras.png"

@onready var capa_confirmacion = $confrimar
@onready var menu_pausa = $Menupausa

# --- CONFIGURACIÓN DE RECOMPENSAS BASE ---
const RECOMPENSA_BASE_PUNTOS := 100
const MONEDAS_POR_ESTRELLA := 50

# Tiempos de validación
const TIEMPO_TOTAL := 210.0 # 3:30 minutos en segundos
const LIMITE_3_ESTRELLAS := 90.0 # 1:30 min
const LIMITE_2_ESTRELLAS := 160.0 # 2:40 min

# --- REFERENCIAS DE INTERFAZ DEL JUEGO (RUTAS CORREGIDAS) ---
@onready var ui_juego = $CanvasLayer
@onready var ui_juego2 = $CanvasLayer/CanvasLayer2
@onready var contenedor_pregunta = $CanvasLayer/CanvasLayer2/VBoxContainer/CenterContainer
@onready var fondo_pregunta = $CanvasLayer/CanvasLayer2/VBoxContainer/CenterContainer/PanelContainer
@onready var label_pregunta = $CanvasLayer/CanvasLayer2/VBoxContainer/CenterContainer/PanelContainer/MarginContainer/Label
@onready var btn_verdadero = $CanvasLayer/CanvasLayer2/VBoxContainer/GridContainer/Button
@onready var btn_falso = $CanvasLayer/CanvasLayer2/VBoxContainer/GridContainer/Button2
@onready var label_contador = $CanvasLayer/Label
@onready var label_progreso = $CanvasLayer/Label2

# --- REFERENCIAS PARA LA PANTALLA DE RESULTADOS ---
@onready var panel_resultados =$PantallaResultados
@onready var res_label_nivel = $PantallaResultados/Panel/nivel
@onready var res_label_puntos = $PantallaResultados/Panel/puntos
@onready var res_label_dinero = $PantallaResultados/Panel/dinero
@onready var res_label_tiempo = $PantallaResultados/Panel/tiempofinal
@onready var res_estrella1 = $PantallaResultados/Panel/HBoxContainer/TextureRect
@onready var res_estrella2 = $PantallaResultados/Panel/HBoxContainer/TextureRect2
@onready var res_estrella3 = $PantallaResultados/Panel/HBoxContainer/TextureRect3

# --- REFERENCIAS DEL PERSONAJE ---
@onready var sprite_personaje = $capapersonaje/SpritePersonaje
@onready var panel_dialogo = $capapersonaje/PanelContainer
@onready var label_dialogo = $capapersonaje/PanelContainer/MarginContainer/Label

var pose_normal = preload("res://GFX/normal.png")
var pose_feliz = preload("res://GFX/Feliz.png")
var pose_preocupado = preload("res://GFX/preocupado.png")
var pose_pensativo = preload("res://GFX/pensativo.png")

var img_estrella_llena = preload("res://GFX/estrella completada.png")
var img_estrella_vacia = preload("res://GFX/estrella vacia.png")

# --- VARIABLES DE ESTADO ---
var db: SQLite
var numero_de_nivel: int = 1
var datos_nivel: Array = []

var tiempo_restante: float = TIEMPO_TOTAL
var juego_activo: bool = false
var pregunta_actual: int = 0
var aciertos: int = 0
var bloqueando_clicks: bool = false

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if menu_pausa: 
		menu_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
		menu_pausa.hide()
	if capa_confirmacion:
		capa_confirmacion.process_mode = Node.PROCESS_MODE_ALWAYS
		capa_confirmacion.hide()

	db = SQLiteHelper.open_db_connection()
	numero_de_nivel = maxi(1, int(GlobalUsuario.nivel_seleccionado))
	tiempo_restante = TIEMPO_TOTAL
	
	# Ocultar todos los paneles inicialmente
	if ui_juego: ui_juego.hide()
	if ui_juego2: ui_juego2.hide()
	if panel_resultados: panel_resultados.hide()
	if panel_dialogo: panel_dialogo.hide()
	
	_cargar_datos_nivel()
	
	if datos_nivel.is_empty():
		Alertas.mostrar_alerta("No hay preguntas configuradas para este nivel.", 2.5)
		Configuracion.change_scene_to_file("res://selectorverdaderofalso.tscn")
		return

	# Preparación visual y de interacciones
	_ajustar_panel_pregunta()
	_estilizar_y_conectar_botones()

	_actualizar_cronometro()
	_actualizar_progreso()
	await _ejecutar_presentacion_inicial()
	
	_configurar_interactividad_botones()
		# Conexión explícita por código (más seguro que el editor)
	if btn_verdadero and not btn_verdadero.pressed.is_connected(_on_btn_verdadero_pressed):
		btn_verdadero.pressed.connect(_on_btn_verdadero_pressed)
		
	if btn_falso and not btn_falso.pressed.is_connected(_on_btn_falso_pressed):
		btn_falso.pressed.connect(_on_btn_falso_pressed)

func _configurar_interactividad_botones() -> void:
	var botones = [btn_verdadero, btn_falso]
	for btn in botones:
		if btn:
			# CRÍTICO: Asegurar que el botón reciba el evento
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			# Forzar cursor de flecha estándar
			btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
			# Asegurar que no sea transparente a clics
			btn.flat = false 

func _process(delta: float) -> void:
	if juego_activo and not get_tree().paused:
		tiempo_restante -= delta
		if tiempo_restante <= 0.0:
			tiempo_restante = 0.0
			juego_activo = false
			_actualizar_cronometro()
			_procesar_fin_del_juego(true)
		else:
			_actualizar_cronometro()

# ==========================================================
# 🛠️ ESTILIZACIÓN Y DESBLOQUEO VISUAL
# ==========================================================

func _ajustar_panel_pregunta() -> void:
	# 1. Ajustar Panel contenedor para que domine el CenterContainer
	if fondo_pregunta:
		fondo_pregunta.custom_minimum_size = Vector2(850, 100) # Tamaño fijo amplio
		# CRÍTICO: Prevenir que este panel tape los clics de los botones
		fondo_pregunta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	# 2. Ajustar Label de texto
	if label_pregunta:
		label_pregunta.custom_minimum_size = Vector2(200, 80)
		label_pregunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label_pregunta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label_pregunta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# CRÍTICO: El texto tampoco debe tapar clics
		label_pregunta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if ResourceLoader.exists(RUTA_FUENTE):
			label_pregunta.add_theme_font_override("font", load(RUTA_FUENTE))
		
		# Letra grande
		label_pregunta.add_theme_font_size_override("font_size", 38)

func _estilizar_y_conectar_botones() -> void:
	var mi_fuente = load(RUTA_FUENTE) if ResourceLoader.exists(RUTA_FUENTE) else null

	var st = StyleBoxTexture.new()
	st.texture = load("res://GFX/boton-extras.png")
	# Agregamos padding para que la letra no quede pegada a los bordes de la imagen
	st.content_margin_left = 20
	st.content_margin_right = 20
	st.content_margin_top = 10
	st.content_margin_bottom = 10

	var botones = [btn_verdadero, btn_falso]
	for btn in botones:
		if not btn: continue
		
		# Limpiar conexiones fantasma del editor
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)
			
		# CRÍTICO: Obligar al botón a atrapar el ratón
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# MANTENER CURSOR ORIGINAL (Evita que cambie o se esconda)
		btn.mouse_default_cursor_shape = Control.CURSOR_ARROW 
		
		# IMPORTANTE: Desactivar 'flat' y el icono normal, usaremos el StyleBox
		btn.flat = false
		btn.icon = null 
		
		if tex_fondo:
			btn.add_theme_stylebox_override("normal", st)
			btn.add_theme_stylebox_override("hover", st)
			btn.add_theme_stylebox_override("pressed", st)
			btn.add_theme_stylebox_override("focus", st)
			
		# Texto: Fuente, Tamaño GRANDE y Color NEGRO
		if mi_fuente:
			btn.add_theme_font_override("font", mi_fuente)
			
		btn.add_theme_font_size_override("font_size", 42)
		btn.add_theme_color_override("font_color", Color.BLACK)
		btn.add_theme_color_override("font_hover_color", Color(0.2, 0.2, 0.2)) # Oscurece un poco al pasar el mouse
		btn.add_theme_color_override("font_pressed_color", Color.BLACK)
		btn.add_theme_color_override("font_focus_color", Color.BLACK)
		
		btn.custom_minimum_size = Vector2(600, 140)
		
		# Elevamos el botón para que quede por encima de capas invisibles
		btn.z_index = 100
		
	# Conexiones limpias por código
	if btn_verdadero:
		btn_verdadero.text = "VERDADERO"
		btn_verdadero.pressed.connect(_on_btn_verdadero_pressed)
	
	if btn_falso:
		btn_falso.text = "FALSO"
		btn_falso.pressed.connect(_on_btn_falso_pressed)

# ==========================================================
# 🛡️ RESPALDO GLOBAL DE CLICS (FALLBACK ANTI-BLOQUEOS)
# ==========================================================
func _unhandled_input(event: InputEvent) -> void:
	if not juego_activo or bloqueando_clicks: return
	
	# Si un panel invisible está tapando tus botones, este código fuerza el clic de todas formas
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if btn_verdadero and btn_verdadero.get_global_rect().has_point(event.global_position):
			get_viewport().set_input_as_handled()
			_on_btn_verdadero_pressed()
		elif btn_falso and btn_falso.get_global_rect().has_point(event.global_position):
			get_viewport().set_input_as_handled()
			_on_btn_falso_pressed()

# --- ACTUALIZACIÓN DE TEXTOS Y DATOS ---

func _actualizar_cronometro() -> void:
	if label_contador == null: return
	var tiempo_entero := int(tiempo_restante)
	var minutos := tiempo_entero / 60
	var segundos := tiempo_entero % 60
	label_contador.text = "%02d:%02d" % [minutos, segundos]

func _actualizar_progreso() -> void:
	if label_progreso:
		label_progreso.text = "Aciertos: %d / %d" % [aciertos, datos_nivel.size()]

func _cargar_datos_nivel() -> void:
	datos_nivel.clear()
	if not FileAccess.file_exists(RUTA_DATOS_VERDFAL): return
	
	var archivo := FileAccess.open(RUTA_DATOS_VERDFAL, FileAccess.READ)
	if archivo == null: return
	
	var parsed: Variant = JSON.parse_string(archivo.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY: return
	
	var clave_nivel = str(numero_de_nivel)
	if parsed.has(clave_nivel):
		var array_preguntas = parsed[clave_nivel]
		if typeof(array_preguntas) == TYPE_ARRAY:
			datos_nivel = array_preguntas

# --- DIÁLOGOS Y PRESENTACIÓN ---
func decir_mensaje(texto: String, tiempo: float = 3.0) -> void:
	if label_dialogo == null or panel_dialogo == null: return
	
	label_dialogo.show() 
	if label_dialogo.get_parent(): label_dialogo.get_parent().show()
	label_dialogo.text = texto
	
	var tween = create_tween()
	panel_dialogo.modulate.a = 0
	panel_dialogo.show()
	tween.tween_property(panel_dialogo, "modulate:a", 1.0, 0.2)
	
	await get_tree().create_timer(tiempo).timeout
	
	var tween_out = create_tween()
	tween_out.tween_property(panel_dialogo, "modulate:a", 0.0, 0.2)
	await tween_out.finished
	panel_dialogo.hide()

func cambiar_pose(nueva_textura: Texture2D) -> void:
	if sprite_personaje == null or nueva_textura == null: return
	sprite_personaje.texture = nueva_textura
	var t = create_tween()
	sprite_personaje.scale = Vector2(0.9, 0.9)
	t.tween_property(sprite_personaje, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

func _ejecutar_presentacion_inicial() -> void:
	cambiar_pose(pose_normal)
	await decir_mensaje("¡Bienvenido al Nivel " + str(numero_de_nivel) + " de Verdadero o Falso!", 3.0)
	
	cambiar_pose(pose_pensativo)
	await decir_mensaje("¡ATENCIÓN! Tienes 3:30 minutos para responder todas las oraciones. ¡Lee bien!", 4.0)
	
	cambiar_pose(pose_feliz)
	await decir_mensaje("¡Tu tiempo comienza ahora! ¡Mucha suerte!", 2.0)
	
	if label_dialogo and label_dialogo.get_parent():
		label_dialogo.get_parent().hide()
	
	_iniciar_nivel()

# --- FLUJO DEL JUEGO ---
func _iniciar_nivel() -> void:
	if ui_juego2: ui_juego2.show()
	if ui_juego: ui_juego.show() 
	juego_activo = true
	_mostrar_pregunta()

func _mostrar_pregunta() -> void:
	if btn_verdadero: btn_verdadero.modulate = Color.WHITE
	if btn_falso: btn_falso.modulate = Color.WHITE
	
	if pregunta_actual < datos_nivel.size():
		var p = datos_nivel[pregunta_actual]
		if label_pregunta:
			label_pregunta.text = p.get("texto", "Error cargando la pregunta")
		bloqueando_clicks = false
	else:
		_procesar_fin_del_juego(false) 

func _on_btn_verdadero_pressed() -> void:
	_procesar_respuesta(true, btn_verdadero)

func _on_btn_falso_pressed() -> void:
	_procesar_respuesta(false, btn_falso)

func _procesar_respuesta(es_verdadero: bool, btn_presionado: Button) -> void:
	if bloqueando_clicks or not juego_activo: return
	bloqueando_clicks = true 
	
	var p = datos_nivel[pregunta_actual]
	var respuesta_correcta: bool = p.get("respuesta", false)
	var explicacion: String = p.get("explicacion", "")
	
	if btn_presionado:
		btn_presionado.modulate = Color.YELLOW
		
	var tiempo_guardado = juego_activo
	juego_activo = false 
	
	if es_verdadero == respuesta_correcta:
		aciertos += 1
		cambiar_pose(pose_feliz)
		_actualizar_progreso()
		await decir_mensaje("¡Correcto! " + explicacion, 4.0)
	else:
		cambiar_pose(pose_preocupado)
		await decir_mensaje("¡Oh no! " + explicacion, 4.0)
	
	pregunta_actual += 1
	juego_activo = tiempo_guardado
	
	if tiempo_restante > 0:
		_mostrar_pregunta()
	else:
		_procesar_fin_del_juego(true)
	
	await get_tree().create_timer(1.0).timeout
	bloqueando_clicks = false

# --- PROCESAMIENTO FINAL ---
func _procesar_fin_del_juego(por_tiempo_agotado: bool) -> void:
	juego_activo = false
	if ui_juego: ui_juego.hide()
	if ui_juego2: ui_juego2.hide()
	
	var tiempo_transcurrido = TIEMPO_TOTAL - tiempo_restante
	var estrellas = 0
	var ratio_aciertos: float = float(aciertos) / float(maxi(1, datos_nivel.size()))
	
	if por_tiempo_agotado:
		cambiar_pose(pose_preocupado)
		await decir_mensaje("¡Se te acabó el tiempo!", 3.0)
		
		if ratio_aciertos >= 0.8:
			estrellas = 2
			await decir_mensaje("¡Pero respondiste la mayoría bien! Buen trabajo.", 3.0)
		elif ratio_aciertos >= 0.5:
			estrellas = 1
			await decir_mensaje("Lograste acertar la mitad. ¡Intenta ser más rápido la próxima!", 3.5)
		else:
			estrellas = 0
			await decir_mensaje("Faltó velocidad y precisión. ¡Volvamos a intentarlo!", 3.5)
	else:
		if ratio_aciertos < 0.6: 
			estrellas = 0
			cambiar_pose(pose_pensativo)
			await decir_mensaje("Terminaste rápido, pero tuviste demasiados errores. ¡Lee con más calma!", 4.0)
		else:
			if tiempo_transcurrido <= LIMITE_3_ESTRELLAS:
				estrellas = 3
				cambiar_pose(pose_feliz)
				await decir_mensaje("¡Increíble velocidad! Lo completaste antes de 1:30 min. ¡3 ESTRELLAS!", 4.0)
			elif tiempo_transcurrido <= LIMITE_2_ESTRELLAS:
				estrellas = 2
				cambiar_pose(pose_feliz)
				await decir_mensaje("¡Muy bien! Lo lograste en excelente tiempo. ¡2 ESTRELLAS!", 3.5)
			else:
				estrellas = 1
				cambiar_pose(pose_normal)
				await decir_mensaje("¡Meta superada! Completaste el nivel dentro del límite. ¡1 ESTRELLA!", 3.5)

	var puntos : int = estrellas * RECOMPENSA_BASE_PUNTOS + (aciertos * 10)
	var monedas : int = estrellas * MONEDAS_POR_ESTRELLA
	
	if estrellas > 0:
		_guardar_progreso_db(puntos, estrellas)

	_mostrar_pantalla_resultados(estrellas, puntos, monedas, tiempo_transcurrido)

func _mostrar_pantalla_resultados(estrellas: int, puntos: int, monedas: int, tiempo_seg: float) -> void:
	if panel_resultados == null: return
	
	if res_label_nivel: res_label_nivel.text = "NIVEL " + str(numero_de_nivel)
	if res_label_puntos: res_label_puntos.text = "Puntaje Total: " + str(puntos)
	if res_label_dinero: res_label_dinero.text = "Dinero Ganado: " + str(monedas) + "Bs."
	
	var minutes := int(tiempo_seg) / 60
	var segundos := int(tiempo_seg) % 60
	if res_label_tiempo: res_label_tiempo.text = "Tiempo: %02d:%02d" % [minutes, segundos]
	
	if res_estrella1: res_estrella1.texture = img_estrella_llena if estrellas >= 1 else img_estrella_vacia
	if res_estrella2: res_estrella2.texture = img_estrella_llena if estrellas >= 2 else img_estrella_vacia
	if res_estrella3: res_estrella3.texture = img_estrella_llena if estrellas == 3 else img_estrella_vacia
	
	panel_resultados.show()

# --- LOGICA DE LOS 4 BOTONES DE RESULTADOS ---
func _on_btn_repetir_nivel_pressed() -> void:
	_cerrar_db_seguro()
	get_tree().reload_current_scene()

func _on_btn_menu_minijuegos_pressed() -> void:
	_cerrar_db_seguro()
	Configuracion.change_scene_to_file(RUTA_ESCENA_SELECCION)

func _on_btn_selector_verdaderofalso_pressed() -> void:
	_cerrar_db_seguro()
	Configuracion.change_scene_to_file("res://selectorverdaderofalso.tscn")

func _on_btn_siguiente_nivel_pressed() -> void:
	_cerrar_db_seguro()
	GlobalUsuario.nivel_seleccionado = int(GlobalUsuario.nivel_seleccionado) + 1
	get_tree().reload_current_scene()

func _cerrar_db_seguro() -> void:
	if db:
		SQLiteHelper.close_db_connection(db)
		db = null

# --- BASE DE DATOS ---
func _guardar_progreso_db(pts: int, estrellas: int) -> void:
	if estrellas == 0 or db == null: return
	var id_user = GlobalUsuario.usuario_actual_id
	var usr_name = SQLiteHelper.escape(GlobalUsuario.nombre_alumno)
	
	db.query("INSERT INTO minijuegos_resultados (NU_USU, NM_ALUMNO, NM_MINIJUEGO, NU_PUNTOS, NU_ESTRELLAS, NU_INTENTOS) VALUES (%d, '%s', 'verdadero_falso_%d', %d, %d, 1);" % [id_user, usr_name, numero_de_nivel, pts, estrellas])
	
	var prox := numero_de_nivel + 1
	db.query("UPDATE Alumnos SET NU_NIVEL_MAX = %d WHERE NU_USU = %d AND NU_NIVEL_MAX < %d;" % [prox, id_user, prox])
	
	SQLiteHelper.mirror_minijuegos_resultados(db, id_user, GlobalUsuario.nombre_alumno, "verdadero_falso", pts, estrellas)
	
	db.query("SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d;" % id_user)
	var dinero_total := 0
	if not db.query_result.is_empty(): dinero_total = int(db.query_result[0].get("NU_DINERO", 0))
	Logros.evaluar_post_nivel(estrellas, pts, dinero_total)

# --- SISTEMA DE PAUSAS Y CONFIRMACIONES ---
func _input(event):
	if event.is_action_pressed("ui_cancel") and not capa_confirmacion.visible:
		gestionar_pausa()

func _on_boton_pausa_visual_pressed():
	gestionar_pausa()

func gestionar_pausa():
	var nuevo_estado_pausa = !get_tree().paused 
	get_tree().paused = nuevo_estado_pausa
	if menu_pausa: menu_pausa.visible = nuevo_estado_pausa
	if not nuevo_estado_pausa:
		if capa_confirmacion: capa_confirmacion.hide()

func _on_continuar_pressed():
	gestionar_pausa()
	get_tree().paused = false

const ESCENA_OPCIONES = preload("res://Opcionesnivel.tscn")

func _on_opciones_pressed():
	$Menupausa/CenterContainer.visible = false
	var opciones_instancia = ESCENA_OPCIONES.instantiate()
	opciones_instancia.name = "MenuOpcionesDinamico"
	opciones_instancia.process_mode = Node.PROCESS_MODE_ALWAYS
	$Menupausa.add_child(opciones_instancia)

func _on_salir_pressed():
	capa_confirmacion.show()
	
func _on_confirmar_no_quedarme_pressed():
	capa_confirmacion.hide()

func _on_boton_salir_pressed():
	menu_pausa.hide()
	capa_confirmacion.show()

func _on_boton_si_confirmar_salir_pressed():
	get_tree().paused = false
	GlobalUsuario.nivel_seleccionado = numero_de_nivel
	get_tree().change_scene_to_file("res://selectorverdaderofalso.tscn")

func _on_boton_no_cancelar_pressed():
	capa_confirmacion.hide()
	menu_pausa.show()

func _on_button_4_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://selectorverdaderofalso.tscn")
