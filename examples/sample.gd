tool
extends EditorScript

const GDTypeSafe = preload("res://gdtypesafe.gd")

func _run() -> void:
	var preloadable_class := ["res://examples/preloadable_class.gd", "PreloadableClass"]
	var preloadable_class_subclass := ["res://examples/preloadable_class.gd", "PreloadableClassSubclass", "Subclass"]

	GDTypeSafe \
		.new("res://examples/gen") \
		.set_class_name(false) \
		.add_nullables([
			"int",
			"String",
			"GlobalClass",
			"GlobalClass.Subclass",
			preloadable_class,
			preloadable_class_subclass,
		]) \
		.add_arrays([
			"int",
			"String",
			"NullableGlobalClass",
			"GlobalDependent",
		]) \
		.add_dictionaries([
			["int", "String"],
			["PackedScene", "NullableString"],
			["Vector3", "Vector3"],
		]) \
		.add_proxies([
			"GlobalClass",
		]) \
		.write()
