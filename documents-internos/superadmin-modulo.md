# Modulo Super Admin

## Objetivo

Habilitar un rol de **Super Admin** con acceso restringido para:

1. Crear usuarios Docente
2. Visualizar actividad de alumnos y docentes
3. Consultar resumen operativo del sistema

---

## Arquitectura funcional

### 1) Entrada de usuario

- `Scenes/Login.tscn`  
  Pantalla principal de seleccion de perfil:
  - Docente
  - Alumno
  - Super Admin

- `Scenes/login.gd`  
  Navega a cada modulo segun boton.

### 2) Autenticacion Super Admin

- `Scenes/SuperAdminLogin.tscn`  
  Login visual estilo Alumno (sin panel de registro).

- `Scenes/super_admin_login.gd`  
  - Abre DB
  - Verifica tabla `SuperAdmin`
  - Valida credenciales
  - Registra actividad de inicio de sesion
  - Redirige a `Scenes/SuperAdmin.tscn`

### 3) Panel Super Admin

- `Scenes/SuperAdmin.tscn`  
  Vista principal con dos columnas:
  - Creacion de Docentes
  - Monitoreo y actividad del sistema

- `Scenes/super_admin.gd`  
  - Crea usuario Docente en tabla `Admin`
  - Lista docentes existentes
  - Muestra resumen de sistema (docentes, alumnos, partidas)
  - Muestra top de alumnos por puntaje
  - Muestra actividad reciente (auditoria)

### 4) Capa de datos utilitaria

- `Scripts/sqlite_helper.gd`  
  Funciones compartidas:
  - `open_db_connection()`
  - `close_db_connection()`
  - `escape()`
  - `ensure_activity_table()`
  - `log_activity()`
  - `ensure_superadmin_table()`

---

## Modelo de tablas

### Tabla `SuperAdmin` (acceso restringido)

```sql
CREATE TABLE IF NOT EXISTS SuperAdmin (
  NU_USU INTEGER PRIMARY KEY AUTOINCREMENT,
  NM_SUPERADMIN TEXT NOT NULL UNIQUE,
  CO_PSW TEXT NOT NULL
);
```

### Tabla `Admin` (Docentes)

Se reutiliza la tabla existente:

```sql
CREATE TABLE IF NOT EXISTS Admin (
  NU_USU INTEGER PRIMARY KEY AUTOINCREMENT,
  NM_ADMIN TEXT NOT NULL UNIQUE,
  CO_PSW TEXT NOT NULL
);
```

### Tabla `actividad` (auditoria)

```sql
CREATE TABLE IF NOT EXISTS actividad (
  NU_ACT INTEGER PRIMARY KEY AUTOINCREMENT,
  TX_TIPO_USUARIO TEXT NOT NULL,
  TX_USUARIO TEXT NOT NULL,
  TX_ACCION TEXT NOT NULL,
  TX_FECHA TEXT NOT NULL
);
```

---

## Alta manual de Super Admin (solo desarrollador)

> Este flujo **no existe en UI**, por seguridad operativa.

Script listo en:

- `documents-internos/create_superadmin.sql`
- `documents-internos/run_create_superadmin.py`

Superusuario inicial por defecto (idempotente):

- `admin / admin`

Insercion por defecto en el SQL:

```sql
INSERT OR IGNORE INTO SuperAdmin (NM_SUPERADMIN, CO_PSW)
VALUES ('admin', 'admin');
```

Opcional para otro super admin:

```sql
INSERT INTO SuperAdmin (NM_SUPERADMIN, CO_PSW)
VALUES ('ops_admin', 'cambia_esta_clave_tambien');
```

Ejecucion automatica del SQL:

```bash
python "documents-internos/run_create_superadmin.py"
```

---

## Flujo de actividad registrada

Se registran eventos como:

- `inicio_sesion` (alumno, docente, superadmin)
- `registro` (alumno)
- `creo_docente:<usuario>` (superadmin)
- `acceso_panel` (superadmin)

Esto alimenta el bloque **Actividad reciente** del panel.

---

## Ajustes visuales aplicados

### Login principal

- Se devolvio a una composicion mas cercana al arte original.
- Se mantuvo encabezado central para claridad de rol.
- Se conservo un boton dedicado de `SUPER ADMIN` sin saturar la vista.

### Super Admin

- Tipografias mas grandes y legibles.
- Mayor contraste en labels, inputs y paneles.
- Colores de fondo y borde alineados al estilo visual del juego.
- Jerarquia visual clara: titulo -> acciones -> datos.

---

## Notas de mantenimiento

1. Si migras autenticacion a hash, ajusta comparacion en `Scenes/super_admin_login.gd`.
2. Si agregas mas modulos de actividad, reutiliza `SQLiteHelper.log_activity()`.
3. Si cambias nombres de nodos de `SuperAdmin.tscn`, actualiza rutas `@onready` en `Scenes/super_admin.gd`.
