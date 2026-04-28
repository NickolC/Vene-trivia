extends CanvasLayer

@onready var label_dialogo = $PanelContainer/MarginContainer/Label
@onready var panel_dialogo = $PanelContainer

var _tween_actual: Tween

func _ready() -> void:
	panel_dialogo.hide()

func mostrar_alerta(texto: String, tiempo: float = 3.0) -> void:
	if _tween_actual and _tween_actual.is_running():
		_tween_actual.kill()

	label_dialogo.text = texto
	panel_dialogo.modulate.a = 0
	panel_dialogo.show()
	
	_tween_actual = create_tween()
	_tween_actual.tween_property(panel_dialogo, "modulate:a", 1.0, 0.3)
	
	await get_tree().create_timer(tiempo).timeout
	
	_tween_actual = create_tween()
	_tween_actual.tween_property(panel_dialogo, "modulate:a", 0.0, 0.3)
	await _tween_actual.finished
	panel_dialogo.hide()
