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

var thread: Thread = Thread.new()
var _playerPosition: Vector3
var mutex: Mutex


func _ready():
	mutex = Mutex.new()
	
	_chunks = self.get_children().filter(func(i): return i is Chunk)
	var count = _chunks.size()
	while count < _width * _width:
		var chunk = chunkScene.instantiate()
		#get_parent().call_deferred("add_child", chunk)
		add_child(chunk)
		_chunks.append(chunk)
		count = _chunks.size()
	#call_deferred("generate_chunk_index")
	print("instantiated ", count, " chunks")
	generate_chunk_index()
	print("called generate_chunk_index")

	if not Engine.is_editor_hint():
		thread.start(thread_process)

		
func generate_chunk_index():
	var previous_index
	for x in _width:
		for y in _width:
			var index: int = (x * _width) + y
			if index == previous_index:
				continue
			_chunks[index].set_chunk_position(Vector2i(x - _halfwidth, y - _halfwidth))
			#_chunks[index].call_deferred("set_chunk_position", Vector2i(x - _halfwidth, y - _halfwidth))
			previous_index = index
	print("called set_chunk_position ", previous_index + 1, " times")



func update_chunk_position(chunk: Chunk, currentPosition: Vector2i, previousPosition: Vector2i):
	if _positionToChunk.has(previousPosition):
		if _positionToChunk[previousPosition] == chunk:
			_positionToChunk.erase(previousPosition)
	_chunkToPosition[chunk] = currentPosition
	_positionToChunk[currentPosition] = chunk

func set_block(global_position: Vector3i, block: Block):
	var chunkTilePosition = Vector2i(floori(global_position.x / float(Chunk.dimensions.x)), floori(global_position.z / float(Chunk.dimensions.z)))
	mutex.lock()
	if _positionToChunk.has(chunkTilePosition):
		var chunk = _positionToChunk[chunkTilePosition]
		chunk.set_block(global_position - Vector3i(chunk.global_position), block)
	mutex.unlock()


func _physics_process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		mutex.lock()
		_playerPosition = Player.instance.global_position
		mutex.unlock()

func thread_process():
	while is_instance_valid(self):
		var playerChunkX: int
		var playerChunkZ: int

		mutex.lock()
		playerChunkX = floori(_playerPosition.x / Chunk.dimensions.x)
		playerChunkZ = floori(_playerPosition.z / Chunk.dimensions.z)
		mutex.unlock()

		for chunk in _chunks:
			mutex.lock()
			var chunkPosition = _chunkToPosition[chunk]
			mutex.unlock()
			
			var chunkX = chunkPosition.x
			var chunkZ = chunkPosition.y

			var newChunkX = int(fposmod(chunkX - playerChunkX + _width / 2.0, _width) + playerChunkX - _width / 2.0)
			var newChunkZ = int(fposmod(chunkZ - playerChunkZ + _width / 2.0, _width) + playerChunkZ - _width / 2.0)
			
			if newChunkX != chunkX or newChunkZ != chunkZ:
				mutex.lock()
				if _positionToChunk.has(chunkPosition):
					_positionToChunk.erase(chunkPosition)

				var newPosition = Vector2(newChunkX, newChunkZ)

				_chunkToPosition[chunk] = newPosition
				_positionToChunk[newPosition] = chunk
				
				#chunk.set_chunk_position(newPosition)
				chunk.call_deferred("set_chunk_position", newPosition)
				mutex.unlock()
			
func _exit_tree() -> void:
	thread.wait_to_finish()

