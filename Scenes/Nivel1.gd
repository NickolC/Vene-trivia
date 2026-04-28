extends Node

var numero_de_nivel = GlobalUsuario.nivel_maximo
var nombre_estudiante : String

var db : SQLite

var estrellas_ganadas : int = 0
var puntaje_total : int = 0
var img_estrella_llena = preload("res://GFX/estrella completada.png")
var img_estrella_vacia = preload("res://GFX/estrella vacia.png")

var todas_las_preguntas : Array = []    # Las 40 del JSON
var pool_disponible : Array = []       # Las que aún no han salido
var preguntas_partida_actual : Array = [] # Las 15 de esta ronda
var botones_respuesta = []
var mi_fuente = load("res://GFX/Minecraft.ttf")

var ya_aviso_tiempo_mediano = false
var ya_aviso_tiempo_corto = false # Para que no repita el aviso de 5 segundos

var comodin_usado = false
var comodin_llamada_usado = false
var comodin_publico_usado = false

var lista_circulos = [] # Aquí guardaremos los iconos

@onready var sprite_personaje = $capapersonaje/SpritePersonaje
@onready var panel_dialogo = $capapersonaje/PanelContainer
@onready var label_dialogo = $capapersonaje/PanelContainer/MarginContainer/Label

# Cargar tus PNGs (Asegúrate de que las rutas sean correctas)
var pose_normal = preload("res://GFX/normal.png")
var pose_feliz = preload("res://GFX/Feliz.png")
var pose_preocupado = preload("res://GFX/preocupado.png")
var pose_pensativo = preload("res://GFX/pensativo.png")

@onready var contenedor_progreso = $barraprogreso/Control/HBoxContainer
@onready var textura_gris = preload("res://GFX/gris.png")
@onready var textura_verde = preload("res://GFX/verde.png")
@onready var textura_roja = preload("res://GFX/rojo.png")

# Referencia de los nodos de la UI
@onready var fondo_pregunta = $CanvasLayer2/CenterContainer/PanelContainer
@onready var label_pregunta = $CanvasLayer2/CenterContainer/PanelContainer/MarginContainer/Label
@onready var contenedor_botones = $CanvasLayer2/GridContainer
@onready var timer_pregunta = $CanvasLayer2/Timer
@onready var barra_tiempo = $CanvasLayer2/Timer/ProgressBar

@onready var panel_llamada = $CanvasLayer/CenterContainer/PanelContainer
@onready var texto_llamada = $CanvasLayer/CenterContainer/PanelContainer/MarginContainer/HBoxContainer/Label
@onready var timer_llamada = Timer.new()

@onready var menu_pausa = $Menupausa
@onready var capa_confirmacion = $confrimar

@onready var label_puntaje = $Labelpuntaje

var indice_actual = 0
var puntos = 0

func decir_mensaje(texto: String, tiempo: float = 3.0):
	label_dialogo.show() 
	if label_dialogo.get_parent(): label_dialogo.get_parent().show() # MarginContainer
	
	# 2. Asignamos el texto ANTES de mostrar el panel
	label_dialogo.text = texto
	
	
	# 4. Animación de aparición
	var tween = create_tween()
	panel_dialogo.modulate.a = 0
	panel_dialogo.show() # Mostramos el PanelContainer principal
	tween.tween_property(panel_dialogo, "modulate:a", 1.0, 0.3)
	
	# Debug para confirmar en consola
	print("Texto asignado: ", label_dialogo.text)
	
	await get_tree().create_timer(tiempo).timeout
	
	# 5. Desvanecimiento
	var tween_out = create_tween()
	tween_out.tween_property(panel_dialogo, "modulate:a", 0.0, 0.3)
	await tween_out.finished
	panel_dialogo.hide()

func cambiar_pose(nueva_textura):
	sprite_personaje.texture = nueva_textura
	var t = create_tween()
	sprite_personaje.scale = Vector2(0.9, 0.9)
	t.tween_property(sprite_personaje, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

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
	
	$CanvasLayer2/CenterContainer.hide() # Ocultamos todo lo anterior
	$CanvasLayer2/GridContainer.hide()
	$Buttoncomodin.hide()
	$Buttonpublico.hide()
	$Buttonporcentaje.hide()
	$Buttonpausa.hide()
	$Labelpuntaje.hide()
	$barraprogreso.hide()
	$CanvasLayer2/Timer/ProgressBar.hide()
	
	cambiar_pose(pose_normal)
	decir_mensaje("¡Bienvenido! Prepárate para este reto.", 2.0)
	
	await get_tree().create_timer(3.0).timeout
	
	cambiar_pose(pose_feliz)
	decir_mensaje("¡La ronda comienza ahora! ¡Mucha suerte!", 2.0)
	
	await get_tree().create_timer(2.0).timeout
	
	# ACTIVACIÓN DEL JUEGO
	label_dialogo.get_parent().hide() # Ocultamos el cuadro de texto
	$CanvasLayer2/CenterContainer.show() # Mostramos preguntas, puntos y círculos
	$CanvasLayer2/GridContainer.show()
	$Buttoncomodin.show()
	$Buttonpublico.show()
	$Buttonporcentaje.show()
	$Buttonpausa.show()
	$Labelpuntaje.show()
	$barraprogreso.show()
	$CanvasLayer2/Timer/ProgressBar.show()
	
	comenzar_nivel() # Tu función que arranca la primera pregunta
	
	cargar_json()
	preparar_nuevo_nivel()
# Se conecta la señal del timer para cuando se acabe el tiempo
	timer_pregunta.timeout.connect(_on_timer_timeout)
	# Suponiendo que ya se tiene las preguntas_ronda cargadas
	comenzar_nivel()
	
	# Configurar el timer de la llamada
	add_child(timer_llamada)
	timer_llamada.one_shot = true
	timer_llamada.timeout.connect(_on_terminar_llamada)
	
	# Ambos empiezan ocultos
	menu_pausa.hide()
	capa_confirmacion.hide()
	
	$Buttonpausa.pressed.connect(_on_boton_pausa_visual_pressed)
	menu_pausa.hide()
	
	crear_barra_progreso(15) # Creamos 15 puntos para el nivel

func crear_barra_progreso(cantidad):
	# Limpiamos por si acaso
	for hijo in contenedor_progreso.get_children():
		hijo.queue_free()
	lista_circulos.clear()
	
	for i in range(cantidad):
		var circulo = TextureRect.new()
		circulo.texture = textura_gris
		circulo.expand_mode = 2
		circulo.custom_minimum_size = Vector2(30, 30) # Tamaño del círculo
		
		contenedor_progreso.add_child(circulo)
		lista_circulos.append(circulo)

# Llamamos a esta función después de cada respuesta
func actualizar_circulo_progreso(fue_correcta: bool):
	if indice_actual < lista_circulos.size():
		if fue_correcta:
			lista_circulos[indice_actual].texture = textura_verde
		else:
			lista_circulos[indice_actual].texture = textura_roja

func dibujar_linea_fondo():
	var linea = $Line2D
	linea.clear_points()
	# Punto inicial (izquierda del contenedor)
	linea.add_point(contenedor_progreso.global_position + Vector2(0, 15)) 
	# Punto final (derecha del contenedor)
	linea.add_point(contenedor_progreso.global_position + Vector2(contenedor_progreso.size.x, 15))

# Detectar la tecla de escape o el botón de pausa
func _input(event):
	if event.is_action_pressed("ui_cancel") and not capa_confirmacion.visible:
		gestionar_pausa()

func _on_boton_pausa_visual_pressed():
	# El botón visual hace lo mismo que la tecla ESC
	gestionar_pausa()

func gestionar_pausa():
	var estado_pausa = !get_tree().paused # Invierte el estado actual
	get_tree().paused = estado_pausa
	menu_pausa.visible = estado_pausa
	# Si quitamos la pausa, ocultamos también el cuadro de confirmación
	if not estado_pausa:
		capa_confirmacion.hide()

# --- BOTONES DEL MENÚ ---

func _on_continuar_pressed():
	gestionar_pausa()

func _on_opciones_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/Opciones.tscn")
	# Aquí cargarías tu escena o panel de opciones

func _on_salir_pressed():
	# Mostrar el cuadro de confirmación antes de salir
	capa_confirmacion.show()
	
func _on_confirmar_no_quedarme_pressed():
	capa_confirmacion.hide()

# --- LÓGICA DEL MENÚ DE PAUSA ---

func _on_boton_salir_pressed():
	# Al darle a "Salir" en el primer menú, ocultamos la pausa y mostramos confirmación
	menu_pausa.hide()
	capa_confirmacion.show()

# --- LÓGICA DE LA CAPA DE CONFIRMACIÓN ---

func _on_boton_si_confirmar_salir_pressed():
	# IMPORTANTE: Quitar la pausa antes de cambiar de escena
	#get_tree().paused = false
	# Reemplaza con la ruta real de tu escena de mapa
	get_tree().change_scene_to_file("res://Mapa.tscn")

func _on_boton_no_cancelar_pressed():
	# Si se arrepiente, cerramos la confirmación y VOLVEMOS al menú de pausa
	capa_confirmacion.hide()
	menu_pausa.show()

func actualizar_interfaz_puntos():
	# Usamos str() para convertir el número a texto
	label_puntaje.text = str(puntos)
	
	# Animación de "Pop"
	var tween = create_tween()
	# Crece al 120% y vuelve al 100% en 0.2 segundos
	tween.tween_property(label_puntaje, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(label_puntaje, "scale", Vector2(1.0, 1.0), 0.1)
	
	# Nota: Para que el escalado funcione desde el centro, 
	# cambia el 'Pivot Offset' del Label a la mitad de su tamaño.

func cargar_json():
	var path = "res://Jsons/Preguntas nivel 1.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_string = file.get_as_text()
		var datos = JSON.parse_string(json_string)
		if datos is Array:
			todas_las_preguntas = datos
			# Al inicio, todas están disponibles
			pool_disponible = todas_las_preguntas.duplicate()
			pool_disponible.shuffle() # Barajeamos el mazo completo

func preparar_nuevo_nivel():
	# 1. Se verifica si hay suficientes preguntas en el pool
	# Si quedan menos de 15, recargamos y barajeamos todo para no quedarnos cortos
	if pool_disponible.size() < 15:
		print("Pocas preguntas restantes. Recargando mazo...")
		pool_disponible = todas_las_preguntas.duplicate()
		pool_disponible.shuffle()

	# 2. Se extrae exactamente 15 preguntas
	preguntas_partida_actual.clear()
	
	for i in range(15):
		# pop_front() saca el elemento del array y lo elimina de la lista disponible
		var pregunta_sacada = pool_disponible.pop_front()
		preguntas_partida_actual.append(pregunta_sacada)
	
	print("Preguntas listas para la partida. Quedan en reserva: ", pool_disponible.size())
	comenzar_nivel()

func comenzar_nivel():
	indice_actual = 0
	puntos = 0
	mostrar_pregunta()

func mostrar_pregunta():
	cambiar_pose(pose_normal)
	
	if indice_actual >= preguntas_partida_actual.size():
		finalizar_nivel()
		return

		# Esto obliga al PanelContainer a reajustar su tamaño 
		# inmediatamente según el nuevo texto del Label.
	var datos_pregunta = preguntas_partida_actual[indice_actual]
	label_pregunta.text = datos_pregunta["pregunta"]
	
	# 1. Indicamos que el punto de crecimiento es el centro
	fondo_pregunta.pivot_offset = fondo_pregunta.size / 2
	
	# 2. Forzamos al Label a calcular su tamaño real con el texto nuevo
	# Esto evita que el fondo se quede pequeño
	fondo_pregunta.reset_size() 
	
	# Se limpian los botones anteriores
	botones_respuesta.clear()
	for n in contenedor_botones.get_children():
		n.queue_free()
		
	# Se crean los 4 botones de respuesta
	for i in range(datos_pregunta["opciones"].size()):
		var boton = Button.new()
		boton.text = datos_pregunta["opciones"][i]
		
		
		var texto_respuesta = datos_pregunta["opciones"][i]
		boton.text = texto_respuesta
		if texto_respuesta.length() > 25: # Si tiene más de 50 caracteres
			boton.add_theme_font_size_override("font_size", 18) # Letra pequeña
		else:
			boton.add_theme_font_size_override("font_size", 24) # Letra normal
		
		# --- AGREGAR ICONO ---
		var textura_icono = load("res://GFX/boton-extras.png") # Carga tu imagen
		boton.icon = textura_icono
		boton.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boton.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		boton.flat = true
		# Permite que el texto salte a la siguiente línea
		boton.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		# IMPORTANTE: Define un tamaño fijo para que el autowrap sepa dónde "rebotar"
		boton.custom_minimum_size = Vector2(800, 155) 
		# Asegura que el icono cubra todo el fondo del botón
		boton.expand_icon = true
		
		# --- PERSONALIZACIÓN DE TEXTO ---
		# 1. Asignar la fuente importada
		boton.add_theme_font_override("font", mi_fuente)
		
		# 2. Cambiar el tamaño de la letra (ejemplo: 24 o 32)
		boton.add_theme_font_size_override("font_size", 28)
		
		# Asegurarse de que el texto sea visible sobre el icono
		boton.add_theme_color_override("font_color", Color.BLACK)
		
		# Conectamos el clic y pasamos el ID de la opción
		boton.pressed.connect(_on_respuesta_seleccionada.bind(i, boton))
		contenedor_botones.add_child(boton)
		botones_respuesta.append(boton)
		
		barra_tiempo.max_value = 10 # Asegurar el máximo
		barra_tiempo.value = 10     # Empezar llena
		barra_tiempo.self_modulate = Color.GREEN
		timer_pregunta.start(10)
		
	# Reiniciar y arrancar el reloj de 25 segundos
	timer_pregunta.start(10)
	ya_aviso_tiempo_corto = false # Reseteamos el seguro para la nueva pregunta
	ya_aviso_tiempo_mediano = false

func configurar_estilo_boton(boton: Button):
	var estilo = StyleBoxTexture.new()
	estilo.texture = load("res://GFX/boton-extras.png")
	# ESTO ES LO MÁS IMPORTANTE: Márgenes de Contenido
	# Estos valores obligan al texto a separarse de los bordes del icono
	estilo.content_margin_left = 30
	estilo.content_margin_right = 30
	estilo.content_margin_top = 20
	estilo.content_margin_bottom = 20
	# Aplicar el estilo a todos los estados del botón
	boton.add_theme_stylebox_override("normal", estilo)
	boton.add_theme_stylebox_override("hover", estilo)
	boton.add_theme_stylebox_override("pressed", estilo)
	boton.add_theme_stylebox_override("disabled", estilo)
	# Eliminar el icono normal para que no estorbe
	boton.icon = null

func _process(_delta):
	if not timer_pregunta.is_stopped():
		var tiempo_restante = timer_pregunta.time_left
		barra_tiempo.value = tiempo_restante
		
		# Calcular la transición de color
		actualizar_color_barra(tiempo_restante)
		
	if timer_pregunta.time_left <= 6.5 and timer_pregunta.time_left > 0:
		if not ya_aviso_tiempo_mediano and not get_tree().paused:
			ya_aviso_tiempo_mediano = true # Bloqueamos futuras repeticiones
			cambiar_pose(pose_pensativo)
			# Usamos una llamada limpia a decir_mensaje
			decir_mensaje("¡Oye! No te quedes pensando tanto, ¡el tiempo corre!", 2.5)
			
		if timer_pregunta.time_left <= 3.0 and timer_pregunta.time_left > 0:
			if not ya_aviso_tiempo_corto and not get_tree().paused:
				ya_aviso_tiempo_corto = true # Bloqueamos futuras repeticiones
				cambiar_pose(pose_preocupado)
				# Usamos una llamada limpia a decir_mensaje
				decir_mensaje("¡Rápido! ¡Solo quedan 3 segundos!", 2.5)

func _on_terminar_llamada():
	panel_llamada.hide()
	timer_pregunta.paused = false # Reanudar el tiempo de la pregunta
	
func actualizar_color_barra(tiempo):
	# Calculamos el porcentaje (de 1.0 a 0.0)
	# Si Max Value es 25, 25/25 = 1.0 (Lleno)
	var porcentaje = tiempo / barra_tiempo.max_value
	
	if porcentaje > 0.5:
		# Mientras sea más de la mitad, se mantiene Verde
		barra_tiempo.self_modulate = Color.WEB_GREEN
	else:
		# Interpolación lineal (lerp) para pasar de Verde a Rojo
		# El peso de la transición se acelera cuando queda menos tiempo
		# Usamos (porcentaje * 2) para que el rango 0.5 a 0.0 se convierta en 1.0 a 0.0
		var peso = porcentaje * 2 
		barra_tiempo.self_modulate = Color.DARK_RED.lerp(Color.WEB_GREEN, peso)

func _on_respuesta_seleccionada(id_elegido: int, boton_presionado: Button):
	timer_pregunta.stop() # Detener el reloj inmediatamente
	label_dialogo.get_parent().show() # Mostramos el cuadro
	
	# Bloquear todos los botones para que no sigan clickeando
	for b in botones_respuesta:
		b.disabled = true
	
	var correcta = preguntas_partida_actual[indice_actual]["correcta"]
	
	if id_elegido == correcta:
		# Respuesta Correcta: Pintar de verde
		puntos += 5
		actualizar_interfaz_puntos()
		print("¡Correcto!")
		cambiar_color_boton(boton_presionado, Color.GREEN)
		actualizar_circulo_progreso(true) # <-- Círculo Verde
		
		cambiar_pose(pose_feliz)
		
		# 1. Creamos la lista de frases
		var frases_exito = ["¡Excelente! Sigue así.", "¡Yo también pensaba que era esa!"]
		# 2. Elegimos una al azar
		var mensaje_elegido = frases_exito.pick_random()
		# 3. Se la enviamos a la función (el tiempo es opcional, por defecto son 3.0s)
		decir_mensaje(mensaje_elegido, 1.5)
		await get_tree().create_timer(0.5).timeout
	else:
		# Respuesta Incorrecta: Pintar el presionado de rojo y el correcto de verde
		print("Incorrecto...")
		cambiar_color_boton(boton_presionado, Color.RED)
		cambiar_color_boton(botones_respuesta[correcta], Color.GREEN)
		actualizar_circulo_progreso(false) # <-- Círculo Rojo
		
		cambiar_pose(pose_preocupado)
		var frases_perdido = ["¡Dios, eso estuvo cerca!", "Vaya... Yo pensaba que si era esa"]
	# 2. Elegimos una al azar
		var mensaje_elegido = frases_perdido.pick_random()
	# 3. Se la enviamos a la función (el tiempo es opcional, por defecto son 3.0s)
		
		decir_mensaje(mensaje_elegido, 1.5)
		await get_tree().create_timer(0.5).timeout
		# Esperamos 2 segundos para que el usuario lea y seguimos
		
	
	siguiente_pregunta()

func cambiar_color_boton(boton: Button, color: Color):
	# Usamos 'self_modulate' para teñir el icono sin cambiar su textura original
	boton.self_modulate = color


func _on_timer_timeout() -> void:
	# 1. Bloqueamos todos los botones para que el usuario no pueda 
	# hacer clic justo cuando el tiempo termina.
	for b in botones_respuesta:
		b.disabled = true
	
	# 2. Obtenemos el índice de la respuesta correcta desde nuestro JSON
	var id_correcta = preguntas_partida_actual[indice_actual]["correcta"]
	
	# 3. Pintamos el botón de la respuesta correcta en VERDE
	# 'botones_respuesta' es el array donde guardamos los botones al crearlos
	var boton_correcto = botones_respuesta[id_correcta]
	cambiar_color_boton(boton_correcto, Color.GREEN)
	
	print("¡Tiempo agotado! La correcta era: ", boton_correcto.text)
	
	# 4. Esperamos un par de segundos para que el usuario vea cuál era
	# antes de limpiar todo y pasar a la siguiente.
	await get_tree().create_timer(2.0).timeout 
	
	# 5. Llamamos a la función para pasar de pregunta
	siguiente_pregunta()

func siguiente_pregunta():
	indice_actual += 1
	# Verificamos si ya llegamos al límite (15 preguntas)
	if indice_actual >= 15:
		finalizar_nivel()
	else:
		# Pequeña pausa opcional antes de la siguiente para que el usuario respire
		await get_tree().create_timer(1.0).timeout 
		mostrar_pregunta()

func finalizar_nivel():
	timer_pregunta.stop()
	if indice_actual == 15:
		$CanvasLayer2/CenterContainer.hide() # Ocultamos todo lo anterior
		$CanvasLayer2/GridContainer.hide()
		$Buttoncomodin.hide()
		$Buttonpublico.hide()
		$Buttonporcentaje.hide()
		$Buttonpausa.hide()
		$Labelpuntaje.hide()
		$barraprogreso.hide()
		$CanvasLayer2/Timer/ProgressBar.hide()
	print("Nivel terminado. Puntos: ", puntos)
	
	# 2. El presentador cambia a una pose feliz y da su mensaje final
	# Creamos un mensaje dinámico basado en su esfuerzo
	if indice_actual == 15:
		var mensaje_final = ""
		if puntos >= 60:
			mensaje_final = "¡Increíble esfuerzo! Has demostrado una maestría total en este nivel."
		elif puntos >= 40:
			mensaje_final = "¡Muy bien hecho! Tu dedicación se nota en cada respuesta."
		else:
			mensaje_final = "¡Buen intento! Con un poco más de práctica serás imparable."
			# Llamamos a la función de diálogo que creamos antes (esperamos 4 segundos)
		await get_tree().create_timer(1.5).timeout 
		cambiar_pose(pose_normal)
		await decir_mensaje(mensaje_final, 4.0)
	# Aquí llamas a la lógica de las estrellas que vimos antes
	
	var total_preguntas = 15
	var respuestas_correctas = puntos # Las que acumuló el jugador
	
	# Lógica de estrellas
	if puntos == 75:
		estrellas_ganadas = 3
	elif puntos >= 50:
		estrellas_ganadas = 2
	elif puntos >= 25:
		estrellas_ganadas = 1
	else:
		estrellas_ganadas = 0
	
	# Cálculo de puntos con bonos
	var bono_estrellas = estrellas_ganadas * 150 # Ejemplo: 150 puntos extra por cada estrella
	var puntos_finales = (respuestas_correctas * 100) + bono_estrellas
	
	# Llamada simple: solo pasas los datos del juego, la DB saca el usuario del Autoload
	guardar_final_nivel(total_preguntas, respuestas_correctas, puntos_finales, estrellas_ganadas)
	
	mostrar_resultados(respuestas_correctas)

func _on_buttoncomodin_pressed() -> void:
	if comodin_usado or indice_actual >= preguntas_partida_actual.size():
		return # No hacer nada si ya se usó o no hay preguntas
	
	var pregunta_actual = preguntas_partida_actual[indice_actual]
	var indice_correcto = pregunta_actual["correcta"]
	
	# Creamos una lista con los índices de las respuestas incorrectas (0, 1, 2, 3 excepto el correcto)
	var indices_incorrectos = []
	for i in range(4):
		if i != indice_correcto:
			indices_incorrectos.append(i)
	
	# Barajamos los incorrectos y elegimos uno para QUE SE QUEDE (el sobreviviente)
	indices_incorrectos.shuffle()
	@warning_ignore("unused_variable")
	var indice_incorrecto_sobreviviente = indices_incorrectos.pop_front()
	
	# Ahora, los que quedan en el array 'indices_incorrectos' son los que debemos ELIMINAR/OCULTAR
	for indice_a_eliminar in indices_incorrectos:
		var boton = botones_respuesta[indice_a_eliminar]
		
		# Opción A: Hacerlo invisible y que no se pueda clickear
		boton.modulate.a = 0 # Transparencia total
		boton.disabled = true
		
		# Opción B (Si quieres que desaparezca el espacio):
		# boton.visible = false 
	
	# Desactivar el botón de comodín para que no se use de nuevo
	comodin_usado = true
	$Buttoncomodin.disabled = true
	$Buttoncomodin.modulate = Color.DARK_GRAY # Feedback visual de usado

func generar_respuesta_amigo():
	var pregunta_actual = preguntas_partida_actual[indice_actual]
	var indice_correcto = pregunta_actual["correcta"]
	var opciones = pregunta_actual["opciones"]
	
	# Creamos una lista de opciones incorrectas por si el amigo falla
	var opciones_incorrectas = []
	for i in range(opciones.size()):
		if i != indice_correcto:
			opciones_incorrectas.append(opciones[i])
	opciones_incorrectas.shuffle() # Mezclamos para elegir una al azar
	
	var suerte = randf() # Número entre 0.0 y 1.0
	
	# --- NUEVA LÓGICA DE PROBABILIDADES ---
	
	if suerte > 0.85: # 15% Probabilidad: No sabe nada
		return "¡Hola! Ay... me agarras en frío. No tengo ni la más remota idea, mejor no te arriesgues conmigo."
		
	elif suerte > 0.65: # 20% Probabilidad: DUDA Y SE EQUIVOCA (Nueva)
		var fallo = opciones_incorrectas[0]
		return "Mmm... déjame ver... estoy casi seguro de que es '" + fallo + "', pero no me hagas mucho caso que estoy dudando."
		
	elif suerte > 0.35: # 30% Probabilidad: DUDA PERO ACIERTA
		var acierto = opciones[indice_correcto]
		return "¡Qué difícil! Estaba entre dos opciones... pero pensándolo bien, creo que la correcta es '" + acierto + "'."
		
	else: # 35% Probabilidad: ESTÁ MUY SEGURO (Acierto total)
		var acierto = opciones[indice_correcto]
		return "¡Esa es fácil! La respuesta es '" + acierto + "'. ¡Rápido, márcala antes de que se acabe el tiempo!"

func _on_buttonpublico_pressed() -> void:
	panel_dialogo.hide() # Cierre instantáneo
	$capapersonaje/SpritePersonaje.hide() # Ocultar al presentador
	
	$TimerInactividad.stop() # Detenemos el regaño por inactividad
	
	if comodin_llamada_usado: return
	
	comodin_llamada_usado = true
	$Buttonpublico.disabled = true
	#timer_pregunta.paused = true # Pausamos el tiempo del juego
	
	panel_llamada.show()
	$CanvasLayer.show()
	
	# SIMULACIÓN DE CONVERSACIÓN (Divagando)
	texto_llamada.text = "Llamando..."
	await get_tree().create_timer(1.0).timeout
	
	texto_llamada.text = "Amigo: ¿Hola? ¿Quién habla?"
	await get_tree().create_timer(1.25).timeout
	
	texto_llamada.text = "Amigo: ¡Ah, hola! Espera... déjame leer la pregunta..."
	await get_tree().create_timer(1.5).timeout
	
	# Aquí mostramos el resultado de la probabilidad
	texto_llamada.text = "Amigo: " + generar_respuesta_amigo()
	
	# --- TIEMPO DE LECTURA (5 SEGUNDOS) ---
	# El diálogo se queda fijo 5 segundos para que el usuario lo lea
	await get_tree().create_timer(2.5).timeout
	
	# --- CIERRE AUTOMÁTICO ---
	cerrar_llamada_automaticamente()
	$capapersonaje/SpritePersonaje.show()
	$capapersonaje/PanelContainer/MarginContainer/Label.show()
	
	$TimerInactividad.start() # Lo reiniciamos al terminar

func cerrar_llamada_automaticamente():
	panel_llamada.hide()
	texto_llamada.text = "" # Limpiamos el texto para la próxima vez
	
	# Reanudamos el tiempo de la pregunta donde se quedó
	timer_pregunta.paused = false
	print("Llamada finalizada. El tiempo de juego continúa.")

func generar_votos_publico() -> Dictionary:
	for b in botones_respuesta:
		b.disabled = true
		
	var pregunta_actual = preguntas_partida_actual[indice_actual]
	var correcta = pregunta_actual["correcta"]
	var porcentajes = [0, 0, 0, 0]
	
	var suerte = randf()
	var indice_ganador = correcta # Por defecto, el público elige la correcta
	
	# Determinar quién gana la votación
	if suerte > 0.8: # 20% de probabilidad de que el público se equivoque masivamente
		var incorrectas = []
		for i in range(4): 
			if i != correcta: incorrectas.append(i)
		incorrectas.shuffle()
		indice_ganador = incorrectas[0] # El público vota por una falsa
	
	# Repartir los puntos (Sistema de pesos)
	var puntos_restantes = 100
	
	# El ganador se lleva entre el 40% y 70%
	var votos_ganador = randi_range(40, 70)
	porcentajes[indice_ganador] = votos_ganador
	puntos_restantes -= votos_ganador
	
	# Repartir lo que queda entre los otros 3
	for i in range(4):
		if i == indice_ganador: continue
		if i == 3 or (i == 2 && indice_ganador == 3): # Al último le damos lo que sobre
			porcentajes[i] = puntos_restantes
		else:
			var sorteo = randi_range(0, puntos_restantes)
			porcentajes[i] = sorteo
			puntos_restantes -= sorteo
			
	return {"votos": porcentajes, "ganador": indice_ganador}


func _on_buttonporcentaje_pressed() -> void:
	panel_dialogo.hide() # Cierre instantáneo
	$capapersonaje/SpritePersonaje.hide() # Ocultar al presentador
	
	for b in botones_respuesta:
		b.disabled = true
	
	if comodin_publico_usado: return
	comodin_publico_usado = true
	$Buttonporcentaje.disabled = true
	
	timer_pregunta.paused = true
	$PublicoUI.show()
	
	var resultados = generar_votos_publico()
	var votos = resultados["votos"]
	
	# Mostrar los resultados en las barras (puedes usar un Tween para que suban)
	for i in range(4):
		var barra = get_node("PublicoUI/ProgressBar" + str(i))
		var label_pct = get_node("PublicoUI/Label" + str(i))
		
		if barra != null:
			var tween = create_tween()
			# Importante: tween_property devuelve un PropertyTweener, 
			# nos aseguramos de que 'barra' sea un objeto válido antes de llamar a esto.
			tween.tween_property(barra, "value", votos[i], 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			if label_pct != null:
				label_pct.text = str(votos[i]) + "%"

	# Esperar 15 segundos antes de cerrar automáticamente
	await get_tree().create_timer(3.0).timeout
	cerrar_publico()
	
	$capapersonaje/SpritePersonaje.show()
	$capapersonaje/PanelContainer/MarginContainer/Label.show()

func cerrar_publico():
	$PublicoUI.hide()
	timer_pregunta.paused = false
	
	for b in botones_respuesta:
		b.disabled = false

func _on_timer_inactividad_timeout():
	# Solo hablamos si el juego no está pausado y el presentador no está diciendo otra cosa
	if not get_tree().paused and not panel_dialogo.visible:
		cambiar_pose(pose_pensativo)
		
		# La función decir_mensaje ya se encarga de:
		# 1. Mostrar el panel
		# 2. Poner el texto
		# 3. Esperar el tiempo (4.0 segundos en este caso)
		# 4. Ocultar el panel
		decir_mensaje("¡Oye! No te quedes pensando tanto, ¡el tiempo corre!", 4.0)

func mostrar_resultados(puntos_acumulados: int):
	puntos = puntos_acumulados
	
	# 1. Evaluar Estrellas (Basado en 15 preguntas)
	if puntos == 75:
		estrellas_ganadas = 3
	elif puntos >= 50:
		estrellas_ganadas = 2
	elif puntos >= 25:
		estrellas_ganadas = 1
	else:
		estrellas_ganadas = 0
		
	# 2. Calcular Bonificación
	# Ejemplo: 3 estrellas = +500 pts, 2 = +200 pts, 1 = +50 pts
	var bono = 0
	match estrellas_ganadas:
		3: bono = 500
		2: bono = 200
		1: bono = 50
	
	puntaje_total = (puntos * 100) + bono # Cada pregunta vale 100 + bono
	
	# 3. Actualizar Visuales
	$PantallaResultados/Panel/Label2.text = "Puntaje Total: " + str(puntaje_total)
	
	actualizar_estrellas_visual(estrellas_ganadas)
	configurar_botones(estrellas_ganadas)
	
	if indice_actual == 15:
		$PantallaResultados.show() # Mostrar la pantalla
		

func actualizar_estrellas_visual(cantidad):
	# Supongamos que tienes 3 TextureRect dentro del HBoxContainer
	var estrellas = $PantallaResultados/Panel/HBoxContainer.get_children()
	for i in range(estrellas.size()):
		if i < cantidad:
			# Cambiamos la imagen
			estrellas[i].texture = img_estrella_llena
			
			# Animación de "Pop"
			var tween = create_tween()
			estrellas[i].scale = Vector2(0, 0) # Empieza invisible/pequeña
			# Crece un poco más del 100% y vuelve a su tamaño normal
			tween.tween_property(estrellas[i], "scale", Vector2(1.2, 1.2), 0.2).set_delay(i * 0.3)
			tween.tween_property(estrellas[i], "scale", Vector2(1.0, 1.0), 0.1)
		else:
			estrellas[i].texture = img_estrella_vacia
			estrellas[i].scale = Vector2(1.0, 1.0)

func configurar_botones(estrellas):
	# Condición: Dejar de mostrar "Repetir" si ya tiene 3 estrellas
	if estrellas == 3:
		$PantallaResultados/Panel/HBoxContainer2/Button3.hide()
	else:
		$PantallaResultados/Panel/HBoxContainer2/Button3.show()
		
	if estrellas == 0:
		$PantallaResultados/Panel/HBoxContainer2/Button.hide()
	else:
		$PantallaResultados/Panel/HBoxContainer2/Button.show()
		
func _on_btn_siguiente_pressed():
	# Lógica para ir al nivel 2 (asumiendo que estás en el 1)
	Configuracion.change_scene_to_file("res://Scenes/Nivel2.tscn")

func _on_btn_repetir_pressed():
	# Reseteamos manualmente las variables críticas antes de recargar
	indice_actual = 0
	puntos = 0
	ya_aviso_tiempo_corto = false
	ya_aviso_tiempo_mediano = false
	# Ahora sí, recargamos
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_btn_mapa_pressed():
	Configuracion.change_scene_to_file("res://Mapa.tscn")

func _on_btn_menu_pressed():
	Configuracion.change_scene_to_file("res://Scenes/menu-alumno.tscn")

func guardar_final_nivel(total_preg: int, correctas: int, punto: int, estrellas: int):
		
		var incorrectas = total_preg - correctas
		var id_actual = GlobalUsuario.usuario_actual_id
		var nombre_actual = GlobalUsuario.nombre_alumno
		var completado_100 = 1 if estrellas == 3 else 0
		var nivel = GlobalUsuario.nivel_maximo
		
		# 2. Ejecutar el INSERT
		var query_nivel = "INSERT OR REPLACE INTO niveles " + \
		"(NU_NIVEL, NU_USU, NM_ALUMNO, NU_PREG, NU_RESPC, NU_RESPI, NU_PUNTOS, NU_ESTRELLAS, SW_COM) " + \
		"VALUES (%d, %d, '%s', %d, %d, %d, %d, %d, %d);" % [
			nivel, id_actual, nombre_actual, total_preg, correctas, incorrectas, punto, estrellas, completado_100
		]
		# Ejecutamos una sola vez y guardamos el resultado
		var check_nivel = db.query(query_nivel)
		
		# 3. Ejecutar el UPDATE
		var proximo_nivel = nivel + 1
		var query_alumno = "UPDATE Alumnos SET NU_NIVEL_MAX = %d WHERE NU_USU = %d AND NU_NIVEL_MAX < %d;" % [
			proximo_nivel, id_actual, proximo_nivel
		]
		var check_alumno = db.query(query_alumno)
		
		# Verificación por consola
		if check_nivel and check_alumno:
			print("¡Datos guardados con éxito en la DB!")
			print("Nivel guardado:", nivel, " para el ID:", id_actual)
		else:
			print("Error en los queries. Revisa nombres de tablas/columnas.") 
