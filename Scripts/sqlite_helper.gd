extends RefCounted

const DB_PATH := "res://DB/venetrivia.db"

static func open_db_connection() -> SQLite:
	var database := SQLite.new()
	database.path = DB_PATH
	database.open_db()
	return database

static func escape(value: String) -> String:
	return value.replace("'", "''")

static func close_db_connection(database: SQLite) -> void:
	if database != null:
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
