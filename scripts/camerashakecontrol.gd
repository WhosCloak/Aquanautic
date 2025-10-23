extends Control

@onready var shake_slider: HSlider = $shake_slider
@onready var strength_label: Label = $strength_label

func _ready() -> void:
	_on_shake_slider_value_changed(shake_slider.value)

func _on_shake_slider_value_changed(value: float) -> void:
	Global.randomstrength = shake_slider.value
	strength_label.text = str(snapped(value, 1))
