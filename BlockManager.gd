@tool
extends Node
class_name BlockManager

@export var air: Block = Block.new()
@export var stone: Block = Block.new()
@export var dirt: Block = Block.new()
@export var grass: Block = Block.new()

var _atlasLookup: Dictionary

var _gridWidth: int = 4
var _gridHeight: int

var blockTextureSize: Vector2i = Vector2i(16,16)

var textureAtlasSize: Vector2

var chunkMaterial: StandardMaterial3D = StandardMaterial3D.new()

func _ready():

	var blockTextures = [air, stone, dirt, grass]
	var blockTypes = [air, stone, dirt, grass]
	var blocks: int = len(blockTextures)

	#for each block in blocks add that block.textures to blockTextures
	for block in blocks:
		blockTextures.append_array(blockTextures[block].textures())

	#fore each block in blocks remove that blocktype
	for block in blocks:
		blockTextures.erase(blockTypes[block])

	#purpose unknown - ?filter out duplicates?
	blockTextures = blockTextures.filter(
		func(texture): return texture != null && blockTextures.count(texture)
	)

	print(blockTextures)
	
	#for each in blockTextures
	for i in len(blockTextures):
		#add to atlasLookup the position of that texture                               
		_atlasLookup[blockTextures[i]] = Vector2i(i % _gridWidth, floori(i / float(_gridWidth)))

	#set gridHeight to (length of blockTextures / _gridWidth) rounded up
	_gridHeight = ceili(len(blockTextures)/ float(_gridWidth))

	#Create an image that is (gridWidth * blockTextureSize.x) by (_gridHeight * blockTextureSize.y) 
	var image = Image.create(
			_gridWidth * blockTextureSize.x, _gridHeight * blockTextureSize.y, false, Image.FORMAT_RGBA8)
	
	for x in _gridWidth:
		for y in _gridHeight:
			var imgIndex = x + y * _gridWidth

			if imgIndex >= len(blockTextures): 
				continue
			
			var currentImage = blockTextures[imgIndex].get_image()
			currentImage.convert(Image.FORMAT_RGBA8)

			#copy contents of Rect2i from currentImage to Vector2i in image
			image.blit_rect(currentImage, Rect2i(Vector2i.ZERO, blockTextureSize), Vector2i(x,y) * blockTextureSize)

	var textureAtlas: Texture2D = ImageTexture.create_from_image(image)
	
	chunkMaterial.albedo_texture = textureAtlas
	chunkMaterial.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

	textureAtlasSize = Vector2i(_gridWidth, _gridHeight)

	print(
		"Loaded {textures} images to make a {width} x {height} atlas.".format(
			{"textures": len(blockTextures), "width": _gridWidth, "height": _gridHeight}
		)
	)

func GetTextureAtlasPosition(texture: Texture2D) -> Vector2i:
	if texture == null:
		return Vector2.ZERO
	else:
		return _atlasLookup[texture]






