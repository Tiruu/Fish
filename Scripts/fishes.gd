extends Node3D

@export var spawn_target: Marker3D
@export var entity_scene: PackedScene  # The scene to spawn
@export var navigation_region: NavigationRegion3D

var wait_target_time: float
var wait_timer: float = 0.0

var fish_count: int = 0

func _ready():
	wait_target_time = randf_range(1, 1)

func _physics_process(delta):
	if not Globals.is_getting_fished:
		wait_timer += delta
		if wait_timer >= wait_target_time:
			if fish_count <= 1:
				spawn_entity()
				wait_timer = 0.0

func get_random_point_in_navigation_region() -> Vector3:
	# Check if the navigation region is valid
	if navigation_region:
		var nav_mesh = navigation_region.get_navigation_mesh()
		if nav_mesh:
			# Get the vertices of the navigation mesh
			var vertices = nav_mesh.get_vertices()
			if vertices.size() > 0:
				# Sample a random vertex from the navigation mesh
				var random_index = randi() % vertices.size()
				return vertices[random_index]
	
	return Vector3.ZERO  # Return a default value if something goes wrong

func spawn_entity():
	var instance = entity_scene.instantiate()  # Create an instance of the entity
	var random_point = get_random_point_in_navigation_region()
	
	if random_point != Vector3.ZERO:  # Ensure the point is valid
		var height_offset = 0.2  # Adjust this value to set how high you want the entity to spawn
		random_point.y += height_offset  # Raise the y-coordinate by the height offset
		
		add_child(instance)  # Add the entity to the scene first
		instance.global_position = random_point  # Set the position of the entity after adding it to the scene
		fish_count = fish_count + 1
		print("+1 fish, count ", fish_count)
