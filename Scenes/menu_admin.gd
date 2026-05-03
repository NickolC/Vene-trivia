extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

enum VistaDocente {
	GESTION,
	AUDITORIA,
	RENDIMIENTO
}

var db: SQLite
var _docente_nombre: String = ""
var _vista_actual: int = VistaDocente.GESTION
var _alumno_seleccionado_id: int = -1

@onready var btn_canvas_gestion: Button = $MainPanel/Margin/VBox/NavBar/BtnCanvasGestion
@onready var btn_canvas_auditoria: Button = $MainPanel/Margin/VBox/NavBar/BtnCanvasAuditoria
@onready var btn_canvas_rendimiento: Button = $MainPanel/Margin/VBox/NavBar/BtnCanvasRendimiento

@onready var filtro_bar: HBoxContainer = $MainPanel/Margin/VBox/FiltroBar
@onready var filtro_input: LineEdit = $MainPanel/Margin/VBox/FiltroBar/FiltroInput
@onready var label_resumen: Label = $MainPanel/Margin/VBox/ResumenLabel
@onready var arbol_alumnos: Tree = $MainPanel/Margin/VBox/ArbolAlumnos
@onready var panel_edicion: PanelContainer = $MainPanel/Margin/VBox/PanelEdicion
@onready var label_alumno_seleccionado: Label = $MainPanel/Margin/VBox/PanelEdicion/Margin/EdicionVBox/AlumnoSeleccionado
@onready var input_editar_usuario: LineEdit = $MainPanel/Margin/VBox/PanelEdicion/Margin/EdicionVBox/InputEditarUsuario
@onready var input_editar_clave: LineEdit = $MainPanel/Margin/VBox/PanelEdicion/Margin/EdicionVBox/InputEditarClave
@onready var label_estado_edicion: Label = $MainPanel/Margin/VBox/PanelEdicion/Margin/EdicionVBox/EstadoEdicion

@onready var canvas_auditoria: PanelContainer = $MainPanel/Margin/VBox/CanvasAuditoria
@onready var input_filtro_auditoria: LineEdit = $MainPanel/Margin/VBox/CanvasAuditoria/Margin/AuditoriaVBox/FiltroAuditoria
@onready var texto_auditoria: RichTextLabel = $MainPanel/Margin/VBox/CanvasAuditoria/Margin/AuditoriaVBox/TextoAuditoria

@onready var canvas_rendimiento: PanelContainer = $MainPanel/Margin/VBox/CanvasRendimiento
@onready var arbol_rendimiento_general: Tree = $MainPanel/Margin/VBox/CanvasRendimiento/Margin/RendimientoVBox/ArbolRendimientoGeneral
@onready var selector_alumno_detalle: OptionButton = $MainPanel/Margin/VBox/CanvasRendimiento/Margin/RendimientoVBox/DetalleFiltros/SelectorAlumnoDetalle
@onready var selector_nivel_detalle: OptionButton = $MainPanel/Margin/VBox/CanvasRendimiento/Margin/RendimientoVBox/DetalleFiltros/SelectorNivelDetalle
@onready var arbol_rendimiento_detalle: Tree = $MainPanel/Margin/VBox/CanvasRendimiento/Margin/RendimientoVBox/ArbolRendimientoDetalle
@onready var texto_logros: RichTextLabel = $MainPanel/Margin/VBox/CanvasRendimiento/Margin/RendimientoVBox/TextoLogros

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	SQLiteHelper.ensure_alumnos_activo_column(db)
	SQLiteHelper.ensure_minijuegos_table(db)
	SQLiteHelper.ensure_logros_table(db)
	_docente_nombre = GlobalUsuario.nombre_alumno
	SQLiteHelper.log_activity(db, "docente", _docente_nombre, "acceso_panel_docente")

	_setup_tree_gestion()
	_setup_tree_rendimiento_general()
	_setup_tree_rendimiento_detalle()
	_setup_selectores_detalle()
	_set_vista(VistaDocente.GESTION)

func _exit_tree() -> void:
	SQLiteHelper.close_db_connection(db)

func _set_vista(vista: int) -> void:
	_vista_actual = vista

	var es_gestion := vista == VistaDocente.GESTION
	var es_auditoria := vista == VistaDocente.AUDITORIA
	var es_rendimiento := vista == VistaDocente.RENDIMIENTO

	filtro_bar.visible = es_gestion
	label_resumen.visible = es_gestion
	arbol_alumnos.visible = es_gestion
	panel_edicion.visible = es_gestion

	canvas_auditoria.visible = es_auditoria
	canvas_rendimiento.visible = es_rendimiento

	btn_canvas_gestion.disabled = es_gestion
	btn_canvas_auditoria.disabled = es_auditoria
	btn_canvas_rendimiento.disabled = es_rendimiento

	if es_gestion:
		_refresh_gestion(filtro_input.text.strip_edges())
	elif es_auditoria:
		_refresh_auditoria(input_filtro_auditoria.text.strip_edges())
	else:
		_refresh_rendimiento_general()
		_refresh_rendimiento_detalle()

func _setup_tree_gestion() -> void:
	arbol_alumnos.columns = 7
	arbol_alumnos.column_titles_visible = true
	arbol_alumnos.hide_root = true
	arbol_alumnos.set_column_title(0, "Alumno")
	arbol_alumnos.set_column_title(1, "Estado")
	arbol_alumnos.set_column_title(2, "Nivel")
	arbol_alumnos.set_column_title(3, "Partidas")
	arbol_alumnos.set_column_title(4, "Puntos")
	arbol_alumnos.set_column_title(5, "Estrellas")
	arbol_alumnos.set_column_title(6, "Aciertos %")

func _setup_tree_rendimiento_general() -> void:
	arbol_rendimiento_general.columns = 6
	arbol_rendimiento_general.column_titles_visible = true
	arbol_rendimiento_general.hide_root = true
	arbol_rendimiento_general.set_column_title(0, "Alumno")
	arbol_rendimiento_general.set_column_title(1, "Nivel max")
	arbol_rendimiento_general.set_column_title(2, "Estrellas niveles")
	arbol_rendimiento_general.set_column_title(3, "Estrellas minijuegos")
	arbol_rendimiento_general.set_column_title(4, "Puntos niveles")
	arbol_rendimiento_general.set_column_title(5, "Partidas")

func _setup_tree_rendimiento_detalle() -> void:
	arbol_rendimiento_detalle.columns = 5
	arbol_rendimiento_detalle.column_titles_visible = true
	arbol_rendimiento_detalle.hide_root = true
	arbol_rendimiento_detalle.set_column_title(0, "Tipo")
	arbol_rendimiento_detalle.set_column_title(1, "Nombre")
	arbol_rendimiento_detalle.set_column_title(2, "Estrellas")
	arbol_rendimiento_detalle.set_column_title(3, "Puntos")
	arbol_rendimiento_detalle.set_column_title(4, "Extra")

func _setup_selectores_detalle() -> void:
	selector_nivel_detalle.clear()
	selector_nivel_detalle.add_item("Todos", 0)
	for i in range(1, 16):
		selector_nivel_detalle.add_item("Nivel %d" % i, i)
	selector_nivel_detalle.select(0)

	_refresh_selector_alumnos_detalle()

func _refresh_selector_alumnos_detalle() -> void:
	selector_alumno_detalle.clear()
	if db == null:
		selector_alumno_detalle.add_item("Sin datos", -1)
		selector_alumno_detalle.select(0)
		return

	var query := "SELECT NU_USU, NM_ALUMNO FROM Alumnos ORDER BY NM_ALUMNO ASC;"
	if not db.query(query) or db.query_result.is_empty():
		selector_alumno_detalle.add_item("Sin alumnos", -1)
		selector_alumno_detalle.select(0)
		return

	for row in db.query_result:
		var id_alumno := int(row.get("NU_USU", -1))
		var nombre := str(row.get("NM_ALUMNO", "sin_nombre"))
		selector_alumno_detalle.add_item(nombre, id_alumno)

	selector_alumno_detalle.select(0)

func _refresh_gestion(filtro: String = "") -> void:
	arbol_alumnos.clear()
	var root := arbol_alumnos.create_item()

	var where_clause := ""
	if not filtro.is_empty():
		where_clause = "WHERE a.NM_ALUMNO LIKE '%%%s%%'" % SQLiteHelper.escape(filtro)

	var query := (
		"SELECT a.NU_USU, a.NM_ALUMNO, a.NU_NIVEL_MAX, " +
		"COALESCE(a.SW_ACTIVO, 1) AS SW_ACTIVO, " +
		"COUNT(n.NU_NIVEL) AS partidas_jugadas, " +
		"COALESCE(SUM(n.NU_PUNTOS), 0) AS total_puntos, " +
		"COALESCE(SUM(n.NU_RESPC), 0) AS total_correctas, " +
		"COALESCE(SUM(n.NU_PREG), 0) AS total_preguntas, " +
		"COALESCE(AVG(CAST(n.NU_ESTRELLAS AS REAL)), 0.0) AS prom_estrellas " +
		"FROM Alumnos a LEFT JOIN niveles n ON n.NU_USU = a.NU_USU " +
		where_clause +
		" GROUP BY a.NU_USU ORDER BY total_puntos DESC, a.NM_ALUMNO ASC;"
	)

	if not db.query(query) or db.query_result.is_empty():
		var vacio := arbol_alumnos.create_item(root)
		vacio.set_text(0, "Sin datos de alumnos.")
		label_resumen.text = "No hay alumnos registrados."
		return

	var total_alumnos := 0
	var total_activos := 0
	var total_puntos_global := 0

	for data in db.query_result:
		var id_alumno := int(data.get("NU_USU", -1))
		var nombre := str(data.get("NM_ALUMNO", "?"))
		var activo := int(data.get("SW_ACTIVO", 1))
		var nivel := int(data.get("NU_NIVEL_MAX", 0))
		var partidas := int(data.get("partidas_jugadas", 0))
		var puntos := int(data.get("total_puntos", 0))
		var correctas := int(data.get("total_correctas", 0))
		var preguntas := int(data.get("total_preguntas", 0))
		var prom_estrellas := float(data.get("prom_estrellas", 0.0))

		var pct_aciertos := 0.0
		if preguntas > 0:
			pct_aciertos = (float(correctas) / float(preguntas)) * 100.0

		var item := arbol_alumnos.create_item(root)
		item.set_text(0, nombre)
		item.set_text(1, "Activo" if activo == 1 else "Inactivo")
		item.set_text(2, str(nivel))
		item.set_text(3, str(partidas))
		item.set_text(4, str(puntos))
		item.set_text(5, "%.1f estrs" % prom_estrellas)
		item.set_text(6, "%.1f%%" % pct_aciertos)
		item.set_metadata(0, id_alumno)

		if activo == 0:
			for col in range(7):
				item.set_custom_color(col, Color(0.55, 0.35, 0.35))

		total_alumnos += 1
		total_puntos_global += puntos
		if activo == 1:
			total_activos += 1

	label_resumen.text = (
		"Total: %d alumnos  |  Activos: %d  |  Inactivos: %d  |  Puntos acumulados: %d"
		% [total_alumnos, total_activos, total_alumnos - total_activos, total_puntos_global]
	)

func _refresh_auditoria(filtro_alumno: String = "") -> void:
	if db == null:
		texto_auditoria.text = "Sin conexion a base de datos."
		return

	var where_clause := "WHERE TX_TIPO_USUARIO = 'alumno'"
	if not filtro_alumno.is_empty():
		where_clause += " AND TX_USUARIO LIKE '%%%s%%'" % SQLiteHelper.escape(filtro_alumno)

	var query := "SELECT TX_USUARIO, TX_ACCION, TX_FECHA FROM actividad %s ORDER BY NU_ACT DESC LIMIT 250;" % where_clause
	var lineas: Array[String] = []
	lineas.append("AUDITORIA DE ESTUDIANTES")
	lineas.append("Docente: %s" % _docente_nombre)
	lineas.append("")

	if db.query(query) and not db.query_result.is_empty():
		for row in db.query_result:
			var usuario := str(row.get("TX_USUARIO", "desconocido"))
			var accion := str(row.get("TX_ACCION", "sin_accion"))
			var fecha := str(row.get("TX_FECHA", "sin_fecha"))
			lineas.append("- %s -> %s (%s)" % [usuario, accion, fecha])
	else:
		lineas.append("Sin acciones de estudiantes para mostrar.")

	texto_auditoria.text = "\n".join(lineas)

func _refresh_rendimiento_general() -> void:
	arbol_rendimiento_general.clear()
	var root := arbol_rendimiento_general.create_item()

	var query := (
		"SELECT a.NU_USU, a.NM_ALUMNO, a.NU_NIVEL_MAX, " +
		"COALESCE(nv.estrellas_niveles, 0) AS estrellas_niveles, " +
		"COALESCE(nv.puntos_niveles, 0) AS puntos_niveles, " +
		"COALESCE(nv.partidas_niveles, 0) AS partidas_niveles, " +
		"COALESCE(mj.estrellas_minijuegos, 0) AS estrellas_minijuegos " +
		"FROM Alumnos a " +
		"LEFT JOIN (" +
		"SELECT NU_USU, SUM(NU_ESTRELLAS) AS estrellas_niveles, SUM(NU_PUNTOS) AS puntos_niveles, COUNT(*) AS partidas_niveles " +
		"FROM niveles GROUP BY NU_USU" +
		") nv ON nv.NU_USU = a.NU_USU " +
		"LEFT JOIN (" +
		"SELECT NU_USU, SUM(NU_ESTRELLAS) AS estrellas_minijuegos FROM minijuegos_resultados GROUP BY NU_USU" +
		") mj ON mj.NU_USU = a.NU_USU " +
		"ORDER BY puntos_niveles DESC, a.NM_ALUMNO ASC;"
	)

	if not db.query(query) or db.query_result.is_empty():
		var vacio := arbol_rendimiento_general.create_item(root)
		vacio.set_text(0, "Sin rendimiento para mostrar.")
		return

	for row in db.query_result:
		var item := arbol_rendimiento_general.create_item(root)
		item.set_text(0, str(row.get("NM_ALUMNO", "sin_nombre")))
		item.set_text(1, str(int(row.get("NU_NIVEL_MAX", 0))))
		item.set_text(2, str(int(row.get("estrellas_niveles", 0))))
		item.set_text(3, str(int(row.get("estrellas_minijuegos", 0))))
		item.set_text(4, str(int(row.get("puntos_niveles", 0))))
		item.set_text(5, str(int(row.get("partidas_niveles", 0))))

	_refresh_selector_alumnos_detalle()

func _refresh_rendimiento_detalle() -> void:
	arbol_rendimiento_detalle.clear()
	var root := arbol_rendimiento_detalle.create_item()

	if selector_alumno_detalle.item_count == 0:
		return

	var alumno_id := selector_alumno_detalle.get_selected_id()
	if alumno_id < 0:
		var vacio := arbol_rendimiento_detalle.create_item(root)
		vacio.set_text(0, "Selecciona un alumno.")
		return

	var nivel_id := selector_nivel_detalle.get_selected_id()
	var where_nivel := "WHERE NU_USU = %d" % alumno_id
	if nivel_id > 0:
		where_nivel += " AND NU_NIVEL = %d" % nivel_id

	var niveles_query := "SELECT NU_NIVEL, NU_ESTRELLAS, NU_PUNTOS, NU_RESPC, NU_PREG FROM niveles %s ORDER BY NU_NIVEL ASC;" % where_nivel
	if db.query(niveles_query) and not db.query_result.is_empty():
		for row in db.query_result:
			var item_nivel := arbol_rendimiento_detalle.create_item(root)
			item_nivel.set_text(0, "Nivel")
			item_nivel.set_text(1, "Nivel %d" % int(row.get("NU_NIVEL", 0)))
			item_nivel.set_text(2, "%d/3" % int(row.get("NU_ESTRELLAS", 0)))
			item_nivel.set_text(3, str(int(row.get("NU_PUNTOS", 0))))
			item_nivel.set_text(4, "%d/%d aciertos" % [int(row.get("NU_RESPC", 0)), int(row.get("NU_PREG", 0))])
	else:
		var vacio_niveles := arbol_rendimiento_detalle.create_item(root)
		vacio_niveles.set_text(0, "Nivel")
		vacio_niveles.set_text(1, "Sin registros")

	var mini_query := "SELECT NM_MINIJUEGO, NU_ESTRELLAS, NU_PUNTOS, NU_INTENTOS FROM minijuegos_resultados WHERE NU_USU = %d ORDER BY NM_MINIJUEGO ASC;" % alumno_id
	if db.query(mini_query) and not db.query_result.is_empty():
		for row_mini in db.query_result:
			var item_mini := arbol_rendimiento_detalle.create_item(root)
			item_mini.set_text(0, "Minijuego")
			item_mini.set_text(1, str(row_mini.get("NM_MINIJUEGO", "-")))
			item_mini.set_text(2, str(int(row_mini.get("NU_ESTRELLAS", 0))))
			item_mini.set_text(3, str(int(row_mini.get("NU_PUNTOS", 0))))
			item_mini.set_text(4, "%d intentos" % int(row_mini.get("NU_INTENTOS", 0)))

	_refresh_logros(alumno_id)

func _refresh_logros(alumno_id: int) -> void:
	var query := "SELECT TX_LOGRO, FE_DESBLOQUEO FROM logros_alumno WHERE NU_USU = %d AND SW_DESBLOQUEADO = 1 ORDER BY FE_DESBLOQUEO DESC;" % alumno_id
	var lineas: Array[String] = []
	lineas.append("LOGROS DEL ALUMNO")

	if db.query(query) and not db.query_result.is_empty():
		for row in db.query_result:
			var logro := str(row.get("TX_LOGRO", "sin_logro"))
			var fecha := str(row.get("FE_DESBLOQUEO", "sin_fecha"))
			lineas.append("- %s (%s)" % [logro, fecha])
	else:
		var query_fallback := "SELECT COUNT(*) AS niveles, SUM(CASE WHEN NU_ESTRELLAS = 3 THEN 1 ELSE 0 END) AS perfectos FROM niveles WHERE NU_USU = %d;" % alumno_id
		if db.query(query_fallback) and not db.query_result.is_empty():
			var niveles := int(str(db.query_result[0].get("niveles", 0)))
			var perfectos := int(str(db.query_result[0].get("perfectos", 0)))
			if niveles > 0:
				lineas.append("- Explorador Historico (completo al menos un nivel)")
			if perfectos >= 3:
				lineas.append("- Maestro de 3 Estrellas (%d niveles perfectos)" % perfectos)
			if perfectos == 0 and niveles > 0:
				lineas.append("- En progreso: aun sin nivel perfecto")
			if niveles == 0:
				lineas.append("- Sin logros registrados.")
		else:
			lineas.append("- Sin logros registrados.")

	texto_logros.text = "\n".join(lineas)

func _on_btn_canvas_gestion_pressed() -> void:
	_set_vista(VistaDocente.GESTION)

func _on_btn_canvas_auditoria_pressed() -> void:
	_set_vista(VistaDocente.AUDITORIA)

func _on_btn_canvas_rendimiento_pressed() -> void:
	_set_vista(VistaDocente.RENDIMIENTO)

func _on_btn_actualizar_pressed() -> void:
	if _vista_actual == VistaDocente.GESTION:
		_refresh_gestion(filtro_input.text.strip_edges())
	elif _vista_actual == VistaDocente.AUDITORIA:
		_refresh_auditoria(input_filtro_auditoria.text.strip_edges())
	else:
		_refresh_rendimiento_general()
		_refresh_rendimiento_detalle()

func _on_filtro_text_submitted(new_text: String) -> void:
	_refresh_gestion(new_text.strip_edges())

func _on_arbol_alumnos_item_selected() -> void:
	var item := arbol_alumnos.get_selected()
	if item == null:
		return

	var alumno_id := int(item.get_metadata(0))
	if alumno_id <= 0:
		return

	var query := "SELECT NM_ALUMNO, CO_PSW FROM Alumnos WHERE NU_USU = %d LIMIT 1;" % alumno_id
	if not db.query(query) or db.query_result.is_empty():
		return

	var row: Dictionary = db.query_result[0]
	_alumno_seleccionado_id = alumno_id
	label_alumno_seleccionado.text = "Alumno seleccionado: %s (ID %d)" % [str(row.get("NM_ALUMNO", "-")), alumno_id]
	input_editar_usuario.text = str(row.get("NM_ALUMNO", ""))
	input_editar_clave.text = str(row.get("CO_PSW", ""))
	label_estado_edicion.text = ""

func _on_btn_guardar_edicion_pressed() -> void:
	if _alumno_seleccionado_id <= 0:
		_set_estado_edicion("Selecciona un alumno desde la tabla.", Color(0.85, 0.52, 0.08))
		return

	var nuevo_usuario := input_editar_usuario.text.strip_edges()
	var nueva_clave := input_editar_clave.text.strip_edges()

	if nuevo_usuario.is_empty() or nueva_clave.is_empty():
		_set_estado_edicion("Usuario y clave son obligatorios.", Color(0.9, 0.2, 0.2))
		return

	if nuevo_usuario.length() < 4 or nueva_clave.length() < 4:
		_set_estado_edicion("Usuario y clave deben tener al menos 4 caracteres.", Color(0.9, 0.2, 0.2))
		return

	var update_query := "UPDATE Alumnos SET NM_ALUMNO = '%s', CO_PSW = '%s' WHERE NU_USU = %d;" % [
		SQLiteHelper.escape(nuevo_usuario),
		SQLiteHelper.escape(nueva_clave),
		_alumno_seleccionado_id
	]

	if db.query(update_query):
		SQLiteHelper.log_activity(db, "docente", _docente_nombre, "edito_alumno:%d" % _alumno_seleccionado_id)
		_set_estado_edicion("Datos actualizados correctamente.", Color(0.15, 0.6, 0.25))
		_refresh_gestion(filtro_input.text.strip_edges())
		_refresh_selector_alumnos_detalle()
	else:
		_set_estado_edicion("No se pudo actualizar. Verifica que el usuario no exista.", Color(0.9, 0.2, 0.2))

func _on_btn_actualizar_auditoria_pressed() -> void:
	_refresh_auditoria(input_filtro_auditoria.text.strip_edges())

func _on_btn_actualizar_rendimiento_pressed() -> void:
	_refresh_rendimiento_general()
	_refresh_rendimiento_detalle()

func _on_selector_alumno_detalle_item_selected(_index: int) -> void:
	_refresh_rendimiento_detalle()

func _on_selector_nivel_detalle_item_selected(_index: int) -> void:
	_refresh_rendimiento_detalle()

func _on_btn_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Login.tscn")

func _set_estado_edicion(mensaje: String, color: Color) -> void:
	label_estado_edicion.text = mensaje
	label_estado_edicion.modulate = color
