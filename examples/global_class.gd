class_name GlobalClass

const ArrayOfGlobalDependent := preload("res://examples/gen/ArrayOfGlobalDependent.gd").ArrayOfGlobalDependent

var dependents: ArrayOfGlobalDependent

func do_something(hey: int) -> String:
	return "o hi " + str(hey)

func get_self() -> GlobalClass:
	return self

class Subclass:
	pass
