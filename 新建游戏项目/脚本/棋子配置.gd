class_name 棋子配置
extends Resource

enum 阵营类型 { 红方, 黑方 }
enum 棋种类型 { 将帅, 士仕, 象相, 马, 车, 炮, 兵卒 }

@export var 阵营: 阵营类型 = 阵营类型.红方
@export var 棋种: 棋种类型 = 棋种类型.兵卒
@export var 棋盘位置: Vector2i = Vector2i.ZERO
@export_range(1, 999, 1) var 血量: int = 1
