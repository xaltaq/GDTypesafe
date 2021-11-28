# GDTypesafe
GDTypesafe is a class generator for Godot which helps work around GDScript's insufficient typing system. Specifically, it
* Allows explicitely specifying that a variable can be null using [nullables](https://github.com/xaltaq/GDTypesafe/wiki/Nullables)
* Provides typesafe [arrays](https://github.com/xaltaq/GDTypesafe/wiki/Arrays) and [dictionaries](https://github.com/xaltaq/GDTypesafe/wiki/Dictionaries)
* Gets around the cyclical dependency problems using [proxies](https://github.com/xaltaq/GDTypesafe/wiki/Proxies)

## Usage
The entire code is contained within the [gdtypesafe.gd](https://github.com/xaltaq/GDTypesafe/blob/master/gdtypesafe.gd) file. Copy just the file, or clone this repository, into your project.

## Examples
The [examples/sample.gd](https://github.com/xaltaq/GDTypesafe/blob/master/examples/sample.gd) demonstrates how to use GDTypesafe to generate various classes. This script can be run directly from the editor through File > Run. It will generate a bunch of files inside the examples/gen directory.

## License
Licensed under the MIT License. 
