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

# Fix deuda técnica: add_theme_stylebox_override espera un StyleBox, no un
# Texture2D. Envolvemos la textura en un StyleBoxTexture para que el fondo de la
# carta se pinte de verdad (antes load(...png) fallaba en silencio).
func _stylebox_textura(ruta: String) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(ruta)
	return sb

func _aplicar_fondo(ruta: String) -> void:
	var sb := _stylebox_textura(ruta)
	for estado in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(estado, sb)

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
	icon = null # Limpiamos el icono para que se vea el fondo

	# Fondo de carta boca abajo (StyleBoxTexture válido)
	_aplicar_fondo("res://GFX/estrella vacia.png")

	modulate = Color.WHITE

func voltear_boca_arriba() -> void:
	if volteada or completada: return
	volteada = true
	icon = null

	# Cambiar el fondo a la carta descubierta (StyleBoxTexture válido)
	_aplicar_fondo("res://GFX/estrella completada.png")

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
