extends Node

signal logro_desbloqueado(clave: String, texto: String)

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

const CATALOGO: Dictionary = {
	"primer_nivel":    "¡Primer Nivel Completado! Has dado tus primeros pasos.",
	"perfectista":     "¡Perfeccionista! Completaste un nivel con 3 estrellas.",
	"puntuacion_alta": "¡Gran Puntuación! Obtuviste más de 1000 puntos en un nivel.",
	"millonario":      "¡Adinerado! Acumulaste más de 500 Bs.",
	"cinco_niveles":   "¡Explorador! Completaste 5 niveles distintos.",
	"diez_niveles":    "¡Historiador! Completaste 10 niveles distintos.",
	"leyenda":         "¡Leyenda de Venezuela! Completaste los 15 niveles.",
}

var _db: SQLite

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	logro_desbloqueado.connect(_on_logro_desbloqueado)

func _on_logro_desbloqueado(_clave: String, texto: String) -> void:
	Alertas.mostrar_alerta("Logro: %s" % texto, 3.0)

func _get_db() -> SQLite:
	if not is_instance_valid(_db):
		_db = SQLiteHelper.open_db_connection()
	return _db

func desbloquear(clave: String) -> void:
	if GlobalUsuario.usuario_actual_id <= 0:
		return
	if not CATALOGO.has(clave):
		return

	var database := _get_db()
	var id_usu : int = GlobalUsuario.usuario_actual_id
	var nombre := SQLiteHelper.escape(GlobalUsuario.nombre_alumno)

	database.query("SELECT 1 FROM logros_alumno WHERE NU_USU = %d AND TX_LOGRO = '%s' LIMIT 1;" % [id_usu, SQLiteHelper.escape(clave)])
	if not database.query_result.is_empty():
		return

	var fecha := Time.get_datetime_string_from_system().replace("T", " ")
	database.query(
		"INSERT INTO logros_alumno (NU_USU, NM_ALUMNO, TX_LOGRO, SW_DESBLOQUEADO, FE_DESBLOQUEO) VALUES (%d, '%s', '%s', 1, '%s');" % [
			id_usu, nombre, SQLiteHelper.escape(clave), SQLiteHelper.escape(fecha)
		]
	)
	logro_desbloqueado.emit(clave, CATALOGO[clave])

func evaluar_post_nivel(estrellas: int, puntos: int, dinero_total: int) -> void:
	if GlobalUsuario.usuario_actual_id <= 0:
		return

	var database := _get_db()
	var id_usu : int = GlobalUsuario.usuario_actual_id

	database.query("SELECT COUNT(*) AS cnt FROM niveles WHERE NU_USU = %d AND NU_ESTRELLAS > 0;" % id_usu)
	var niveles_con_estrella: int = 0
	if not database.query_result.is_empty():
		niveles_con_estrella = int(database.query_result[0].get("cnt", 0))

	if niveles_con_estrella >= 1:
		desbloquear("primer_nivel")
	if niveles_con_estrella >= 5:
		desbloquear("cinco_niveles")
	if niveles_con_estrella >= 10:
		desbloquear("diez_niveles")
	if niveles_con_estrella >= 15:
		desbloquear("leyenda")
	if estrellas >= 3:
		desbloquear("perfectista")
	if puntos >= 1000:
		desbloquear("puntuacion_alta")
	if dinero_total >= 500:
		desbloquear("millonario")
