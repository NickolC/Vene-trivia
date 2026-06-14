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

**Juego principal (`Scenes/Niveles.gd`, escena `Nivel 1.tscn`):** una sola escena reutilizada para todos los niveles. El número de nivel viene de `GlobalUsuario.nivel_seleccionado`; las preguntas de `res://Jsons/Preguntas_nivel_<N>.json` (existen 1-15). Ronda de 15 preguntas, temporizador por pregunta, 3 comodines (50/50, llamada, público). Al terminar: calcula estrellas/puntos y persiste vía `Scripts/sqlite_helper.gd`. También registra el tiempo total por nivel con `REPLACE INTO tiempos_niveles`.

**Nivel Verdadero/Falso (`nivelverdfal.gd`, escena `nivelverdfal.tscn`):** tipo de nivel propio, separado del juego principal y de los minijuegos. Selector: `selectorverdfal.gd`. Persiste el resultado en `minijuegos_resultados` (con `NM_MINIJUEGO = 'verdadero_falso_<N>'`) y avanza `Alumnos.NU_NIVEL_MAX`; la tabla `trueorfalse_niveles` la escriben los selectores.

**Persistencia (`Scripts/sqlite_helper.gd`):** clase estática `RefCounted`. `open_db_connection()` abre y hace `ensure_*` (crea tablas si faltan). Queries con strings interpolados (`escape()` solo reemplaza comillas — riesgo de inyección, claves en texto plano). El esquema real (verificar siempre con Python) es más grande que el README:
- **Auth:** `Alumnos` (incluye `NU_DINERO`, `SW_ACTIVO`, comodines `NU_PUBLICO/NU_PROBABILIDAD/NU_MITAD`, y `NU_NIVEL_MAX_SOPA/COLUMNAS/MEMORIA`), `Admin`, `SuperAdmin`.
- **Juego principal:** `niveles` (mejor resultado), `niveles_intentos` (historial), `nivel_1` (legacy, mismas columnas que `niveles`).
- **Minijuegos (mejor + historial por minijuego):** `sopa_niveles`/`sopa_intentos`, `columnas_niveles`/`columnas_intentos`, `memoria_niveles`/`memoria_intentos`, `trueorfalse_niveles`. Más `minijuegos_resultados` (agregado que lee el panel docente).
- **Otros:** `Tienda(NU_USU, TP_MINIJUEGO, NV_EXTRA)`, `minijuegos_bloqueos(NU_USU, TX_MINIJUEGO, SW_BLOQUEADO)`, `logros_alumno`, `tiempos_niveles(NU_USU, TX_TIPO_NIVEL, NU_NIVEL, TIEMPOTOTAL_SEGUNDOS, ...)`, `actividad` (auditoría).

**Panel docente (`Scenes/menu_admin.gd`):** funcional y completo — gestión de alumnos, **creación y edición de niveles**, bloqueo/desbloqueo de minijuegos por alumno (`minijuegos_bloqueos`, leído por `Scenes/minijuegos.gd`), auditoría (`actividad`), rendimiento (lee `niveles` + `minijuegos_resultados` + `logros_alumno`). Al modificar persistencia de minijuegos, mantener `minijuegos_resultados` poblada o el panel mostrará ceros. Nota: la creación/edición de niveles aún **no escribe auditoría** en `actividad`.

**Opciones (tres scripts, base + 2):** `Scripts/opciones_base.gd` es la base; `Scenes/opciones.gd` y `opcionesnivel.gd` heredan de ella. Aplican resolución/brillo/volumen sobre `Configuracion` y un `WorldEnvironment` llamado `WorldGamma` que cada escena de fondo debe tener.

**Minijuegos:** selectores (`selector*.gd`, más el genérico `Scripts/selector_minijuego_json.gd`) → escenas de juego (`nivelsopa.gd`, `nivel_columna.gd`, `nivelmemoria.gd`). Cada uno tiene su banco de datos propio embebido (no leen los JSON del juego principal). Los tres persisten ahora correctamente: `_guardar_progreso*` hace `INSERT` en `<juego>_intentos`/`<juego>_niveles` + `minijuegos_resultados` y actualiza `Alumnos.NU_NIVEL_MAX_<JUEGO>`. El desbloqueo de los niveles 11-15 es por compra en la tienda; el docente puede bloquear/desbloquear minijuegos por alumno vía `minijuegos_bloqueos`.

## Deuda técnica conocida (verificada)

- **`carta_memoria.gd`** pasa un `Texture2D` (PNG vía `load(...)`) a `add_theme_stylebox_override("normal", ...)`, que espera un `StyleBox` — no aplica el estilo correctamente.
- **Tienda con tres mecanismos:** `perfil.gd` escribe en `Tienda`; algunos selectores usan booleanos hardcodeados; el bloqueo del docente vive en `minijuegos_bloqueos`. No están unificados (verificar coherencia al tocar desbloqueos).
- **`Nivel 1.tscn` vs `Nivel1.tscn`:** referencias a escenas/columnas que no existen en varios sitios.
- **Conflictos de merge sin resolver:** ha pasado que se commitean archivos con marcadores `<<<<<<<`/`=======`/`>>>>>>>` (ej. `nivelverdfal.gd`/`.tscn`, ya corregidos). Antes de commitear: `grep -rl '^<<<<<<< ' --include=*.gd --include=*.tscn .`
- **`actividad` incompleta:** la creación/edición de niveles del panel docente no registra auditoría.

> Nota: la antigua deuda "persistencia de minijuegos rota" (tablas/columnas inexistentes, `nivelmemoria` solo con `print`) ya está **resuelta** — las tablas existen y los scripts escriben en ellas. Verificado contra el esquema real.

Plan de trabajo detallado y mapeo de bugs: `docs/superpowers/plans/2026-06-02-vene-trivia-12-tareas.md`.

## Tooling del repo

`godot-mcp/` es el servidor MCP de Godot vendoreado (Node/TS). `.mcp.json` lo registra (cualquier IA que abra el repo lo detecta). `.env` (gitignored) lleva `GODOT_PATH` local de cada dev; `.env.example` es la plantilla. `node_modules/` y `build/` de godot-mcp están gitignored.
