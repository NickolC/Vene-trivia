extends Node

# GameConfig.gd

var brillo: float = 1.0
var saturacion: float = 1.0
var contraste: float = 1.0


func aplicar_ajustes(env: Environment) -> void:
	if env == null:
		return

	var configuracion := get_node_or_null("/root/Configuracion")
	if configuracion:
		env.adjustment_brightness = configuracion.brillo
		env.adjustment_saturation = configuracion.saturacion
		env.adjustment_contrast = configuracion.contraste
		return

	env.adjustment_brightness = brillo
	env.adjustment_saturation = saturacion
	env.adjustment_contrast = contraste
