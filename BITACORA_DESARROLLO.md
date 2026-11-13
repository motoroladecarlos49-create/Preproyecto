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


### 2026-11-12 — Integración inicial de menús principal y pausa
- Archivos creados:
  - `Menus/menu_principal.tscn`
  - `Menus/menu_pausa.tscn`
  - `Menus/scripts/menu_principal.gd`
  - `Menus/scripts/menu_pausa.gd`
- Archivos modificados:
  - `project.godot`
  - `Scripts/GameManager.gd`
  - `Escenas/player.tscn`
- Menú principal:
  - Se configura como escena inicial del proyecto.
  - El botón «Jugar» pasa a llamarse «Nueva partida».
  - Se agrega dinámicamente «Continuar» solo si existe un guardado válido: el recurso debe poder cargarse, tener una escena registrada y esa escena debe existir.
  - «Continuar» llama al sistema de carga manual existente, conservando escena, posición, inventario, selección y estado de linterna según los datos del guardado.
  - Si ya existe un guardado válido, «Nueva partida» solicita confirmación y avisa que eliminará ese guardado. Solo después de confirmar se elimina el archivo anterior y se reinicia el estado global.
  - Se conserva el menú de opciones (volumen, pantalla completa y resolución); se corrigió la ruta del nodo OptionButton para coincidir con el nombre real de la escena.
- Menú de pausa:
  - Se instancia dentro de la escena del jugador.
  - Se abre/cierra con la acción `ui_cancel` (Escape por defecto) y pausa el árbol mientras está visible.
  - «Reanudar» quita la pausa.
  - «Menú principal» despausa antes de cambiar a `Menus/menu_principal.tscn`.
  - Se corrigieron la ruta del panel de opciones y el método conectado al botón de volver al menú.
- Organización:
  - Los archivos integrados se colocan en una nueva carpeta `Menus/`.
  - Se conserva intacta la carpeta original `menuprincipal/`, incluido su `project.godot` y archivos temporales `.tmp`, para no borrar material de referencia antes de probar la integración.
  - No se modificaron ni movieron recursos de `Imagenes/assepts`; quedan disponibles para una etapa posterior de mejora visual.
- Prueba/estado: cambios subidos a GitHub. No se ejecutó Godot; quedan pendientes la importación y las pruebas de inicio, aparición dinámica de «Continuar», confirmación de nueva partida, carga, pausa, reanudación y regreso al menú.
- Commits:
  - Script del menú principal: `858099bd74ec29c6e932a8140aa1f3f8951cad1a`
  - Script del menú de pausa: `e044acdc85a8abce8fc771efd991ec085315267c`
  - GameManager: `484dcb345df599c605196fe32b50ba897eb0e5fc`
  - Escena del menú principal: `5ef7738a0e757c839dfa7efc8bf6f2ad2b90d874`
  - Escena del menú de pausa: `b27c0461183f3880432098d5c792741ed193aade`
  - Integración del menú de pausa en player: `e40cf3d5a6ce722602a0dd5539a66160ae2342fa`
  - Escena inicial del proyecto: `fe423c3abe8623d3350fadd1d56d40e24a8e9b31`
  - Ajuste de texto del menú de pausa: `a13c7f0858a46c0cd4e95bdf992b632df819a68d`


### 2026-11-12 — Corrección de apertura del menú de pausa con Escape
- Archivos modificados:
  - `Menus/scripts/menu_pausa.gd`
  - `Menus/menu_pausa.tscn`
- Cambio:
  - Se detecta Escape directamente como tecla, además de mantener compatibilidad con la acción `ui_cancel`.
  - Se ignoran repeticiones de tecla y se marca el evento como atendido para evitar que otros controles reaccionen al mismo Escape.
  - Al abrir la pausa se muestra el fondo y se cierra el submenú de opciones; al cerrar se reanuda el árbol.
  - Se mantiene el procesamiento del menú durante la pausa y se eleva su CanvasLayer a la capa 10 para dibujarlo por encima de la interfaz del juego.
  - El fondo ahora se ajusta al tamaño completo de la ventana en lugar de usar dimensiones fijas.
  - Se quitó el reinicio forzado de `get_tree().paused` en `_ready()`, para no alterar el estado global al instanciar el menú.
- Motivo: hacer fiable la apertura/cierre con Esc y evitar que el menú quede parcialmente dibujado o detrás del inventario.
- Prueba/estado: cambios subidos a GitHub; no se ejecutó Godot, por lo que queda pendiente probar Escape, Reanudar, Opciones y Menú principal en ejecución.


### 2026-11-12 — Centralizar guardado y opciones en el menú de pausa
- Archivos modificados:
  - `Menus/scripts/menu_pausa.gd`
  - `Menus/menu_pausa.tscn`
  - `Menus/scripts/menu_principal.gd`
  - `Menus/menu_principal.tscn`
  - `Inventario/ui_inventario.gd`
  - `Escenas/ui_inventario.tscn`
- Cambios:
  - Escape actúa como interruptor: una pulsación abre la pausa y otra pulsación la cierra; no hace falta mantener la tecla.
  - Se trasladan los botones Guardar y Cargar desde el inventario al menú de pausa. Guardar usa el jugador actual como referencia; Cargar se deshabilita cuando no existe un guardado válido.
  - Se muestra un mensaje de resultado dentro del menú de pausa.
  - Las opciones de pausa ahora incluyen volumen general, pantalla completa y resolución (1600x900, 1280x720 y 720x480), igual que el menú principal.
  - Se sincronizan los controles con los ajustes actuales al abrir opciones. Se ordenaron los controles del submenú para mostrar volumen, pantalla completa, resolución y Volver.
  - Se corrige el rango del volumen a 0..1 en ambos menús para que la conversión lineal/decibelios sea correcta.
  - Se retiran Guardar y Cargar del inventario; el botón Tirar y la gestión de objetos permanecen.
- Motivo: concentrar las acciones de partida y configuración en la pausa, manteniendo el inventario enfocado en los objetos.
- Prueba/estado: cambios subidos a GitHub; no se ejecutó Godot. Probar apertura/cierre con Escape, guardado/carga desde pausa, ajustes de volumen/pantalla/resolución y confirmar que el inventario conserva Tirar.


### 2026-11-12 — Corregir tipado del recorrido de resoluciones en pausa
- Archivo modificado: `Menus/scripts/menu_pausa.gd`.
- Error informado: Godot no podía inferir el tipo de la variable `resolucion` dentro del `for` que recorre el arreglo de resoluciones.
- Causa: aunque el arreglo está declarado como `Array[Vector2i]`, el analizador no estaba infiriendo el tipo del elemento del bucle.
- Solución: declarar explícitamente el tipo del iterador: `for resolucion: Vector2i in resoluciones:`.
- Alcance: cambio puntual; no se alteró la lógica de opciones ni las demás funciones del menú.
- Prueba/estado: corrección subida a GitHub. No se ejecutó Godot desde aquí; comprobar que el proyecto ya supera este error de análisis.
- Commit del script: `5ca11a7f7273e629b9be5aaa73bea7f05819bfed`.


### 2026-11-12 — Corregir inferencia de resolución en menú principal
- Archivo modificado: `Menus/scripts/menu_principal.gd`.
- Error informado: persistía el error de inferencia de tipo para la variable `resolucion` al configurar las opciones del menú principal.
- Causa: el menú principal construía un arreglo literal dentro del bucle y Godot no podía inferir el tipo del elemento indexado.
- Solución: declarar una lista compartida y tipada `Array[Vector2i]` y recorrerla directamente para comparar la resolución actual. También se tipó explícitamente el tamaño de ventana como `Vector2i`.
- Prueba/estado: corrección subida a GitHub. No se ejecutó Godot; queda pendiente confirmar que el parser ya no informa este error.
- Commit del script: `80f757f4ed43401a9f8dc537858e4abda2cf5c65`.


### 2026-11-12 — Rediseñar y ordenar las opciones del menú de pausa
- Archivos modificados:
  - `Menus/scripts/menu_pausa.gd`
  - `Menus/menu_pausa.tscn`
- Cambios funcionales:
  - El panel de opciones ahora es independiente del botón «Opciones» y queda centrado en la ventana.
  - Al abrir opciones se ocultan título, botones y estado del menú de pausa; queda visible el fondo oscurecido y el panel de configuración.
  - Se agregó «VOLVER A PAUSA». Escape dentro de opciones también vuelve primero al menú de pausa; una nueva pulsación de Escape cierra la pausa.
  - Se separó la configuración del volumen de la configuración de pantalla para que la resolución y pantalla completa sigan cargándose aunque no exista el bus Master esperado.
  - El selector de resoluciones se rellena al abrir opciones. Elegir una resolución cambia a modo ventana, aplica el tamaño y centra la ventana.
  - El volumen refleja también el estado de silencio del bus; el valor cero silencia y los valores superiores restauran el sonido.
  - Se conserva la lógica de guardado/carga y se muestra el estado de las acciones.
- Diseño y recursos:
  - Se utiliza la fuente existente `fuente/immortal/IMMORTAL.ttf` en títulos y botones.
  - Se incorporan recursos gráficos Kenney Fantasy UI desde `Imagenes/assepts/kenney_fantasy-ui-borders/PNG/Default/Border/panel-border-000.png` y `.../Divider/divider-000.png`.
  - Se añadió un panel oscuro centrado con borde dorado, sombra, botones con estados normal/hover/presionado y una composición más uniforme.
- Motivo: evitar que las opciones aparezcan como una ventana superpuesta al menú de pausa y mejorar la legibilidad y presentación del menú.
- Prueba/estado: cambios subidos a GitHub. No se ejecutó Godot desde aquí; probar apertura/cierre de pausa, entrada/salida de opciones, volumen, silencio, pantalla completa, resoluciones, guardado y carga. Confirmar también que la fuente y los recursos gráficos se importen correctamente.
- Commits:
  - Escena: `a8cea300d6e9aba30e8fcf72e3357c3fde3b7ef4`
  - Script (ajuste de tipado incluido): `11147e91a25edb3b123f53c73f7d778bf5528761`


- Ajuste posterior: después de guardar correctamente, se vuelve a comprobar si existe una partida válida para habilitar inmediatamente el botón «CARGAR» sin tener que cerrar y reabrir la pausa.
- Commit adicional del script: `f010e15da0c132c4f4fd4a2816320a22834dfe45`.


### 2026-11-12 — Unificar el diseño del menú principal y los mensajes tutoriales
- Archivos modificados:
  - `Menus/menu_principal.tscn`
  - `Menus/scripts/menu_principal.gd`
  - `Scripts/MessageManager.gd`
- Menú principal:
  - Se reorganizó la pantalla con el título y los botones centrados, usando una paleta oscura y dorada.
  - Se reutiliza la fuente `fuente/immortal/IMMORTAL.ttf` y los recursos Kenney de borde y divisor ya presentes en el proyecto.
  - El panel de opciones ahora es independiente del contenedor del menú, queda centrado y oculta el menú principal mientras está abierto.
  - Se agregó el botón «VOLVER AL MENÚ» y Escape también permite volver desde opciones.
  - Se mantuvieron Nueva partida, Continuar (cuando hay guardado), la confirmación de sobrescritura y Salir.
- Funcionamiento de opciones:
  - Se sincronizan volumen, silencio, pantalla completa y resolución al abrir el panel.
  - Se separó la lectura del volumen de la configuración de pantalla para que la falta del bus Master no impida configurar pantalla.
  - Al elegir una resolución se cambia primero a modo ventana, se aplica el tamaño seleccionado y se centra la ventana; el control de pantalla completa se actualiza para reflejar ese cambio.
  - El interruptor de pantalla completa cambia entre los modos ventana y pantalla completa.
- Mensajes tutoriales:
  - `MessageManager.gd` ahora muestra los mensajes en un panel inferior oscuro con borde dorado, tipografía del proyecto, texto centrado y ajuste automático de línea.
  - Se conserva la función `mostrar_mensaje(texto, duracion)`, el temporizador y la lógica para no reiniciar mensajes idénticos que todavía están visibles.
- Motivo: dar continuidad visual entre menú principal, pausa, opciones y mensajes tutoriales, y corregir el cambio de resolución para que no intente redimensionar la ventana mientras sigue en pantalla completa.
- Prueba/estado: cambios subidos a GitHub. No se ejecutó Godot desde este entorno; queda pendiente probar el menú en ventana y pantalla completa, las tres resoluciones, volumen/silencio, Continuar/Nueva partida y la aparición/desaparición de mensajes tutoriales.
- Commits:
  - Script del menú principal: `f08dc7142ebd98bf1e10f968b0e20e0ab7e8ac3a`
  - Escena del menú principal: `cff1ec7ed6893b5969fa9f713f6a9780d6a7cb3d`
  - Mensajes tutoriales: `cc281ff4b8d91998157f5fe618e127778078c96a`


### 2026-11-13 — Corregir ruta del botón Volver en opciones del menú principal
- Archivo modificado: `Menus/scripts/menu_principal.gd`.
- Error informado en Godot: no encontraba `submenuOpciones/MarginContainer/VBoxOpciones/botonvolver`; luego `_estilizar_boton()` intentaba aplicar la fuente sobre una referencia nula.
- Causa: en `Menus/menu_principal.tscn` el nodo está nombrado `botoncerrar`, pero el `@onready` del script buscaba `botonvolver`.
- Solución: se corrigió la ruta del `@onready var boton_volver` para apuntar al nombre real `botoncerrar`. No se modificó la escena ni el comportamiento del botón.
- Prueba/estado: verificada la coincidencia entre la ruta corregida y el nombre del nodo en la escena remota. No se ejecutó Godot desde este entorno; comprobar que desaparezcan ambos errores al iniciar el menú.
- Commit del script: `f559bf6a2574ed1bb255044e9ada8a0087bee05d`.


### 2026-11-13 — Recuperar la distribución original del menú principal y corregir el uso de las barras
- Archivos modificados:
  - `Menus/menu_principal.tscn`
  - `Menus/scripts/menu_principal.gd`
- Menú principal:
  - Se recuperaron la jerarquía, el orden y las propiedades de posición/tamaño del menú original ubicado en `menuprincipal/menu_principal.tscn`.
  - Se quitaron los elementos decorativos añadidos como separadores, que alteraban el espaciado y la distribución.
  - Se mantuvieron la tipografía Immortal y el estilo oscuro/dorado del contenedor de opciones y los botones, sin imponer tamaños mínimos nuevos ni centrar/reubicar el menú.
- Barras y controles:
  - Se eliminó el uso de la textura gráfica de divisor como adorno entre el título y los botones y en el panel de opciones.
  - Se recuperó el nodo `HSeparator` original para separar visualmente el encabezado de opciones de sus controles.
  - El volumen sigue siendo un `HSlider` funcional y ahora su pista y tramo recorrido tienen estilos propios; no se usa una barra decorativa para simular un control.
  - Se conservaron los controles reales de pantalla completa y resolución.
- Motivo: respetar la composición que tenía el menú principal y reservar los elementos tipo barra para controles que representan valores, como el volumen.
- Prueba/estado: archivos actualizados en GitHub. No se ejecutó Godot desde este entorno; comprobar la posición y el orden visual, el slider de volumen, pantalla completa y las resoluciones.
- Commits:
  - Escena: 577c124fd5c39c3235a8d56b44455c28a1400611
  - Script: accc1ee1048af41fbeae186b1e51c88c3ebb26c1


### 2026-11-13 — Ajustar la ruta del selector tras recuperar la escena original
- Archivo modificado: `Menus/scripts/menu_principal.gd`.
- Cambio: la referencia al `OptionButton` ahora apunta al nodo original `HBoxContainer/optionbutton`, en lugar del contenedor que existía solamente en el rediseño anterior.
- Motivo: mantener el menú con su jerarquía original sin dejar referencias rotas en el script.
- Prueba/estado: ruta contrastada con `Menus/menu_principal.tscn` en GitHub. No se ejecutó Godot; queda pendiente la prueba funcional de las opciones.
- Commit: 75ab3999bdc1b6ef84dcd25c6941b42503e51690.


### 2026-11-13 — Corregir divisor de opciones de pausa y unificar barras de volumen
- Archivos modificados:
  - `Menus/menu_pausa.tscn`
  - `Menus/scripts/menu_pausa.gd`
- Menú de pausa:
  - Se quitó el recurso gráfico `divider-000.png` y el nodo `separador_visual`, que estaban usados como una barra decorativa debajo del título de opciones.
  - Se conservó el orden y la distribución del resto de los controles.
  - Se aplicó al `HSlider` de volumen el mismo estilo oscuro/dorado del menú principal: pista oscura, tramo recorrido dorado y esquinas redondeadas.
- Menú principal:
  - Se verificó que su `HSlider` ya utiliza el mismo estilo de pista y tramo recorrido; no fue necesario modificarlo en esta corrección.
- Motivo: reservar la apariencia de barra para el control real de volumen en ambos menús y eliminar la falsa separación visual del panel de pausa.
- Prueba/estado: cambios subidos y verificados en GitHub. No se ejecutó Godot; probar visualmente ambos sliders y confirmar que el panel de pausa ya no muestra el divisor.
- Commits:
  - Escena de pausa: d49b4793413d9e6ba882fe06d40f751a9b2e09d5
  - Script de pausa: 02caff44214afc68f7c97ec164f0c051d986cd71
