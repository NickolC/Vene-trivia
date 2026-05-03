extends RefCounted

const DB_PATH := "res://DB/venetrivia.db"

static func open_db_connection() -> SQLite:
	var database := SQLite.new()
	database.path = DB_PATH
	database.open_db()
	ensure_niveles_table(database)
	ensure_niveles_intentos_table(database)
	return database

static func escape(value: String) -> String:
	return value.replace("'", "''")

static func close_db_connection(database: SQLite) -> void:
	if is_instance_valid(database):
		database.close_db()

static func ensure_activity_table(database: SQLite) -> void:
	if database == null:
		return

	var query := "CREATE TABLE IF NOT EXISTS actividad (" + \
	"NU_ACT INTEGER PRIMARY KEY AUTOINCREMENT, " + \
	"TX_TIPO_USUARIO TEXT NOT NULL, " + \
	"TX_USUARIO TEXT NOT NULL, " + \
	"TX_ACCION TEXT NOT NULL, " + \
	"TX_FECHA TEXT NOT NULL);"
	database.query(query)

static func ensure_superadmin_table(database: SQLite) -> void:
	if database == null:
		return

	var query := "CREATE TABLE IF NOT EXISTS SuperAdmin (" + \
	"NU_USU INTEGER PRIMARY KEY AUTOINCREMENT, " + \
	"NM_SUPERADMIN TEXT NOT NULL UNIQUE, " + \
	"CO_PSW TEXT NOT NULL);"
	database.query(query)

static func ensure_niveles_table(database: SQLite) -> void:
	if database == null:
		return

	var create_query := "CREATE TABLE IF NOT EXISTS niveles (" + \
	"NU_NIVEL INTEGER NOT NULL, " + \
	"NU_USU INTEGER NOT NULL, " + \
	"NM_ALUMNO TEXT NOT NULL, " + \
	"NU_PREG INTEGER NOT NULL, " + \
	"NU_RESPC INTEGER, " + \
	"NU_RESPI INTEGER, " + \
	"NU_PUNTOS INTEGER, " + \
	"NU_ESTRELLAS INTEGER, " + \
	"SW_COM INTEGER DEFAULT 0, " + \
	"PRIMARY KEY (NU_NIVEL, NU_USU));"
	database.query(create_query)
	database.query("CREATE INDEX IF NOT EXISTS idx_niveles_usu ON niveles (NU_USU);")

	if _table_exists(database, "nivel_1"):
		var migrate_query := "INSERT OR IGNORE INTO niveles " + \
		"(NU_NIVEL, NU_USU, NM_ALUMNO, NU_PREG, NU_RESPC, NU_RESPI, NU_PUNTOS, NU_ESTRELLAS, SW_COM) " + \
		"SELECT NU_NIVEL, NU_USU, NM_ALUMNO, NU_PREG, NU_RESPC, NU_RESPI, NU_PUNTOS, NU_ESTRELLAS, SW_COM FROM nivel_1;"
		database.query(migrate_query)

static func _table_exists(database: SQLite, table_name: String) -> bool:
	var query := "SELECT name FROM sqlite_master WHERE type='table' AND name='%s' LIMIT 1;" % escape(table_name)
	database.query(query)
	return not database.query_result.is_empty()

static func ensure_alumnos_activo_column(database: SQLite) -> void:
	if database == null:
		return
		# 1. Consultar la estructura actual de la tabla
		database.query("PRAGMA table_info(Alumnos);")
		
		var existe = false
		for columna in database.query_result:
			if columna["name"] == "SW_ACTIVO":
				existe = true
			break
			
			# 2. Solo agregarla si no existe
			if not existe:
				database.query("ALTER TABLE Alumnos ADD COLUMN SW_ACTIVO INTEGER NOT NULL DEFAULT 1;")
				print("Columna SW_ACTIVO agregada con éxito.")
	else:
		print("La columna SW_ACTIVO ya existe, saltando...")

static func ensure_minijuegos_table(database: SQLite) -> void:
	if database == null:
		return

	var query := "CREATE TABLE IF NOT EXISTS minijuegos_resultados (" + \
	"NU_ID INTEGER PRIMARY KEY AUTOINCREMENT, " + \
	"NU_USU INTEGER NOT NULL, " + \
	"NM_ALUMNO TEXT NOT NULL, " + \
	"NM_MINIJUEGO TEXT NOT NULL, " + \
	"NU_INTENTOS INTEGER NOT NULL DEFAULT 0, " + \
	"NU_PUNTOS INTEGER NOT NULL DEFAULT 0, " + \
	"NU_ESTRELLAS INTEGER NOT NULL DEFAULT 0, " + \
	"FE_ULTIMO TEXT DEFAULT '');"
	database.query(query)
	database.query("CREATE INDEX IF NOT EXISTS idx_minijuegos_usu ON minijuegos_resultados (NU_USU);")

static func ensure_logros_table(database: SQLite) -> void:
	if database == null:
		return

	var query := "CREATE TABLE IF NOT EXISTS logros_alumno (" + \
	"NU_ID INTEGER PRIMARY KEY AUTOINCREMENT, " + \
	"NU_USU INTEGER NOT NULL, " + \
	"NM_ALUMNO TEXT NOT NULL, " + \
	"TX_LOGRO TEXT NOT NULL, " + \
	"SW_DESBLOQUEADO INTEGER NOT NULL DEFAULT 1, " + \
	"FE_DESBLOQUEO TEXT DEFAULT '');"
	database.query(query)
	database.query("CREATE INDEX IF NOT EXISTS idx_logros_usu ON logros_alumno (NU_USU);")

static func ensure_niveles_intentos_table(database: SQLite) -> void:
	if database == null:
		return

	var query := "CREATE TABLE IF NOT EXISTS niveles_intentos (" + \
	"NU_INTENTO INTEGER PRIMARY KEY AUTOINCREMENT, " + \
	"NU_USU INTEGER NOT NULL, " + \
	"NM_ALUMNO TEXT NOT NULL, " + \
	"NU_NIVEL INTEGER NOT NULL, " + \
	"NU_PREG INTEGER NOT NULL, " + \
	"NU_RESPC INTEGER NOT NULL, " + \
	"NU_RESPI INTEGER NOT NULL, " + \
	"NU_PUNTOS INTEGER NOT NULL, " + \
	"NU_ESTRELLAS INTEGER NOT NULL, " + \
	"SW_COM INTEGER NOT NULL DEFAULT 0, " + \
	"FE_INTENTO TEXT NOT NULL);"
	database.query(query)
	database.query("CREATE INDEX IF NOT EXISTS idx_niveles_intentos_usu_nivel ON niveles_intentos (NU_USU, NU_NIVEL);")

static func log_activity(database: SQLite, tipo_usuario: String, usuario: String, accion: String) -> void:
	if database == null:
		return

	ensure_activity_table(database)
	var fecha := Time.get_datetime_string_from_system().replace("T", " ")
	var query := "INSERT INTO actividad (TX_TIPO_USUARIO, TX_USUARIO, TX_ACCION, TX_FECHA) VALUES ('%s', '%s', '%s', '%s');" % [
		escape(tipo_usuario),
		escape(usuario),
		escape(accion),
		escape(fecha)
	]
	database.query(query)
