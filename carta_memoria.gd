extends Button
class_name CartaMemoria

var id_pareja: int = 0
var es_texto: bool = false
var texto_asociado: String = ""
var imagen_asociada: Texture2D = null

var volteada: bool = false
var completada: bool = false

# Recursos visuales por defecto (puedes asignarlos desde el inspector)
var textura_dorso = preload("res://GFX/estrella vacia.png") # Imagen de la carta boca abajo

signal carta_seleccionada(carta)

func _ready() -> void:
	custom_minimum_size = Vector2(120, 160) # Tamaño ideal para que quepan 20 en pantalla
	mostrar_boca_abajo()

func configurar(id: int, texto: String, imagen: Texture2D, tipo_texto: bool) -> void:
	self.id_pareja = id
	self.texto_asociado = texto
	self.imagen_asociada = imagen
	self.es_texto = tipo_texto

func mostrar_boca_abajo() -> void:
	if completada: return
	volteada = false
	text = ""
	icon = null # Limpiamos el icono para que se vea el fondo
	
	# 🌟 Ahora cargamos el recurso .tres que sí es un StyleBox válido
	add_theme_stylebox_override("normal", load("res://GFX/estrella vacia.png"))
	
	modulate = Color.WHITE

func voltear_boca_arriba() -> void:
	if volteada or completada: return
	volteada = true
	icon = null
	
	# Cambiar el fondo a la carta descubierta
	add_theme_stylebox_override("normal", load("res://GFX/estrella completada.png"))
	
	if es_texto:
		text = texto_asociado
		# Configuración opcional de fuente
	else:
		icon = imagen_asociada
		expand_icon = true

func marcar_error() -> void:
	modulate = Color.RED

func marcar_acierto() -> void:
	modulate = Color.GREEN
	completada = true
	
	# Efecto de desvanecimiento (Fade out) elegante usando Tween
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.tween_callback(queue_free) # Remueve la carta al terminar para limpiar la UI

func _pressed() -> void:
	# Emitir señal al tablero si la carta es válida para clickear
	if not volteada and not completada:
		carta_seleccionada.emit(self)
