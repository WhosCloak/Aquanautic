extends HSlider

@onready var label: Label = $"../Label"

func _ready() -> void:
	_on_value_changed(self.value)

func _on_value_changed(slider_value: float) -> void:
	GlobalWorldEnvironment.environment.adjustment_brightness = slider_value
	label.text = str(snapped(slider_value, 1)) + "%" 
