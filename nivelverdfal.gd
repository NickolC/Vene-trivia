extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")
const RUTA_ESCENA_SELECCION := "res://Scenes/Minijuegos.tscn"
const RUTA_DATOS_VERDFAL := "res://Data/minijuegos/verdadero_falso.json"

@onready var capa_confirmacion = $confrimar
@onready var menu_pausa = $Menupausa

# --- CONFIGURACIÓN DE RECOMPENSAS BASE ---
const RECOMPENSA_BASE_PUNTOS := 100
const MONEDAS_POR_ESTRELLA := 50

# Tiempos de validación
const TIEMPO_TOTAL := 210.0 # 3:30 minutos en segundos
const LIMITE_3_ESTRELLAS := 90.0 # 1:30 min
const LIMITE_2_ESTRELLAS := 160.0 # 2:40 min

# --- REFERENCIAS DE INTERFAZ DEL JUEGO ---
@onready var ui_juego = $CanvasLayer
@onready var ui_juego2 = $CanvasLayer/CanvasLayer2
@onready var contenedor_pregunta = $CanvasLayer/CanvasLayer2/VBoxContainer/CenterContainer
@onready var fondo_pregunta = $CanvasLayer/CanvasLayer2/VBoxContainer/CenterContainer/PanelContainer
@onready var label_pregunta =$CanvasLayer/CanvasLayer2/VBoxContainer/CenterContainer/PanelContainer/MarginContainer/Label
@onready var btn_verdadero = $CanvasLayer/CanvasLayer2/VBoxContainer/GridContainer/Button
@onready var btn_falso = $CanvasLayer/CanvasLayer2/VBoxContainer/GridContainer/Button2
@onready var label_contador = $CanvasLayer/Label # Donde se muestra el tiempo (Ajusta la ruta si es diferente)
@onready var label_progreso = $CanvasLayer/Label2 # Asegúrate de crear este Label para mostrar los aciertos

# --- REFERENCIAS PARA LA PANTALLA DE RESULTADOS ---
@onready var panel_resultados = $PantallaResultados
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
	ui_juego.hide()
	ui_juego2.hide()
	if panel_resultados: panel_resultados.hide()
	if panel_dialogo: panel_dialogo.hide()
	
	_cargar_datos_nivel()
	
	if datos_nivel.is_empty():
		Alertas.mostrar_alerta("No hay preguntas configuradas para este nivel.", 2.5)
		Configuracion.change_scene_to_file("res://selectorverdaderofalso.tscn")
		return

	# Conectar los botones de opciones
	if not btn_verdadero.pressed.is_connected(_on_btn_respuesta_pressed):
		btn_verdadero.pressed.connect(_on_btn_respuesta_pressed.bind(true))
	if not btn_falso.pressed.is_connected(_on_btn_respuesta_pressed):
		btn_falso.pressed.connect(_on_btn_respuesta_pressed.bind(false))
	
	# Preparar textos de botones (opcional si ya los tienes seteados en el editor)
	btn_verdadero.text = "VERDADERO"
	btn_falso.text = "FALSO"

	_actualizar_cronometro()
	_actualizar_progreso()
	await _ejecutar_presentacion_inicial()

func _process(delta: float) -> void:
	if juego_activo and not get_tree().paused:
		tiempo_restante -= delta
		if tiempo_restante <= 0.0:
			tiempo_restante = 0.0
			juego_activo = false
			_actualizar_cronometro()
			_procesar_fin_del_juego(true) # Finalizado por límite de tiempo
		else:
			_actualizar_cronometro()

func _actualizar_cronometro() -> void:
	if label_contador == null: return
	var tiempo_entero := int(tiempo_restante)
	var minutos := tiempo_entero / 60
	var segundos := tiempo_entero % 60
	label_contador.text = "%02d:%02d" % [minutos, segundos]

func _actualizar_progreso() -> void:
	if label_progreso:
		label_progreso.text = "Aciertos: %d / %d" % [aciertos, datos_nivel.size()]

# --- CARGA DEL JSON ---
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
	ui_juego.show() # Mostrar interfaz del juego
	ui_juego2.show() # Mostrar interfaz del juego
	juego_activo = true
	_mostrar_pregunta()

func _mostrar_pregunta() -> void:
	btn_verdadero.modulate = Color.WHITE
	btn_falso.modulate = Color.WHITE
	
	if pregunta_actual < datos_nivel.size():
		var p = datos_nivel[pregunta_actual]
		label_pregunta.text = p.get("texto", "Error cargando la pregunta")
		bloqueando_clicks = false
	else:
		_procesar_fin_del_juego(false) # Terminó respondiendo todas

func _on_btn_respuesta_pressed(es_verdadero: bool) -> void:
	if bloqueando_clicks or not juego_activo: return
	bloqueando_clicks = true # Evitar doble click
	
	var p = datos_nivel[pregunta_actual]
	var respuesta_correcta: bool = p.get("respuesta", false)
	var explicacion: String = p.get("explicacion", "")
	
	# Efecto visual en el botón seleccionado
	if es_verdadero:
		btn_verdadero.modulate = Color.YELLOW
	else:
		btn_falso.modulate = Color.YELLOW
		
	# Pausar cronómetro brevemente mientras lee la explicación (Opcional)
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
	juego_activo = tiempo_guardado # Reanudar el tiempo
	
	if tiempo_restante > 0:
		_mostrar_pregunta()
	else:
		_procesar_fin_del_juego(true)

# --- PROCESAMIENTO FINAL ---
func _procesar_fin_del_juego(por_tiempo_agotado: bool) -> void:
	juego_activo = false
	ui_juego.hide() # Ocultamos todo el tablero de juego
	
	var tiempo_transcurrido = TIEMPO_TOTAL - tiempo_restante
	var estrellas = 0
	
	# Calcular ratio de completado si el tiempo se agota
	var ratio_aciertos: float = float(aciertos) / float(maxi(1, datos_nivel.size()))
	
	if por_tiempo_agotado:
		cambiar_pose(pose_preocupado)
		await decir_mensaje("¡Se te acabó el tiempo!", 3.0)
		
		# Si se acabó el tiempo, evaluamos en base a su esfuerzo (las que sí pudo responder bien)
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
		# Finalizó respondiendo todo antes del tiempo
		if ratio_aciertos < 0.6: # Penalización si responde a lo loco (Menos del 60% bien)
			estrellas = 0
			cambiar_pose(pose_pensativo)
			await decir_mensaje("Terminaste rápido, pero tuviste demasiados errores. ¡Lee con más calma!", 4.0)
		else:
			# Completó con buen puntaje, evaluamos por TIEMPO RÁPIDO
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

	# Cálculo de recompensas
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
	# Asegúrate de colocar aquí el nombre exacto de tu escena selectora de niveles Verdadero/Falso
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
	var time_str = Time.get_datetime_string_from_system().replace("T", " ")
	
	var completado_juego := 1 if estrellas == 3 else 0
	
	# Usando tabla genérica de minijuegos como en columnas, adaptar según la que prefieras
	db.query("INSERT INTO minijuegos_resultados (NU_USU, NM_ALUMNO, NM_MINIJUEGO, NU_PUNTOS, NU_ESTRELLAS, NU_INTENTOS) VALUES (%d, '%s', 'verdadero_falso_%d', %d, %d, 1);" % [id_user, usr_name, numero_de_nivel, pts, estrellas])
	
	var prox := numero_de_nivel + 1
	db.query("UPDATE Alumnos SET NU_NIVEL_MAX = %d WHERE NU_USU = %d AND NU_NIVEL_MAX < %d;" % [prox, id_user, prox])
	
	SQLiteHelper.mirror_minijuegos_resultados(db, id_user, GlobalUsuario.nombre_alumno, "verdadero_falso", pts, estrellas)
	
	db.query("SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d;" % id_user)
	var dinero_total := 0
	if not db.query_result.is_empty(): dinero_total = int(db.query_result[0].get("NU_DINERO", 0))
	Logros.evaluar_post_nivel(estrellas, pts, dinero_total)

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
