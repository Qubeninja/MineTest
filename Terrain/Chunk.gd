@tool
class_name Chunk
extends StaticBody3D

@export var CollisionShape: CollisionShape3D
@export var MeshInstance: MeshInstance3D

@export var noise: FastNoiseLite

@onready var blockManager: BlockManager = $"../../BlockManager"
@onready var chunkManager: ChunkManager = $".."

#How big is the chunk x, y, z
static var dimensions: Vector3i = Vector3i(16, 64, 16)

#points of the a single cube 
#TODO: come back a properly comment where each point is on the cube
static var _vertices: Array[Vector3i] = [
	Vector3i(0,0,0), #0
	Vector3i(1,0,0), #1
	Vector3i(0,1,0), #2
	Vector3i(1,1,0), #3
	Vector3i(0,0,1), #4
	Vector3i(1,0,1), #5
	Vector3i(0,1,1), #6
	Vector3i(1,1,1)  #7
]

#define each face
#TODO: same as _vertices
static var _top: Array[int] = [2,3,7,6]
static var _bottom: Array[int] = [0,4,5,1]
static var _left: Array[int] = [6,4,0,2]
static var _right: Array[int] = [3,1,5,7]
static var _back: Array[int] = [7,5,4,6]
static var _front: Array[int] = [2,0,1,3]

var _surfacetool: SurfaceTool = SurfaceTool.new()

#WARN: possible problem point
var _blocks: Dictionary = {}

var chunkPosition: Vector2i

var generate_thread: Thread = Thread.new()
var mutex: Mutex = Mutex.new()
var update_thread: Thread = Thread.new()
var update_mutex: Mutex = Mutex.new()


#func _ready() -> void:
	#set_chunk_position(Vector2i(global_position.x / dimensions.x, global_position.z / dimensions.z))
 

func set_chunk_position(position: Vector2i):
	chunkManager.update_chunk_position(self, position, chunkPosition)
	chunkPosition = position
	global_position = Vector3(chunkPosition.x * dimensions.x, 0, chunkPosition.y * dimensions.z)
	
	#generate_thread.start(generate)
	#update_thread.start(update)
	generate()
	update()
	

#Fill _blocks dict
func generate():
	for x in dimensions.x:
		for y in dimensions.y:
			for z in dimensions.z:
				var block: Block 
				var globalBlockPosition: Vector2i = (chunkPosition * Vector2i(dimensions.x, dimensions.z)) + Vector2i(x, z)
				# get_noise_2d outputs a value in range of (-1 - 1), +1 makes it (0 - 2), /2 makes it (0 - 1), * dim.y makes it a value between 0 and dim.y,
				# finally cast whole thing as an int
				var groundHeight: int = int((dimensions.y * ((noise.get_noise_2d(globalBlockPosition.x, globalBlockPosition.y) + 1.0) / 2.0))) 
				if y < groundHeight / 1.2:
					block = blockManager.stone
				elif y < groundHeight:
					block = blockManager.dirt
				elif y == groundHeight:
					block = blockManager.grass
				else:
					block = blockManager.air
				
				mutex.lock()
				_blocks[Vector3i(x,y,z)] = block
				mutex.unlock()
	print("Chunk.generate created ", _blocks.size(), " blocks")
	#generate_thread.wait_to_finish()

#using _blocks generate CollisionShape & MeshInstance
func update():
	_surfacetool.begin(Mesh.PRIMITIVE_TRIANGLES)
	_surfacetool.set_smooth_group(-1)
	for x in dimensions.x:
		for y in dimensions.y:
			for z in dimensions.z:
				create_block_mesh(Vector3i(x,y,z))
	_surfacetool.generate_normals()
	_surfacetool.set_material(blockManager.chunkMaterial)
	var mesh: ArrayMesh = _surfacetool.commit()
	MeshInstance.mesh = mesh
	CollisionShape.shape = mesh.create_trimesh_shape()
	#update_thread.wait_to_finish()
	print(
		"generated {vertices} vertices ({triangles} triangles, {faces} faces)".format(
			{
				"vertices": mesh.surface_get_array_len(0),
				"triangles": mesh.surface_get_array_len(0) / 3.0,
				"faces": (mesh.surface_get_array_len(0) / 3.0) / 2.0
			}
		)
	)

#generate a block mesh 
func create_block_mesh(block_position: Vector3i):
	mutex.lock()
	var block = _blocks[Vector3i(block_position)]
	mutex.unlock()

	if block == blockManager.air: return
	#Check if block above is transparent
	if check_transparent(block_position + Vector3i.UP):
		
		#if true create top face mesh
		create_face_mesh(_top, block_position, block.topTexture if block.topTexture else block.texture)

	if check_transparent(block_position + Vector3i.DOWN):
		create_face_mesh(_bottom, block_position, block.bottomTexture if block.bottomTexture else block.texture)
		
	if check_transparent(block_position + Vector3i.LEFT):
		create_face_mesh(_left, block_position, block.texture)
		
	if check_transparent(block_position + Vector3i.RIGHT):
		create_face_mesh(_right, block_position, block.texture)
			
	if check_transparent(block_position + Vector3i.BACK):
		create_face_mesh(_back, block_position, block.texture)

	if check_transparent(block_position + Vector3i.FORWARD):
		create_face_mesh(_front, block_position, block.texture)
	

#generate a face mesh using face array
func create_face_mesh(face: Array[int], block_position: Vector3i, texture: Texture2D):

	var texturePosition: Vector2 = blockManager.get_texture_atlas_position(texture)
	var textureAtlasSize: Vector2 = blockManager.textureAtlasSize

	var uvOffset = texturePosition / textureAtlasSize
	var uvWidth = 1.0 / textureAtlasSize.x
	var uvHeight = 1.0 / textureAtlasSize.y

	var uvA = uvOffset + Vector2(0, 0) 
	var uvB = uvOffset + Vector2(0, uvHeight)
	var uvC = uvOffset + Vector2(uvWidth, uvHeight)
	var uvD = uvOffset + Vector2(uvWidth, 0)

	var a = _vertices[face[0]] + block_position
	var b = _vertices[face[1]] + block_position					#a----------d
	var c = _vertices[face[2]] + block_position					#|			|
	var d = _vertices[face[3]] + block_position					#|			|
																#|			|
	var uvTriangle1 = [uvA, uvB, uvC]							#b----------c
	var uvTriangle2 = [uvA, uvC, uvD]						
							
	var triangle1 = [a,b,c]										
	var triangle2 = [a,c,d]

	_surfacetool.add_triangle_fan(triangle1, uvTriangle1)
	_surfacetool.add_triangle_fan(triangle2, uvTriangle2)


#Check if adjacent block is transparent 
func check_transparent(block_position: Vector3i) -> bool:
	if (block_position.x < 0 || block_position.x >= dimensions.x): return true
	if (block_position.y < 0 || block_position.y >= dimensions.y): return true
	if (block_position.z < 0 || block_position.z >= dimensions.z): return true
	
	return _blocks[Vector3i(block_position)] == blockManager.air
	

func set_block(blockPosition: Vector3i, block: Block):
	mutex.lock()
	_blocks[Vector3i(blockPosition.x, blockPosition.y, blockPosition.z)] = block
	mutex.unlock()
	update()
