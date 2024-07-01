extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var horizontal = Input.get_axis("ui_left", "ui_right")*PI
	var vertical = Input.get_axis("ui_down", "ui_up")*PI
	rotation.y += horizontal*delta
	rotation.x += vertical*delta
	if Input.is_action_just_pressed("zoom_out"):
		scale += Vector3.ONE*0.2
	if Input.is_action_just_pressed("zoom_in"):
		scale -= Vector3.ONE*0.2
	if scale.x < 0: # ick, fucked up camera
		scale = Vector3.ZERO
