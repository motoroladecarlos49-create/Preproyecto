# Bitácora de desarrollo — Preproyecto

Repositorio: https://github.com/motoroladecarlos49-create/Preproyecto
Rama: main

## Propósito
Este archivo mantiene el contexto técnico para retomar el proyecto en futuras conversaciones o con otra instancia de ChatGPT. Actualizarlo ante cada modificación, creación o eliminación de archivos, cambios de escenas/configuración y decisiones técnicas importantes.

## Arquitectura conocida
- Proyecto Godot.
- Jugador: `Scripts/player.gd`.
- Estado global/autoload: `Scripts/GameManager.gd`.
- Mochila: `Inventario/inventario.gd` (clase `Mochila`).
- UI del inventario: `Inventario/ui_inventario.gd`.
- Objeto recogible: `items/linterna_mundo.gd`, escena `Escenas/linterna_mundo.tscn`.
- El usuario sincroniza el repo remoto con GitHub Desktop. Tras cambios remotos debe usar Fetch origin y Pull origin.

## Historial de cambios conocidos

### Persistencia de objetos soltados
- GameManager tiene `registrar_item_tirado`, `quitar_item_tirado` y `restaurar_items_tirados`; los registros conservan escena y posición.
- Al recoger un objeto, se agrega su ID a `partida_actual.items_recogidos` y se quita el registro de objeto soltado.
- Al soltar, se conserva el ID original como recogido para evitar que reaparezca el objeto inicial del mapa. El objeto soltado recibe un ID nuevo.
- La restauración usa `_agregar_item_restaurado.call_deferred` para evitar el error de `add_child()` durante la configuración de hijos.
- Commits históricos informados: `39bea73d9bb383198dfdafd0811bdb9e85cbb85b`, `ceb01691a399cd76687fe75f6df15e98dc0f6c42`, `557b9b3b7eea56e6e10dae3fcad9b9230ea22d63`, `5cff0e4c09bf91fab4ec69b99738cffefd267170`, `9f40fe7e5ebd89e8a8f316fc351985faadb466a4`, `aec4f8f39c0e0a921409718f076008e976fdbe95`.

### Selección y bloqueo de movimiento
- La mochila global persiste entre escenas.
- Al crear un jugador, `player.gd` reaplica `mochila.item_seleccionado` mediante `_on_mochila_item_seleccionado_cambiado`, recuperando sprite y animación.
- `get_input()` pone `velocity = Vector2.ZERO` y reproduce idle mientras el inventario está visible o hay diálogo activo.
- Commit: `11020d0da5e513e618a4fb923f9e5c71a51803f8`.

### Estado encendido de la linterna entre escenas — 2026-11-12
- Archivos modificados: `Scripts/GameManager.gd`, `Scripts/player.gd`.
- Se añadió `GameManager.linterna_encendida`.
- Al alternar la linterna, se sincroniza esta variable con `flash_light.enabled`.
- Al reaplicar la selección de linterna en la nueva escena, se restaura el estado encendido/apagado.
- Al deseleccionar la linterna, se apaga y se limpia el estado global.
- Commits de código: `1852b79e472e515db687f2cebd7f66af24bbacc8` (GameManager), `1c5daaa0f5d8ffe0ea18b2ba8eb8dba0ed8e05ff` (player).
- Prueba: pendiente de ejecutar en Godot.

### 2026-11-12 — Soltar objetos a la altura de la colisión
- Archivo modificado: `Scripts/player.gd`.
- Cambio: al soltar un objeto, se agrega primero a la escena y luego se calcula su posición para alinear el centro de su `CollisionShape2D` con el centro de la colisión del jugador. Se elimina el desplazamiento fijo `Vector2(50, 50)`.
- Motivo: que el objeto aparezca a la altura real de la colisión del jugador y que el cálculo respete las escalas de la escena y del objeto.
- Prueba/estado: cambio subido a GitHub; pendiente de probar dentro de Godot en las distintas habitaciones.
- Commit de código: f927c7833c316e43e1706f8706cc9b670053bf82.

## Reglas para futuras modificaciones
1. Antes de editar, leer la versión actual de los archivos remotos; no asumir que el código sigue igual que en mensajes anteriores.
2. Hacer cambios pequeños y específicos, conservando el resto del código.
3. Actualizar esta bitácora en el mismo conjunto de cambios que el código.
4. Registrar archivos tocados, cambio, motivo, estado de prueba y commit SHA cuando esté disponible.
5. No afirmar que algo fue probado en Godot si no se ejecutó realmente.
6. Después de cambios remotos, recordar al usuario hacer Fetch/Pull origin en GitHub Desktop.
7. Registrar errores detectados, causa identificada y solución aplicada o pendiente.

## Plantilla de entrada
### AAAA-MM-DD — Título
- Archivos:
- Cambio:
- Motivo:
- Prueba/estado:
- Commit:


### 2026-11-12 — Ajustar posición intermedia al soltar objetos
- Archivo modificado: `Scripts/player.gd`.
- Cambio: la posición del objeto soltado se calcula como el punto medio entre la posición que alinea ambas colisiones y el desplazamiento anterior de `Vector2(50, 50)`.
- Motivo: dejar el objeto algo más arriba/cerca que con el desplazamiento anterior, sin mantenerlo exactamente centrado sobre la colisión del jugador.
- Prueba/estado: cambio subido a GitHub; pendiente de probar dentro de Godot y ajustar si la altura visual no resulta adecuada.
- Commit de código: 92eee59125f5526ec994847e28978002304fe067.


### 2026-11-12 — Primera etapa del sistema de guardado manual
- Archivos modificados:
  - `Scripts/GameManager.gd`
  - `Scripts/SaveGame.gd`
  - `Scripts/player.gd`
  - `Inventario/ui_inventario.gd`
  - `Escenas/ui_inventario.tscn`
  - `items/item.gd`
- Diseño: se incorpora guardado/carga manual desde dos botones visibles en la interfaz del inventario. El autoguardado queda fuera de esta primera etapa para implementarlo después sin duplicar la lógica de serialización.
- Datos guardados: mochila, escena actual, posición global del jugador, clave del objeto seleccionado, estado encendido/apagado de la linterna, objetos recogidos y objetos soltados con sus posiciones/escenas.
- Persistencia adicional: `Item.id_escena` pasa a ser exportado para que ResourceSaver conserve el identificador al serializar recursos.
- Carga: se recupera el recurso SaveGame, se restaura la mochila y el estado de linterna, se abre la escena guardada y el jugador aplica posición y selección guardadas al inicializarse.
- Interfaz: se agregan los botones `Guardar` y `Cargar` junto al botón existente `Tirar`; se muestran mensajes de resultado.
- Ruta local de guardado: `user://partida_guardada.tres`.
- Prueba/estado: cambios subidos a GitHub. No se ejecutó el proyecto en Godot; queda pendiente probar guardado, carga, selección, linterna y objetos soltados en ejecución. El autoguardado todavía no está implementado.
- Commits:
  - GameManager: `084694629d3ff768aa7e8af03e0bdba4bbd4a6b7`
  - SaveGame: `0c5d4b469f25262b83a98ba2cb6e35aad709f198`
  - Item: `547e46322eaac019465ca1f012b928803b8d3820`
  - Player: `2bfc8c62cae8139a3102f33cf2a765d602f6dbf4`
  - UI script: `3cfbd101e71f514882d54ed293f6df9cd669d0f5`
  - UI scene: `a116b5a5ce1a1df1e3c5a59e5a1dd28bf361fab7`
