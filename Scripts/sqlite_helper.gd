extends RefCounted

const DB_PATH := "res://DB/venetrivia.db"

static func open_db_connection() -> SQLite:
	var database := SQLite.new()
	database.path = DB_PATH
	database.open_db()
	ensure_niveles_table(database)
	ensure_niveles_intentos_table(database)
	ensure_minijuegos_table(database)
	ensure_logros_table(database)
	ensure_sopa_tables(database)
	ensure_columnas_tables(database)
	ensure_memoria_tables(database)
	ensure_alumnos_minijuego_columns(database)
	ensure_minijuego_tiempo_column(database)
	return database

# REP-02: columna de MEJOR tiempo (segundos) por minijuego. Se conserva el menor
# valor registrado (no se sobreescribe con tiempos peores).
static func ensure_minijuego_tiempo_column(database: SQLite) -> void:
	if database == null:
		return
	database.query("PRAGMA table_info(minijuegos_resultados);")
	var cols: Array = []
	for c in database.query_result:
		cols.append(c["name"])
	if not "NU_MEJOR_TIEMPO" in cols:
		database.query("ALTER TABLE minijuegos_resultados ADD COLUMN NU_MEJOR_TIEMPO REAL DEFAULT 0;")

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

	# 1. Ejecutar en una transacción para mayor seguridad y velocidad
	database.query("BEGIN TRANSACTION;")
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

	# 2. Verificar la existencia antes de intentar migrar
	if _table_exists(database, "nivel_1"):
		# Verificar si la tabla niveles ya tiene datos para evitar errores de clave primaria
		var count_query := "SELECT COUNT(*) as total FROM niveles;"
		database.query(count_query)
		if int(database.query_result[0]["total"]) == 0:
			var migrate_query := "INSERT INTO niveles " + \
			"(NU_NIVEL, NU_USU, NM_ALUMNO, NU_PREG, NU_RESPC, NU_RESPI, NU_PUNTOS, NU_ESTRELLAS, SW_COM) " + \
			"SELECT NU_NIVEL, NU_USU, NM_ALUMNO, NU_PREG, NU_RESPC, NU_RESPI, NU_PUNTOS, NU_ESTRELLAS, SW_COM FROM nivel_1;"
			database.query(migrate_query)
			# Opcional: Eliminar la tabla vieja una vez migrada para evitar errores futuros
			# database.query("DROP TABLE nivel_1;")
	# 3. Cerrar transacción
	database.query("COMMIT;")

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
			break # Detenemos la búsqueda porque ya la encontramos
			
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

static func mirror_minijuegos_resultados(database: SQLite, id_usu: int, nombre: String, minijuego: String, pts: int, estrellas: int, tiempo_seg: float = 0.0) -> void:
	if database == null:
		return
	var fecha := Time.get_datetime_string_from_system().replace("T", " ")
	database.query(
		"SELECT NU_ID, NU_INTENTOS, NU_PUNTOS, NU_ESTRELLAS, NU_MEJOR_TIEMPO FROM minijuegos_resultados WHERE NU_USU = %d AND NM_MINIJUEGO = '%s' LIMIT 1;" % [id_usu, escape(minijuego)]
	)
	if database.query_result.is_empty():
		var t_ini := maxf(0.0, tiempo_seg)
		database.query(
			"INSERT INTO minijuegos_resultados (NU_USU, NM_ALUMNO, NM_MINIJUEGO, NU_INTENTOS, NU_PUNTOS, NU_ESTRELLAS, FE_ULTIMO, NU_MEJOR_TIEMPO) VALUES (%d, '%s', '%s', 1, %d, %d, '%s', %f);" % [id_usu, escape(nombre), escape(minijuego), pts, estrellas, escape(fecha), t_ini]
		)
	else:
		var row := database.query_result[0]
		var intentos := int(row.get("NU_INTENTOS", 0)) + 1
		var mejor_pts := maxi(pts, int(row.get("NU_PUNTOS", 0)))
		var mejor_est := maxi(estrellas, int(row.get("NU_ESTRELLAS", 0)))
		var nu_id := int(row.get("NU_ID", 0))
		# REP-02: conservar el MENOR tiempo positivo (mejor tiempo).
		var prev_t := float(row.get("NU_MEJOR_TIEMPO", 0.0))
		var mejor_t := prev_t
		if tiempo_seg > 0.0:
			mejor_t = tiempo_seg if prev_t <= 0.0 else minf(prev_t, tiempo_seg)
		database.query(
			"UPDATE minijuegos_resultados SET NU_INTENTOS = %d, NU_PUNTOS = %d, NU_ESTRELLAS = %d, FE_ULTIMO = '%s', NU_MEJOR_TIEMPO = %f WHERE NU_ID = %d;" % [intentos, mejor_pts, mejor_est, escape(fecha), mejor_t, nu_id]
		)

## BUG-02: acreditar monedas ganadas en un minijuego al saldo del alumno.
## Los minijuegos calculaban las monedas pero nunca las escribian en NU_DINERO.
static func sumar_dinero(database: SQLite, id_usu: int, monedas: int) -> void:
	if database == null or monedas <= 0:
		return
	database.query("UPDATE Alumnos SET NU_DINERO = NU_DINERO + %d WHERE NU_USU = %d;" % [monedas, id_usu])

static func nivel_comprado(database: SQLite, id_usu: int, tp_minijuego: String, nv: int) -> bool:
	if database == null:
		return false
	var q := "SELECT 1 FROM Tienda WHERE NU_USU = %d AND TP_MINIJUEGO = '%s' AND NV_EXTRA = %d LIMIT 1;" % [id_usu, escape(tp_minijuego), nv]
	database.query(q)
	return not database.query_result.is_empty()

static func nivel_principal_comprado(database: SQLite, id_usu: int, nv: int) -> bool:
	return nivel_comprado(database, id_usu, "niveles", nv)

static func get_pack_niveles(pack_id: int) -> Array[int]:
	match pack_id:
		1:
			return [11, 12]
		2:
			return [13, 14]
		3:
			return [15]
		_:
			return []

static func pack_niveles_comprado(database: SQLite, id_usu: int, pack_id: int) -> bool:
	if database == null:
		return false
	var niveles := get_pack_niveles(pack_id)
	if niveles.is_empty():
		return false
	for nivel in niveles:
		if not nivel_principal_comprado(database, id_usu, nivel):
			return false
	return true

static func puede_comprar_pack_niveles(database: SQLite, id_usu: int, pack_id: int) -> bool:
	if database == null:
		return false
	if pack_id < 1 or pack_id > 3:
		return false
	if pack_niveles_comprado(database, id_usu, pack_id):
		return false
	if pack_id == 1:
		return true
	return pack_niveles_comprado(database, id_usu, pack_id - 1)

static func comprar_pack_niveles(database: SQLite, id_usu: int, costo: int, pack_id: int) -> Dictionary:
	if database == null:
		return {"ok": false, "mensaje": "Sin conexion de base de datos."}
	if not puede_comprar_pack_niveles(database, id_usu, pack_id):
		if pack_niveles_comprado(database, id_usu, pack_id):
			return {"ok": false, "mensaje": "Ese pack ya fue comprado."}
		return {"ok": false, "mensaje": "Debes comprar los packs anteriores primero."}

	var niveles := get_pack_niveles(pack_id)
	if niveles.is_empty():
		return {"ok": false, "mensaje": "Pack invalido."}

	database.query("SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d LIMIT 1;" % id_usu)
	if database.query_result.is_empty():
		return {"ok": false, "mensaje": "No se encontro el alumno."}

	var dinero := int(database.query_result[0].get("NU_DINERO", 0))
	if dinero < costo:
		return {"ok": false, "mensaje": "No tienes suficiente dinero. Necesitas %d Bs." % costo}

	for nivel in niveles:
		database.query("INSERT OR IGNORE INTO Tienda (NU_USU, TP_MINIJUEGO, NV_EXTRA) VALUES (%d, 'niveles', %d);" % [id_usu, nivel])

	database.query("UPDATE Alumnos SET NU_DINERO = NU_DINERO - %d WHERE NU_USU = %d;" % [costo, id_usu])
	return {"ok": true, "mensaje": "Pack comprado con exito.", "niveles": niveles}

static func ensure_sopa_tables(database: SQLite) -> void:
	if database == null:
		return
	database.query(
		"CREATE TABLE IF NOT EXISTS sopa_intentos (" +
		"NU_INTENTO INTEGER PRIMARY KEY AUTOINCREMENT, " +
		"NU_USU INTEGER NOT NULL, " +
		"NM_ALUMNO TEXT NOT NULL, " +
		"NU_NIVEL INTEGER NOT NULL, " +
		"NU_PUNTOS INTEGER NOT NULL DEFAULT 0, " +
		"NU_ESTRELLAS INTEGER NOT NULL DEFAULT 0, " +
		"SW_COM INTEGER NOT NULL DEFAULT 0, " +
		"FE_INTENTO TEXT NOT NULL);"
	)
	database.query(
		"CREATE TABLE IF NOT EXISTS sopa_niveles (" +
		"NU_NIVEL INTEGER NOT NULL, " +
		"NU_USU INTEGER NOT NULL, " +
		"NM_ALUMNO TEXT NOT NULL, " +
		"NU_PUNTOS INTEGER NOT NULL DEFAULT 0, " +
		"NU_ESTRELLAS INTEGER NOT NULL DEFAULT 0, " +
		"SW_COM INTEGER NOT NULL DEFAULT 0, " +
		"PRIMARY KEY (NU_NIVEL, NU_USU));"
	)

static func ensure_columnas_tables(database: SQLite) -> void:
	if database == null:
		return
	database.query(
		"CREATE TABLE IF NOT EXISTS columnas_intentos (" +
		"NU_INTENTO INTEGER PRIMARY KEY AUTOINCREMENT, " +
		"NU_USU INTEGER NOT NULL, " +
		"NM_ALUMNO TEXT NOT NULL, " +
		"NU_NIVEL INTEGER NOT NULL, " +
		"NU_PUNTOS INTEGER NOT NULL DEFAULT 0, " +
		"NU_ESTRELLAS INTEGER NOT NULL DEFAULT 0, " +
		"SW_COM INTEGER NOT NULL DEFAULT 0, " +
		"FE_INTENTO TEXT NOT NULL);"
	)
	database.query(
		"CREATE TABLE IF NOT EXISTS columnas_niveles (" +
		"NU_NIVEL INTEGER NOT NULL, " +
		"NU_USU INTEGER NOT NULL, " +
		"NM_ALUMNO TEXT NOT NULL, " +
		"NU_PUNTOS INTEGER NOT NULL DEFAULT 0, " +
		"NU_ESTRELLAS INTEGER NOT NULL DEFAULT 0, " +
		"SW_COM INTEGER NOT NULL DEFAULT 0, " +
		"PRIMARY KEY (NU_NIVEL, NU_USU));"
	)

static func ensure_memoria_tables(database: SQLite) -> void:
	if database == null:
		return
	database.query(
		"CREATE TABLE IF NOT EXISTS memoria_intentos (" +
		"NU_INTENTO INTEGER PRIMARY KEY AUTOINCREMENT, " +
		"NU_USU INTEGER NOT NULL, " +
		"NM_ALUMNO TEXT NOT NULL, " +
		"NU_NIVEL INTEGER NOT NULL, " +
		"NU_PUNTOS INTEGER NOT NULL DEFAULT 0, " +
		"NU_ESTRELLAS INTEGER NOT NULL DEFAULT 0, " +
		"SW_COM INTEGER NOT NULL DEFAULT 0, " +
		"FE_INTENTO TEXT NOT NULL);"
	)
	database.query(
		"CREATE TABLE IF NOT EXISTS memoria_niveles (" +
		"NU_NIVEL INTEGER NOT NULL, " +
		"NU_USU INTEGER NOT NULL, " +
		"NM_ALUMNO TEXT NOT NULL, " +
		"NU_PUNTOS INTEGER NOT NULL DEFAULT 0, " +
		"NU_ESTRELLAS INTEGER NOT NULL DEFAULT 0, " +
		"SW_COM INTEGER NOT NULL DEFAULT 0, " +
		"PRIMARY KEY (NU_NIVEL, NU_USU));"
	)

static func ensure_alumnos_minijuego_columns(database: SQLite) -> void:
	if database == null:
		return
	database.query("PRAGMA table_info(Alumnos);")
	var columnas_existentes: Array = []
	for col in database.query_result:
		columnas_existentes.append(col["name"])
	if not "NU_NIVEL_MAX_SOPA" in columnas_existentes:
		database.query("ALTER TABLE Alumnos ADD COLUMN NU_NIVEL_MAX_SOPA INTEGER DEFAULT 1;")
	if not "NU_NIVEL_MAX_COLUMNAS" in columnas_existentes:
		database.query("ALTER TABLE Alumnos ADD COLUMN NU_NIVEL_MAX_COLUMNAS INTEGER DEFAULT 1;")
	if not "NU_NIVEL_MAX_MEMORIA" in columnas_existentes:
		database.query("ALTER TABLE Alumnos ADD COLUMN NU_NIVEL_MAX_MEMORIA INTEGER DEFAULT 1;")
	# BUG-04: trackers de nivel independientes para los minijuegos textuales.
	if not "NU_NIVEL_MAX_COMPLETAR" in columnas_existentes:
		database.query("ALTER TABLE Alumnos ADD COLUMN NU_NIVEL_MAX_COMPLETAR INTEGER DEFAULT 1;")
	if not "NU_NIVEL_MAX_AHORCADO" in columnas_existentes:
		database.query("ALTER TABLE Alumnos ADD COLUMN NU_NIVEL_MAX_AHORCADO INTEGER DEFAULT 1;")

static func log_activity(database: SQLite, tipo_usuario: String, usuario: String, accion: String, es_parte_de_transaccion: bool = false) -> void:
	if database == null:
		return
	# Solo iniciamos transacción si NO venimos de otra transacción
	if not es_parte_de_transaccion:
		database.query("BEGIN TRANSACTION;")
		ensure_activity_table(database)
		var fecha := Time.get_datetime_string_from_system().replace("T", " ")
		var query := "INSERT INTO actividad (TX_TIPO_USUARIO, TX_USUARIO, TX_ACCION, TX_FECHA) VALUES ('%s', '%s', '%s', '%s');" % [
			escape(tipo_usuario),
			escape(usuario),
			escape(accion),
			escape(fecha)
		]
		database.query(query)
	# Solo hacemos commit si nosotros iniciamos la transacción
	if not es_parte_de_transaccion:
		database.query("COMMIT;")
