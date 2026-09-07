extends Node

# Global variables for fishing and encyclopedia
var is_getting_fished: bool = false
var is_bait_placed: bool = false
var is_inside_book: bool = false
var is_inside_details: bool = false

var current_fish_type: int
var current_fishing_zone: String = "ocean"

var saved_fish_data: Dictionary = {}  # Stores player progress (caught fish)
var fish_data: Dictionary = {}  # Stores fish info from JSON (static data)
var achievement_data: Dictionary = {}
var saved_achievement_data: Dictionary = {}

var total_count: int = 0
var most_caught_fish: String = ""
var least_caught_fish: String = ""
var highest_count:int = 0
var lowest_count = INF

var is_fish_biggest: bool = false
var last_fish_caught: int = 0

@onready var fish_type: String = ""

# File paths for saving and loading data
const FISH_SAVE_FILE_PATH: String = "user://fish_save_data.json"
const ACHIEV_SAVE_FILE_PATH: String = "user://achievements_save_data.json"
const FISH_JSON_PATH: String = "res://fish_data.json"
const ACHIEV_JSON_PATH: String = "res://achievements_data.json"

func _ready():
	load_fish_save_data()
	load_fish_data()
	load_achievement_save_data()
	load_achievement_data()
	print(saved_achievement_data)
	print(saved_fish_data)
	
#Load fish info from fish_data.json (static data)
func load_fish_data():
	if FileAccess.file_exists(FISH_JSON_PATH):
		var file = FileAccess.open(FISH_JSON_PATH, FileAccess.READ)
		if file:
			var json_parser = JSON.new()
			var parse_result = json_parser.parse(file.get_as_text())
			if parse_result == OK and typeof(json_parser.data) == TYPE_DICTIONARY:
				fish_data = json_parser.data
				print("Fish data loaded successfully")
			else:
				print("Error: Failed to parse fish_data.json!")
			file.close()
	else:
		print("Error: fish_data.json not found!")
		
func load_achievement_data():
	if FileAccess.file_exists(ACHIEV_JSON_PATH):
		var file = FileAccess.open(ACHIEV_JSON_PATH, FileAccess.READ)
		if file:
			var json_parser = JSON.new()
			var parse_result = json_parser.parse(file.get_as_text())
			if parse_result == OK and typeof(json_parser.data) == TYPE_DICTIONARY:
				achievement_data = json_parser.data
				print("Achievements data loaded successfully")
			else:
				print("Error: Failed to parse achievement_data.json!")
			file.close()
	else:
		print("Error: achievement_data.json not found!")

func is_fish_caught(fish_id: int) -> bool:
	return saved_fish_data.get(str(fish_id), { "caught": false })["caught"]

func get_fish_name(fish_id: int) -> String:
	return fish_data.get(str(fish_id), {}).get("name", "Unknown Fish")

func get_fish_fact(fish_id: int) -> String:
	return fish_data.get(str(fish_id), {}).get("fact", "No fact available.")

func get_fish_habitat(fish_id: int) -> String:
	if fish_data.has(str(fish_id)):
		var habitat_data = fish_data[str(fish_id)]["habitat"]
		
		# If it's already a string, return it directly
		if habitat_data is String:
			return habitat_data
		
		# If it's an array, join the elements with ", "
		elif habitat_data is Array:
			return ", ".join(PackedStringArray(habitat_data))
		
	return "Unknown Habitat"

func get_fish_record(fish_id: int) -> float:
	return saved_fish_data.get(str(fish_id), { "size": 0.0 })["size"]

func get_fish_catch_count(fish_id: int) -> int:
	return saved_fish_data.get(str(fish_id), { "count": 0 })["count"]

func get_random_fish_size(fish_id: int) -> float:
	var fish = fish_data.get(str(fish_id), {})
	var min_size = fish.get("min_size", 5.0)  # Default min size if not found
	var max_size = fish.get("max_size", 15.0)  # Default max size if not found
	
	# Generate a random number in the range [0, 1]
	var rand_value = randf()
	
	# Apply a quadratic curve to skew the value towards the min_size
	var skewed_value = min_size + (max_size - min_size) * pow(rand_value, 1)  # Squaring the random value makes it more biased towards min_size
	
	return snapped(skewed_value, 0.01)

func add_fish_to_encyclopedia(fish_id: int, size: float):
	# Get fish details
	var fish_name = get_fish_name(fish_id)
	print(fish_name)
	var fish_fact = get_fish_fact(fish_id)
	print(fish_fact)
	var fish_habitat = get_fish_habitat(fish_id)
	print(fish_habitat)

	if fish_name == "Unknown Fish":
		print("Error: Fish ID", fish_id, "not found in fish_data.json!")
		return  # Prevent saving unknown fish
	
	print(saved_fish_data)
	if str(fish_id) in saved_fish_data:
		print(fish_id)
		# Increase count of times caught
		saved_fish_data[str(fish_id)]["count"] += 1
		print(saved_fish_data[str(fish_id)]["count"])

		# Update record if the new size is larger
		if size > saved_fish_data[str(fish_id)]["size"]:
			saved_fish_data[str(fish_id)]["size"] = size
			saved_fish_data[str(fish_id)]["biggest"] = true  # Add a "biggest" flag if relevant

		# Update fact only if it's different
		if fish_fact != saved_fish_data[str(fish_id)].get("fact", ""):
			saved_fish_data[str(fish_id)]["fact"] = fish_fact

		# Update habitat if it's different
		if fish_habitat != saved_fish_data[str(fish_id)].get("habitat", ""):
			saved_fish_data[str(fish_id)]["habitat"] = fish_habitat
	else:
		# Add new entry for this fish
		saved_fish_data[str(fish_id)] = {
			"name": fish_name,
			"caught": true,
			"size": size,
			"count": 1,
			"fact": fish_fact,
			"habitat": fish_habitat,
		}

	save_data()  # Save progress

func analyze_fish_data() -> void:
	total_count = 0
	highest_count = 0
	lowest_count = INF  # Reset to a very high number for comparison
	most_caught_fish = ""
	least_caught_fish = ""

	# Iterate through the saved fish data
	for fish_id in saved_fish_data.keys():
		var fish_info = saved_fish_data[str(fish_id)]
		var fish_name = fish_info.get("name", "Unknown fish")
		var count = fish_info.get("count", 0)
		
		# Add to total count
		total_count += count

		# Check for most caught fish
		if count > highest_count:
			highest_count = count
			most_caught_fish = fish_name

		# Check for least caught fish (ensure caught is true)
		# Update if:
		# 1. The current count is less than the lowest_count
		# 2. The current fish is caught
		if fish_info.get("caught", false) and count <= lowest_count:
			lowest_count = count
			least_caught_fish = fish_name

	# Print or return the results
	print("Total fish caught: ", total_count)
	print("Most caught fish: ", most_caught_fish, " with ", highest_count, " catches")
	print("Least caught fish: ", least_caught_fish, " with ", lowest_count, " catches")

func verify_achievement_conditions():
	# Check total fish count for "Fishing Amateur" achievement
	if total_count >= 100:
		add_achievement_to_encyclopedia(1)
	if total_count >= 200:
		add_achievement_to_encyclopedia(2)
	if total_count >= 500:
		add_achievement_to_encyclopedia(3)
	if total_count >= 1000:
		add_achievement_to_encyclopedia(4)

	# Check if at least one of every fish has been caught
	var all_fish_caught = true  # Assume all fish are caught, prove otherwise
	for fish_id in fish_data.keys():
		var fish_name = fish_data[fish_id].get("name", "")
		if fish_name == "":
			continue  # Skip invalid entries
		if fish_name == "Long Mec":
			continue
		if fish_name == "Amungos":
			continue

		# Check if the fish exists in saved data and has been caught at least once
		var fish_info = saved_fish_data.get(fish_name, { "count": 0 })
		if fish_info.get("count", 0) < 1:
			all_fish_caught = false
			break  # If any fish is not caught, exit early

	if all_fish_caught:
		add_achievement_to_encyclopedia(7)
	
	var car_tire_data = saved_fish_data.get("Car Tire", { "count": 0 })
	if car_tire_data.get("count", 0) >= 4:
		add_achievement_to_encyclopedia(8)

	var longmec_data = saved_fish_data.get("Long Mec", { "count": 0 })
	if longmec_data.get("count", 0) >= 1:
		add_achievement_to_encyclopedia(6)
		
	var amungos_data = saved_fish_data.get("Amungos", { "count": 0 })
	if amungos_data.get("count", 0) >= 1:
		add_achievement_to_encyclopedia(5)
		
	var anchovy_data = saved_fish_data.get("European Anchovy", { "count": 0 })
	if anchovy_data.get("count", 0) >= 100:
		add_achievement_to_encyclopedia(9)

func get_achievement_title(achievement_id: int) -> String:
	return achievement_data.get(str(achievement_id), {}).get("title", "Unknow achievement")

func get_achievement_desc(achievement_id: int) -> String:
	return achievement_data.get(str(achievement_id), {}).get("description", "No description")
	
func get_achievement_hidden(achievement_id: int) -> bool:
	return achievement_data.get(str(achievement_id), {}).get("hidden", false)

func get_achievement_unlocked(achievement_id: int) -> bool:
	var achievement_title = get_achievement_title(achievement_id)
	print("saved achievement data ", saved_achievement_data)
	return saved_achievement_data.get(achievement_title, { "unlocked": false })["unlocked"]

func add_achievement_to_encyclopedia(achievement_id: int):
	var achievement_title = get_achievement_title(achievement_id)
	var achievement_desc = get_achievement_desc(achievement_id)
	var achievement_hidden = get_achievement_hidden(achievement_id)

	# Prevent saving an unknown achievement
	if achievement_title == "Unknown Achievement":
		print("Error: Achievement ID", achievement_id, "not found in achievement_data!")
		return  

	# Convert the achievement_id to a string for consistency
	var achievement_key = str(achievement_id)

	# Ensure the achievement ID exists in the dictionary
	if achievement_key in saved_achievement_data:
		# Update only if the description has changed
		if achievement_desc != saved_achievement_data[achievement_key].get("description", ""):
			saved_achievement_data[achievement_key]["description"] = achievement_desc
	else:
		# Create a new achievement entry under the correct ID
		saved_achievement_data[achievement_key] = {
			"title": achievement_title,
			"description": achievement_desc,
			"unlocked": true,
			"hidden": achievement_hidden
		}

	# Save the updated achievements back to file
	save_achievement_data()

#Save player progress to a file
func save_data():
	if saved_fish_data.is_empty():
		print("Warning: No data to save.")
		return

	var file = FileAccess.open(FISH_SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var serialized_data = JSON.stringify(saved_fish_data, "\t")  # Pretty format for debugging
		file.store_string(serialized_data)
		file.close()

# Save achievements progress to a file
func save_achievement_data():
	if saved_achievement_data.is_empty():
		print("Warning: No achievements to save.")
		return

	var file = FileAccess.open(ACHIEV_SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var serialized_data = JSON.stringify(saved_achievement_data, "\t")  # Pretty format for readability
		file.store_string(serialized_data)
		file.close()
		print("Achievements progress saved successfully.")

#Load player progress from a file
func load_fish_save_data():
	if FileAccess.file_exists(FISH_SAVE_FILE_PATH):
		var file = FileAccess.open(FISH_SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			var json_parser = JSON.new()
			var parse_result = json_parser.parse(content)

			if parse_result == OK and typeof(json_parser.data) == TYPE_DICTIONARY:
				saved_fish_data = json_parser.data  # Load saved fish data
			else:
				print("Error: Failed to parse saved data! Resetting fish encyclopedia.")
				saved_fish_data.clear()  # Reset if there's an error

			file.close()
	else:
		print("Save file not found. Starting with empty saved_fish_data.")

# Load achievements progress from a file
func load_achievement_save_data():
	if FileAccess.file_exists(ACHIEV_SAVE_FILE_PATH):
		var file = FileAccess.open(ACHIEV_SAVE_FILE_PATH, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			var json_parser = JSON.new()
			var parse_result = json_parser.parse(content)

			if parse_result == OK and typeof(json_parser.data) == TYPE_DICTIONARY:
				saved_achievement_data = json_parser.data
				print(saved_achievement_data)
			else:
				print("Error: Failed to parse achievements data! Resetting saved achievements.")
				saved_achievement_data.clear()  # Reset if parsing fails

			file.close()
	else:
		print("Achievements file not found. Starting with empty achievement_data.")
