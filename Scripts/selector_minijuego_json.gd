extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

@export var minijuego_id: String = "verdadero_falso"
@export var minijuego_nombre: String = "Minijuego"
@export var scene_juego: String = "res://Scenes/minijuego_textual.tscn"

const ESTRELLA_LLENA = preload("res://GFX/nivelpasadolleno.png")
const ESTRELLA_VACIA = preload("res://GFX/nivelpasado.png")
const TEMAS_NIVELES: Dictionary = {
	1: "Tema: El Reino del Agua",
	2: "Tema: Amalivaca y el Orinoco",
	3: "Tema: Las Perlas de Cubagua",
	4: "Tema: Piratas en el Caribe",
	5: "Tema: Miranda, el Viajero",
	6: "Tema: El 19 de Abril",
	7: "Tema: La Batalla de Carabobo",
	8: "Tema: Las Heroinas",
	9: "Tema: El Congreso de Angostura",
	10: "Tema: La Abolicion",
	11: "Tema: El Tren de Guzman Blanco",
	12: "Tema: El Reventon Petrolero",
	13: "Tema: La Ciudad Universitaria",
	14: "Tema: Inventores Venezolanos",
	15: "Tema: Venezuela en el Mundo"
}

var db: SQLite
var nivel_seleccionado_temp: int = -1

@onready var estrella_1: TextureRect = $PrevNiveles/MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer/TextureRect
@onready var estrella_2: TextureRect = $PrevNiveles/MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer/TextureRect2
@onready var estrella_3: TextureRect = $PrevNiveles/MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer/TextureRect3
@onready var prev_nivel: Label = $PrevNiveles/Label2
@onready var prev_tema: Label = $PrevNiveles/MarginContainer/VBoxContainer/MarginContainer2/Label
@onready var contenedor1: HBoxContainer = $VBoxContainer/HBoxContainer
@onready var contenedor2: HBoxContainer = $VBoxContainer/HBoxContainer2
@onready var contenedor3: HBoxContainer = $VBoxContainer/HBoxContainer3

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	_cargar_usuario_actual()
	$PrevNiveles.hide()
	configurar_selector()

func _exit_tree() -> void:
	if db:
		SQLiteHelper.close_db_connection(db)
		db = null

func _on_atras_pressed() -> void:
	Configuracion.change_scene_to_file("res://Scenes/Minijuegos.tscn")

func configurar_selector() -> void:
	var todos_los_botones: Array[Node] = []
	todos_los_botones.append_array(contenedor1.get_children())
	todos_los_botones.append_array(contenedor2.get_children())
	todos_los_botones.append_array(contenedor3.get_children())

	for i in range(todos_los_botones.size()):
		var n_nivel := i + 1
		var btn := todos_los_botones[i] as Button
		if btn == null:
			continue
		if n_nivel <= 15:
			desbloquear_boton(btn, n_nivel)
		else:
			bloquear_boton(btn)

func desbloquear_boton(btn: Button, num: int) -> void:
	btn.disabled = false
	btn.modulate = Color.WHITE
	_desconectar_senales_boton(btn)
	btn.pressed.connect(Callable(self, "_on_nivel_seleccionado_desde_mapa").bind(num))

func bloquear_boton(btn: Button) -> void:
	btn.disabled = true
	btn.modulate = Color(0.3, 0.3, 0.3, 0.8)

func _desconectar_senales_boton(btn: Button) -> void:
	for conexion in btn.pressed.get_connections():
		btn.pressed.disconnect(conexion.callable)

func _on_nivel_seleccionado_desde_mapa(num: int) -> void:
	nivel_seleccionado_temp = num
	prev_nivel.text = "%s - Nivel %d" % [minijuego_nombre, num]
	prev_tema.text = TEMAS_NIVELES.get(num, "Tema no disponible")

	var estrellas := _cargar_estrellas_minijuego()
	estrella_1.texture = ESTRELLA_LLENA if estrellas >= 1 else ESTRELLA_VACIA
	estrella_2.texture = ESTRELLA_LLENA if estrellas >= 2 else ESTRELLA_VACIA
	estrella_3.texture = ESTRELLA_LLENA if estrellas >= 3 else ESTRELLA_VACIA

	$PrevNiveles.show()

func _cargar_estrellas_minijuego() -> int:
	if db == null or GlobalUsuario.usuario_actual_id <= 0:
		return 0
	var q := "SELECT NU_ESTRELLAS FROM minijuegos_resultados WHERE NU_USU = %d AND NM_MINIJUEGO = '%s' LIMIT 1;" % [GlobalUsuario.usuario_actual_id, SQLiteHelper.escape(minijuego_id)]
	db.query(q)
	if db.query_result.is_empty():
		return 0
	return int(db.query_result[0].get("NU_ESTRELLAS", 0))

func _on_button_pressed() -> void:
	if nivel_seleccionado_temp == -1:
		_mostrar_alerta("Selecciona un nivel antes de jugar.")
		return

	GlobalUsuario.nivel_seleccionado = nivel_seleccionado_temp
	GlobalUsuario.minijuego_actual = minijuego_id
	if db:
		SQLiteHelper.close_db_connection(db)
		db = null
	Configuracion.change_scene_to_file(scene_juego)

func _on_button_4_pressed() -> void:
	nivel_seleccionado_temp = -1
	$PrevNiveles.hide()

func _cargar_usuario_actual() -> void:
	if db == null:
		return
	var query := ""
	if GlobalUsuario.usuario_actual_id > 0:
		query = "SELECT NU_USU, NM_ALUMNO FROM Alumnos WHERE NU_USU = %d;" % GlobalUsuario.usuario_actual_id
	elif not GlobalUsuario.nombre_alumno.is_empty():
		query = "SELECT NU_USU, NM_ALUMNO FROM Alumnos WHERE NM_ALUMNO = '%s';" % SQLiteHelper.escape(GlobalUsuario.nombre_alumno)
	else:
		return

	db.query(query)
	if db.query_result.is_empty():
		_mostrar_alerta("No se encontro la sesion del alumno.")
		return

	var resultado: Dictionary = db.query_result[0]
	GlobalUsuario.usuario_actual_id = int(resultado.get("NU_USU", GlobalUsuario.usuario_actual_id))
	GlobalUsuario.nombre_alumno = str(resultado.get("NM_ALUMNO", GlobalUsuario.nombre_alumno))

func _mostrar_alerta(mensaje: String) -> void:
	var alertas: Node = get_node_or_null("/root/Alertas")
	if alertas and alertas.has_method("mostrar_alerta"):
		alertas.mostrar_alerta(mensaje, 1.2)
	print(mensaje)
