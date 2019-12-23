local constants = {
	 _VERSION = ... .. '.lua 1.1.0',
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

-- returns the class that deals with immutable constants
return classy:newClass (  
			classy:attributes ( { attributeStore = Table ( Immutable ), locked = Bool ( Private ), fortress = Bool ( PrivateImmutable ), test = Table (), secretStore = Table ( Private ) } ),
			classy:initMethod (
					function (obj)
						-- set the attribute store up if not already there, user may have sent a constructor table
						if not obj.attributeStore then
							obj.attributeStore = {}
						end
						-- create a secret place to store the objects, we don't want to access directly
						obj.secretStore = {}

						-- the user may have called attributes store in the constructor with objects in that constructor so move them into the secret store
						local next = next
						local k, v

						for k, v in next, obj.attributeStore, nil do
							obj.secretStore [ k ] = v
							rawset ( obj.attributeStore, k, nil )
						end

						-- mark the class initially unlocked, we do not set fortress
						if not obj.locked then
							obj.locked = false
						end

						-- as secretStore is Private we need to create classy methods to affact change on them, as they can't call directly 
						-- we also have to test for obj values first before assumeing it is a secretStore Value
						obj.attributeStore.__index = function (t, k) if obj [ k ] then return obj [ k ] else return obj:getValue ( k ) end end
						obj.attributeStore.__newindex = function (t, k, v) obj:setValue ( t, k, v ) end 
						setmetatable (obj.attributeStore, obj.attributeStore)
					end
				),
			-- this method is required to enusre locked and fortress are addresable, they would not be inside __newindex
			classy:addMethod ('setValue', function ( obj, t, k, v ) 
												if not (obj.locked or obj.fortress) then -- if we have not locked the store
													if not obj.secretStore [ k ] then -- if we have not already set the attribute, as we want attributes to be immutable
														obj.secretStore [ k ] = v  
													else
														error ( k .. ' attribute, once set remain immutable', 5)
													end
												else 
													error ('store is locked', 5 ) 
												end 
											end),
			-- this method is required to enure secretStore is accessable, it would not be inside __index
			classy:addMethod ('getValue', function ( obj, k ) if obj.secretStore then return obj.secretStore [ k ] end end),
			-- note the above error is 5 because the source code is calling inside __newindex->setValue (class itself has 3 methods binding these calls)
			classy:addMethod ('lock', function (obj) obj.locked = true end),
			classy:addMethod ('unlock', function (obj) obj.locked = false end),
			classy:addMethod ('fortify', function (obj) obj.fortress = true end),
			classy:addNotes (constants._VERSION .. '\n\n' .. constants._DESCRIPTION .. '\n' .. constants._LICENSE, ... )
			)
