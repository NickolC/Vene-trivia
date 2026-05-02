extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite
var _super_admin_actual: String = "root"
var _alumno_ids: Array[int] = []

@onready var lista_alumnos: ItemList = $MainPanel/Margin/VBox/Content/ListaPanel/Margin/ListaVBox/ListaAlumnos
@onready var label_estado: Label = $MainPanel/Margin/VBox/Content/AccionesPanel/Margin/AccionesVBox/EstadoLabel
@onready var btn_desactivar: Button = $MainPanel/Margin/VBox/Content/AccionesPanel/Margin/AccionesVBox/BtnDesactivar
@onready var btn_activar: Button = $MainPanel/Margin/VBox/Content/AccionesPanel/Margin/AccionesVBox/BtnActivar

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	SQLiteHelper.ensure_alumnos_activo_column(db)
	_super_admin_actual = GlobalUsuario.nombre_alumno if not GlobalUsuario.nombre_alumno.is_empty() else "root"
	btn_desactivar.disabled = true
	btn_activar.disabled = true
	_refresh_alumnos()

func _exit_tree() -> void:
	SQLiteHelper.close_db_connection(db)

func _refresh_alumnos() -> void:
	lista_alumnos.clear()
	_alumno_ids.clear()
	label_estado.text = ""
	btn_desactivar.disabled = true
	btn_activar.disabled = true

	var query := "SELECT NU_USU, NM_ALUMNO, COALESCE(SW_ACTIVO, 1) AS SW_ACTIVO FROM Alumnos ORDER BY NM_ALUMNO ASC;"
	if not db.query(query) or db.query_result.is_empty():
		lista_alumnos.add_item("No hay alumnos registrados.")
		return

	for row in db.query_result:
		var id := int(row.get("NU_USU", 0))
		var nombre := str(row.get("NM_ALUMNO", "sin_nombre"))
		var activo := int(row.get("SW_ACTIVO", 1))

		var estado_txt := "ACTIVO" if activo else "INACTIVO"
		lista_alumnos.add_item("%s  [%s]" % [nombre, estado_txt])

		var idx := lista_alumnos.item_count - 1
		if activo == 0:
			lista_alumnos.set_item_custom_fg_color(idx, Color(0.75, 0.18, 0.18))
		else:
			lista_alumnos.set_item_custom_fg_color(idx, Color(0.08, 0.45, 0.15))

		_alumno_ids.append(id)

func _on_lista_alumnos_item_selected(_index: int) -> void:
	btn_desactivar.disabled = false
	btn_activar.disabled = false
	label_estado.text = ""
	label_estado.modulate = Color.WHITE

func _on_btn_desactivar_pressed() -> void:
	var selected := lista_alumnos.get_selected_items()
	if selected.is_empty():
		_set_estado("Selecciona un alumno primero.", Color(0.8, 0.55, 0.1))
		return

	var alumno_id := _alumno_ids[selected[0]]
	if db.query("UPDATE Alumnos SET SW_ACTIVO = 0 WHERE NU_USU = %d;" % alumno_id):
		SQLiteHelper.log_activity(db, "superadmin", _super_admin_actual, "desactivo_alumno:%d" % alumno_id)
		_set_estado("Alumno desactivado correctamente.", Color(0.8, 0.2, 0.2))
		_refresh_alumnos()
	else:
		_set_estado("Error al desactivar el alumno.", Color(0.9, 0.1, 0.1))

func _on_btn_activar_pressed() -> void:
	var selected := lista_alumnos.get_selected_items()
	if selected.is_empty():
		_set_estado("Selecciona un alumno primero.", Color(0.8, 0.55, 0.1))
		return

	var alumno_id := _alumno_ids[selected[0]]
	if db.query("UPDATE Alumnos SET SW_ACTIVO = 1 WHERE NU_USU = %d;" % alumno_id):
		SQLiteHelper.log_activity(db, "superadmin", _super_admin_actual, "reactivo_alumno:%d" % alumno_id)
		_set_estado("Alumno reactivado correctamente.", Color(0.15, 0.6, 0.25))
		_refresh_alumnos()
	else:
		_set_estado("Error al reactivar el alumno.", Color(0.9, 0.1, 0.1))

func _on_btn_actualizar_pressed() -> void:
	_refresh_alumnos()
	_set_estado("Lista actualizada.", Color(0.15, 0.6, 0.25))

func _on_btn_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/SuperAdmin.tscn")

func _set_estado(msg: String, color: Color) -> void:
	label_estado.text = msg
	label_estado.modulate = color
