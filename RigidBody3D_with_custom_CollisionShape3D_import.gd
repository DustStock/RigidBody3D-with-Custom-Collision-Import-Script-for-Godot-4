# This script is used to re-import gltf assets to make rigidbody objects with custom collosion meshes.
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
	print(scene.transform)
	
	print("Starting post-import processing.")
	# Ensure there is exactly one child (the main MeshInstance3D)
	if scene.get_child_count() != 1:
		push_error("Scene should have exactly one child.")
		return scene

	# Get the main MeshInstance3D
	var mesh_model = scene.get_child(0)

	# Check if the first child is a MeshInstance3D
	if not mesh_model is MeshInstance3D:
		push_error("Scene's first child should be MeshInstance3D.")
		return scene
	
	# Ensure the MeshInstance3D has at least one MeshInstance3D child
	if mesh_model.get_child_count() < 1:
		push_error("MeshInstance3D should have at least one MeshInstance3D child.")
		return scene
	
	# Check if the first grandchild is a MeshInstance3D
	if not mesh_model.get_child(0) is MeshInstance3D:
		push_error("MeshInstance3D's first child should be MeshInstance3D.")
		return scene
	
	# Detach the main MeshInstance3D from the scene
	scene.remove_child(mesh_model)
	
	# Create a new RigidBody3D and configure it
	var rigid_body = RigidBody3D.new()
	rigid_body.name = mesh_model.name + "_rigid"
	
	# Add the main MeshInstance3D as a child of the new RigidBody3D
	rigid_body.add_child(mesh_model)
	# Set the owner to the rigid_body to ensure it's saved with the scene
	mesh_model.owner = rigid_body  

	# Iterate through MeshInstance3D children to create individual collision shapes
	for child in mesh_model.get_children():
		if child is MeshInstance3D and child.mesh:
			var mesh_shape = child.mesh.create_convex_shape()
			var collision_shape = CollisionShape3D.new()
			collision_shape.shape = mesh_shape
			# Apply the original mesh child's transform to the collision shape
			collision_shape.transform = child.transform
			# Add the collision shape to the RigidBody3D
			rigid_body.add_child(collision_shape)
			# Set the owner to ensure it's saved with the rigid_body
			collision_shape.owner = rigid_body
			print("Added CollisionShape3D for: ", child.name)
			# Remove the original MeshInstance3D as it's now represented by a collision shape
			child.queue_free()
	
	# Free the original scene root, as it's no longer needed
	scene.queue_free()
	print("Finished setting up RigidBody3D and collision shapes.")
	# Return the new root node (RigidBody3D) to replace the original scene root
	return rigid_body
