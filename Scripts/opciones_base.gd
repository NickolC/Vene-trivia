extends Control

const RESOLUTIONS: Dictionary = {
	0: Vector2i(1920, 1080),
	1: Vector2i(1280, 720),
	2: Vector2i(640, 480)
}

@onready var slider_brillo: HSlider = $"TextureRect3/Guardar/Volumen Maestro/Brillo"
@onready var slider_gamma: HSlider = $"TextureRect3/Guardar/Volumen Maestro/Brillo/Gamma"
@onready var check_full: CheckButton = $"TextureRect3/Pantalla Completa"
@onready var option_res: OptionButton = $TextureRect3/Resolucion

func _ready() -> void:
	Configuracion.cargar_ajustes()
	actualizar_ui_con_valores()

func actualizar_ui_con_valores() -> void:
	slider_brillo.value = Configuracion.brillo
	slider_gamma.value = Configuracion.saturacion
	check_full.button_pressed = Configuracion.fullscreen
	var safe_index := clampi(Configuracion.res_index, 0, RESOLUTIONS.size() - 1)
	option_res.select(safe_index)
	Configuracion.res_index = safe_index
	aplicar_todo()

func aplicar_todo() -> void:
	if Configuracion.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	_on_resolucion_item_selected(Configuracion.res_index)
	Configuracion.aplicar_ajustes_actuales()

func _on_resolucion_item_selected(index: int) -> void:
	if not RESOLUTIONS.has(index):
		return

	Configuracion.res_index = index
	var target_resolution: Vector2i = RESOLUTIONS[index]
	DisplayServer.window_set_size(target_resolution)

	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		var screen_center := DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2)
		var window_size := DisplayServer.window_get_size()
		DisplayServer.window_set_position(screen_center - (window_size / 2))

func _on_pantalla_completa_toggled(toggled_on: bool) -> void:
	Configuracion.fullscreen = toggled_on
	aplicar_todo()

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
