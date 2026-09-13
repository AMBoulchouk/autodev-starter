# AutoDev Engine

Herramienta universal de especificación, gobernanza y desarrollo autónomo guiado por contratos para agentes de IA. Diseñada para funcionar tanto en **repositorios existentes** como en **proyectos en blanco (greenfield)**.

---

## 🚀 Cómo usarlo en un Proyecto Nuevo (Desde Cero / Greenfield)

1. **Copia `.autodev/`, `AGENTS.md` y `PRODUCT_BRIEF.md`** a una carpeta vacía.
2. **Escribe tu idea** en `PRODUCT_BRIEF.md` (visión general, actores, MVP y preferencias técnicas opcionales).
3. **Pídele al agente de IA:**
   > *"Lee AGENTS.md y PRODUCT_BRIEF.md, inicializa el proyecto y construye el MVP siguiendo el ciclo de AutoDev."*

El agente seguirá automáticamente las 3 fases:
- **Fase 0 (Bootstrap):** Inicializa el runtime (Next.js, FastAPI, Go, etc.), git y configura el entorno.
- **Fase 1 (Especificación):** Descompone la idea en `.autodev/domain/` y crea el backlog en `.autodev/features/`.
- **Fase 2 (Ejecución):** Implementa cada feature secuencialmente, escribe tests, valida los contratos y genera commits atómicos.

---

## 🛠️ Cómo usarlo en un Proyecto Existente (Brownfield)

1. Copia `.autodev/`, `AGENTS.md` y `PRODUCT_BRIEF.md` a la raíz del repositorio.
2. Ejecuta `.autodev/commands/inspect` (o `.ps1` en Windows) para verificar la detección automática de tu stack.
3. Si utilizas scripts personalizados, ajusta `.autodev/commands/test` o `build` según tus necesidades.
4. Define nuevas funcionalidades en `.autodev/features/nueva-feature.md` y solicita al agente su implementación.

---

## 📋 Contratos de Comandos Disponibles

Cada comando cuenta con soporte multiplataforma (Bash y PowerShell `.ps1`):

| Contrato | Propósito |
| :--- | :--- |
| `bootstrap` | Inicializa el repositorio git y el motor de estado `progress.json`. |
| `plan` | Sincroniza `PRODUCT_BRIEF.md` con las especificaciones de `.autodev/features/`. |
| `inspect` | Diagnostica el stack técnico, runtime y estado sin bloquear el agente. |
| `validate` | Valida integridad estructural de gobernanza y ejecuta linters si existen. |
| `test` | Ejecuta la suite de pruebas (soporte nativo para npm, pytest, go test, cargo test). |
| `build` | Compila o verifica empaquetado si el stack lo requiere. |
| `run` | Inicia la aplicación localmente mediante los entrypoints detectados. |
| `auto-cycle` | Valida la feature actual, ejecuta pruebas, commitea y avanza el estado. |

---

## 📊 Motor de Estado (`.autodev/state/progress.json`)

El motor de estado mantiene la trazabilidad del desarrollo:
- `phase`: `"bootstrap"` | `"specification"` | `"development"` | `"complete"`
- `features_completed`: Lista de features verificadas con tests.
- `current_feature`: Feature bajo desarrollo activo.
- `features_pending`: Cola de trabajo pendiente.

Esto garantiza que el desarrollo sea **reanudable, medible y tolerante a interrupciones**.
