extends Label

# Adjustable parameters
@export var typing_speed: float = 0.05 # Seconds between each character
@export var typing_sound: AudioStream # Reference to the sound stream for typing

var full_text: String = "" # Stores the complete text to display
var current_index: int = 0 # Current position in the text
var is_typing: bool = false # State to prevent overlapping animations

# Typing sound container
var sound_players: Array = []

func _ready() -> void:
	# Prepopulate a pool of AudioStreamPlayer nodes
	for i in range(10):  # Pool size (adjust if needed)
		var player = AudioStreamPlayer.new()
		player.stream = typing_sound
		add_child(player)
		sound_players.append(player)

func set_typing_text(base_text: String, variable_text: String) -> void:
	if is_typing:
		return
	full_text = base_text + variable_text
	current_index = 0
	text = "" # Start with an empty text
	is_typing = true
	call_deferred("_type_letter")

# Incrementally type each letter
func _type_letter() -> void:
	if current_index < full_text.length():
		text += full_text[current_index]
		_play_typing_sound()
		current_index += 1
		await get_tree().create_timer(typing_speed).timeout
		_type_letter() # Call next letter
	else:
		is_typing = false # Done typing

func _play_typing_sound() -> void:
	for player in sound_players:
		if not player.playing:
			player.play()
			return
