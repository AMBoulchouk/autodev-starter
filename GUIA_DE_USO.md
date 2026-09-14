# Guía de Uso Rápido (GUIA_DE_USO.md)

Esta guía explica paso a paso cómo cualquier desarrollador puede tomar **AutoDev Starter** y aplicarlo en la práctica, tanto para **crear un proyecto nuevo desde cero** como para **gobernar el desarrollo de un proyecto existente**.

---

## 🚀 Escenario 1: Proyecto Nuevo desde Cero (Greenfield)

Usa este flujo si tienes una idea para una aplicación, API, microservicio o SaaS y quieres que un agente de IA lo construya de forma guiada, ordenada y con pruebas automáticas.

### Paso 1: Descargar el Starter en tu nueva carpeta
Abre tu terminal y ejecuta:

```bash
# 1. Clona el starter en una carpeta con el nombre de tu proyecto
git clone --depth=1 https://github.com/AMBoulchouk/autodev-starter.git mi-nuevo-proyecto

# 2. Entra al directorio
cd mi-nuevo-proyecto

# 3. Elimina el historial Git del starter para tener tu propio historial limpio
# En Linux / macOS / Git Bash:
rm -rf .git

# En Windows PowerShell:
Remove-Item -Recurse -Force .git
```

---

### Paso 2: Escribir la idea en `PRODUCT_BRIEF.md`
Abre la carpeta en tu editor preferido (VS Code, Cursor, Antigravity, etc.) y abre el archivo [`PRODUCT_BRIEF.md`](file:///c:/Users/ambou/Desktop/autodev-starter/autodev-starter/PRODUCT_BRIEF.md). Completa las secciones en lenguaje natural:

```markdown
# Product Brief

## 1. Visión del Producto
Una API REST para gestionar reservas de canchas de pádel con control de horarios y disponibilidad.

## 2. Usuarios Principales (Actores)
- Jugador: Consulta canchas libres y reserva turnos.
- Administrador: Gestiona canchas y tarifas.

## 3. Características Principales (MVP)
1. Listar canchas disponibles por fecha y franja horaria.
2. Crear una reserva validando que no se solape con otra existente.
3. Cancelar una reserva con anticipación.

## 4. Preferencias y Restricciones Técnicas (Opcional)
- Stack: FastAPI con Python y SQLite (o déjalo en blanco para que el agente elija el mejor stack).
```

---

### Paso 3: Ajustar el nombre del proyecto en `manifest.yaml`
Abre [`.autodev/manifest.yaml`](file:///c:/Users/ambou/Desktop/autodev-starter/autodev-starter/.autodev/manifest.yaml) y cambia `replace-me` por el nombre de tu aplicación:

```yaml
project:
  name: padel-booking-api
  type: application
```

---

### Paso 4: Dar el prompt de arranque al Agente de IA
Abre el chat de tu asistente de código con IA (Cursor Composer, Antigravity, Claude Code, etc.) y envíale esta instrucción:

> *"Lee `AGENTS.md` y `PRODUCT_BRIEF.md`. Ejecuta la fase de bootstrap de AutoDev, selecciona la arquitectura técnica, configura `.autodev/runtime.yaml` e implementa el Walking Skeleton (`F001`) hasta verificar todos los contratos."*

---

### Paso 5: ¿Qué hace el Agente automáticamente?
El agente seguirá el protocolo estricto definido en `AGENTS.md`:
1. **Inicializa el Engine:** Ejecuta `.autodev/commands/bootstrap.ps1` (o `./.autodev/commands/bootstrap`), creando tu nuevo repositorio Git y la máquina de estados.
2. **Registra Decisiones de Arquitectura:** Crea los registros en `.autodev/state/decisions.md` explicando el stack y las librerías elegidas.
3. **Configura el Project Driver:** Define los comandos reales en `.autodev/runtime.yaml`:
   ```yaml
   commands:
     validate: "ruff check ."
     test: "pytest"
     build: ""
     run: "uvicorn main:app --reload"
     verify: "pytest tests/test_health.py"
   ```
4. **Crea el Walking Skeleton (`F001`):** Genera la estructura inicial del proyecto, el punto de entrada y un health check automatizado.
5. **Ejecuta el Ciclo de Verificación:** Lanza `.autodev/commands/auto-cycle.ps1`. El engine compila, prueba, verifica criterios de aceptación, audita políticas de seguridad de Git, genera la evidencia en `.autodev/evidence/F001.json` y crea tu primer commit atómico.

---

### Paso 6: Desarrollar las siguientes features
Para cada funcionalidad del MVP:
1. El agente (o tú) crea la especificación en `.autodev/features/F002-listar-canchas.md` usando [`FEATURE_TEMPLATE.md`](file:///c:/Users/ambou/Desktop/autodev-starter/autodev-starter/.autodev/features/FEATURE_TEMPLATE.md).
2. Pídele al agente:
   > *"Sincroniza el backlog con `.autodev/commands/plan` y ejecuta el ciclo de desarrollo de la feature F002 con `.autodev/commands/auto-cycle`."*

El engine avanzará feature por feature hasta completar el backlog.

---

## 🛠️ Escenario 2: Proyecto Existente (Brownfield)

Usa este flujo si ya tienes un proyecto con código y tests (en Node.js, Python, Go, Rust, .NET, Java, etc.) y quieres incorporar la gobernanza y automatización de AutoDev.

### Paso 1: Copiar los archivos a la raíz de tu proyecto
Copia únicamente estos 4 elementos a tu repositorio:
- Carpeta `.autodev/`
- Archivo `AGENTS.md`
- Archivo `PRODUCT_BRIEF.md`
- Archivo `CONFIG.md`

---

### Paso 2: Conectar tus herramientas en `.autodev/runtime.yaml`
Abre `.autodev/runtime.yaml` y escribe los comandos que tu proyecto **ya utiliza habitualmente**:

```yaml
version: 1

commands:
  validate: "npm run lint"        # Comando de linter / tipado
  test: "npm test"                # Suite de pruebas existente
  build: "npm run build"          # Paso de compilación o build
  run: "npm run dev"              # Iniciar la app localmente
  verify: "npm run test:e2e"      # Pruebas de aceptación / integración
  preview: ""

health:
  command: "curl -f http://localhost:3000/api/health"
  expected_exit_code: 0
```

*(Si prefieres no hacerlo a mano, puedes pedirle al agente: "Inspecciona este proyecto y configura `.autodev/runtime.yaml` con nuestros comandos reales").*

---

### Paso 3: Verificar el estado del proyecto
Ejecuta el diagnóstico en tu terminal:

```powershell
# En Windows PowerShell:
.\.autodev\commands\inspect.ps1

# En Linux / macOS:
./.autodev/commands/inspect
```

Confirmará que detecta tu Git, tus archivos de gobernanza y tus contratos de `runtime.yaml`.

---

### Paso 4: Solicitar nuevas tareas o features al Agente
Crea una especificación en `.autodev/features/F001-nueva-funcionalidad.md` y dale la orden al agente:

> *"Implementa la feature F001 respetando la arquitectura existente y siguiendo las reglas de `AGENTS.md`. Valida y commitea usando `.autodev/commands/auto-cycle`."*

El agente escribirá el código mínimo necesario, agregará tests y `auto-cycle` garantizará que **ningún test previo se rompa**, que no se filtren secretos (`.env`) y creará el commit atómico con evidencia auditable en `.autodev/evidence/`.

---

## 📋 Resumen de Comandos Principales

Todos los comandos cuentan con versiones idénticas para **PowerShell (`.ps1`)** y **POSIX Bash (`sh`)**:

| Comando | Para qué sirve | Cuándo se usa |
| :--- | :--- | :--- |
| `inspect` | Diagnostica el estado del proyecto, git, gobernanza y driver. | Al inicio o para revisar el entorno. |
| `bootstrap` | Inicializa Git, directorios y el motor de estado `progress.json`. | Al arrancar un proyecto nuevo. |
| `plan` | Indexa especificaciones de features y resuelve dependencias. | Al crear o actualizar specs en `.autodev/features/`. |
| `validate` | Comprueba la gobernanza y corre el linter configurado en `runtime.yaml`. | Chequeo estático de calidad. |
| `test` | Ejecuta las pruebas automatizadas delegando en `runtime.yaml`. | Durante el desarrollo. |
| `build` | Compila o empaqueta el artefacto según `runtime.yaml`. | Verificación de construcción. |
| `verify` | Ejecuta la verificación de criterios de aceptación de la feature. | Previo a dar por lista una feature. |
| `run` | Inicia la aplicación localmente según `runtime.yaml`. | Para probar la app en vivo. |
| `auto-cycle` | **El orquestador completo:** corre validate, test, build, verify, audita políticas de Git, genera evidencia y hace el commit. | Al terminar de codificar una feature. |

---

## 💡 Ventajas Clave para el Desarrollador

1. **Cero fricción tecnológica:** AutoDev no impone ningún lenguaje ni framework; se adapta a tu stack a través de `runtime.yaml`.
2. **Seguridad y Control:** El agente tiene prohibido commitear si fallan las pruebas, si se tocan archivos de políticas o si se detectan secretos (`.env*`, `*.key`).
3. **Trazabilidad:** Cada feature completada deja un registro JSON inmutable en `.autodev/evidence/` con el hash del commit, los archivos modificados y el resultado de las pruebas.
