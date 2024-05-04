@tool
class_name ChunkManager
extends Node

#Dict of Chunks: Postions
var _chunkToPosition: Dictionary = {}
#Dict of Positions: Chunks
var _positionToChunk: Dictionary = {}

#List of Chunks
var _chunks: Array

func _ready():
    _chunks = get_parent().get_children().filter(func(i): return i is Chunk)


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