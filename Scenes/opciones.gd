extends Control

var db : SQLite
var nivel_actual: int 
var costopor: int
var costopub: int
var costomid: int

@onready var slider_brillo = $"TextureRect3/Guardar/Volumen Maestro/Brillo"
@onready var slider_gamma = $"TextureRect3/Guardar/Volumen Maestro/Brillo/Gamma"
@onready var check_full = $"TextureRect3/Pantalla Completa"
@onready var option_res = $TextureRect3/Resolucion
@onready var label_dinero = $TextureRect2/HBoxContainer/moneda
@onready var precioPor = $TextureRect2/VBoxContainer/Precio
@onready var precioPub = $TextureRect2/VBoxContainer2/Precio
@onready var precioMid = $TextureRect2/VBoxContainer3/Precio

@onready var volumen_maestro = $"TextureRect3/Guardar/Volumen Maestro"
@onready var musica = $"TextureRect3/Guardar/Volumen Maestro/Musica"
@onready var efectos = $"TextureRect3/Guardar/Volumen Maestro/Musica/Efectos"

@onready var compra = $TextureRect2/confrimarcomodines/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Label

# Creamos un diccionario para asociar el índice del botón con una resolución real
const RESOLUTIONS: Dictionary = {
	0: Vector2i(1920, 1080),
	1: Vector2i(1280, 720),
	2: Vector2i(640, 480)
}

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
	actualizar_ui_con_valores()
	# Opcional: Seleccionar por defecto la resolución actual al abrir el menú
	_on_resolucion_item_selected(0)
	# Revisa si ya estamos en pantalla completa y marca el botón
	var es_full = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	$"TextureRect3/Pantalla Completa".button_pressed = es_full
	costopor =100
	costopub = 150
	costomid = 200
	
	precioPor.text = str(costopor) + "Bs."
	precioPub.text = str(costopub) + "Bs."
	precioMid.text = str(costomid) + "Bs."
	
	actualizar_dinero_visual()


func actualizar_ui_con_valores():
	# Sincronizamos los nodos visuales con las variables del Singleton
	slider_brillo.value = Configuracion.brillo
	slider_gamma.value = Configuracion.saturacion
	check_full.button_pressed = Configuracion.fullscreen
	option_res.selected = Configuracion.res_index
	
	# Aplicamos los cambios al motor (opcional, si quieres que se vea al instante)
	aplicar_todo()

func aplicar_todo():
	# Lógica para aplicar pantalla completa, resolución, etc.
	if Configuracion.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Aplicar a WorldEnvironment (ajusta la ruta según tu escena)
	var env = get_tree().root.find_child("res://Scenes/menu-alumno.tscn/$Fondo/WorldGamma", true, false)
	if env:
		env.environment.adjustments_enabled = true
		env.environment.adjustment_brightness = Configuracion.brillo
		env.environment.adjustment_saturation = Configuracion.saturacion
		env.environment.adjustment_contrast = Configuracion.contraste

func _on_resolucion_item_selected(index: int) -> void:
	# Obtenemos la resolución del diccionario usando el índice seleccionado
	var target_resolution = RESOLUTIONS[index]
	
	# Cambiamos el tamaño de la ventana (Solo Godot 4+)
	DisplayServer.window_set_size(target_resolution)
	
	# Centramos la ventana después del cambio
	var screen_center = DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2)
	var window_size = DisplayServer.window_get_size()
	DisplayServer.window_set_position(screen_center - (window_size / 2))
	
	pass # Replace with function body.


func _on_pantalla_completa_toggled(toggled_on: bool) -> void:
	if toggled_on:
		# Activar Pantalla Completa
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		# Volver a Modo Ventana
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	pass # Replace with function body.

func _on_brillo_value_changed(value: float) -> void:
	# Guardamos el valor globalmente
	Configuracion.brillo = value
	
	# Buscamos el WorldEnvironment que esté vivo en la escena actual
	var world_env = get_tree().root.find_child("WorldGamma", true, false)
	if world_env:
		Configuracion.aplicar_ajustes(world_env.environment)
	pass # Replace with function body.

func _on_gamma_value_changed(value: float) -> void:
	# Guardamos el valor globalmente
	Configuracion.saturacion = value
	# Buscamos el WorldEnvironment que esté vivo en la escena actual
	var world_env = get_tree().root.find_child("WorldGamma", true, false)
	if world_env:
		Configuracion.aplicar_ajustes(world_env.environment)
	pass # Replace with function body.

# --- BOTÓN GUARDAR ---
func _on_guardar_pressed() -> void:
	# Antes de guardar, capturamos los valores actuales de la UI
	guardar_todo()
	Alertas.mostrar_alerta("Ajustes guardados con éxito.", 1.0)
	print("Ajustes guardados con éxito.")
	
	#Configuracion.brillo = slider_brillo.value
	#Configuracion.brillo = slider_gamma.value
	#Configuracion.saturacion = slider_gamma.value
	#Configuracion.contraste = slider_gamma.value
	#Configuracion.fullscreen = check_full.button_pressed
	#Configuracion.res_index = option_res.selected
	#Configuracion.guardar_ajustes()
	#Alertas.mostrar_alerta("Ajustes guardados con éxito.", 1.0)
	#print("Ajustes guardados con éxito.")
	#pass # Replace with function body.

# --- BOTÓN RESTABLECER ---
func _on_restablecer_pressed() -> void:
	# Volvemos a las constantes por defecto
	Configuracion.brillo = Configuracion.DEFAULT_BRILLO
	Configuracion.saturacion = Configuracion.DEFAULT_SATURATION
	Configuracion.contraste = Configuracion.DEFAULT_CONTRAST
	Configuracion.fullscreen = Configuracion.DEFAULT_FULLSCREEN
	Configuracion.res_index = Configuracion.DEFAULT_RES_INDEX
	
	# Actualizamos la visualización de los sliders/botones
	actualizar_ui_con_valores()
	Alertas.mostrar_alerta("Ajustes restablecidas con éxito.", 1.0)
	print("Ajustes guardados con éxito.")
	pass # Replace with function body.


func _on_cancelar_pressed() -> void:
	#$TextureRect.visible = false
	$TextureRect2.visible = false
	$TextureRect3.visible = false
	$TextureRect4.visible = true
	
	pass # Replace with function body.


func _on_opciones_pressed() -> void:
	#$TextureRect.visible = false
	$TextureRect2.visible = false
	$TextureRect3.visible = true
	$TextureRect4.visible = false
	pass # Replace with function body.


func _on_volvermenu_pressed() -> void:
	# 1. Llamamos a la función que guarda los datos en el archivo .cfg o .json
	# Esta es la misma función que usa tu botón "Guardar"
	guardar_todo()
	Alertas.mostrar_alerta("Ajustes guardados automáticamente.", 1.0)
	print("Ajustes guardados automáticamente.")
	Configuracion.change_scene_to_file("res://Scenes/menu-alumno.tscn")
	
	
	# Esta es la función que ya deberías tener para tu botón de "Guardar"
func guardar_todo():
	# Actualizamos las variables del Singleton (Autoload) con los valores de la UI
	Configuracion.brillo = slider_brillo.value
	Configuracion.saturacion = slider_gamma.value
	Configuracion.contraste = slider_gamma.value
	#Configuracion.volumen_maestro = volumen_maestro.value
	#Configuracion.volumen_musica = musica.value
	#Configuracion.volumen_sfx = efectos.value
	Configuracion.fullscreen = check_full.button_pressed
	Configuracion.res_index = option_res.selected
	
	# Llamamos al método del Singleton que escribe el archivo en el disco (user://)
	Configuracion.guardar_ajustes()

func _on_salir_pressed() -> void:
	Configuracion.change_scene_to_file("res://Scenes/Alumno.tscn")


func _on_tienda_pressed() -> void:
	#$TextureRect.visible = false
	$TextureRect2.visible = true
	$TextureRect3.visible = false
	$TextureRect4.visible = false
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


func _on_perfil_pressed() -> void:
	#$TextureRect.visible = true
	$TextureRect2.visible = false
	$TextureRect3.visible = false
	$TextureRect4.visible = false

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
