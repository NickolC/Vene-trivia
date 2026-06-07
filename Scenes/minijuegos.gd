extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")
const ICON_CANVAS_SIZE := 256
# Mapeamos cada ruta de botón con su icono, nombre visual y nombre exacto en la base de datos (db_nombre)
const MINIJUEGOS := {
	"VBoxContainer/HBoxContainer/Level 1": {
		"icono": "res://GFX/Minijuegos/Sopa.png",
		"nombre": "NIVELES DE SOPA",
		"db_nombre": "Sopa de Letras"
	},
	"VBoxContainer/HBoxContainer/Level 2": {
		"icono": "res://GFX/Minijuegos/Memoria.png",
		"nombre": "NIVELES DE MEMORIA",
		"db_nombre": "Memoria"
	},
	"VBoxContainer/HBoxContainer/Level 3": {
		"icono": "res://GFX/Minijuegos/Columnas.png",
		"nombre": "NIVELES DE COLUMNAS",
		"db_nombre": "RelacionColumnas"
	},
	"VBoxContainer/HBoxContainer3/Level 11": {
		"icono": "res://GFX/Minijuegos/TrueorFalse.png",
		"nombre": "NIVELES DE VERDADERO O FALSO",
		"db_nombre": "VerdaderoFalso"
	},
	"VBoxContainer/HBoxContainer3/Level 12": {
		"icono": "res://GFX/Minijuegos/Completar.png",
		"nombre": "NIVELES DE COMPLETAR FRASES",
		"db_nombre": "CompletarFrases"
	},
	"VBoxContainer/HBoxContainer3/Level 13": {
		"icono": "res://GFX/Minijuegos/Ahorcado.png",
		"nombre": "NIVELES DE AHORCADO",
		"db_nombre": "Ahorcado"
	},
}

var db: SQLite
var nivel_actual: int = GlobalUsuario.nivel_maximo

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	_cargar_usuario_actual()
	_configurar_iconos_minijuegos()
	_aplicar_bloqueos_minijuegos()

func _exit_tree() -> void:
	if db:
		SQLiteHelper.close_db_connection(db)
		db = null 

func _on_atras_pressed() -> void:
	Configuracion.change_scene_to_file("res://Scenes/menu-alumno.tscn")


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
	var alertas: Node = get_node_or_null("/root/Alertas")
	if alertas and alertas.has_method("mostrar_alerta"):
		alertas.mostrar_alerta(mensaje, 1.0)
	print(mensaje)


func _configurar_iconos_minijuegos() -> void:
	for ruta_boton in MINIJUEGOS.keys():
		var boton := get_node_or_null(ruta_boton) as Button
		if boton == null:
			continue

		var datos := MINIJUEGOS[ruta_boton] as Dictionary
		var textura := _crear_icono_normalizado(str(datos.get("icono", "")))
		if textura == null:
			continue

		_configurar_tarjeta_minijuego(boton, textura, str(datos.get("nombre", "")))


func _configurar_tarjeta_minijuego(boton: Button, textura: Texture2D, titulo: String) -> void:
	var fondo_vacio := StyleBoxEmpty.new()
	boton.flat = true
	boton.text = ""
	boton.icon = null
	boton.add_theme_stylebox_override("normal", fondo_vacio)
	boton.add_theme_stylebox_override("hover", fondo_vacio)
	boton.add_theme_stylebox_override("pressed", fondo_vacio)
	boton.add_theme_stylebox_override("focus", fondo_vacio)

	var icono := boton.get_node_or_null("Icono") as TextureRect
	if icono == null:
		icono = TextureRect.new()
		icono.name = "Icono"
		icono.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boton.add_child(icono)

	icono.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icono.offset_left = 0.0
	icono.offset_top = 0.0
	icono.offset_right = 0.0
	icono.offset_bottom = -52.0
	icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono.stretch_mode = TextureRect.STRETCH_SCALE
	icono.texture = textura

	var etiqueta := boton.get_node_or_null("Titulo") as Label
	if etiqueta == null:
		etiqueta = Label.new()
		etiqueta.name = "Titulo"
		etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boton.add_child(etiqueta)

	etiqueta.anchor_left = 0.0
	etiqueta.anchor_right = 1.0
	etiqueta.anchor_top = 1.0
	etiqueta.anchor_bottom = 1.0
	etiqueta.offset_left = 0.0
	etiqueta.offset_right = 0.0
	etiqueta.offset_top = -44.0
	etiqueta.offset_bottom = -8.0
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	etiqueta.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	etiqueta.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	etiqueta.add_theme_constant_override("outline_size", 4)
	etiqueta.add_theme_font_size_override("font_size", 24)
	etiqueta.text = titulo


func _crear_icono_normalizado(ruta_textura: String) -> Texture2D:
	if not FileAccess.file_exists(ruta_textura):
		push_warning("No se encontro icono: %s" % ruta_textura)
		return null

	var imagen := Image.new()
	var err := imagen.load(ruta_textura)
	if err != OK:
		push_warning("No se pudo cargar icono: %s" % ruta_textura)
		return null

	imagen.resize(ICON_CANVAS_SIZE, ICON_CANVAS_SIZE, Image.INTERPOLATE_NEAREST)

	return ImageTexture.create_from_image(imagen)


# --- GESTIONAR BLOQUEOS FÍSICOS Y VISUALES ---
func _aplicar_bloqueos_minijuegos() -> void:
	if db == null or GlobalUsuario.usuario_actual_id <= 0:
		return

	# 1. Recuperamos la configuración del alumno actual desde la tabla de bloqueos
	var bloqueos_activos := {}
	var query := "SELECT TX_MINIJUEGO, SW_BLOQUEADO FROM minijuegos_bloqueos WHERE NU_USU = %d;" % GlobalUsuario.usuario_actual_id

	if db.query(query) and not db.query_result.is_empty():
		for row in db.query_result:
			bloqueos_activos[str(row.get("TX_MINIJUEGO", ""))] = int(row.get("SW_BLOQUEADO", 0))

	# 2. Iteramos los botones definidos para aplicar las propiedades visuales y guardar metadatos
	for ruta_boton in MINIJUEGOS.keys():
		var boton := get_node_or_null(ruta_boton) as Button
		if boton == null:
			continue

		var datos := MINIJUEGOS[ruta_boton] as Dictionary
		var db_nombre: String = datos.get("db_nombre", "")

		# Si el minijuego está marcado como bloqueado (1) en la base de datos
		var esta_bloqueado: bool = bloqueos_activos.get(db_nombre, 0) == 1

		# 🌟 SOLUCIÓN CRÍTICA: No deshabilitamos físicamente el botón para que pueda recibir el clic y lanzar la alerta
		boton.disabled = false
		
		# Guardamos el estado de bloqueo dentro del propio botón de manera segura usando metadatos
		boton.set_meta("bloqueado", esta_bloqueado)

		# Aplicamos efectos visuales (oscurecer o brillar) al icono del botón
		var icono := boton.get_node_or_null("Icono") as TextureRect
		if icono:
			if esta_bloqueado:
				icono.modulate = Color(0.35, 0.35, 0.35, 0.8) # Grisáceo oscuro opaco si está bloqueado
			else:
				icono.modulate = Color.WHITE # Color original brillante si está libre
				
		# También aplicamos modulación de color grisáceo a la etiqueta del título para simular bloqueo
		var etiqueta := boton.get_node_or_null("Titulo") as Label
		if etiqueta:
			if esta_bloqueado:
				etiqueta.modulate = Color(0.5, 0.5, 0.5, 0.8) # Texto grisáceo si está bloqueado
			else:
				etiqueta.modulate = Color.WHITE # Texto blanco normal si está libre

# --- FUNCIONALIDAD PARA VALIDAR EN EJECUCIÓN (Botoneras y Clicks) ---
func comprobar_minijuego_bloqueado(nombre_minijuego: String) -> bool:
	var db_local = SQLiteHelper.open_db_connection()
	if db_local == null: 
		return false # Si falla la DB, por defecto permitimos entrar
	
	var usuario_id : int = GlobalUsuario.usuario_actual_id
	var esta_bloqueado : bool = false
	
	var query := "SELECT SW_BLOQUEADO FROM minijuegos_bloqueos WHERE NU_USU = %d AND TX_MINIJUEGO = '%s' LIMIT 1;" % [
		usuario_id, SQLiteHelper.escape(nombre_minijuego)
	]
	
	if db_local.query(query) and not db_local.query_result.is_empty():
		esta_bloqueado = int(db_local.query_result[0].get("SW_BLOQUEADO", 0)) == 1
		
	SQLiteHelper.close_db_connection(db_local)
	return esta_bloqueado

# --- EVENTOS DE PRESIONADO DE BOTONES ---

func _on_level_1_pressed() -> void:
	# 🌟 SOLUCIÓN: Consultamos el estado de bloqueo rápido guardado en el metadato del botón
	var boton := get_node("VBoxContainer/HBoxContainer/Level 1") as Button
	if boton and boton.get_meta("bloqueado", false):
		Alertas.mostrar_alerta("Este minijuego está bloqueado. Solo el docente puede desbloquearlo.", 3.0)
		return
		
	GlobalUsuario.nivel_seleccionado = _nivel_minijuego_por_defecto()
	Configuracion.change_scene_to_file("res://scenes/selectorsopaletras.tscn")

func _on_level_2_pressed() -> void:
	var boton := get_node("VBoxContainer/HBoxContainer/Level 2") as Button
	if boton and boton.get_meta("bloqueado", false):
		Alertas.mostrar_alerta("Este minijuego está bloqueado. Solo el docente puede desbloquearlo.", 3.0)
		return
		
	GlobalUsuario.nivel_seleccionado = _nivel_minijuego_por_defecto()
	Configuracion.change_scene_to_file("res://selectormemoria.tscn")

func _on_level_3_pressed() -> void:
	var boton := get_node("VBoxContainer/HBoxContainer/Level 3") as Button
	if boton and boton.get_meta("bloqueado", false):
		Alertas.mostrar_alerta("Este minijuego está bloqueado. Solo el docente puede desbloquearlo.", 3.0)
		return
		
	GlobalUsuario.nivel_seleccionado = _nivel_minijuego_por_defecto()
	Configuracion.change_scene_to_file("res://selectorelacioncolumn.tscn")

func _on_level_11_pressed() -> void:
	var boton := get_node("VBoxContainer/HBoxContainer3/Level 11") as Button
	if boton and boton.get_meta("bloqueado", false):
		Alertas.mostrar_alerta("Este minijuego está bloqueado. Solo el docente puede desbloquearlo.", 3.0)
		return
		
	GlobalUsuario.minijuego_actual = "verdadero_falso"
	GlobalUsuario.nivel_seleccionado = _nivel_minijuego_por_defecto()
	Configuracion.change_scene_to_file("res://Scenes/minijuego_textual.tscn")

func _on_level_12_pressed() -> void:
	var boton := get_node("VBoxContainer/HBoxContainer3/Level 12") as Button
	if boton and boton.get_meta("bloqueado", false):
		Alertas.mostrar_alerta("Este minijuego está bloqueado. Solo el docente puede desbloquearlo.", 3.0)
		return
		
	GlobalUsuario.minijuego_actual = "completar_frases"
	GlobalUsuario.nivel_seleccionado = _nivel_minijuego_por_defecto()
	Configuracion.change_scene_to_file("res://Scenes/minijuego_textual.tscn")

func _on_level_13_pressed() -> void:
	var boton := get_node("VBoxContainer/HBoxContainer3/Level 13") as Button
	if boton and boton.get_meta("bloqueado", false):
		Alertas.mostrar_alerta("Este minijuego está bloqueado. Solo el docente puede desbloquearlo.", 3.0)
		return
		
	GlobalUsuario.minijuego_actual = "ahorcado"
	GlobalUsuario.nivel_seleccionado = _nivel_minijuego_por_defecto()
	Configuracion.change_scene_to_file("res://Scenes/minijuego_textual.tscn")

func _nivel_minijuego_por_defecto() -> int:
	return clampi(GlobalUsuario.nivel_maximo, 1, 15)
