@tool
extends StaticBody3D

@export var CollisionShape: CollisionShape3D
@export var MeshInstance: MeshInstance3D

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
var _blocks: Dictionary

func _ready():
	Generate()
	Update()

#Fill _blocks dict
func Generate():
	var block = Block
	for x in dimensions.x:
		
		for y in dimensions.y:
			
			for z in dimensions.z:
				_blocks[Vector3i(x,y,z)] = block

#using _blocks generate CollisionShape & MeshInstance
func Update():
	_surfacetool.begin(Mesh.PRIMITIVE_TRIANGLES)

	for x in dimensions.x:
		
		for y in dimensions.y:
			
			for z in dimensions.z:
				CreateBlockMesh(Vector3i(x,y,z))
	
	var mesh: ArrayMesh = _surfacetool.commit()

	MeshInstance.mesh = mesh
	CollisionShape.shape = mesh.create_trimesh_shape()

#Generate a block mesh 
func CreateBlockMesh(block_postion: Vector3i):
		#Check if block above is transparent
		if CheckTransparent(block_postion + Vector3i.UP):
			#if true create top face mesh
			CreateFaceMesh(_top, block_postion)

		if CheckTransparent(block_postion + Vector3i.DOWN):
			CreateFaceMesh(_bottom, block_postion)
		
		if CheckTransparent(block_postion + Vector3i.LEFT):
			CreateFaceMesh(_left, block_postion)
		
		if CheckTransparent(block_postion + Vector3i.RIGHT):
			CreateFaceMesh(_right, block_postion)
			
		if CheckTransparent(block_postion + Vector3i.BACK):
			CreateFaceMesh(_back, block_postion)

		if CheckTransparent(block_postion + Vector3i.FORWARD):
			CreateFaceMesh(_front, block_postion)

#Generate a face mesh using face array
func CreateFaceMesh(face: Array[int], block_position: Vector3i):
	var a = _vertices[face[0]] + block_position
	var b = _vertices[face[1]] + block_position					#a----------d
	var c = _vertices[face[2]] + block_position					#|			|
	var d = _vertices[face[3]] + block_position					#|			|
																#|			|
	var triangle1 = [a,b,c]										#b----------c
	var triangle2 = [a,c,d]

	_surfacetool.add_triangle_fan(triangle1)
	_surfacetool.add_triangle_fan(triangle2)


#Check if adjacent block is transparent 
func CheckTransparent(block_postion: Vector3i) -> bool:
	return true