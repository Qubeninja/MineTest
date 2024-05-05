@tool
class_name ChunkManager
extends Node

@export var chunkScene: PackedScene

#Dict of Chunks: Postions
var _chunkToPosition: Dictionary = {}
#Dict of Positions: Chunks
var _positionToChunk: Dictionary = {}

#List of Chunks
var _chunks: Array

var _width: int = 5
var _halfwidth = floori(_width / 2.0)


func _ready():
    _chunks = get_parent().get_children().filter(func(i): return i is Chunk)
    
    for i in _chunks:
        if i < _width * _width:
            var chunk = chunkScene.instantiate()
            get_parent().call_deferred("add_child", chunk)
            _chunks.append(chunk)
        else: return

    for x in _width:
        for y in _width:
            var index = (y * _width) + x
            _chunks[index].set_chunk_position(Vector2i(x - _halfwidth, y - _halfwidth))



func update_chunk_position(chunk: Chunk, currentPosition: Vector2i, previousPosition: Vector2i):

    if _positionToChunk.has(previousPosition):
        if _positionToChunk[previousPosition] == chunk:
            _positionToChunk.erase(previousPosition)

    _chunkToPosition[chunk] = currentPosition
    _positionToChunk[currentPosition] = chunk

func set_block(global_position: Vector3i, block: Block):
    var chunkTilePosition = Vector2i(floori(global_position.x / float(Chunk.dimensions.x)), floori(global_position.z / float(Chunk.dimensions.z)))

    if _positionToChunk.has(chunkTilePosition):
        var chunk = _positionToChunk[chunkTilePosition]
        chunk.set_block(global_position - Vector3i(chunk.global_position), block)