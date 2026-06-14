extends "res://Scripts/opciones_base.gd"

var db : SQLite
var nivel_actual: int 

@onready var volumen_maestro = $"TextureRect3/Volumen Maestro2"
@onready var musica = $"TextureRect3/Musica2"
@onready var efectos = $"TextureRect3/Efectos"


func _ready():
	Configuracion.cargar_ajustes()
	actualizar_ui_con_valores()

	if volumen_maestro and not volumen_maestro.value_changed.is_connected(_on_volumen_maestro_value_changed):
		volumen_maestro.value_changed.connect(_on_volumen_maestro_value_changed)
	if musica and not musica.value_changed.is_connected(_on_musica_value_changed):
		musica.value_changed.connect(_on_musica_value_changed)
	if efectos and not efectos.value_changed.is_connected(_on_efectos_value_changed):
		efectos.value_changed.connect(_on_efectos_value_changed)

	if "res_index" in Configuracion and Configuracion.res_index >= 0:
		option_res.selected = Configuracion.res_index
		_on_resolucion_item_selected(Configuracion.res_index)
	else:
		var resolucion_pantalla: Vector2i = DisplayServer.screen_get_size()
		var indice_ideal: int = 0
		for index in Configuracion.RESOLUTIONS:
			var res_posible: Vector2i = Configuracion.RESOLUTIONS[index]
			if res_posible.x <= resolucion_pantalla.x and res_posible.y <= resolucion_pantalla.y:
				indice_ideal = index
				break
		option_res.selected = indice_ideal
		Configuracion.res_index = indice_ideal
		_on_resolucion_item_selected(indice_ideal)

	var es_full = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	$"TextureRect3/Pantalla Completa".button_pressed = es_full


func actualizar_ui_con_valores():
	slider_brillo.value = Configuracion.brillo
	slider_gamma.value = Configuracion.saturacion
	check_full.button_pressed = Configuracion.fullscreen
	option_res.selected = Configuracion.res_index
	if volumen_maestro:
		volumen_maestro.value = Configuracion.volumen_maestro * 100.0
	if musica:
		musica.value = Configuracion.volumen_musica * 100.0
	if efectos:
		efectos.value = Configuracion.volumen_sfx * 100.0
	# OPC-01: al abrir NO forzamos modo de ventana; solo sincronizamos visibilidad.
	_sync_visibilidad_resolucion()

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
	var target_resolution = Configuracion.RESOLUTIONS[index]
	
	# Cambiamos el tamaño de la ventana (Solo Godot 4+)
	DisplayServer.window_set_size(target_resolution)
	
	# Centramos la ventana después del cambio
	var screen_center = DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2)
	var window_size = DisplayServer.window_get_size()
	DisplayServer.window_set_position(screen_center - (window_size / 2))
	
	pass # Replace with function body.


func _on_pantalla_completa_toggled(toggled_on: bool) -> void:
	Configuracion.fullscreen = toggled_on
	if toggled_on:
		# Activar Pantalla Completa
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# Volver a Modo Ventana
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	# OPC-01: ocultar/mostrar resolución segun el check
	_sync_visibilidad_resolucion()

func _on_brillo_value_changed(value: float) -> void:
	# BUG-05: el env ahora es global (autoload), aplicamos directo y en tiempo real.
	Configuracion.brillo = value
	Configuracion.aplicar_ajustes()

func _on_gamma_value_changed(value: float) -> void:
	Configuracion.saturacion = value
	Configuracion.contraste = value
	Configuracion.aplicar_ajustes()

func _on_volumen_maestro_value_changed(value: float) -> void:
	Configuracion.volumen_maestro = value / 100.0
	Configuracion.aplicar_volumenes()

func _on_musica_value_changed(value: float) -> void:
	Configuracion.volumen_musica = value / 100.0
	Configuracion.aplicar_volumenes()

func _on_efectos_value_changed(value: float) -> void:
	Configuracion.volumen_sfx = value / 100.0
	Configuracion.aplicar_volumenes()

# --- BOTÓN GUARDAR ---
func _on_guardar_pressed() -> void:
	# Antes de guardar, capturamos los valores actuales de la UI
	guardar_todo()
	Alertas.mostrar_alerta("Ajustes guardados con éxito.", 1.0)
	print("Ajustes guardados con éxito.")
	
	#Configuracion.brillo = slider_brillo.value
	#Configuracion.brillo = slider_gamma.value
	#Configuracion.saturacion = slider_gamma.value
	#Configuracion.contraste = slider_gamma.value
	#Configuracion.fullscreen = check_full.button_pressed
	#Configuracion.res_index = option_res.selected
	#Configuracion.guardar_ajustes()
	#Alertas.mostrar_alerta("Ajustes guardados con éxito.", 1.0)
	#print("Ajustes guardados con éxito.")
	#pass # Replace with function body.

# --- BOTÓN RESTABLECER ---
func _on_restablecer_pressed() -> void:
	# Volvemos a las constantes por defecto
	Configuracion.brillo = Configuracion.DEFAULT_BRILLO
	Configuracion.saturacion = Configuracion.DEFAULT_SATURATION
	Configuracion.contraste = Configuracion.DEFAULT_CONTRAST
	Configuracion.fullscreen = Configuracion.DEFAULT_FULLSCREEN
	Configuracion.res_index = Configuracion.DEFAULT_RES_INDEX
	# OPC-02: restablecer tambien el audio
	Configuracion.volumen_maestro = Configuracion.DEFAULT_VOL_MAESTRO
	Configuracion.volumen_musica = Configuracion.DEFAULT_VOL_MUSICA
	Configuracion.volumen_sfx = Configuracion.DEFAULT_VOL_SFX
	Configuracion.aplicar_volumenes()

	# Actualizamos la visualización de los sliders/botones
	actualizar_ui_con_valores()
	Alertas.mostrar_alerta("Ajustes restablecidas con éxito.", 1.0)
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
	aplicar_todo()
	Alertas.mostrar_alerta("Ajustes guardados automáticamente.", 1.0)
	print("Ajustes guardados automáticamente.")
	Configuracion.change_scene_to_file("res://Scenes/menu-alumno.tscn")
	
	
	# Esta es la función que ya deberías tener para tu botón de "Guardar"
func guardar_ajustes():
	Configuracion.brillo          = slider_brillo.value
	Configuracion.saturacion      = slider_gamma.value
	Configuracion.contraste       = slider_gamma.value
	Configuracion.fullscreen      = check_full.button_pressed
	Configuracion.res_index       = option_res.selected
	if volumen_maestro:
		Configuracion.volumen_maestro = volumen_maestro.value / 100.0
	if musica:
		Configuracion.volumen_musica  = musica.value / 100.0
	if efectos:
		Configuracion.volumen_sfx     = efectos.value / 100.0
	Configuracion.aplicar_volumenes()
	Configuracion.guardar_ajustes()

func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Login.tscn")

func _get_return_scene_path() -> String:
	return "res://Scenes/menu-alumno.tscn"


func _get_exit_scene_path() -> String:
	return "res://Scenes/Login.tscn"
