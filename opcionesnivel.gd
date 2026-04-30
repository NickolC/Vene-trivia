extends "res://Scripts/opciones_base.gd"

func _get_return_scene_path() -> String:
	return "res://Nivel 1.tscn"

@onready var slider_brillo = $"TextureRect3/Guardar/Volumen Maestro/Brillo"
@onready var slider_gamma = $"TextureRect3/Guardar/Volumen Maestro/Brillo/Gamma"
@onready var check_full = $"TextureRect3/Pantalla Completa"
@onready var option_res = $TextureRect3/Resolucion

@onready var volumen_maestro = $"TextureRect3/Guardar/Volumen Maestro"
@onready var musica = $"TextureRect3/Guardar/Volumen Maestro/Musica"
@onready var efectos = $"TextureRect3/Guardar/Volumen Maestro/Musica/Efectos"

# Creamos un diccionario para asociar el índice del botón con una resolución real
const RESOLUTIONS: Dictionary = {
	0: Vector2i(1920, 1080),
	1: Vector2i(1280, 720),
	2: Vector2i(640, 480)
}

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
	
	# Al abrir el menú, cargamos lo que ya estaba guardado
	Configuracion.cargar_ajustes()
	actualizar_ui_con_valores()
	# Opcional: Seleccionar por defecto la resolución actual al abrir el menú
	_on_resolucion_item_selected(0)
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
	var env = get_tree().root.find_child("WorldEnvironment", true, false)
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
	Configuracion.saturacion = slider_gamma.value
	Configuracion.contraste = slider_gamma.value
	Configuracion.fullscreen = check_full.button_pressed
	Configuracion.res_index = option_res.selected
	
	Configuracion.guardar_ajustes()
	Alertas.mostrar_alerta("Ajustes guardados con éxito.", 1.0)
	print("Ajustes guardados con éxito.")
	pass # Replace with function body.

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
	Alertas.mostrar_alerta("Ajustes restablecidos con éxito.", 1.0)
	print("Ajustes guardados con éxito.")
	pass # Replace with function body.


func _on_cancelar_pressed() -> void:
	$TextureRect3.visible = false
	$TextureRect4.visible = true
	
	pass # Replace with function body.


func _on_opciones_pressed() -> void:
	$TextureRect3.visible = true
	$TextureRect4.visible = false
	pass # Replace with function body.


func _on_volvermenu_pressed() -> void:
	# 1. Llamamos a la función que guarda los datos en el archivo .cfg o .json
	# Esta es la misma función que usa tu botón "Guardar"
	guardar_todo()
	
	# 2. (Opcional) Puedes mostrar un mensaje rápido o esperar un frame
	Alertas.mostrar_alerta("Ajustes guardados automáticamente.", 1.0)
	print("Ajustes guardados automáticamente.")
	
	
	
	# Esta es la función que ya deberías tener para tu botón de "Guardar"
func guardar_todo():
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
	
	# 3. Cambiamos de escena
	Configuracion.change_scene_to_file("res://Nivel 1.tscn")

	pass # Replace with function body.


func _on_salir_pressed() -> void:
	Configuracion.change_scene_to_file("res://Mapa.tscn")
