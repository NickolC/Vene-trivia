extends Control

var db : SQLite
var nivel_actual: int 
var costopor: int
var costopub: int
var costomid: int

@onready var label_dinero = $TextureRect2/HBoxContainer/moneda
@onready var precioPor = $TextureRect2/VBoxContainer/Precio
@onready var precioPub = $TextureRect2/VBoxContainer2/Precio
@onready var precioMid = $TextureRect2/VBoxContainer3/Precio
@onready var compra = $TextureRect2/confrimarcomodines/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Label

func _ready():
	# En el script de tu Nivel o Escena de Juego
	db = SQLite.new()
	db.path = "res://DB/venetrivia.db"
	db.open_db()
	
	var query = ("SELECT * FROM Alumnos WHERE NM_ALUMNO = '%s';" % GlobalUsuario.nombre_alumno)
	db.query(query)
	
	var resultado = db.query_result # Esto devuelve un Array de Diccionarios
	if resultado.size() > 0:
		# ¡Éxito! El primer elemento [0] tiene nuestro ID
		GlobalUsuario.nombre_alumno = resultado[0]["NM_ALUMNO"]
		print("Sesión iniciada como: ", GlobalUsuario.nombre_alumno)
	else:
		print("El alumno no existe en la base de datos.")
	
	# Al abrir el menú, cargamos lo que ya estaba guardado
	Configuracion.cargar_ajustes()
	costopor =100
	costopub = 150
	costomid = 200
	
	precioPor.text = str(costopor) + "Bs."
	precioPub.text = str(costopub) + "Bs."
	precioMid.text = str(costomid) + "Bs."
	
	actualizar_dinero_visual()

func actualizar_dinero_visual():
	var id_usu = GlobalUsuario.usuario_actual_id
	
	# 1. Consultamos el campo de dinero (PUNTOS_TOTALES) en la tabla Alumnos
	var query = "SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d" % id_usu
	db.query(query)
	
	# 2. Verificamos que la consulta devolvió resultados
	if db.query_result.size() > 0:
		var dinero_actual = db.query_result[0]["NU_DINERO"]
		
		# 3. Formateamos el texto del Label
		# Usamos str() para convertir el número a texto
		label_dinero.text = str(dinero_actual) + "Bs."
		
		print("Dinero cargado en interfaz: ", dinero_actual)
	else:
		label_dinero.text = "0 Bs."
		print("No se encontraron datos para el usuario.")

func _on_buttonporcentaje_pressed() -> void:
	$TextureRect2/confrimarcomodines.visible = true
	compra.text = "
	
	¿Deseas comprar el comodin de Votacion del publico? el precio es de " + precioPor.text + "
	
	"


func _on_aceptar_pressed(costo: int):
	var id_usu = GlobalUsuario.usuario_actual_id
	# 1. Obtenemos el dinero actualizado directamente de la base de datos
	var query_puntos = "SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d" % id_usu
	db.query(query_puntos)
	if db.query_result.size() > 0:
		# Extraemos el valor del diccionario resultante
		var puntos_en_db = db.query_result[0]["NU_DINERO"]
		# 2. Ahora sí hacemos la comparación con el campo de la tabla
		if puntos_en_db >= costo:
			# Proceder con la compra...
			print("Compra autorizada. Puntos actuales: ", puntos_en_db)
			# Aquí vendría tu UPDATE para restar el costo
			var query_restar = "UPDATE Alumnos SET NU_DINERO = NU_DINERO - %d WHERE NU_USU = %d" % [costo, id_usu]
			db.query(query_restar)
			Alertas.mostrar_alerta("Compra realizada con éxito", 1.0)
			actualizar_dinero_visual()
		else:
			Alertas.mostrar_alerta("No tienes suficientes puntos acumulados", 1.0)
	else:
		print("Error: No se encontró al usuario en la base de datos.")

func comprar_nivel_extra(tipo: String, num_nivel: int, costo: int):
	costo = 500
	var id_usu = GlobalUsuario.usuario_actual_id
	# 1. Verificar si ya lo compró anteriormente
	var query_check = "SELECT * FROM Tienda WHERE NU_USU = %d AND TP_MINIJUEGO = '%s' AND NV_EXTRA = %d" % [id_usu, tipo, num_nivel]
	db.query(query_check)
	if db.query_result.size() > 0:
		Alertas.mostrar_alerta("Ya posees este nivel", 1.0)
		return
		# 2. Si no lo tiene, verificar puntos y comprar
	var query_puntos = "SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d" % id_usu
	db.query(query_puntos)
	if db.query_result.size() > 0:
		# Extraemos el valor del diccionario resultante
		var puntos_en_db = db.query_result[0]["NU_DINERO"]
		# 2. Ahora sí hacemos la comparación con el campo de la tabla
		if puntos_en_db >= costo:
			# Proceder con la compra...
			print("Compra autorizada. Puntos actuales: ", puntos_en_db)
			# Insertar en inventario
			var query_insert = "INSERT INTO Tienda (NU_USU, TP_MINIJUEGO, NV_EXTRA) VALUES (%d, '%s', %d)" % [id_usu, tipo, num_nivel]
			db.query(query_insert)
			# Aquí vendría tu UPDATE para restar el costo
			var query_restar = "UPDATE Alumnos SET NU_DINERO = NU_DINERO - %d WHERE NU_USU = %d" % [costo, id_usu]
			db.query(query_restar)
			Alertas.mostrar_alerta("Compra realizada con éxito", 1.0)
			actualizar_dinero_visual()
		else:
			Alertas.mostrar_alerta("No tienes suficientes puntos acumulados", 1.0)
	else:
		print("Error: No se encontró al usuario en la base de datos.")


func _on_cancelar2_pressed() -> void:
	$TextureRect2/confrimarcomodines.visible = false
	
func _on_cancelar3_pressed() -> void:
	$TextureRect2/confirmarniveles.visible = false


func _on_tienda_2_pressed() -> void:
	$TextureRect.visible = false
	$TextureRect2.visible = true
	$TextureRect4.visible = false
	actualizar_dinero_visual()

func _on_cancelar_2_pressed() -> void:
	$TextureRect.visible = false
	$TextureRect2.visible = false
	$TextureRect4.visible = true


func _on_perfil_pressed() -> void:
	$TextureRect.visible = true
	$TextureRect2.visible = false
	$TextureRect4.visible = false


func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Login.tscn")

func _on_volvermenu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menu-alumno.tscn")
