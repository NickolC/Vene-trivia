# Plan Maestro v2 — 12 Tareas Vene-trivia

> **Para ejecutores agénticos:** SUB-SKILL REQUERIDA: superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans. Pasos con checkboxes (`- [ ]`).

**Goal:** Arreglar layout de preguntas, responsividad, volumen por canal, economía/tienda, perfil, logros con alertas, reportes docente PDF, opciones de nivel, minijuegos y extras — sin romper lo que ya funciona (panel docente).

**v2:** Reescrito tras revisión completa del proyecto. Incorpora 10 bugs nuevos (N1-N10) hallados en minijuegos/tienda/persistencia y las decisiones del autor (tablas separadas, bancos propios con datos reales, tabla `Tienda` única).

---

## Mapeo real (verificado leyendo TODO el proyecto)

**Autoloads** (los nombres engañan, confirmado por uid):
- `GlobalUsuario` = `Datosusuario.gd`
- `Configuracion` = **`SceneManager.gd`** (tiene brillo/saturacion/contraste/fullscreen/res_index + `change_scene_to_file`; NO tiene RESOLUTIONS/volumen/aplicar_ajustes_actuales)
- `Alertas` = `alertas.tscn` (+ AlertasGlobal.gd → `mostrar_alerta(texto, tiempo)`)
- `AudioManager` = `Scripts/audio_manager.gd` (3 AudioStreamPlayer sin bus)
- **CÓDIGO MUERTO (no autoloaded):** `ConfigGlobal.gd`, `ConfiguracionGlobal.gd`

**DB real (`DB/venetrivia.db`):**
- `Alumnos(NU_USU, NM_ALUMNO, CO_PSW, NU_NIVEL_MAX, NU_PUBLICO, NU_PROBABILIDAD, NU_MITAD, NU_DINERO, SW_ACTIVO)`
- `niveles(...mejor resultado por nivel...)`, `niveles_intentos(...historial...)`
- `minijuegos_resultados(NU_USU, NM_ALUMNO, NM_MINIJUEGO, NU_INTENTOS, NU_PUNTOS, NU_ESTRELLAS, FE_ULTIMO)` ← **el panel docente lee esta**
- `logros_alumno(...)`, `Tienda(NU_USU, TP_MINIJUEGO, NV_EXTRA)`, `actividad(...)`
- **NO existen:** `sopa_intentos`, `sopa_niveles`, `columnas_intentos`, `columnas_niveles`, `tienda_desbloqueos` (el código de minijuegos las usa → falla silenciosa)
- `Alumnos` **NO tiene** `NU_NIVEL_MAX_SOPA` ni `NU_NIVEL_MAX_COLUMNAS` (el código las actualiza → falla)
- Preguntas JSON `res://Jsons/Preguntas_nivel_1..15.json` ✓ existen

## Inventario de bugs

**De config/audio/UI (v1):**
- A. `SceneManager.gd` no define `RESOLUTIONS`, `volumen_*`, `aplicar_ajustes_actuales()`
- B. `opciones_base.gd:97,102` llama `Configuracion.aplicar_ajustes_actuales()` → no existe → error
- C. `opciones.gd:190-192`, `opcionesnivel.gd:208-210` guardan `Configuracion.volumen_*` → no existen
- D. `audio_manager.gd:68-86` players sin `.bus` → no se puede separar música/efectos
- F. `Nivel 1.tscn:150-159`+`Niveles.gd:350-357` pregunta sin ancho máx → desborde
- G. `Niveles.gd:540-567` no acredita `NU_DINERO`
- H. `perfil.gd:73-93` compra comodín no suma columna del comodín
- L. `opcionesnivel.gd:96` find_child con ruta-string inválida

**Nuevos de minijuegos/tienda (v2):**
- N1. `nivelsopa.gd:369-387` guarda en `sopa_intentos`/`sopa_niveles`/`NU_NIVEL_MAX_SOPA` inexistentes
- N2. `nivel_columna.gd:641-652` guarda en `columnas_*`/`NU_NIVEL_MAX_COLUMNAS` inexistentes
- N3. `nivel_columna.gd:569` lee `tienda_desbloqueos` inexistente (real: `Tienda`)
- N4. selectores: desbloqueo por booleanos hardcodeados `nivel_11_comprado=false`, no leen DB
- N5. 3 mecanismos de tienda inconexos (perfil→`Tienda`, selector→bools, columna→`tienda_desbloqueos`)
- N6. `carta_memoria.gd:34,44` `add_theme_stylebox_override("normal", load("....png"))` — PNG no es StyleBox
- N7. `nivelmemoria.gd:122` `finalizar_juego_victoria()` solo `print` (sin estrellas/guardado/nivel/cronómetro)
- N8. `nivel_columna.gd:26-282` datos placeholder repetidos ("19 de Abr/Independencia")
- N9. `nivel_columna.gd:16` `RUTA_ESCENA_SELECCION="res://selectorcolumnas.tscn"` no existe (real: `selectorelacioncolumn.tscn`)
- N10. selectores `:161` estrellas preview leen `niveles` (juego principal) en vez del minijuego

## Decisiones del autor (fijadas)
1. Persistencia minijuego: **crear tablas separadas** `sopa_*`/`columnas_*`/`memoria_*` + columnas `NU_NIVEL_MAX_*`. **Más:** cada save hace mirror-upsert en `minijuegos_resultados` para que el panel docente siga viéndolos.
2. Contenido minijuego: **bancos propios** en cada minijuego, rellenados con **datos reales** por nivel (arregla N8).
3. Desbloqueo tienda: **solo tabla `Tienda(NU_USU, TP_MINIJUEGO, NV_EXTRA)`** en todos lados.

**Verificación:** sin harness de tests UI. Cada fase se valida con el MCP de Godot: `run_project` + `get_debug_output` (sin errores) y `launch_editor` para inspección visual; lecturas a DB con `python -c "import sqlite3..."`.

---

## FASE 0 — Cimientos: config + audio + esquema DB (BLOQUEA 3, 6, 7, 9, 10)

### Task 0.1: Buses de audio Master/Music/SFX
**Files:** `default_bus_layout.tres` (editor), `Scripts/audio_manager.gd:68-86`
- [ ] Editor (`launch_editor`): panel Audio → buses `Music` y `SFX` → output `Master`. Guardar layout en Project Settings.
- [ ] Asignar `.bus`: `_music_player.bus="Music"`, `_button_sfx_player.bus="SFX"`, `_transition_sfx_player.bus="SFX"`.
- [ ] Verificar: `run_project`+`get_debug_output` sin error de bus.

### Task 0.2: Volumen por canal en `Configuracion` (SceneManager.gd)
**Files:** `SceneManager.gd`
- [ ] Añadir `DEFAULT_VOL_*` y vars `volumen_maestro/musica/sfx` (float 0..1, default 1.0).
- [ ] Persistir/leer en `guardar_ajustes()`/`cargar_ajustes()`.
- [ ] `aplicar_volumenes()` mapea lineal→dB y aplica a buses; mute si <=0.001:
```gdscript
func aplicar_volumenes() -> void:
    _set_bus_volume("Master", volumen_maestro)
    _set_bus_volume("Music", volumen_musica)
    _set_bus_volume("SFX", volumen_sfx)
func _set_bus_volume(bus_name: String, lineal: float) -> void:
    var idx := AudioServer.get_bus_index(bus_name)
    if idx < 0: return
    if lineal <= 0.001:
        AudioServer.set_bus_mute(idx, true); return
    AudioServer.set_bus_mute(idx, false)
    AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(lineal, 0.0, 1.0)))
```
- [ ] Llamar `aplicar_volumenes()` al final de `cargar_ajustes()` y en `_ready()`.

### Task 0.3: `RESOLUTIONS` + `aplicar_ajustes_actuales()` en `Configuracion`
**Files:** `SceneManager.gd`, `Scripts/opciones_base.gd`
- [ ] Mover `RESOLUTIONS` (16 entradas de `opciones_base.gd:3-20`) a `SceneManager.gd` como `const`. Fuente única.
- [ ] Implementar `aplicar_ajustes_actuales()` (causa del crash B): fullscreen→WINDOW_MODE_FULLSCREEN; windowed→set_size(RESOLUTIONS[res_index])+centrar; aplicar env WorldGamma; `aplicar_volumenes()`.
- [ ] `opciones_base.gd` usa `Configuracion.RESOLUTIONS` (quitar local).
- [ ] Verificar: abrir Opciones sin error "aplicar_ajustes_actuales".

### Task 0.4: Borrar código muerto
**Files:** delete `ConfigGlobal.gd(.uid)`, `ConfiguracionGlobal.gd(.uid)`
- [ ] `grep -rn "ConfigGlobal\|ConfiguracionGlobal" --include=*.gd --include=*.tscn .` → vacío. Borrar. `run_project` ok.

### Task 0.5: Esquema DB faltante (decisión 1) — en `Scripts/sqlite_helper.gd`
**Files:** `Scripts/sqlite_helper.gd` (+ llamarlas en `open_db_connection`)
- [ ] `ensure_sopa_tables(db)`: crea `sopa_intentos(NU_INTENTO PK, NU_USU, NM_ALUMNO, NU_NIVEL, NU_PUNTOS, NU_ESTRELLAS, SW_COM, FE_INTENTO)` y `sopa_niveles(NU_NIVEL, NU_USU, NM_ALUMNO, NU_PUNTOS, NU_ESTRELLAS, SW_COM, PK(NU_NIVEL,NU_USU))`.
- [ ] `ensure_columnas_tables(db)`: idem con `columnas_intentos`/`columnas_niveles`.
- [ ] `ensure_memoria_tables(db)`: idem `memoria_intentos`/`memoria_niveles`.
- [ ] `ensure_alumnos_minijuego_columns(db)`: `ALTER TABLE Alumnos ADD COLUMN NU_NIVEL_MAX_SOPA INTEGER DEFAULT 1` (idem COLUMNAS, MEMORIA) con guarda PRAGMA como `ensure_alumnos_activo_column`.
- [ ] Llamar las 4 nuevas en `open_db_connection()`.
- [ ] Verificar: `python` confirma que las tablas/columnas existen tras abrir el juego una vez.

---

## FASE 1 — Layout responsivo (Tareas 1 y 2)

### Task 1.1: Pregunta no desborda (Tarea 1)
**Files:** `Nivel 1.tscn` (Label pregunta + su PanelContainer), `Scenes/Niveles.gd:350-357`
- [ ] En el `.tscn`: Label pregunta `autowrap_mode=3`; dar ancho máximo vía contenedor (`PanelContainer.custom_minimum_size.x≈1100`, MarginContainer con márgenes). Alto crece con el wrap.
- [ ] Quitar `fondo_pregunta.reset_size()` (`Niveles.gd:357`) que rompe el ancho fijo.
- [ ] Verificar: nivel con pregunta larga → texto en varias líneas dentro de márgenes (`launch_editor`).

### Task 1.2: Componentes respetan lugar al cambiar resolución en ventana (Tarea 2)
**Causa:** HUD con `anchors_preset=-1` + offsets absolutos (ej. `Buttoncomodin offset_left=1578`); stretch `expand` recoloca por aspecto al achicar.
**Files:** Project Settings; `Nivel 1.tscn` (y escenas con HUD absoluto)
- [ ] Display→Window→Stretch: `mode=canvas_items`, probar `aspect=keep` (evita recolocación por aspecto). Validar visualmente (puede dar barras negras → decisión).
- [ ] HUD posicionado con offsets absolutos → asignar anchor preset coherente (ej. esquina sup. der.) con offsets pequeños.
- [ ] Verificar: cambiar resolución en ventana; botones/labels en su sitio.

---

## FASE 2 — Economía y tienda (Tarea 4)

### Task 2.1: Dinero al finalizar nivel + mostrarlo
**Files:** `Scenes/Niveles.gd` (`finalizar_nivel`/`mostrar_resultados`/`guardar_final_nivel`), `Nivel 1.tscn` (`PantallaResultados/Panel` + `LabelDinero`)
- [ ] Fórmula: `dinero_ganado = correctas*10 + estrellas*25`. Política (decisión autor): **acreditar siempre** (repetir da dinero).
- [ ] En `guardar_final_nivel`: `UPDATE Alumnos SET NU_DINERO = NU_DINERO + dinero_ganado WHERE NU_USU=id`.
- [ ] `mostrar_resultados`: pintar `LabelDinero` con "Dinero ganado: %d Bs.".
- [ ] Verificar: terminar nivel → `python` confirma `NU_DINERO` subió.

### Task 2.2: Comodines comprables (Tarea 4)
**Files:** `perfil.gd:73-93`, `Scenes/Niveles.gd` (gasto de comodín)
- [ ] Mapear botón→columna: público→`NU_PUBLICO`, probabilidad/porcentaje→`NU_PROBABILIDAD`, mitad→`NU_MITAD`.
- [ ] Compra: `UPDATE Alumnos SET NU_DINERO=NU_DINERO-costo, <col>=<col>+1 WHERE NU_USU=id`.
- [ ] En `Niveles.gd`: al usar comodín `<col>=<col>-1`, `disabled = stock<=0`; leer stock al iniciar nivel.
- [ ] Verificar: comprar → columna +1, dinero -costo.

### Task 2.3: Tienda de niveles extra unificada en `Tienda` (decisión 3 — arregla N3,N4,N5,N9)
**Files:** `perfil.gd:95-125`; `selectorsopaletras.gd`, `selectorelacioncolumn.gd`, `selectormemoria.gd`; `nivel_columna.gd:16,567-573`
- [ ] `perfil.comprar_nivel_extra`: quitar `costo=500` hardcode (recibir costo real); INSERT en `Tienda(NU_USU, TP_MINIJUEGO, NV_EXTRA)` + restar dinero (ya casi está).
- [ ] Crear helper `SQLiteHelper.nivel_comprado(db, id, tp_minijuego, nv) -> bool` que consulta `Tienda`.
- [ ] En CADA selector: borrar booleanos `nivel_1X_comprado`; `_verificar_si_nivel_esta_comprado(n)` → `SQLiteHelper.nivel_comprado(db, id, "<tp>", n)`. `<tp>`: "sopa"/"columnas"/"memoria".
- [ ] `nivel_columna.gd`: `_verificar_nivel_desbloqueado_en_tienda` → usar `Tienda` (no `tienda_desbloqueos`); corregir `RUTA_ESCENA_SELECCION` a `res://selectorelacioncolumn.tscn` (N9).
- [ ] Verificar: comprar nivel 11 sopa → fila en `Tienda` → selector lo desbloquea → entra.

---

## FASE 3 — Perfil + leaderboard (Tarea 5)

### Task 3.1: Helper de estadísticas
**Files:** create `Scripts/perfil_stats.gd`
- [ ] Métodos estáticos(db, id): puntaje_total (`SUM(NU_PUNTOS) niveles`), puntos_por_nivel, estrellas_totales+por_nivel, comodines (`NU_PUBLICO/PROBABILIDAD/MITAD`), dinero, niveles_desbloqueados (`NU_NIVEL_MAX` + `NU_NIVEL_MAX_SOPA/COLUMNAS/MEMORIA`), minijuegos_desbloqueados (`Tienda`), niveles_perfectos (`NU_ESTRELLAS=3`), peor+normal (`niveles_intentos` min/avg), veces_repetido (`COUNT niveles_intentos`), leaderboard (`SUM puntos GROUP BY usuario ORDER DESC LIMIT 10`).
- [ ] Verificar: `print` desde script temporal con `run_project`.

### Task 3.2: Pintar perfil + scroll de logros
**Files:** `perfil.tscn` (labels/listas + `ScrollContainer` abajo), `perfil.gd`
- [ ] `_ready` rellena todas las stats. Leaderboard top-10. Logros en `ScrollContainer>VBoxContainer` (catálogo con bloqueados en gris).
- [ ] Verificar: perfil de alumno con datos; inspección visual.

---

## FASE 4 — Logros + alertas (Tareas 8 y 11)

### Task 4.1: Motor de logros
**Files:** create `Scripts/logros.gd` (autoload `Logros`)
- [ ] `const CATALOGO` (clave→texto). `desbloquear(clave)`: si no existe en `logros_alumno`, INSERT + emite `logro_desbloqueado(clave, texto)`. `evaluar_post_nivel(estrellas, puntos, dinero_total)`.
- [ ] Verificar: fila en `logros_alumno`.

### Task 4.2: Alerta visual (Tarea 11)
**Files:** `Scripts/logros.gd`, opcional `AlertasGlobal.gd`
- [ ] Al `logro_desbloqueado` → `Alertas.mostrar_alerta("🏆 Logro: %s" % texto, 3.0)` (o `mostrar_logro` con panel propio).
- [ ] `Niveles.gd:guardar_final_nivel` (y cada minijuego) llaman `Logros.evaluar_post_nivel(...)`.
- [ ] Verificar: terminar nivel que dispare logro → alerta visible.

---

## FASE 5 — Escena Opciones-nivel (Tarea 9 — arregla L, C)
**Files:** `opcionesnivel.gd`
- [ ] Borrar `aplicar_todo()` local roto (L); usar `Configuracion.aplicar_ajustes_actuales()` (Task 0.3).
- [ ] Sliders volumen → `Configuracion.volumen_*` + `aplicar_volumenes()` (depende Fase 0).
- [ ] Confirmar `_on_salir_pressed` (Mapa) y `cerrar_opciones()` reabre pausa del nivel.
- [ ] Verificar: en nivel, pausa→opciones, cambiar brillo/volumen efecto inmediato; cerrar y reanudar.

---

## FASE 6 — Minijuegos funcionales (Tarea 10 — arregla N1,N2,N6,N7,N8,N10)
> Depende de Fase 0.5 (tablas). Tras auditoría conviene sub-planes por minijuego.

### Task 6.1: Auditoría
- [ ] `run_project` cada minijuego desde su selector; `get_debug_output`; anotar estado.

### Task 6.2: Persistencia sopa (N1) + mirror docente
**Files:** `nivelsopa.gd:361-387`
- [ ] Guardar en `sopa_intentos`/`sopa_niveles` (ya creadas) y `NU_NIVEL_MAX_SOPA`.
- [ ] **Mirror:** upsert en `minijuegos_resultados(NM_MINIJUEGO="sopa")` (intentos+1, mejor puntos/estrellas, fecha) para que el panel docente lo vea.
- [ ] Verificar: jugar sopa → `python` ve filas en sopa_niveles + minijuegos_resultados.

### Task 6.3: Persistencia columnas (N2) + contenido real (N8) + ruta (N9)
**Files:** `nivel_columna.gd`
- [ ] Igual que 6.2 con `columnas_*` + mirror `NM_MINIJUEGO="columnas"`.
- [ ] Rellenar `BANCO_NIVELES_GLOBAL` con parejas reales por nivel/tema (decisión 2). Quitar placeholders repetidos.
- [ ] Corregir ruta selector (N9) — ya en Task 2.3.
- [ ] Verificar: jugar, parejas reales distinguibles; guarda.

### Task 6.4: Memoria completo (N6, N7)
**Files:** `nivelmemoria.gd`, `carta_memoria.gd`
- [ ] `carta_memoria.gd`: arreglar StyleBox (N6) — usar `StyleBoxTexture` con la textura, o usar `icon`/`TextureRect` en vez de stylebox PNG.
- [ ] `nivelmemoria.gd`: leer `numero_de_nivel` de `GlobalUsuario.nivel_seleccionado`; banco por nivel (datos reales); cronómetro + estrellas por tiempo (como sopa); `finalizar_juego_victoria` → pantalla resultados + guardar (`memoria_*` + mirror) + `Logros.evaluar_post_nivel`.
- [ ] Verificar: jugar memoria de inicio a fin; guarda; cartas se ven bien.

### Task 6.5: Estrellas preview correctas (N10)
**Files:** los 3 selectores `:161`
- [ ] Leer estrellas de la tabla del minijuego (`sopa_niveles`/`columnas_niveles`/`memoria_niveles`), no de `niveles`.

> Los otros 3 minijuegos (verdfal, comfrases, ordenfrases) tienen selector pero sin escena de juego implementada — fuera de alcance inicial; abrir sub-plan si se quieren.

---

## FASE 7 — Reporte docente PDF (Tarea 6) — DESPUÉS de Fase 6
> El panel docente (`menu_admin.gd`) YA funciona (gestión/auditoría/rendimiento/logros). Falta SOLO exportar. Hacer tras Fase 6 para que minijuegos no salgan en 0.
> **DECISIÓN PENDIENTE:** PDF vía (1) HTML→imprimir [recomendado, cero deps], (2) CSV, (3) librería PDF.

**Files (opción 1):** create `Scripts/reporte_docente.gd`; `Scenes/menu_admin.gd` (botones "Reporte general"/"Reporte por alumno")
- [ ] General: por alumno activo → puntaje, estrellas, niveles, % aciertos (reusar queries de `_refresh_gestion`/`_refresh_rendimiento_general`).
- [ ] Construir HTML; `user://reporte_general.html`; `OS.shell_open(globalize_path(...))`.
- [ ] Por alumno: stats del perfil + (opcional) consejos: detectar nivel con peor `NU_RESPC/NU_PREG` → sugerir tema (de `TEMAS_NIVELES`).
- [ ] Verificar: generar, abrir HTML, validar contenido.

---

## FASE 8 — Extras informativo (Tarea 12)
**Files:** `Scenes/Extras.tscn`, `Scenes/extras.gd`
- [ ] `extras.gd` tiene 8 labels/paneles pero solo 3 botones cableados (bienvenida/comojugar/sobreeljuego) y refs duplicadas a `PanelContainer2`. Cablear el resto o reducir a los reales; contenido en `ScrollContainer` si es largo.
- [ ] Verificar: navegación y textos correctos.

---

## Orden recomendado
0 (cimientos+DB) → 1 (UI alto impacto) → 2 (dinero/tienda) → 4 (logros) → 3 (perfil) → 5 (opciones-nivel) → 6 (minijuegos) → 7 (reporte, tras 6) → 8 (extras).

## No romper
- **Panel docente** (`menu_admin.gd`) funciona y lee `minijuegos_resultados` → por eso el mirror-upsert en Fase 6 es obligatorio.
- Mapa + Niveles.gd (juego principal) funciona.

## Decisiones abiertas
- Stretch `aspect=keep` (Task 1.2): validar barras negras.
- PDF (Fase 7): elegir opción 1/2/3.
- Minijuegos verdfal/comfrases/ordenfrases sin escena: ¿implementar o dejar fuera?
