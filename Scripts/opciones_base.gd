extends Control

@onready var slider_brillo: HSlider = $"TextureRect3/Brillo"
@onready var slider_gamma: HSlider = $"TextureRect3/Gamma"
@onready var check_full: CheckButton = $"TextureRect3/Pantalla Completa"
@onready var option_res: OptionButton = $TextureRect3/Resolucion

func _ready() -> void:
	Configuracion.cargar_ajustes()
	actualizar_ui_con_valores()

func actualizar_ui_con_valores() -> void:
	slider_brillo.value = Configuracion.brillo
	slider_gamma.value = Configuracion.saturacion
	check_full.button_pressed = Configuracion.fullscreen

# Sincronizar el interruptor de pantalla completa
	if check_full and "fullscreen" in Configuracion:
		check_full.button_pressed = Configuracion.fullscreen

	# Sincronizar el desplegable de resolución
	if option_res and "res_index" in Configuracion:
		option_res.selected = Configuracion.res_index
		# Si estaba guardado como pantalla completa, congelamos el desplegable
		option_res.disabled = Configuracion.fullscreen
	# OPC-01: al ABRIR opciones NO forzamos modo de ventana (no auto-fullscreen);
	# solo sincronizamos la visibilidad de la resolución segun el check.
	_sync_visibilidad_resolucion()

# OPC-01: oculta el label "Resolución" y su OptionButton cuando el check de
# pantalla completa esta activo (en fullscreen la resolución no aplica).
func _sync_visibilidad_resolucion() -> void:
	var es_full: bool = check_full.button_pressed if check_full else false
	if option_res:
		option_res.visible = not es_full
		option_res.disabled = es_full
	var label_res := get_node_or_null("TextureRect3/Resolucion2")
	if label_res:
		label_res.visible = not es_full

func aplicar_todo() -> void:
	if Configuracion.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		# OPCIONAL: Desactivar visualmente el OptionButton porque en Fullscreen no aplica
		if option_res:
			option_res.disabled = true 
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if option_res:
			option_res.disabled = false
		
		# 2. SOLO si está en modo ventana, le exigimos a la pantalla cambiar su tamaño
		if Configuracion.RESOLUTIONS.has(Configuracion.res_index):
			var nueva_resolucion: Vector2i = Configuracion.RESOLUTIONS[Configuracion.res_index]
			DisplayServer.window_set_size(nueva_resolucion)
			
			# Centrar la ventana en el monitor para que no quede cortada abajo/derecha
			var screen_center = DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2) - (nueva_resolucion / 2)
			DisplayServer.window_set_position(screen_center)

func _on_resolucion_item_selected(index: int) -> void:
	if not Configuracion.RESOLUTIONS.has(index):
		return

	Configuracion.res_index = index
	var target_resolution: Vector2i = Configuracion.RESOLUTIONS[index]
	DisplayServer.window_set_size(target_resolution)

	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		var screen_center := DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2)
		var window_size := DisplayServer.window_get_size()
		DisplayServer.window_set_position(screen_center - (window_size / 2))

func _on_pantalla_completa_toggled(toggled_on: bool) -> void:
	Configuracion.fullscreen = toggled_on

	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

		# Forzar a recuperar la resolución de la lista al quitar la pantalla completa
		if Configuracion.RESOLUTIONS.has(option_res.selected):
			var res = Configuracion.RESOLUTIONS[option_res.selected]
			DisplayServer.window_set_size(res)
	# OPC-01: actualizar visibilidad del label/boton de resolución tras el toggle
	_sync_visibilidad_resolucion()

func _on_brillo_value_changed(value: float) -> void:
	Configuracion.brillo = value
	Configuracion.aplicar_ajustes_actuales()

func _on_gamma_value_changed(value: float) -> void:
	Configuracion.saturacion = value
	Configuracion.contraste = value
	Configuracion.aplicar_ajustes_actuales()

func _on_guardar_pressed() -> void:
	guardar_todo(false)
	_mostrar_alerta("Ajustes guardados con exito.", 1.0)

func _on_restablecer_pressed() -> void:
	Configuracion.brillo = Configuracion.DEFAULT_BRILLO
	Configuracion.saturacion = Configuracion.DEFAULT_SATURATION
	Configuracion.contraste = Configuracion.DEFAULT_CONTRAST
	Configuracion.fullscreen = Configuracion.DEFAULT_FULLSCREEN
	Configuracion.res_index = Configuracion.DEFAULT_RES_INDEX
	# OPC-02: restablecer tambien el audio, no solo lo visual
	Configuracion.volumen_maestro = Configuracion.DEFAULT_VOL_MAESTRO
	Configuracion.volumen_musica = Configuracion.DEFAULT_VOL_MUSICA
	Configuracion.volumen_sfx = Configuracion.DEFAULT_VOL_SFX
	Configuracion.aplicar_volumenes()
	actualizar_ui_con_valores()

func _on_cancelar_pressed() -> void:
	$TextureRect3.visible = false
	$TextureRect4.visible = true

func _on_opciones_pressed() -> void:
	$TextureRect3.visible = true
	$TextureRect4.visible = false

func _on_volvermenu_pressed() -> void:
	guardar_todo()
	_mostrar_alerta("Ajustes guardados automaticamente.", 1.0)

func guardar_todo(cambiar_escena := true) -> void:
	Configuracion.brillo = slider_brillo.value
	Configuracion.saturacion = slider_gamma.value
	Configuracion.contraste = slider_gamma.value
	Configuracion.fullscreen = check_full.button_pressed
	Configuracion.res_index = option_res.selected
	aplicar_todo()
	Configuracion.guardar_ajustes()

	if cambiar_escena:
		var scene_path := _get_return_scene_path()
		if not scene_path.is_empty():
			get_tree().change_scene_to_file(scene_path)

func _on_salir_pressed() -> void:
	var scene_path := _get_exit_scene_path()
	if not scene_path.is_empty():
		get_tree().change_scene_to_file(scene_path)

func _get_return_scene_path() -> String:
	return ""

func _get_exit_scene_path() -> String:
	return ""

func _mostrar_alerta(texto: String, tiempo: float) -> void:
	var alertas := get_node_or_null("/root/Alertas")
	if alertas and alertas.has_method("mostrar_alerta"):
		alertas.mostrar_alerta(texto, tiempo)
	print(texto)
