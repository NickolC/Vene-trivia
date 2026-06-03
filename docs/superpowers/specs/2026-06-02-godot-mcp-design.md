# Godot MCP para Vene-trivia — Diseño

Fecha: 2026-06-02

## Objetivo

Cualquier IA (Claude Code u otra) que abra este repo detecta automáticamente un
servidor MCP de Godot y puede operar el proyecto headless: correr el juego,
leer errores, manipular escenas y archivos. Cada desarrollador apunta a su
propia instalación de Godot vía un archivo `.env` local; el resto de la
configuración es compartida y versionada.

## Base

Se adapta el proyecto open-source `godot-mcp` (Coding-Solo, Node/TypeScript).
Ya implementa lanzamiento headless, captura de salida y operaciones de escena
vía un script GDScript ejecutado con `godot --headless`. Se vendoriza dentro
del repo en lugar de construir desde cero.

## Cobertura de funcionalidad

- **Headless / ejecución:** `run_project`, `get_debug_output`, `stop_project`,
  `launch_editor`, `get_godot_version`.
- **Archivos / proyecto:** `get_project_info`, `list_projects`, `get_uid`,
  `update_project_uids`.
- **Control de escena:** `create_scene`, `add_node`, `load_sprite`,
  `save_scene`, `export_mesh_library`.

Nota: el control de escena manipula archivos `.tscn` vía script headless; no
controla el editor *vivo* en tiempo real. Godot no necesita estar abierto. Un
addon GDScript para control en vivo queda como fase futura opcional.

## Arquitectura

```
IA / Claude Code ──MCP/stdio──> godot-mcp (proceso Node)
                                    │ spawn
                                    ├─> godot.exe --headless --script godot_operations.gd
                                    └─> godot.exe --headless --path <proyecto>
```

El proceso Node lee `GODOT_PATH` desde el entorno (cargado por dotenv) para
saber qué binario de Godot ejecutar.

## Componentes y archivos

1. **`godot-mcp/`** — código vendoreado del MCP, commiteado.
   `node_modules/` y `build/` se ignoran. Cada dev corre
   `pnpm install && pnpm build` una vez.
2. **`.mcp.json`** (raíz, commiteado) — registra el server. Arranca con:
   `node -r dotenv/config godot-mcp/build/index.js`.
   La ruta a `index.js` es **relativa al cwd**, que Claude Code fija a la raíz
   del repo. Por eso el mismo `.mcp.json` funciona en cualquier máquina sin
   configuración por dev.
3. **`.env`** (raíz, gitignored) — variable local de cada dev:
   `GODOT_PATH=<ruta a su Godot>`. dotenv la carga al arrancar el server.
4. **`.env.example`** (raíz, commiteado) — plantilla: `GODOT_PATH=`.
5. **`.gitignore`** — añadir `.env`, `godot-mcp/node_modules/`,
   `godot-mcp/build/`.

### Por qué la ruta del server es relativa y no una variable

`.mcp.json` expande `${VAR}` desde el entorno del SO *antes* de que Node
arranque y dotenv cargue `.env`. Por eso una variable de ruta puesta solo en
`.env` no puede localizar `index.js`. La ruta relativa al cwd evita ese
problema de orden de carga y no requiere configuración por dev. Solo
`GODOT_PATH` —que se lee en runtime— vive en `.env`.

## Manejo de errores

El server captura stderr de Godot y lo devuelve como texto del resultado del
tool. Procesos colgados se cortan por timeout. Si `GODOT_PATH` falta o apunta a
un binario inválido, el server reporta error claro al primer tool que lo use.

## Pruebas / validación

Tras `pnpm install && pnpm build`:

1. Verificar que Claude Code detecta el server desde `.mcp.json`.
2. Confirmar cwd = raíz del repo (validar que la ruta relativa resuelve). Si no
   resolviera, plan B: exigir variable de SO `GODOT_MCP_DIR` y usar
   `${GODOT_MCP_DIR}` en `.mcp.json`.
3. `get_godot_version` → debe devolver `4.6.2.stable`.
4. `get_project_info` contra Vene-trivia → debe leer nombre y escena principal.
5. `run_project` breve + `get_debug_output` → confirma captura de salida.

## Ruta de Godot del autor (referencia)

`C:\Users\juanr\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe`
(verificada: `4.6.2.stable.official`)

## Fuera de alcance (YAGNI)

- Addon GDScript para control del editor en vivo.
- Exportación de builds de release.
- Soporte multi-proyecto (este repo tiene un solo `project.godot`).
