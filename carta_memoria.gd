extends Button
class_name CartaMemoria

var id_pareja: int = 0
var es_texto: bool = false
var termino_asociado: String = ""
var pista_asociada: String = ""

var volteada: bool = false
var completada: bool = false

# Recursos visuales por defecto (puedes asignarlos desde el inspector)
var textura_dorso = preload("res://GFX/estrella vacia.png") # Imagen de la carta boca abajo

signal carta_seleccionada(carta)

func _ready() -> void:
	custom_minimum_size = Vector2(185, 135)
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mostrar_boca_abajo()

func configurar(id: int, termino: String, pista: String, tipo_texto: bool) -> void:
	self.id_pareja = id
	self.termino_asociado = termino
	self.pista_asociada = pista
	self.es_texto = tipo_texto

func mostrar_boca_abajo() -> void:
	if completada: return
	volteada = false
	text = ""
	icon = textura_dorso
	expand_icon = true
	add_theme_font_size_override("font_size", 24)
	modulate = Color.WHITE

func voltear_boca_arriba() -> void:
	if volteada or completada: return
	volteada = true
	
	if es_texto:
		icon = null
		text = pista_asociada
		add_theme_font_size_override("font_size", 20)
	else:
		text = ""
		icon = null
		text = termino_asociado
		add_theme_font_size_override("font_size", 26)

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
