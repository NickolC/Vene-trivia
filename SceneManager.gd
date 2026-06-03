extends Node

const DEFAULT_BRILLO: float = 1.0
const DEFAULT_SATURATION: float = 1.0
const DEFAULT_CONTRAST: float = 1.0
const DEFAULT_FULLSCREEN: bool = false
const DEFAULT_RES_INDEX: int = 0
const DEFAULT_VOL_MAESTRO: float = 1.0
const DEFAULT_VOL_MUSICA: float = 1.0
const DEFAULT_VOL_SFX: float = 1.0

const RESOLUTIONS: Dictionary = {
	0: Vector2i(1920, 1080),
	1: Vector2i(1680, 1050),
	2: Vector2i(1600, 900),
	3: Vector2i(1440, 900),
	4: Vector2i(1400, 1050),
	5: Vector2i(1366, 768),
	6: Vector2i(1360, 768),
	7: Vector2i(1280, 1024),
	8: Vector2i(1280, 960),
	9: Vector2i(1280, 800),
	10: Vector2i(1280, 768),
	11: Vector2i(1280, 720),
	12: Vector2i(1280, 600),
	13: Vector2i(1152, 864),
	14: Vector2i(1024, 768),
	15: Vector2i(800, 600)
}

var brillo: float = DEFAULT_BRILLO
var saturacion: float = DEFAULT_SATURATION
var contraste: float = DEFAULT_CONTRAST
var fullscreen: bool = DEFAULT_FULLSCREEN
var res_index: int = DEFAULT_RES_INDEX
var volumen_maestro: float = DEFAULT_VOL_MAESTRO
var volumen_musica: float = DEFAULT_VOL_MUSICA
var volumen_sfx: float = DEFAULT_VOL_SFX

const SAVE_PATH = "user://configuracion_usuario.cfg"
# SceneManager.gd - Autoload para manejar cambios de escena con guardado automático

signal scene_changing(from_scene: String, to_scene: String)
signal scene_changed(to_scene: String)

var current_scene_path: String

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	current_scene_path = get_tree().current_scene.scene_file_path
	get_tree().tree_changed.connect(_on_tree_changed)
	cargar_ajustes()
	aplicar_volumenes()

func change_scene_to_file(scene_path: String) -> void:
	# Guardar configuraciones antes de cambiar escena
	guardar_ajustes()
	# Emitir señal antes de cambiar
	scene_changing.emit(current_scene_path, scene_path)

	# Cambiar escena
	var result = get_tree().change_scene_to_file(scene_path)
	if result == OK:
		current_scene_path = scene_path
		scene_changed.emit(scene_path)
	else:
		push_error("Failed to change scene to: " + scene_path)

func _on_tree_changed() -> void:
	# Guardar cuando la escena cambie (por cualquier método)
	guardar_ajustes()

func guardar_ajustes() -> void:
	var config := ConfigFile.new()
	config.set_value("Ajustes", "brillo", brillo)
	config.set_value("Ajustes", "saturacion", saturacion)
	config.set_value("Ajustes", "contraste", contraste)
	config.set_value("Ajustes", "fullscreen", fullscreen)
	config.set_value("Ajustes", "res_index", res_index)
	config.set_value("Ajustes", "volumen_maestro", volumen_maestro)
	config.set_value("Ajustes", "volumen_musica", volumen_musica)
	config.set_value("Ajustes", "volumen_sfx", volumen_sfx)
	config.save(SAVE_PATH)
		
func cargar_ajustes() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		brillo = config.get_value("Ajustes", "brillo", DEFAULT_BRILLO)
		saturacion = config.get_value("Ajustes", "saturacion", DEFAULT_SATURATION)
		contraste = config.get_value("Ajustes", "contraste", DEFAULT_CONTRAST)
		fullscreen = config.get_value("Ajustes", "fullscreen", DEFAULT_FULLSCREEN)
		res_index = config.get_value("Ajustes", "res_index", DEFAULT_RES_INDEX)
		volumen_maestro = config.get_value("Ajustes", "volumen_maestro", DEFAULT_VOL_MAESTRO)
		volumen_musica = config.get_value("Ajustes", "volumen_musica", DEFAULT_VOL_MUSICA)
		volumen_sfx = config.get_value("Ajustes", "volumen_sfx", DEFAULT_VOL_SFX)
	var env_nodo := get_tree().root.find_child("WorldGamma", true, false)
	if env_nodo and env_nodo is WorldEnvironment:
		aplicar_ajustes(env_nodo.environment)
	aplicar_volumenes()

func aplicar_ajustes(env: Environment) -> void:
	if env:
		env.set("adjustments_enabled", true)
		env.set("adjustment_brightness", brillo)
		env.set("adjustment_saturation", saturacion)
		env.set("adjustment_contrast", contraste)

func aplicar_ajustes_actuales() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if RESOLUTIONS.has(res_index):
			var res: Vector2i = RESOLUTIONS[res_index]
			DisplayServer.window_set_size(res)
			var screen_center := DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2) - (res / 2)
			DisplayServer.window_set_position(screen_center)
	var env_nodo := get_tree().root.find_child("WorldGamma", true, false)
	if env_nodo and env_nodo is WorldEnvironment:
		aplicar_ajustes(env_nodo.environment)
	aplicar_volumenes()

func aplicar_volumenes() -> void:
	_set_bus_volume("Master", volumen_maestro)
	_set_bus_volume("Music", volumen_musica)
	_set_bus_volume("SFX", volumen_sfx)

func _set_bus_volume(bus_name: String, lineal: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	if lineal <= 0.001:
		AudioServer.set_bus_mute(idx, true)
		return
	AudioServer.set_bus_mute(idx, false)
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(lineal, 0.0, 1.0)))
