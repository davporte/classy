------------
-- a test rig for classy.lua
-- @author David Porter
-- @release 1.0.2
-- @license MIT
-- @copyright (c) 2019 David Porter

-- for inspecting we use inspect: https://github.com/kikito/inspect.lua
-- a copy has been downloaded to this project for your convienence, but please refer to the orgional project link
inspect = require ('inspect.inspect')

-- load the classy module
classy = require ('classy')

-- turn off Garbage collection for these tests, some tests will fail as user objects are created in garbage collection
classy._GCEVENT = false

-- load up a sample class to test classy against
Constants = require ('constants')

-- log of test
local tests, failed = 0, 0

-- change to true to turn on logging
classy._LOGGING = false

-- for testing we use luaunit: https://github.com/bluebird75/luaunit/tree/LUAUNIT_V3_2_1
-- a copy has been downloaded to this project for your convienence, but please refer to the orgional project link
lu = require ('LuaUnit.LuaUnit')

-- string a number of attributes together as a string
local function stringTogether ( ... )
	message = ''
	local args = { ... }
	local x
	for x = 1, #args do
		message = message .. ' ' .. tostring ( args [x] )
	end

	return message
end

-- tests for exceptions
TypesOfTests = { }
	function TypesOfTests:exceptionForLockedAttribute ( A, attribute , value )
		local testFunction = function ( ) A [attribute]  = value end
		local result, msg = pcall ( testFunction )
		return ( not result ), msg
	end
	
		function TypesOfTests:noExceptionForLockedAttribute ( A, attribute , value )
		local testFunction = function ( ) A [attribute]  = value end
		local result, msg = pcall ( testFunction )
		return result, msg
	end

-- get the luaunit test names into the global table, so we can call them directly
local k, v
for k, v in next, TypesOfTests, nil do
	_G [ k ] = k
end

-- calls a TypesOfTests or a luaunit test
local function callTest (why, testFunction, ... )
	tests = tests + 1
	local description = 'calling Test:' .. tests .. ':\t' .. why .. ' ' .. testFunction .. ', with' .. stringTogether ( ... )
	local ok, err
	if lu [ testFunction ] then
		testFunction = lu [ testFunction ]
		ok, err =  pcall ( testFunction, ... )
	else
		ok, err = TypesOfTests [ testFunction ] ( callTest, ... )
	end

	if ok then
		description = description ..  ' -> Pass\n'
	else
		failed = failed + 1
		err = err or ''
		description = description  .. ' X Failed - ' .. err .. '\n'
	end

	print ( description )
end

-- create object a of Class Constants
local a = Constants ()
-- get its metatable
local aMeta = getmetatable ( a )

-- create object b of Class Constants
local b = Constants ()
-- get its metatable
local bMeta = getmetatable ( b )

-- run tests 

callTest ( 'objects have the same metatable', assertEquals, aMeta, bMeta )

callTest ( 'objects have the same attributes', assertEquals, aMeta._attributeStore, bMeta._attributeStore )

callTest ( 'objects are infact the same table', assertIs, aMeta._attributeStore, bMeta._attributeStore )

callTest ( 'objects have the differnt attributes stores', assertNotEquals, aMeta._attributeStore [  a  ], bMeta._attributeStore  [  b  ] )

callTest ( 'objects have different attributes tables ', assertStrMatches, tostring ( aMeta._attributeStore ), tostring ( bMeta._attributeStore ) )

callTest ( 'objects are identical once constructed', assertEquals, a, b )

callTest ( 'objects are not same table', assertNotIs, a, b )

b.attributeStore.c = 5

callTest ( 'objects are still identical once attribute added, as attributes stored in secretStore', assertEquals, a, b )

callTest ( 'however they are not equal if pulled from the secretStore', assertNotEquals, a.attributeStore.c, b.attributeStore.c )

a.attributeStore.c = 5

callTest ( 'objects are still identical once attribute added to other member, as attributes stored in secretStore', assertEquals, a, b )

callTest ( 'and they are equal if pulled from the secretStore', assertEquals, a.attributeStore.c, b.attributeStore.c )

callTest ( 'exception raised for locked attributes 1,', exceptionForLockedAttribute, a, 'attributeStore', {} )

callTest ( 'exception raised for locked attributes 2,', exceptionForLockedAttribute, a.attributeStore, 'c', 6 )

callTest ( 'exception raised for locked attributes 3,', exceptionForLockedAttribute, b.attributeStore, 'c', nil )

callTest ( 'exception raised for incorrect class', exceptionForLockedAttribute, b, 'test', 5 )

callTest ( 'exception raised unknow attribute', exceptionForLockedAttribute, a, 'doopy', false )

callTest ( 'exception raised locked attribute', exceptionForLockedAttribute, a, 'fortress', false )

a:removeSelf( )

callTest ( 'objects are are identical once removeSelf( ) executed', assertEquals, a, b )

callTest ( 'object a attribute store is nil in the class', assertIsNil, aMeta._attributeStore [ a  ] )

callTest ( 'object b attribute store is not nil in the class', assertNotIsNil, aMeta._attributeStore [  b  ] )

callTest ( 'object b attribute store is stillin the class so the _attributeStore should be still exist', assertNotIsNil, bMeta._attributeStore  )

b:removeSelf( )

callTest ( 'object b attribute store is nil in the class and as a was remove the _attributeStore should be nil', assertIsNil, bMeta._attributeStore  )

callTest ( 'objects are identical once removeSelf( ) executed on second attribute', assertEquals, a, b )

callTest ( 'objects are identical once removeSelf( ) executed on second attribute', assertEquals, a, b )

a.attributeStore = {  }

callTest ( 'object a is back, and correctly constructed so the _attributeStore should exist again', assertIsNil, aMeta._attributeStore  )

a = Constants ()

callTest ( 'object a is back, and correctly constructed so the _attributeStore should exist again', assertNotIsNil, aMeta._attributeStore  )

callTest ( 'object a attribute store is store should be exist', assertNotIsNil, aMeta._attributeStore [  a  ] )

callTest ( 'exception raised for immutble attributes attributeStore', exceptionForLockedAttribute, a, 'attributeStore', {} )

callTest ( 'no exception raised for adding attribute to a attributeStore', noExceptionForLockedAttribute, a.attributeStore, 'c', {} )

callTest ( 'exception raised for changing attribute to nil attributeStore', exceptionForLockedAttribute, a.attributeStore, 'c', nil )

callTest ( 'exception raised unknow attribute', exceptionForLockedAttribute, a, 'doopy', false )


print ( 'Tests run = ' .. tests, 'Tests Passed = ' .. tests - failed, 'Tests Failed = ' .. failed)

-- running a basic example of inhertance for a type called Enum

local Enum = require ('enum')
-- change to true to turn on logging
classy._LOGGING = true

local animal = Enum ( 'dog', 'cat', 'bird' )

-- returns 1 as dog first in list
print (animal.attributeStore.dog)

-- returns nil as enum 7 does not exist
print (animal.attributeStore [7])

-- returns cat as enum 2 exists
print (animal.attributeStore [2])

-- returns nil as enum fish does not exist
print (animal.attributeStore.fish )

-- remember to remove class objects specifically before nilling
animal:removeSelf ()
animal = nil
