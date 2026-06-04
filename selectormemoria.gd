extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite

# !!! NUEVAS VARIABLES ADAPTADAS !!!
# Usamos una variable de progreso específica para este selector (por defecto el nivel máximo alcanzado aquí es el 1, o el que desees)
var nivel_maximo_sopa: int = 1 

# Lista de IDs de niveles especiales que se compran en la tienda
var niveles_tienda: Array[int] = [11, 12, 13, 14, 15]


const ESTRELLA_LLENA = preload("res://GFX/nivelpasadolleno.png")
const ESTRELLA_VACIA = preload("res://GFX/nivelpasado.png")

@onready var estrella_1: TextureRect = $PrevNiveles/MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer/TextureRect
@onready var estrella_2: TextureRect = $PrevNiveles/MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer/TextureRect2
@onready var estrella_3: TextureRect = $PrevNiveles/MarginContainer/VBoxContainer/MarginContainer3/HBoxContainer/TextureRect3

var nivel_seleccionado_temp: int = -1

const TEMAS_NIVELES: Dictionary = {
	1: "Tema: El Reino del Agua",
	2: "Tema: Amalivaca y el Orinoco",
	3: "Tema: Las Perlas de Cubagua",
	4: "Tema: Piratas en el Caribe",
	5: "Tema: Miranda, el Viajero",
	6: "Tema: El 19 de Abril",
	7: "Tema: La Batalla de Carabobo",
	8: "Tema: Las Heroinas",
	9: "Tema: El Congreso de Angostura",
	10: "Tema: La Abolición",
	11: "Tema: El Tren de Guzmán Blanco",
	12: "Tema: El Reventón Petrolero",
	13: "Tema: La Ciudad Universitaria",
	14: "Tema: Inventores Venezolanos",
	15: "Tema: Venezuela en el Mundo"
}

@onready var Prevnivel = $PrevNiveles/Label2
@onready var prevtema = $PrevNiveles/MarginContainer/VBoxContainer/MarginContainer2/Label
@onready var contenedor1: HBoxContainer = $VBoxContainer/HBoxContainer
@onready var contenedor2: HBoxContainer = $VBoxContainer/HBoxContainer2
@onready var contenedor3: HBoxContainer = $VBoxContainer/HBoxContainer3

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	_cargar_usuario_actual()
	$PrevNiveles.hide() 
	configurar_selector()

func _exit_tree() -> void:
	if db:
		SQLiteHelper.close_db_connection(db)
		db = null 

func _on_atras_pressed() -> void:
	Configuracion.change_scene_to_file("res://Scenes/Minijuegos.tscn")

# LÓGICA DE CONFIGURACIÓN ADAPTADA
func configurar_selector() -> void:
	if contenedor1 == null or contenedor2 == null or contenedor3 == null:
		print("❌ ERROR CRÍTICO: Uno de los contenedores HBox es NULL. Revisa los @onready.")
		return

	var todos_los_nodos: Array[Node] = []
	todos_los_nodos.append_array(contenedor1.get_children())
	todos_los_nodos.append_array(contenedor2.get_children())
	todos_los_nodos.append_array(contenedor3.get_children())
	
	print("--- INICIANDO CONFIGURACIÓN DE BOTONES (Total encontrados: ", todos_los_nodos.size(), ") ---")
	
	for i in range(todos_los_nodos.size()):
		var n_nivel := i + 1
		var nodo_actual := todos_los_nodos[i]
		
		# BUSCADOR AUTOMÁTICO DE BOTONES:
		# Si el nodo no es un botón, pero tiene un botón adentro, lo buscamos de forma recursiva o directa
		var btn: Button = null
		if nodo_actual is Button:
			btn = nodo_actual
		else:
			# Si metiste el botón dentro de un panel/caja, esto busca el botón adentro
			for sub_hijo in nodo_actual.get_children():
				if sub_hijo is Button:
					btn = sub_hijo
					break
		
		# Si de verdad no hay ningún botón aquí, avisamos en consola
		if btn == null:
			print("⚠️ Alerta en Índice ", i, " (Nivel ", n_nivel, "): El nodo se llama '", nodo_actual.name, "' pero NO contiene ningún botón.")
			continue

		print("✅ Configurando exitosamente el botón del Nivel ", n_nivel, " (Nodo: ", btn.name, ")")

		# Configuración de clics y bloqueos (Tu lógica corregida)
		if n_nivel in niveles_tienda:
			var comprado: bool = _verificar_si_nivel_esta_comprado(n_nivel)
			if comprado:
				desbloquear_boton(btn, n_nivel)
			else:
				configurar_boton_bloqueado_tienda(btn, n_nivel)
		elif n_nivel <= 15:
			desbloquear_boton(btn, n_nivel)
		else:
			bloquear_boton_por_progreso(btn)
			
	print("--- FIN DE CONFIGURACIÓN ---")

func desbloquear_boton(btn: Button, num: int) -> void:
# 1. Asegurar propiedades físicas del botón
	btn.disabled = false
	btn.process_mode = Node.PROCESS_MODE_INHERIT # Fuerza a que no esté pausado
	btn.visible = true
	btn.modulate = Color.WHITE
	
	# 2. Forzar que el ratón no sea bloqueado por el propio botón o sus hijos
	btn.mouse_filter = Control.MOUSE_FILTER_STOP # El botón DEBE detener el mouse para hacer click
	for hijo in btn.get_children():
		if hijo is Control:
			hijo.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 3. Limpiar conexiones viejas de manera agresiva
	if btn.pressed.is_connected(_on_nivel_seleccionado_desde_mapa):
		btn.pressed.disconnect(_on_nivel_seleccionado_desde_mapa)
	_desconectar_senales_boton(btn)

	# 4. Conexión limpia y directa usando la nueva sintaxis de Godot 4
	# En lugar de usar Callable.bind(), usamos una función anónima (lambda) que es infalible
	btn.pressed.connect(func(): 
		_on_nivel_seleccionado_desde_mapa(num)
	)
	
	print("🔌 Conexión forzada exitosa para Nivel ", num, " en el botón: ", btn.name)

# NUEVA FUNCIÓN: Mantiene el botón clickeable pero avisa que requiere la tienda
func configurar_boton_bloqueado_tienda(btn: Button, num: int) -> void:
	btn.disabled = false # Permitimos el clic para que salte la advertencia
	btn.modulate = Color(0.4, 0.4, 0.4, 0.9) # Apariencia visual de bloqueado
	
	# Desconectamos cualquier lógica de nivel previa que tuviera el botón
	_desconectar_senales_boton(btn)
	
	# Evitamos que los elementos hijos (textos, texturas) interfieran con el clic
	for hijo in btn.get_children():
		if hijo is Control:
			hijo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Conexión directa y limpia mediante una función lambda
	btn.pressed.connect(func():
		_on_nivel_bloqueado_tienda_pressed(num)
	)
	
	print("🛒 Nivel ", num, " configurado como: Bloqueado por Tienda.")

func bloquear_boton_por_progreso(btn: Button):
	btn.disabled = true
	btn.modulate = Color(0.3, 0.3, 0.3, 0.8)

func _verificar_si_nivel_esta_comprado(num: int) -> bool:
	return SQLiteHelper.nivel_comprado(db, GlobalUsuario.usuario_actual_id, "memoria", num)

# NUEVA FUNCIÓN INTERMEDIA: Se ejecuta al presionar un nivel de pago no adquirido
func _on_nivel_bloqueado_tienda_pressed(num: int) -> void:
	print("❌ Intento de acceso denegado al nivel de tienda: ", num)
	_mostrar_alerta("¡Nivel Bloqueado! Debes canjear este nivel en la Tienda.")

# Limpia conexiones viejas del botón para poder reutilizarlo sin duplicar clics
func _desconectar_senales_boton(btn: Button) -> void:
	for conexion in btn.pressed.get_connections():
		btn.pressed.disconnect(conexion.callable)

func _on_nivel_seleccionado_desde_mapa(num: int) -> void:
	print("🚀 ¡FUNCIÓN EJECUTADA! Se presionó el nivel: ", num)
	nivel_seleccionado_temp = num 
	var tema: String = TEMAS_NIVELES.get(num, "Tema Desconocido")
	
	Prevnivel.text = "nivelsopa"
	prevtema.text = tema
	
	var cant_estrellas: int = 0 
	var q_estrellas := ""
	
	if GlobalUsuario.usuario_actual_id > 0:
		q_estrellas = "SELECT NU_ESTRELLAS FROM memoria_niveles WHERE NU_NIVEL = %d AND NU_USU = %d LIMIT 1;" % [num, GlobalUsuario.usuario_actual_id]
	else:
		q_estrellas = "SELECT NU_ESTRELLAS FROM memoria_niveles WHERE NU_NIVEL = %d AND NM_ALUMNO = '%s' LIMIT 1;" % [num, SQLiteHelper.escape(GlobalUsuario.nombre_alumno)]
	
	db.query(q_estrellas)
	if db.query_result.size() > 0:
		cant_estrellas = int(db.query_result[0]["NU_ESTRELLAS"])
		print("Nivel ", num, " tiene ", cant_estrellas, " estrellas asignadas.")
	
	if estrella_1:
		estrella_1.texture = ESTRELLA_LLENA if cant_estrellas >= 1 else ESTRELLA_VACIA
	if estrella_2:
		estrella_2.texture = ESTRELLA_LLENA if cant_estrellas >= 2 else ESTRELLA_VACIA
	if estrella_3:
		estrella_3.texture = ESTRELLA_LLENA if cant_estrellas == 3 else ESTRELLA_VACIA
		
	$PrevNiveles/MarginContainer.queue_sort()
	$PrevNiveles.show()

func _on_button_pressed() -> void:
	if nivel_seleccionado_temp != -1:
		_ir_al_nivel(nivel_seleccionado_temp)
	else:
		print("Error: No se ha seleccionado ningún nivel válido.")

func _on_button_4_pressed() -> void:
	nivel_seleccionado_temp = -1 
	$PrevNiveles.hide()

func _ir_al_nivel(n: int) -> void:
	GlobalUsuario.nivel_seleccionado = n
	if db:
		SQLiteHelper.close_db_connection(db)
		db = null 
	
	# Redirige a tu escena correspondiente (Sopa de letras)
	Configuracion.change_scene_to_file("res://nivelmemoria.tscn")

func _cargar_usuario_actual() -> void:
	var query := ""
	if GlobalUsuario.usuario_actual_id > 0:
		query = "SELECT NU_USU, NM_ALUMNO, NU_NIVEL_MAX FROM Alumnos WHERE NU_USU = %d;" % GlobalUsuario.usuario_actual_id
	elif not GlobalUsuario.nombre_alumno.is_empty():
		query = "SELECT NU_USU, NM_ALUMNO, NU_NIVEL_MAX FROM Alumnos WHERE NM_ALUMNO = '%s';" % SQLiteHelper.escape(GlobalUsuario.nombre_alumno)
	else:
		return

	db.query(query)
	if db.query_result.is_empty():
		_mostrar_alerta("No se encontro la sesion del alumno.")
		return

	var resultado: Dictionary = db.query_result[0]
	GlobalUsuario.usuario_actual_id = int(resultado.get("NU_USU", GlobalUsuario.usuario_actual_id))
	GlobalUsuario.nombre_alumno = str(resultado.get("NM_ALUMNO", GlobalUsuario.nombre_alumno))
	# Mantenemos la lectura del usuario, pero recuerda que operamos con 'nivel_maximo_sopa' de forma independiente
	print("Sesion iniciada como: ", GlobalUsuario.nombre_alumno)

func _mostrar_alerta(mensaje: String) -> void:
	var alertas: Node = get_node_or_null("/root/Alertas")
	if alertas and alertas.has_method("mostrar_alerta"):
		alertas.mostrar_alerta(mensaje, 1.0)
	print(mensaje)
