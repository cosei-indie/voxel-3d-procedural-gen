extends Node3D

var sphere := preload("res://spawning.tscn")
@export var dirt_scene: PackedScene
@export var sand_scene: PackedScene
@export var stone_scene: PackedScene
@export var water_scene: PackedScene
@export var grass_scene: PackedScene

var noise: Noise
@export var noise_height_text : NoiseTexture2D
@export var chunk_size := 512
@export var chunk_vertical_size := 256
@export var alt_amplifier := 75

var spacing = 1.0
# Displayed meshs array
var displayed_dirt_meshes := []
var displayed_sand_meshes := []
var displayed_grass_meshes := []
var displayed_water_meshes := []
var displayed_stone_meshes := []

# Collision management
var terrain_collision_body := StaticBody3D.new()
var terrain_surface_tool := SurfaceTool.new()

func _process(delta):
	if Input.is_action_pressed("space"):
		var instance = sphere.instantiate()
		instance.global_position = %Camera3D.global_position
		add_child(instance)

func _ready():
	#noise
	noise = noise_height_text.noise
	init_all_multimesh()
	
	add_child(terrain_collision_body)
	terrain_surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	load_chunk(Vector3(0, 0, 0), Vector3(0, 0, 0))
	create_mesh(%DirtGenerator, displayed_dirt_meshes)
	create_mesh(%SandGenerator, displayed_sand_meshes)
	create_mesh(%StoneGenerator, displayed_stone_meshes)
	create_mesh(%WaterGenerator, displayed_water_meshes)
	create_mesh(%GrassGenerator, displayed_grass_meshes)
	var col_mesh = terrain_surface_tool.commit()
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(col_mesh.get_faces())

	var col_shape = CollisionShape3D.new()
	col_shape.shape = shape
	terrain_collision_body.add_child(col_shape)

func create_mesh(multiMeshInst: MultiMeshInstance3D, arr: Array):
	multiMeshInst.multimesh.instance_count = arr.size()
	var index = 0
	for coor in arr:
		var xform = Transform3D.IDENTITY
		xform.origin = coor
		multiMeshInst.multimesh.set_instance_transform(index, xform)
		index += 1
	
func load_chunk(chunk: Vector3i, post: Vector3i) -> void:
	var block_map := {}
	var directions = [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 1, 0), Vector3i(0, -1, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1),
	]

	# 1ère passe : stocker les blocs pleins
	for x in range(chunk_size * chunk.x, chunk_size * chunk.x + chunk_size):
		for z in range(chunk_size * chunk.z, chunk_size * chunk.z + chunk_size):
			var noise_val: float = noise.get_noise_2d(x, z)
			var height: int = int(clamp(noise_val * alt_amplifier, 0, chunk_vertical_size - 1))
			var terrain
			if height == 0:
				var pos = Vector3i(x, 0, z)
				block_map[pos] = displayed_water_meshes
				
			for y in range(height):
				if height < 4:
					terrain = displayed_sand_meshes
				else:
					if y > height -2:
						terrain = displayed_grass_meshes
					elif y > height -4:
						terrain = displayed_dirt_meshes
					else:
						terrain = displayed_stone_meshes
				block_map[Vector3i(x, y, z)] = terrain

	# 2e passe : ne garder que les blocs visibles
	for pos in block_map.keys():
		var visible := false
		var visible_dirs := []
		for dir in directions:
			if not block_map.has(pos + dir):
				visible = true
				visible_dirs.append(dir)

		if visible:
			var world_pos = Vector3(pos.x * spacing, pos.y * spacing, pos.z * spacing)
			block_map[pos].append(world_pos)
			add_block_to_collision(terrain_surface_tool, world_pos, spacing, visible_dirs)
			
func init_all_multimesh():
	init_one_multimesh(sand_scene, %SandGenerator)
	init_one_multimesh(dirt_scene, %DirtGenerator)
	init_one_multimesh(water_scene, %WaterGenerator)
	init_one_multimesh(grass_scene, %GrassGenerator)
	init_one_multimesh(stone_scene, %StoneGenerator)
	
func init_one_multimesh(scene: PackedScene, multiMeshInst: MultiMeshInstance3D):
	var temp = scene.instantiate()
	var mesh_instance = temp.get_node("Node/cube")
	var mesh = mesh_instance.mesh
	# Get mesh material
	var material = mesh_instance.get_active_material(0)
	multiMeshInst.multimesh = MultiMesh.new()
	multiMeshInst.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multiMeshInst.multimesh.mesh = mesh
	
func add_block_to_collision(st: SurfaceTool, pos: Vector3, size: float, directions: Array):
	var p = pos  
	var s = size  

	var face_map = {
		Vector3i(0, 0, -1): [0, 1, 2, 2, 3, 0], # back
		Vector3i(0, 0, 1):  [5, 4, 7, 7, 6, 5], # front
		Vector3i(-1, 0, 0): [4, 0, 3, 3, 7, 4], # left
		Vector3i(1, 0, 0):  [1, 5, 6, 6, 2, 1], # right
		Vector3i(0, 1, 0):  [3, 2, 6, 6, 7, 3], # top
		Vector3i(0, -1, 0): [4, 5, 1, 1, 0, 4]  # bottom
	}

	var v = [
		p + Vector3(0, 0, 0),            # 0: bottom back left
		p + Vector3(s, 0, 0),            # 1: bottom back right
		p + Vector3(s, s, 0),            # 2: top back right
		p + Vector3(0, s, 0),            # 3: top back left
		p + Vector3(0, 0, s),            # 4: bottom front left
		p + Vector3(s, 0, s),            # 5: bottom front right
		p + Vector3(s, s, s),            # 6: top front right
		p + Vector3(0, s, s)             # 7: top front left
	]

	for dir in directions:
		for i in face_map.get(dir, []):
			st.add_vertex(v[i])
