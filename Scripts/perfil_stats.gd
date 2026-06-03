extends RefCounted

static func puntaje_total(database: SQLite, id: int) -> int:
	database.query("SELECT SUM(NU_PUNTOS) AS total FROM niveles WHERE NU_USU = %d;" % id)
	if database.query_result.is_empty():
		return 0
	return int(database.query_result[0].get("total", 0))

static func estrellas_totales(database: SQLite, id: int) -> int:
	database.query("SELECT SUM(NU_ESTRELLAS) AS total FROM niveles WHERE NU_USU = %d;" % id)
	if database.query_result.is_empty():
		return 0
	return int(database.query_result[0].get("total", 0))

static func niveles_perfectos(database: SQLite, id: int) -> int:
	database.query("SELECT COUNT(*) AS cnt FROM niveles WHERE NU_USU = %d AND NU_ESTRELLAS = 3;" % id)
	if database.query_result.is_empty():
		return 0
	return int(database.query_result[0].get("cnt", 0))

static func niveles_completados(database: SQLite, id: int) -> int:
	database.query("SELECT COUNT(*) AS cnt FROM niveles WHERE NU_USU = %d AND NU_ESTRELLAS > 0;" % id)
	if database.query_result.is_empty():
		return 0
	return int(database.query_result[0].get("cnt", 0))

static func veces_repetido(database: SQLite, id: int) -> int:
	database.query("SELECT COUNT(*) AS cnt FROM niveles_intentos WHERE NU_USU = %d;" % id)
	if database.query_result.is_empty():
		return 0
	return int(database.query_result[0].get("cnt", 0))

static func datos_alumno(database: SQLite, id: int) -> Dictionary:
	database.query(
		"SELECT NU_DINERO, NU_PUBLICO, NU_PROBABILIDAD, NU_MITAD, NU_NIVEL_MAX FROM Alumnos WHERE NU_USU = %d;" % id
	)
	if database.query_result.is_empty():
		return {}
	return database.query_result[0]

static func minijuegos_desbloqueados(database: SQLite, id: int) -> int:
	database.query("SELECT COUNT(*) AS cnt FROM Tienda WHERE NU_USU = %d;" % id)
	if database.query_result.is_empty():
		return 0
	return int(database.query_result[0].get("cnt", 0))

static func leaderboard(database: SQLite) -> Array:
	database.query(
		"SELECT NM_ALUMNO, SUM(NU_PUNTOS) AS total FROM niveles GROUP BY NU_USU ORDER BY total DESC LIMIT 10;"
	)
	return database.query_result

static func logros_desbloqueados(database: SQLite, id: int) -> Array:
	database.query(
		"SELECT TX_LOGRO FROM logros_alumno WHERE NU_USU = %d AND SW_DESBLOQUEADO = 1 ORDER BY FE_DESBLOQUEO;" % id
	)
	var result: Array = []
	for row in database.query_result:
		result.append(str(row.get("TX_LOGRO", "")))
	return result
