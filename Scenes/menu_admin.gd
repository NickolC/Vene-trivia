extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")
const ReporteDocente = preload("res://Scripts/reporte_docente.gd")

enum VistaDocente {
	GESTION,
	AUDITORIA,
	RENDIMIENTO
}

var _btn_reporte_general: Button
var _btn_reporte_alumno: Button

const LISTA_MINIJUEGOS = ["Sopa de Letras", "Memoria", "RelacionColumnas", "VerdaderoFalso", "CompletarFrases", "Ahorcado"]

const MAPEO_RECURSOS_MINIJUEGOS := {
	"Sopa de Letras": {"icono": "res://GFX/Minijuegos/Sopa.png", "titulo": "SOPA DE LETRAS"},
	"Memoria": {"icono": "res://GFX/Minijuegos/Memoria.png", "titulo": "MEMORIA"},
	"RelacionColumnas": {"icono": "res://GFX/Minijuegos/Columnas.png", "titulo": "COLUMNAS"},
	"VerdaderoFalso": {"icono": "res://GFX/Minijuegos/TrueorFalse.png", "titulo": "VERDADERO O FALSO"},
	"CompletarFrases": {"icono": "res://GFX/Minijuegos/Completar.png", "titulo": "COMPLETAR FRASES"},
	"Ahorcado": {"icono": "res://GFX/Minijuegos/Ahorcado.png", "titulo": "AHORCADO"}
}

# RUTAS DE TUS RECURSOS PERSONALIZADOS (Ajusta la extensión o carpeta si es necesario)
const RUTA_FUENTE_CUSTOM = "res://font/Minecraft.ttf"
const RUTA_CHECK_CUSTOM = "res://GFX/switch de prendido.png" # Icono propio para los interruptores/checks
const RUTA_CHECK_CUSTOM2 = "res://GFX/switch de desactivado.png" # Icono propio para los interruptores/checks

var db: SQLite
var _docente_nombre: String = ""
var _vista_actual: int = VistaDocente.GESTION
var _alumno_seleccionado_id: int = -1

var _cambios_temporales_bloqueo: Dictionary = {}

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

@onready var contenedor_bloqueos_minijuegos: VBoxContainer = $MainPanel/Margin/VBox/PanelEdicion/Margin/EdicionVBox/VBoxContainer

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
	
	# Damos un pequeño respiro al motor de SQLite para que libere bloqueos
	await get_tree().process_frame 
	SQLiteHelper.log_activity(db, "docente", _docente_nombre, "inicio_sesion")
	
	SQLiteHelper.ensure_alumnos_activo_column(db)
	SQLiteHelper.ensure_minijuegos_table(db)
	SQLiteHelper.ensure_logros_table(db)
	
	_asegurar_tabla_bloqueos_minijuegos()
	_tiempoactividad()
	
	_docente_nombre = GlobalUsuario.nombre_alumno
	SQLiteHelper.log_activity(db, "docente", _docente_nombre, "acceso_panel_docente")

	_setup_tree_gestion()
	_setup_tree_rendimiento_general()
	_setup_tree_rendimiento_detalle()
	_setup_selectores_detalle()
	_set_vista(VistaDocente.GESTION)
	_agregar_botones_reporte()
	_agregar_boton_crear_nivel()

	arbol_alumnos.item_selected.connect(_on_arbol_alumnos_item_selected) # Un clic
	arbol_alumnos.item_activated.connect(_on_alumnos_seleccionado) # Doble clic


func _on_alumno_seleccionado() -> void:
	# 1. Obtenemos el elemento utilizando la variable real 'arbol_alumnos'
	var item: TreeItem = arbol_alumnos.get_selected()
	if not item:
		return
	
	# 2. Extraemos el ID del alumno desde sus metadatos
	var alumno_id: int = int(item.get_metadata(0)) 
	
	# 3. Validamos que el ID sea correcto y llamamos al panel
	if alumno_id > 0:
		_crear_y_mostrar_panel_bloqueos(alumno_id)
	else:
		print("Error: No se pudo recuperar un ID de alumno válido de esta fila.")

func _exit_tree() -> void:
	SQLiteHelper.close_db_connection(db)

func _asegurar_tabla_bloqueos_minijuegos() -> void:
	if db == null: return
	var query := "CREATE TABLE IF NOT EXISTS minijuegos_bloqueos (
		NU_USU INTEGER,
		TX_MINIJUEGO TEXT,
		SW_BLOQUEADO INTEGER DEFAULT 0,
		PRIMARY KEY(NU_USU, TX_MINIJUEGO)
	);"
	db.query(query)

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

	# --- CONTROL DE VISIBILIDAD DE REPORTES ---
	# Reporte General: visible ÚNICAMENTE en Gestión
	if _btn_reporte_general:
		_btn_reporte_general.visible = es_gestion

	# Reporte Alumno: visible ÚNICAMENTE en Rendimiento
	if _btn_reporte_alumno:
		_btn_reporte_alumno.visible = es_rendimiento
	# ------------------------------------------

	if es_gestion:
		_refresh_gestion(filtro_input.text.strip_edges())
	elif es_auditoria:
		_refresh_auditoria(input_filtro_auditoria.text.strip_edges())
	else:
		_refresh_rendimiento_general()
		_refresh_rendimiento_detalle()

# REP-02/03: formatea segundos a mm:ss para columnas de tiempo de los arboles.
func _fmt_seg(t) -> String:
	var seg := float(t) if t != null else 0.0
	if seg <= 0.0:
		return "--:--"
	var total := int(round(seg))
	return "%02d:%02d" % [total / 60, total % 60]

func _setup_tree_gestion() -> void:
	arbol_alumnos.columns = 8
	arbol_alumnos.column_titles_visible = true
	arbol_alumnos.hide_root = true
	arbol_alumnos.set_column_title(0, "Alumno")
	arbol_alumnos.set_column_title(1, "Estado")
	arbol_alumnos.set_column_title(2, "Nivel")
	arbol_alumnos.set_column_title(3, "Partidas")
	arbol_alumnos.set_column_title(4, "Puntos")
	arbol_alumnos.set_column_title(5, "Estrellas")
	arbol_alumnos.set_column_title(6, "Aciertos %")
	arbol_alumnos.set_column_title(7, "Tiempo total")

func _setup_tree_rendimiento_general() -> void:
	arbol_rendimiento_general.columns = 7
	arbol_rendimiento_general.column_titles_visible = true
	arbol_rendimiento_general.hide_root = true
	arbol_rendimiento_general.set_column_title(0, "Alumno")
	arbol_rendimiento_general.set_column_title(1, "Nivel max")
	arbol_rendimiento_general.set_column_title(2, "Estrellas niveles")
	arbol_rendimiento_general.set_column_title(3, "Estrellas minijuegos")
	arbol_rendimiento_general.set_column_title(4, "Puntos niveles")
	arbol_rendimiento_general.set_column_title(5, "Partidas")
	arbol_rendimiento_general.set_column_title(6, "Tiempo total")

func _setup_tree_rendimiento_detalle() -> void:
	arbol_rendimiento_detalle.columns = 6
	arbol_rendimiento_detalle.column_titles_visible = true
	arbol_rendimiento_detalle.hide_root = true
	arbol_rendimiento_detalle.set_column_title(0, "Tipo")
	arbol_rendimiento_detalle.set_column_title(1, "Nombre")
	arbol_rendimiento_detalle.set_column_title(2, "Estrellas")
	arbol_rendimiento_detalle.set_column_title(3, "Puntos")
	arbol_rendimiento_detalle.set_column_title(4, "Extra")
	arbol_rendimiento_detalle.set_column_title(5, "Tiempo 
	")

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
		"COALESCE(AVG(CAST(n.NU_ESTRELLAS AS REAL)), 0.0) AS prom_estrellas, " +
		"(SELECT COALESCE(SUM(tn.TIEMPOTOTAL_SEGUNDOS),0) FROM tiempos_niveles tn WHERE tn.NU_USU = a.NU_USU AND tn.TX_TIPO_NIVEL = 'TRIVIA') AS tiempo_total " +
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
		item.set_text(7, _fmt_seg(data.get("tiempo_total", 0.0)))
		item.set_metadata(0, id_alumno)

		if activo == 0:
			for col in range(8):
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
		"COALESCE(mj.estrellas_minijuegos, 0) AS estrellas_minijuegos, " +
		"(SELECT COALESCE(SUM(tn.TIEMPOTOTAL_SEGUNDOS),0) FROM tiempos_niveles tn WHERE tn.NU_USU = a.NU_USU AND tn.TX_TIPO_NIVEL = 'TRIVIA') AS tiempo_total " +
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
		item.set_text(6, _fmt_seg(row.get("tiempo_total", 0.0)))

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
	var where_nivel := "WHERE n.NU_USU = %d" % alumno_id
	if nivel_id > 0:
		where_nivel += " AND n.NU_NIVEL = %d" % nivel_id

	var niveles_query := """
	SELECT n.NU_NIVEL, n.NU_ESTRELLAS, n.NU_PUNTOS, n.NU_RESPC, n.NU_PREG, t.TIEMPOTOTAL_SEGUNDOS 
	FROM niveles n LEFT JOIN tiempos_niveles t ON n.NU_NIVEL = t.NU_NIVEL and n.NU_USU = t.NU_USU %s 
	ORDER BY n.NU_NIVEL ASC;
	""" % where_nivel
	
	if db.query(niveles_query) and not db.query_result.is_empty():
		for row in db.query_result:
			var item_nivel := arbol_rendimiento_detalle.create_item(root)
			item_nivel.set_text(0, "Nivel")
			item_nivel.set_text(1, "Nivel %d" % int(row.get("NU_NIVEL", 0)))
			item_nivel.set_text(2, "%d/3" % int(row.get("NU_ESTRELLAS", 0)))
			item_nivel.set_text(3, str(int(row.get("NU_PUNTOS", 0))))
			item_nivel.set_text(4, "%d/%d aciertos" % [int(row.get("NU_RESPC", 0)), int(row.get("NU_PREG", 0))])
			# PROCESAR TIEMPO
			var tiempo = row.get("TIEMPOTOTAL_SEGUNDOS", 0.0)
			if tiempo != null and tiempo > 0:
				var mins = int(tiempo) / 60
				var secs = int(tiempo) % 60
				item_nivel.set_text(5, "%02d:%02d" % [mins, secs])
			else:
				item_nivel.set_text(5, "--:--")
	else:
		var vacio_niveles := arbol_rendimiento_detalle.create_item(root)
		vacio_niveles.set_text(0, "Nivel")
		vacio_niveles.set_text(1, "Sin registros")

	var mini_query := "SELECT NM_MINIJUEGO, NU_ESTRELLAS, NU_PUNTOS, NU_INTENTOS, COALESCE(NU_MEJOR_TIEMPO,0) AS mejor_t FROM minijuegos_resultados WHERE NU_USU = %d ORDER BY NM_MINIJUEGO ASC;" % alumno_id
	if db.query(mini_query) and not db.query_result.is_empty():
		for row_mini in db.query_result:
			var item_mini := arbol_rendimiento_detalle.create_item(root)
			item_mini.set_text(0, "Minijuego")
			item_mini.set_text(1, str(row_mini.get("NM_MINIJUEGO", "-")))
			item_mini.set_text(2, str(int(row_mini.get("NU_ESTRELLAS", 0))))
			item_mini.set_text(3, str(int(row_mini.get("NU_PUNTOS", 0))))
			item_mini.set_text(4, "%d intentos" % int(row_mini.get("NU_INTENTOS", 0)))
			# REP-02/03: mejor tiempo del minijuego
			item_mini.set_text(5, _fmt_seg(row_mini.get("mejor_t", 0.0)))

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
	
	var btn_abrir = contenedor_bloqueos_minijuegos.get_node_or_null("BtnAbrirBloqueos")
	if btn_abrir:
		btn_abrir.disabled = false
		
	# LÍNEA ELIMINADA / COMENTADA: 
	# Al quitar esta línea, el panel ya no se abrirá con un solo clic.
	# _crear_y_mostrar_panel_bloqueos(alumno_id)

func _on_alumnos_seleccionado() -> void:
	# 1. Obtenemos el elemento utilizando la variable real 'arbol_alumnos'
	var item: TreeItem = arbol_alumnos.get_selected()
	if not item:
		return
	
	# 2. Extraemos el ID del alumno desde sus metadatos
	var alumno_id: int = int(item.get_metadata(0)) 
	
	# 3. Validamos que el ID sea correcto y llamamos al panel
	if alumno_id > 0:
		# ESTA ES LA QUE SE EJECUTA CON EL DOBLE CLIC
		_crear_y_mostrar_panel_bloqueos(alumno_id)
	else:
		print("Error: No se pudo recuperar un ID de alumno válido de esta fila.")

func _reconfigurar_contenedor_lateral_para_boton_emergente() -> void:
	if contenedor_bloqueos_minijuegos == null: return
	for hijo in contenedor_bloqueos_minijuegos.get_children():
		hijo.queue_free()
		
	var btn_abrir_popup := Button.new()
	btn_abrir_popup.name = "BtnAbrirBloqueos"
	btn_abrir_popup.text = "Configurar Minijuegos ⚙"
	btn_abrir_popup.custom_minimum_size = Vector2(0, 45)
	btn_abrir_popup.disabled = true # Desactivado hasta seleccionar un alumno
	btn_abrir_popup.pressed.connect(_on_btn_abrir_popup_pressed)
	contenedor_bloqueos_minijuegos.add_child(btn_abrir_popup)

func _on_btn_abrir_popup_pressed() -> void:
	if _alumno_seleccionado_id <= 0: return
	_crear_y_mostrar_panel_bloqueos(_alumno_seleccionado_id)

func _crear_y_mostrar_panel_bloqueos(alumno_id: int) -> void:
	# Si ya existe un panel previo por seguridad, lo eliminamos
	var antiguo_panel = get_node_or_null("CapaSuperpuestaBloqueos")
	if antiguo_panel: antiguo_panel.queue_free()

	# 1. Contenedor Raíz de la capa de superposición (Oscurece el fondo levemente)
	var capa_fondo := PanelContainer.new()
	capa_fondo.name = "CapaSuperpuestaBloqueos"
	capa_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var estilo_fondo := StyleBoxFlat.new()
	estilo_fondo.bg_color = Color(0, 0, 0, 0.55) # Fondo oscuro semi-transparente
	capa_fondo.add_theme_stylebox_override("panel", estilo_fondo)

	# 2. Ventana de Diálogo Central
	var panel_central := PanelContainer.new()
	panel_central.custom_minimum_size = Vector2(750, 620)
	panel_central.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel_central.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var estilo_ventana := StyleBoxFlat.new()
	estilo_ventana.bg_color = Color(0.18, 0.18, 0.22, 1.0)
	estilo_ventana.border_width_left = 3
	estilo_ventana.border_width_top = 3
	estilo_ventana.border_width_right = 3
	estilo_ventana.border_width_bottom = 3
	estilo_ventana.border_color = Color(0.4, 0.4, 0.45, 1.0)
	estilo_ventana.corner_radius_top_left = 8
	estilo_ventana.corner_radius_top_right = 8
	estilo_ventana.corner_radius_bottom_right = 8
	estilo_ventana.corner_radius_bottom_left = 8
	panel_central.add_theme_stylebox_override("panel", estilo_ventana)
	capa_fondo.add_child(panel_central)

	# Margen interior de la ventana
	var margin_container := MarginContainer.new()
	margin_container.add_theme_constant_override("margin_top", 16)
	margin_container.add_theme_constant_override("margin_bottom", 16)
	margin_container.add_theme_constant_override("margin_left", 20)
	margin_container.add_theme_constant_override("margin_right", 20)
	panel_central.add_child(margin_container)

	var vbox_principal := VBoxContainer.new()
	vbox_principal.add_theme_constant_override("separation", 14)
	margin_container.add_child(vbox_principal)

	# 3. TÍTULO DEL PANEL
	var lbl_titulo := Label.new()
	lbl_titulo.text = "HABILITACIÓN O DESHABILITACIÓN DE MINIJUEGOS"
	_aplicar_estilo_texto_custom(lbl_titulo, 40, true, Color.WHITE, Color.BLACK)
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_principal.add_child(lbl_titulo)

	# Separador visual line
	var line_sep := ColorRect.new()
	line_sep.custom_minimum_size = Vector2(0, 2)
	line_sep.color = Color(0.5, 0.5, 0.5, 0.4)
	vbox_principal.add_child(line_sep)

	# Contenedor con Scroll para albergar la lista de minijuegos ordenadamente
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_principal.add_child(scroll)

	var grid_minijuegos := VBoxContainer.new()
	grid_minijuegos.add_theme_constant_override("separation", 10)
	grid_minijuegos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid_minijuegos)

	# Buscar estado actual de bloqueos en base de datos para inicializar el diccionario temporal
	_cambios_temporales_bloqueo.clear()
	var bloqueos_activos := {}
	var query := "SELECT TX_MINIJUEGO, SW_BLOQUEADO FROM minijuegos_bloqueos WHERE NU_USU = %d;" % alumno_id
	if db.query(query) and not db.query_result.is_empty():
		for row in db.query_result:
			bloqueos_activos[str(row.get("TX_MINIJUEGO", ""))] = int(row.get("SW_BLOQUEADO", 0))

	# Cargar fuente e icono personalizado si existen
	var fuente_personalizada = load(RUTA_FUENTE_CUSTOM) if ResourceLoader.exists(RUTA_FUENTE_CUSTOM) else null
	var icono_check_personalizado = load(RUTA_CHECK_CUSTOM) if ResourceLoader.exists(RUTA_CHECK_CUSTOM) else null
	var icono_check_personalizado2 = load(RUTA_CHECK_CUSTOM2) if ResourceLoader.exists(RUTA_CHECK_CUSTOM2) else null

	# 4. ITERACIÓN PARA CONSTRUIR CADA COMPONENTE DE MINIJUEGO
	for nombre_minijuego in LISTA_MINIJUEGOS:
		var datos_recurso = MAPEO_RECURSOS_MINIJUEGOS.get(nombre_minijuego, {"icono": "", "titulo": nombre_minijuego.to_upper()})
		var esta_bloqueado = bloqueos_activos.get(nombre_minijuego, 0) == 1
		
		# Guardamos en nuestra caché el estado actual inicial
		_cambios_temporales_bloqueo[nombre_minijuego] = esta_bloqueado

		# HBox para la fila del minijuego
		var hbox_fila := HBoxContainer.new()
		hbox_fila.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox_fila.add_theme_constant_override("separation", 15)
		
		# Estilo de fondo sutil por fila
		var p_fila := PanelContainer.new()
		var st_fila := StyleBoxFlat.new()
		st_fila.bg_color = Color(1, 1, 1, 0.03)
		st_fila.set_corner_radius_all(4)
		p_fila.add_theme_stylebox_override("panel", st_fila)
		p_fila.add_child(hbox_fila)
		grid_minijuegos.add_child(p_fila)

		# A. Miniatura / Imagen del Minijuego
		var tex_rect := TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(180, 180)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		if ResourceLoader.exists(datos_recurso["icono"]):
			tex_rect.texture = load(datos_recurso["icono"])
		hbox_fila.add_child(tex_rect)

		# Contenedor del Nombre del minijuego + Estado entre paréntesis
		var vbox_texto := VBoxContainer.new()
		vbox_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_texto.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox_fila.add_child(vbox_texto)

		var lbl_nombre_juego := Label.new()
		lbl_nombre_juego.text = str(datos_recurso["titulo"])
		_aplicar_estilo_texto_custom(lbl_nombre_juego, 35, false, Color.WHITE, Color.BLACK)
		vbox_texto.add_child(lbl_nombre_juego)

		var lbl_estado_parentesis := Label.new()
		lbl_estado_parentesis.text = "(Activo)" if not esta_bloqueado else "(Inactivo)"
		
		# 🌟 SOLUCIÓN: Definimos la variable col_fuente localmente antes de usarla
		var col_fuente := Color(0.12, 0.73, 0.28, 1.0) if not esta_bloqueado else Color(0.85, 0.18, 0.18, 1.0)
		
		_aplicar_estilo_texto_custom(lbl_estado_parentesis, 25, false, col_fuente, Color.BLACK)
		lbl_estado_parentesis.modulate = Color(0.3, 0.85, 0.4) if not esta_bloqueado else Color(0.85, 0.3, 0.3)
		vbox_texto.add_child(lbl_estado_parentesis)

		# B. Interruptor CheckButton
		var check_btn := CheckButton.new()
		check_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		check_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		
		# Lógica Inversa: Activado significa acceso permitido (no bloqueado)
		check_btn.button_pressed = not esta_bloqueado

		# Aplicar icono propio si se suministró la ruta
		if icono_check_personalizado:
			check_btn.add_theme_icon_override("checked", icono_check_personalizado)
			check_btn.add_theme_icon_override("unchecked", icono_check_personalizado2)

		# Conectamos el cambio del interruptor a la caché de cambios locales temporales
		check_btn.toggled.connect(func(esta_activo: bool):
			var actual_bloqueado = not esta_activo
			_cambios_temporales_bloqueo[nombre_minijuego] = actual_bloqueado
			
			# Modificar dinámicamente el texto aclaratorio del paréntesis al interactuar
			lbl_estado_parentesis.text = "(Activo)" if esta_activo else "(Inactivo)"
			lbl_estado_parentesis.modulate = Color(0.3, 0.85, 0.4) if esta_activo else Color(0.85, 0.3, 0.3)
		)
		hbox_fila.add_child(check_btn)

	# Barra de botones inferiores (Guardar y Salir)
	var hbox_botones := HBoxContainer.new()
	hbox_botones.add_theme_constant_override("separation", 20)
	hbox_botones.alignment = HBoxContainer.ALIGNMENT_CENTER
	vbox_principal.add_child(hbox_botones)

	# BOTÓN SALIR (Auto-guarda los cambios y destruye la interfaz flotante)
	var btn_salir := Button.new()
	btn_salir.text = "Guardar Permisos"
	btn_salir.custom_minimum_size = Vector2(200, 42)
	btn_salir.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_salir.pressed.connect(func():
		_procesar_guardado_masivo_base_datos(alumno_id)
		capa_fondo.queue_free() # Cierra el panel volviendo a la pantalla principal
	)
	hbox_botones.add_child(btn_salir)

	# Finalmente añadimos la gran capa sobre el nodo principal de la escena actual
	add_child(capa_fondo)

func _aplicar_estilo_texto_custom(lbl: Label, tamano: int, es_titulo: bool, color_texto: Color, color_contorno: Color) -> void:
	# Cargar fuente personalizada dinámica
	if ResourceLoader.exists(RUTA_FUENTE_CUSTOM):
		lbl.add_theme_font_override("font", load(RUTA_FUENTE_CUSTOM))
	
	lbl.add_theme_font_size_override("font_size", tamano)
	
	# Color de la letra y del contorno personalizados de manera dinámica
	lbl.add_theme_color_override("font_color", color_texto)
	lbl.add_theme_color_override("font_outline_color", color_contorno)
	lbl.add_theme_constant_override("outline_size", 5 if es_titulo else 3)

func _procesar_guardado_masivo_base_datos(alumno_id: int) -> void:
	if db == null:
		_set_estado_edicion("Fallo de conexión.", Color(0.9, 0.2, 0.2))
		return

	# INICIAR TRANSACCIÓN
	db.query("BEGIN TRANSACTION;")
	var error_detectado := false
	for minijuego in _cambios_temporales_bloqueo.keys():
		var bloquear: bool = _cambios_temporales_bloqueo[minijuego]
		var valor_bloqueo := 1 if bloquear else 0
		var query := "REPLACE INTO minijuegos_bloqueos (NU_USU, TX_MINIJUEGO, SW_BLOQUEADO) VALUES (%d, '%s', %d);" % [
			alumno_id, SQLiteHelper.escape(minijuego), valor_bloqueo
		]
		if not db.query(query):
			error_detectado = true
			break # Salir si algo falla
		else:
			var accion_log = "panel de minijuegos bloqueo" # Tu lógica de log aquí

	# FINALIZAR TRANSACCIÓN
	if not error_detectado:
		db.query("COMMIT;")
		_set_estado_edicion("Todos los permisos de minijuegos aplicados con éxito.", Color(0.15, 0.6, 0.25))
	else:
		db.query("ROLLBACK;")
		_set_estado_edicion("Errores parciales al guardar permisos en la Base de Datos.", Color(0.9, 0.2, 0.2))

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

	db.query("BEGIN TRANSACTION;")
	var update_query := "UPDATE Alumnos SET NM_ALUMNO = '%s', CO_PSW = '%s' WHERE NU_USU = %d;" % [
		SQLiteHelper.escape(nuevo_usuario),
		SQLiteHelper.escape(nueva_clave),
		_alumno_seleccionado_id
	]

	if db.query(update_query):
		db.query("COMMIT;")
		SQLiteHelper.log_activity(db, "docente", _docente_nombre, "edito_alumno:%d" % _alumno_seleccionado_id)
		_set_estado_edicion("Datos actualizados correctamente.", Color(0.15, 0.6, 0.25))
		_refresh_gestion(filtro_input.text.strip_edges())
		_refresh_selector_alumnos_detalle()
	else:
		db.query("ROLLBACK;")
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

func _agregar_botones_reporte() -> void:
	var navbar := get_node_or_null("MainPanel/Margin/VBox/NavBar")
	if navbar == null: return
	
	# Guardamos la referencia en la variable global del script
	_btn_reporte_general = Button.new()
	_btn_reporte_general.text = "REPORTE GENERAL"
	_estilizar_boton_reporte(_btn_reporte_general)
	_btn_reporte_general.pressed.connect(_on_btn_reporte_general_pressed)
	navbar.add_child(_btn_reporte_general)
	
	# Guardamos la referencia en la variable global del script
	_btn_reporte_alumno = Button.new()
	_btn_reporte_alumno.text = "REPORTE ALUMNO"
	_estilizar_boton_reporte(_btn_reporte_alumno)
	_btn_reporte_alumno.pressed.connect(_on_btn_reporte_alumno_pressed)
	navbar.add_child(_btn_reporte_alumno)

func _estilizar_boton_reporte(btn: Button) -> void:
	btn.clip_contents = true
	btn.custom_minimum_size = Vector2(220, 48)
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(0.12, 0.12, 0.12, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.08, 0.08, 0.08, 1.0))
	btn.add_theme_color_override("font_disabled_color", Color(0.56, 0.47, 0.40, 0.85))

	var font := btn_canvas_rendimiento.get_theme_font("font")
	if font:
		btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 20)

	btn.add_theme_stylebox_override("normal", _crear_stylebox_reporte(Color(0.882, 0.702, 0.490, 1.0), Color(0.506, 0.286, 0.231, 0.90)))
	btn.add_theme_stylebox_override("hover", _crear_stylebox_reporte(Color(0.925, 0.760, 0.560, 1.0), Color(0.506, 0.286, 0.231, 1.0)))
	btn.add_theme_stylebox_override("pressed", _crear_stylebox_reporte(Color(0.790, 0.610, 0.430, 1.0), Color(0.400, 0.220, 0.170, 1.0)))
	btn.add_theme_stylebox_override("disabled", _crear_stylebox_reporte(Color(0.860, 0.790, 0.690, 0.95), Color(0.580, 0.470, 0.390, 0.70)))

func _crear_stylebox_reporte(color_fondo: Color, color_borde: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color_fondo
	estilo.border_width_left = 2
	estilo.border_width_top = 2
	estilo.border_width_right = 2
	estilo.border_width_bottom = 2
	estilo.border_color = color_borde
	estilo.corner_radius_top_left = 6
	estilo.corner_radius_top_right = 6
	estilo.corner_radius_bottom_right = 6
	estilo.corner_radius_bottom_left = 6
	return estilo

func _on_btn_reporte_general_pressed() -> void:
	if db == null:
		Alertas.mostrar_alerta("Sin conexion a la base de datos.", 2.0)
		return
	var html := ReporteDocente.generar_general(db)
	ReporteDocente.guardar_y_abrir(html, "reporte_general.html")
	Alertas.mostrar_alerta("Reporte general generado (HTML + PDF).", 2.0)
	SQLiteHelper.log_activity(db, "docente", _docente_nombre, "genero_reporte_general")

func _on_btn_reporte_alumno_pressed() -> void:
	if db == null:
		Alertas.mostrar_alerta("Sin conexion a la base de datos.", 2.0)
		return
	var alumno_id := -1
	var alumno_nombre := ""

	if _alumno_seleccionado_id > 0:
		alumno_id = _alumno_seleccionado_id
		db.query("SELECT NM_ALUMNO FROM Alumnos WHERE NU_USU = %d LIMIT 1;" % alumno_id)
		if not db.query_result.is_empty():
			alumno_nombre = str(db.query_result[0].get("NM_ALUMNO", "alumno"))
	else:
		var sel_id := selector_alumno_detalle.get_selected_id()
		if sel_id > 0:
			alumno_id = sel_id
			alumno_nombre = selector_alumno_detalle.get_item_text(selector_alumno_detalle.get_selected())

	if alumno_id <= 0:
		Alertas.mostrar_alerta("Selecciona un alumno primero.", 2.0)
		return

	var html := ReporteDocente.generar_por_alumno(db, alumno_id, alumno_nombre)
	var archivo := "reporte_%s.html" % alumno_nombre.to_lower().replace(" ", "_")
	ReporteDocente.guardar_y_abrir(html, archivo)
	Alertas.mostrar_alerta("Reporte de %s generado (HTML + PDF)." % alumno_nombre, 2.0)
	SQLiteHelper.log_activity(db, "docente", _docente_nombre, "genero_reporte_alumno:%d" % alumno_id)

var _preguntas_temporales: Array = []
var _numero_nivel_nuevo: int = 16 # Se podría consultar dinámicamente el último nivel existente

func _agregar_boton_crear_nivel() -> void:
	var navbar := get_node_or_null("MainPanel/Margin/VBox/NavBar")
	if navbar:
		var btn := Button.new()
		btn.text = "CREAR NIVEL"
		_estilizar_boton_reporte(btn) # Usamos tu estilo existente
		btn.pressed.connect(_abrir_panel_creacion_nivel)
		navbar.add_child(btn)
	
	var navbar2 := get_node_or_null("MainPanel/Margin/VBox/NavBar")
	if navbar:
		var btn_editar := Button.new()
		btn_editar.text = "EDITAR NIVEL"
		_estilizar_boton_reporte(btn_editar)
		btn_editar.pressed.connect(_abrir_buscador_archivos)
		navbar.add_child(btn_editar)

func _abrir_panel_creacion_nivel(ruta_archivo: String = "") -> void:
	if ruta_archivo == "": _preguntas_temporales = []
	
	# 1. Overlay y Panel
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 700)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.15, 0.15, 0.2)
	estilo.set_border_width_all(2)
	estilo.border_color = Color.WHITE
	estilo.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", estilo)
	center.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	# Campos
	var txt_pregunta := LineEdit.new(); txt_pregunta.placeholder_text = "Pregunta"
	
	var txt_tipo := Label.new() 
	txt_tipo.text = "Tipo de pregunta: Texto"
	txt_tipo.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	# Se eliminó txt_tipo.editable = false porque los Label no lo necesitan ni lo soportan
	
	# SOLUCIÓN AL ERROR: Declarar explícitamente que es un arreglo de LineEdit
	var opciones: Array[LineEdit] = []
	for i in range(4):
		var le := LineEdit.new()
		le.placeholder_text = "Opción %d" % (i + 1)
		vbox.add_child(le)
		opciones.append(le)
	
	var opt_correcta := OptionButton.new()
	for i in range(4): opt_correcta.add_item("Correcta: Opción %d" % (i + 1), i)
	
	var txt_expl := TextEdit.new(); txt_expl.custom_minimum_size.y = 60; txt_expl.placeholder_text = "Explicación"
	var txt_dato := TextEdit.new(); txt_dato.custom_minimum_size.y = 60; txt_dato.placeholder_text = "Dato Curioso (Opcional)"
	var lbl_contador := Label.new(); lbl_contador.text = "Preguntas guardadas: %d/15" % _preguntas_temporales.size()
	
	vbox.add_child(txt_pregunta); vbox.add_child(txt_tipo); vbox.add_child(opt_correcta)
	vbox.add_child(txt_expl); vbox.add_child(txt_dato); vbox.add_child(lbl_contador)
	
	# Botones
	var btn_guardar := Button.new(); btn_guardar.text = "Guardar Pregunta"
	var btn_crear := Button.new(); btn_crear.text = "CREAR NIVEL"
	if btn_crear:
		btn_crear.disabled = _preguntas_temporales.size() < 15
	var btn_cancelar := Button.new(); btn_cancelar.text = "Cancelar"
	
	vbox.add_child(btn_guardar)
	vbox.add_child(btn_crear)
	vbox.add_child(btn_cancelar)
	
	# --- LÓGICA DE BOTONES ---
	
	btn_cancelar.pressed.connect(func(): overlay.queue_free())
	
	btn_guardar.pressed.connect(func():
		# Como el arreglo ya es Array[LineEdit], Godot sabe que '.text' es un String válido
		var preg := txt_pregunta.text.strip_edges()
		var op0 := opciones[0].text.strip_edges()
		var op1 := opciones[1].text.strip_edges()
		var op2 := opciones[2].text.strip_edges()
		var op3 := opciones[3].text.strip_edges()
		var expl := txt_expl.text.strip_edges()
		
		if preg == "" or op0 == "" or op1 == "" or op2 == "" or op3 == "" or expl == "":
			_mostrar_alerta("Debes llenar todos los campos requeridos para guardar.")
			return 
		
		if _preguntas_temporales.size() < 15:
			_preguntas_temporales.append({
				"pregunta": preg,
				"tipo": "Texto", 
				"opciones": [op0, op1, op2, op3],
				"correcta": opt_correcta.selected,
				"explicacion": expl,
				"dato_curioso": txt_dato.text.strip_edges()
			})
			lbl_contador.text = "Preguntas guardadas: %d/15" % _preguntas_temporales.size()
			
			txt_pregunta.text = ""
			for o in opciones: o.text = ""
			txt_expl.text = ""
			txt_dato.text = ""
			
			if _preguntas_temporales.size() >= 15:
				btn_crear.disabled = false
	)
	
	btn_crear.pressed.connect(func():
		var path = ruta_archivo if ruta_archivo != "" else "res://Jsons/niveles creados por docentes/Preguntas_nivel_%d.json" % _numero_nivel_nuevo
		var dir = DirAccess.open("res://")
		if not dir.dir_exists("res://Jsons/niveles creados por docentes/"):
			dir.make_dir_recursive("res://Jsons/niveles creados por docentes/")
		
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(_preguntas_temporales, "\t"))
		file.close()
		_mostrar_alerta("Nivel guardado correctamente.")
		overlay.queue_free()
	)

func _mostrar_alerta(mensaje: String) -> void:
	var alertas := get_node_or_null("/root/Alertas")
	if alertas and alertas.has_method("mostrar_alerta"):
		alertas.mostrar_alerta(mensaje, 1.5)
	print(mensaje)

var ruta_archivo: String = "" # Si está vacía, estamos creando; si tiene ruta, estamos editando

func _abrir_buscador_archivos() -> void:
	var file_dialog := FileDialog.new()
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_RESOURCES
	file_dialog.filters = ["*.json; Archivos JSON de Niveles"]
	file_dialog.current_dir = "res://Jsons/niveles creados por docentes/"
	
	file_dialog.file_selected.connect(func(path: String):
		_cargar_json_para_edicion(path)
	)
	
	add_child(file_dialog)
	file_dialog.popup_centered(Vector2(600, 400))

func _cargar_json_para_edicion(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			_preguntas_temporales = json.data
			# CAMBIO: Ahora llamamos al panel de desglose intermedio
			_abrir_panel_desglose_edicion(path) 
		else:
			_mostrar_alerta("Error al leer el archivo...")

func _abrir_panel_desglose_edicion(ruta_archivo: String) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(550, 650)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.12, 0.12, 0.18)
	estilo.set_border_width_all(2)
	estilo.border_color = Color.WHITE
	estilo.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", estilo)
	center.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	panel.add_child(vbox)
	
	var lbl_titulo := Label.new()
	lbl_titulo.text = "Desglose de Preguntas Existentes"
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_titulo)
	
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 400
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	
	var lista_vbox := VBoxContainer.new()
	lista_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
	lista_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(lista_vbox)
	
	# Imprimimos los botones de las preguntas directamente
	if typeof(_preguntas_temporales) != TYPE_ARRAY:
		var lbl_err := Label.new()
		lbl_err.text = "El archivo JSON está vacío o no tiene un formato válido."
		lista_vbox.add_child(lbl_err)
	else:
		for i in range(_preguntas_temporales.size()):
			var item = _preguntas_temporales[i]
			var texto_mostrar = "Pregunta desconocida"
			
			if typeof(item) == TYPE_DICTIONARY:
				if item.has("pregunta"):
					texto_mostrar = str(item["pregunta"])
				elif item.has("Pregunta"):
					texto_mostrar = str(item["Pregunta"])
			
			var btn_preg := Button.new()
			btn_preg.text = "%d. %s" % [i + 1, texto_mostrar] 
			btn_preg.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn_preg.clip_text = true
			btn_preg.custom_minimum_size = Vector2(0, 45)
			btn_preg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lista_vbox.add_child(btn_preg)
			
			# IMPORTANTE: El .bind(i) asegura que el clic le envíe el ID correcto de la pregunta
			var accion_boton = func(idx_preg):
				_abrir_formulario_pregunta(ruta_archivo, idx_preg, false, overlay)
			btn_preg.pressed.connect(accion_boton.bind(i))
			
	var btn_nueva_pregunta := Button.new()
	btn_nueva_pregunta.text = "Añadir Nueva Pregunta"
	btn_nueva_pregunta.custom_minimum_size.y = 45 
	vbox.add_child(btn_nueva_pregunta)
	btn_nueva_pregunta.pressed.connect(func():
		_abrir_formulario_pregunta(ruta_archivo, -1, true, overlay)
	)
	
	var btn_cancelar_desglose := Button.new()
	btn_cancelar_desglose.text = "Cancelar y Salir de Edición"
	btn_cancelar_desglose.custom_minimum_size.y = 45 
	vbox.add_child(btn_cancelar_desglose)
	btn_cancelar_desglose.pressed.connect(func():
		overlay.queue_free()
	)

# NOTA: Se eliminó el parámetro callback_refrescar
func _abrir_formulario_pregunta(ruta_archivo: String, indice_pregunta: int, es_nueva: bool, overlay_desglose: Control) -> void:
	var overlay_form := ColorRect.new()
	overlay_form.color = Color(0, 0, 0, 0.9)
	overlay_form.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_desglose.add_child(overlay_form)
	
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_form.add_child(center)
	
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 680)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.15, 0.15, 0.2)
	estilo.set_border_width_all(2)
	estilo.border_color = Color.WHITE
	estilo.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", estilo)
	center.add_child(panel)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	
	var lbl_subtitulo := Label.new()
	lbl_subtitulo.text = "Crear Nueva Pregunta" if es_nueva else "Editar Pregunta Existente"
	lbl_subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_subtitulo)
	
	var txt_pregunta := LineEdit.new(); txt_pregunta.placeholder_text = "Pregunta"
	
	var txt_tipo := Label.new() 
	txt_tipo.text = "Tipo de pregunta: Texto"
	txt_tipo.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	
	var opciones: Array[LineEdit] = []
	for i in range(4):
		var le := LineEdit.new()
		le.placeholder_text = "Opción %d" % (i + 1)
		vbox.add_child(le)
		opciones.append(le)
		
	var opt_correcta := OptionButton.new()
	for i in range(4): opt_correcta.add_item("Correcta: Opción %d" % (i + 1), i)
	
	var txt_expl := TextEdit.new(); txt_expl.custom_minimum_size.y = 50; txt_expl.placeholder_text = "Explicación"
	var txt_dato := TextEdit.new(); txt_dato.custom_minimum_size.y = 50; txt_dato.placeholder_text = "Dato Curioso (Opcional)"
	
	vbox.add_child(txt_pregunta); vbox.add_child(txt_tipo); vbox.add_child(opt_correcta)
	vbox.add_child(txt_expl); vbox.add_child(txt_dato)
	
	if not es_nueva and indice_pregunta >= 0:
		var datos: Dictionary = _preguntas_temporales[indice_pregunta]
		txt_pregunta.text = str(datos.get("pregunta", ""))
		txt_expl.text = str(datos.get("explicacion", ""))
		txt_dato.text = str(datos.get("dato_curioso", ""))
		opt_correcta.selected = int(datos.get("correcta", 0))
		
		var ops = datos.get("opciones", ["", "", "", ""])
		for i in range(min(4, ops.size())):
			opciones[i].text = str(ops[i])
			
	# --- BOTONES DE ACCIÓN ---
	var btn_guardar := Button.new()
	btn_guardar.text = "Guardar Pregunta" if es_nueva else "Guardar Cambios"
	vbox.add_child(btn_guardar)
	
	# Botón de eliminar (Aparece solo si estamos editando)
	if not es_nueva:
		var btn_eliminar := Button.new()
		btn_eliminar.text = "Eliminar Pregunta"
		btn_eliminar.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3)) # Color rojo para advertencia
		vbox.add_child(btn_eliminar)
		
		btn_eliminar.pressed.connect(func():
			# 1. Crear el Panel de Confirmación Oscuro
			var overlay_conf := ColorRect.new()
			overlay_conf.color = Color(0, 0, 0, 0.95)
			overlay_conf.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			overlay_form.add_child(overlay_conf)
			
			var center_conf := CenterContainer.new()
			center_conf.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			overlay_conf.add_child(center_conf)
			
			var panel_conf := PanelContainer.new()
			var estilo_conf := StyleBoxFlat.new()
			estilo_conf.bg_color = Color(0.15, 0.1, 0.1) # Fondo ligeramente rojizo
			estilo_conf.set_border_width_all(2)
			estilo_conf.border_color = Color(0.8, 0.2, 0.2)
			estilo_conf.set_content_margin_all(20)
			panel_conf.add_theme_stylebox_override("panel", estilo_conf)
			center_conf.add_child(panel_conf)
			
			var vbox_conf := VBoxContainer.new()
			vbox_conf.add_theme_constant_override("separation", 20)
			panel_conf.add_child(vbox_conf)
			
			var lbl_conf := Label.new()
			lbl_conf.text = "¿Estás seguro de eliminar esta pregunta?"
			lbl_conf.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vbox_conf.add_child(lbl_conf)
			
			var hbox_conf := HBoxContainer.new()
			hbox_conf.alignment = BoxContainer.ALIGNMENT_CENTER
			hbox_conf.add_theme_constant_override("separation", 15)
			vbox_conf.add_child(hbox_conf)
			
			var btn_si := Button.new()
			btn_si.text = "Sí, eliminar"
			btn_si.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
			
			var btn_no := Button.new()
			btn_no.text = "No, mantener"
			
			hbox_conf.add_child(btn_si)
			hbox_conf.add_child(btn_no)
			
			# Lógica si el usuario se arrepiente (Cierra solo la alerta)
			btn_no.pressed.connect(func():
				overlay_conf.queue_free()
			)
			
			# Lógica si el usuario confirma la eliminación
			btn_si.pressed.connect(func():
				_preguntas_temporales.remove_at(indice_pregunta)
				
				var file = FileAccess.open(ruta_archivo, FileAccess.WRITE)
				if file:
					file.store_string(JSON.stringify(_preguntas_temporales, "\t"))
					file.close()
					
				_mostrar_alerta("Pregunta eliminada satisfactoriamente.")
				
				# Destruimos el menú raíz entero para forzar un refresco
				overlay_desglose.queue_free()
				_abrir_panel_desglose_edicion(ruta_archivo)
			)
		)

	var btn_cancelar := Button.new()
	btn_cancelar.text = "Cancelar"
	vbox.add_child(btn_cancelar)
	
	# --- SEÑALES ---
	btn_cancelar.pressed.connect(func():
		overlay_form.queue_free() 
	)
	
	btn_guardar.pressed.connect(func():
		var preg := txt_pregunta.text.strip_edges()
		var op0 := opciones[0].text.strip_edges()
		var op1 := opciones[1].text.strip_edges()
		var op2 := opciones[2].text.strip_edges()
		var op3 := opciones[3].text.strip_edges()
		var expl := txt_expl.text.strip_edges()
		
		if preg == "" or op0 == "" or op1 == "" or op2 == "" or op3 == "" or expl == "":
			_mostrar_alerta("Debes de tener todos los campos requeridos llenos con lo que se desea guardar.")
			return 
			
		var dict_pregunta := {
			"pregunta": preg,
			"tipo": "Texto",
			"opciones": [op0, op1, op2, op3],
			"correcta": opt_correcta.selected,
			"explicacion": expl,
			"dato_curioso": txt_dato.text.strip_edges()
		}
		
		if es_nueva:
			_preguntas_temporales.append(dict_pregunta)
		else:
			_preguntas_temporales[indice_pregunta] = dict_pregunta
			
		var file = FileAccess.open(ruta_archivo, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(_preguntas_temporales, "\t"))
			file.close()
			
		_mostrar_alerta("Cambios guardados correctamente." if not es_nueva else "Nueva pregunta anexada correctamente.")
		
		overlay_desglose.queue_free()
		_abrir_panel_desglose_edicion(ruta_archivo)
	)

func _tiempoactividad() -> void:
	if db == null: return
	var query := "CREATE TABLE IF NOT EXISTS tiempos_niveles (
		NU_USU INTEGER NOT NULL,
		TX_TIPO_NIVEL TEXT NOT NULL, -- 'trivia' o nombre del minijuego
		NU_NIVEL INTEGER NOT NULL,
		TIEMPO_TOTAL_SEGUNDOS REAL NOT NULL,
		TX_FECHA_REGISTRO DATETIME DEFAULT CURRENT_TIMESTAMP,
		PRIMARY KEY (NU_USU, TX_TIPO_NIVEL, NU_NIVEL)
	)"
	db.query(query)
