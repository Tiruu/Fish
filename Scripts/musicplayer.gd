extends AudioStreamPlayer

@onready var dummy_player = AudioStreamPlayer.new()

var fading = false

func _ready() -> void:
	# Add dummy_player to the scene
	add_child(dummy_player)
	# Load and set the initial stream
	dummy_player.stream = load("res://Audio/ocean.mp3")
	dummy_player.stream.loop = true  # Set loop before playback
	play_song("ocean")  # Play the main stream

func _physics_process(delta: float) -> void:
	if fading:
		# Smoothly crossfade the audio streams
		volume_db -= 60 * delta  # Fade out current audio
		dummy_player.volume_db += 60 * delta  # Fade in dummy_player audio
		
		# Check if the crossfade is complete
		if dummy_player.volume_db >= 0:
			# Finalize audio swap
			volume_db = 0
			dummy_player.volume_db = -60
			stream = dummy_player.stream  # Switch main player to dummy stream
			play(dummy_player.get_playback_position())  # Resume new stream
			dummy_player.stop()  # Stop the dummy player
			fading = false  # Stop fading

func play_song(song_name: String) -> void:
	# Load a new stream into dummy_player
	dummy_player.stream = load("res://Audio/" + song_name + ".mp3")
	dummy_player.stream.loop = true  # Ensure the new stream loops
	dummy_player.volume_db = -60  # Start with dummy_player muted
	dummy_player.play()  # Start playing the new stream
	
	fading = true  # Start crossfade process
