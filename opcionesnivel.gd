extends "res://Scripts/opciones_base.gd"

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite
var nivel_actual: int = GlobalUsuario.nivel_maximo
var costopor: int
var costopub: int
var costomid: int

@onready var volumen_maestro = $"TextureRect3/Volumen Maestro2"
@onready var musica = $TextureRect3/Musica2
@onready var efectos = $TextureRect3/Efectos

func _ready():
	# En el script de tu Nivel o Escena de Juego
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
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Conectamos manualmente el slider de Brillo
	var slider_brillo = get_node_or_null("TextureRect3/Brillo")
	if slider_brillo:
		if slider_brillo.value_changed.is_connected(_on_brillo_value_changed):
			slider_brillo.value_changed.disconnect(_on_brillo_value_changed)
		slider_brillo.value_changed.connect(_on_brillo_value_changed)
		
	# Conectamos manualmente el slider de Gamma (revisa la nueva ruta tras sacarlo de Brillo)
	var slider_gamma = get_node_or_null("TextureRect3/Gamma")
	if slider_gamma:
		if slider_gamma.value_changed.is_connected(_on_gamma_value_changed):
			slider_gamma.value_changed.disconnect(_on_gamma_value_changed)
		slider_gamma.value_changed.connect(_on_gamma_value_changed)
		
	# Al abrir el menú, cargamos lo que ya estaba guardado
	Configuracion.cargar_ajustes()
	actualizar_ui_con_valores()
	
# 1. Comprobamos si el jugador ya tiene un índice de resolución guardado válido
	# (Asumiendo que por defecto inicializas Configuracion.res_index en un valor negativo como -1 si es nuevo)
	if "res_index" in Configuracion and Configuracion.res_index >= 0:
		# Si ya hay una guardada, seleccionamos ese ítem en el OptionButton
		option_res.selected = Configuracion.res_index
		_on_resolucion_item_selected(Configuracion.res_index)
	else:
		# 2. Si es la primera vez (no hay guardada), detectamos la resolución máxima del monitor
		var resolucion_pantalla: Vector2i = DisplayServer.screen_get_size()
		var indice_ideal: int = 0 # Por si acaso, dejamos el 0 de respaldo
		
		# Recorremos tu diccionario RESOLUTIONS para buscar la que mejor se adapte sin pasarse
		for index in RESOLUTIONS:
			var res_posible: Vector2i = RESOLUTIONS[index]
			# Buscamos la primera resolución en tu lista que sea igual o menor a la del monitor
			if res_posible.x <= resolucion_pantalla.x and res_posible.y <= resolucion_pantalla.y:
				indice_ideal = index
				break # Rompemos el ciclo porque tu lista va de mayor a menor
		
		# 3. Aplicamos el índice ideal detectado automáticamente
		option_res.selected = indice_ideal
		Configuracion.res_index = indice_ideal # Lo guardamos en memoria
		_on_resolucion_item_selected(indice_ideal)
	# Revisa si ya estamos en pantalla completa y marca el botón
	var es_full = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	$"TextureRect3/Pantalla Completa".button_pressed = es_full

func actualizar_ui_con_valores():
	# Sincronizamos los nodos visuales con las variables del Singleton
	slider_brillo.value = Configuracion.brillo
	slider_gamma.value = Configuracion.saturacion
	check_full.button_pressed = Configuracion.fullscreen
	option_res.selected = Configuracion.res_index
	
	# Aplicamos los cambios al motor (opcional, si quieres que se vea al instante)
	aplicar_todo()

func aplicar_todo():
	# Lógica para aplicar pantalla completa, resolución, etc.
	if Configuracion.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Aplicar a WorldEnvironment (ajusta la ruta según tu escena)
	var env = get_tree().root.find_child("res://Scenes/menu-alumno.tscn/$Fondo/WorldGamma", true, false)
	if env:
		env.environment.adjustments_enabled = true
		env.environment.adjustment_brightness = Configuracion.brillo
		env.environment.adjustment_saturation = Configuracion.saturacion
		env.environment.adjustment_contrast = Configuracion.contraste

func _on_resolucion_item_selected(index: int) -> void:
	# Obtenemos la resolución del diccionario usando el índice seleccionado
	var target_resolution = RESOLUTIONS[index]
	
	# Cambiamos el tamaño de la ventana (Solo Godot 4+)
	DisplayServer.window_set_size(target_resolution)
	
	# Centramos la ventana después del cambio
	var screen_center = DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2)
	var window_size = DisplayServer.window_get_size()
	DisplayServer.window_set_position(screen_center - (window_size / 2))
	
	pass # Replace with function body.


func _on_pantalla_completa_toggled(toggled_on: bool) -> void:
	if toggled_on:
		# Activar Pantalla Completa
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# Volver a Modo Ventana
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	pass # Replace with function body.

func _on_brillo_value_changed(value: float) -> void:
	# Guardamos el valor globalmente
	Configuracion.brillo = value
	
	# Buscamos el WorldEnvironment que esté vivo en la escena actual
	var world_env = get_tree().root.find_child("WorldGamma", true, false)
	if world_env:
		Configuracion.aplicar_ajustes(world_env.environment)
	pass # Replace with function body.

func _on_gamma_value_changed(value: float) -> void:
	# Guardamos el valor globalmente
	Configuracion.saturacion = value
	# Buscamos el WorldEnvironment que esté vivo en la escena actual
	var world_env = get_tree().root.find_child("WorldGamma", true, false)
	if world_env:
		Configuracion.aplicar_ajustes(world_env.environment)
	pass # Replace with function body.

# --- BOTÓN GUARDAR ---
func _on_guardar_pressed() -> void:
	# Antes de guardar, capturamos los valores actuales de la UI
	Configuracion.brillo = slider_brillo.value
	Configuracion.brillo = slider_gamma.value
	Configuracion.saturacion = slider_gamma.value
	Configuracion.contraste = slider_gamma.value
	Configuracion.fullscreen = check_full.button_pressed
	Configuracion.res_index = option_res.selected
	Configuracion.guardar_ajustes()
	cerrar_opciones()
	Alertas.mostrar_alerta("Ajustes guardados con éxito.", 1.0)
	print("Ajustes guardados con éxito.")

# --- BOTÓN RESTABLECER ---
func _on_restablecer_pressed() -> void:
	# Volvemos a las constantes por defecto
	Configuracion.brillo = Configuracion.DEFAULT_BRILLO
	Configuracion.saturacion = Configuracion.DEFAULT_SATURATION
	Configuracion.contraste = Configuracion.DEFAULT_CONTRAST
	Configuracion.fullscreen = Configuracion.DEFAULT_FULLSCREEN
	Configuracion.res_index = Configuracion.DEFAULT_RES_INDEX
	
	# Actualizamos la visualización de los sliders/botones
	actualizar_ui_con_valores()
	Alertas.mostrar_alerta("Ajustes restablecidas con éxito.", 1.0)
	print("Ajustes guardados con éxito.")
	pass # Replace with function body.
	
func cerrar_opciones() -> void:
	# Buscamos al nodo padre (que es el CanvasLayer "Menupausa" del nivel)
	var menu_pausa = get_parent()
	if menu_pausa:
		# Volvemos a hacer visible el menú de pausa original
		menu_pausa.get_node("CenterContainer").visible = true
	
	# Eliminamos esta escena de opciones de la memoria
	queue_free()

func _on_cancelar_pressed() -> void:
	$TextureRect3.visible = false
	$TextureRect4.visible = true
	
	pass # Replace with function body.


func _on_opciones_pressed() -> void:
	$TextureRect3.visible = true
	$TextureRect4.visible = false
	pass # Replace with function body.


func _on_volvermenu_pressed() -> void:
	cerrar_opciones()

	
	# Esta es la función que ya deberías tener para tu botón de "Guardar"
func guardar_ajustes():
	# Actualizamos las variables del Singleton (Autoload) con los valores de la UI
	Configuracion.brillo = slider_brillo.value
	Configuracion.saturacion = slider_gamma.value
	Configuracion.contraste = slider_gamma.value
	Configuracion.volumen_maestro = volumen_maestro.value
	Configuracion.volumen_musica = musica.value
	Configuracion.volumen_sfx = efectos.value
	Configuracion.fullscreen = check_full.button_pressed
	Configuracion.res_index = option_res.selected
	
	# Llamamos al método del Singleton que escribe el archivo en el disco (user://)
	Configuracion.guardar_ajustes()

func _on_salir_pressed() -> void:
	Configuracion.change_scene_to_file("res://Mapa.tscn")

func _get_return_scene_path() -> String:
	return "res://Nivel 1.tscn"
