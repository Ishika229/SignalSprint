extends Node3D

const TARGET_CELLS := 5
const ARENA_SIZE := 18.0
const PLAYER_SPEED := 8.0

var player: CharacterBody3D
var hazard: Area3D
var score := 0
var game_over := false
var score_label: Label
var message_label: Label
var restart_button: Button
var hazard_direction := 1.0

func _ready() -> void:
	_build_world()
	_build_ui()
	_update_score()

func _build_world() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#101b2c")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#b8d5ff")
	environment.ambient_light_energy = 0.7
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.4
	add_child(sun)

	_add_box("Floor", Vector3(0, -0.5, 0), Vector3(ARENA_SIZE, 1, ARENA_SIZE), Color("#263b4d"))
	_add_box("North Wall", Vector3(0, 0.5, -ARENA_SIZE / 2), Vector3(ARENA_SIZE, 2, 0.5), Color("#526b80"))
	_add_box("South Wall", Vector3(0, 0.5, ARENA_SIZE / 2), Vector3(ARENA_SIZE, 2, 0.5), Color("#526b80"))
	_add_box("West Wall", Vector3(-ARENA_SIZE / 2, 0.5, 0), Vector3(0.5, 2, ARENA_SIZE), Color("#526b80"))
	_add_box("East Wall", Vector3(ARENA_SIZE / 2, 0.5, 0), Vector3(0.5, 2, ARENA_SIZE), Color("#526b80"))
	_add_box("Obstacle A", Vector3(-3, 0.5, -1), Vector3(2.0, 1.0, 2.0), Color("#64748b"))
	_add_box("Obstacle B", Vector3(3, 0.5, 2), Vector3(2.0, 1.0, 2.0), Color("#64748b"))

	player = CharacterBody3D.new()
	player.name = "Player"
	var player_mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3(0.9, 0.9, 0.9)
	player_mesh.mesh = cube
	player_mesh.position.y = 0.45
	player_mesh.material_override = _material(Color("#42d6c5"))
	player.add_child(player_mesh)
	var player_collision := CollisionShape3D.new()
	var player_shape := BoxShape3D.new()
	player_shape.size = Vector3(0.9, 0.9, 0.9)
	player_collision.shape = player_shape
	player_collision.position.y = 0.45
	player.add_child(player_collision)
	player.position = Vector3(0, 0, 7)
	add_child(player)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 17, 13)
	camera.rotation_degrees = Vector3(-52, 0, 0)
	camera.current = true
	player.add_child(camera)

	for p in [Vector3(-6, 0.55, 5), Vector3(6, 0.55, 5), Vector3(-6, 0.55, -5), Vector3(6, 0.55, -5), Vector3(0, 0.55, -7)]:
		_add_collectible(p)

	hazard = Area3D.new()
	hazard.name = "SecurityDrone"
	var hazard_mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.65
	sphere.height = 1.3
	hazard_mesh.mesh = sphere
	hazard_mesh.material_override = _material(Color("#ff5b65"))
	hazard.add_child(hazard_mesh)
	var hazard_collision := CollisionShape3D.new()
	var hazard_shape := SphereShape3D.new()
	hazard_shape.radius = 0.8
	hazard_collision.shape = hazard_shape
	hazard.add_child(hazard_collision)
	hazard.position = Vector3(-5, 0.7, 0)
	hazard.body_entered.connect(_on_hazard_body_entered)
	add_child(hazard)

func _add_box(label: String, pos: Vector3, dimensions: Vector3, tint: Color) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.position = pos
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(tint)
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func _add_collectible(pos: Vector3) -> void:
	var item := Area3D.new()
	item.name = "EnergyCell"
	item.position = pos
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.38
	mesh.height = 0.76
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(Color("#ffd166"))
	item.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.55
	collision.shape = shape
	item.add_child(collision)
	item.body_entered.connect(_on_collectible_body_entered.bind(item))
	add_child(item)

func _material(tint: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.metallic = 0.15
	material.roughness = 0.45
	return material

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 18)
	panel.add_theme_stylebox_override("panel", _panel_style())
	layer.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 6)
	panel.add_child(layout)
	score_label = Label.new()
	score_label.add_theme_font_size_override("font_size", 22)
	layout.add_child(score_label)
	var help := Label.new()
	help.text = "WASD / Arrow keys: Move   •   Collect 5 cells   •   Avoid the red drone"
	help.add_theme_font_size_override("font_size", 15)
	layout.add_child(help)

	message_label = Label.new()
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	message_label.position = Vector2(-220, -55)
	message_label.size = Vector2(440, 80)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 30)
	message_label.add_theme_color_override("font_color", Color("#ffffff"))
	message_label.visible = false
	layer.add_child(message_label)

	restart_button = Button.new()
	restart_button.text = "Play Again"
	restart_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	restart_button.position = Vector2(-75, 35)
	restart_button.size = Vector2(150, 42)
	restart_button.visible = false
	restart_button.pressed.connect(_restart)
	layer.add_child(restart_button)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.07, 0.11, 0.88)
	style.set_content_margin_all(12)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style

func _physics_process(delta: float) -> void:
	if game_over:
		return
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A): input_dir.x -= 1
	if Input.is_key_pressed(KEY_D): input_dir.x += 1
	if Input.is_key_pressed(KEY_W): input_dir.y -= 1
	if Input.is_key_pressed(KEY_S): input_dir.y += 1
	input_dir = input_dir.normalized()
	player.velocity = Vector3(input_dir.x * PLAYER_SPEED, 0, input_dir.y * PLAYER_SPEED)
	player.move_and_slide()
	player.position.x = clampf(player.position.x, -8.2, 8.2)
	player.position.z = clampf(player.position.z, -8.2, 8.2)

	hazard.position.x += hazard_direction * 3.0 * delta
	if hazard.position.x > 6.5: hazard_direction = -1.0
	if hazard.position.x < -6.5: hazard_direction = 1.0

func _on_collectible_body_entered(body: Node3D, item: Area3D) -> void:
	if body != player or game_over:
		return
	score += 1
	item.queue_free()
	_update_score()
	if score >= TARGET_CELLS:
		_finish_game(true)

func _on_hazard_body_entered(body: Node3D) -> void:
	if body == player and not game_over:
		_finish_game(false)

func _update_score() -> void:
	if score_label:
		score_label.text = "ENERGY CELLS: %d / %d" % [score, TARGET_CELLS]

func _finish_game(won: bool) -> void:
	game_over = true
	message_label.text = "FACILITY RESTORED!" if won else "DRONE CAUGHT YOU!"
	message_label.visible = true
	restart_button.visible = true

func _restart() -> void:
	get_tree().reload_current_scene()
