extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

const RUTAS_JSON: Dictionary = {
	"verdadero_falso": "res://Data/minijuegos/verdadero_falso.json",
	"completar_frases": "res://Data/minijuegos/completar_frases.json",
	"ahorcado": "res://Data/minijuegos/ahorcado.json"
}

const RUTA_MINIJUEGOS := "res://Scenes/Minijuegos.tscn"

const ALFABETO := "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ"

var db: SQLite
var modo: String = "verdadero_falso"
var nivel: int = 1
var ronda: Array = []
var indice: int = 0
var aciertos: int = 0
var puntaje: int = 0

var palabra_actual: String = ""
var pista_actual: String = ""
var letras_usadas: Dictionary = {}
var fallos_restantes: int = 6

var titulo_label: Label
var estado_label: Label
var pregunta_label: Label
var pista_label: Label
var mascara_label: Label
var feedback_label: Label
var opciones_box: VBoxContainer
var teclado_grid: GridContainer
var boton_siguiente: Button
var boton_selector: Button
var boton_menu: Button
var boton_reintentar: Button

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	modo = str(GlobalUsuario.minijuego_actual)
	if modo.is_empty() or not RUTAS_JSON.has(modo):
		modo = "verdadero_falso"
	nivel = maxi(1, int(GlobalUsuario.nivel_seleccionado))

	_crear_ui_base()
	if not _cargar_ronda_desde_json():
		feedback_label.text = "No se pudo cargar contenido para este nivel."
		boton_selector.visible = true
		return

	_mostrar_item_actual()

func _exit_tree() -> void:
	if db:
		SQLiteHelper.close_db_connection(db)
		db = null

func _crear_ui_base() -> void:
	var fondo := ColorRect.new()
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fondo.color = Color(0.07, 0.09, 0.14, 1.0)
	add_child(fondo)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 14)
	margin.add_child(root_box)

	titulo_label = Label.new()
	titulo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo_label.add_theme_font_size_override("font_size", 36)
	titulo_label.text = _nombre_modo() + " - Nivel %d" % nivel
	root_box.add_child(titulo_label)

	estado_label = Label.new()
	estado_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	estado_label.text = ""
	root_box.add_child(estado_label)

	pregunta_label = Label.new()
	pregunta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pregunta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pregunta_label.add_theme_font_size_override("font_size", 28)
	root_box.add_child(pregunta_label)

	pista_label = Label.new()
	pista_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pista_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_box.add_child(pista_label)

	mascara_label = Label.new()
	mascara_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mascara_label.add_theme_font_size_override("font_size", 34)
	root_box.add_child(mascara_label)

	opciones_box = VBoxContainer.new()
	opciones_box.add_theme_constant_override("separation", 8)
	root_box.add_child(opciones_box)

	teclado_grid = GridContainer.new()
	teclado_grid.columns = 7
	teclado_grid.add_theme_constant_override("h_separation", 6)
	teclado_grid.add_theme_constant_override("v_separation", 6)
	root_box.add_child(teclado_grid)

	feedback_label = Label.new()
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root_box.add_child(feedback_label)

	var acciones := HBoxContainer.new()
	acciones.alignment = BoxContainer.ALIGNMENT_CENTER
	acciones.add_theme_constant_override("separation", 10)
	root_box.add_child(acciones)

	boton_siguiente = Button.new()
	boton_siguiente.text = "Siguiente"
	boton_siguiente.visible = false
	boton_siguiente.pressed.connect(_on_boton_siguiente_pressed)
	acciones.add_child(boton_siguiente)

	boton_reintentar = Button.new()
	boton_reintentar.text = "Reintentar"
	boton_reintentar.visible = false
	boton_reintentar.pressed.connect(_on_reintentar_pressed)
	acciones.add_child(boton_reintentar)

	boton_selector = Button.new()
	boton_selector.text = "Volver a minijuegos"
	boton_selector.visible = false
	boton_selector.pressed.connect(_on_selector_pressed)
	acciones.add_child(boton_selector)

	boton_menu = Button.new()
	boton_menu.text = "Menu minijuegos"
	boton_menu.visible = false
	boton_menu.pressed.connect(_on_menu_pressed)
	acciones.add_child(boton_menu)

func _cargar_ronda_desde_json() -> bool:
	var ruta := str(RUTAS_JSON.get(modo, ""))
	if ruta.is_empty() or not FileAccess.file_exists(ruta):
		return false

	var file := FileAccess.open(ruta, FileAccess.READ)
	if file == null:
		return false
	var json_text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	var key := str(nivel)
	if not parsed.has(key):
		return false

	var nivel_data: Array = parsed[key]
	if nivel_data.is_empty():
		return false

	ronda = nivel_data.duplicate(true)
	ronda.shuffle()
	if ronda.size() > 5:
		ronda = ronda.slice(0, 5)
	return true

func _mostrar_item_actual() -> void:
	if indice >= ronda.size():
		_finalizar_juego()
		return

	estado_label.text = "Pregunta %d/%d  |  Puntaje: %d" % [indice + 1, ronda.size(), puntaje]
	feedback_label.text = ""
	boton_siguiente.visible = false
	_limpiar_opciones()

	if modo == "ahorcado":
		_mostrar_item_ahorcado(ronda[indice])
	else:
		_mostrar_item_trivia(ronda[indice])

func _mostrar_item_trivia(item: Dictionary) -> void:
	mascara_label.visible = false
	teclado_grid.visible = false
	pista_label.visible = true
	opciones_box.visible = true

	if modo == "verdadero_falso":
		pregunta_label.text = str(item.get("texto", ""))
		pista_label.text = "Selecciona Verdadero o Falso"
		_crear_opcion("Verdadero", true)
		_crear_opcion("Falso", false)
		return

	pregunta_label.text = str(item.get("frase", ""))
	pista_label.text = "Completa la frase seleccionando una opcion"
	var opciones: Array = item.get("opciones", [])
	for i in range(opciones.size()):
		_crear_opcion(str(opciones[i]), i)

func _crear_opcion(texto: String, valor) -> void:
	var boton := Button.new()
	boton.text = texto
	boton.custom_minimum_size = Vector2(0, 46)
	boton.pressed.connect(Callable(self, "_on_opcion_pressed").bind(valor))
	opciones_box.add_child(boton)

func _on_opcion_pressed(valor) -> void:
	for node in opciones_box.get_children():
		var boton_opcion := node as Button
		if boton_opcion:
			boton_opcion.disabled = true

	var item: Dictionary = ronda[indice]
	var es_correcta := false
	if modo == "verdadero_falso":
		es_correcta = bool(valor) == bool(item.get("respuesta", false))
	else:
		es_correcta = int(valor) == int(item.get("correcta", -1))

	if es_correcta:
		aciertos += 1
		puntaje += 200
		feedback_label.text = "Correcto. " + str(item.get("explicacion", ""))
	else:
		feedback_label.text = "Incorrecto. " + str(item.get("explicacion", ""))

	boton_siguiente.visible = true

func _mostrar_item_ahorcado(item: Dictionary) -> void:
	opciones_box.visible = false
	teclado_grid.visible = true
	mascara_label.visible = true
	pista_label.visible = true

	palabra_actual = str(item.get("palabra", "")).to_upper().strip_edges()
	pista_actual = str(item.get("pista", ""))
	letras_usadas.clear()
	fallos_restantes = 6

	pregunta_label.text = "Ahorcado"
	pista_label.text = "Pista: %s | Intentos restantes: %d" % [pista_actual, fallos_restantes]
	_actualizar_mascara_palabra()
	_construir_teclado()

func _construir_teclado() -> void:
	for child in teclado_grid.get_children():
		child.queue_free()
	for letra in ALFABETO:
		var boton := Button.new()
		boton.text = letra
		boton.custom_minimum_size = Vector2(52, 38)
		boton.pressed.connect(Callable(self, "_on_letra_presionada").bind(letra, boton))
		teclado_grid.add_child(boton)

func _on_letra_presionada(letra: String, boton: Button) -> void:
	if boton.disabled:
		return
	boton.disabled = true
	letras_usadas[letra] = true

	if palabra_actual.find(letra) != -1:
		_actualizar_mascara_palabra()
		if _palabra_completada():
			aciertos += 1
			puntaje += 250
			feedback_label.text = "Excelente. Resolviste la palabra."
			teclado_grid.visible = false
			boton_siguiente.visible = true
	else:
		fallos_restantes -= 1
		pista_label.text = "Pista: %s | Intentos restantes: %d" % [pista_actual, fallos_restantes]
		if fallos_restantes <= 0:
			feedback_label.text = "Sin intentos. La palabra era: %s" % palabra_actual
			teclado_grid.visible = false
			boton_siguiente.visible = true

func _actualizar_mascara_palabra() -> void:
	var partes: Array[String] = []
	for c in palabra_actual:
		if c == " ":
			partes.append("  ")
		elif letras_usadas.has(c):
			partes.append(c)
		else:
			partes.append("_")
	mascara_label.text = " ".join(partes)

func _palabra_completada() -> bool:
	for c in palabra_actual:
		if c == " ":
			continue
		if not letras_usadas.has(c):
			return false
	return true

func _on_boton_siguiente_pressed() -> void:
	indice += 1
	_mostrar_item_actual()

func _finalizar_juego() -> void:
	var total := maxi(1, ronda.size())
	var ratio := float(aciertos) / float(total)
	var estrellas := 0
	if ratio >= 0.8:
		estrellas = 3
	elif ratio >= 0.5:
		estrellas = 2
	elif ratio > 0.0:
		estrellas = 1

	pregunta_label.text = "Resultado final"
	pista_label.text = "Aciertos: %d/%d" % [aciertos, total]
	mascara_label.visible = false
	opciones_box.visible = false
	teclado_grid.visible = false
	feedback_label.text = "Puntaje: %d | Estrellas: %d" % [puntaje, estrellas]

	_guardar_resultado(puntaje, estrellas)

	boton_siguiente.visible = false
	boton_reintentar.visible = true
	boton_selector.visible = true
	boton_menu.visible = true

func _guardar_resultado(puntos: int, estrellas: int) -> void:
	if db == null:
		return
	if GlobalUsuario.usuario_actual_id <= 0:
		return
	SQLiteHelper.mirror_minijuegos_resultados(
		db,
		GlobalUsuario.usuario_actual_id,
		GlobalUsuario.nombre_alumno,
		modo,
		puntos,
		estrellas
	)

func _on_selector_pressed() -> void:
	Configuracion.change_scene_to_file(RUTA_MINIJUEGOS)

func _on_menu_pressed() -> void:
	Configuracion.change_scene_to_file(RUTA_MINIJUEGOS)

func _on_reintentar_pressed() -> void:
	Configuracion.change_scene_to_file("res://Scenes/minijuego_textual.tscn")

func _limpiar_opciones() -> void:
	for child in opciones_box.get_children():
		child.queue_free()

func _nombre_modo() -> String:
	match modo:
		"verdadero_falso":
			return "Verdadero o Falso"
		"completar_frases":
			return "Completar Frases"
		"ahorcado":
			return "Ahorcado"
		_:
			return "Minijuego"
