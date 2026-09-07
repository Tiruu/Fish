extends TextureButton

@onready var water: MeshInstance3D = get_node("/root/Game/Level/WaterPlane/CollisionShape3D/WaterTop")
@onready var zone_label: Label = %ZoneLabel
@onready var animator: AnimationPlayer = %AnimationPlayer
@onready var black_screen: ColorRect = %BlackScreen
@onready var riff: StaticBody3D = get_node("/root/Game/Level/Riff")

var current_zone: String = "Ocean"

# Array to store textures
var textures: Array = []
var current_texture_index: int = 0

var is_button_pressed: bool = false 

func _ready():
	# Initialize the textures array
	textures = [
		load("res://Textures/Other/water.png"),
		load("res://Textures/Other/water3.png")
	]

func _physics_process(delta: float) -> void:
	if self.button_pressed:
		on_button_pressed()
	elif not self.button_pressed:
		is_button_pressed = false

	zone_label.text = current_zone.capitalize()

func on_button_pressed() -> void:
	if not is_button_pressed and not Globals.is_bait_placed:
		is_button_pressed = true
		black_screen.visible = true

		# Fade-out animation
		animator.play("FadeOut")
		await get_tree().create_timer(1).timeout

		# Switch textures and update zone
		switch_shader()
		Musicplayer.play_song(Globals.current_fishing_zone)

		# Fade-in animation
		animator.play("FadeIn")
		await get_tree().create_timer(1).timeout
		black_screen.visible = false

		print(Globals.current_fishing_zone)

func switch_shader() -> void:
	if water:
		var mesh = water.get_mesh()
		var material = mesh.surface_get_material(0)

		if material and material is ShaderMaterial:
			# Cycle through textures
			current_texture_index = (current_texture_index + 1) % textures.size()
			var new_texture = textures[current_texture_index]
			material.set_shader_parameter("tex_frg_12", new_texture)

			# Set shader parameters based on current texture
			_update_zone_parameters(material)

			# Update global fishing zone
			Globals.current_fishing_zone = current_zone

func _update_zone_parameters(material: ShaderMaterial) -> void:
	if current_texture_index == 0:
		current_zone = "ocean"
		material.set_shader_parameter("SpeedModifier", 0.2)
		riff.visible = false
	else:
		current_zone = "river"
		material.set_shader_parameter("SpeedModifier", 0.3)
		riff.visible = true

	material.set_shader_parameter("PingPong", false)
