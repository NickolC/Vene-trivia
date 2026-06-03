extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite
var nivel_actual: int = GlobalUsuario.nivel_maximo

@onready var info1 = $TextureRect/Extras/Label
@onready var info2 = $TextureRect/Extras/Label2
@onready var info3 = $TextureRect/Extras/Label3

@onready var ram1 = $TextureRect/Extras/TextureRect2
@onready var ram2 = $TextureRect/Extras/TextureRect3
@onready var ram3 = $TextureRect/Extras/TextureRect4

@onready var panel_dialogo1 = $TextureRect/Extras/PanelContainer
@onready var label_dialogo1 = $TextureRect/Extras/PanelContainer/MarginContainer/Label

@onready var panel_contenido = $TextureRect/Extras/PanelContainer2
@onready var label_contenido = $TextureRect/Extras/PanelContainer2/MarginContainer/Label

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	Configuracion.cargar_ajustes()
	_mostrar_seccion_1()

func _ocultar_todo() -> void:
	panel_dialogo1.visible = false
	panel_contenido.visible = false
	for i in [info1, info2, info3]:
		if i: i.visible = false
	for r in [ram1, ram2, ram3]:
		if r: r.visible = false

func _mostrar_seccion_1() -> void:
	_ocultar_todo()
	panel_dialogo1.visible = true
	if ram1: ram1.visible = true
	if info1: info1.visible = true
	label_dialogo1.text = "Bienvenida"
	info1.text = (
		"Hola, valiente explorador del tiempo!\n\n" +
		"Alguna vez te has preguntado como se fundaron nuestras ciudades, " +
		"quienes fueron los heroes que lucharon por nuestra libertad o " +
		"que secretos esconden nuestras tradiciones?\n\n" +
		"En este juego, no solo pondras a prueba tu memoria, sino que te " +
		"convertiras en un verdadero experto de la Historia de Venezuela. " +
		"Al estilo del famoso concurso de preguntas, tendras que avanzar " +
		"por una escalera de retos para alcanzar la meta final."
	)

func _mostrar_seccion(ram: TextureRect, info: Label, titulo: String, texto: String) -> void:
	_ocultar_todo()
	panel_contenido.visible = true
	if ram: ram.visible = true
	if info: info.visible = true
	label_contenido.text = titulo
	if info: info.text = texto

func _on_bienvenida_pressed() -> void:
	_mostrar_seccion_1()

func _on_comojugar_pressed() -> void:
	_mostrar_seccion(
		ram2, info2,
		"Como jugar",
		(
			"En el menu principal, selecciona 'Jugar'. Veras 15 niveles.\n" +
			"Cada nivel representa una etapa de la historia venezolana.\n\n" +
			"Dentro del nivel, tienes 4 opciones de respuesta por pregunta. Solo una es correcta.\n\n" +
			"Comodines disponibles (uno por nivel cada uno):\n" +
			"  50/50 — Elimina dos respuestas incorrectas.\n" +
			"  Llamada — Da una pista sobre la respuesta.\n" +
			"  Publico — Muestra el porcentaje de votos.\n\n" +
			"Con el boton Pausa puedes Reanudar, ir a Opciones o Salir al menu " +
			"(si sales, perdes el progreso del nivel)."
		)
	)

func _on_sobreeljuego_pressed() -> void:
	_mostrar_seccion(
		ram3, info3,
		"Sobre el juego",
		(
			"Vene-Trivia es un juego educativo sobre Historia de Venezuela.\n\n" +
			"Cuenta con 15 niveles de preguntas progresivas que cubren desde " +
			"las culturas indigenas hasta Venezuela en el mundo moderno.\n\n" +
			"Ademas incluye tres tipos de minijuegos:\n" +
			"  Sopa de letras — Encuentra palabras históricas.\n" +
			"  Relacionar columnas — Une conceptos con su definicion.\n" +
			"  Memoria — Empareja imagenes con sus nombres.\n\n" +
			"Los niveles 11-15 de cada minijuego se desbloquean en la Tienda " +
			"usando las monedas ganadas al completar niveles.\n\n" +
			"El panel docente permite a los profesores revisar el rendimiento " +
			"de sus estudiantes y generar reportes HTML."
		)
	)

func _on_atras_pressed() -> void:
	SQLiteHelper.close_db_connection(db)
	Configuracion.change_scene_to_file("res://Scenes/menu-alumno.tscn")
