class_name PieceSetup
extends Resource

enum Team { BLACK, RED }
enum Kind { KING, ADVISOR, ELEPHANT, HORSE, ROOK, CANNON, PAWN }

@export var side: Team = Team.BLACK
@export var kind: Kind = Kind.PAWN
@export var position: Vector2i = Vector2i.ZERO
@export_range(1, 999, 1) var health: int = 1
