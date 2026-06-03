extends "res://Scripts/opciones_base.gd"

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite
var nivel_actual: int = GlobalUsuario.nivel_maximo

@onready var slider_vol_maestro = $"TextureRect3/Volumen Maestro2"
@onready var slider_musica = $TextureRect3/Musica2
@onready var slider_efectos = $TextureRect3/Efectos

func _ready():
	db = SQLiteHelper.open_db_connection()
	process_mode = Node.PROCESS_MODE_ALWAYS

	if slider_brillo and not slider_brillo.value_changed.is_connected(_on_brillo_value_changed):
		slider_brillo.value_changed.connect(_on_brillo_value_changed)
	if slider_gamma and not slider_gamma.value_changed.is_connected(_on_gamma_value_changed):
		slider_gamma.value_changed.connect(_on_gamma_value_changed)
	if slider_vol_maestro and not slider_vol_maestro.value_changed.is_connected(_on_vol_maestro_value_changed):
		slider_vol_maestro.value_changed.connect(_on_vol_maestro_value_changed)
	if slider_musica and not slider_musica.value_changed.is_connected(_on_musica_value_changed):
		slider_musica.value_changed.connect(_on_musica_value_changed)
	if slider_efectos and not slider_efectos.value_changed.is_connected(_on_efectos_value_changed):
		slider_efectos.value_changed.connect(_on_efectos_value_changed)

	Configuracion.cargar_ajustes()
	actualizar_ui_con_valores()

	if Configuracion.res_index >= 0:
		option_res.selected = Configuracion.res_index
		_on_resolucion_item_selected(Configuracion.res_index)
	else:
		var pantalla := DisplayServer.screen_get_size()
		var indice_ideal := 0
		for index in Configuracion.RESOLUTIONS:
			var res: Vector2i = Configuracion.RESOLUTIONS[index]
			if res.x <= pantalla.x and res.y <= pantalla.y:
				indice_ideal = index
				break
		option_res.selected = indice_ideal
		Configuracion.res_index = indice_ideal
		_on_resolucion_item_selected(indice_ideal)

	check_full.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

func actualizar_ui_con_valores():
	slider_brillo.value = Configuracion.brillo
	slider_gamma.value = Configuracion.saturacion
	check_full.button_pressed = Configuracion.fullscreen
	option_res.selected = Configuracion.res_index
	if slider_vol_maestro:
		slider_vol_maestro.value = Configuracion.volumen_maestro * 100.0
	if slider_musica:
		slider_musica.value = Configuracion.volumen_musica * 100.0
	if slider_efectos:
		slider_efectos.value = Configuracion.volumen_sfx * 100.0
	Configuracion.aplicar_ajustes_actuales()

func _on_resolucion_item_selected(index: int) -> void:
	if not Configuracion.RESOLUTIONS.has(index):
		return
	var target_resolution: Vector2i = Configuracion.RESOLUTIONS[index]
	DisplayServer.window_set_size(target_resolution)
	var screen_center := DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2)
	DisplayServer.window_set_position(screen_center - (DisplayServer.window_get_size() / 2))

func _on_pantalla_completa_toggled(toggled_on: bool) -> void:
	Configuracion.fullscreen = toggled_on
	if toggled_on:
		option_res.disabled = true
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		option_res.disabled = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if Configuracion.RESOLUTIONS.has(option_res.selected):
			var res: Vector2i = Configuracion.RESOLUTIONS[option_res.selected]
			DisplayServer.window_set_size(res)

func _on_brillo_value_changed(value: float) -> void:
	Configuracion.brillo = value
	Configuracion.aplicar_ajustes_actuales()

func _on_gamma_value_changed(value: float) -> void:
	Configuracion.saturacion = value
	Configuracion.contraste = value
	Configuracion.aplicar_ajustes_actuales()

func _on_vol_maestro_value_changed(value: float) -> void:
	Configuracion.volumen_maestro = value / 100.0
	Configuracion.aplicar_volumenes()

func _on_musica_value_changed(value: float) -> void:
	Configuracion.volumen_musica = value / 100.0
	Configuracion.aplicar_volumenes()

func _on_efectos_value_changed(value: float) -> void:
	Configuracion.volumen_sfx = value / 100.0
	Configuracion.aplicar_volumenes()

func _on_guardar_pressed() -> void:
	guardar_ajustes()
	cerrar_opciones()
	Alertas.mostrar_alerta("Ajustes guardados con éxito.", 1.0)

func _on_restablecer_pressed() -> void:
	Configuracion.brillo        = Configuracion.DEFAULT_BRILLO
	Configuracion.saturacion    = Configuracion.DEFAULT_SATURATION
	Configuracion.contraste     = Configuracion.DEFAULT_CONTRAST
	Configuracion.fullscreen    = Configuracion.DEFAULT_FULLSCREEN
	Configuracion.res_index     = Configuracion.DEFAULT_RES_INDEX
	Configuracion.volumen_maestro = Configuracion.DEFAULT_VOL_MAESTRO
	Configuracion.volumen_musica  = Configuracion.DEFAULT_VOL_MUSICA
	Configuracion.volumen_sfx     = Configuracion.DEFAULT_VOL_SFX
	actualizar_ui_con_valores()
	Alertas.mostrar_alerta("Ajustes restablecidos.", 1.0)

func guardar_ajustes():
	Configuracion.brillo          = slider_brillo.value
	Configuracion.saturacion      = slider_gamma.value
	Configuracion.contraste       = slider_gamma.value
	Configuracion.fullscreen      = check_full.button_pressed
	Configuracion.res_index       = option_res.selected
	if slider_vol_maestro:
		Configuracion.volumen_maestro = slider_vol_maestro.value / 100.0
	if slider_musica:
		Configuracion.volumen_musica  = slider_musica.value / 100.0
	if slider_efectos:
		Configuracion.volumen_sfx     = slider_efectos.value / 100.0
	Configuracion.guardar_ajustes()

func cerrar_opciones() -> void:
	var menu_pausa := get_parent()
	if menu_pausa:
		var centro := menu_pausa.get_node_or_null("CenterContainer")
		if centro:
			centro.visible = true
	queue_free()

func _on_cancelar_pressed() -> void:
	$TextureRect3.visible = false
	$TextureRect4.visible = true

func _on_opciones_pressed() -> void:
	$TextureRect3.visible = true
	$TextureRect4.visible = false

func _on_volvermenu_pressed() -> void:
	cerrar_opciones()

func _on_salir_pressed() -> void:
	Configuracion.change_scene_to_file("res://Mapa.tscn")

func _get_return_scene_path() -> String:
	return "res://Nivel 1.tscn"
