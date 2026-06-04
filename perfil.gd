extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")
const PerfilStats  = preload("res://Scripts/perfil_stats.gd")
const Logros       = preload("res://Scripts/logros.gd")

var db: SQLite
var costopor: int = 100
var costopub:  int = 150
var costomid:  int = 200
const COSTO_PACK_NIVELES: int = 1000
var _columna_comodin: String = ""
var _pack_nivel_seleccionado: int = 0

var _lbl_stats:   Label
var _vbox_logros: VBoxContainer
var _foto_rect:   TextureRect
var _panel_packs_niveles: PanelContainer
var _botones_pack_niveles: Dictionary = {}
var _labels_pack_niveles: Dictionary = {}

const FOTO_CONFIG_PREFIX := "user://perfil_foto_"

@onready var label_dinero = $TextureRect2/HBoxContainer/moneda
@onready var precioPor    = $TextureRect2/VBoxContainer/Precio
@onready var precioPub    = $TextureRect2/VBoxContainer2/Precio
@onready var precioMid    = $TextureRect2/VBoxContainer3/Precio
@onready var compra       = $TextureRect2/confrimarcomodines/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Label
@onready var compra_niveles = $TextureRect2/confirmarniveles/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/Label

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()

	var q := "SELECT * FROM Alumnos WHERE NU_USU = %d;" % GlobalUsuario.usuario_actual_id
	db.query(q)
	if db.query_result.size() > 0:
		GlobalUsuario.nombre_alumno = str(db.query_result[0]["NM_ALUMNO"])

	Configuracion.cargar_ajustes()
	precioPor.text = str(costopor) + " Bs."
	precioPub.text = str(costopub) + " Bs."
	precioMid.text = str(costomid) + " Bs."

	_conectar_botones_tienda()
	_conectar_botones_niveles()
	_crear_panel_packs_niveles()
	actualizar_dinero_visual()
	_crear_panel_perfil()
	call_deferred("_cargar_perfil_stats")

# ──────────────────────────────────────────────
# Conexiones de señales (no están en el .tscn)
# ──────────────────────────────────────────────
func _conectar_botones_tienda() -> void:
	var btn_por := $TextureRect2/VBoxContainer/Buttonporcentaje
	var btn_pub := $TextureRect2/VBoxContainer2/Buttonpublico
	var btn_mid := $TextureRect2/VBoxContainer3/Buttoncomodin

	if btn_por and not btn_por.pressed.is_connected(_on_buttonporcentaje_pressed):
		btn_por.pressed.connect(_on_buttonporcentaje_pressed)
	if btn_pub and not btn_pub.pressed.is_connected(_on_buttonpublico_pressed):
		btn_pub.pressed.connect(_on_buttonpublico_pressed)
	if btn_mid and not btn_mid.pressed.is_connected(_on_buttonmitad_pressed):
		btn_mid.pressed.connect(_on_buttonmitad_pressed)

	var btn_ac := $TextureRect2/confrimarcomodines/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/aceptar
	var btn_ca := $TextureRect2/confrimarcomodines/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/cancelar
	if btn_ac and not btn_ac.pressed.is_connected(_on_aceptar_pressed):
		btn_ac.pressed.connect(_on_aceptar_pressed)
	if btn_ca and not btn_ca.pressed.is_connected(_on_cancelar2_pressed):
		btn_ca.pressed.connect(_on_cancelar2_pressed)

func _conectar_botones_niveles() -> void:
	var btn_ac_niv := $TextureRect2/confirmarniveles/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/aceptar
	var btn_ca_niv := $TextureRect2/confirmarniveles/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/cancelar
	if btn_ac_niv and not btn_ac_niv.pressed.is_connected(_on_aceptar_niveles_pressed):
		btn_ac_niv.pressed.connect(_on_aceptar_niveles_pressed)
	if btn_ca_niv and not btn_ca_niv.pressed.is_connected(_on_cancelar3_pressed):
		btn_ca_niv.pressed.connect(_on_cancelar3_pressed)

func _crear_panel_packs_niveles() -> void:
	var root_tienda := $TextureRect2
	if root_tienda == null:
		return

	if _panel_packs_niveles and is_instance_valid(_panel_packs_niveles):
		_panel_packs_niveles.queue_free()

	_panel_packs_niveles = PanelContainer.new()
	_panel_packs_niveles.name = "PanelPacksNiveles"
	_panel_packs_niveles.layout_mode = 1
	_panel_packs_niveles.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	
	_panel_packs_niveles.anchor_left = 0.19
	_panel_packs_niveles.anchor_top = 0.59
	_panel_packs_niveles.anchor_right = 0.79
	_panel_packs_niveles.anchor_bottom = 0.85
	_panel_packs_niveles.offset_left = 0
	_panel_packs_niveles.offset_top = 0
	_panel_packs_niveles.offset_right = 0
	_panel_packs_niveles.offset_bottom = 0
	_panel_packs_niveles.add_theme_stylebox_override("panel", _crear_stylebox_boton(Color(0.93, 0.83, 0.67, 0.95)))
	root_tienda.add_child(_panel_packs_niveles)

	var margin := MarginContainer.new()
	margin.layout_mode = 2
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel_packs_niveles.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.layout_mode = 2
	vbox.add_theme_constant_override("separation", 25)
	margin.add_child(vbox)

	var fuente := load("res://GFX/Minecraft.ttf") as FontFile
	var titulo := Label.new()
	titulo.text = "DESBLOQUEO NIVELES 11-15"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_color_override("font_color", Color(0.15, 0.10, 0.07, 1.0))
	titulo.add_theme_font_size_override("font_size", 20)
	if fuente:
		titulo.add_theme_font_override("font", fuente)
	vbox.add_child(titulo)

	_botones_pack_niveles.clear()
	_labels_pack_niveles.clear()
	for pack_id in [1, 2, 3]:
		var fila := HBoxContainer.new()
		fila.layout_mode = 2
		fila.alignment = BoxContainer.ALIGNMENT_CENTER
		fila.add_theme_constant_override("separation", 20)
		vbox.add_child(fila)

		var label := Label.new()
		label.layout_mode = 2
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = _texto_pack_niveles(pack_id)
		label.add_theme_color_override("font_color", Color(0.18, 0.12, 0.08, 1.0))
		label.add_theme_font_size_override("font_size", 18)
		if fuente:
			label.add_theme_font_override("font", fuente)
		fila.add_child(label)
		_labels_pack_niveles[pack_id] = label

		var btn := Button.new()
		btn.layout_mode = 2
		btn.custom_minimum_size = Vector2(185, 38)
		btn.text = "Comprar %d Bs." % COSTO_PACK_NIVELES
		btn.add_theme_color_override("font_color", Color(0.15, 0.10, 0.07, 1.0))
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_stylebox_override("normal", _crear_stylebox_boton(Color(0.88, 0.74, 0.56, 0.95)))
		btn.add_theme_stylebox_override("hover", _crear_stylebox_boton(Color(0.93, 0.80, 0.62, 1.0)))
		btn.add_theme_stylebox_override("pressed", _crear_stylebox_boton(Color(0.80, 0.64, 0.46, 1.0)))
		if fuente:
			btn.add_theme_font_override("font", fuente)
		btn.pressed.connect(_on_comprar_pack_niveles_pressed.bind(pack_id))
		fila.add_child(btn)
		_botones_pack_niveles[pack_id] = btn

	_refresh_estado_packs_niveles()

func _texto_pack_niveles(pack_id: int) -> String:
	match pack_id:
		1:
			return "Pack A: Niveles 11 y 12"
		2:
			return "Pack B: Niveles 13 y 14"
		3:
			return "Pack C: Nivel 15"
		_:
			return "Pack"

func _refresh_estado_packs_niveles() -> void:
	if db == null:
		return
	var id := GlobalUsuario.usuario_actual_id
	for pack_id in [1, 2, 3]:
		var btn := _botones_pack_niveles.get(pack_id) as Button
		var label := _labels_pack_niveles.get(pack_id) as Label
		if btn == null or label == null:
			continue

		var comprado := SQLiteHelper.pack_niveles_comprado(db, id, pack_id)
		var disponible := SQLiteHelper.puede_comprar_pack_niveles(db, id, pack_id)
		if comprado:
			btn.disabled = true
			btn.text = "Comprado"
			label.modulate = Color(0.20, 0.55, 0.25, 1.0)
		elif disponible:
			btn.disabled = false
			btn.text = "Comprar %d Bs." % COSTO_PACK_NIVELES
			label.modulate = Color(1, 1, 1, 1)
		else:
			btn.disabled = true
			btn.text = "Bloqueado"
			label.modulate = Color(0.65, 0.65, 0.65, 1.0)

func _on_comprar_pack_niveles_pressed(pack_id: int) -> void:
	_pack_nivel_seleccionado = pack_id
	$TextureRect2/confirmarniveles.visible = true
	compra_niveles.text = "\n¿Comprar %s?\nCosto: %d Bs.\n" % [_texto_pack_niveles(pack_id), COSTO_PACK_NIVELES]

func _on_aceptar_niveles_pressed() -> void:
	if _pack_nivel_seleccionado <= 0:
		Alertas.mostrar_alerta("Selecciona un pack primero.", 1.8)
		return

	var resultado := SQLiteHelper.comprar_pack_niveles(db, GlobalUsuario.usuario_actual_id, COSTO_PACK_NIVELES, _pack_nivel_seleccionado)
	if bool(resultado.get("ok", false)):
		Alertas.mostrar_alerta("Pack comprado: %s" % _texto_pack_niveles(_pack_nivel_seleccionado), 2.0)
		actualizar_dinero_visual()
		_refresh_estado_packs_niveles()
	else:
		Alertas.mostrar_alerta(str(resultado.get("mensaje", "No se pudo comprar el pack.")), 2.2)

	$TextureRect2/confirmarniveles.visible = false
	_pack_nivel_seleccionado = 0

# ──────────────────────────────────────────────
# Construcción dinámica del panel de perfil
# ──────────────────────────────────────────────
func _crear_panel_perfil() -> void:
	var rect := $TextureRect
	var fuente := load("res://GFX/Minecraft.ttf") as FontFile
	var layout_existente := rect.get_node_or_null("PerfilLayout")
	if layout_existente:
		layout_existente.queue_free()

	var layout := MarginContainer.new()
	layout.name = "PerfilLayout"
	layout.layout_mode = 1
	layout.anchors_preset = -1
	layout.anchor_left = 0.10
	layout.anchor_top = 0.12
	layout.anchor_right = 0.86
	layout.anchor_bottom = 0.88
	layout.add_theme_constant_override("margin_left", 130)
	layout.add_theme_constant_override("margin_top", 10)
	layout.add_theme_constant_override("margin_right", 108)
	layout.add_theme_constant_override("margin_bottom", 60)
	rect.add_child(layout)

	var cuerpo := HBoxContainer.new()
	cuerpo.layout_mode = 2
	cuerpo.add_theme_constant_override("separation", 46)
	layout.add_child(cuerpo)

	var columna_izq := VBoxContainer.new()
	columna_izq.layout_mode = 2
	columna_izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna_izq.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#columna_izq.custom_minimum_size = Vector2(450, 0)
	columna_izq.add_theme_constant_override("separation", 20)
	cuerpo.add_child(columna_izq)

	var columna_der := VBoxContainer.new()
	columna_der.layout_mode = 2
	columna_der.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columna_der.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cuerpo.add_child(columna_der)

	var foto_panel := PanelContainer.new()
	foto_panel.layout_mode = 2
	foto_panel.custom_minimum_size = Vector2(0, 230)
	_apply_dark_style(foto_panel)
	columna_izq.add_child(foto_panel)

	var foto_margin := MarginContainer.new()
	foto_margin.layout_mode = 2
	foto_margin.add_theme_constant_override("margin_left", 14)
	foto_margin.add_theme_constant_override("margin_top", 14)
	foto_margin.add_theme_constant_override("margin_right", 14)
	foto_margin.add_theme_constant_override("margin_bottom", 14)
	foto_panel.add_child(foto_margin)

	var foto_hbox := HBoxContainer.new()
	foto_hbox.layout_mode = 2
	foto_hbox.add_theme_constant_override("separation", 16)
	foto_margin.add_child(foto_hbox)

	var marco_foto := PanelContainer.new()
	marco_foto.layout_mode = 2
	marco_foto.custom_minimum_size = Vector2(190, 190)
	_apply_dark_style(marco_foto)
	foto_hbox.add_child(marco_foto)

	var foto_center := CenterContainer.new()
	foto_center.layout_mode = 2
	marco_foto.add_child(foto_center)

	_foto_rect = TextureRect.new()
	_foto_rect.layout_mode = 2
	_foto_rect.custom_minimum_size = Vector2(170, 170)
	_foto_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_foto_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_foto_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foto_center.add_child(_foto_rect)
	_cargar_foto_guardada()

	var foto_vbox := VBoxContainer.new()
	foto_vbox.layout_mode = 2
	foto_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foto_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	foto_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	foto_vbox.add_theme_constant_override("separation", 12)
	foto_hbox.add_child(foto_vbox)

	var lbl_nombre := Label.new()
	lbl_nombre.layout_mode = 2
	lbl_nombre.text = GlobalUsuario.nombre_alumno
	lbl_nombre.add_theme_color_override("font_color", Color(0.12, 0.07, 0.02, 1.0))
	lbl_nombre.add_theme_font_size_override("font_size", 32)
	lbl_nombre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if fuente: lbl_nombre.add_theme_font_override("font", fuente)
	foto_vbox.add_child(lbl_nombre)

	var btn_foto := Button.new()
	btn_foto.text = "Cambiar foto"
	btn_foto.custom_minimum_size = Vector2(250, 46)
	btn_foto.add_theme_font_size_override("font_size", 20)
	btn_foto.add_theme_color_override("font_color", Color(0.15, 0.10, 0.07, 1.0))
	btn_foto.add_theme_stylebox_override("normal", _crear_stylebox_boton(Color(0.88, 0.74, 0.56, 0.95)))
	btn_foto.add_theme_stylebox_override("hover", _crear_stylebox_boton(Color(0.93, 0.80, 0.62, 1.0)))
	btn_foto.add_theme_stylebox_override("pressed", _crear_stylebox_boton(Color(0.80, 0.64, 0.46, 1.0)))
	if fuente: btn_foto.add_theme_font_override("font", fuente)
	btn_foto.pressed.connect(_on_cambiar_foto_pressed)
	foto_vbox.add_child(btn_foto)

	var stats_panel := PanelContainer.new()
	stats_panel.layout_mode = 2
	stats_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_dark_style(stats_panel)
	columna_izq.add_child(stats_panel)

	var margin := MarginContainer.new()
	margin.layout_mode = 2
	for s in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 14)
	stats_panel.add_child(margin)

	_lbl_stats = Label.new()
	_lbl_stats.layout_mode = 2
	_lbl_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_stats.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_lbl_stats.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_lbl_stats.add_theme_color_override("font_color", Color(0.12, 0.07, 0.02, 1.0))
	_lbl_stats.add_theme_font_size_override("font_size", 18)
	if fuente: _lbl_stats.add_theme_font_override("font", fuente)
	margin.add_child(_lbl_stats)

	var logros_panel := PanelContainer.new()
	logros_panel.layout_mode = 2
	logros_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_dark_style(logros_panel)
	columna_der.add_child(logros_panel)

	var logros_margin := MarginContainer.new()
	logros_margin.layout_mode = 2
	logros_margin.add_theme_constant_override("margin_left", 14)
	logros_margin.add_theme_constant_override("margin_top", 10)
	logros_margin.add_theme_constant_override("margin_right", 14)
	logros_margin.add_theme_constant_override("margin_bottom", 12)
	logros_panel.add_child(logros_margin)

	var scroll := ScrollContainer.new()
	scroll.layout_mode = 2
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	logros_margin.add_child(scroll)

	_vbox_logros = VBoxContainer.new()
	_vbox_logros.layout_mode = 2
	_vbox_logros.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vbox_logros.add_theme_constant_override("separation", 8)
	scroll.add_child(_vbox_logros)

func _apply_dark_style(panel: PanelContainer) -> void:
	var card := StyleBoxFlat.new()
	card.bg_color = Color(0.96, 0.88, 0.74, 0.82)
	card.border_width_left = 3
	card.border_width_top = 3
	card.border_width_right = 3
	card.border_width_bottom = 3
	card.border_color = Color(0.43, 0.29, 0.19, 0.9)
	card.corner_radius_top_left = 8
	card.corner_radius_top_right = 8
	card.corner_radius_bottom_right = 8
	card.corner_radius_bottom_left = 8
	panel.add_theme_stylebox_override("panel", card)

func _crear_stylebox_boton(color_base: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color_base
	box.border_width_left = 2
	box.border_width_top = 2
	box.border_width_right = 2
	box.border_width_bottom = 2
	box.border_color = Color(0.43, 0.29, 0.19, 0.95)
	box.corner_radius_top_left = 5
	box.corner_radius_top_right = 5
	box.corner_radius_bottom_right = 5
	box.corner_radius_bottom_left = 5
	return box

# ──────────────────────────────────────────────
# Foto de perfil
# ──────────────────────────────────────────────
func _cargar_foto_guardada() -> void:
	if _foto_rect == null:
		return
	var ruta_cfg := FOTO_CONFIG_PREFIX + str(GlobalUsuario.usuario_actual_id) + ".txt"
	if not FileAccess.file_exists(ruta_cfg):
		return
	var f := FileAccess.open(ruta_cfg, FileAccess.READ)
	if f == null:
		return
	var ruta_img := f.get_as_text().strip_edges()
	f.close()
	if ruta_img.is_empty() or not FileAccess.file_exists(ruta_img):
		return
	var img := Image.load_from_file(ruta_img)
	if img == null:
		return
	_foto_rect.texture = ImageTexture.create_from_image(img)

func _on_cambiar_foto_pressed() -> void:
	var dialogo := FileDialog.new()
	dialogo.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialogo.access    = FileDialog.ACCESS_FILESYSTEM
	dialogo.filters   = PackedStringArray(["*.png,*.jpg,*.jpeg,*.webp ; Imágenes"])
	dialogo.title     = "Seleccionar foto de perfil"
	dialogo.size      = Vector2i(900, 600)
	add_child(dialogo)
	dialogo.popup_centered()
	dialogo.file_selected.connect(func(ruta: String) -> void:
		var img := Image.load_from_file(ruta)
		if img == null:
			Alertas.mostrar_alerta("No se pudo cargar la imagen.", 2.0)
			dialogo.queue_free()
			return
		_foto_rect.texture = ImageTexture.create_from_image(img)
		var cfg := FOTO_CONFIG_PREFIX + str(GlobalUsuario.usuario_actual_id) + ".txt"
		var fw := FileAccess.open(cfg, FileAccess.WRITE)
		if fw:
			fw.store_string(ruta)
			fw.close()
		Alertas.mostrar_alerta("Foto actualizada.", 1.5)
		dialogo.queue_free()
	)

# ──────────────────────────────────────────────
# Carga de estadísticas
# ──────────────────────────────────────────────
func _cargar_perfil_stats() -> void:
	var id := GlobalUsuario.usuario_actual_id
	if id <= 0 or _lbl_stats == null:
		return

	var pts        := PerfilStats.puntaje_total(db, id)
	var estrellas  := PerfilStats.estrellas_totales(db, id)
	var perfectos  := PerfilStats.niveles_perfectos(db, id)
	var completados := PerfilStats.niveles_completados(db, id)
	var intentos   := PerfilStats.veces_repetido(db, id)
	var alumno     := PerfilStats.datos_alumno(db, id)
	var dinero     := int(alumno.get("NU_DINERO", 0))
	var pub        := int(alumno.get("NU_PUBLICO", 0))
	var prob       := int(alumno.get("NU_PROBABILIDAD", 0))
	var mitad      := int(alumno.get("NU_MITAD", 0))
	var nivel_max  := int(alumno.get("NU_NIVEL_MAX", 1))
	var extras     := PerfilStats.minijuegos_desbloqueados(db, id)

	_lbl_stats.text = (
		"Puntaje total: %d\n" % pts +
		"Estrellas totales: %d\n" % estrellas +
		"Niveles perfectos (3★): %d\n" % perfectos +
		"Niveles completados: %d / 15\n" % completados +
		"Veces repetido: %d\n" % intentos +
		"Nivel max: %d\n\n" % nivel_max +
		"Dinero: %d Bs.\n\n" % dinero +
		"Comodines:\n" +
		"  Llamada: %d\n" % pub +
		"  Porcentaje: %d\n" % prob +
		"  50/50: %d\n\n" % mitad +
		"Extras desbloqueados: %d" % extras
	)

	_cargar_logros(id)
	_cargar_leaderboard()

func _cargar_logros(id: int) -> void:
	for child in _vbox_logros.get_children():
		child.queue_free()

	var fuente := load("res://GFX/Minecraft.ttf") as FontFile

	var titulo := Label.new()
	titulo.text = "--- Logros ---"
	titulo.add_theme_color_override("font_color", Color(0.5, 0.3, 0.0, 1.0))
	titulo.add_theme_font_size_override("font_size", 18)
	if fuente: titulo.add_theme_font_override("font", fuente)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox_logros.add_child(titulo)

	var desbloqueados := PerfilStats.logros_desbloqueados(db, id)
	
	for clave in Logros.CATALOGO:
		var lbl := Label.new()
		var texto: String = Logros.CATALOGO[clave]
		var obtenido: bool = clave in desbloqueados
		lbl.text = ("  ★ " if obtenido else "  ○ ") + texto
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_color_override("font_color", Color(0.12, 0.07, 0.02, 1.0) if obtenido else Color(0.5, 0.45, 0.4, 1.0))
		lbl.add_theme_font_size_override("font_size", 16)
		if fuente: lbl.add_theme_font_override("font", fuente)
		_vbox_logros.add_child(lbl)

	var sep := HSeparator.new()
	_vbox_logros.add_child(sep)

	var titulo2 := Label.new()
	titulo2.text = "--- Leaderboard ---"
	titulo2.add_theme_color_override("font_color", Color(0.5, 0.3, 0.0, 1.0))
	titulo2.add_theme_font_size_override("font_size", 18)
	if fuente: titulo2.add_theme_font_override("font", fuente)
	titulo2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox_logros.add_child(titulo2)

func _cargar_leaderboard() -> void:
	var fuente := load("res://GFX/Minecraft.ttf") as FontFile
	var rows   := PerfilStats.leaderboard(db)
	for i in rows.size():
		var row: Dictionary = rows[i]
		var lbl := Label.new()
		lbl.text = "%d. %s — %d pts" % [i + 1, str(row.get("NM_ALUMNO", "?")), int(row.get("total", 0))]
		var es_actual: bool = str(row.get("NM_ALUMNO", "")) == GlobalUsuario.nombre_alumno
		lbl.add_theme_color_override("font_color", Color(0.0, 0.3, 0.6, 1.0) if es_actual else Color(0.12, 0.07, 0.02, 1.0))
		lbl.add_theme_font_size_override("font_size", 16)
		if fuente: lbl.add_theme_font_override("font", fuente)
		_vbox_logros.add_child(lbl)

# ──────────────────────────────────────────────
# Tienda — comodines
# ──────────────────────────────────────────────
func actualizar_dinero_visual() -> void:
	var id := GlobalUsuario.usuario_actual_id
	db.query("SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d;" % id)
	if db.query_result.size() > 0:
		label_dinero.text = str(db.query_result[0].get("NU_DINERO", 0)) + " Bs."
	else:
		label_dinero.text = "0 Bs."

func _on_buttonporcentaje_pressed() -> void:
	_columna_comodin = "NU_PROBABILIDAD"
	$TextureRect2/confrimarcomodines.visible = true
	compra.text = "\n¿Comprar comodín de Porcentaje?\nPrecio: %d Bs.\n" % costopor

func _on_buttonpublico_pressed() -> void:
	_columna_comodin = "NU_PUBLICO"
	$TextureRect2/confrimarcomodines.visible = true
	compra.text = "\n¿Comprar comodín de Llamada al Amigo?\nPrecio: %d Bs.\n" % costopub

func _on_buttonmitad_pressed() -> void:
	_columna_comodin = "NU_MITAD"
	$TextureRect2/confrimarcomodines.visible = true
	compra.text = "\n¿Comprar comodín de 50/50?\nPrecio: %d Bs.\n" % costomid

func _on_aceptar_pressed() -> void:
	var costo: int
	match _columna_comodin:
		"NU_PROBABILIDAD": costo = costopor
		"NU_PUBLICO":      costo = costopub
		"NU_MITAD":        costo = costomid
		_:
			Alertas.mostrar_alerta("Error: comodín no seleccionado.", 2.0)
			return

	var id := GlobalUsuario.usuario_actual_id
	db.query("SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d;" % id)
	if db.query_result.is_empty():
		Alertas.mostrar_alerta("Error al leer tu dinero.", 2.0)
		return

	var dinero_db: int = int(db.query_result[0].get("NU_DINERO", 0))
	if dinero_db >= costo:
		var col := _columna_comodin
		var q := "UPDATE Alumnos SET NU_DINERO = NU_DINERO - %d, %s = %s + 1 WHERE NU_USU = %d;" % [costo, col, col, id]
		if db.query(q):
			_columna_comodin = ""
			$TextureRect2/confrimarcomodines.visible = false
			Alertas.mostrar_alerta("¡Compra exitosa! -" + str(costo) + " Bs.", 2.0)
			actualizar_dinero_visual()
		else:
			Alertas.mostrar_alerta("Error al procesar la compra.", 2.0)
	else:
		Alertas.mostrar_alerta("No tienes suficiente dinero. Necesitas %d Bs." % costo, 2.5)

func comprar_nivel_extra(tipo: String, num_nivel: int, costo: int) -> void:
	var id := GlobalUsuario.usuario_actual_id
	db.query("SELECT * FROM Tienda WHERE NU_USU = %d AND TP_MINIJUEGO = '%s' AND NV_EXTRA = %d;" % [id, tipo, num_nivel])
	if db.query_result.size() > 0:
		Alertas.mostrar_alerta("Ya tienes este nivel desbloqueado.", 1.5)
		return
	db.query("SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d;" % id)
	if db.query_result.is_empty():
		return
	var dinero_db: int = int(db.query_result[0].get("NU_DINERO", 0))
	if dinero_db >= costo:
		db.query("INSERT INTO Tienda (NU_USU, TP_MINIJUEGO, NV_EXTRA) VALUES (%d, '%s', %d);" % [id, tipo, num_nivel])
		db.query("UPDATE Alumnos SET NU_DINERO = NU_DINERO - %d WHERE NU_USU = %d;" % [costo, id])
		Alertas.mostrar_alerta("¡Nivel desbloqueado! -" + str(costo) + " Bs.", 2.0)
		actualizar_dinero_visual()
	else:
		Alertas.mostrar_alerta("No tienes suficiente dinero. Necesitas %d Bs." % costo, 2.5)

# ──────────────────────────────────────────────
# Navegación entre vistas
# ──────────────────────────────────────────────
func _on_cancelar2_pressed() -> void:
	$TextureRect2/confrimarcomodines.visible = false
	_columna_comodin = ""

func _on_cancelar3_pressed() -> void:
	$TextureRect2/confirmarniveles.visible = false
	_pack_nivel_seleccionado = 0

func _on_tienda_2_pressed() -> void:
	$TextureRect.visible  = false
	$TextureRect2.visible = true
	$TextureRect4.visible = false
	actualizar_dinero_visual()
	_refresh_estado_packs_niveles()

func _on_cancelar_2_pressed() -> void:
	$TextureRect.visible  = false
	$TextureRect2.visible = false
	$TextureRect4.visible = true

func _on_perfil_pressed() -> void:
	$TextureRect.visible  = true
	$TextureRect2.visible = false
	$TextureRect4.visible = false
	_cargar_perfil_stats()

func _on_salir_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Login.tscn")

func _on_volvermenu_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/menu-alumno.tscn")
