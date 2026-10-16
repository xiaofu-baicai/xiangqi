class_name 语言管理
extends RefCounted

const 偏好路径 := "user://语言偏好.cfg"
static var 当前语言 := "zh_CN"
static var 已加载 := false
static var 偏好文件 := 偏好路径

static func 初始化() -> void:
	if 已加载:
		return
	TranslationServer.add_translation(preload("res://翻译/中文.tres"))
	TranslationServer.add_translation(preload("res://翻译/英文.tres"))
	已加载 = true
	读取偏好()

static func 读取偏好() -> void:
	var 配置 := ConfigFile.new()
	var 语言 := "zh_CN"
	if 配置.load(偏好文件) == OK:
		语言 = str(配置.get_value("界面", "语言", "zh_CN"))
	设置语言(语言, false)

static func 设置语言(语言: String, 保存: bool = true) -> void:
	当前语言 = "en" if 语言 == "en" else "zh_CN"
	TranslationServer.set_locale(当前语言)
	if 保存:
		var 配置 := ConfigFile.new()
		配置.set_value("界面", "语言", 当前语言)
		var 错误码 := 配置.save(偏好文件)
		if 错误码 != OK:
			push_warning("无法保存语言偏好 / Could not save language preference: %s" % 错误码)

static func 文本(原文: String) -> String:
	初始化()
	return TranslationServer.translate(原文)
