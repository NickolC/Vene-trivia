extends Node

# Valores por defecto (Predeterminados)
const DEFAULT_BRILLO := 1.0
const DEFAULT_SATURATION := 1.0
const DEFAULT_CONTRAST := 1.0
const DEFAULT_FULLSCREEN := false
const DEFAULT_RES_INDEX := 0
const SAVE_PATH := "user://configuracion_usuario.cfg"

const RESOLUTIONS: Dictionary = {
	0: Vector2i(1920, 1080),
	1: Vector2i(1280, 720),
	2: Vector2i(640, 480)
}

# Variables actuales
var brillo: float = DEFAULT_BRILLO
var saturacion: float = DEFAULT_SATURATION
var contraste: float = DEFAULT_CONTRAST
var fullscreen: bool = DEFAULT_FULLSCREEN
var res_index: int = DEFAULT_RES_INDEX

func guardar_ajustes() -> void:
	var config := ConfigFile.new()
	config.set_value("Ajustes", "brillo", brillo)
	config.set_value("Ajustes", "saturacion", saturacion)
	config.set_value("Ajustes", "contraste", contraste)
	config.set_value("Ajustes", "fullscreen", fullscreen)
	config.set_value("Ajustes", "res_index", res_index)
	config.save(SAVE_PATH)
	
func cargar_ajustes() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err == OK:
		brillo = config.get_value("Ajustes", "brillo", DEFAULT_BRILLO)
		saturacion = config.get_value("Ajustes", "saturacion", DEFAULT_SATURATION)
		contraste = config.get_value("Ajustes", "contraste", DEFAULT_CONTRAST)
		fullscreen = config.get_value("Ajustes", "fullscreen", DEFAULT_FULLSCREEN)
		res_index = config.get_value("Ajustes", "res_index", DEFAULT_RES_INDEX)

func aplicar_ajustes_actuales() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	if RESOLUTIONS.has(res_index):
		DisplayServer.window_set_size(RESOLUTIONS[res_index])

	var world_environment := _buscar_world_environment()
	if world_environment and world_environment.environment:
		aplicar_ajustes_entorno(world_environment.environment)

func aplicar_ajustes_entorno(env: Environment) -> void:
	env.adjustment_enabled = true
	env.adjustment_brightness = brillo
	env.adjustment_saturation = saturacion
	env.adjustment_contrast = contraste

func _buscar_world_environment() -> WorldEnvironment:
	var nodo := get_tree().root.find_child("WorldEnvironment", true, false)
	if nodo is WorldEnvironment:
		return nodo as WorldEnvironment

	nodo = get_tree().root.find_child("WorldGamma", true, false)
	if nodo is WorldEnvironment:
		return nodo as WorldEnvironment

	return null
