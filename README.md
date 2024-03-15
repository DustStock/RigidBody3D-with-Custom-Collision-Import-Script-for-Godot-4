This script is used to re-import gltf assets to make rigidbody objects with custom collosion meshes.

Your gltf should have exactly one mesh with multiple children
The root mesh is used for the MeshInstance3D of the RigidBody3D
the child meshes are turned into CollisionShape3Ds for the RigidBody3D

To use:
1) Import gltf normally into Godot 4
2) Select the resource in the FileSystem pane
3) Select the Import pane
4) Scroll down and load this script as the "Import Script"
5) Select re-import
