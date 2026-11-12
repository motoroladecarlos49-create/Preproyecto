extends Resource
class_name Mochila

signal mochila_actualizada
signal item_seleccionado_cambiado(item: Item)

@export var objetos: Dictionary = {}
@export var capacidad_maxima: int = 8

var item_seleccionado: Item = null

func agregar_item(item: Item) -> bool:
	# --- PROTECCIÓN CONTRA NULOS ---
	if item == null:
		print("ERROR: Se intentó agregar un ítem nulo a la mochila.")
		return false
	# -------------------------------
	
	var clave = item.nombre
	
	# 1. Intentar apilar
	if item.apilable and objetos.has(clave):
		var item_en_mochila = objetos[clave]
		if item_en_mochila.cantidad < item_en_mochila.max_cantidad:
			item_en_mochila.cantidad += 1
			mochila_actualizada.emit()
			return true
			
	# 2. Comprobar si hay espacio libre
	if objetos.size() >= capacidad_maxima:
		return false
		
	# 3. Agregar nuevo
	var nueva_instancia_item = item.duplicate()
	nueva_instancia_item.nombre = item.nombre
	nueva_instancia_item.id_escena = item.id_escena # Copiamos el ID original
	
	var clave_nueva = clave
	
	if not nueva_instancia_item.apilable or objetos.has(clave_nueva):
		clave_nueva += "_" + str(randi())
		
	objetos[clave_nueva] = nueva_instancia_item
	mochila_actualizada.emit()
	return true

func remover_item_por_clave(clave: String):
	if objetos.has(clave):
		if objetos[clave] == item_seleccionado:
			item_seleccionado = null
			item_seleccionado_cambiado.emit(null)
		objetos.erase(clave)
		mochila_actualizada.emit()

func seleccionar_item(clave: String):
	if clave == "" or not objetos.has(clave):
		item_seleccionado = null
	elif objetos[clave] == item_seleccionado:
		item_seleccionado = null 
	else:
		item_seleccionado = objetos[clave]
		
	item_seleccionado_cambiado.emit(item_seleccionado)
