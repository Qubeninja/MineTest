class_name Player
extends CharacterBody3D

@export var head: Node3D
@export var camera: Camera3D
@export var rayCast: RayCast3D
@export var blockHighlight: MeshInstance3D

@export var _mouseSensitivity: float = 0.15
@export var _movementSpeed: float = 5.0
@export var _jumpVelocity: float = 5.0

var _cameraXRotation: float

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

static var instance: Player

@onready var blockManager = $"../BlockManager"
@onready var chunkManager = $"../ChunkManager"

func _ready() -> void:
	instance = self

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:

	if event is InputEventMouseMotion:
		var mouseMotion = event as InputEventMouseMotion
		var deltaX = mouseMotion.relative.y * _mouseSensitivity
		var deltaY = mouseMotion.relative.x * _mouseSensitivity

		head.rotate_y(deg_to_rad(-deltaY))
		if (_cameraXRotation + deltaX) > -90 and (_cameraXRotation + deltaX) < 90:
			camera.rotate_x(deg_to_rad(-deltaX))
			_cameraXRotation += deltaX


func _process(delta: float) -> void:

	if rayCast.is_colliding() && rayCast.get_collider() is Chunk:
		blockHighlight.visible = true
		
		var chunk = rayCast.get_collider()
		var blockPosition = rayCast.get_collision_point() - (0.5 * rayCast.get_collision_normal())
		var intBlockPosition: Vector3i = Vector3i(floori(blockPosition.x), floori(blockPosition.y), floori(blockPosition.z))

		blockHighlight.global_position = Vector3(intBlockPosition) + Vector3(0.5, 0.5, 0.5)

		if Input.is_action_just_pressed("Break"):
			chunk.set_block(Vector3i(Vector3(intBlockPosition) - chunk.global_position), blockManager.air)

		if Input.is_action_just_pressed("Place"):
			chunkManager.set_block(Vector3i(intBlockPosition + Vector3i(rayCast.get_collision_normal())), blockManager.stone)
		
	else:
		blockHighlight.visible = false


func _physics_process(delta: float) -> void:
	var _velocity: Vector3 = velocity
	if not is_on_floor():
		_velocity.y -= _gravity * float(delta)

	if Input.is_action_just_pressed("Jump") && is_on_floor():
		_velocity.y = _jumpVelocity

	var inputDirection: Vector2 = Input.get_vector("Left", "Right", "Back", "Forward").normalized()

	var direction: Vector3 = Vector3.ZERO

	direction += inputDirection.x * head.global_basis.x

	#Forward is negative z
	direction += inputDirection.y * -head.global_basis.z

	_velocity.x = direction.x * _movementSpeed
	_velocity.z = direction.z * _movementSpeed

	velocity = _velocity
	move_and_slide()
