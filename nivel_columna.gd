extends Control

class ParejaRelacion:
	var id: int
	var texto_izq: String
	var texto_der: String
	
	func _init(_id: int, _izq: String, _der: String):
		self.id = _id
		self.texto_izq = _izq
		self.texto_der = _der

# --- CONFIGURACIÓN DE RECOMPENSAS BASE ---
const RECOMPENSA_BASE_PUNTOS := 100
const MONEDAS_POR_ESTRELLA := 50
const RUTA_ESCENA_SELECCION := "res://Scenes/Minijuegos.tscn"
const RUTA_DATOS_COLUMNAS := "res://Data/minijuegos/columnas.json"

# Diccionario de tiempos máximos por nivel (8 minutos = 480 segundos)
const TIEMPOS_POR_NIVEL: Dictionary = {
	1: 480.0, 2: 480.0, 3: 480.0, 4: 480.0, 5: 480.0,
	6: 480.0, 7: 480.0, 8: 480.0, 9: 480.0, 10: 480.0,
	11: 480.0, 12: 480.0, 13: 480.0, 14: 480.0, 15: 480.0
}

var banco_columnas_runtime: Dictionary = {}
var banco_relaciones: Array[ParejaRelacion] = []

# --- REFERENCIAS DE INTERFAZ ---
@onready var interfaz_juego = $InterfazJuego
@onready var contenedor_izq: VBoxContainer = $InterfazJuego/Control/Panel/HBoxContainer/VBoxContainer
@onready var contenedor_der: VBoxContainer = $InterfazJuego/Control/Panel/HBoxContainer/VBoxContainer2
@onready var label_titulo_tematica: Label = $InterfazJuego/Control/Label
@onready var label_cronometro: Label = $InterfazJuego/Control/Label2

# --- 🌟 NUEVAS REFERENCIAS PARA LA PANTALLA DE RESULTADOS 🌟 ---
# Asegúrate de crear este Panel o CanvasLayer en tu escena con estos nombres exactos
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

# Texturas del personaje y estrellas
var pose_normal = preload("res://GFX/normal.png")
var pose_feliz = preload("res://GFX/Feliz.png")
var pose_preocupado = preload("res://GFX/preocupado.png")
var pose_pensativo = preload("res://GFX/pensativo.png")

var img_estrella_llena = preload("res://GFX/estrella completada.png")
var img_estrella_vacia = preload("res://GFX/estrella vacia.png")

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")
var boton_izq_seleccionado: Button = null
var boton_der_seleccionado: Button = null

var conexiones_establecidas: Dictionary = {} 
var db: SQLite
var numero_de_nivel: int = 1
var tematica_actual: int = 1

# Variables de control de tiempo y progreso
var tiempo_restante: float = 480.0
var juego_activo: bool = false
var _tiempo_inicio_ms: int = 0
var _errores: int = 0
var parejas_restantes: int = 0
var total_parejas_nivel: int = 0
var parejas_correctas_totales: int = 0

@onready var capa_confirmacion = $confrimar
@onready var menu_pausa = $Menupausa

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	numero_de_nivel = maxi(1, int(GlobalUsuario.nivel_seleccionado))
	
	tiempo_restante = TIEMPOS_POR_NIVEL.get(numero_de_nivel, 480.0)
	_actualizar_interfaz_cronometro()
	
	_cargar_banco_columnas_desde_archivo()
	
	# Ocultamos la UI del juego y el panel de resultados al inicio
	if interfaz_juego: interfaz_juego.hide()
	if menu_pausa: menu_pausa.hide()
	if capa_confirmacion: capa_confirmacion.hide()
	if panel_dialogo: panel_dialogo.hide()
	if panel_resultados: panel_resultados.hide()
	
	await _ejecutar_presentacion_inicial()
	
	tematica_actual = 1
	_cargar_tematica(tematica_actual)
	
	if banco_relaciones.is_empty():
		Alertas.mostrar_alerta("No hay contenido configurado para este nivel.", 2.5)
		Configuracion.change_scene_to_file("res://selectorelacioncolumn.tscn")
		return

	parejas_restantes = banco_relaciones.size()
	
	if interfaz_juego: interfaz_juego.show()
	_tiempo_inicio_ms = Time.get_ticks_msec()
	juego_activo = true 
	inicializar_tablero()
	
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	if menu_pausa: menu_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	if capa_confirmacion: capa_confirmacion.process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if juego_activo and not get_tree().paused:
		tiempo_restante -= delta
		if tiempo_restante <= 0.0:
			tiempo_restante = 0.0
			juego_activo = false
			_actualizar_interfaz_cronometro()
			_procesar_fin_del_juego(true) # Fin por derrota de tiempo
		else:
			_actualizar_interfaz_cronometro()

func _actualizar_interfaz_cronometro() -> void:
	if label_cronometro == null: return
	var tiempo_entero := int(tiempo_restante)
	var minutos := tiempo_entero / 60
	var segundos := tiempo_entero % 60
	label_cronometro.text = "%02d:%02d" % [minutos, segundos]

# --- LÓGICA DEL PERSONAJE Y DIÁLOGOS ---

func decir_mensaje(texto: String, tiempo: float = 3.0) -> void:
	if label_dialogo == null or panel_dialogo == null: return
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

func cambiar_pose(nueva_textura: Texture2D) -> void:
	if sprite_personaje == null or nueva_textura == null: return
	sprite_personaje.texture = nueva_textura
	var t = create_tween()
	sprite_personaje.scale = Vector2(0.9, 0.9)
	t.tween_property(sprite_personaje, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

func _ejecutar_presentacion_inicial() -> void:
	cambiar_pose(pose_normal)
	await decir_mensaje("¡Bienvenido al Nivel " + str(numero_de_nivel) + " de Relación de Columnas!", 2.5)
	cambiar_pose(pose_pensativo)
	await decir_mensaje("Recuerda que tienes un tiempo máximo de 8 minutos para superar este reto.", 3.0)
	cambiar_pose(pose_feliz)
	await decir_mensaje("¡La ronda comienza ahora! ¡Mucha suerte!", 2.0)
	if label_dialogo and label_dialogo.get_parent():
		label_dialogo.get_parent().hide()

# --- CARGA DE DATOS ---

func _cargar_banco_columnas_desde_archivo() -> void:
	banco_columnas_runtime.clear()
	if not FileAccess.file_exists(RUTA_DATOS_COLUMNAS): return
	var archivo := FileAccess.open(RUTA_DATOS_COLUMNAS, FileAccess.READ)
	if archivo == null: return
	var parsed: Variant = JSON.parse_string(archivo.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY: return
	banco_columnas_runtime = parsed
	_calcular_total_parejas_del_nivel()

func _calcular_total_parejas_del_nivel() -> void:
	total_parejas_nivel = 0
	var clave_nivel = str(numero_de_nivel)
	if banco_columnas_runtime.has(clave_nivel):
		for t in ["1", "2", "3"]:
			if banco_columnas_runtime[clave_nivel].has(t) and banco_columnas_runtime[clave_nivel][t].has("parejas"):
				total_parejas_nivel += banco_columnas_runtime[clave_nivel][t]["parejas"].size()

func _cargar_tematica(num_tematica: int) -> void:
	banco_relaciones.clear()
	var clave_nivel = str(numero_de_nivel)
	var clave_tematica = str(num_tematica)
	
	if not banco_columnas_runtime.has(clave_nivel): return
	if not banco_columnas_runtime[clave_nivel].has(clave_tematica): return
	
	var datos_tematica = banco_columnas_runtime[clave_nivel][clave_tematica]
	if typeof(datos_tematica) != TYPE_DICTIONARY or not datos_tematica.has("parejas"): return
		
	if label_titulo_tematica != null:
		if datos_tematica.has("titulo"): label_titulo_tematica.text = str(datos_tematica["titulo"])
		elif datos_tematica.has("nombre"): label_titulo_tematica.text = str(datos_tematica["nombre"])
		else: label_titulo_tematica.text = "Temática " + str(num_tematica)
		
	var lista_parejas: Variant = datos_tematica["parejas"]
	if typeof(lista_parejas) != TYPE_ARRAY: return
		
	var id_local := 1
	for fila in lista_parejas:
		if typeof(fila) != TYPE_DICTIONARY: continue
		var izq = str(fila.get("izq", "")).strip_edges()
		var der = str(fila.get("der", "")).strip_edges()
		if izq.is_empty() or der.is_empty(): continue
		
		banco_relaciones.append(ParejaRelacion.new(id_local, izq, der))
		id_local += 1

func inicializar_tablero() -> void:
	contenedor_izq = get_node_or_null("InterfazJuego/Control/Panel/HBoxContainer/VBoxContainer")
	contenedor_der = get_node_or_null("InterfazJuego/Control/Panel/HBoxContainer/VBoxContainer2")
	
	if contenedor_izq == null or contenedor_der == null: return
		
	var lista_izq: Array[Button] = []
	var lista_der: Array[Button] = []
	var mi_fuente = null
	if ResourceLoader.exists("res://font/Minecraft.ttf"):
		mi_fuente = preload("res://font/Minecraft.ttf")
	
	for par in banco_relaciones:
		var btn_izq := Button.new()
		btn_izq.text = par.texto_izq
		btn_izq.custom_minimum_size = Vector2(350, 80)
		if mi_fuente: btn_izq.add_theme_font_override("font", mi_fuente)
		btn_izq.add_theme_font_size_override("font_size", 22)
		btn_izq.set_meta("id_pareja", par.id)
		btn_izq.set_meta("es_columna_izquierda", true)
		btn_izq.pressed.connect(_on_item_seleccionado.bind(btn_izq))
		lista_izq.append(btn_izq)
		
		var btn_der := Button.new()
		btn_der.text = par.texto_der
		btn_der.custom_minimum_size = Vector2(350, 80)
		if mi_fuente: btn_der.add_theme_font_override("font", mi_fuente)
		btn_der.add_theme_font_size_override("font_size", 22)
		btn_der.set_meta("id_pareja", par.id)
		btn_der.set_meta("es_columna_izquierda", false)
		btn_der.pressed.connect(_on_item_seleccionado.bind(btn_der))
		lista_der.append(btn_der)
		
	lista_izq.shuffle()
	lista_der.shuffle()
	
	for btn in lista_izq: if is_instance_valid(contenedor_izq): contenedor_izq.add_child(btn)
	for btn in lista_der: if is_instance_valid(contenedor_der): contenedor_der.add_child(btn)

# --- MECÁNICA DE JUEGO ---

func _on_item_seleccionado(btn: Button) -> void:
	var es_izq: bool = btn.get_meta("es_columna_izquierda", false)
	
	if es_izq:
		if boton_izq_seleccionado == btn:
			boton_izq_seleccionado.modulate = Color.WHITE
			boton_izq_seleccionado = null
		else:
			if boton_izq_seleccionado: boton_izq_seleccionado.modulate = Color.WHITE
			boton_izq_seleccionado = btn
			boton_izq_seleccionado.modulate = Color.YELLOW
	else:
		if boton_der_seleccionado == btn:
			boton_der_seleccionado.modulate = Color.WHITE
			boton_der_seleccionado = null
		else:
			if boton_der_seleccionado: boton_der_seleccionado.modulate = Color.WHITE
			boton_der_seleccionado = btn
			boton_der_seleccionado.modulate = Color.YELLOW
			
	if boton_izq_seleccionado and boton_der_seleccionado:
		var id_izq: int = boton_izq_seleccionado.get_meta("id_pareja", -1)
		var id_der: int = boton_der_seleccionado.get_meta("id_pareja", -2)
		
		var texto_izq = boton_izq_seleccionado.text
		var texto_der = boton_der_seleccionado.text
		
		if id_izq == id_der:
			boton_izq_seleccionado.modulate = Color.GREEN
			boton_der_seleccionado.modulate = Color.GREEN
			boton_izq_seleccionado.disabled = true
			boton_der_seleccionado.disabled = true
			
			conexiones_establecidas[boton_izq_seleccionado] = boton_der_seleccionado
			if has_node("LineasCanvas"): get_node("LineasCanvas").queue_redraw()
			
			boton_izq_seleccionado = null
			boton_der_seleccionado = null
			parejas_restantes -= 1
			parejas_correctas_totales += 1
			
			cambiar_pose(pose_feliz)
			
			# --- 5 VARIACIONES DE EXPLICACIÓN CORRECTA ---
			var indice_explicacion = randi() % 5
			var mensaje_correcto = ""
			match indice_explicacion:
				0: mensaje_correcto = "¡Excelente! '%s' corresponde con '%s' porque representa su definición conceptual exacta." % [texto_izq, texto_der]
				1: mensaje_correcto = "¡Es correcto! Relacionamos '%s' directamente con '%s', siendo su característica o fecha más relevante." % [texto_izq, texto_der]
				2: mensaje_correcto = "¡Muy bien analizado! '%s' se vincula con '%s' dado que forman parte del mismo contexto temático." % [texto_izq, texto_der]
				3: mensaje_correcto = "¡Perfecto! El elemento '%s' tiene como respuesta idónea a '%s', demostrando una asociación correcta." % [texto_izq, texto_der]
				4: mensaje_correcto = "¡Acertaste! Existe una relación lógica e histórica directa entre '%s' y '%s'." % [texto_izq, texto_der]
				
			await decir_mensaje(mensaje_correcto, 3.2)
			
			if parejas_restantes <= 0:
				_comprobar_victoria_tematica()
		else:
			_errores += 1
			boton_izq_seleccionado.modulate = Color.RED
			boton_der_seleccionado.modulate = Color.RED
			
			cambiar_pose(pose_preocupado)
			
			# --- 5 VARIACIONES DE PISTAS ANTE ERRORES ---
			var indice_pista = randi() % 5
			var mensaje_pista = ""
			
			# Buscamos la respuesta real que correspondía a la izquierda para poder armar la pista analítica
			var respuesta_esperada = ""
			for par in banco_relaciones:
				if par.texto_izq == texto_izq:
					respuesta_esperada = par.texto_der
					break
					
			match indice_pista:
				0: mensaje_pista = "¡Oh, no es correcto! Piensa un poco: para '%s', debes buscar algo más relacionado con: '%s'." % [texto_izq, respuesta_esperada]
				1: mensaje_pista = "Eso no coincide. Recuerda que el concepto '%s' guarda un vínculo estrecho con '%s'." % [texto_izq, respuesta_esperada]
				2: mensaje_pista = "¡Cerca, pero no! Intenta buscar una característica en la columna derecha que hable sobre '%s'." % respuesta_esperada
				3: mensaje_pista = "No es la pareja correcta. Una pista: el elemento '%s' se asocia con '%s'. ¡Busca algo similar!" % [texto_izq, respuesta_esperada]
				4: mensaje_pista = "¡Incorrecto! Vuelve a leer bien. '%s' no combina con '%s'. Te sugiero buscar '%s'." % [texto_izq, texto_der, respuesta_esperada]
				
			await decir_mensaje(mensaje_pista, 4.0)
			
			var b_izq = boton_izq_seleccionado
			var b_der = boton_der_seleccionado
			boton_izq_seleccionado = null
			boton_der_seleccionado = null
			
			await get_tree().create_timer(0.4).timeout
			if is_instance_valid(b_izq) and not b_izq.disabled: b_izq.modulate = Color.WHITE
			if is_instance_valid(b_der) and not b_der.disabled: b_der.modulate = Color.WHITE

func _comprobar_victoria_tematica() -> void:
	tematica_actual += 1
	if tematica_actual <= 3:
		cambiar_pose(pose_feliz)
		await decir_mensaje("¡Grandioso! Has completado esta temática correctamente.", 2.0)
		
		conexiones_establecidas.clear()
		if has_node("Node2D"): get_node("Node2D").queue_redraw()
		
		for hijo in contenedor_izq.get_children(): hijo.queue_free()
		for hijo in contenedor_der.get_children(): hijo.queue_free()
		
		await get_tree().process_frame
		
		_cargar_tematica(tematica_actual)
		parejas_restantes = banco_relaciones.size()
		inicializar_tablero()
	else:
		juego_activo = false 
		_procesar_fin_del_juego(false) # Fin completado con éxito

# --- 🌟 NUEVA FUNCIÓN MAESTRA: PROCESAR FIN DEL JUEGO CON DIÁLOGOS Y RESULTADOS 🌟 ---

func _procesar_fin_del_juego(por_tiempo_agotado: bool) -> void:
	juego_activo = false
	if interfaz_juego: interfaz_juego.hide()

	var tiempo_seg := float(Time.get_ticks_msec() - _tiempo_inicio_ms) / 1000.0
	var estrellas := 0
	
	if not por_tiempo_agotado:
		if tiempo_seg <= 180.0:
			estrellas = 3
			cambiar_pose(pose_feliz)
			await decir_mensaje("¡Increíble! ¡Tiempo récord! Has resuelto todas las temáticas en menos de 3 minutos. ¡Eres un maestro!", 4.0)
		elif tiempo_seg <= 300.0:
			estrellas = 2
			cambiar_pose(pose_feliz)
			await decir_mensaje("¡Excelente trabajo! Completaste el nivel en un tiempo medio muy bueno. ¡Sigue así!", 3.5)
		else:
			estrellas = 1
			cambiar_pose(pose_normal)
			await decir_mensaje("¡Bien hecho! Lograste resolver el nivel antes de que se acabara el tiempo límite. ¡Prueba superada!", 3.5)
	else:
		var ratio_completado : float = float(parejas_correctas_totales) / float(maxi(1, total_parejas_nivel))
		if ratio_completado >= 0.75:
			estrellas = 2
			cambiar_pose(pose_pensativo)
			await decir_mensaje("¡El tiempo se agotó! Pero lograste completar una gran cantidad de relaciones correctas. ¡Buen esfuerzo!", 4.0)
		elif ratio_completado >= 0.40:
			estrellas = 1
			cambiar_pose(pose_preocupado)
			await decir_mensaje("¡Tiempo fuera! Lograste emparejar de manera decente algunas columnas, pero nos faltó velocidad.", 4.0)
		else:
			estrellas = 0
			cambiar_pose(pose_preocupado)
			await decir_mensaje("¡Se acabó el tiempo! No lograste completar suficientes relaciones. ¡Debemos repasar y volver a intentarlo!", 4.0)

	var puntos := estrellas * RECOMPENSA_BASE_PUNTOS + maxi(0, 50 - _errores * 4)
	var monedas := estrellas * MONEDAS_POR_ESTRELLA
	
	if estrellas > 0:
		_guardar_progreso_db(puntos, estrellas)

	_mostrar_pantalla_resultados(estrellas, puntos, monedas, tiempo_seg)

func _mostrar_pantalla_resultados(estrellas: int, puntos: int, monedas: int, tiempo_seg: float) -> void:
	if panel_resultados == null: return
	
	if res_label_nivel: res_label_nivel.text = "NIVEL " + str(numero_de_nivel)
	if res_label_puntos: res_label_puntos.text = str(puntos) + " PTS"
	if res_label_dinero: res_label_dinero.text = "+$" + str(monedas)
	
	var minutos := int(tiempo_seg) / 60
	var segundos := int(tiempo_seg) % 60
	if res_label_tiempo: res_label_tiempo.text = "%02d:%02d" % [minutos, segundos]
	
	if res_estrella1: res_estrella1.texture = img_estrella_llena if estrellas >= 1 else img_estrella_vacia
	if res_estrella2: res_estrella2.texture = img_estrella_llena if estrellas >= 2 else img_estrella_vacia
	if res_estrella3: res_estrella3.texture = img_estrella_llena if estrellas == 3 else img_estrella_vacia
	
	panel_resultados.show()

# --- 🌟 LOGICA DE LOS 4 BOTONES DE LA PANTALLA DE RESULTADOS 🌟 ---

func _on_btn_repetir_nivel_pressed() -> void:
	_cerrar_db_seguro()
	get_tree().reload_current_scene()

func _on_btn_menu_minijuegos_pressed() -> void:
	_cerrar_db_seguro()
	Configuracion.change_scene_to_file(RUTA_ESCENA_SELECCION)

func _on_btn_selector_columnas_pressed() -> void:
	_cerrar_db_seguro()
	Configuracion.change_scene_to_file("res://selectorelacioncolumn.tscn")

func _on_btn_siguiente_nivel_pressed() -> void:
	_cerrar_db_seguro()
	# Incrementamos el nivel seleccionado globalmente antes de recargar
	GlobalUsuario.nivel_seleccionado = int(GlobalUsuario.nivel_seleccionado) + 1
	get_tree().reload_current_scene()

func _cerrar_db_seguro() -> void:
	if db:
		SQLiteHelper.close_db_connection(db)
		db = null

# --- BASE DE DATOS Y PAUSAS ---

func _guardar_progreso_db(pts: int, estrellas: int) -> void:
	if estrellas == 0 or db == null: return
	var id_user = GlobalUsuario.usuario_actual_id
	var usr_name = SQLiteHelper.escape(GlobalUsuario.nombre_alumno)
	var time_str = Time.get_datetime_string_from_system().replace("T", " ")
	
	var completado_col := 1 if estrellas == 3 else 0
	db.query("INSERT INTO columnas_intentos (NU_USU, NM_ALUMNO, NU_NIVEL, NU_PUNTOS, NU_ESTRELLAS, SW_COM, FE_INTENTO) VALUES (%d, '%s', %d, %d, %d, %d, '%s');" % [id_user, usr_name, numero_de_nivel, pts, estrellas, completado_col, time_str])
	
	db.query("SELECT NU_ESTRELLAS FROM columnas_niveles WHERE NU_USU = %d AND NU_NIVEL = %d;" % [id_user, numero_de_nivel])
	if db.query_result.is_empty():
		db.query("INSERT INTO columnas_niveles (NU_NIVEL, NU_USU, NM_ALUMNO, NU_PUNTOS, NU_ESTRELLAS, SW_COM) VALUES (%d, %d, '%s', %d, %d, %d);" % [numero_de_nivel, id_user, usr_name, pts, estrellas, completado_col])
	else:
		var previas := int(db.query_result[0].get("NU_ESTRELLAS", 0))
		if estrellas > previas:
			db.query("UPDATE columnas_niveles SET NU_PUNTOS = %d, NU_ESTRELLAS = %d, SW_COM = %d WHERE NU_NIVEL = %d AND NU_USU = %d;" % [pts, estrellas, completado_col, numero_de_nivel, id_user])
			
	var prox := numero_de_nivel + 1
	db.query("UPDATE Alumnos SET NU_NIVEL_MAX_COLUMNAS = %d WHERE NU_USU = %d AND NU_NIVEL_MAX_COLUMNAS < %d;" % [prox, id_user, prox])
	SQLiteHelper.mirror_minijuegos_resultados(db, id_user, GlobalUsuario.nombre_alumno, "columnas", pts, estrellas)
	
	db.query("SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d;" % id_user)
	var dinero_total := 0
	if not db.query_result.is_empty(): dinero_total = int(db.query_result[0].get("NU_DINERO", 0))
	Logros.evaluar_post_nivel(estrellas, pts, dinero_total)

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

func _on_continuar_pressed(): 
	gestionar_pausa()

func _on_salir_pressed():
	if menu_pausa: menu_pausa.hide()
	if capa_confirmacion: capa_confirmacion.show()
func _on_confirmar_no_quedarme_pressed():
	if capa_confirmacion: capa_confirmacion.hide()
	if menu_pausa: menu_pausa.show()
func _on_boton_si_confirmar_salir_pressed():
	get_tree().paused = false
	_cerrar_db_seguro()
	Configuracion.change_scene_to_file("res://selectorelacioncolumn.tscn")

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
