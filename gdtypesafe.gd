#
# When true, `class_name` will be added to each generated class, and those classes can be used
# without preloading.
# When false, each desired class will need to be imported, e.g.
#   const GeneratedClass := preload("/path/to/gen/GeneratedClass.gd").GeneratedClass
#
# Default: false
#
func set_class_name(flag: bool = true):
	_set_class_name = flag
	return self

#
# Generate nullable wrappers.
# The contents of each wrapper will either be present or null.
# The argument is an array, and each element can be:
# * String defining a built-in type or a globally loaded class
#   e.g. "int", "String", "MyClass" (assuming there's a file with the line `class_name MyClass`)
# * An array defining a class which is not globally loaded, but can be safely preloaded, in the form
#     [path, name, (subclass)]
#   where
#     path - path to the script to be loaded, preferrably beginning with "res://"
#     name - desired name of the preloade class
#     subclass - optionally define which subclass inside the script will be used
# For the type {Name}, the generated class will be called Nullable{Name}, with some exceptions.
#
# Retuns self so it can be chained with other methods.
#
func add_nullables(nullables: Array):
	_add_nullables(nullables)
	return self

#
# Generate typesafe array wrappers.
# The argument is an array, and each element can be:
# * String defining a built-in type or a globally loaded class
#   e.g. "int", "String", "MyClass" (assuming there's a file with the line `class_name MyClass`)
# * An array defining a class which is not globally loaded, but can be safely preloaded, in the form
#     [path, name, (subclass)]
#   where
#     path - path to the script to be loaded, preferrably beginning with "res://"
#     name - desired name of the preloade class
#     subclass - optionally define which subclass inside the script will be used
# For the type {Name}, the generated class will be called Nullable{Name}, with some exceptions.
#
# Retuns self so it can be chained with other methods.
#
func add_arrays(arrays: Array):
	_add_arrays(arrays)
	return self

#
# Generate typesafe dictionary wrappers.
# The argument is an array, and each element is an array of [key, value].
# Each key, value element can be:
# * String defining a built-in type or a globally loaded class
#   e.g. "int", "String", "MyClass" (assuming there's a file with the line `class_name MyClass`)
# * An array defining a class which is not globally loaded, but can be safely preloaded, in the form
#     [path, name, (subclass)]
#   where
#     path - path to the script to be loaded, preferrably beginning with "res://"
#     name - desired name of the preloade class
#     subclass - optionally define which subclass inside the script will be used
# For the type {Name}, the generated class will be called Nullable{Name}, with some exceptions.
#
# Retuns self so it can be chained with other methods.
#
func add_dictionaries(dictionaries: Array):
	_add_dictionaries(dictionaries)
	return self

#
# TODO
#
func add_proxies(proxies: Array):
	_add_proxies(proxies)
	return self

#
# Generate code inside the provided directory.
# If the directory does not exist, it will be created, and if a file to be generated exists, it will
# be overwritten.
# Note that, depending on your configuration, a lot of files can be generated, so you should select
# a directory with no hand-written files, preferrably ignored from version control.
#
func write(dest: String) -> void:
	_write(dest)

#################### END OF PUBLIC API ####################

var _set_class_name := false
var _templates := {}

func _add_nullables(nullables: Array) -> void:
	for i in len(nullables):
		var cls := _resolve_class_type(nullables[i], "nullables", i)
		var template := _NullableTemplate.new(cls)
		_add_template(template)

func _add_arrays(arrays: Array) -> void:
	for i in len(arrays):
		var cls := _resolve_class_type(arrays[i], "arrays", i)
		var template := _ArrayTemplate.new(cls)
		_add_template(template)

func _add_dictionaries(dictionaries: Array) -> void:
	for i in len(dictionaries):
		var kv = dictionaries[i]
		if (not kv is Array) or (len(kv) != 2):
			_die("dictionaries", i, "item must be an array of [key, value]")
		var key := _resolve_class_type(kv[0], "dictionaries", i)
		var value := _resolve_class_type(kv[1], "dictionaries", i)
		var template := _DictionaryTemplate.new(key, value)
		_add_template(template)
		for dependency in template.dependencies():
			_add_template(dependency)

func _add_proxies(proxies: Array) -> void:
	for i in len(proxies):
		var template := _ProxyTemplate.new()
		_add_template(template)

func _add_template(template: _AbstractTemplate) -> void:
	_templates[template.real_class_name()] = template

func _write(dest: String) -> void:
	var dir := Directory.new()
	if dir.file_exists(dest):
		_die("write", 0, "specified path is a file, not a directory")
	if not dir.dir_exists(dest):
		var err := dir.make_dir_recursive(dest)
		if err != OK:
			_die("write", 0, "cannot create directory")
	var err := dir.open(dest)
	if err != OK:
		_die("write", 0, "cannot open directory")

	var generated_class_names := _templates.keys()
	for template_raw in _templates.values():
		var template: _AbstractTemplate = template_raw
		var file := File.new()
		var filename := "%s/%s.gd" % [dest, template.real_class_name()]
		err = file.open(filename, File.WRITE)
		if err != OK:
			_die("write", 0, "cannot open " + filename)
		file.store_string(template.write(_set_class_name, generated_class_names))
		file.close()

static func _resolve_class_type(arg, arr_name: String, arr_idx: int) -> _AbstractType:
	if arg is String:
		return _GlobalType.new(arg)
	if arg is Array:
		if len(arg) < 2 or len(arg) > 3:
			_die(arr_name, arr_idx, "argument must be in the form [path, class_name, (subclass)]")
		return _PreloadableType.new(arg)
	_die(arr_name, arr_idx, "argument must be string or array")
	return null

static func _die(arr_name: String, arr_idx: int, err: String) -> void:
	printerr("Error in ", arr_name, " index ", arr_idx, ": ", err)
	assert(false)

### Class types

class _AbstractType:
	func used_class_name() -> String:
		return ""

	func displayed_class_name() -> String:
		return ""

	func prelude_code(_set_class_name: bool, _generated_class_names: Array) -> String:
		return ""

	func load_script() -> GDScript:
		return null

class _GlobalType:
	extends _AbstractType

	var _cls_name: String
	var _displayed_name: String

	func _init(cls_name: String) -> void:
		_cls_name = cls_name
		_displayed_name = cls_name.left(1).to_upper() + cls_name.right(1).replace(".", "")

	func used_class_name() -> String:
		return _cls_name

	func displayed_class_name() -> String:
		return _displayed_name

	func prelude_code(set_class_name: bool, generated_class_names: Array) -> String:
		if not set_class_name and _displayed_name in generated_class_names:
			return "const %s = preload(\"%s.gd\").%s\n" % [_displayed_name, _displayed_name, _displayed_name]
		return .prelude_code(set_class_name, generated_class_names)

	func load_script() -> GDScript:
		for gsl in ProjectSettings["_global_script_classes"]:
			if gsl["class"] == _cls_name:
				return load(gsl["path"]) as GDScript

		printerr(_cls_name, " is not a global class")
		return null

class _PreloadableType:
	extends _AbstractType

	var _path: String
	var _cls_name: String
	var _subclass: String

	func _init(parts: Array) -> void:
		_path = parts[0]
		_cls_name = parts[1]
		_subclass = "." + parts[2] if parts.size() == 3 else ""

	func used_class_name() -> String:
		return _cls_name

	func displayed_class_name() -> String:
		return _cls_name

	func prelude_code(_set_class_name: bool, _generated_class_names: Array) -> String:
		return "const %s = preload(\"%s\")%s\n" % [_cls_name, _path, _subclass]

	func load_script() -> GDScript:
		return load("path") as GDScript

### Templates

class _AbstractTemplate:
	func real_class_name() -> String:
		return _apply_replacements("{Name}")

	func _proxy_name() -> String:
		return "{Proxy}"

	func _custom_code() -> String:
		return ""

	func _proxy_calls() -> Array:
		return []

	func _replacements() -> Dictionary:
		return {}

	func _types() -> Array:
		return []

	func write(set_class_name: bool, generated_class_names: Array) -> String:
		var header = "# AUTO-GENERATED CODE, DO NOT MODIFY\n"
		if set_class_name:
			header += "class_name %s\nextends Reference\n" % real_class_name()
		else:
			header += "class %s:\n\textends Reference\n" % real_class_name()

		var code := "\n"
		for type in _types():
			code += (type as _AbstractType).prelude_code(set_class_name, generated_class_names)
		code += _custom_code()
		for proxy_call in _proxy_calls():
			var function_name = proxy_call[0]
			var return_type = proxy_call[1]
			var parameters := PoolStringArray()
			var variables := PoolStringArray()
			for i in range(2, len(proxy_call), 2):
				parameters.append("%s: %s" % [proxy_call[i], proxy_call[i + 1]])
				variables.append(proxy_call[i])
			code += """
func %s(%s) -> %s:
	%s%s.%s(%s)
""" % [
				function_name,
				parameters.join(", "),
				return_type,
				"return " if return_type != "void" else "",
				_proxy_name(),
				function_name,
				variables.join(", ")
			]

		if not set_class_name:
			code = code.replace("\n", "\n\t")
		code = header + code

		return _apply_replacements(code)

	func to_type() -> _GlobalType:
		return _GlobalType.new(real_class_name())

	func _apply_replacements(string: String) -> String:
		var replacements := _replacements()
		for replacement in replacements.keys():
			string = string.replace(replacement, replacements[replacement])
		return string

class _NullableTemplate:
	extends _AbstractTemplate

	var _cls: _AbstractType

	func _init(cls: _AbstractType) -> void:
		_cls = cls

	func _custom_code() -> String:
		return """
var {Proxy}: {Class}

func _init(item_or_null) -> void:
	assert((item is {Class}) or (item == null))
	{Proxy} = item_or_null

func is_present() -> bool:
	return {Proxy} is {Class}

func is_absent() -> bool:
	return {Proxy} == null

func fetch() -> {Class}:
	assert(is_present())
	return {Proxy}
"""

	func _replacements() -> Dictionary:
		return {
			"{Name}": "Nullable" + _cls.displayed_class_name(),
			"{Class}": _cls.used_class_name(),
			"{Proxy}": "item"
		}

	func _types() -> Array:
		return [_cls]

class _ArrayTemplate:
	extends _AbstractTemplate

	var _cls: _AbstractType

	func _init(cls: _AbstractType) -> void:
		_cls = cls

	func _custom_code() -> String:
		return """
var {Proxy}: Array

func _init(from: Array = []) -> void:
	{Proxy} = from

func fetch(idx: int) -> {Class}:
	var item = {Proxy}[idx]
	assert(item is {Class})
	return item

func put(idx: int, item: {Class}) -> void:
	{Proxy}[idx] = item

func append_array(array: {Name}) -> void:
	{Proxy}.append_array(array.{Proxy})
"""

	func _proxy_calls() -> Array:
		return [
			["append", "void", "value", "{Class}"],
			["back", "{Class}"],
			["bsearch", "int", "value", "{Class}", "before", "bool = true"],
			["bsearch_custom", "int", "value", "{Class}", "obj", "Object", "fn", "String", "before", "bool = true"],
			["count", "int", "value", "{Class}"],
			["erase", "void", "value", "{Class}"],
			["find", "int", "what", "{Class}", "from", "int = 0"],
			["find_last", "int", "what", "{Class}"],
			["front", "{Class}"],
			["has", "bool", "value", "{Class}"],
			["insert", "void", "position", "int", "value", "{Class}"],
			["max", "{Class}"],
			["min", "{Class}"],
			# TODO the rest
		]

	func _replacements() -> Dictionary:
		return {
			"{Name}": "ArrayOf" + _cls.displayed_class_name(),
			"{Class}": _cls.used_class_name(),
			"{Proxy}": "items"
		}

	func _types() -> Array:
		return [_cls]

class _DictionaryTemplate:
	extends _AbstractTemplate

	var _key: _AbstractType
	var _value: _AbstractType
	var _key_array_template: _ArrayTemplate
	var _value_array_template: _ArrayTemplate

	func _init(key: _AbstractType, value: _AbstractType) -> void:
		_key = key
		_value = value
		_key_array_template = _ArrayTemplate.new(key)
		_value_array_template = _ArrayTemplate.new(value)

	func dependencies() -> Array:
		return [_key_array_template, _value_array_template]

	func _custom_code() -> String:
		return """
var {Proxy}: Dictionary

func _init(from: Dictionary = {}) -> void:
	{Proxy} = from

func fetch(key: {Key}, default = null) -> {Value}:
	assert((default is {Value}) or (default == null))
	return {Proxy}.get(key, default)

func put(key: {Key}, value: {Value}) -> void:
	{Proxy}[key] = value

func duplicate(deep: bool = false) -> {Name}:
	return {Name}.new({Proxy}.duplicate(deep))

func has_all(keys: {KeyArray}) -> bool:
	return {Proxy}.has_all(keys.items)

func keys() -> {KeyArray}:
	return {KeyArray}.new({Proxy}.keys())

func values() -> {ValueArray}:
	return {ValueArray}.new({Proxy}.values())
"""

	func _proxy_calls() -> Array:
		return [
			["clear", "void"],
			["empty", "bool"],
			["erase", "bool", "key", "{Key}"],
			["has", "bool", "key", "{Key}"],
			["hash", "int"],
			["size", "int"],
		]

	func _replacements() -> Dictionary:
		return {
			"{Name}": "DictionaryOf" + _key.displayed_class_name() + "To" + _value.displayed_class_name(),
			"{Key}": _key.used_class_name(),
			"{Value}": _value.used_class_name(),
			"{KeyArray}": _key_array_template.real_class_name(),
			"{ValueArray}": _value_array_template.real_class_name(),
			"{Proxy}": "items"
		}

	func _types() -> Array:
		return [_key, _value, _key_array_template.to_type(), _value_array_template.to_type()]

class _ProxyTemplate:
	extends _AbstractTemplate
