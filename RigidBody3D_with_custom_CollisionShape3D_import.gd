# This script is used to re-import gltf assets to make rigidbody objects with custom collosion meshes.
# It also saves the rigidbody with collisions as a *.tscn in res://
# 
# Your gltf should have exactly one mesh with multiple children
# The root mesh is used for the MeshInstance3D of the RigidBody3D
# the child meshes are turned into CollisionShape3Ds for the RigidBody3D
#
# To use:
# 1) Import gltf normally into Godot 4
# 2) Select the resource in the FileSystem pane
# 3) Select the Import pane
# 4) Scroll down and load this script as the "Import Script"
# 5) Select re-import

@tool # Needed so it runs in the editor.
extends EditorScenePostImport

func _post_import(scene):
	print(scene.name)
	print(scene.transform)
	
	print("Starting post-import processing.")
	# Ensure there is exactly one child (the main MeshInstance3D)
	if scene.get_child_count() != 1:
		push_error("Scene should have exactly one child.")
		return scene

	# Get the main MeshInstance3D
	var mesh_model = scene.get_child(0)

	# Check if the child is a MeshInstance3D
	# This is used for the MeshInstance3D on the imported model
	if not mesh_model is MeshInstance3D:
		push_error("Scene's first child should be MeshInstance3D.")
		return scene
	
	# Check that all granchildren are MeshInstance3D
	# These are used for the convex collision shapes
	for child in mesh_model.get_children():
		if not child is MeshInstance3D and child.mesh:
			push_error("All Grandchildren should be of type MeshInstance3D.")
			return scene
	
	# Detach the main MeshInstance3D from the scene
	mesh_model.set_owner(null) # Seems like this shouldn't need to be here, but it does. Perhaps a bug.
	scene.remove_child(mesh_model) # without the line above, this makes a warning
	
	# Create a new RigidBody3D and configure it
	# This will be the root node of the returned scene
	var rigid_body = RigidBody3D.new()
	rigid_body.name = mesh_model.name + "_rigid"
	
	# Add the main MeshInstance3D as a child of the new RigidBody3D
	rigid_body.add_child(mesh_model)
	mesh_model.set_owner(rigid_body)

	# Iterate through MeshInstance3D children to create individual collision shapes
	for child in mesh_model.get_children():
		var mesh_shape = child.mesh.create_convex_shape()
		var collision_shape = CollisionShape3D.new()
		collision_shape.shape = mesh_shape
		collision_shape.name = child.name + "_collision"
		# Apply the original mesh child's transform to the collision shape
		collision_shape.transform = child.transform
		# Add the collision shape to the RigidBody3D
		rigid_body.add_child(collision_shape)
		# Set the owner to ensure it's saved with the rigid_body # scene
		collision_shape.set_owner(rigid_body)
		print("Added CollisionShape3D for: ", child.name)
		# Remove the original MeshInstance3D as it's now represented by a collision shape
		mesh_model.remove_child(child)
		child.queue_free()
	
	# Free the original scene root, as it's no longer needed
	scene.queue_free()
	
	print("Finished setting up RigidBody3D and collision shapes.")
	
	# Create and save scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(rigid_body)
	var save_path = "res://" + rigid_body.name + ".tscn"
	print("Saving scene... " + save_path)
	ResourceSaver.save(packed_scene, save_path)
	
	return rigid_body
