extends RefCounted

# REP-04: membrete institucional mostrado en todos los reportes.
const MEMBRETE_TITULO := "Vene-Trivia — Juego Educativo de Historia de Venezuela"
const MEMBRETE_SUBTITULO := "Panel Docente · Reporte de Progreso de Alumnos"

# REP-02: formatea segundos a mm:ss para las columnas de tiempo.
static func _fmt_tiempo(segundos: float) -> String:
	if segundos <= 0.0:
		return "—"
	var total := int(round(segundos))
	return "%02d:%02d" % [total / 60, total % 60]

# REP-01: nombre del pack a partir del nivel comprado en la tienda.
static func _nombre_pack(tp: String, nv: int) -> String:
	if tp == "niveles":
		if nv in [11, 12]:
			return "Pack A (niveles 11-12)"
		if nv in [13, 14]:
			return "Pack B (niveles 13-14)"
		if nv == 15:
			return "Pack C (nivel 15)"
		return "Niveles extra (nivel %d)" % nv
	return "%s (nivel %d)" % [tp.capitalize(), nv]

static func generar_general(database: SQLite) -> String:
	var fecha := Time.get_datetime_string_from_system().replace("T", " ")

	var query := (
		"SELECT a.NU_USU, a.NM_ALUMNO, a.NU_NIVEL_MAX, " +
		"COALESCE(a.SW_ACTIVO, 1) AS SW_ACTIVO, " +
		"COALESCE(a.NU_DINERO, 0) AS dinero, " +
		"(COALESCE(a.NU_MITAD,0) + COALESCE(a.NU_PUBLICO,0) + COALESCE(a.NU_PROBABILIDAD,0)) AS comodines, " +
		"(SELECT COUNT(*) FROM Tienda t WHERE t.NU_USU = a.NU_USU) AS packs, " +
		"(SELECT COALESCE(SUM(tn.TIEMPOTOTAL_SEGUNDOS),0) FROM tiempos_niveles tn WHERE tn.NU_USU = a.NU_USU AND tn.TX_TIPO_NIVEL = 'TRIVIA') AS tiempo_total, " +
		"COUNT(n.NU_NIVEL) AS partidas, " +
		"COALESCE(SUM(n.NU_PUNTOS), 0) AS puntos, " +
		"COALESCE(SUM(n.NU_RESPC), 0) AS correctas, " +
		"COALESCE(SUM(n.NU_PREG), 0) AS preguntas, " +
		"COALESCE(SUM(n.NU_ESTRELLAS), 0) AS estrellas " +
		"FROM Alumnos a LEFT JOIN niveles n ON n.NU_USU = a.NU_USU " +
		"GROUP BY a.NU_USU ORDER BY puntos DESC, a.NM_ALUMNO ASC;"
	)
	database.query(query)

	var filas := ""
	for row in database.query_result:
		var nombre   := str(row.get("NM_ALUMNO", "?"))
		var activo   := int(row.get("SW_ACTIVO", 1))
		var nivel    := int(row.get("NU_NIVEL_MAX", 0))
		var partidas := int(row.get("partidas", 0))
		var puntos   := int(row.get("puntos", 0))
		var estrellas := int(row.get("estrellas", 0))
		var correctas := int(row.get("correctas", 0))
		var preguntas := int(row.get("preguntas", 0))
		var dinero    := int(row.get("dinero", 0))
		var comodines := int(row.get("comodines", 0))
		var packs     := int(row.get("packs", 0))
		var tiempo    := float(row.get("tiempo_total", 0.0))
		var pct := "%.1f%%" % (float(correctas) / float(preguntas) * 100.0) if preguntas > 0 else "0%"
		var estado := "Activo" if activo == 1 else "Inactivo"
		var color  := "" if activo == 1 else " style=\"color:#aa4444\""

		filas += "<tr%s><td>%s</td><td>%s</td><td>%d</td><td>%d</td><td>%d</td><td>%d</td><td>%s</td><td>%d Bs.</td><td>%d</td><td>%d</td><td>%s</td></tr>\n" % [
			color, nombre, estado, nivel, partidas, puntos, estrellas, pct, dinero, comodines, packs, _fmt_tiempo(tiempo)
		]

	return _wrap_html(
		"Reporte General — Vene-Trivia",
		fecha,
		"<table>\n<tr><th>Alumno</th><th>Estado</th><th>Nivel Max</th><th>Partidas</th><th>Puntos</th><th>Estrellas</th><th>%% Aciertos</th><th>Monedas</th><th>Comodines</th><th>Packs</th><th>Tiempo total (trivia)</th></tr>\n" +
		filas + "</table>"
	)

static func generar_por_alumno(database: SQLite, id_usu: int, nombre: String) -> String:
	var fecha := Time.get_datetime_string_from_system().replace("T", " ")
	var body := "<h2>Alumno: %s</h2>\n" % nombre

	# REP-01: resumen economico (monedas, comodines actuales, packs comprados)
	database.query("SELECT COALESCE(NU_DINERO,0) AS dinero, COALESCE(NU_MITAD,0) AS mitad, COALESCE(NU_PUBLICO,0) AS publico, COALESCE(NU_PROBABILIDAD,0) AS prob FROM Alumnos WHERE NU_USU = %d LIMIT 1;" % id_usu)
	var dinero := 0
	var c_mitad := 0
	var c_publico := 0
	var c_prob := 0
	if not database.query_result.is_empty():
		var r0 = database.query_result[0]
		dinero = int(r0.get("dinero", 0))
		c_mitad = int(r0.get("mitad", 0))
		c_publico = int(r0.get("publico", 0))
		c_prob = int(r0.get("prob", 0))

	# Tiempos por nivel (trivia) en un mapa NU_NIVEL -> segundos para cruzar con niveles
	var tiempos_por_nivel := {}
	database.query("SELECT NU_NIVEL, TIEMPOTOTAL_SEGUNDOS FROM tiempos_niveles WHERE NU_USU = %d AND TX_TIPO_NIVEL = 'TRIVIA';" % id_usu)
	for tr in database.query_result:
		tiempos_por_nivel[int(tr.get("NU_NIVEL", 0))] = float(tr.get("TIEMPOTOTAL_SEGUNDOS", 0.0))

	# Packs comprados (tienda)
	database.query("SELECT TP_MINIJUEGO, NV_EXTRA FROM Tienda WHERE NU_USU = %d ORDER BY TP_MINIJUEGO, NV_EXTRA;" % id_usu)
	var lista_packs: Array[String] = []
	for pr in database.query_result:
		lista_packs.append(_nombre_pack(str(pr.get("TP_MINIJUEGO", "")), int(pr.get("NV_EXTRA", 0))))
	var packs_txt := ", ".join(lista_packs) if not lista_packs.is_empty() else "Ninguno"

	body += "<h3>Resumen</h3>\n<table>\n"
	body += "<tr><th>Monedas actuales</th><td>%d Bs.</td></tr>\n" % dinero
	body += "<tr><th>Comodines disponibles</th><td>50/50: %d · Llamada: %d · Público: %d (total %d)</td></tr>\n" % [c_mitad, c_publico, c_prob, c_mitad + c_publico + c_prob]
	body += "<tr><th>Packs comprados (%d)</th><td>%s</td></tr>\n" % [lista_packs.size(), packs_txt]
	body += "</table>\n"

	# Niveles (REP-02: columna de tiempo por nivel)
	database.query("SELECT NU_NIVEL, NU_ESTRELLAS, NU_PUNTOS, NU_RESPC, NU_PREG FROM niveles WHERE NU_USU = %d ORDER BY NU_NIVEL ASC;" % id_usu)
	body += "<h3>Niveles</h3>\n<table>\n<tr><th>Nivel</th><th>Estrellas</th><th>Puntos</th><th>Correctas</th><th>Preguntas</th><th>%% Aciertos</th><th>Tiempo</th></tr>\n"
	for row in database.query_result:
		var preg := int(row.get("NU_PREG", 0))
		var resp := int(row.get("NU_RESPC", 0))
		var nlvl := int(row.get("NU_NIVEL", 0))
		var pct  := "%.1f%%" % (float(resp) / float(preg) * 100.0) if preg > 0 else "0%"
		var tlvl := float(tiempos_por_nivel.get(nlvl, 0.0))
		body += "<tr><td>%d</td><td>%d/3</td><td>%d</td><td>%d</td><td>%d</td><td>%s</td><td>%s</td></tr>\n" % [
			nlvl, int(row.get("NU_ESTRELLAS", 0)),
			int(row.get("NU_PUNTOS", 0)), resp, preg, pct, _fmt_tiempo(tlvl)
		]
	body += "</table>\n"

	# Minijuegos (REP-02: columna de mejor tiempo)
	database.query("SELECT NM_MINIJUEGO, NU_INTENTOS, NU_PUNTOS, NU_ESTRELLAS, COALESCE(NU_MEJOR_TIEMPO,0) AS mejor_t FROM minijuegos_resultados WHERE NU_USU = %d ORDER BY NM_MINIJUEGO;" % id_usu)
	body += "<h3>Minijuegos</h3>\n<table>\n<tr><th>Minijuego</th><th>Intentos</th><th>Puntos</th><th>Estrellas</th><th>Mejor tiempo</th></tr>\n"
	for row in database.query_result:
		body += "<tr><td>%s</td><td>%d</td><td>%d</td><td>%d</td><td>%s</td></tr>\n" % [
			str(row.get("NM_MINIJUEGO", "-")), int(row.get("NU_INTENTOS", 0)),
			int(row.get("NU_PUNTOS", 0)), int(row.get("NU_ESTRELLAS", 0)), _fmt_tiempo(float(row.get("mejor_t", 0.0)))
		]
	body += "</table>\n"

	# Logros
	database.query("SELECT TX_LOGRO, FE_DESBLOQUEO FROM logros_alumno WHERE NU_USU = %d AND SW_DESBLOQUEADO = 1 ORDER BY FE_DESBLOQUEO;" % id_usu)
	body += "<h3>Logros</h3>\n<ul>\n"
	for row in database.query_result:
		body += "<li>%s (%s)</li>\n" % [str(row.get("TX_LOGRO", "")), str(row.get("FE_DESBLOQUEO", ""))]
	body += "</ul>\n"

	return _wrap_html("Reporte Alumno — %s" % nombre, fecha, body)

static func guardar_y_abrir(html: String, nombre_archivo: String) -> void:
	var ruta := "user://%s" % nombre_archivo
	var archivo := FileAccess.open(ruta, FileAccess.WRITE)
	if archivo == null:
		push_error("No se pudo escribir el reporte: %s" % ruta)
		return
	archivo.store_string(html)
	archivo.close()

	var nombre_pdf := nombre_archivo
	if nombre_pdf.to_lower().ends_with(".html"):
		nombre_pdf = nombre_pdf.substr(0, nombre_pdf.length() - 5) + ".pdf"
	else:
		nombre_pdf += ".pdf"
	_generar_pdf_desde_html(ruta, "user://%s" % nombre_pdf)

	OS.shell_open(ProjectSettings.globalize_path(ruta))

static func _generar_pdf_desde_html(ruta_html_user: String, ruta_pdf_user: String) -> void:
	var navegador := _buscar_navegador_compatible()
	if navegador.is_empty():
		push_warning("No se encontro Edge o Chrome para exportar PDF. Solo se genero HTML.")
		return

	var ruta_html_abs := ProjectSettings.globalize_path(ruta_html_user)
	var ruta_pdf_abs := ProjectSettings.globalize_path(ruta_pdf_user)
	var url_html := "file:///" + ruta_html_abs.replace("\\", "/")

	var salida: Array = []
	var args := PackedStringArray([
		"--headless=new",
		"--disable-gpu",
		"--print-to-pdf=%s" % ruta_pdf_abs,
		url_html,
	])
	var exit_code := OS.execute(navegador, args, salida, true)
	if exit_code != 0:
		push_warning("No se pudo exportar PDF automaticamente. Codigo: %d" % exit_code)
		return

	if not FileAccess.file_exists(ruta_pdf_user):
		push_warning("Se intento exportar PDF, pero no se encontro el archivo final.")

static func _buscar_navegador_compatible() -> String:
	var candidatos := PackedStringArray()
	var program_files := OS.get_environment("ProgramFiles")
	var program_files_x86 := OS.get_environment("ProgramFiles(x86)")
	var local_app_data := OS.get_environment("LOCALAPPDATA")

	if not program_files.is_empty():
		candidatos.append(program_files.path_join("Microsoft/Edge/Application/msedge.exe"))
		candidatos.append(program_files.path_join("Google/Chrome/Application/chrome.exe"))
	if not program_files_x86.is_empty():
		candidatos.append(program_files_x86.path_join("Microsoft/Edge/Application/msedge.exe"))
		candidatos.append(program_files_x86.path_join("Google/Chrome/Application/chrome.exe"))
	if not local_app_data.is_empty():
		candidatos.append(local_app_data.path_join("Microsoft/Edge/Application/msedge.exe"))
		candidatos.append(local_app_data.path_join("Google/Chrome/Application/chrome.exe"))

	for ruta in candidatos:
		if FileAccess.file_exists(ruta):
			return ruta

	return ""

static func _wrap_html(titulo: String, fecha: String, cuerpo: String) -> String:
	return (
		"<!DOCTYPE html>\n<html lang=\"es\">\n<head>\n" +
		"<meta charset=\"utf-8\">\n<title>%s</title>\n" % titulo +
		"<style>\n" +
		"body{font-family:Arial,sans-serif;padding:24px;background:#f9f9f9;color:#222}\n" +
		"h1,h2,h3{color:#333}\n" +
		"table{border-collapse:collapse;width:100%;margin-bottom:16px}\n" +
		"th,td{border:1px solid #bbb;padding:7px 10px;text-align:left}\n" +
		"th{background:#2c5282;color:#fff}\n" +
		"tr:nth-child(even){background:#edf2f7}\n" +
		"ul{margin:0;padding-left:20px}\n" +
		# REP-04: estilos del membrete institucional
		".membrete{border-bottom:3px solid #2c5282;margin-bottom:18px;padding-bottom:10px}\n" +
		".membrete .titulo{font-size:20px;font-weight:bold;color:#2c5282}\n" +
		".membrete .subtitulo{font-size:13px;color:#555}\n" +
		"</style>\n</head>\n<body>\n" +
		# REP-04: membrete presente en todos los reportes
		"<div class=\"membrete\"><div class=\"titulo\">%s</div><div class=\"subtitulo\">%s</div></div>\n" % [MEMBRETE_TITULO, MEMBRETE_SUBTITULO] +
		"<h1>%s</h1>\n<p><em>Generado: %s</em></p>\n" % [titulo, fecha] +
		cuerpo +
		"\n</body>\n</html>\n"
	)
