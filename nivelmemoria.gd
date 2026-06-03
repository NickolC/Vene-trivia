extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

class ParMemoria:
	var id: int
	var termino: String
	var pista: String
	func _init(_id: int, _termino: String, _pista: String):
		self.id = _id
		self.termino = _termino
		self.pista = _pista

const ESCENA_CARTA = preload("res://CartaMemoria.tscn")
const RUTA_SELECTOR := "res://Scenes/Minijuegos.tscn"
const RUTA_DATOS_MEMORIA := "res://Data/minijuegos/memoria.json"

# Tiempos límite por nivel para calcular estrellas (segundos)
const TIEMPO_3_ESTRELLAS := 90.0
const TIEMPO_2_ESTRELLAS := 180.0

var banco_memoria_runtime: Dictionary = {}
var banco_parejas: Array[ParMemoria] = []

@onready var contenedor_cartas: GridContainer = $ContenedorCartas

var primera_carta: CartaMemoria = null
var segunda_carta: CartaMemoria = null
var bloqueado: bool = false
var parejas_restantes: int = 0

var db: SQLite
var numero_de_nivel: int = 1
var _tiempo_inicio_ms: int = 0
var _errores: int = 0

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	numero_de_nivel = maxi(1, int(GlobalUsuario.nivel_seleccionado))
	_cargar_banco_memoria_desde_archivo()
	banco_parejas = _obtener_parejas_del_nivel(numero_de_nivel)
	if banco_parejas.is_empty():
		Alertas.mostrar_alerta("No hay contenido configurado para este nivel.", 2.5)
		Configuracion.change_scene_to_file(RUTA_SELECTOR)
		return

	contenedor_cartas.columns = 4
	parejas_restantes = banco_parejas.size()
	_tiempo_inicio_ms = Time.get_ticks_msec()
	inicializar_tablero()

func inicializar_tablero() -> void:
	var lista: Array = []
	for par in banco_parejas:
		var carta_img := ESCENA_CARTA.instantiate() as CartaMemoria
		carta_img.configurar(par.id, par.termino, par.pista, false)
		carta_img.carta_seleccionada.connect(_on_carta_seleccionada)
		lista.append(carta_img)

		var carta_txt := ESCENA_CARTA.instantiate() as CartaMemoria
		carta_txt.configurar(par.id, par.termino, par.pista, true)
		carta_txt.carta_seleccionada.connect(_on_carta_seleccionada)
		lista.append(carta_txt)

	lista.shuffle()
	for hijo in contenedor_cartas.get_children():
		hijo.queue_free()
	for carta in lista:
		contenedor_cartas.add_child(carta)

func _on_carta_seleccionada(carta: CartaMemoria) -> void:
	if bloqueado: return
	carta.voltear_boca_arriba()
	if primera_carta == null:
		primera_carta = carta
	else:
		segunda_carta = carta
		bloqueado = true
		_comprobar_pareja()

func _comprobar_pareja() -> void:
	if primera_carta.id_pareja == segunda_carta.id_pareja and primera_carta.es_texto != segunda_carta.es_texto:
		primera_carta.marcar_acierto()
		segunda_carta.marcar_acierto()
		parejas_restantes -= 1
		_limpiar_seleccion_turno()
		if parejas_restantes == 0:
			finalizar_juego_victoria()
	else:
		_errores += 1
		primera_carta.marcar_error()
		segunda_carta.marcar_error()
		await get_tree().create_timer(1.2).timeout
		if is_instance_valid(primera_carta): primera_carta.mostrar_boca_abajo()
		if is_instance_valid(segunda_carta): segunda_carta.mostrar_boca_abajo()
		_limpiar_seleccion_turno()

func _limpiar_seleccion_turno() -> void:
	primera_carta = null
	segunda_carta = null
	bloqueado = false

func finalizar_juego_victoria() -> void:
	var tiempo_seg := float(Time.get_ticks_msec() - _tiempo_inicio_ms) / 1000.0
	var estrellas := _calcular_estrellas(tiempo_seg)
	var puntos := estrellas * 100 + maxi(0, 50 - _errores * 5)

	_guardar_progreso(puntos, estrellas)

	var msg := "¡Victoria! %d estrella(s) — %.0fs — %d error(es)" % [estrellas, tiempo_seg, _errores]
	Alertas.mostrar_alerta(msg, 4.0)

	await get_tree().create_timer(4.5).timeout
	if is_instance_valid(self):
		Configuracion.change_scene_to_file(RUTA_SELECTOR)

func _calcular_estrellas(tiempo_seg: float) -> int:
	if tiempo_seg <= TIEMPO_3_ESTRELLAS:
		return 3
	if tiempo_seg <= TIEMPO_2_ESTRELLAS:
		return 2
	return 1

func _guardar_progreso(puntos: int, estrellas: int) -> void:
	if db == null:
		return
	var id := GlobalUsuario.usuario_actual_id
	var nombre := SQLiteHelper.escape(GlobalUsuario.nombre_alumno)
	var completado := 1 if estrellas == 3 else 0
	var fecha := Time.get_datetime_string_from_system().replace("T", " ")

	db.query(
		"INSERT INTO memoria_intentos (NU_USU, NM_ALUMNO, NU_NIVEL, NU_PUNTOS, NU_ESTRELLAS, SW_COM, FE_INTENTO) VALUES (%d, '%s', %d, %d, %d, %d, '%s');" % [id, nombre, numero_de_nivel, puntos, estrellas, completado, SQLiteHelper.escape(fecha)]
	)

	db.query("SELECT NU_ESTRELLAS FROM memoria_niveles WHERE NU_USU = %d AND NU_NIVEL = %d;" % [id, numero_de_nivel])
	if db.query_result.is_empty():
		db.query(
			"INSERT INTO memoria_niveles (NU_NIVEL, NU_USU, NM_ALUMNO, NU_PUNTOS, NU_ESTRELLAS, SW_COM) VALUES (%d, %d, '%s', %d, %d, %d);" % [numero_de_nivel, id, nombre, puntos, estrellas, completado]
		)
	else:
		var prev_est := int(db.query_result[0].get("NU_ESTRELLAS", 0))
		if estrellas > prev_est:
			db.query(
				"UPDATE memoria_niveles SET NU_PUNTOS = %d, NU_ESTRELLAS = %d, SW_COM = %d WHERE NU_NIVEL = %d AND NU_USU = %d;" % [puntos, estrellas, completado, numero_de_nivel, id]
			)

	var prox := numero_de_nivel + 1
	db.query("UPDATE Alumnos SET NU_NIVEL_MAX_MEMORIA = %d WHERE NU_USU = %d AND NU_NIVEL_MAX_MEMORIA < %d;" % [prox, id, prox])

	SQLiteHelper.mirror_minijuegos_resultados(db, id, GlobalUsuario.nombre_alumno, "memoria", puntos, estrellas)

	db.query("SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d;" % id)
	var dinero_total := 0
	if not db.query_result.is_empty():
		dinero_total = int(db.query_result[0].get("NU_DINERO", 0))
	Logros.evaluar_post_nivel(estrellas, puntos, dinero_total)

func _cargar_banco_memoria_desde_archivo() -> void:
	banco_memoria_runtime.clear()
	if not FileAccess.file_exists(RUTA_DATOS_MEMORIA):
		return
	var archivo := FileAccess.open(RUTA_DATOS_MEMORIA, FileAccess.READ)
	if archivo == null:
		return
	var parsed: Variant = JSON.parse_string(archivo.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var parsed_dict: Dictionary = parsed
	banco_memoria_runtime = parsed_dict

func _obtener_parejas_del_nivel(nivel: int) -> Array[ParMemoria]:
	var resultado: Array[ParMemoria] = []
	var clave := str(nivel)
	if not banco_memoria_runtime.has(clave):
		return resultado

	var filas_raw: Variant = banco_memoria_runtime[clave]
	if typeof(filas_raw) != TYPE_ARRAY:
		return resultado
	var filas: Array = filas_raw

	var id_local := 1
	for fila in filas:
		if typeof(fila) != TYPE_DICTIONARY:
			continue
		var termino := str(fila.get("termino", "")).strip_edges()
		var pista := str(fila.get("pista", "")).strip_edges()
		if termino.is_empty() or pista.is_empty():
			continue
		resultado.append(ParMemoria.new(id_local, termino, pista))
		id_local += 1

	return resultado
