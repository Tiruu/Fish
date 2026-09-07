extends TextureButton

# Declaring @onready variables
@onready var controls = {
	"close_button": %CloseButton,
	"achiev_button": %AchievButton,
	"fish_book": %FishBook,
	"env_button": %EnvironmentButton,
	"book_anim": %BookAnim,
	"book_sound": %BookSound,
	"fish": %Fish2,
	"fish_anim": %AnimatedSprite2D2,
	"label": %Label2,
	"label2": %Label3,
	"zone_label": %ZoneLabel,
	"detail_container1": %DetailContainer,
	"detail_container2": %DetailContainer2,
	"zone_container": %ZoneContainer,
	"achievement_container": %AchievementContainer,
	"achievement_container2": %AchievementContainer2,
	"ocean_button": %OceanButton,
	"river_button": %RiverButton,
	"other_button": %OtherButton,
	"player_info": %PlayerInfos
}

var scene = preload("res://Scenes/detail_button.tscn")
var achiev_scene = preload("res://Scenes/achievement_button.tscn")
var button_map = {}
var achievement_button_map = {}

var current_zone_details: String = ""
var current_button_number: int = 1
var current_achievement_button_number: int = 1
var current_page: String = ""

func _ready():
	# Validate all buttons in button_map
	for button in button_map.keys():
		if button == null:
			print("Button not assigned correctly: ", button)

	controls["ocean_button"].connect("pressed", Callable(self, "_on_ocean_button_pressed"))
	controls["river_button"].connect("pressed", Callable(self, "_on_river_button_pressed"))
	controls["other_button"].connect("pressed", Callable(self, "_on_other_button_pressed"))
	controls["close_button"].connect("pressed", Callable(self, "_on_close_button_pressed"))
	controls["achiev_button"].connect("pressed", Callable(self, "_on_achiev_button_pressed"))

# Function to handle ocean button press
func _on_ocean_button_pressed():
	open_zone_details("Ocean")

# Function to handle river button press
func _on_river_button_pressed():
	open_zone_details("River")

# Function to handle other button press
func _on_other_button_pressed():
	open_zone_details("Other")

func _on_achiev_button_pressed():
	open_achievements()
	
func _on_close_button_pressed():
	match current_page:
		"main":
			close_book()
		"zone":
			close_zone_details()
		"fish":
			close_fish_details()
		"achievements":
			close_achievements()

func _process(delta: float) -> void:
	if button_pressed() and not Globals.is_bait_placed:
		open_book()
	
	for button in button_map.keys():
		if button.button_pressed:
			open_fish_details(button_map[button])
			break

func button_pressed() -> bool:
	return self.is_pressed()

func open_book():
	toggle_ui(false)
	controls["fish_book"].visible = true
	animate_and_play_sound("Uping", 0.3, "Open")
	await get_tree().create_timer(0.6).timeout
	controls["zone_container"].visible = true
	controls["close_button"].visible = true
	controls["achiev_button"].visible = true
	controls["player_info"].visible = true
	current_page = "main"
	Globals.is_inside_book = true

	# Recalculate player statistics when the book is opened
	Globals.analyze_fish_data()

	# Update the player info text
	controls["player_info"].text = "\n---Player records---\n\n\n-Total number of catch-\n\n" + \
		(str(Globals.total_count) if Globals.total_count > 0 else "None") + \
		"\n\n\n-Most caught fish-\n\n" + \
		(Globals.most_caught_fish if Globals.most_caught_fish != "" else "None") + \
		" (" + (str(Globals.highest_count) if Globals.highest_count > 0 else "None") + ")" + \
		"\n\n\n-Least caught fish-\n\n" + \
		(Globals.least_caught_fish if Globals.least_caught_fish != "" else "None") + \
		" (" + (str(Globals.lowest_count) if Globals.lowest_count < INF else "None") + ")"

func close_book():
	toggle_ui(true)
	controls["zone_container"].visible = false
	controls["close_button"].visible = false
	controls["achiev_button"].visible = false
	controls["player_info"].visible = false
	animate_and_play_sound("Close", 0.3, "Downing", controls["fish_book"], false, true)
	current_page = ""
	Globals.is_inside_book = false

func open_zone_details(current_zone: String):
	current_zone_details = current_zone
	controls["zone_container"].visible = false
	controls["player_info"].visible = false
	controls["achiev_button"].visible = false
	controls["detail_container1"].visible = true
	controls["detail_container2"].visible = true
	current_page = "zone"
	animate_and_play_sound("", 0, "")
	set_button_active()
	
func close_zone_details():
	current_zone_details = "None"
	controls["zone_container"].visible = true
	controls["player_info"].visible = true
	controls["achiev_button"].visible = true
	controls["detail_container1"].visible = false
	controls["detail_container2"].visible = false
	current_page = "main"
	animate_and_play_sound("", 0, "")
	reset_buttons_for_habitat()

func open_fish_details(fish_type: String):
	Globals.is_inside_details = true
	controls["fish_anim"].play()
	animate_and_play_sound("", 0, "")  # Just play sound with no animation
	controls["detail_container1"].visible = false
	controls["detail_container2"].visible = false
	controls["fish"].visible = true
	current_page = "fish"

	# Find the fish_id that matches fish_type
	var fish_id: int = -1
	for id in Globals.fish_data.keys():
		if Globals.fish_data[id].get("name", "") == fish_type:
			fish_id = int(id)
			break  # Found the correct fish, exit loop
	if fish_id == -1:
		print("Error: Fish ID not found for ", fish_type)
		return
	
	 # Now fetch and display the correct fish data
	controls["fish_anim"].play(fish_type)
	controls["label"].text = "Species : %s\n\nTimes caught : %d\n\nBiggest catch : %scm\n\nHabitat : %s" % [
		fish_type,
		Globals.get_fish_catch_count(fish_id),
		Globals.get_fish_record(fish_id),
		Globals.get_fish_habitat(fish_id)
	]
	controls["label2"].text = Globals.get_fish_fact(fish_id)
	
func close_fish_details():
	Globals.is_inside_details = false
	controls["fish_anim"].stop()
	animate_and_play_sound("", 0, "")  # Just play sound with no animation
	controls["detail_container1"].visible = true
	controls["detail_container2"].visible = true
	controls["fish"].visible = false
	current_page = "zone"
	
func open_achievements():
	Globals.verify_achievement_conditions()
	controls["zone_container"].visible = false
	controls["player_info"].visible = false
	controls["achiev_button"].visible = false
	controls["achievement_container"].visible = true
	controls["achievement_container2"].visible = true
	current_page = "achievements"
	animate_and_play_sound("", 0, "")
	set_achievement_button_active()

func close_achievements():
	controls["zone_container"].visible = true
	controls["player_info"].visible = true
	controls["achiev_button"].visible = true
	controls["achievement_container"].visible = false
	controls["achievement_container2"].visible = false
	current_page = "main"
	animate_and_play_sound("", 0, "")
	reset_buttons_for_achievement()

func toggle_ui(visible: bool):
	self.visible = visible
	controls["env_button"].visible = visible
	controls["zone_label"].visible = visible

func animate_and_play_sound(
		anim_name: String,
		delay: float,
		anim_after: String,
		final_visibility: Node = null,
		visibility: bool = true,
		play_sound_early: bool = false
	):
	# Play the sound early if specified
	if play_sound_early:
		controls["book_sound"].pitch_scale = randf_range(0.8, 1.2)
		controls["book_sound"].play()

	# Play the first animation if provided
	if anim_name != "":
		controls["book_anim"].play(anim_name)
		await get_tree().create_timer(delay).timeout

	# Play the second animation if provided
	if anim_after != "":
		controls["book_anim"].play(anim_after)

	# Update final visibility if applicable
	if final_visibility:
		await get_tree().create_timer(0.3).timeout
		final_visibility.visible = visibility

	# Play sound (fallback for later play)
	if not play_sound_early:
		controls["book_sound"].pitch_scale = randf_range(0.8, 1.2)
		controls["book_sound"].play()

func reset_buttons_for_habitat():
	# First, clear all the buttons from the container before adding new ones
	var target_container = get_target_container()
	if target_container:
		for button in button_map.keys():
			# Remove buttons that belong to the current habitat
			if button.is_inside_tree():
				button.queue_free()  # De-instantiate the button
		button_map.clear()  # Clear the button map after removal
		
	current_button_number = 1
	print("Button count reset to 0.")

func reset_buttons_for_achievement():
	# First, clear all the buttons from the container before adding new ones
	var target_container = get_achievement_container()
	if target_container:
		for button in achievement_button_map.keys():
			# Remove buttons that belong to the current habitat
			if button.is_inside_tree():
				button.queue_free()  # De-instantiate the button
		achievement_button_map.clear()  # Clear the button map after removal
	# Reset the button count
	current_achievement_button_number = 1
	print("Button count reset to 0.")

func set_button_active():
	# Only add buttons for the selected habitat
	for fish_id in Globals.saved_fish_data.keys():
		var fish_name = Globals.get_fish_name(int(fish_id))
		if (int(fish_id) == -1):
			print("Error: Fish type", fish_id, "not found in fish_data.json!")
			continue

		var habitat = Globals.get_fish_habitat(int(fish_id))
		
		if habitat == ("Ocean"):
			pass
		elif habitat == ("River"):
			pass
		else:
			habitat = "Other"
		
		# Only show buttons for the selected habitat
		if habitat != current_zone_details:
			continue  # Skip if the habitat doesn't match the selected one

		var target_container = get_target_container()
		if not target_container:
			print("Unknown habitat for:", fish_name, "with habitat:", habitat)
			continue

		# Check if the button already exists in the container
		if target_container.has_node(fish_name):
			print(fish_id, "button already exists in the container, skipping.")
			continue

		# Instantiate the new button
		var button = scene.instantiate()
		current_button_number += 1
		button.name = fish_name
		var label = button.get_node("Label")
		if label:
			label.text = fish_name
		target_container.add_child(button)
		button_map[button] = fish_name
		print("Added button for:", fish_name)
		
func set_achievement_button_active():
	# Loop through the achievements stored in Globals (or similar)
	for achievement in Globals.achievement_data.keys():  # Assume Globals.saved_achievements holds the data
		var achievement_data = Globals.achievement_data[achievement]
		var saved_achievement_data = Globals.saved_achievement_data.get(str(achievement), {})
		
		# Extract achievement details
		var achievement_id = int(achievement)
		var achievement_title = achievement_data.get("title", "Unknown achievement")
		var achievement_text = achievement_data.get("description", "No description")
		var is_unlocked = saved_achievement_data.get("unlocked", false)
		var is_hidden = achievement_data.get("hidden", false)

		# Skip if no valid ID
		if achievement_id == -1:
			print("Error: Achievement ID for", achievement_title, "is invalid!")
			continue

		# Get the target container for buttons
		var target_container = get_achievement_container()
		if not target_container:
			print("Error: Target container not found!")
			continue

		# Check if the button already exists
		if target_container.has_node("Achievement_" + str(achievement_title)):
			print("Button for achievement", achievement_title, "already exists, skipping.")
			continue
		
		# Instantiate the new button
		var button = achiev_scene.instantiate()  # Replace `achiev_scene` with your actual button scene variable
		current_achievement_button_number += 1
		print(current_achievement_button_number)
		button.name = "Achievement_" + str(achievement_id)
		
		# Set labels based on achievement state
		var label = button.get_node("Label")
		var label2 = button.get_node("Label2")
		#var label3 = button.get_node("Label3")
		
		
		if is_unlocked and not is_hidden:
			# If the achievement is unlocked, show full details
			if label:
				label.text = achievement_title
			if label2:
				label2.text = achievement_text
		elif is_unlocked and is_hidden:
			# If the achievement is unlocked, show full details
			if label:
				label.text = achievement_title
				label.label_settings.font_color = Color(243 / 255.0, 171 / 255.0, 32 / 255.0)
			if label2:
				label2.text = achievement_text
				label2.label_settings.font_color = Color(243 / 255.0, 171 / 255.0, 32 / 255.0)
		elif not is_unlocked and not is_hidden:
			# If the achievement is unlocked, show full details
			if label:
				label.text = "???"
				label.label_settings.font_color = Color(0.5, 0.5, 0.5)
			if label2:
				label2.text = achievement_text
				label2.label_settings.font_color = Color(0.5, 0.5, 0.5)
		elif not is_unlocked and is_hidden:
			# If the achievement is unlocked, show full details
			if label:
				label.text = "???"
				label.label_settings.font_color = Color(0.5, 0.5, 0.5)
			if label2:
				label2.text = "???"
				label2.label_settings.font_color = Color(0.5, 0.5, 0.5)

		# Add the button to the container
		target_container.add_child(button)
		achievement_button_map[button] = achievement

func get_target_container() -> GridContainer:
	# Return the container where all buttons will go (assuming same container for ocean, river, and others)
	return controls["detail_container1"] if current_button_number <= 16 else controls["detail_container2"]
	
func get_achievement_container() -> GridContainer:
	# Return the container where all buttons will go (assuming same container for ocean, river, and others)
	return controls["achievement_container"] if current_achievement_button_number <= 7 else controls["achievement_container2"]
