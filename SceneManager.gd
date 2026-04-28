extends Node

# Valores por defecto (Predeterminados)
const DEFAULT_BRILLO: float = 1.0
const DEFAULT_SATURATION: float = 1.0
const DEFAULT_CONTRAST: float = 1.0
const DEFAULT_FULLSCREEN = false
const DEFAULT_RES_INDEX = 0

# Variables actuales
var brillo = DEFAULT_BRILLO
var saturacion = DEFAULT_SATURATION
var contraste = DEFAULT_CONTRAST
var fullscreen = DEFAULT_FULLSCREEN
var res_index = DEFAULT_RES_INDEX

const SAVE_PATH = "user://configuracion_usuario.cfg"
# SceneManager.gd - Autoload para manejar cambios de escena con guardado automático

signal scene_changing(from_scene: String, to_scene: String)
signal scene_changed(to_scene: String)

var current_scene_path: String

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	current_scene_path = get_tree().current_scene.scene_file_path
	# Conectar a la señal de cambio de escena del SceneTree
	get_tree().tree_changed.connect(_on_tree_changed)

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
	var config = ConfigFile.new()
	config.set_value("Ajustes", "brillo", brillo)
	config.set_value("Ajustes", "saturacion", saturacion)
	config.set_value("Ajustes", "contraste", contraste)
	config.set_value("Ajustes", "fullscreen", fullscreen)
	config.set_value("Ajustes", "res_index", res_index)
	config.save(SAVE_PATH)
		
func cargar_ajustes() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		brillo = config.get_value("Ajustes", "brillo", DEFAULT_BRILLO)
		saturacion = config.get_value("Ajustes", "saturacion", DEFAULT_SATURATION)
		contraste = config.get_value("Ajustes", "contraste", DEFAULT_CONTRAST)
		fullscreen = config.get_value("Ajustes", "fullscreen", DEFAULT_FULLSCREEN)
		res_index = config.get_value("Ajustes", "res_index", DEFAULT_RES_INDEX)

	# Aplicar los ajustes al WorldEnvironment de la escena actual
	var env_nodo = get_tree().root.find_child("WorldGamma", true, false)
	if env_nodo and env_nodo is WorldEnvironment:
		aplicar_ajustes(env_nodo.environment)

func aplicar_ajustes(env: Environment):
	if env:
		env.set("adjustments_enabled", true)
		env.set("adjustment_brightness", brillo)
		env.set("adjustment_saturation", saturacion)
		env.set("adjustment_contrast", contraste)
