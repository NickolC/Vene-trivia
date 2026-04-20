extends Node

# Valores por defecto (Predeterminados)
const DEFAULT_BRILLO = 1.0
const DEFAULT_SATURATION = 1.0
const DEFAULT_CONTRAST = 1.0
const DEFAULT_FULLSCREEN = false
const DEFAULT_RES_INDEX = 0

# Variables actuales
var brillo = DEFAULT_BRILLO
var saturacion = DEFAULT_SATURATION
var contraste = DEFAULT_CONTRAST
var fullscreen = DEFAULT_FULLSCREEN
var res_index = DEFAULT_RES_INDEX

const SAVE_PATH = "user://configuracion_usuario.cfg"

func guardar_ajustes():
	var config = ConfigFile.new()
	config.set_value("Ajustes", "brillo", brillo)
	config.set_value("Ajustes", "saturacion", saturacion)
	config.set_value("Ajustes", "contraste", contraste)
	config.set_value("Ajustes", "fullscreen", fullscreen)
	config.set_value("Ajustes", "res_index", res_index)
	config.save(SAVE_PATH)
	
func cargar_ajustes():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		brillo = config.get_value("Ajustes", "brillo", DEFAULT_BRILLO)
		saturacion = config.get_value("Ajustes", "saturacion", DEFAULT_SATURATION)
		contraste = config.get_value("Ajustes", "contraste", DEFAULT_CONTRAST)
		fullscreen = config.get_value("Ajustes", "fullscreen", DEFAULT_FULLSCREEN)
		res_index = config.get_value("Ajustes", "res_index", DEFAULT_RES_INDEX)
