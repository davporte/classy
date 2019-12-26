local constants = {
	 _VERSION = ... .. '.lua 1.1.2',
     _URL = 'https://github.com/davporte/classy/blob/master/constants.lua',
     _DESCRIPTION = [[
      ============================================================================
      constants manages all constants class and makes them imutable once 
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
   
      ============================================================================
      ]],
     _LICENSE = [[
      MIT LICENSE
      Copyright (c) 2019 David Porter
      Permission is hereby granted, free of charge, to any person obtaining a
      copy of this software and associated documentation files (the
      "Software"), to deal in the Software without restriction, including
      without limitation the rights to use, copy, modify, merge, publish,
      distribute, sublicense, and/or sell copies of the Software, and to
      permit persons to whom the Software is furnished to do so, subject to
      the following conditions:
      The above copyright notice and this permission notice shall be included
      in all copies or substantial portions of the Software.
      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
      OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
      MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
      IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
      CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
      TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
      SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
      ]],
      _MODULENAME = ...,
      _LOGGING = false,
      _TABLETYPE = type ( {} ),
      _DEPENDANCIES = { 'classy','inspect' },
}

-- a local function place holder
local mettaGetta

-- require dependancies if any
local dependancies = constants._DEPENDANCIES
if dependancies then
	if type ( dependancies ) == constants._TABLETYPE then
		local x
		for x = 1, #dependancies do
			if not _G [dependancies [x]] then
				_G [dependancies [x]] = require ( dependancies [x] )
			end
		end
	else
		_G [ dependancies ] = require ( dependancies )
	end
end

--- this returns a key stored in a tables metatable, we are doing this to forc __index/__newindex to control the attributes
-- @param t the table we want the  result from
-- @param k the particular key we want from t's metatable 
-- @return the value of key k in table t metatable 
local function indexLocal ( t, k )
	return getmetatable ( t ) [ k ] 
end

--- sets a key in a tables metatable, we are doing this to forc __index/__newindex to control the attributes.dependancies
-- If the key exists then an exception will be raised, as constants are immutable
-- @param t the table we want to set the value in ( it goes in its metatable )
-- @param k the particular key we want to set in t's metatable 
-- @param v the value we want to set the key to
-- @param path is text showing the attributes table structure, for error message
-- @param depth how far down in the stack are we for an error message
-- @return None 
local function newindexLocal ( t, k, v, depth, path )
	local mt = getmetatable ( t )
	if not mt [ k ] then
		mt [ k ] = mettaGetta ( v, depth, path .. '.' .. k )
	else
		error ( 'key ' .. path .. '.' .. k .. ' is immutable, and cannot be changed in ' .. constants._MODULENAME .. ' once it is set', depth )
	end
end

--- gets an attribute from the secretstore
-- @param obj the object
-- @param t the table we want the result from ( ignored as we are using secretStore )
-- @param k the particular key we want from the secretStore
-- @return the value from the secretStore or nil
local function gettingAttribute ( obj, t, k )
	if obj [ k ] then 
		return obj [ k ] 
	elseif obj.secretStore then
		return obj.secretStore [ k ] 
	end 
end


--- takes an attribute and if it is a table also makes that table immutable
-- @function metaGetta
-- @param v the value of attribute being set
-- @param depth how deep are we into the stack for error messages
-- @param path is text showing the attributes table structure, for error message
-- @return the value of the attribute, and if this is atable the approriate metatable is also attached
mettaGetta =  function ( v, depth, path )
	depth = depth + 1
	if type ( v ) == constants._TABLETYPE then -- attach we want this immutablity to propogte down through tables
		local mt = {
				__index = indexLocal,
				__newindex = function ( t, k, v ) newindexLocal ( t, k, v, depth, path ) end
		}
		-- move values over to the local metatable
		local next = next
		local key, val
		for key, val in next, v, nil do
			mt [ key ] = mettaGetta ( val, depth, path )
			v [ key ] = nil
		end
		return setmetatable ( v, mt )
	else
		return v
	end
end

--- sets atributes for a table, itterates through that table locking it down from change
-- @param obj the object making the call
-- @param t the table the attribute is being set
-- @param k the key we are setting
-- @param v the value we are setting
local function settingAttribute ( obj, t, k, v )
	if not (obj.locked or obj.fortress) then -- if we have not locked the store
		if not obj.secretStore [ k ] then -- if we have not already set the attribute, as we want attributes to be immutable			
			obj.secretStore [ k ] = mettaGetta ( v, 1, k )  
		else
			-- throw error +3, settingAttribute, __newindex, module
			error ( 'key ' .. k .. ' is immutable, and cannot be changed in ' .. constants._MODULENAME .. ' once it is set', 3 )
		end
	else 
		-- throw error +3, settingAttribute, __newindex, module
		error ('store is locked in ' .. constants._MODULENAME, 3 ) 
	end 
end

-- returns the class that deals with immutable constants
return classy:newClass (  
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
