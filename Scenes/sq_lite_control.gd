extends Control

var db : SQLite

func _ready():
	db = SQLite.new()
	db.path = "res://DB/venetrivia.db"
	db.open_db()
	
func _on_creartabla_button_down() -> void:
	var table = {
		"NU_USU" : {"data_type" : "int", "primary_key" : true, "not_null" : true, "auto_increment" : true},
		"NM_ADMIN" : {"data_type" : "text", "not_null" : true, "unique" : true},
		"CO_PSW" : {"data_type" : "text", "not_null" : true}
	}
	db.create_table("Admin", table)
	pass # Replace with function body.

func _on_insertardata_button_down() -> void:
	var data = {
		"NM_ADMIN" : $nombre/nombre/name.text,
		"CO_PSW" : $nombre/nombre/name/psw.text
	}
	db.insert_row("Admin", data)
	pass # Replace with function body.


func _on_seleccionardata_button_down() -> void:
	pass # Replace with function body.


func _on_actualizardata_button_down() -> void:
	pass # Replace with function body.


func _on_borrardata_button_down() -> void:
	pass # Replace with function body.


func _on_editar_seleccion_button_down() -> void:
	pass # Replace with function body.
