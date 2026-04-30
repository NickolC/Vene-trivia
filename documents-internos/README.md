# Documentacion Interna - Vene-trivia

Esta carpeta concentra la documentacion tecnica interna de los modulos nuevos y ajustes visuales del proyecto.

## Modulos documentados

- `superadmin-modulo.md`  
  Flujo completo del Super Admin, autenticacion, creacion de docentes, monitoreo de actividad y scripts SQL recomendados.
- `create_superadmin.sql`  
  Script SQL listo para crear cuentas de Super Admin de forma manual.
- `run_create_superadmin.py`  
  Script ejecutable para aplicar `create_superadmin.sql` sobre la base local.

## Mapa rapido de archivos

- `Scenes/Login.tscn` - Pantalla principal de roles (Docente, Alumno, Super Admin)
- `Scenes/login.gd` - Navegacion desde login principal
- `Scenes/SuperAdminLogin.tscn` - Login exclusivo de Super Admin (sin registro)
- `Scenes/super_admin_login.gd` - Validacion de credenciales Super Admin
- `Scenes/SuperAdmin.tscn` - Panel operativo de Super Admin
- `Scenes/super_admin.gd` - Creacion de docentes + analytics de actividad
- `Scripts/sqlite_helper.gd` - Utilidades SQLite comunes (escape, tablas de auditoria, etc.)

## Convencion

- El alta de **Super Admin** se hace solo por SQL manual (desarrollador).
- El alta de **Docente** se hace desde el panel de Super Admin.
- El alta de **Alumno** se mantiene desde la vista de Alumno.
