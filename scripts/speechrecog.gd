extends Node

var client := StreamPeerTCP.new()

func _ready():
	var err = client.connect_to_host("127.0.0.1", 65432)
	if err != OK:
		print("❌ Could not connect to Python server")
	else:
		print("✅ Connected to Python voice server")

func _process(_delta):
	if client.get_status() == StreamPeerTCP.STATUS_CONNECTED and client.get_available_bytes() > 0:
		var msg = client.get_utf8_string(client.get_available_bytes()).strip_edges()
		handle_command(msg)

func handle_command(command: String):
	match command:
		"up", "jump", "forward":
			Input.action_press("up")
		"down":
			Input.action_press("down")
		"left":
			Input.action_press("left")
		"right":
			Input.action_press("right")
		"fire", "shoot":
			Input.action_press("fire")
		_:
			print("⚠️ Unknown command:", command)

	# 👇 release automatically after a short delay (so it behaves like a tap)
	await get_tree().create_timer(0.2).timeout
	match command:
		"up", "jump", "forward":
			Input.action_release("up")
		"down":
			Input.action_release("down")
		"left":
			Input.action_release("left")
		"right":
			Input.action_release("right")
		"fire", "shoot":
			Input.action_release("fire")
