extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite
var nivel_actual: int = GlobalUsuario.nivel_maximo
@onready var info1 = $TextureRect/Extras/Label
@onready var info2 = $TextureRect/Extras/Label2
@onready var info3 = $TextureRect/Extras/Label3
@onready var info4 = $TextureRect/Extras/Label4
@onready var info5 = $TextureRect/Extras/Label5
@onready var info6 = $TextureRect/Extras/Label6
@onready var info7 = $TextureRect/Extras/Label7
@onready var info8 = $TextureRect/Extras/Label8

@onready var ram1 = $TextureRect/Extras/TextureRect2
@onready var ram2 = $TextureRect/Extras/TextureRect3
@onready var ram3 = $TextureRect/Extras/TextureRect4
@onready var ram4 = $TextureRect/Extras/TextureRect5
@onready var ram5 = $TextureRect/Extras/TextureRect6
@onready var ram6 = $TextureRect/Extras/TextureRect7
@onready var ram7 = $TextureRect/Extras/TextureRect8
@onready var ram8 = $TextureRect/Extras/TextureRect9

@onready var label_dialogo1 = $TextureRect/Extras/PanelContainer/MarginContainer/Label
@onready var panel_dialogo1 = $TextureRect/Extras/PanelContainer

@onready var label_dialogo2 = $TextureRect/Extras/PanelContainer2/MarginContainer/Label
@onready var panel_dialogo2 = $TextureRect/Extras/PanelContainer2

@onready var label_dialogo3 = $TextureRect/Extras/PanelContainer2/MarginContainer/Label
@onready var panel_dialogo3 = $TextureRect/Extras/PanelContainer2

@onready var label_dialogo4 = $TextureRect/Extras/PanelContainer2/MarginContainer/Label
@onready var panel_dialogo4 = $TextureRect/Extras/PanelContainer2

@onready var label_dialogo5 = $TextureRect/Extras/PanelContainer2/MarginContainer/Label
@onready var panel_dialogo5 = $TextureRect/Extras/PanelContainer2

@onready var label_dialogo6 = $TextureRect/Extras/PanelContainer2/MarginContainer/Label
@onready var panel_dialogo6 = $TextureRect/Extras/PanelContainer2

@onready var label_dialogo7 = $TextureRect/Extras/PanelContainer2/MarginContainer/Label
@onready var panel_dialogo7 = $TextureRect/Extras/PanelContainer2

@onready var label_dialogo8 = $TextureRect/Extras/PanelContainer2/MarginContainer/Label
@onready var panel_dialogo8 = $TextureRect/Extras/PanelContainer2

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
	
	info1.text = '¡Hola, valiente explorador del tiempo! 🎩✨
	¿Alguna vez te has preguntado cómo se fundaron nuestras ciudades, quiénes fueron los héroes que lucharon por nuestra libertad o qué secretos esconden nuestras tradiciones? ¡Estás a punto de descubrirlo de la forma más emocionante posible!
	En este juego, no solo pondrás a prueba tu memoria, sino que te convertirás en un verdadero experto de la Historia de Venezuela. Al estilo del famoso concurso de preguntas, tendrás que avanzar por una escalera de retos para alcanzar la meta final.'

func _on_bienvenida_pressed() -> void:
	panel_dialogo1.visible = true
	ram1.visible = true
	info1.visible = true
	
	ram2.visible = false
	panel_dialogo2.visible = false
	info2.visible = false
	
	ram3.visible = false
	panel_dialogo3.visible = false
	info3.visible = false
	
	ram4.visible = false
	panel_dialogo4.visible = false
	info4.visible = false
	
	ram5.visible = false
	panel_dialogo5.visible = false
	info5.visible = false
	
	ram6.visible = false
	panel_dialogo6.visible = false
	info6.visible = false
	
	ram7.visible = false
	panel_dialogo7.visible = false
	info7.visible = false
	
	ram8.visible = false
	panel_dialogo8.visible = false
	info8.visible = false
	
	info1.text = '¡Hola, valiente explorador del tiempo! 🎩✨
	¿Alguna vez te has preguntado cómo se fundaron nuestras ciudades, quiénes fueron los héroes que lucharon por nuestra libertad o qué secretos esconden nuestras tradiciones? ¡Estás a punto de descubrirlo de la forma más emocionante posible!
	En este juego, no solo pondrás a prueba tu memoria, sino que te convertirás en un verdadero experto de la Historia de Venezuela. Al estilo del famoso concurso de preguntas, tendrás que avanzar por una escalera de retos para alcanzar la meta final.'

func _on_comojugar_pressed() -> void:
	ram2.visible = true
	panel_dialogo2.visible = true
	info2.visible = true
	
	ram1.visible = false
	panel_dialogo1.visible = false
	info1.visible = false
	
	ram3.visible = false
	panel_dialogo3.visible = false
	info3.visible = false
	
	ram4.visible = false
	panel_dialogo4.visible = false
	info4.visible = false
	
	ram5.visible = false
	panel_dialogo5.visible = false
	info5.visible = false
	
	ram6.visible = false
	panel_dialogo6.visible = false
	info6.visible = false
	
	ram7.visible = false
	panel_dialogo7.visible = false
	info7.visible = false
	
	ram8.visible = false
	panel_dialogo8.visible = false
	info8.visible = false
	
	label_dialogo2.text = '¿Con que asi se jugaba? es bueno saberlo'
	
	info2.text = 'En el menú principal, dirígete al Selector de Niveles en donde dice "Jugar". Verás 15 niveles por completar. Cada uno representa una etapa distinta de nuestra historia. ¡Haz clic en el nivel que quieras desafiar para comenzar!
	Una vez dentro del juego, aparecerá una pregunta en pantalla. Tienes 4 opciones de respuesta, pero ¡cuidado!, solo una es la correcta. Lee con atención y elige la que te llevará a la siguiente pregunta.
	Si una pregunta te hace dudar, ¡no te preocupes! Tienes comodines especiales para ayudarte a ganar pero ten en cuenta que solo se usa una vez por nivel:
	50/50: Elimina dos respuestas incorrectas.
	Llamada: Te da una pista sobre cuál podría ser la respuesta.
	Público: Te muestra qué opinan los demás.
	Si quieres descansar o ajustar algo, presiona el botón de Pausa. Allí podrás elegir entre:
	Reanudar: Para seguir justo donde quedaste.
	Opciones: Para ajustar las resoluciones, brillo, gamma o el sonido en general.
	Salir: Para volver al menú principal (¡pero recuerda que perderás tu progreso del nivel!).'	

func _on_sobreeljuego_pressed() -> void:
	ram3.visible = true
	panel_dialogo3.visible = true
	info3.visible = true
	
	ram1.visible = false
	panel_dialogo1.visible = false
	info1.visible = false
	
	ram2.visible = false
	panel_dialogo2.visible = false
	info2.visible = false
	
	ram4.visible = false
	panel_dialogo4.visible = false
	info4.visible = false
	
	ram5.visible = false
	panel_dialogo5.visible = false
	info5.visible = false
	
	ram6.visible = false
	panel_dialogo6.visible = false
	info6.visible = false
	
	ram7.visible = false
	panel_dialogo7.visible = false
	info7.visible = false
	
	ram8.visible = false
	panel_dialogo8.visible = false
	info8.visible = false
	
	label_dialogo3.text = '¡Es bueno saber eso!'
	
	info3.text = 'En el menú principal, dirígete al Selector de Niveles en donde dice "Jugar". Verás 15 niveles por completar. Cada uno representa una etapa distinta de nuestra historia. ¡Haz clic en el nivel que quieras desafiar para comenzar!
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
