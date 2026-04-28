extends Control

const SQLiteHelper = preload("res://Scripts/sqlite_helper.gd")

var db: SQLite

func _ready() -> void:
	db = SQLiteHelper.open_db_connection()

func _exit_tree() -> void:
	SQLiteHelper.close_db_connection(db)
	
func _on_creartabla_button_down() -> void:
	var table := {
		"NU_USU" : {"data_type" : "int", "primary_key" : true, "not_null" : true, "auto_increment" : true},
		"NM_ADMIN" : {"data_type" : "text", "not_null" : true, "unique" : true},
		"CO_PSW" : {"data_type" : "text", "not_null" : true}
	}
	db.create_table("Admin", table)

func _on_insertardata_button_down() -> void:
	var data := {
		"NM_ADMIN" : $nombre/nombre/name.text,
		"CO_PSW" : $nombre/nombre/name/psw.text
	}
	db.insert_row("Admin", data)


func _on_seleccionardata_button_down() -> void:
	print(db.select_rows("Admin", "1=1", ["NU_USU", "NM_ADMIN"]))


func _on_actualizardata_button_down() -> void:
	print("Accion de actualizar pendiente de implementar.")


func _on_borrardata_button_down() -> void:
	print("Accion de borrar pendiente de implementar.")


func _on_editar_seleccion_button_down() -> void:
	print("Accion de editar pendiente de implementar.")
