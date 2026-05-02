extends Node

const MENU_MUSIC_PATH := "res://Music/General/Victory_at_the_Podium.mp3"
const TRANSITION_SFX_PATH := "res://Music/Transitions/Transition.mp3"
const BUTTON_SFX_PATH := "res://Music/Buttoms/ButtonSound.mp3"
const DEBUG_AUDIO_ROUTING := false

const LEVEL_MUSIC_PATHS := {
	1: "res://Music/Nivel1/Morning_at_the_Water_s_Edge.mp3",
	2: "res://Music/Nivel2/Call_Across_the_Orinoco.mp3",
	3: "res://Music/Nivel3/Cubagua_Pearl_Dive.mp3",
	4: "res://Music/Nivel4/Iron_Sails_on_the_Tide.mp3",
	5: "res://Music/Nivel5/Courts_and_Coastlines.mp3",
	6: "res://Music/Nivel6/Steps_on_Cobblestone.mp3",
	7: "res://Music/Nivel7/Viva_la_Carga.mp3",
	8: "res://Music/Nivel8/Queen_of_the_High_Plateau.mp3",
	9: "res://Music/Nivel9/The_Final_Hour_of_Unity.mp3"
}

const MENU_SCENES := {
	"res://Scenes/Login.tscn": true,
	"res://Scenes/SuperAdminLogin.tscn": true,
	"res://Scenes/Admin.tscn": true,
	"res://Scenes/Alumno.tscn": true,
	"res://Scenes/menu-alumno.tscn": true,
	"res://Scenes/Menu-admin.tscn": true,
	"res://Scenes/Opciones.tscn": true,
	"res://Scenes/Extras.tscn": true,
	"res://Scenes/Minijuegos.tscn": true,
	"res://Scenes/SuperAdmin.tscn": true,
	"res://Mapa.tscn": true,
	"res://Scenes/principal.tscn": true
}

const LEVEL1_SCENES := {
	"res://Nivel 1.tscn": true,
	"res://Nivel1.tscn": true,
	"res://Scenes/Nivel1.tscn": true
}

var _music_player: AudioStreamPlayer
var _button_sfx_player: AudioStreamPlayer
var _transition_sfx_player: AudioStreamPlayer
var _audio_change_token: int = 0
var _menu_music_stream: AudioStream
var _level_music_streams: Dictionary = {}
var _last_scene_signature: String = ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_players()

	if not get_tree().scene_changed.is_connected(_on_scene_changed):
		get_tree().scene_changed.connect(_on_scene_changed)

	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)

	call_deferred("_sync_with_current_scene")

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var signature := _build_scene_signature(scene)

	if signature != _last_scene_signature:
		_sync_with_current_scene()

func _setup_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.volume_db = -8.0
	_menu_music_stream = _load_looped_stream(MENU_MUSIC_PATH)
	_music_player.stream = _menu_music_stream
	add_child(_music_player)

	_button_sfx_player = AudioStreamPlayer.new()
	_button_sfx_player.name = "ButtonSfxPlayer"
	_button_sfx_player.volume_db = -10.0
	_button_sfx_player.stream = load(BUTTON_SFX_PATH)
	add_child(_button_sfx_player)

	_transition_sfx_player = AudioStreamPlayer.new()
	_transition_sfx_player.name = "TransitionSfxPlayer"
	_transition_sfx_player.volume_db = -7.0
	_transition_sfx_player.stream = load(TRANSITION_SFX_PATH)
	add_child(_transition_sfx_player)

func _load_looped_stream(path: String) -> AudioStream:
	var stream := load(path)
	if stream == null:
		return null

	if stream is AudioStreamMP3:
		var mp3 := (stream as AudioStreamMP3).duplicate() as AudioStreamMP3
		mp3.loop = true
		return mp3

	if stream is AudioStreamOggVorbis:
		var ogg := (stream as AudioStreamOggVorbis).duplicate() as AudioStreamOggVorbis
		ogg.loop = true
		return ogg

	if stream is AudioStreamWAV:
		var wav := (stream as AudioStreamWAV).duplicate() as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		return wav

	return stream

func _on_scene_changed(_scene_root: Node) -> void:
	call_deferred("_sync_with_current_scene")

func _sync_with_current_scene() -> void:
	var current_scene := get_tree().current_scene
	var signature := _build_scene_signature(current_scene)

	if signature == _last_scene_signature:
		return

	_last_scene_signature = signature

	if current_scene == null:
		_debug_log("Scene is null during transition; keeping current audio")
		return

	var scene_path := current_scene.scene_file_path
	var scene_script_path := _get_scene_script_path(current_scene)
	_debug_log("Scene sync path=%s script=%s" % [scene_path, scene_script_path])

	_connect_buttons_recursive(current_scene)
	_handle_scene_audio(scene_path, scene_script_path)

func _handle_scene_audio(scene_path: String, scene_script_path: String) -> void:
	_audio_change_token += 1
	var token := _audio_change_token

	if _is_menu_scene(scene_path):
		_debug_log("Detected menu scene")
		_stop_transition_sfx()
		_play_music(MENU_MUSIC_PATH)
		return

	if _is_any_level_scene(scene_path, scene_script_path):
		_debug_log("Detected level scene")
		_stop_music()
		var level_number := _detect_level_number(scene_path, scene_script_path)
		_play_transition_then_level(token, level_number)
		return

	_debug_log("Scene not classified as menu/level")
	_stop_transition_sfx()
	_stop_music()

func _is_menu_scene(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false
	return MENU_SCENES.has(scene_path)

func _is_any_level_scene(scene_path: String, scene_script_path: String) -> bool:
	if not scene_path.is_empty():
		var scene_file_name := scene_path.get_file().to_lower()
		if scene_file_name.begins_with("nivel") and scene_file_name.ends_with(".tscn"):
			return true

	if scene_script_path.is_empty():
		return false

	var script_file_name := scene_script_path.get_file().to_lower()
	return script_file_name.begins_with("nivel") and script_file_name.ends_with(".gd")

func _build_scene_signature(scene: Node) -> String:
	if scene == null:
		return ""

	var scene_path := scene.scene_file_path
	var scene_script_path := _get_scene_script_path(scene)

	if not scene_path.is_empty():
		if scene_script_path.is_empty():
			return scene_path
		return "%s|%s" % [scene_path, scene_script_path]

	if not scene_script_path.is_empty():
		return scene_script_path

	return str(scene.get_instance_id())

func _get_scene_script_path(scene: Node) -> String:
	if scene == null:
		return ""

	var script_resource := scene.get_script() as Script
	if script_resource == null:
		return ""

	return script_resource.resource_path

func _play_music(path: String) -> void:
	if _music_player == null:
		return

	var target_stream: AudioStream
	if path == MENU_MUSIC_PATH:
		target_stream = _menu_music_stream
	else:
		target_stream = _level_music_streams.get(path, null)
		if target_stream == null:
			target_stream = _load_looped_stream(path)
			if target_stream:
				_level_music_streams[path] = target_stream

	if target_stream == null:
		return

	if _music_player.stream != target_stream:
		_music_player.stream = target_stream
		_debug_log("Play music %s" % path)
		_music_player.play()
		return

	if not _music_player.playing:
		_debug_log("Resume music %s" % path)
		_music_player.play()

func _stop_music() -> void:
	if _music_player and _music_player.playing:
		_music_player.stop()

func _play_transition_then_level(token: int, level_number: int) -> void:
	var level_music_path := _get_level_music_path(level_number)
	if level_music_path.is_empty():
		_debug_log("No music configured for level %d" % level_number)
		_play_transition_only()
		return

	if _transition_sfx_player == null or _transition_sfx_player.stream == null:
		_debug_log("Transition stream missing; fallback to level music")
		_play_music(level_music_path)
		return

	_debug_log("Play transition SFX then level %d" % level_number)
	_transition_sfx_player.play()
	await _transition_sfx_player.finished

	if token != _audio_change_token:
		_debug_log("Transition cancelled by newer scene change")
		return

	_play_music(level_music_path)

func _detect_level_number(scene_path: String, scene_script_path: String) -> int:
	var from_scene := _extract_level_number(scene_path.get_file())
	if from_scene > 0:
		if LEVEL1_SCENES.has(scene_path) and int(GlobalUsuario.nivel_seleccionado) > 0:
			return int(GlobalUsuario.nivel_seleccionado)
		return from_scene

	var from_script := _extract_level_number(scene_script_path.get_file())
	if from_script > 0:
		return from_script

	return maxi(1, int(GlobalUsuario.nivel_seleccionado))

func _extract_level_number(file_name: String) -> int:
	if file_name.is_empty():
		return -1

	var digits := ""
	for c in file_name:
		if c.is_valid_int():
			digits += c

	if digits.is_empty():
		return -1

	return int(digits)

func _get_level_music_path(level_number: int) -> String:
	if LEVEL_MUSIC_PATHS.has(level_number):
		return str(LEVEL_MUSIC_PATHS[level_number])
	return ""

func _play_transition_only() -> void:
	if _transition_sfx_player == null or _transition_sfx_player.stream == null:
		return
	_debug_log("Play transition SFX only")
	_transition_sfx_player.play()

func _stop_transition_sfx() -> void:
	if _transition_sfx_player and _transition_sfx_player.playing:
		_transition_sfx_player.stop()

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node as BaseButton)

func _connect_buttons_recursive(root: Node) -> void:
	if root == null:
		return

	if root is BaseButton:
		_connect_button(root as BaseButton)

	for child in root.get_children():
		_connect_buttons_recursive(child)

func _connect_button(button: BaseButton) -> void:
	if button == null:
		return
	if button.pressed.is_connected(_on_any_button_pressed):
		return
	button.pressed.connect(_on_any_button_pressed)

func _on_any_button_pressed() -> void:
	if _button_sfx_player == null or _button_sfx_player.stream == null:
		return
	_button_sfx_player.play()

func _debug_log(message: String) -> void:
	if not DEBUG_AUDIO_ROUTING:
		return
	print("[AudioManager] %s" % message)
