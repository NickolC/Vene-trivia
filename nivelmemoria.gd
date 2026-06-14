extends Control

class ParMemoria:
	var id: int
	var termino: String
	var pista: String
	func _init(_id: int, _termino: String, _pista: String):
		self.id = _id
		self.termino = _termino
		self.pista = _pista

const ESCENA_CARTA = preload("res://CartaMemoria.tscn")
const RUTA_SELECTOR := "res://Scenes/Minijuegos.tscn"
const RUTA_DATOS_MEMORIA := "res://Data/minijuegos/memoria.json"

# --- CONFIGURACIÓN DE RECOMPENSAS BASE ---
const RECOMPENSA_BASE_PUNTOS := 100
const MONEDAS_POR_ESTRELLA := 50

# --- REFERENCIAS DE INTERFAZ ---
@onready var interfaz_juego = $InterfazJuego
@onready var contenedor_cartas: GridContainer = $ContenedorCartas
@onready var label_cronometro: Label = $InterfazJuego/Control/Label
@onready var label_progreso_parejas: Label = $InterfazJuego/Control/Label2
@onready var boton_pausa_visual = $Buttonpausa

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

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var banco_memoria_runtime: Dictionary = {}
var banco_parejas: Array[ParMemoria] = []

var primera_carta: CartaMemoria = null
var segunda_carta: CartaMemoria = null
var bloqueado: bool = false

# Variables de control de tiempo y progreso
var tiempo_total_nivel: float = 480.0 # 8 Minutos máximo
var tiempo_restante: float = 480.0
var juego_activo: bool = false
var _errores: int = 0
var parejas_restantes: int = 0
var total_parejas_nivel: int = 0
var parejas_correctas_totales: int = 0
var bloqueando_clicks: bool = false

@onready var menu_pausa = $Menupausa
@onready var capa_confirmacion = $confrimar
var db: SQLite
var numero_de_nivel: int = 1

var aviso_3_estrellas_dado: bool = false
var aviso_2_estrellas_dado: bool = false
const TIEMPO_TOTAL := 480.0
const LIMITE_3_ESTRELLAS := 300.0
const LIMITE_2_ESTRELLAS := 180.0 

func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	
	if menu_pausa: 
		menu_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
		menu_pausa.hide()
	if capa_confirmacion:
		capa_confirmacion.process_mode = Node.PROCESS_MODE_ALWAYS
		capa_confirmacion.hide()
		
	if boton_pausa_visual:
		boton_pausa_visual.process_mode = Node.PROCESS_MODE_ALWAYS
		boton_pausa_visual.pressed.connect(_on_boton_pausa_visual_pressed)
		boton_pausa_visual.hide()
	
	if interfaz_juego: interfaz_juego.hide()
	if panel_resultados: panel_resultados.hide()
	if panel_dialogo: panel_dialogo.hide()
	if contenedor_cartas: contenedor_cartas.hide()
	
	db = SQLiteHelper.open_db_connection()
	numero_de_nivel = maxi(1, int(GlobalUsuario.nivel_seleccionado))
	
	_cargar_banco_memoria_desde_archivo()
	banco_parejas = _obtener_parejas_del_nivel(numero_de_nivel)
	
	if banco_parejas.is_empty():
		Alertas.mostrar_alerta("No hay contenido configurado para este nivel.", 2.5)
		Configuracion.change_scene_to_file(RUTA_SELECTOR)
		return

	contenedor_cartas.columns = 4
	total_parejas_nivel = banco_parejas.size()
	parejas_restantes = total_parejas_nivel
	parejas_correctas_totales = 0
	
	tiempo_restante = tiempo_total_nivel
	_actualizar_interfaz_cronometro()
	_actualizar_interfaz_progreso()
	
	inicializar_tablero()
	
	# Ejecutar presentación inicial con UI oculto
	await _ejecutar_presentacion_inicial()
	
	# Presentación terminada: Mostramos elementos y activamos juego
	if interfaz_juego: interfaz_juego.show()
	if contenedor_cartas: contenedor_cartas.show()
	if boton_pausa_visual: boton_pausa_visual.show()
	
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
		if tiempo_restante <= 0.0:
			tiempo_restante = 0.0
			juego_activo = false
			_actualizar_interfaz_cronometro()
			_procesar_fin_del_juego(true)
		else:
			_actualizar_interfaz_cronometro()

func _mostrar_aviso_tiempo(estrellas_perdidas: int) -> void:
	cambiar_pose(pose_preocupado)
	await decir_mensaje("¡Oh no, has perdido la oportunidad de conseguir " + str(estrellas_perdidas) + " estrellas!", 3.0)
	cambiar_pose(pose_normal)

func _actualizar_interfaz_cronometro() -> void:
	if label_cronometro == null: return
	var tiempo_entero := int(tiempo_restante)
	var minutos := tiempo_entero / 60
	var segundos := tiempo_entero % 60
	label_cronometro.text = "%02d:%02d" % [minutos, segundos]

func _actualizar_interfaz_progreso() -> void:
	if label_progreso_parejas == null: return
	label_progreso_parejas.text = "Parejas: %d / %d" % [parejas_correctas_totales, total_parejas_nivel]

# --- LÓGICA DEL PERSONAJE Y DIÁLOGOS ---

func decir_mensaje(texto: String, tiempo: float = 3.0) -> void:
	if label_dialogo == null or panel_dialogo == null: return
	bloqueando_clicks = true 
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
	bloqueando_clicks = false 

func cambiar_pose(nueva_textura: Texture2D) -> void:
	if sprite_personaje == null or nueva_textura == null: return
	sprite_personaje.texture = nueva_textura
	var t = create_tween()
	sprite_personaje.scale = Vector2(0.9, 0.9)
	t.tween_property(sprite_personaje, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

func _ejecutar_presentacion_inicial() -> void:
	cambiar_pose(pose_normal)
	await decir_mensaje("¡Bienvenido al Nivel " + str(numero_de_nivel) + " del juego de Memoria!", 2.5)
	cambiar_pose(pose_pensativo)
	await decir_mensaje("Recuerda que tienes un tiempo máximo de 8 minutos para encontrar todas las parejas.", 3.0)
	cambiar_pose(pose_feliz)
	await decir_mensaje("¡Las barajas están listas! ¡Mucha suerte!", 2.0)
	cambiar_pose(pose_normal)
	if label_dialogo and label_dialogo.get_parent():
		label_dialogo.get_parent().hide()

# --- MECÁNICA DE JUEGO ---

func inicializar_tablero() -> void:
	var lista: Array = []
	for par in banco_parejas:
		var carta_img := ESCENA_CARTA.instantiate() as CartaMemoria
		carta_img.configurar(par.id, par.termino, par.pista, false)
		carta_img.carta_seleccionada.connect(_on_carta_seleccionada)
		lista.append(carta_img)

		var carta_txt := ESCENA_CARTA.instantiate() as CartaMemoria
		carta_txt.configurar(par.id, par.termino, par.pista, true)
		carta_txt.carta_seleccionada.connect(_on_carta_seleccionada)
		lista.append(carta_txt)

	lista.shuffle()
	for hijo in contenedor_cartas.get_children():
		hijo.free() # Uso de free para evitar desincronizaciones visuales instantáneas
	for carta in lista:
		contenedor_cartas.add_child(carta)

func _on_carta_seleccionada(carta: CartaMemoria) -> void:
	if bloqueado or bloqueando_clicks or not juego_activo: return
	carta.voltear_boca_arriba()
	if primera_carta == null:
		primera_carta = carta
	else:
		segunda_carta = carta
		bloqueado = true
		_comprobar_pareja()

func _comprobar_pareja() -> void:
	if primera_carta.id_pareja == segunda_carta.id_pareja and primera_carta.es_texto != segunda_carta.es_texto:
		primera_carta.marcar_acierto()
		segunda_carta.marcar_acierto()
		parejas_restantes -= 1
		parejas_correctas_totales += 1
		_actualizar_interfaz_progreso()
		
		cambiar_pose(pose_feliz)
		var indice_correcto = randi() % 4
		var mensaje_correcto = ""
		match indice_correcto:
			0: mensaje_correcto = "¡Excelente combinación! Has descubierto una pareja válida."
			1: mensaje_correcto = "¡Magnífico! Tu memoria y asociación conceptual son correctas."
			2: mensaje_correcto = "¡Muy bien analizado! Ambos elementos corresponden al mismo contexto."
			3: mensaje_correcto = "¡Perfecto!"
		
		_limpiar_seleccion_turno()
		
		if parejas_restantes == 0:
			juego_activo = false
			_procesar_fin_del_juego(false)
		else:
			await decir_mensaje(mensaje_correcto, 2.2)
			cambiar_pose(pose_normal)
	else:
		_errores += 1
		primera_carta.marcar_error()
		segunda_carta.marcar_error()
		
		cambiar_pose(pose_preocupado)
		var indice_incorrecto = randi() % 4
		var mensaje_incorrecto = ""
		match indice_incorrecto:
			0: mensaje_incorrecto = "¡Oh, no coinciden!"
			1: mensaje_incorrecto = "Eso no es correcto."
			2: mensaje_incorrecto = "No forman una pareja conceptual."
			3: mensaje_incorrecto = "¡Fallaste!"
			
		await decir_mensaje(mensaje_incorrecto, 2.5)
		cambiar_pose(pose_normal)
		
		if is_instance_valid(primera_carta): primera_carta.mostrar_boca_abajo()
		if is_instance_valid(segunda_carta): segunda_carta.mostrar_boca_abajo()
		_limpiar_seleccion_turno()

func _limpiar_seleccion_turno() -> void:
	primera_carta = null
	segunda_carta = null
	bloqueado = false

# --- PROCESAR FIN DEL JUEGO CON DIÁLOGOS Y RESULTADOS ---

func _procesar_fin_del_juego(por_tiempo_agotado: bool) -> void:
	juego_activo = false
	
	# Ocultamos la interfaz interactiva para centrar la atención en el personaje
	if interfaz_juego: interfaz_juego.hide()
	if contenedor_cartas: contenedor_cartas.hide()
	if boton_pausa_visual: boton_pausa_visual.hide()
	
	var tiempo_seg := tiempo_total_nivel - tiempo_restante
	var estrellas := 0
	
	if not por_tiempo_agotado:
		# Regla unificada: 3 estrellas exige completar a tiempo Y sin errores.
		if tiempo_seg <= 180.0 and _errores == 0: # Menos de 3 minutos y sin fallos
			estrellas = 3
			cambiar_pose(pose_feliz)
			await decir_mensaje("¡Increíble! ¡Tiempo récord y sin fallos! Has resuelto toda la memoria en menos de 3 minutos. ¡Eres un maestro!", 4.0)
		elif tiempo_seg <= 300.0: # Menos de 5 minutos
			estrellas = 2
			cambiar_pose(pose_pensativo)
			await decir_mensaje("¡Excelente trabajo! Completaste el juego de memoria en un tiempo medio muy bueno. ¡Sigue así!", 3.5)
		else: # Menos de 8 minutos
			estrellas = 1
			cambiar_pose(pose_pensativo)
			await decir_mensaje("¡Bien hecho! Lograste resolver la memoria, pero necesitas más práctica para mejorar tu velocidad.", 3.5)
	else:
		cambiar_pose(pose_preocupado)
		await decir_mensaje("¡Oh no, has perdido la oportunidad de conseguir estrellas por tiempo, evaluare si conseguiste en base a lo respondido!", 3.0)
		cambiar_pose(pose_normal)
		var ratio_completado : float = float(parejas_correctas_totales) / float(maxi(1, total_parejas_nivel))
		if ratio_completado >= 0.75:
			estrellas = 2
			cambiar_pose(pose_pensativo)
			await decir_mensaje("¡Lograste encontrar la gran mayoría de las parejas. ¡Buen esfuerzo!", 4.0)
		elif ratio_completado >= 0.25:
			estrellas = 1
			cambiar_pose(pose_pensativo)
			await decir_mensaje("¡Lograste emparejar una cantidad mínima de cartas, nos faltó velocidad y memoria.", 4.0)
		else:
			estrellas = 0
			cambiar_pose(pose_preocupado)
			await decir_mensaje("¡No lograste completar suficientes relaciones. ¡Debemos repasar y volver a intentarlo!", 4.0)

	var puntos := estrellas * RECOMPENSA_BASE_PUNTOS + maxi(0, 50 - _errores * 4)
	var monedas := estrellas * MONEDAS_POR_ESTRELLA
	
	if estrellas > 0:
		# REP-02: mejor tiempo solo si completó (no por tiempo agotado)
		_guardar_progreso(puntos, estrellas, tiempo_seg if not por_tiempo_agotado else 0.0)

	_mostrar_pantalla_resultados(estrellas, puntos, monedas, tiempo_seg)

func _mostrar_pantalla_resultados(estrellas: int, puntos: int, monedas: int, tiempo_seg: float) -> void:
	if panel_resultados == null: return
	
	if res_label_nivel: res_label_nivel.text = "NIVEL " + str(numero_de_nivel)
	if res_label_puntos: res_label_puntos.text = "Puntaje Total: " + str(puntos)
	if res_label_dinero: res_label_dinero.text = "Dinero Ganado: " + str(monedas) + "Bs."
	
	var minutes := int(tiempo_seg) / 60
	var segundos := int(tiempo_seg) % 60
	if res_label_tiempo: res_label_tiempo.text = "Tiempo resuelto: %02d:%02d" % [minutes, segundos]
	
	if res_estrella1: res_estrella1.texture = img_estrella_llena if estrellas >= 1 else img_estrella_vacia
	if res_estrella2: res_estrella2.texture = img_estrella_llena if estrellas >= 2 else img_estrella_vacia
	if res_estrella3: res_estrella3.texture = img_estrella_llena if estrellas == 3 else img_estrella_vacia
	
	panel_resultados.show()

# --- LÓGICA DE LOS 4 BOTONES DE LA PANTALLA DE RESULTADOS ---

func _on_btn_repetir_nivel_pressed() -> void:
	_cerrar_db_seguro()
	get_tree().reload_current_scene()

func _on_btn_menu_minijuegos_pressed() -> void:
	_cerrar_db_seguro()
	Configuracion.change_scene_to_file(RUTA_SELECTOR)

func _on_btn_selector_memoria_pressed() -> void:
	_cerrar_db_seguro()
	Configuracion.change_scene_to_file("res://selectormemoria.tscn")

func _on_btn_siguiente_nivel_pressed() -> void:
	_cerrar_db_seguro()
	GlobalUsuario.nivel_seleccionado = int(GlobalUsuario.nivel_seleccionado) + 1
	get_tree().reload_current_scene()

func _cerrar_db_seguro() -> void:
	if db:
		SQLiteHelper.close_db_connection(db)
		db = null

# --- CARGA DE DATOS ---

func _cargar_banco_memoria_desde_archivo() -> void:
	banco_memoria_runtime.clear()
	if not FileAccess.file_exists(RUTA_DATOS_MEMORIA): return
	var archivo := FileAccess.open(RUTA_DATOS_MEMORIA, FileAccess.READ)
	if archivo == null: return
	var parsed: Variant = JSON.parse_string(archivo.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY: return
	banco_memoria_runtime = parsed

func _obtener_parejas_del_nivel(nivel: int) -> Array[ParMemoria]:
	var resultado: Array[ParMemoria] = []
	var clave := str(nivel)
	if not banco_memoria_runtime.has(clave): return resultado

	var filas_raw: Variant = banco_memoria_runtime[clave]
	if typeof(filas_raw) != TYPE_ARRAY: return resultado
	var filas: Array = filas_raw

	var id_local := 1
	for fila in filas:
		if typeof(fila) != TYPE_DICTIONARY: continue
		var termino := str(fila.get("termino", "")).strip_edges()
		var pista := str(fila.get("pista", "")).strip_edges()
		if termino.is_empty() or pista.is_empty(): continue
		resultado.append(ParMemoria.new(id_local, termino, pista))
		id_local += 1

	return resultado

# --- BASE DE DATOS Y PAUSAS ---

func _guardar_progreso(puntos: int, estrellas: int, tiempo_seg: float = 0.0) -> void:
	if db == null: return
	var id: int = GlobalUsuario.usuario_actual_id
	var nombre := SQLiteHelper.escape(GlobalUsuario.nombre_alumno)
	var completado := 1 if estrellas == 3 else 0
	var fecha := Time.get_datetime_string_from_system().replace("T", " ")

	db.query("INSERT INTO memoria_intentos (NU_USU, NM_ALUMNO, NU_NIVEL, NU_PUNTOS, NU_ESTRELLAS, SW_COM, FE_INTENTO) VALUES (%d, '%s', %d, %d, %d, %d, '%s');" % [id, nombre, numero_de_nivel, puntos, estrellas, completado, SQLiteHelper.escape(fecha)])

	db.query("SELECT NU_ESTRELLAS FROM memoria_niveles WHERE NU_USU = %d AND NU_NIVEL = %d;" % [id, numero_de_nivel])
	if db.query_result.is_empty():
		db.query("INSERT INTO memoria_niveles (NU_NIVEL, NU_USU, NM_ALUMNO, NU_PUNTOS, NU_ESTRELLAS, SW_COM) VALUES (%d, %d, '%s', %d, %d, %d);" % [numero_de_nivel, id, nombre, puntos, estrellas, completado])
	else:
		var prev_est := int(db.query_result[0].get("NU_ESTRELLAS", 0))
		if estrellas > prev_est:
			db.query("UPDATE memoria_niveles SET NU_PUNTOS = %d, NU_ESTRELLAS = %d, SW_COM = %d WHERE NU_NIVEL = %d AND NU_USU = %d;" % [puntos, estrellas, completado, numero_de_nivel, id])

	var prox := numero_de_nivel + 1
	db.query("UPDATE Alumnos SET NU_NIVEL_MAX_MEMORIA = %d WHERE NU_USU = %d AND NU_NIVEL_MAX_MEMORIA < %d;" % [prox, id, prox])
	SQLiteHelper.mirror_minijuegos_resultados(db, id, GlobalUsuario.nombre_alumno, "memoria", puntos, estrellas, tiempo_seg)

	# BUG-02: acreditar las monedas ganadas (estrellas * MONEDAS_POR_ESTRELLA)
	SQLiteHelper.sumar_dinero(db, id, estrellas * MONEDAS_POR_ESTRELLA)

	db.query("SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d;" % id)
	var dinero_total := 0
	if not db.query_result.is_empty(): dinero_total = int(db.query_result[0].get("NU_DINERO", 0))
	Logros.evaluar_post_nivel(estrellas, puntos, dinero_total)

func _input(event):
	if event.is_action_pressed("ui_cancel") and not capa_confirmacion.visible and not panel_resultados.visible:
		gestionar_pausa()

func _on_boton_pausa_visual_pressed():
	if not panel_resultados.visible: gestionar_pausa()

func gestionar_pausa():
	var nuevo_estado_pausa = !get_tree().paused
	get_tree().paused = nuevo_estado_pausa
	if menu_pausa: menu_pausa.visible = nuevo_estado_pausa
	if not nuevo_estado_pausa: if capa_confirmacion: capa_confirmacion.hide()

func _on_continuar_pressed(): gestionar_pausa()
func _on_salir_pressed():
	if menu_pausa: menu_pausa.hide()
	if capa_confirmacion: capa_confirmacion.show()
func _on_confirmar_no_quedarme_pressed():
	if capa_confirmacion: capa_confirmacion.hide()
	if menu_pausa: menu_pausa.show()
func _on_boton_salir_pressed():
	if menu_pausa: menu_pausa.hide()
	if capa_confirmacion: capa_confirmacion.show()
func _on_boton_si_confirmar_salir_pressed():
	get_tree().paused = false
	_cerrar_db_seguro()
	Configuracion.change_scene_to_file("res://selectormemoria.tscn")
func _on_boton_no_cancelar_pressed():
	if capa_confirmacion: capa_confirmacion.hide()
	if menu_pausa: menu_pausa.show()

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
