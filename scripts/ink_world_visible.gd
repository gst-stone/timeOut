extends "res://scripts/ink_world_stage.gd"

## Runtime-visible wrapper.
## The original ink stage intentionally used a negative z-index, which put it
## behind MainV2's own opaque _draw(). This wrapper keeps the visual layer
## above the root draw but below the runtime UI and character stages.

func _ready() -> void:
	z_index = 0
	queue_redraw()
