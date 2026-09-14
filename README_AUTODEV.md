# AutoDev Engine

**AutoDev Engine** es una infraestructura universal de gobernanza, ciclo de vida y orquestación de contratos para agentes de desarrollo autónomo. 

Su diseño desacopla por completo la capa de gobernanza de la tecnología subyacente. AutoDev **no conoce lenguajes, frameworks ni gestores de paquetes**; opera exclusivamente como un motor determinista de estados y políticas, mientras el Agente de IA asume el razonamiento técnico, el diseño de la arquitectura y la implementación.

```
USER
  │ (define visión del producto)
  ▼
PRODUCT_BRIEF.md
  │
  ▼
AGENT (Razonamiento: dominio, arquitectura, selección técnica, código, tests, ADRs)
  │
  ▼
AUTODEV CORE (Gobernanza: ciclo de vida, máquina de estados, políticas git, evidencia)
  │
  ▼
PROJECT DRIVER (.autodev/runtime.yaml: contratos ejecutables)
  │
  ▼
REAL PROJECT (Cualquier tecnología: Node, Python, Rust, Go, C#, Elixir, etc.)
```

---

## 1. Qué ES y Qué NO ES AutoDev

| Qué ES AutoDev | Qué NO ES AutoDev |
| :--- | :--- |
| **Un motor de gobernanza y ciclo de vida.** | Un generador de plantillas atado a un framework. |
| **Agnóstico de tecnología:** soporta cualquier stack. | Un script que huele `package.json` o `Cargo.toml`. |
| **Determinista y auditable:** verifica contratos y genera evidencia. | Un reemplazo de la inteligencia y criterio del agente. |
| **Un ejecutor de contratos:** delega en `runtime.yaml`. | Un linter o test runner propio. |

---

## 2. Separación de Responsabilidades

### ENGINE RESPONSIBILITIES (AutoDev Core)
* **Lifecycle:** Control de fases (`bootstrap` $\to$ `specification` $\to$ `development` $\to$ `complete`).
* **State Machine:** Transiciones estrictas en `.autodev/state/progress.json`.
* **Contract Delegation:** Ejecución neutral de comandos a través de `.autodev/runtime.yaml`.
* **Policy Enforcement:** Prevención de fugas de credenciales y cambios destructivos.
* **Evidence Collection:** Registro inmutable en `.autodev/evidence/<FEATURE_ID>.json`.
* **Git Safety & Atomic Commits:** Validación previa de diffs y creación de commits semánticos.

### AGENT RESPONSIBILITIES (Agente de IA)
* Interpretar `PRODUCT_BRIEF.md` y modelar entidades en `.autodev/domain/`.
* Seleccionar la arquitectura y tecnologías más adecuadas.
* Generar y mantener `.autodev/runtime.yaml` (Project Driver).
* Descomponer el trabajo en especificaciones atómicas (`.autodev/features/`).
* Implementar el **Walking Skeleton (`F001`)** en proyectos nuevos.
* Escribir código de producción y suites de pruebas automatizadas.
* Investigar y corregir fallos cuando un contrato no pasa.
* Documentar decisiones de arquitectura en `.autodev/state/decisions.md`.

---

## 3. Organización Conceptual: WHAT / CONSTRAINTS / HOW / WHY

```
WHAT (Requerimientos de Negocio)
├── PRODUCT_BRIEF.md              # Visión de alto nivel
├── .autodev/domain/              # Modelos de entidades, invariantes y reglas
└── .autodev/features/            # Especificaciones funcionales y criterios Given-When-Then

CONSTRAINTS (Restricciones y Políticas)
├── .autodev/manifest.yaml        # Manifiesto de autonomía y políticas de seguridad Git
├── .autodev/architecture.md      # Principios arquitectónicos
└── .autodev/policies/            # Políticas de testing, despliegue y seguridad

HOW TO OPERATE (Driver de Ejecución)
├── .autodev/runtime.yaml         # Comandos reales configurados por el agente
└── .autodev/commands/            # Adaptadores estándar (PowerShell y POSIX)

WHY (Auditoría y Trazabilidad)
├── .autodev/state/decisions.md   # Registro de decisiones arquitectónicas (ADRs)
├── .autodev/state/progress.json  # Máquina de estados del proyecto
└── .autodev/evidence/            # Registros auditables por feature completada
```

---

## 4. Project Driver (`.autodev/runtime.yaml`)

El archivo `.autodev/runtime.yaml` es la interfaz entre AutoDev Core y el proyecto real. Durante la fase de bootstrap, el Agente configura este archivo con los comandos reales de su stack:

```yaml
version: 1

environment:
  setup: "poetry install"        # o "npm install", "cargo build", etc.
  install: "poetry install"

commands:
  validate: "poetry run ruff check ."
  test: "poetry run pytest"
  build: "poetry build"
  run: "poetry run uvicorn app.main:app"
  verify: "poetry run python -m verify_criteria {FEATURE}"
  preview: ""

health:
  command: "curl -f http://localhost:8000/health"
  expected_exit_code: 0
```

Si el proyecto cambia de herramientas o lenguaje, **AutoDev Core permanece idéntico**: solo se modifica `runtime.yaml`.

---

## 5. Modos de Entrada

### Modo Greenfield (Proyecto desde Cero)
1. Colocar `.autodev/`, `AGENTS.md` y `PRODUCT_BRIEF.md` en una carpeta vacía.
2. Definir la visión en `PRODUCT_BRIEF.md`.
3. Ejecutar `.autodev/commands/bootstrap` (inicializa Git, directorios y `progress.json`).
4. El Agente analiza el producto, elige tecnologías y documenta las decisiones en `decisions.md`.
5. El Agente configura `runtime.yaml` y genera el scaffolding del proyecto.
6. **Walking Skeleton obligatorio (`F001`):** El Agente implementa una vertical mínima funcional que demuestre que el runtime, el health check, el build y los tests pasan.
7. El Agente ejecuta `.autodev/commands/plan` para estructurar las features pendientes y avanza feature por feature con `auto-cycle`.

### Modo Brownfield (Proyecto Existente)
1. Copiar `.autodev/`, `AGENTS.md` y `PRODUCT_BRIEF.md` a la raíz del repositorio.
2. Ejecutar `.autodev/commands/inspect` para verificar gobernanza y estado.
3. El Agente analiza el código existente y genera `runtime.yaml` mapeando los comandos reales.
4. El Agente formaliza la arquitectura en `architecture.md` y agrega especificaciones en `.autodev/features/`.
5. El proyecto queda normalizado bajo el ciclo estándar de AutoDev.

---

## 6. Máquina de Estados (`progress.json` Schema v2)

El ciclo de desarrollo transiciona por estados formales:
```
pending ──> ready ──> implementing ──> validating ──> completed
                         ▲                 │
                         └── failed <──────┘
```

* **`pending`:** La feature espera que sus dependencias (`depends_on`) sean completadas.
* **`ready`:** Todas sus dependencias están satisfechas; es la siguiente en la cola.
* **`implementing`:** Asignada como `current_feature`; el agente está escribiendo código/tests.
* **`validating`:** El engine está ejecutando la secuencia de contratos (`validate` $\to$ `test` $\to$ `build` $\to$ `verify`).
* **`failed`:** Al menos un contrato falló. Incrementa `attempts` y regresa a `implementing` para corrección.
* **`blocked`:** Violación de política de seguridad crítica (ej. detección de secretos `.env`).
* **`approval_required`:** Modificación de archivos de gobernanza protegidos o exceso del límite de archivos modificados.
* **`completed`:** Todos los contratos pasaron, políticas de Git verificadas y evidencia generada.

---

## 7. Verificación y Evidencia Auditable

Para dar una feature por completada, AutoDev no se limita a `test` o `build`: ejecuta el contrato **`verify`** que comprueba los criterios de aceptación específicos de la especificación.

Al completarse, se genera un archivo inmutable en `.autodev/evidence/<FEATURE_ID>.json`:
```json
{
  "feature": "F001",
  "spec": ".autodev/features/F001-walking-skeleton.md",
  "timestamp": "2026-09-13T21:00:00Z",
  "verification": {
    "validate": "passed",
    "test": "passed",
    "build": "passed",
    "verify": "passed"
  },
  "commit": "a1b2c3d",
  "changed_files": ["src/app.py", "tests/test_health.py"],
  "attempts": 1,
  "dependencies": [],
  "acceptance_criteria_verified": true
}
```

---

## 8. Políticas de Seguridad de Git

Antes de cada commit, el motor inspecciona el diff del repositorio:
* **Archivos prohibidos (`forbidden`):** Si se detectan `.env*`, `*.pem`, `*.key`, `secrets.*`, el ciclo se detiene inmediatamente y la feature pasa a estado `blocked`.
* **Archivos protegidos (`protected`):** Si se modifican archivos de política (`.autodev/policies/**`, `manifest.yaml`), la feature requiere aprobación explícita (`approval_required`).
* **Umbral de cambios (`max_changed_files`):** Si una feature modifica más de 50 archivos simultáneamente, se suspende para revisión humana.
* **Commits atómicos:** Solo los archivos permitidos se añaden al commit con mensaje estructurado `feat(<id>): verified acceptance criteria`.

---

## 9. Paridad Multiplataforma

Todos los adaptadores cuentan con implementaciones equivalentes en **PowerShell (`.ps1`)** y **POSIX Bash (`sh`)** bajo `.autodev/commands/`:
* `inspect` / `inspect.ps1`
* `bootstrap` / `bootstrap.ps1`
* `plan` / `plan.ps1`
* `validate` / `validate.ps1`
* `test` / `test.ps1`
* `build` / `build.ps1`
* `verify` / `verify.ps1`
* `run` / `run.ps1`
* `deploy-preview` / `deploy-preview.ps1`
* `auto-cycle` / `auto-cycle.ps1`
