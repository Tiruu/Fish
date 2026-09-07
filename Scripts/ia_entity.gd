extends CharacterBody3D

@export var movement_target: Marker3D
@onready var navigation_region: NavigationRegion3D = get_node("../../%NavigationRegion3D")
@onready var navigation_agent = $NavigationAgent3D
@onready var fish_spawner: Node3D = get_node("../../%Fishes")

@export var fish_value: int

var movement_speed: float = 1.0

var change_target_time: float  # Time in seconds to change the target position
var target_timer: float = 0.0
var wait_target_time: float
var wait_timer: float = 0.0
var is_waiting: bool = false  # State variable to track if the agent is waiting

func _ready():
	fish_value = round(randf_range(1, 10))
	
	change_target_time = randf_range(7.0, 10.0)
	wait_target_time = randf_range(2.0, 8.0)
	
	# Set the initial target position
	update_marker_position()

func _physics_process(delta):
	if not Globals.is_getting_fished:
		target_timer += delta

		if is_waiting:
			wait_timer += delta
			if wait_timer >= wait_target_time:
				is_waiting = false  # Reset waiting state
				update_marker_position()  # Change target position after waiting
				target_timer = 0.0  # Reset target timer
				wait_timer = 0.0  # Reset wait timer
		else:
			if target_timer >= change_target_time:
				is_waiting = true  # Start waiting
				wait_timer = 0.0  # Reset wait timer

			if navigation_agent.is_navigation_finished():
				return
			
			var current_entity_position = global_position
			var next_path_position = navigation_agent.get_next_path_position()

			var new_velocity = next_path_position - current_entity_position
			new_velocity = new_velocity.normalized()
			
			new_velocity *= movement_speed
			velocity = new_velocity 
			
			move_and_slide()

func update_marker_position():
	# Get a random point within the navigation region
	var random_point = get_random_point_in_navigation_region()
	if random_point != Vector3.ZERO:  # Ensure the point is valid
		movement_target.position = random_point
		navigation_agent.target_position = random_point

func get_random_point_in_navigation_region() -> Vector3:
	# Check if the navigation region is valid
	if navigation_region:
		var nav_mesh = navigation_region.get_navigation_mesh()
		if nav_mesh:
			var vertices = nav_mesh.get_vertices()
			if vertices.size() > 0:
				var random_index = randi() % vertices.size()
				return vertices[random_index]
	
	return Vector3.ZERO  # Return a default value if something goes wrong
