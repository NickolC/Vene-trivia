extends Node

# Variables que vivirán durante todo el juego
var usuario_actual_id: int = -1
var nombre_alumno: String = ""
var nivel_maximo: int = 1

# Función para limpiar la sesión (Cerrar Sesión)
func limpiar_sesion():
	usuario_actual_id = -1
	nombre_alumno = ""
	nivel_maximo = 1
