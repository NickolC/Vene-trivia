extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite
var _super_admin_actual: String = "root"

@onready var input_usuario_docente: LineEdit = $MainPanel/Margin/VBox/Content/CrearDocentePanel/Margin/CrearDocenteVBox/InputUsuarioDocente
@onready var input_clave_docente: LineEdit = $MainPanel/Margin/VBox/Content/CrearDocentePanel/Margin/CrearDocenteVBox/InputClaveDocente
@onready var label_estado: Label = $MainPanel/Margin/VBox/Content/CrearDocentePanel/Margin/CrearDocenteVBox/EstadoOperacion
@onready var lista_docentes: ItemList = $MainPanel/Margin/VBox/Content/CrearDocentePanel/Margin/CrearDocenteVBox/ListaDocentes
@onready var texto_actividad: RichTextLabel = $MainPanel/Margin/VBox/Content/ActividadPanel/Margin/ActividadVBox/ActividadTexto

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	_ensure_admin_table()
	SQLiteHelper.ensure_superadmin_table(db)
	SQLiteHelper.ensure_activity_table(db)
	_super_admin_actual = GlobalUsuario.nombre_alumno if not GlobalUsuario.nombre_alumno.is_empty() else "root"
	SQLiteHelper.log_activity(db, "superadmin", _super_admin_actual, "acceso_panel")
	_refresh_data()

func _exit_tree() -> void:
	SQLiteHelper.close_db_connection(db)

func _ensure_admin_table() -> void:
	if db == null:
		return

	var query := "CREATE TABLE IF NOT EXISTS Admin (" + \
	"NU_USU INTEGER PRIMARY KEY AUTOINCREMENT, " + \
	"NM_ADMIN TEXT NOT NULL UNIQUE, " + \
	"CO_PSW TEXT NOT NULL);"
	db.query(query)

func _on_crear_docente_pressed() -> void:
	var usuario := input_usuario_docente.text.strip_edges()
	var clave := input_clave_docente.text

	if usuario.is_empty() or clave.is_empty():
		_set_estado("Completa usuario y clave para crear el docente.", Color(0.9, 0.2, 0.2))
		return

	if usuario.length() < 4:
		_set_estado("El usuario del docente debe tener al menos 4 caracteres.", Color(0.9, 0.2, 0.2))
		return

	if clave.length() < 4:
		_set_estado("La clave del docente debe tener al menos 4 caracteres.", Color(0.9, 0.2, 0.2))
		return

	var query := "INSERT INTO Admin (NM_ADMIN, CO_PSW) VALUES ('%s', '%s');" % [
		SQLiteHelper.escape(usuario),
		SQLiteHelper.escape(clave)
	]

	if db.query(query):
		SQLiteHelper.log_activity(db, "superadmin", _super_admin_actual, "creo_docente:" + usuario)
		_set_estado("Docente creado con exito: " + usuario, Color(0.15, 0.6, 0.25))
		input_usuario_docente.text = ""
		input_clave_docente.text = ""
		_refresh_data()
	else:
		_set_estado("No se pudo crear el docente. Verifica si ya existe.", Color(0.9, 0.2, 0.2))

func _on_actualizar_actividad_pressed() -> void:
	_refresh_data()
	_set_estado("Actividad actualizada.", Color(0.15, 0.6, 0.25))

func _on_volver_login_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Login.tscn")

func _refresh_data() -> void:
	_refresh_docentes()
	_refresh_actividad()

func _refresh_docentes() -> void:
	lista_docentes.clear()
	if db == null:
		lista_docentes.add_item("Sin conexion a la base de datos.")
		return

	var query := "SELECT NU_USU, NM_ADMIN FROM Admin ORDER BY NU_USU DESC;"
	if not db.query(query):
		lista_docentes.add_item("No se pudieron cargar docentes.")
		return

	if db.query_result.is_empty():
		lista_docentes.add_item("No hay docentes registrados.")
		return

	for row in db.query_result:
		var nombre := str(row.get("NM_ADMIN", "sin_nombre"))
		var id_docente := int(row.get("NU_USU", 0))
		lista_docentes.add_item("#%d  %s" % [id_docente, nombre])

func _refresh_actividad() -> void:
	if db == null:
		texto_actividad.text = "No hay conexion a la base de datos."
		return

	var total_docentes := _scalar_int("SELECT COUNT(*) AS total FROM Admin;", "total")
	var total_alumnos := _scalar_int("SELECT COUNT(*) AS total FROM Alumnos;", "total")
	var partidas_jugadas := _scalar_int("SELECT COUNT(*) AS total FROM niveles;", "total")

	var lineas: Array[String] = []
	lineas.append("RESUMEN")
	lineas.append("Docentes registrados: %d" % total_docentes)
	lineas.append("Alumnos registrados: %d" % total_alumnos)
	lineas.append("Partidas registradas: %d" % partidas_jugadas)

	lineas.append("")
	lineas.append("TOP ALUMNOS POR PUNTAJE")
	var ranking_query := "SELECT a.NM_ALUMNO, a.NU_NIVEL_MAX, COALESCE(SUM(n.NU_PUNTOS), 0) AS total_puntos " + \
	"FROM Alumnos a LEFT JOIN niveles n ON n.NU_USU = a.NU_USU " + \
	"GROUP BY a.NU_USU ORDER BY total_puntos DESC, a.NU_NIVEL_MAX DESC, a.NM_ALUMNO ASC LIMIT 8;"

	if db.query(ranking_query) and not db.query_result.is_empty():
		for row in db.query_result:
			var alumno := str(row.get("NM_ALUMNO", "sin_nombre"))
			var nivel := int(row.get("NU_NIVEL_MAX", 0))
			var puntos := int(row.get("total_puntos", 0))
			lineas.append("- %s | Nivel max: %d | Puntos: %d" % [alumno, nivel, puntos])
	else:
		lineas.append("- Sin datos de actividad de alumnos.")

	lineas.append("")
	lineas.append("ACTIVIDAD RECIENTE")
	var activity_query := "SELECT TX_TIPO_USUARIO, TX_USUARIO, TX_ACCION, TX_FECHA FROM actividad ORDER BY NU_ACT DESC LIMIT 20;"
	if db.query(activity_query) and not db.query_result.is_empty():
		for row in db.query_result:
			var tipo := str(row.get("TX_TIPO_USUARIO", "sistema"))
			var usuario := str(row.get("TX_USUARIO", "desconocido"))
			var accion := str(row.get("TX_ACCION", "sin_accion"))
			var fecha := str(row.get("TX_FECHA", "sin_fecha"))
			lineas.append("- [%s] %s -> %s (%s)" % [tipo, usuario, accion, fecha])
	else:
		lineas.append("- Sin eventos registrados.")

	texto_actividad.text = "\n".join(lineas)

func _scalar_int(query: String, key: String) -> int:
	if db == null:
		return 0
	if not db.query(query):
		return 0
	if db.query_result.is_empty():
		return 0
	return int(db.query_result[0].get(key, 0))

func _set_estado(mensaje: String, color: Color) -> void:
	label_estado.text = mensaje
	label_estado.modulate = color
