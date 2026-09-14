# Guía de Configuración de Proyecto (CONFIG.md)

Este repositorio es una plantilla universal completamente limpia y agnóstica de cualquier tecnología. 
Sigue esta guía para configurar AutoDev en **cualquier proyecto** (tanto proyectos nuevos que empiezan desde cero como proyectos existentes).

---

## 🗺️ Mapa de Archivos a Configurar

| Paso | Archivo a Editar | Qué Información Completar | Obligatorio |
| :---: | :--- | :--- | :---: |
| **1** | [`PRODUCT_BRIEF.md`](file:///c:/Users/ambou/Desktop/autodev-starter/autodev-starter/PRODUCT_BRIEF.md) | Visión del producto, usuarios (actores), funcionalidades MVP y preferencias técnicas. | **Sí** |
| **2** | [`.autodev/manifest.yaml`](file:///c:/Users/ambou/Desktop/autodev-starter/autodev-starter/.autodev/manifest.yaml) | Nombre del proyecto, capacidades requeridas y políticas de autonomía y Git. | **Sí** |
| **3** | [`.autodev/architecture.md`](file:///c:/Users/ambou/Desktop/autodev-starter/autodev-starter/.autodev/architecture.md) | Principios arquitectónicos, patrones y restricciones de diseño de ingeniería. | Opcional (valores por defecto) |
| **4** | [`.autodev/domain/`](file:///c:/Users/ambou/Desktop/autodev-starter/autodev-starter/.autodev/domain) | Entidades de negocio, invariantes y reglas del dominio. | **Sí** (o dejar al Agente) |
| **5** | [`.autodev/runtime.yaml`](file:///c:/Users/ambou/Desktop/autodev-starter/autodev-starter/.autodev/runtime.yaml) | Comandos reales del proyecto (Project Driver): test, build, validate, run, verify. | **Sí** (o generado por Agente) |
| **6** | [`.autodev/features/`](file:///c:/Users/ambou/Desktop/autodev-starter/autodev-starter/.autodev/features) | Especificaciones atómicas de las features con criterios Given/When/Then. | **Sí** |
| **7** | [`.autodev/state/decisions.md`](file:///c:/Users/ambou/Desktop/autodev-starter/autodev-starter/.autodev/state/decisions.md) | Ledger de Architectural Decision Records (ADRs). | Durante el ciclo |

---

## 📝 Detalle de Cada Archivo

### 1. `PRODUCT_BRIEF.md` (La Visión del Producto)
* **Ubicación:** Raíz del proyecto.
* **Qué debes escribir:**
  1. **Visión:** ¿Qué es la aplicación y qué problema resuelve?
  2. **Actores:** ¿Quiénes interactúan con el sistema? (ej. Administrador, Cliente, API Externa).
  3. **Funcionalidades MVP:** Lista numerada de los casos de uso esenciales para la primera versión.
  4. **Restricciones Técnicas (Opcional):** Si prefieres un lenguaje, framework o base de datos en particular, indícalo aquí. Si lo dejas en blanco, el Agente elegirá el stack más óptimo.

---

### 2. `.autodev/manifest.yaml` (Gobernanza y Políticas)
* **Ubicación:** `.autodev/manifest.yaml`
* **Campos clave a completar:**
  * `project.name`: Cambia `replace-me` por el nombre real de tu proyecto.
  * `project.type`: Define el tipo de software (`application`, `service`, `library`, `cli`).
  * `capabilities`: Declara qué recursos utiliza tu sistema cambiando `available: true/false`:
    * `database`: Si el proyecto persiste datos.
    * `authentication`: Si incluye gestión de identidad / login.
    * `browser_ui`: Si incluye frontend web interactivo.
    * `external_http`: Si consume APIs de terceros.
  * `git.forbidden`: Lista patrones de archivos que nunca deben commitearse (ej. `.env*`, `*.pem`, `*.key`).
  * `git.protected`: Rutas cuya modificación requiere aprobación explícita (ej. `.autodev/policies/**`).

---

### 3. `.autodev/architecture.md` (Principios de Arquitectura)
* **Ubicación:** `.autodev/architecture.md`
* **Qué debes escribir:**
  * Principios de diseño (ej. Clean Architecture, Modular Monolith, Separación Dominio/Infraestructura).
  * Estándares de validación en los límites del sistema.
  * Estrategia de migraciones de base de datos.

---

### 4. `.autodev/domain/` (Modelado de Negocio)
Completa estos 3 archivos para que el agente implemente código coherente con tu negocio:
* **`entities.md`:** Define los conceptos centrales de tu aplicación (ej. `Usuario`, `Producto`, `Factura`) y sus atributos clave.
* **`invariants.md`:** Condiciones que **siempre** deben cumplirse en el sistema (ej. *"El saldo nunca puede ser negativo"*, *"Un usuario inactivo no puede iniciar sesión"*).
* **`rules.md`:** Lógica de validación y cálculo del negocio (ej. límites, permisos, transiciones de estado permitidas).

---

### 5. `.autodev/runtime.yaml` (Project Driver)
* **Ubicación:** `.autodev/runtime.yaml`
* **Propósito:** Conecta AutoDev con las herramientas reales de tu proyecto.
* **Cómo completarlo:**
  * **En proyectos desde cero (Greenfield):** El Agente lo configurará automáticamente tras crear el scaffolding inicial.
  * **En proyectos existentes (Brownfield):** Escribe los comandos de tu proyecto:
  ```yaml
  version: 1
  
  environment:
    setup: "npm install"        # Comando de instalación
  
  commands:
    validate: "npm run lint"    # Linter o typecheck
    test: "npm test"            # Suite de pruebas automatizadas
    build: "npm run build"      # Compilación o empaquetado
    run: "npm run dev"          # Iniciar la app localmente
    verify: "npm run test:e2e"  # Verificación de criterios de aceptación
    preview: ""
  
  health:
    command: "curl -f http://localhost:3000/api/health"
    expected_exit_code: 0
  ```

---

### 6. `.autodev/features/` (Especificaciones de Features)
* **Ubicación:** `.autodev/features/`
* **Cómo estructurarlo:**
  1. **`F001-walking-skeleton.md`:** Ya viene incluido. Es la primera vertical mínima obligatoria para demostrar que el runtime, build, test y health check funcionan.
  2. **Features adicionales (`F002-....md`, `F003-....md`):**
     * Usa la plantilla [`FEATURE_TEMPLATE.md`](file:///c:/Users/ambou/Desktop/autodev-starter/autodev-starter/.autodev/features/FEATURE_TEMPLATE.md).
     * Cada archivo debe declarar:
       * `id`: Identificador único (`F002`, `F003`, etc.).
       * `depends_on`: Lista de IDs de features previas requeridas (ej. `depends_on: [F001]`).
       * Criterios de aceptación estructurados en formato **Given / When / Then**.

---

### 7. `.autodev/state/decisions.md` (Registro de Decisiones - ADRs)
* **Ubicación:** `.autodev/state/decisions.md`
* Registra cualquier decisión arquitectónica relevante (ej. elección de base de datos, motor de autenticación, estrategia de caché) siguiendo el formato:
  * `ID`, `Status`, `Problem`, `Decision`, `Reason`, `Rejected alternatives`, `Consequences`.

---

## 🚀 Flujo de Trabajo: Cómo Empezar a Desarrollar

Una vez completado o definido el `PRODUCT_BRIEF.md`:

1. **Diagnóstico inicial:**
   ```powershell
   # En Windows PowerShell:
   .\.autodev\commands\inspect.ps1
   
   # En POSIX (Linux/macOS):
   ./.autodev/commands/inspect
   ```
2. **Inicializar el entorno (Bootstrap):**
   ```powershell
   .\.autodev\commands\bootstrap.ps1
   ```
3. **Indexar y sincronizar las features (Plan):**
   ```powershell
   .\.autodev\commands\plan.ps1
   ```
4. **Ejecutar el ciclo de desarrollo autónomo (Auto-Cycle):**
   ```powershell
   .\.autodev\commands\auto-cycle.ps1
   ```
   * El engine validará la feature activa, correrá los tests, ejecutará el contrato `verify`, auditará las políticas de seguridad de Git, generará la evidencia en `.autodev/evidence/` y creará un commit atómico.
   * Al terminar, desbloqueará automáticamente la siguiente feature dependiente en la cola.
