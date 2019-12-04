# classy
a LUA implementation of Object Orientated Programming

The module classy.lua emulates object orientated programming for LUA. This includes object and method inheretance, the concept of public and private and immutable and mutable objects. Classsy also perfroms strict type casting on objects.

[Full Documentation](http://htmlpreview.github.com/?https://github.com/davporte/classy/blob/master/doc/index.html)

## Example Module constants

The directory contains a sample object called Constants.lua and a main.lua with a test rig based on LuaUnit to test that classy and the Constants.lu module are operating correctly.

Constants is designed to manage an imutable set of objects. Example use in  code would be:

``` Lua
local Constants = require ('constants')

local object = Constants ()
object.attributestable.constantA = valueA
object.attributestable.constantB = valueB
```
valueA and valueB are both immutable, as is the table object.attributes. Alternatively you could declare as follows:

``` Lua
local Constants = require ('constants')

local object = Constants ( { attributestable = { constantA = valueA, constantB = valueB } } )
```
objects of class Constants have the following attributes controlled via these methods:

| Attribute | Description | Methods |
|----------|--------------|---------|
|lock      | If true the attributes table is locked| you can change this value using object:lock (), object:unlock () |
|fortress  | If true then the table is permanatly locked regadless of the value of lock, this cannot be undone| This can be set using the object:fortify () method |
|attributeStore | where the atributes are stored | can be accesed directly
|test           | a raw table for testing | can be accesed directly                                                                            |

      set. When you add an item to constants it CAN NOT be altered. 

      usage constants.attribute = VALUE -- this makes the value imutable
      If VALUE is a table then that table can have values set. Any values in that
      table also become imutable and so on.

      You can also completly lock/unlock constants from taking any more new
      attributes using the calls

      constants:lock () -- locks
      constants:unlock () -- unlocks
      constants:fortify () -- locks permanantly, can never unlock

      constants uses the class constructor, so this must also be avaialble

## Special Thanks To 
[LuaUnit - a great unit testing tool](https://github.com/bluebird75/luaunit/tree/LUAUNIT_V3_2_1)

[Inspect - a great tool for inspecting LUA tables](https://github.com/kikito/inspect.lua)
