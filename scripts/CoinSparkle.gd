extends AnimatedSprite2D

@onready var sfx: AudioStreamPlayer2D = AudioStreamPlayer2D.new()

func _ready():
	# Play sparkle sound
	var sparkle_sound = preload("res://audios/gold_coin_hit1.mp3")
	sfx.stream = sparkle_sound
	add_child(sfx)
	sfx.play()
	
	await animation_finished
	queue_free()
