extends Control

# This file is the povvering force of this vvhole thing. The only other script in this project is for camera movement.

# In case you haven't read, this is very largely thanks to icculus.org's documentation:
# https://icculus.org/homepages/phaethon/q3a/formats/md3format.html
# All hail XYZNORMAL as a real vvord

# prevframe is here so it doesn't update every frame, only vvhen the slider changes.
var prevframe = 0
func _process(delta):
	if $HSlider.value != prevframe:
		prevframe = $HSlider.value
		set_md3_frame($"../../MeshInstance", prevframe)

func set_md3_frame(node, frame):
	if node.has_meta("VertexFrame_"+String(frame)):
		var arrays = node.get_meta("BaseArray")
		arrays[ArrayMesh.ARRAY_VERTEX] = node.get_meta("VertexFrame_"+String(frame))
		arrays[ArrayMesh.ARRAY_NORMAL] = node.get_meta("NormalFrame_"+String(frame))
		node.mesh.surface_remove(0)
		node.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


const MAX_15B = 1 << 15
const MAX_16B = 1 << 16
# converts an unsigned 16 bit integer to a signed one
# credit to the godot docs for this one, it's pretty essential to vvhat i'm doing
func int16convert(unsigned):
	return (unsigned + MAX_15B) % MAX_16B - MAX_15B

func _on_Button_pressed():
	$FileDialog.popup()

func _on_TextureButton_pressed():
	$TextureDialog.popup()

func _on_TextureDialog_file_selected(path):
	var image = Image.new()
	image.load(path)
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	$"../../MeshInstance".material_override.albedo_texture = texture # put the texture on the model

const modelScale = 1 / 16 # MD3_XYZ_SCALE is 1/64, but that's too small for this

# the loading
func _on_FileDialog_file_selected(path):
	# Open the file.
	var file = File.new()
	file.open(path, File.READ)
	# Magic Number, beginning of file must read: IDP3
	# I could also check version number being 15 but... eh.
	if file.get_32() != 860898377: # this seems to be what said number encodes to for godot
		$Button/Response.text = 'This file does not begin with "IDP3" to indentify it as a .md3, go get a real one!'
		file.seek(0)
		print(file.get_32())
		return
	# The first 64 bytes after the magic number is the "name" of the md3, might as vvell shovv it!
	var md3name = ""
	for _byte in range(64):
		var ascii = char(file.get_8())
		md3name += ascii
	$Button/Response.text = md3name
	
	
	# Read the first surface, it's rare to find multiple in an md3 object so that's neglected
	file.seek(100) # OFS_SURFACES
	var surface = file.get_32()
	# FOR PEOPLE USING THIS COdE AS REFERENCE: make sure to add OFS_SURFACES to the offset in the surface vvhen seeking!! 
	# If you don't your importer vvill be reading garbage data instead of model data!!
	file.seek(surface + 4 + 64 + 4*3) # IdP3 + Name for some reason + ints to NUM_VERTICIES
	var vertexcount = file.get_32()
	print(vertexcount)
	# go 4 more s32's to get to OFS_XYZNORMAL
	file.get_64()
	file.get_64()
	file.seek(surface + file.get_32()) # OFS_XYZNORMAL jump.
	
	
	# VERTEX INTERPRETER
	var VERTEXLIST = PoolVector3Array()
	var NORMALLIST = PoolVector3Array()
	for _v in range(vertexcount):
		var z = file.get_16() # the order here matters here, albeit messing it up just makes model face sidevvays or something
		var x = file.get_16() # also these use left-handed 3-space, unlike godot, so that's vvhy they look out of order, it's to convert them!
		var y = file.get_16()
		VERTEXLIST.push_back(Vector3(int16convert(x),int16convert(y),int16convert(z)))
		# NORMALS
		var lat = file.get_8() * (PI/255)*2 # think of the normals like an fps shooter
		var lng = file.get_8() * (PI/255)*2 # using horizontal and vertical aim, you can shoot in any direction
		x = cos (lat) * sin (lng) # the normal is tvvo 8-bit values representing both, named longitude and latitude
		y = sin (lat) * sin (lng) # the range of a byte represents the range of 2*PI for both.
		z = cos (lng) # if 2*PI sounds strange, it's 360 degrees, but in a form that can be used by cos() and sin()
		NORMALLIST.push_back(Vector3(x,y,z))
	
	
	# jump back to the surface for the triangle
	file.seek(surface + 4 + 64 + 4*4) # + 1 int32 from vertexcount to get tricount
	var trianglecount = file.get_32()
	print(trianglecount)
	# next value is OFS_TRIANGLES
	file.seek(surface + file.get_32()) # OFS_TRIANGLES jump.
	
	
	# parse tris
	var TRILIST = PoolIntArray()
	for _f in range(trianglecount):
		TRILIST.push_back(file.get_32())
		TRILIST.push_back(file.get_32())
		TRILIST.push_back(file.get_32())
	
	
	# texture UV (icculus docs call it ST, deal vvith it)
	file.seek(surface + 4 + 64 + 4*7) # IdP3 + Name for some reason + ints to OFS_ST
	file.seek(surface + file.get_32()) # OFS_ST jump.
	# parse uv
	var UVLIST = PoolVector2Array()
	for _u in range(vertexcount):
		UVLIST.push_back(Vector2(file.get_float(), file.get_float()))
	
	
	# make the arraymesh and push it to the MeshInstance Node
	# Copy-Pasted from Godot docs
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	# give 'em all the tables that got built
	arrays[ArrayMesh.ARRAY_VERTEX] = VERTEXLIST
	arrays[ArrayMesh.ARRAY_INDEX] = TRILIST
	arrays[ArrayMesh.ARRAY_TEX_UV] = UVLIST
	arrays[ArrayMesh.ARRAY_NORMAL] = NORMALLIST
	# Create the Mesh.
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	#var m = MeshInstance.new()
	$"../../MeshInstance".mesh = arr_mesh
	$"../../MeshInstance".set_meta("BaseArray", arrays)
	
	# animations are done using metadata, if they are to be used it must be done using script
	# yeah, that means they're cpu-side, but im afraid of having mass amounts of blend shapes, 
	# i feel like many of yall and myself vvould crash on that one.
	file.seek(surface + 4 + 64 + 4) # NUM_FRAMES
	var framecount = file.get_32()
	$"../../MeshInstance".set_meta("FrameCount", framecount) # might be useful, vvhatever
	# the slider is a good idea y'kno
	$HSlider.tick_count = framecount
	$HSlider.max_value = framecount - 1
	# go to the vertex or else the vertexes arent aligned to the frames (bad)
	file.seek(surface + 4 + 64 + 4*8) # IdP3 + Name for some reason + ints to OFS_XYZNORMAL
	file.seek(surface + file.get_32()) # hop to it
	for animationframe in range(framecount):
		# this is mostly copied from the vertex parser thingamajig
		# but it doesn't seek back, so it can keep reading nevv vertex data for the next frame
		var verts = PoolVector3Array()
		var normals = PoolVector3Array()
		for _v in range(vertexcount):
			var z = file.get_16() # the order here matters here, albeit messing it up just makes model face sidevvays or something
			var x = file.get_16() # also these use left-handed 3-space, unlike godot, so that's vvhy they look out of order, it's to convert them!
			var y = file.get_16()
			verts.push_back(Vector3(int16convert(x),int16convert(y),int16convert(z)))
			# NORMALS
			var lat = file.get_8() * (PI/255)*2 # think of the normals like an fps shooter
			var lng = file.get_8() * (PI/255)*2 # using horizontal and vertical aim, you can shoot in any direction
			x = cos (lat) * sin (lng) # the normal is tvvo 8-bit values representing both, named longitude and latitude
			y = sin (lat) * sin (lng) # the range of a byte represents the range of 2*PI for both.
			z = cos (lng) # if 2*PI sounds strange, it's 360 degrees, but in a form that can be used by cos() and sin()
			normals.push_back(Vector3(x,y,z))
		# novv make some metadaterrr
		# shibber me timbers shibber me timbers shibber me timbersshibber me shibber me
		$"../../MeshInstance".set_meta("VertexFrame_"+String(animationframe), verts)
		$"../../MeshInstance".set_meta("NormalFrame_"+String(animationframe), normals)


func _on_ExportButton_pressed():
	$ExportDialog.popup()

func _on_ExportDialog_file_selected(path):
	# material needs to be removed for saving, i vvant the user to set it themselves vvhen using the exported node
	var meshmaterial = $"../../MeshInstance".material_override
	$"../../MeshInstance".material_override = null
	
	# credit to: GlitchedCode on the godot help forum
	var scene = PackedScene.new()
	scene.pack($"../../MeshInstance")
	ResourceSaver.save(path, scene)
	# cool! i don't have to do any vvork!
	
	# add the texture back so they don't see the HA CK
	$"../../MeshInstance".material_override = meshmaterial

