# classy
a LUA implementation of Object Orientated Programming

The module classy.lua emulates object orientated programming for LUA. This includes object and method inheretance, the concept of public and private and immutable and mutable objects. Classsy also perfroms strict type casting on objects.

[Full Documentation](http://htmlpreview.github.com/?https://github.com/davporte/classy/blob/master/doc/index.html) can be found here.

## Example Module constants

The directory contains a sample object called Constants.lua and a main.lua with a test rig based on LuaUnit to test that classy and the constants.lua module are operating correctly.

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
|test           | a raw table for testing | can be accesed directly                                                                         

constants is build using the following code:

```
classy:newClass (  
			classy:attributes ( { attributeStore = Table ( Immutable ), locked = Bool ( Private ), fortress = Bool ( PrivateImmutable ), test = Table () } ),
			classy:initMethod (
					function (obj)
						-- set the attribute store up if not already there, user may have sent a constructor table
						if not obj.attributeStore then
							obj.attributeStore = {}
						end
						-- create a secret place to store the objects, we don't want to access directly
						rawset (obj, _SECRETSTORE_NAME, {})

						-- the user may have called attributes store in the constructor with objects in that constructor so move them into the secret store
						local next = next
						local k, v

						for k, v in next, obj.attributeStore, nil do
							obj [ _SECRETSTORE_NAME ] [ k ] = v
							rawset ( obj.attributeStore, k, nil )
						end

						-- mark the class initially unlocked, we do not set fortress
						if not obj.locked then
							obj.locked = false
						end

						obj.attributeStore.__index = function (t, k) return getAttributeFromStore (k, obj) end
						obj.attributeStore.__newindex = function (t, k, v) obj.setValue (obj, t, k, v) end 
						setmetatable (obj.attributeStore, obj.attributeStore)
					end
				),
			-- this private method is required to enusre locked and fortress are addresable, they would not be inside __newindex
			classy:addPrivateMethod ('setValue', function (obj, t, k, v) if not (obj.locked or obj.fortress) then setAttributeInStore (k, v, obj) else error ('store is locked', 5 ) end end),
			-- note the above error is 5 because the source code is calling inside __newindex->setValue (class itself has 3 methods binding these calls)
			classy:addMethod ('lock', function (obj) obj.locked = true end),
			classy:addMethod ('unlock', function (obj) obj.locked = false end),
			classy:addMethod ('fortify', function (obj) obj.fortress = true end),
			classy:addNotes (constants._VERSION .. '\n\n' .. constants._DESCRIPTION .. '\n' .. constants._LICENSE)
			)
```

This code uses the following classy methods:

|       Module     | Purpose |
|------------------|---------|
|classy:newClass | the class constructor. All classy constructor methods go inside this class constructor |
|class:attributes| defines the individual attributes this class has. Attributes can be mutable/immutable public/private. Immutable attributes cannot be changed one set, including to nil. Private attributes can only be addressed from within a class constructor function 

The valid class describers for class:attributes are:

* **Immutable** Immutable, Public same as PublicImmutable
* **Public** Mutable Public same as PublicMutable
* **PublicMutable** Mutable, Public same as Public
* **PublicImmutable** Immutable, Public same as Immutable
* **Private Mutable** Private same as PrivateMutable
* **PrivateMutable** Mutable, Private same as Private
* **PrivateImmutable** Immutable, Private  |

|       Module     | Purpose |
|------------------|---------|
|class:initMethod | this is the init method that runs when you create an object. This method has a paramter called obj, that is the object under construction |
|class:addPrivateMethod | adds a method only avaialble internally to the class constructors. This method has a paramter called obj, that is the object |
|class:addMethod        | adds a public facing method. This method has a paramter called obj, that is the object   |
|class:addNotes         | adds some notes for the class that can be displayed, see [Full Documentation](http://htmlpreview.github.com/?https://github.com/davporte/classy/blob/master/doc/index.html). This method has a paramter called obj, that is the object |

Constants does not use the overload classy method:

|       Module     | Purpose |
|------------------|---------|
| class:overload   | overloads an operator for a class. Note, except uniray minus, this method has two paramters called objA and objB that are the objects being acted upon |

Classy also adds protection to the _G global table to prevent the user from changing specific functions and constants used by classy. Classy will not load if _G already has a metatable.


## Special Thanks To 
[LuaUnit - a great unit testing tool](https://github.com/bluebird75/luaunit/tree/LUAUNIT_V3_2_1)

[Inspect - a great tool for inspecting LUA tables](https://github.com/kikito/inspect.lua)
