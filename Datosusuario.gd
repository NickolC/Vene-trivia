extends Node

# Variables que vivirán durante todo el juego
var usuario_actual_id: int = -1
var nombre_alumno: String = ""
var nivel_maximo: int = 1

# Función para limpiar la sesión (Cerrar Sesión)
func limpiar_sesion() -> void:
	usuario_actual_id = -1
	nombre_alumno = ""
	nivel_maximo = 1

func hay_sesion_activa() -> bool:
	return usuario_actual_id > 0 and not nombre_alumno.is_empty()
