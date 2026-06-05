extends Node2D

@onready var juego_principal = get_parent()

func _ready() -> void:
	top_level = true 

func _process(_delta: float) -> void:
	# Forzar al lienzo a actualizar sus líneas continuamente en cada fotograma
	queue_redraw()

func _draw() -> void:
	if juego_principal == null:
		return

	# 1. Dibujar líneas fijas de aciertos (Verdes)
	if "conexiones_establecidas" in juego_principal:
		for b_izq in juego_principal.conexiones_establecidas.keys():
			var b_der = juego_principal.conexiones_establecidas[b_izq]
			
			# Comprobamos que ambos botones existan físicamente en la escena antes de medir su posición
			if is_instance_valid(b_izq) and is_instance_valid(b_der) and b_izq.is_inside_tree() and b_der.is_inside_tree():
				var origen = b_izq.global_position + Vector2(b_izq.size.x, b_izq.size.y / 2)
				var destino = b_der.global_position + Vector2(0, b_der.size.y / 2)
				
				draw_line(origen, destino, Color.GREEN, 5.0, true)

	# 2. Dibujar línea elástica (Naranja) solo si las variables correspondientes existen y están activas
	if "arrastrando_linea" in juego_principal and juego_principal.arrastrando_linea:
		if "boton_seleccionado_izq" in juego_principal and is_instance_valid(juego_principal.boton_seleccionado_izq):
			var b_izq = juego_principal.boton_seleccionado_izq
			if b_izq.is_inside_tree():
				var origen = b_izq.global_position + Vector2(b_izq.size.x, b_izq.size.y / 2)
				var destino = juego_principal.get_global_mouse_position() # Obtiene la posición directa del mouse de forma segura
				
				draw_line(origen, destino, Color.ORANGE, 3.0, true)
