extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite
var nivel_actual: int = GlobalUsuario.nivel_maximo
@onready var info = $TextureRect/Extras/Label
@onready var infoc = $TextureRect/Extras/Label2

@onready var ram1 = $TextureRect/Extras/TextureRect2
@onready var ram2 = $TextureRect/Extras/TextureRect3

@onready var label_dialogo = $TextureRect/Extras/PanelContainer/MarginContainer/Label
@onready var panel_dialogo = $TextureRect/Extras/PanelContainer

@onready var label_dialogoc = $TextureRect/Extras/PanelContainer2/MarginContainer/Label
@onready var panel_dialogoc = $TextureRect/Extras/PanelContainer2

func _ready() -> void:
	# En el script de tu Nivel o Escena de Juego
	db = SQLite.new()
	db.path = "res://DB/venetrivia.db"
	db.open_db()
	
	var query = ("SELECT * FROM Alumnos WHERE NM_ALUMNO = '%s';" % GlobalUsuario.nombre_alumno)
	db.query(query)
	
	var resultado = db.query_result
	if resultado.size() > 0:
		GlobalUsuario.nombre_alumno = resultado[0]["NM_ALUMNO"]
		print("Sesión iniciada como: ", GlobalUsuario.nombre_alumno)
	else:
		print("El alumno no existe en la base de datos.")
		
	# Buscamos el WorldEnvironment de esta escena específica
	Configuracion.cargar_ajustes()
	
	ram1.visible = true
	
	info.text = '¡Hola, valiente explorador del tiempo! 🎩✨
	¿Alguna vez te has preguntado cómo se fundaron nuestras ciudades, quiénes fueron los héroes que lucharon por nuestra libertad o qué secretos esconden nuestras tradiciones? ¡Estás a punto de descubrirlo de la forma más emocionante posible!
	En este juego, no solo pondrás a prueba tu memoria, sino que te convertirás en un verdadero experto de la Historia de Venezuela. Al estilo del famoso concurso de preguntas, tendrás que avanzar por una escalera de retos para alcanzar la meta final.'

func _on_bienvenida_pressed() -> void:
	panel_dialogo.visible = true
	ram1.visible = true
	info.visible = true
	
	ram2.visible = false
	panel_dialogoc.visible = false
	infoc.visible = false
	
	info.text = '¡Hola, valiente explorador del tiempo! 🎩✨
	¿Alguna vez te has preguntado cómo se fundaron nuestras ciudades, quiénes fueron los héroes que lucharon por nuestra libertad o qué secretos esconden nuestras tradiciones? ¡Estás a punto de descubrirlo de la forma más emocionante posible!
	En este juego, no solo pondrás a prueba tu memoria, sino que te convertirás en un verdadero experto de la Historia de Venezuela. Al estilo del famoso concurso de preguntas, tendrás que avanzar por una escalera de retos para alcanzar la meta final.'

func _on_comojugar_pressed() -> void:
	ram2.visible = true
	panel_dialogoc.visible = true
	infoc.visible = true
	
	ram1.visible = false
	panel_dialogo.visible = false
	info.visible = false
	
	label_dialogoc.text = '¿Con que asi se jugaba? es bueno saberlo'
	
	infoc.text = 'En el menú principal, dirígete al Selector de Niveles en donde dice "Jugar". Verás 15 niveles por completar. Cada uno representa una etapa distinta de nuestra historia. ¡Haz clic en el nivel que quieras desafiar para comenzar!
	Una vez dentro del juego, aparecerá una pregunta en pantalla. Tienes 4 opciones de respuesta, pero ¡cuidado!, solo una es la correcta. Lee con atención y elige la que te llevará a la siguiente pregunta.
	Si una pregunta te hace dudar, ¡no te preocupes! Tienes comodines especiales para ayudarte a ganar pero ten en cuenta que solo se usa una vez por nivel:
	50/50: Elimina dos respuestas incorrectas.
	Llamada: Te da una pista sobre cuál podría ser la respuesta.
	Público: Te muestra qué opinan los demás.
	Si quieres descansar o ajustar algo, presiona el botón de Pausa. Allí podrás elegir entre:
	Reanudar: Para seguir justo donde quedaste.
	Opciones: Para ajustar las resoluciones, brillo, gamma o el sonido en general.
	Salir: Para volver al menú principal (¡pero recuerda que perderás tu progreso del nivel!).'	

func _on_atras_pressed() -> void:
	SQLiteHelper.close_db_connection(db)
	Configuracion.change_scene_to_file("res://Scenes/menu-alumno.tscn")

func cerrar_db_seguro():
	if db != null:
		SQLiteHelper.close_db_connection(db)
		db = null
