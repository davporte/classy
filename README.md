# classy
a LUA implementation of Object Orientated Programming

The module classy.lua emulates object orientated programming for LUA. This includes object and method inheretance, the concept of public and private and immutable and mutable objects. Classsy also perfroms strict type testing on objects.

[Full Documentation](http://htmlpreview.github.com/?https://github.com/davporte/classy/blob/master/doc/index.html) can be found here.

Usage:

``` Lua
local classy = require ('classy')
```

## An Example Module - 'constants'

The directory contains a sample object called Constants.lua and a main.lua with a test rig based on LuaUnit to test that classy and the constants.lua module are operating correctly.

Constants is designed to manage an imutable set of objects. Example use in  code would be:

``` Lua
local Constants = require ('constants')

local object = Constants ()
object.attributestable.constantA = valueA
object.attributestable.constantB = valueB
```
valueA and valueB are both immutable, as is the table object.attributestable. Alternatively you could declare as follows:

``` Lua
local Constants = require ('constants')

local object = Constants ( { attributestable = { constantA = valueA, constantB = valueB } } )
```
objects of class Constants have the following attributes controlled via these methods:

| Attribute | Description | Methods |
|------------------|--------------|---------|
|lock      | If true the attributes table is locked| you can change this value using object:lock (), object:unlock () |
|fortress  | If true then the table is permanatly locked regadless of the value of lock, this cannot be undone| This can be set using the object:fortify () method |
|attributestable | where the atributes are stored | can be accesed directly
|test           | a raw table for testing | can be accesed directly                                                                         

constants is build using the following code:

```
classy:newClass (  
			classy:attributes ( { attributeStore = Table ( Immutable ), locked = Bool ( Private ), fortress = Bool ( PrivateImmutable ), secretStore = Table ( Private ) } ),
			classy:initMethod (
					function (obj, arguments )

						classy:setDefaultValues ( obj, arguments, { attributeStore = {}, secretStore = {}, locked = false } )

						-- the user may have called attributes store in the constructor with objects in that constructor so move them into the secret store
						local next = next
						local k, v

						for k, v in next, obj.attributeStore, nil do
							obj.secretStore [ k ] = v
							rawset ( obj.attributeStore, k, nil )
						end

						-- as secretStore is Private we need to create classy methods to affact change on them, as they can't call directly 
						-- we also have to test for obj values first before assumeing it is a secretStore Value
						-- bindMetaMethods expect the parameters t, k and optional v. We need to bind these methods so that __index/__newindex are viewed as running inside a constructor method.
						obj.attributeStore.__index = classy:bindMetaMethod ( obj, function ( t, k )  
								return gettingAttribute ( obj, t, k )
							end )
						obj.attributeStore.__newindex = classy:bindMetaMethod ( obj, function ( t, k, v ) 
								settingAttribute ( obj, t, k, v )
							end ) 
						setmetatable (obj.attributeStore, obj.attributeStore)
					end
				),
			classy:addMethod ('lock', function (obj) obj.locked = true end),
			classy:addMethod ('unlock', function (obj) obj.locked = false end),
			classy:addMethod ('fortify', function (obj) obj.fortress = true end),
			classy:addNotes (constants._VERSION .. '\n\n' .. constants._DESCRIPTION .. '\n' .. constants._LICENSE, ... )
			)

```

This code uses the following classy methods:

|       Module     | Purpose |
|------------------|---------|
|classy:newClass | the class constructor. All classy constructor methods go inside this class constructor |
|classy:attributes| defines the individual attributes this class has. Attributes can be mutable/immutable public/private. Immutable attributes cannot be changed one set, including to nil. Private attributes can only be addressed from within a class constructor function ```class:METHOD```| 

The valid class describers for class:attributes are:

* **Immutable** Immutable, Public same as PublicImmutable
* **Public** Mutable Public same as PublicMutable - DEFAULT
* **PublicMutable** Mutable, Public same as Public
* **PublicImmutable** Immutable, Public same as Immutable
* **Private Mutable** Private same as PrivateMutable
* **PrivateMutable** Mutable, Private same as Private
* **PrivateImmutable** Immutable, Private  

Note: ALL custom classes must have a class describer! Base classes e.g. Bool, String, Table, Function, Number are assumed to be Public unless otherwise stated.

|       Module     | Purpose |
|------------------|---------|
|classy:initMethod | this is the init method that runs when you create an object. This method has a paramter called obj, that is the object under construction |
|classy:addPrivateMethod | adds a method only avaialble internally to the class constructors. This method has a paramter called obj, that is the object |
|classy:addMethod        | adds a public facing method. This method has a paramter called obj, that is the object   |
|classy:bindMetaMethod   | allows a meta method such as \_\_index or \_\_newindex to execute as if in constructors |
|classy:setDefaultValues | sets default values for the object |
|classy:addNotes         | adds some notes for the class that can be displayed, see [Full Documentation](http://htmlpreview.github.com/?https://github.com/davporte/classy/blob/master/doc/index.html). This method has a paramter called obj, that is the object |

Constants does not use the overload classy method:

|       Module     | Purpose |
|------------------|---------|
| classy:overload   | overloads an operator for a class. Note, except uniray minus (which has obj only), this method has two paramters called objA and objB that are the objects being acted upon |

Supported operators are:

* **+** add
* **-** subtract
* **\*** multiply
* **/** divide
* **%** mod
* **:-** unary minus, note colon on front of -
* **=** equals
* **<** less than
* **<=** less than or equals to

Note:  > and >= supported using not > and not >=

Classy also adds protection to the _G global table to prevent the user from changing specific functions and constants used by classy. Classy will not load if _G already has a metatable.

## Samples

The main directory contains sample usage and test rig for classy. The [sample directory] (https://github.com/davporte/classy/tree/master/sample) contains other stand alone examples.

## Special Thanks To 
[LuaUnit - a great unit testing tool](https://github.com/bluebird75/luaunit/tree/LUAUNIT_V3_2_1)

[Inspect - a great tool for inspecting LUA tables](https://github.com/kikito/inspect.lua)
