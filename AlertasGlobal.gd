extends CanvasLayer

@onready var label_dialogo = $PanelContainer/MarginContainer/Label
@onready var panel_dialogo = $PanelContainer

func _ready():
	panel_dialogo.hide() # Empezamos ocultos

func mostrar_alerta(texto: String, tiempo: float = 3.0):
	# 1. Detener animaciones previas si el usuario hace clic rápido
	var tween = create_tween()
	
	# 2. Configurar el texto
	label_dialogo.text = texto
	panel_dialogo.modulate.a = 0
	panel_dialogo.show()
	
	# 3. Aparecer
	tween.tween_property(panel_dialogo, "modulate:a", 1.0, 0.3)
	
	# 4. Esperar
	await get_tree().create_timer(tiempo).timeout
	
	# 5. Desvanecer y ocultar
	var tween_out = create_tween()
	tween_out.tween_property(panel_dialogo, "modulate:a", 0.0, 0.3)
	await tween_out.finished
	panel_dialogo.hide()
