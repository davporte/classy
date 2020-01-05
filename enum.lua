local enum = {
	 _VERSION = ... .. '.lua 1.0.3',
     _URL = '',
     _DESCRIPTION = [[
      ============================================================================
     enum class built on constants class, built on classy OOP
   
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
      _DEPENDANCIES = { 'classy','constants' },
}

-- a refernce to the string type
local stringType, numType = type ( '' ), type ( 9 )

-- require dependancies if any
local dependancies = enum._DEPENDANCIES
if dependancies then
	if type ( dependancies ) == enum._TABLETYPE then
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


-- returns the class that deals with enumtypes 
return classy:newClass ( Constants,
			-- create the base enumtable this will consist of a Constants class, we will store each enum type in attributeStore inside constants
			classy:initMethod (					function ( obj, ... )
													-- run my super to init me, this creates an attributesStore that is immutable
													obj:callSuperMethod ( obj, 'init' )
													local count
													-- go through each entry and add them to the enum

													for count = 1, arg.n do
														local nameOfEnumObject = tostring ( arg [ count ] )
														obj.attributeStore [ nameOfEnumObject ] = count
														obj.attributeStore [ count ] = nameOfEnumObject
													end

												end
												),

			classy:addNotes (enum._VERSION .. '\n\n' .. enum._DESCRIPTION .. '\n' .. enum._LICENSE, ... )
			)
