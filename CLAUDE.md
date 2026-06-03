# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Vene-trivia: juego educativo de historia de Venezuela. Godot 4.6 + GDScript + SQLite (addon `addons/godot-sqlite`). Escena principal: `Scenes/Login.tscn`.

## Comandos

No hay test harness ni build de release configurados. El proyecto se corre desde el editor (F5) o headless vía el MCP de Godot incluido en el repo.

- **Godot headless** (vía `.mcp.json` → server `godot`): usa `GODOT_PATH` de `.env` (cada dev pone su ruta; plantilla en `.env.example`). Herramientas MCP: `run_project`, `get_debug_output`, `launch_editor`, `get_project_info`. Primera vez: `cd godot-mcp && pnpm install && pnpm build`.
- **Inspeccionar la DB** (no hay sqlite3 CLI; usar Python stdlib):
  ```bash
  python -c "import sqlite3; c=sqlite3.connect('DB/venetrivia.db'); print([r[1] for r in c.execute('PRAGMA table_info(Alumnos)')])"
  ```
- **Verificar un cambio**: correr el proyecto headless y leer `get_debug_output`; los scripts usan `print()`/`push_error()` abundantemente. Para UI, `launch_editor` e inspección visual. godot-sqlite **no lanza excepción** en query a tabla/columna inexistente — devuelve `false` y sigue (falla silenciosa); revisar siempre el esquema real con Python.

## Autoloads — los nombres NO coinciden con los archivos

Verificado por `.gd.uid` (el README está desactualizado en esto). En `project.godot`:

- `GlobalUsuario` = `Datosusuario.gd` — sesión en memoria (`usuario_actual_id`, `nombre_alumno`, `nivel_maximo`, `nivel_seleccionado`).
- `Configuracion` = **`SceneManager.gd`** (NO `ConfigGlobal.gd`). Provee `change_scene_to_file()` (envoltura sobre el SceneTree con guardado), `brillo/saturacion/contraste/fullscreen/res_index`, `guardar_ajustes()`/`cargar_ajustes()`. Casi toda la navegación pasa por `Configuracion.change_scene_to_file(...)`.
- `Alertas` = `alertas.tscn` (+ `AlertasGlobal.gd`) — `mostrar_alerta(texto, tiempo)` para toasts.
- `AudioManager` = `Scripts/audio_manager.gd` — música/SFX por escena vía señales del SceneTree; clasifica escenas con `MENU_SCENES`/`LEVEL_*`.
- **Código muerto (no autoloaded, ignorar):** `ConfigGlobal.gd`, `ConfiguracionGlobal.gd`. No editar para arreglar config — el real es `SceneManager.gd`.

## Arquitectura

**Flujo de escenas:** `Login` → `Alumno`/`Admin` (login+registro) → `menu-alumno` → { `Mapa`→`Nivel 1.tscn` | `Minijuegos`→selectores→escena de minijuego | `Opciones` | `Extras` | `perfil` (incluye tienda) }. Docente: `Login`→`Admin`→`Menu-admin`.

**Juego principal (`Scenes/Niveles.gd`, escena `Nivel 1.tscn`):** una sola escena reutilizada para todos los niveles. El número de nivel viene de `GlobalUsuario.nivel_seleccionado`; las preguntas de `res://Jsons/Preguntas_nivel_<N>.json` (existen 1-15). Ronda de 15 preguntas, temporizador por pregunta, 3 comodines (50/50, llamada, público). Al terminar: calcula estrellas/puntos y persiste vía `Scripts/sqlite_helper.gd`.

**Persistencia (`Scripts/sqlite_helper.gd`):** clase estática `RefCounted`. `open_db_connection()` abre y hace `ensure_*` (crea tablas si faltan). Queries con strings interpolados (`escape()` solo reemplaza comillas — riesgo de inyección, claves en texto plano). Tablas reales: `Alumnos`, `niveles` (mejor resultado por nivel), `niveles_intentos` (historial), `minijuegos_resultados`, `logros_alumno`, `Tienda(NU_USU, TP_MINIJUEGO, NV_EXTRA)`, `actividad`.

**Panel docente (`Scenes/menu_admin.gd`):** funcional y completo — gestión de alumnos, auditoría (`actividad`), rendimiento (lee `niveles` + `minijuegos_resultados` + `logros_alumno`). Al modificar persistencia de minijuegos, mantener `minijuegos_resultados` poblada o el panel mostrará ceros.

**Opciones (tres scripts, base + 2):** `Scripts/opciones_base.gd` es la base; `Scenes/opciones.gd` y `opcionesnivel.gd` heredan de ella. Aplican resolución/brillo/volumen sobre `Configuracion` y un `WorldEnvironment` llamado `WorldGamma` que cada escena de fondo debe tener.

**Minijuegos:** selectores (`selector*.gd`) → escenas de juego (`nivelsopa.gd`, `nivel_columna.gd`, `nivelmemoria.gd`). Cada uno tiene su banco de datos propio embebido (no leen los JSON del juego principal). El desbloqueo de los niveles 11-15 es por compra en la tienda.

## Deuda técnica conocida (verificada)

- **Persistencia de minijuegos rota:** `nivelsopa.gd`/`nivel_columna.gd` guardan en tablas (`sopa_*`, `columnas_*`, `tienda_desbloqueos`) y columnas (`NU_NIVEL_MAX_SOPA/COLUMNAS`) que **no existen** → nunca guardan. `nivelmemoria.gd` está incompleto (`finalizar_juego_victoria` solo hace `print`). `carta_memoria.gd` pasa un PNG a `add_theme_stylebox_override` (un PNG no es StyleBox).
- **Tienda desconectada:** `perfil.gd` escribe en `Tienda`; los selectores usan booleanos hardcodeados; `nivel_columna.gd` lee `tienda_desbloqueos` (inexistente). Tres mecanismos que no se hablan.
- **`Nivel 1.tscn` vs `Nivel1.tscn`:** referencias a escenas/columnas que no existen en varios sitios.

Plan de trabajo detallado y mapeo de bugs: `docs/superpowers/plans/2026-06-02-vene-trivia-12-tareas.md`.

## Tooling del repo

`godot-mcp/` es el servidor MCP de Godot vendoreado (Node/TS). `.mcp.json` lo registra (cualquier IA que abra el repo lo detecta). `.env` (gitignored) lleva `GODOT_PATH` local de cada dev; `.env.example` es la plantilla. `node_modules/` y `build/` de godot-mcp están gitignored.
