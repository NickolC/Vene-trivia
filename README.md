<div align="center">

# 🇻🇪 Vene-Trivia 🇻🇪
**Explora, Aprende y Diviértete con la Historia de Venezuela**

![Godot Engine](https://img.shields.io/badge/Godot_4.6-%23FFFFFF.svg?style=for-the-badge&logo=godot-engine)
![GDScript](https://img.shields.io/badge/GDScript-13354C.svg?style=for-the-badge&logo=godot-engine&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-%2307405e.svg?style=for-the-badge&logo=sqlite&logoColor=white)

*Software educativo interactivo diseñado para fortalecer y evaluar conocimientos históricos en niños, construido con el poder de **Godot 4**.*

</div>

---

## 📑 Tabla de Contenido

<details>
<summary>Haz clic para desplegar</summary>

1. [🎯 Visión General](#-visión-general)
2. [👥 Para quién es este README](#-para-quién-es-este-readme)
3. [🛠️ Stack Tecnológico](#-stack-tecnológico)
4. [📁 Estructura del Proyecto](#-estructura-del-proyecto)
5. [🚀 Cómo ejecutar el proyecto](#-cómo-ejecutar-el-proyecto-por-primera-vez)
6. [🗺️ Flujo Funcional (Arquitectura)](#-cómo-está-organizado-el-juego-flujo-funcional)
7. [⚙️ Autoloads (Singletons)](#️-autoloads-singletons-globales)
8. [🗄️ Base de Datos SQLite](#️-base-de-datos-sqlite)
9. [🎮 Sistema de Preguntas y Nivel](#-sistema-de-preguntas-y-nivel)
10. [🎨 Configuraciones Visuales](#-configuraciones-y-ajustes-visuales)
11. [🔔 Alertas Globales](#-alertas-globales)
12. [⚠️ Riesgos Técnicos Detectados](#️-riesgos-técnicos-detectados)
13. [🤝 Guía para Nuevos Colaboradores](#-guía-rápida-para-nuevos-colaboradores)
14. [🗺️ Hoja de Ruta Recomendada](#️-hoja-de-ruta-recomendada)

</details>

---

## 🎯 Visión General

**Vene-Trivia** es un juego educativo enfocado en el aprendizaje histórico. El usuario principal (alumno) responde preguntas tipo *quiz* por niveles, gana puntaje, obtiene estrellas y desbloquea su progreso de forma visual y entretenida.

✨ **Características Principales:**
- 🔐 **Sistema de Autenticación**: Login diferenciado para **Alumnos** y **Docentes**.
- 🗺️ **Mapa Interactivo**: Selección de niveles con desbloqueo progresivo.
- ⏱️ **Mecánicas de Juego**: Niveles jugables con temporizador, barra de progreso y comodines de ayuda.
- 💾 **Persistencia de Datos**: Guardado de progreso en base de datos local (SQLite).
- ⚙️ **Accesibilidad Visual**: Sistema de configuración persistente (brillo, contraste, resolución y pantalla completa).

---

## 👥 Para quién es este README

Este documento está diseñado como una **guía definitiva de onboarding** para:
- 👶 Desarrolladores que **nunca han trabajado con Godot**.
- 🔍 Programadores nuevos que no conocen esta base de código.
- 🛠️ Colaboradores que desean corregir bugs o agregar *features* sin romper el flujo de la aplicación.

> 💡 *Si vienes de Unity, Unreal o puros frameworks web, esta guía es el puente ideal para entender cómo está estructurado el proyecto en Godot.*

---

## 🛠️ Stack Tecnológico

| Tecnología | Descripción |
| :--- | :--- |
| **Motor** | Godot 4.6 (GL Compatibility) |
| **Lenguaje** | GDScript |
| **Base de Datos** | SQLite (Plugin: ddons/godot-sqlite) |
| **Persistencia Local** | ConfigFile almacenado en user://configuracion_usuario.cfg |

---

## 📁 Estructura del Proyecto

Organización de los archivos más importantes del repositorio:

`	ext
Vene-trivia/
├── ⚙️ project.godot            # Configuración principal y Autoloads
├── 📜 README.md                # Documentación del proyecto
├── 🗄️ DB/
│   └── venetrivia.db           # Base de datos SQLite
├── 📝 Jsons/
│   └── Preguntas nivel 1.json  # Banco de preguntas
├── 🎬 Scenes/                  # Escenas principales del juego
│   ├── Login.tscn
│   ├── Alumno.tscn
│   ├── Admin.tscn
│   ├── menu-alumno.tscn
│   ├── Opciones.tscn
│   └── Niveles.gd              # Script con la lógica pesada del juego
├── 🎮 Nivel 1.tscn / Nivel1.tscn # Escenas del nivel 1 (⚠️ Ver riesgos)
├── 🗺️ Mapa.tscn / mapa.gd       # Lógica y UI del mapa de niveles
├── 🌐 Scripts Globales/
│   ├── ConfigGlobal.gd         # Manejo de archivo de config
│   ├── ConfiguracionGlobal.gd  # Aplicar ajustes en runtime
│   ├── Datosusuario.gd         # Sesión en memoria
│   ├── AlertasGlobal.gd        # Sistema de notificaciones
│   └── alertas.tscn            # UI de notificaciones
`

---

## 🚀 Cómo ejecutar el proyecto por primera vez

### 1️⃣ Requisitos
- Instalar **Godot 4.x** (Se recomienda 4.6 para máxima compatibilidad).

### 2️⃣ Abrir el proyecto
1. Abre Godot Engine.
2. Haz clic en **Importar**.
3. Selecciona la carpeta raíz del repositorio (Vene-trivia).
4. Haz clic en **Abrir y Editar**.

### 3️⃣ Ejecutar
- En project.godot la escena principal configurada es Scenes/Login.tscn.
- Presiona **F5** (o el botón ▶️ Play) para correr el proyecto completo.

### 4️⃣ Flujo de prueba recomendado
1. Inicia en la pantalla de **Login** y selecciona **Alumno**.
2. **Registra** un nuevo usuario (si no tienes uno).
3. Inicia sesión con tus credenciales.
4. Ve a **Jugar -> Mapa**.
5. Entra al **Nivel 1** y prueba las mecánicas.

---

## 🗺️ Cómo está organizado el juego (Flujo Funcional)

### Autenticación (Scenes/Login.tscn)
- Deriva hacia Admin.tscn (Docentes) o Alumno.tscn (Estudiantes).
- El registro e inicio de sesión del Alumno (lumno.gd) guarda la sesión en el Autoload GlobalUsuario y redirige a menu-alumno.tscn.

### Menú Principal del Alumno (Scenes/menu-alumno.tscn)
Da acceso a:
- 🎮 **Jugar**: Carga Mapa.tscn.
- 🧩 **Minijuegos**: Carga Scenes/Minijuegos.tscn.
- ⚙️ **Opciones**: Carga Scenes/Opciones.tscn.

### Mapa y Niveles (mapa.gd)
- Consulta la tabla 
iveles en SQLite para averiguar el 
ivel_disponible del usuario.
- Desbloquea los botones correspondientes en el mapa.
- Enruta dinámicamente a la escena es://Nivel X.tscn.

---

## ⚙️ Autoloads (Singletons Globales)

Patrón fundamental en Godot. Estos scripts siempre están activos:

1. 👤 **GlobalUsuario (Datosusuario.gd)**: Estado de sesión (id, 
ombre, 
ivel_maximo) y función limpiar_sesion().
2. 💾 **Configuracion (ConfigGlobal.gd)**: guardar_ajustes() y cargar_ajustes() en user://.
3. 🖌️ **GameConfig (ConfiguracionGlobal.gd)**: Aplica en tiempo real los valores de UI al WorldEnvironment.
4. 🔔 **Alertas (lertas.tscn + AlertasGlobal.gd)**: Instancia global para *toasts* flotantes.

---

## 🗄️ Base de Datos SQLite

Se usa el plugin ddons/godot-sqlite operando sobre DB/venetrivia.db.

**Tablas principales:**
- Alumnos: Credenciales e info personal.
- Admin: Credenciales docentes.
- 
iveles: Progreso (puntaje, aciertos, estrellas) mapeado por usuario.

> **Flujo BD:** Login -> Nivel (Guarda Resultados) -> Mapa (Lee para desbloquear).

---

## 🎮 Sistema de Preguntas y Nivel

El núcleo del juego vive en Scenes/Niveles.gd.

- 📄 **Carga de Datos**: Lee de Jsons/Preguntas nivel 1.json.
- 🧠 **Lógica**: Selecciona un pool de 15 preguntas dinámicas. Maneja tiempos, puntajes y UI.
- 🃏 **Comodines**: 
  - ✂️ 50/50
  - 📞 Llamada a un amigo
  - 📊 Votación del público

---

## ⚠️ Riesgos Técnicos Detectados

> 🔴 **ATENCIÓN DESARROLLADORES:** Las siguientes áreas representan deuda técnica o bugs conocidos que deben tratarse con prioridad.

1. 💉 **Inyección SQL**: Consultas con strings interpolados usando inputs directos de usuarios (Ej. Login). Requiere usar sentencias parametrizadas.
2. 🔢 **Métricas Inconsistentes**: En Niveles.gd, en lugar de sumar "respuestas correctas", suma "puntos brutos" al contador de aciertos en la DB.
3. 🔗 **Rutas Rotas**: El nivel 1 intenta enrutar a Scenes/Nivel2.tscn, el cual actualmente no existe.
4. 👯 **Escenas Duplicadas**: Existen Nivel 1.tscn y Nivel1.tscn. Unificarlas es fuertemente recomendado.
5. 🔓 **Seguridad de Claves**: Contraseñas almacenadas en texto plano.

---

## 🤝 Guía rápida para nuevos colaboradores

### 👶 Conceptos mínimos de Godot
- **Scene (.tscn)**: Una pantalla, menú o Prefab.
- **Node**: Elemento base de la jerarquía visual o lógica.
- **Script (.gd)**: Código que da vida a los nodos.
- **Signal**: Eventos que comunican nodos (ej. botón presionado).

### 🐛 Primer bug recomendado para ti
Inicia tu recorrido corrigiendo la lógica de puntos en Scenes/Niveles.gd.
*¿Por qué?*
- Es seguro.
- Te obliga a leer todo el flujo de partida.
- Impacta de forma muy positiva en la presentación de datos del alumno.

---

## 🗺️ Hoja de Ruta Recomendada

Para continuar escalando Vene-Trivia, se recomiendan los siguientes hitos:

- [ ] **Fase 1: Estabilización** (Corregir SQL Injection, Hash en DB, unificar escenas de Nivel 1).
- [ ] **Fase 2: Contenido** (Añadir Nivel2.tscn y conectar correctamente los botones de "Siguiente").
- [ ] **Fase 3: Expandibilidad** (Dar vida a las escenas Placeholder: Tienda, Minijuegos, Panel Docente).

---
<p align="center">
  <i>Construido con dedicación para la educación. 🇻🇪📚</i>
</p>
