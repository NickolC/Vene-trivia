extends Node2D

@onready var main_script = get_parent() # Referencia al script principal de arriba

func _draw() -> void:
	# 1. Dibujar todas las conexiones correctas confirmadas
	for btn_izq in main_script.conexiones_establecidas.keys():
		var btn_der = main_script.conexiones_establecidas[btn_izq]
		if is_instance_valid(btn_izq) and is_instance_valid(btn_der):
			var pos_inicio = btn_izq.global_position + (btn_izq.size / 2)
			var pos_fin = btn_der.global_position + (btn_der.size / 2)
			
			# Convertir coordenadas globales a locales del Canvas
			var local_inicio = to_local(pos_inicio)
			var local_fin = to_local(pos_fin)
			
			draw_line(local_inicio, local_fin, Color.GREEN, 5.0)

	# 2. SOLUCIÓN: Dibujar la línea interactiva hacia el mouse si hay una sola columna seleccionada
	if main_script.juego_activo:
		var btn_seleccionado: Button = null
		
		if main_script.boton_izq_seleccionado != null and main_script.boton_der_seleccionado == null:
			btn_seleccionado = main_script.boton_izq_seleccionado
		elif main_script.boton_der_seleccionado != null and main_script.boton_izq_seleccionado == null:
			btn_seleccionado = main_script.boton_der_seleccionado
			
		if btn_seleccionado and is_instance_valid(btn_seleccionado):
			var pos_inicio = btn_seleccionado.global_position + (btn_seleccionado.size / 2)
			var local_inicio = to_local(pos_inicio)
			var local_mouse = get_local_mouse_position()
			
			# Dibuja una línea amarilla discontinua o sólida que conecta el botón con el cursor
			draw_line(local_inicio, local_mouse, Color.YELLOW, 4.0)
