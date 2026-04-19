extends Node

# GameConfig.gd

var brillo: float = 1.0
var saturacion: float = 1.0
var contraste: float = 1.0


func aplicar_ajustes(env: Environment):
	var env_nodo = get_tree().root.find_child("WorldGamma", true, false)
	if env and env_nodo: 
		env.adjustment_brightness = brillo
		env.adjustment_saturation = saturacion
		env.adjustment_contrast = contraste
