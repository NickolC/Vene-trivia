extends RefCounted

static func generar_general(database: SQLite) -> String:
	var fecha := Time.get_datetime_string_from_system().replace("T", " ")

	var query := (
		"SELECT a.NU_USU, a.NM_ALUMNO, a.NU_NIVEL_MAX, " +
		"COALESCE(a.SW_ACTIVO, 1) AS SW_ACTIVO, " +
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
		var pct := "%.1f%%" % (float(correctas) / float(preguntas) * 100.0) if preguntas > 0 else "0%"
		var estado := "Activo" if activo == 1 else "Inactivo"
		var color  := "" if activo == 1 else " style=\"color:#aa4444\""

		filas += "<tr%s><td>%s</td><td>%s</td><td>%d</td><td>%d</td><td>%d</td><td>%d</td><td>%s</td></tr>\n" % [
			color, nombre, estado, nivel, partidas, puntos, estrellas, pct
		]

	return _wrap_html(
		"Reporte General — Vene-Trivia",
		fecha,
		"<table>\n<tr><th>Alumno</th><th>Estado</th><th>Nivel Max</th><th>Partidas</th><th>Puntos</th><th>Estrellas</th><th>%% Aciertos</th></tr>\n" +
		filas + "</table>"
	)

static func generar_por_alumno(database: SQLite, id_usu: int, nombre: String) -> String:
	var fecha := Time.get_datetime_string_from_system().replace("T", " ")
	var body := "<h2>Alumno: %s</h2>\n" % nombre

	# Niveles
	database.query("SELECT NU_NIVEL, NU_ESTRELLAS, NU_PUNTOS, NU_RESPC, NU_PREG FROM niveles WHERE NU_USU = %d ORDER BY NU_NIVEL ASC;" % id_usu)
	body += "<h3>Niveles</h3>\n<table>\n<tr><th>Nivel</th><th>Estrellas</th><th>Puntos</th><th>Correctas</th><th>Preguntas</th><th>%% Aciertos</th></tr>\n"
	for row in database.query_result:
		var preg := int(row.get("NU_PREG", 0))
		var resp := int(row.get("NU_RESPC", 0))
		var pct  := "%.1f%%" % (float(resp) / float(preg) * 100.0) if preg > 0 else "0%"
		body += "<tr><td>%d</td><td>%d/3</td><td>%d</td><td>%d</td><td>%d</td><td>%s</td></tr>\n" % [
			int(row.get("NU_NIVEL", 0)), int(row.get("NU_ESTRELLAS", 0)),
			int(row.get("NU_PUNTOS", 0)), resp, preg, pct
		]
	body += "</table>\n"

	# Minijuegos
	database.query("SELECT NM_MINIJUEGO, NU_INTENTOS, NU_PUNTOS, NU_ESTRELLAS FROM minijuegos_resultados WHERE NU_USU = %d ORDER BY NM_MINIJUEGO;" % id_usu)
	body += "<h3>Minijuegos</h3>\n<table>\n<tr><th>Minijuego</th><th>Intentos</th><th>Puntos</th><th>Estrellas</th></tr>\n"
	for row in database.query_result:
		body += "<tr><td>%s</td><td>%d</td><td>%d</td><td>%d</td></tr>\n" % [
			str(row.get("NM_MINIJUEGO", "-")), int(row.get("NU_INTENTOS", 0)),
			int(row.get("NU_PUNTOS", 0)), int(row.get("NU_ESTRELLAS", 0))
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
		"</style>\n</head>\n<body>\n" +
		"<h1>%s</h1>\n<p><em>Generado: %s</em></p>\n" % [titulo, fecha] +
		cuerpo +
		"\n</body>\n</html>\n"
	)
