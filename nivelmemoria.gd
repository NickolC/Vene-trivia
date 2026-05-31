extends Control

# Estructura de datos para definir los pares
class ParMemoria:
	var id: int
	var nombre: String
	var imagen: Texture2D
	func _init(_id: int, _nom: String, _img_path: String):
		self.id = _id
		self.nombre = _nom
		self.imagen = load(_img_path)

# Precarga de la escena individual de la carta
const ESCENA_CARTA = preload("res://CartaMemoria.tscn")

# Banco de datos maestro (10 parejas = 20 barajas)
var banco_parejas: Array[ParMemoria] = [
	ParMemoria.new(1, "Navidad", "res://GFX/Feliz.png"),
	ParMemoria.new(2, "Año Nuevo", "res://GFX/gris.png"),
	ParMemoria.new(3, "Simón Bolívar", "res://GFX/jugar nivel.png"),
	ParMemoria.new(4, "Sucre", "res://GFX/cicuenta cincuenta.png"),
	ParMemoria.new(5, "Miranda", "res://GFX/amigo.png"),
	ParMemoria.new(6, "Amarillo", "res://GFX/ajuste.png"),
	ParMemoria.new(7, "Azul", "res://GFX/adelante.png"),
	ParMemoria.new(8, "Rojo", "res://GFX/moneda.png"),
	ParMemoria.new(9, "Carabobo", "res://GFX/pausa.png"),
	ParMemoria.new(10, "Turpial", "res://GFX/perilla para ajustes.png"),
	ParMemoria.new(11, "Navidad", "res://GFX/Feliz.png"),
	ParMemoria.new(12, "Año Nuevo", "res://GFX/gris.png"),
	ParMemoria.new(13, "Simón Bolívar", "res://GFX/jugar nivel.png"),
	ParMemoria.new(14, "Sucre", "res://GFX/cicuenta cincuenta.png"),
	ParMemoria.new(15, "Miranda", "res://GFX/amigo.png"),
	ParMemoria.new(16, "Amarillo", "res://GFX/ajuste.png"),
	ParMemoria.new(17, "Azul", "res://GFX/adelante.png"),
	ParMemoria.new(18, "Rojo", "res://GFX/moneda.png"),
	ParMemoria.new(19, "Carabobo", "res://GFX/pausa.png"),
	ParMemoria.new(20, "Turpial", "res://GFX/perilla para ajustes.png")
]

@onready var contenedor_cartas: GridContainer = $ContenedorCartas

# Control del flujo de juego
var primera_carta: CartaMemoria = null
var segunda_carta: CartaMemoria = null
var bloqueado: bool = false # Evita que el jugador clickee una tercera carta mientras se procesa el error/acierto
var parejas_restantes: int = 20

func _ready() -> void:
	contenedor_cartas.columns = 5 # Rejilla de 5x4 = 20 cartas
	inicializar_tablero()

func inicializar_tablero() -> void:
	var lista_cartas_instanciar: Array = []
	
	# Por cada pareja en el banco, creamos la versión de "Imagen" y la versión de "Texto"
	for par in banco_parejas:
		# 1. Carta de Imagen
		var carta_img = ESCENA_CARTA.instantiate() as CartaMemoria
		carta_img.configurar(par.id, par.nombre, par.imagen, false)
		carta_img.carta_seleccionada.connect(_on_carta_seleccionada)
		lista_cartas_instanciar.append(carta_img)
		
		# 2. Carta de Texto
		var carta_txt = ESCENA_CARTA.instantiate() as CartaMemoria
		carta_txt.configurar(par.id, par.nombre, par.imagen, true)
		carta_txt.carta_seleccionada.connect(_on_carta_seleccionada)
		lista_cartas_instanciar.append(carta_txt)
	
	# Mezclar de forma aleatoria las 20 cartas
	lista_cartas_instanciar.shuffle()
	
	# Limpiar el contenedor y añadir las cartas mezcladas
	for hijo in contenedor_cartas.get_children(): hijo.queue_free()
	for carta in lista_cartas_instanciar:
		contenedor_cartas.add_child(carta)

func _on_carta_seleccionada(carta: CartaMemoria) -> void:
	if bloqueado: return
	
	carta.voltear_boca_arriba()
	
	if primera_carta == null:
		# Es la primera carta que toca en este turno
		primera_carta = carta
	else:
		# Es la segunda carta, guardamos referencia y bloqueamos la interacción temporalmente
		segunda_carta = carta
		bloqueado = true
		_comprobar_pareja()

func _comprobar_pareja() -> void:
	# Verificamos si los IDs coinciden Y que una sea texto y la otra imagen (opcional, según tus reglas)
	# Si solo te importa el ID (pueden abrir texto con texto o imagen con imagen), quita la segunda condición.
	if primera_carta.id_pareja == segunda_carta.id_pareja and primera_carta.es_texto != segunda_carta.es_texto:
		# --- ¡ACIERTO! ---
		primera_carta.marcar_acierto()
		segunda_carta.marcar_acierto()
		
		parejas_restantes -= 1
		_limpiar_seleccion_turno()
		
		if parejas_restantes == 0:
			finalizar_juego_victoria()
	else:
		# --- ¡ERROR! ---
		primera_carta.marcar_error()
		segunda_carta.marcar_error()
		
		# Esperar 1.2 segundos mostrando el color rojo antes de ocultarlas otra vez
		await get_tree().create_timer(1.2).timeout
		
		if is_instance_valid(primera_carta): primera_carta.mostrar_boca_abajo()
		if is_instance_valid(segunda_carta): segunda_carta.mostrar_boca_abajo()
		
		_limpiar_seleccion_turno()

func _limpiar_seleccion_turno() -> void:
	primera_carta = null
	segunda_carta = null
	bloqueado = false

func finalizar_juego_victoria() -> void:
	print("¡Felicidades, encontraste todas las parejas!")
	# Aquí puedes integrar tu función ya existente de: finalizar_nivel(true)
