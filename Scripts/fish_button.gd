extends TextureButton

@onready var controls = {
	"fish": %Fish1,
	"fish_anim": %AnimatedSprite2D,
	"label": %FishNameLabel,
	"label2": %FishSizeLabel,
	"book_button": %BookButton,
	"zone_button": %EnvironmentButton,
	"fishrod": get_node("/root/Game/Level/Rod")
}

var wait_target_time: float = 8.0
var wait_timer: float = 0.0
var is_waiting: bool = false

var caught_fish_data = {
	"name": "",
	"size": 0,
	"fact": "",
	"habitat": ""
}

func _physics_process(delta: float) -> void:
	if self.button_pressed:
		_handle_fish_catch()

	if is_waiting:
		_update_wait_timer(delta)

func _handle_fish_catch() -> void:
	# Hide button and reset fishing state
	self.visible = false
	controls["fishrod"].caught_fish()
	controls["fishrod"].is_catching = false

	# Retrieve fish data
	var fish_id = Globals.current_fish_type
	caught_fish_data["name"] = Globals.get_fish_name(fish_id)
	caught_fish_data["fact"] = Globals.get_fish_fact(fish_id)
	caught_fish_data["size"] = Globals.get_random_fish_size(fish_id)
	caught_fish_data["habitat"] = Globals.get_fish_habitat(fish_id)

	# Save caught fish in encyclopedia
	Globals.add_fish_to_encyclopedia(int(fish_id), caught_fish_data["size"])

	# Display the caught fish
	_show_caught_fish_ui()

	# Start waiting timer
	is_waiting = true

func _update_wait_timer(delta: float) -> void:
	wait_timer += delta
	if wait_timer >= wait_target_time:
		_reset_waiting_state()

func _reset_waiting_state() -> void:
	wait_timer = 0.0
	is_waiting = false

	# Reset UI and fish state
	controls["fish"].visible = false
	controls["book_button"].visible = true
	controls["zone_button"].visible = true
	controls["fish_anim"].stop()

	# Reset global states
	Globals.is_fish_biggest = false
	await get_tree().create_timer(0.2).timeout
	Globals.is_getting_fished = false

func _show_caught_fish_ui() -> void:
	controls["fish"].visible = true
	controls["book_button"].visible = false
	controls["zone_button"].visible = false
	controls["fish_anim"].play(caught_fish_data["name"])

	# Update labels with typing effect
	var article = get_article(caught_fish_data["name"])
	controls["label"].set_typing_text("You caught %s " % article, caught_fish_data["name"])

	if Globals.is_fish_biggest:
		controls["label2"].set_typing_text("!! New biggest !! : ", str(caught_fish_data["size"]) + " cm")
	else:
		controls["label2"].set_typing_text("Fish size : ", str(caught_fish_data["size"]) + " cm")

func get_article(word: String) -> String:
	return "an" if word.left(1).to_upper() in ["A", "E", "I", "O", "U"] else "a"

func _unhandled_input(event):
	if is_waiting and event.is_action_pressed("touch"):
		await get_tree().create_timer(0.1).timeout
		_reset_waiting_state()
