# **THIS REPOSITORY IS FOR GODOT 3**
If you want to use this for Godot 4, try using the converter by opening up a Godot 3 project with the exported scene.


Credit to [icculus.org](https://icculus.org/homepages/phaethon/q3a/formats/md3format.html) for their excellent .md3 documentation, as much trouble as I had understanding it as a certified idiot.

As for who __I__ am, I'm NeonSRB2, and I refuse to switch to blender to the point of making this thing.


## Comet Md3 Tool
![look mom its a sonis and knuckle reference omgggggggggg](https://raw.githubusercontent.com/NeonSRB2/CometMd3Tool/main/icon.png)


Not really a fancy name, but it'll do.
This is mainly meant to help for mm3d users, as I don't think there's been a way to put those animations into godot before. Now all you have to do is export to .md3, export to a scene, instance it, and give it a material.
The animations can be read as the tool's UI states, but the tool has a function to set the frame the model uses, so here it is:
```
func set_md3_frame(node, frame):
	if node.has_meta("VertexFrame_"+String(frame)):
		var arrays = node.get_meta("BaseArray")
		arrays[ArrayMesh.ARRAY_VERTEX] = node.get_meta("VertexFrame_"+String(frame))
		arrays[ArrayMesh.ARRAY_NORMAL] = node.get_meta("NormalFrame_"+String(frame))
		node.mesh.surface_remove(0)
		node.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
```
This definitley looks rather expensive, but in my testing it didn't seem to make much of an impact on performance, especially considering the number of animated objects you'd expect in a standard scene.
The big cost these things could introduce is memory, and about the only way to mitigate that is reintroducing the compression used to store the normals, but that might make updating the animation much slower.
I also suggest putting these in .scn files instead of .tscn files, since not only would it prevent mistaking it for a normal scene, it'd be a smaller file, and I wouldn't suggest opening these in a text editor either...


There's a couple more metadatas the tool saves than listed, as the previous code implied.

`"BaseArray"`: .md3s are loaded by the tool as ArrayMeshes, this is the array used to make their surfaces, and it's required if you're going to reconstruct the surface (like the function does to update the verticies)

`"FrameCount"`: The number of frames in the model, this might be good if you need a single looping animation done through script.


As for non-Godot users, the code is meant to be more readable to put extra context behind others trying to implement any .md3 readers into their stuff, though I apologize for the vv and not so much for being very unfunny.
As general advice, try to read something you know the value of, and then if it vvorks you know at least one more thing about the file API you're using.
Also make dead sure that you include the offsets to the pointers in the files. All of the ones in surfaces are relative to the start of the Surface. (aka the pointer you used to get to it or the `"IDP3"` at the beginning of one) That one got me for a while...
