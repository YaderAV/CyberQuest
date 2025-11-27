extends Line2D
class_name FlowEdgeVisual

signal flow_changed(u, v, new_flow)

var u_id: String
var v_id: String
var capacity: float
var current_flow: float = 0.0

# Referencias a los nodos hijos (se crearán o asignarán en la escena)
var label: Label
var btn_plus: Button
var btn_minus: Button

func setup(u: String, v: String, cap: float, start_pos: Vector2, end_pos: Vector2):
	u_id = u
	v_id = v
	capacity = cap
	
	# Dibujar línea
	points = PackedVector2Array([start_pos, end_pos])
	width = 4.0
	default_color = Color(0.3, 0.3, 0.3) # Gris oscuro (vacío)
	
	# Configurar UI (Label y Botones) en el punto medio
	var mid_point = (start_pos + end_pos) / 2.0
	
	# Instanciar o configurar controles (Asumimos que existen como hijos o los creamos)
	if not has_node("Control"):
		var control = Control.new()
		control.name = "Control"
		control.position = mid_point
		add_child(control)
		
		label = Label.new()
		label.position = Vector2(-20, -25)
		control.add_child(label)
		
		btn_plus = Button.new()
		btn_plus.text = "+"
		btn_plus.position = Vector2(10, -10)
		btn_plus.size = Vector2(20, 20)
		btn_plus.pressed.connect(_on_plus_pressed)
		control.add_child(btn_plus)
		
		btn_minus = Button.new()
		btn_minus.text = "-"
		btn_minus.position = Vector2(-30, -10)
		btn_minus.size = Vector2(20, 20)
		btn_minus.pressed.connect(_on_minus_pressed)
		control.add_child(btn_minus)
	else:
		var ctrl = $Control
		ctrl.position = mid_point
		label = ctrl.get_node("Label")
		btn_plus = ctrl.get_node("BtnPlus")
		btn_minus = ctrl.get_node("BtnMinus")
		
		if not btn_plus.pressed.is_connected(_on_plus_pressed):
			btn_plus.pressed.connect(_on_plus_pressed)
			btn_minus.pressed.connect(_on_minus_pressed)

	update_visuals()

func _on_plus_pressed():
	# Intentar aumentar flujo (la lógica de validación estará en el Visualizador)
	emit_signal("flow_changed", u_id, v_id, current_flow + 1.0)

func _on_minus_pressed():
	# Intentar disminuir flujo
	emit_signal("flow_changed", u_id, v_id, current_flow - 1.0)

func update_flow_value(val: float):
	current_flow = val
	update_visuals()

func update_visuals():
	if label:
		label.text = "%d / %d" % [int(current_flow), int(capacity)]
		
		# Colores según saturación
		if current_flow == 0:
			label.modulate = Color.WHITE
			default_color = Color(0.3, 0.3, 0.3)
		elif current_flow < capacity:
			label.modulate = Color.YELLOW
			default_color = Color(1, 0.6, 0) # Naranja
		else:
			label.modulate = Color.GREEN
			default_color = Color(0, 1, 0) # Verde (Saturado)
