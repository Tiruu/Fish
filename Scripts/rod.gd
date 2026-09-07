extends Node3D

@export var water: StaticBody3D
@export var bait_spot: Marker3D
@export var bait_detection_area: Area3D
@onready var fish_button: TextureButton = get_node("/root/Game/UI/FishButton")
@onready var ui: Control = get_node("/root/Game/UI")

@onready var raycast = $RayCast3D  # Reference to the RayCast node
@onready var animator = $AnimationPlayer
@onready var bait_in = %BaitIn
@onready var bait_out = %BaitOut
@onready var fish_touch = %FishTouch
@onready var fish_caught = %FishCaught

var is_catching: bool = false
var catch_target_time: float = 2.0
var catch_timer: float = 0.0

var wait_target_time: float = 0.0
var wait_timer: float = 0.0

var fish_data: Dictionary = {}

func _ready():
	load_fish_data()

func load_fish_data():
	var file = FileAccess.open("res://fishing_zones.json", FileAccess.READ)
	if file:
		var json = JSON.parse_string(file.get_as_text())
		if json:
			fish_data = json["zones"]
		file.close()

func _physics_process(delta):
	if Globals.is_bait_placed and not Globals.is_getting_fished:
		if wait_timer == 0.0:
			wait_target_time = round(randf_range(2.0, 10.0))  # Random wait time for fish
			print(wait_target_time)
		
		wait_timer += delta
		if wait_timer >= wait_target_time:
			get_fish()
			wait_timer = 0.0
	
	if is_catching:
		catch_timer += delta
		if catch_timer >= catch_target_time:
			catch_timer = 0.0
			missed_fish()
			print("The fish got away")

func _unhandled_input(event):
	if event.is_action_pressed("touch") and not Globals.is_getting_fished and not Globals.is_inside_book:
		handle_bait_placement(event.position)

func handle_bait_placement(touch_position):
	var camera = get_viewport().get_camera_3d()
	if camera:
		var ray_origin = camera.project_ray_origin(touch_position)
		var ray_direction = camera.project_ray_normal(touch_position) * 1000  # Extend the ray

		# Update raycast position and perform raycast
		raycast.global_transform.origin = ray_origin
		raycast.target_position = ray_origin + ray_direction
		raycast.force_raycast_update()

		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider == water:
				if not Globals.is_bait_placed:
					place_bait(raycast.get_collision_point())
				else:
					remove_bait()

func place_bait(collision_point):
	bait_spot.position = collision_point
	bait_spot.position.y = 0.5
	bait_spot.visible = true
	Globals.is_bait_placed = true
	animator.play("floater_bobbing")
	bait_in.play()

func remove_bait():
	Globals.is_bait_placed = false
	animator.play("floater_away")
	bait_out.play()
	wait_timer = 0.0

func get_fish():
	var current_zone = Globals.current_fishing_zone
	if not fish_data.has(current_zone):
		print("No fish available in this zone!")
		return
	
	# Combine fish from the current zone and the "other" category
	var available_fish = fish_data[current_zone] + fish_data["other"]
	var total_weight = 0
	
	# Calculate total probability weight, excluding already caught unique fish
	for fish in available_fish:
		if str(fish["type"]) == str(Globals.last_fish_caught):
			print("Skipping dupe fish of type:", fish["type"])  # Debugging
			continue
		total_weight += fish["probability"]

	if total_weight <= 0:
		print("No fish available to catch!")
		return

	# Roll for fish selection based on probability
	var random_roll = randi() % int(total_weight)
	var cumulative_weight = 0
	var caught_fish = available_fish[-1]  # Default to last fish to ensure a catch
	
	print("Available fishes : ", available_fish)
	
	# available_fish.shuffle()
	
	for fish in available_fish:
		if str(fish["type"]) == str(Globals.last_fish_caught):
			continue
		cumulative_weight += fish["probability"]
		if random_roll < cumulative_weight:
			caught_fish = fish
			break

	print("Caught Fish Data:", caught_fish)  # Debugging
	Globals.last_fish_caught = caught_fish["type"]

	Globals.current_fish_type = caught_fish["type"]
	print("Caught fish of type:", caught_fish["type"])

	Globals.is_getting_fished = true
	fish_button.visible = true
	fish_touch.play()
	is_catching = true

func missed_fish():
	Globals.is_getting_fished = false
	fish_button.visible = false
	is_catching = false
	reset_timers()

func caught_fish():
	Globals.is_bait_placed = false
	animator.play("floater_away")
	bait_out.play()
	fish_caught.play()
	reset_timers()

func reset_timers():
	wait_timer = 0.0
	catch_timer = 0.0
