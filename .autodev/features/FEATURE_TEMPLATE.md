# Feature [ID]: [Título de la Funcionalidad]

id: [F00X]
title: [Título corto de la funcionalidad]
depends_on: [F001]

## Objective

[Describe en 1 o 2 oraciones qué valor aporta esta funcionalidad y qué permite al actor realizar.]

## Target Actors

- [Actor principal que interactúa con la funcionalidad]

## Preconditions

- [Condición previa 1: ej. La entidad X existe en estado Y]
- [Condición previa 2: ej. El actor está autenticado con rol Z]

## Business Rules

- [Regla 1: Restricción o validación que aplica]
- [Regla 2: Comportamiento esperado ante datos inválidos]

## Acceptance Criteria

### Scenario 1: [Nombre del escenario exitoso]
Given [Estado inicial o contexto]
And [Condición adicional]
When [El actor realiza una acción específica]
Then [Resultado observable en el sistema]
And [Efecto secundario o estado actualizado]

### Scenario 2: [Nombre del escenario de validación o rechazo]
Given [Estado inicial o contexto inválido]
When [El actor intenta realizar la acción]
Then [La operación es rechazada con un error descriptivo]
And [El estado previo se mantiene inalterado]
