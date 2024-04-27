@tool
class_name Block
extends Resource

@export var texture: Texture2D
@export var topTexture: Texture2D
@export var bottomTexture: Texture2D



func textures() -> Array[Texture2D]:
	return [texture, topTexture, bottomTexture]
