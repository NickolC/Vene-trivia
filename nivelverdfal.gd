extends Control

# Precargamos recursos esenciales
const MI_FUENTE_PERSONALIZADA = preload("res://font/Minecraft.ttf")
const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")
const RUTA_ESCENA_NIVEL := "res://Scenes/Minijuegos.tscn"
const RUTA_DATOS_SOPA := "res://Data/minijuegos/verdadero_falso.json"

# Recompensas económicas base
const RECOMPENSA_BASE_PUNTOS := 100
const MONEDAS_POR_ESTRELLA := 50

# --- NUEVO DICCIONARIO: TIEMPOS MÁXIMOS POR NIVEL (En segundos, max 8 minutos = 480s) ---
const TIEMPOS_POR_NIVEL: Dictionary = {
	1: 480.0,  # Nivel 1: 8 minutos
	2: 480.0,  # Nivel 2: 7:30 minutos
	3: 480.0,  # Nivel 3: 8 minutos
	4: 480.0,  # Nivel 4: 7 minutos
	5: 480.0,  # ... ajusta cada nivel como gustes sin pasarte de 480.0
	6: 480.0,
	7: 480.0,
	8: 480.0,
	9: 480.0,
	10: 480.0,
	11: 480.0,
	12: 480.0,
	13: 480.0,
	14: 480.0,
	15: 480.0
}
# Nodos de la Cuadrícula e Interfaz del Juego
@onready var label_contador = $Label 
@onready var menu_pausa = $Menupausa
@onready var capa_confirmacion = $confrimar

# --- NUEVO NODO VISUAL PARA EL CRONÓMETRO ---
# (Crea un Label en tu escena llamado "Label2" para que se vea el tiempo en pantalla)
@onready var label_timer = get_node_or_null("Label2")

# Nodos del Canvas del Personaje y Diálogos
@onready var sprite_personaje = $capapersonaje/SpritePersonaje
@onready var panel_dialogo = $capapersonaje/PanelContainer
@onready var label_dialogo = $capapersonaje/PanelContainer/MarginContainer/Label

# Nodos de la Pantalla de Resultados
@onready var pantalla_resultados = $PantallaResultados
@onready var label_titulo_resultados = $PantallaResultados/Panel/Label
@onready var label_puntaje_total = $PantallaResultados/Panel/Label2
@onready var contenedor_estrellas = $PantallaResultados/Panel/HBoxContainer
@onready var btn_siguiente = $PantallaResultados/Panel/HBoxContainer2/Button     
@onready var btn_repetir = $PantallaResultados/Panel/HBoxContainer2/Button3    
@onready var btn_selector = $PantallaResultados/Panel/HBoxContainer2/Button4  
@onready var btn_menu_alumno = $PantallaResultados/Panel/HBoxContainer2/Button2

# Recursos Visuales 
var pose_normal = preload("res://GFX/normal.png")
var pose_feliz = preload("res://GFX/Feliz.png")
var pose_preocupado = preload("res://GFX/preocupado.png")
var pose_pensativo = preload("res://GFX/pensativo.png")
var img_estrella_llena = preload("res://GFX/estrella completada.png")
var img_estrella_vacia = preload("res://GFX/estrella vacia.png")

# Variables del Motor de Base de Datos y control de juego
var db: SQLite
var tamaño_tablero: int = 10 
var matriz_letras: Array = [] 
var palabras_objetivo: Array[String] = []
var referencias_lista_ui: Dictionary = {}
var casillas_por_coordenada: Dictionary = {}
var palabras_encontradas: Dictionary = {}

var seleccionando: bool = false
var casillas_seleccionadas: Array[Button] = []
var palabras_encontradas_contador: int = 0
var total_palabras: int = 0 
var numero_de_nivel: int = 1

# --- VARIABLES DEL CRONÓMETRO DINÁMICO ---
var tiempo_maximo_nivel: float = 480.0 # Se sobreescribirá en el ready
var tiempo_restante: float = 480.0
var juego_activo: bool = false


func _ready() -> void:
	db = SQLiteHelper.open_db_connection()
	numero_de_nivel = maxi(1, int(GlobalUsuario.nivel_seleccionado))
	
	
	if menu_pausa: menu_pausa.hide()
	if capa_confirmacion: capa_confirmacion.hide()
	if panel_dialogo: panel_dialogo.hide()
	
	var boton_pausa_visual = get_node_or_null("InterfazJuego/Control/Buttonpausa")
	
	if boton_pausa_visual:
		# 2. Forzamos a que el botón funcione INCLUSO cuando el juego esté pausado
		boton_pausa_visual.process_mode = Node.PROCESS_MODE_ALWAYS
		
		# 3. Conectamos la señal 'pressed' a tu función existente por código
		boton_pausa_visual.pressed.connect(_on_boton_pausa_visual_pressed)
	else:
		print("ERROR: No se encontró el botón de pausa visual en la ruta especificada.")
	
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	if menu_pausa: menu_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
	if capa_confirmacion: capa_confirmacion.process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if juego_activo and not get_tree().paused:
		tiempo_restante -= delta
		if tiempo_restante <= 0.0:
			tiempo_restante = 0.0
			juego_activo = false

# Detectar la tecla de escape o el botón de pausa
func _input(event):
	if event.is_action_pressed("ui_cancel") and not capa_confirmacion.visible:
		gestionar_pausa()

func _on_boton_pausa_visual_pressed():
	# El botón visual hace lo mismo que la tecla ESC
	gestionar_pausa()

func gestionar_pausa():
	var nuevo_estado_pausa = !get_tree().paused # Invierte el estado actual del motor
	get_tree().paused = nuevo_estado_pausa
	
	if menu_pausa:
		menu_pausa.visible = nuevo_estado_pausa
		
	# Si quitamos la pausa (regresamos al juego), nos aseguramos de limpiar las ventanas emergentes
	if not nuevo_estado_pausa:
		if capa_confirmacion:
			capa_confirmacion.hide()

# --- BOTONES DEL MENÚ ---

func _on_continuar_pressed():
	gestionar_pausa()
	get_tree().paused = false

const ESCENA_OPCIONES = preload("res://Opcionesnivel.tscn")

func _on_opciones_pressed():
	# 1. Ocultamos momentáneamente los botones del menú de pausa principal
	$Menupausa/CenterContainer.visible = false
	# 2. Creamos una instancia de la escena de opciones
	var opciones_instancia = ESCENA_OPCIONES.instantiate()
	# 3. Le asignamos un nombre único
	opciones_instancia.name = "MenuOpcionesDinamico"
	
	# ¡IMPORTANTE!: Forzar a la nueva ventana de opciones a procesar en pausa
	opciones_instancia.process_mode = Node.PROCESS_MODE_ALWAYS
	# 4. La añadimos como hija del CanvasLayer de pausa
	$Menupausa.add_child(opciones_instancia)


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
	get_tree().paused = false
	GlobalUsuario.nivel_seleccionado = numero_de_nivel
	get_tree().change_scene_to_file("res://selectorsopaletras.tscn")

func _on_boton_no_cancelar_pressed():
	# Si se arrepiente, cerramos la confirmación y VOLVEMOS al menú de pausa
	capa_confirmacion.hide()
	menu_pausa.show()

func _on_button_4_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://selectorsopaletras.tscn")
