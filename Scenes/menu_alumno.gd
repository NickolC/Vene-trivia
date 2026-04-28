extends Control

var db : SQLite
var nivel_actual: int 

func _ready() -> void:
	# En el script de tu Nivel o Escena de Juego
	db = SQLite.new()
	db.path = "res://DB/venetrivia.db"
	db.open_db()
	
	var query = ("SELECT * FROM Alumnos WHERE NM_ALUMNO = '%s';" % GlobalUsuario.nombre_alumno)
	db.query(query)
	
	var resultado = db.query_result # Esto devuelve un Array de Diccionarios
	if resultado.size() > 0:
		# ¡Éxito! El primer elemento [0] tiene nuestro ID
		GlobalUsuario.nombre_alumno = resultado[0]["NM_ALUMNO"]
		print("Sesión iniciada como: ", GlobalUsuario.nombre_alumno)
	else:
		print("El alumno no existe en la base de datos.")
		
	# Buscamos el WorldEnvironment de esta escena específica
	Configuracion.cargar_ajustes()

func _on_jugar_pressed() -> void:
	Configuracion.change_scene_to_file("res://Mapa.tscn")


func _on_minijuegos_pressed() -> void:
	Configuracion.change_scene_to_file("res://Scenes/Minijuegos.tscn")


func _on_opciones_pressed() -> void:
	Configuracion.change_scene_to_file("res://Scenes/Opciones.tscn")


func _on_extras_pressed() -> void:
	Configuracion.change_scene_to_file("res://Scenes/Extras.tscn")


func _on_cuenta_pressed() -> void:

	pass # Replace with function body.


func _on_button_pressed() -> void:
	Configuracion.change_scene_to_file("res://Scenes/Alumno.tscn")
