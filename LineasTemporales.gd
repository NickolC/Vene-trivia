extends Node2D

# Referencia al script principal para leer sus variables de estado
@onready var juego_principal = get_parent()

func _ready() -> void:
	# Aseguramos que el lienzo ignore el desplazamiento si el padre se mueve
	top_level = true 

func _draw() -> void:
	if juego_principal == null:
		return

	# 1. Dibujar las conexiones que ya son correctas (Líneas Verdes)
	for b_izq in juego_principal.conexiones_establecidas.keys():
		var b_der = juego_principal.conexiones_establecidas[b_izq]
		if is_instance_valid(b_izq) and is_instance_valid(b_der):
			# Calculamos el centro derecho del botón izquierdo
			var origen = b_izq.global_position + Vector2(b_izq.size.x, b_izq.size.y / 2)
			# Calculamos el centro izquierdo del botón derecho
			var destino = b_der.global_position + Vector2(0, b_der.size.y / 2)
			
			draw_line(origen, destino, Color.GREEN, 4.0, true)

	# 2. Dibujar la línea elástica actual en progreso (Línea Naranja)
	if juego_principal.arrastrando_linea and is_instance_valid(juego_principal.boton_seleccionado_izq):
		var b_izq = juego_principal.boton_seleccionado_izq
		var origen = b_izq.global_position + Vector2(b_izq.size.x, b_izq.size.y / 2)
		var destino = juego_principal.mouse_posicion_actual
		
		draw_line(origen, destino, Color.ORANGE, 3.0, true)
