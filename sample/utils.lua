-----------
-- creates a utility class.
-- designed for use with the classy object creator
-- @usage Utils = require ( 'utils' )
-- @author David Porter
-- @module utils
-- @release 1.0.0
-- @license MIT
-- @copyright (c) 2019 David Porter

local utils = {
	 _VERSION = ... .. '.lua 1.0.0',
     _URL = '',
     _DESCRIPTION = [[
      ============================================================================
      A class that contains utilities that can be consumed as mixins by other classes

      Requires the classy OOP builder
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
      --- the module name
      _MODULENAME = ...,
      _DEPENDANCIES = { classy = 'classy' }
}

local Utils -- the classy reference to utils

-- a refernce to the various LUA types, generate them by code just incase it ever did change in the future
local _STRINGTYPE, _NUMTYPE, _TABLETYPE, _BOOLTYPE , _FUNCTYPE = type ( '' ), type ( 9 ), type ( {} ), type ( true ), type ( function () end )

--- constants used by the module
local CONSTANTS = { 
  METHODS = { GIVEMEFUNCTIONS = 'giveMeFunctions', -- the giveMeFunctions method name
  			ADDANOTHERFUNCTION = 'addAnotherFunction' -- the addAnotherFunction method name
  }
} -- the default methods names

-- @local require dependancies if any, this method will be removed after run creation of the module
local function getDependancies ()
  local dependancies = utils._DEPENDANCIES

  if dependancies then
      local next = next
      local k, v
      for k, v in next, dependancies, nil do
        if not _G [ k ] then
          _G [ k ] = require ( v )
        end
      end
  end

end

-- @local generate any dependancie
getDependancies ()
-- @local remove this 
getDependancies = nil

-- @section adjustments to string types

--- removes all WS from string
function string:stripAllWS()
	return self:gsub ('%s', '') 
end

--- removes leading and trailing WS
function string:removeLeadTrailWS() 
	return self:match('^%s*(.-)%s*$') 
end

--- tests a string for whitespace only or empty
function string:isWhiteSpaceOnly ()
	return self:match ('^%s*$') ~= nil
end

--- returns directory, filename, extension
function string:breakFilenameAppart () 
	return string.match(self, "(.-)([^\\/]-%.?([^%.\\/]*))$")
end

--- returns directory, filename, extension
function string:stripDirectory ()
	local _, f = self:breakFilenameAppart ()
	return f
end

--- returns directory, filename, extension
function string:stripFilename ()
	local d = self:breakFilenameAppart ()
	return d
end

-- changes state of pcall flag
function utils.pcallState ( obj, state )
	if state and type ( state ) == _BOOLTYPE then
		obj.pcallOn = state
	    obj.myLogger:Log_Info ( 'pcall state changes to ', state  )
	else
	    obj.myLogger:Log_Info ( 'attempt to change pcall state failed, requires true/false, you sent ', state )
	end
end

--- copies from one table to another
-- @param obj, the object making the call
-- @param from the from table
-- @param to the to table
-- @return No return Value
-- @usage obj:tableCopier ( FROM, TO )
-- @usage obj.tableCopier ( obj, FROM, TO )
function utils.tableCopier ( obj, from, to )
	if to and from and type ( to ) == _TABLETYPE and type ( from ) == _TABLETYPE then
		local x
		for x = 1, #from do
			to [#to + 1] = from [x]
		end
	else
	    obj.myLogger:Log_Error ( 'can\'t copy from, to if from or to is not a table' )
	end
end

--- takes a list l1, l2 ... ln and returns a k,v table based on that list l1 = l1, l2 = l2 ... ln = ln
-- @param obj, the object making the call
-- @param list the list
-- @return a key value pair table
-- @usage obj:listToKVPair ( item1 [, ... itemN ] )
-- @usage obj.listToKVPair ( obj, item1 [, ... itemN ] )
function utils.listToKVPair ( obj, list )
	local r
	if list then
		local x
		for x = 1, #list do
			local item = tostring ( list[ x ] )
			r = r or {}
			r [item] = list[x]
		end
	end

	return r
end

-- call pcal but can control if its on/off
function utils.pcall ( obj, ... )
	if obj.pcallOn then
		return pcall ( ... )
	else
		-- fake a pcall return, if the call crashes then code will stop
		local args = { ... }
	    obj.myLogger:Log_Debug ( 'pcall bypassed: ', utils.appendListWithComma ( obj, {select (2, ...)} ) , debug.getinfo(2).name )
		return true, args [1] ( select (2, ...) )
	end
end

--- logs a time difference between now an t1 to the Log_Info log
-- @param obj the object making the call
-- @param t1 the old time
-- @return No return value
-- @usage obj:timeDiff ( oldTime )
-- @usage obj.timeDiff ( obj, oldTime )
function utils.timeDiff ( obj, t1 )
    obj.myLogger:Log_Info ( 'Time elasped = ' , os.difftime( os.time(), t1 ) )
end


--- if data is a number it returns as a number
-- @param obj the object making the call
-- @param data the data under test
-- @return data as a number or the orgional value
-- @usage obj:dataIsNumber ( DataUnderTest )
-- @usage obj.dataIsNumber ( obj, DataUnderTest )
function utils.dataIsNumber ( obj, data )
	if data then
		if tonumber (data) then
			data = tonumber (data)
		end
	end

	return data
end

--- replaces data references.
-- For example you set dataKey = data, then we look in tbl for refernces data/XXX, if we find such a reference we look in data for a key XXX, if we find key XXX we replace data/XXX with the value of key XXX
-- @param obj the object making the call
-- @param dataKey the data key your are looking to replace
-- @param tbl the table that contains the data to look at, if you see the data key then replace that with information in teh data table
-- @param data table that contains the replacment values
-- @return true if success false if failed
-- @usage obj:replaceDataReferences ( TheDataKeyYouAreLookingFor ( e.g. Data ), TheTableYouWantToTest, TheKeyReplaceMents )
-- @usage obj.replaceDataReferences ( obj, TheDataKeyYouAreLookingFor ( e.g. Data ), TheTableYouWantToTest, TheKeyReplaceMents )
function utils.replaceDataReferences ( obj, dataKey, tbl, data )
	if data then -- only do if data exists
		-- get datKeys to search with
		local firstDataKey = dataKey .. '[^\t "\']+'
		local secondDataKey = '[^' .. dataKey .. '].*'
		-- go through key value pairs of the table tbl
		local k, v
		local next = next
		for k, v in next, tbl, nil do
			if type (v) == _TABLETYPE then
			-- check that table
				utils.replaceDataReferences ( obj, dataKey, v, data)
			elseif type (v) == _STRINGTYPE then
			-- it is a string so may be a reference
				_theFinder = function (str, list)
					local value = str:match (firstDataKey)
					if value then
						list = list or {}
						local start, stop = str:find (firstDataKey)
						if start ~= 1 then
							list [#list + 1] = {s = str:sub (1, start - 1)}
						end
						--print (value, value:match (secondDataKey), secondDataKey)
						list [#list + 1] = {v = value:match (secondDataKey), s = value}
						if stop ~= str:len() then
							list = _theFinder (str:sub (stop + 1), list)
						end
					else
						-- may be the end of a string
						if list then
							list [#list + 1] = {s = str}
						end
					end

					return list
				end

				local _theReplacer
				_theReplacer = function (str, recursionTest)
					local list = _theFinder (str)
					--if list then print ('\n\n',inspect (list)) end
					-- if list exists we found a match so replace keys
					if list then
						local replacement = ''
						local x
						local failed_to_find = false -- flag sets if any key is failed to find stops recalling replacer
						local last_was_table = false -- flag so we avoid " at the end of a table
						for x = 1, #list do
							local entry = list [x]
							if entry.v then -- it is a match for a data entry
								if data [entry.v] then
									recursionTest = recursionTest or {}
									if not recursionTest [data [entry.v]] then
										local newV = data [entry.v]
										if type (newV) == _TABLETYPE then
											newV = utils.tableToString ( obj, newV )
											-- remove the preceding character it may be a " from json
											local len = replacement:len()
											if len ~= 0 then
												replacement = replacement:sub (1, len - 1)
											end
											last_was_table = true
										end
										obj.myLogger:Log_Debug ('attempt to replace data key "' , entry.v , '" success' , newV)
										replacement = replacement .. newV
										recursionTest [entry.v] = true
									else
										obj.myLogger:Log_Error ('attempt to replace data key "' , str , '" failed, recursion detected from "' ,  inspect (data [entry.v]), '"')
										return nil
									end
								else
									obj.myLogger:Log_Warning ('attempt to replace data key "' , entry.v , '" failed, no such data key: in value "' ,str , '"')
									replacement = replacement .. entry.s
									failed_to_find = true
								end
							else -- it is not a match for a data entry
								if last_was_table then
									replacement = replacement .. entry.s:sub(2)
									--last_was_table = false
								else
									replacement = replacement .. entry.s 
								end
							end
						end

						if not failed_to_find then -- check the replacement incase it has references
							return _theReplacer (replacement, recursionTest)
						end
					end
					return str
				end

				local value = _theReplacer (v)
				if value then
					if tonumber (value) then -- it is a number
						value = tonumber (value)
					else
						local possibleTable = utils.stringToTable ( obj, value, true )
						if possibleTable then
							value = possibleTable
						end
					end
					tbl [k] = value
				else
					return false
				end
			end
		end
	end
	return true
end

--- transforms a string to a table, loggingOff stops all warnings 
-- @param obj the object making the call
-- @param str the string to convert
-- @param loggingOff can turn logging off for this method
-- @return data string as a table or nil if failed
-- @usage obj:stringToTable ( String [, true ] )
-- @usage obj.stringToTable ( obj, String [, true ] )
function utils.stringToTable ( obj, str, loggingOff )
	if str and type (str) == _STRINGTYPE then
		local subString = str:removeLeadTrailWS ()
		if subString:removeLeadTrailWS():sub (1,1) == '{' and subString:sub (subString:len()) == '}' then -- it is a possible table, as starts with { and ends with }
			-- splits based on { ... }
			local split, _, matchCounter = utils.breakAppart ( obj, str, true, 0, '{', '}' )
			-- error message if this does not resolve
			if not split or matchCounter ~= 0 then
				if not loggingOff then
					if type (str) == _STRINGTYPE then
						obj.myLogger:Log_Warning ('Not a valid table for stringToTable, "' , str , '", please check { ... } match')
					else
						obj.myLogger:Log_Warning ('Not a valid string for stringToTable, "' , type (str), '", please send string type')
					end
				end
				return nil
			else
				-- constructs the individual characters back to strings
				local _constructor
				_constructor = function ( obj, tbl, store )
								if tbl then
									local next = next
									local k,v
									local r
									for k,v in next, tbl, nil do
										if type (v) == _TABLETYPE then
											store [#store + 1] = _constructor ( obj, v, {} )
										else
											if tonumber (k) then
												r = r or ''
												r = r .. v
											end
										end
									end
									store [#store + 1] = r
								end
								
								return store
							end

				local constructed = _constructor ( obj, split, {} )

				-- sometimes key has leading/training whitepace or is bound by ", this removed this
				local _stringScruber =  function ( value )
					value = value:removeLeadTrailWS()
					if value:sub (1,1) == '"' then
						value = value:sub(2,value:len()-1):removeLeadTrailWS()
					end	
					return value		
				end
				--

				-- we may have embedded tabl {{{{{}}}}}, so look for that first, it occures if we just have tbl and white space
				local _embeddedTester
				_embeddedTester = function ( obj, tbl )
									local x
									local embedded = true
									for x = 1, #tbl do
										tblXType = type ( tbl [ x ] )
										if tblXType == _STRINGTYPE then
											if tbl [ x  ]:removeLeadTrailWS() ~= ''  then
												embedded = false
												break
											end
										elseif tblXType ~= _TABLETYPE then
											embedded = false
											break
										end
									end
									return embedded
								end

				-- analises the results and reconstructs a table
				local _analizer
				_analizer = function ( obj, tbl, store )
								-- ensure we have a table and it's not empty
								if tbl and type ( tbl ) == _TABLETYPE and not utils.tableIsEmpty ( obj, tbl ) then
									local next = next
									local x
									-- _constructor will always have this struncture { item, item, item, string}, where string is the comma structure of the items or empty if a closed table {{}}
									local structure

									if _embeddedTester ( obj, tbl ) then
										return { _analizer ( obj, tbl[1], store ) }
									end		

									structure = tbl[#tbl]:removeLeadTrailWS()

									local commaStructure = utils.splitStringAccountingForStrings ( obj, structure, ',' )
									-- if we begin with a , or end with a , we need to add this as it wont be in structure
									local newCommasStructure = {}
									if structure:sub(1,1) == ',' then
										newCommasStructure [#newCommasStructure + 1] = ''
									end
									for x = 1, #commaStructure do
										newCommasStructure [#newCommasStructure + 1] = commaStructure[x]
									end
									if structure:sub(structure:len(),structure:len()) == ',' then
										newCommasStructure [#newCommasStructure + 1] = ''
									end
									--
									local resultTable = {}
									-- lastTble points to the items as the are consumed via looking at structure
									local lastTbl = 1
									-- go through the dtructure
									for x = 1, #newCommasStructure do
										-- remove leading trailing spaces
										local trimmedStructure = newCommasStructure[x]:removeLeadTrailWS()
										-- this indicates a comma so we need to consume an item
										local commaFound = newCommasStructure[x]:removeLeadTrailWS() == ''
										-- we may have key = {table}, as _constructor broke appart based on { .. }, we will have to assign the table later once we have resolved they key 
										local lastCharIsEquals = trimmedStructure:sub(trimmedStructure:len(),trimmedStructure:len()) == '='
										local key, value
										if lastCharIsEquals or commaFound then
											-- lets test the next item
											local reanalize = _analizer ( obj, tbl [lastTbl], {} )
											if not reanalize then -- must be an empty set
												if lastCharIsEquals then
													-- ok we had key = and no result so must be an empty set _constructor does not return these
													key = trimmedStructure:sub (1, trimmedStructure:len() - 1):removeLeadTrailWS()
													--store [trimmedStructure:sub (1, trimmedStructure:len() - 1):removeLeadTrailWS()] = {}
												end
												-- this is an empty table
												value = {}
											else
												if lastCharIsEquals then
													-- ok we had key = item, where item is not the empty set
													local equalsData = utils.splitStringAccountingForStrings ( obj, trimmedStructure, '=' )
													key = _stringScruber (equalsData[1])
												end
												value = reanalize
												-- as we have consumed an item move the item counter forward
												lastTbl = lastTbl + 1
											end
										else
											-- get the value as it is a pure item
											value = newCommasStructure[x]:removeLeadTrailWS()
											-- test to see if it was a number
											local isDataNumber = tonumber (value) ~= nil
											-- as it was a string we may have key = item so resolve that
											if not isDataNumber then
												local equalsData = utils.splitStringAccountingForStrings (value, '=')
												if #equalsData == 1 and value:sub (value:len(),value:len()) ~= '=' then
													value = value--:sub(2,value:len())
												elseif #equalsData == 2 then
													key = _stringScruber (equalsData [1])
													value = _stringScruber (equalsData [2])
												end
											end

										end
										-- if value is number move it back to a number as process evaluated using strings
										value = utils.dataIsNumber ( obj, value )
										-- store key value pair
										if key then
											store [key] = value
										else
											store [#store + 1] = value
										end
									end
									if lastTbl ~= #tbl then
										obj.myLogger:Log_Warning ('table resolve error between entry: "', newCommasStructure [#newCommasStructure], '" and open table {' )
										return nil
									end
									return store
								else
									if type ( tbl ) == _STRINGTYPE then 
										if tbl:removeLeadTrailWS () == '' then
											return nil
										else
											return tbl
										end
									end
									return {}
								end
							end

				return _analizer ( obj, constructed[1], {})
			end
		else
			if not str then
				obj.myLogger:Log_Warning ('Not a valid string stringToTable, nil' )
			else
				obj.myLogger:Log_Warning ('Not a valid table for stringToTable, "' .. str .. '", please check { ... } match')
			end
		end
	end

	return nil
end

--- transforms a table to a string, note we can force commas and " .. " away and change the bracket with specials table 
-- @param obj the object making the call
-- @param tbl the table to convert
-- @param specials an optional list of controls that sets the values for quote ", comma , , open table bracket { and close table bracket }
-- @return table as string or nil if failed
-- @usage obj:tableToString ( Table [, { OptionalChangesToSpecialCharacters } ] )
-- @usage obj.tableToString ( obj, Table [, { OptionalChangesToSpecialCharacters } ] )
function utils.tableToString ( obj, tbl, specials )
	if not specials or type (specials) ~= _TABLETYPE then
		specials = {}
	end
	specials.quote = specials.quote or '"'
	specials.comma = specials.comma or ','
	specials.oBracket = specials.oBracket or '{'
	specials.cBracket = specials.cBracket or '}'
	if specials.keys == nil then specials.keys = true end
		
	if not utils.tableIsEmpty ( obj, tbl ) then
		str = specials.oBracket
	else
		str = specials.oBracket .. specials.cBracket
	end
	local next = next
	local k, v
	for k, v in next, tbl, nil do
		if not tonumber (k) and specials.keys then 
			str = str .. k .. '='
		end
		if type (v) == _TABLETYPE then
			if utils.tableIsEmpty ( obj, v ) then
				str = str .. specials.oBracket .. specials.cBracket
			else
				str = str .. utils.tableToString ( obj, v, specials ) 
			end
		else
			if type (v) == _STRINGTYPE then
				str = str .. specials.quote .. tostring (v) .. specials.quote
			else
				str = str .. tostring (v)
			end
		end
		str = str .. specials.comma
	end
	return str:sub (1,str:len() - 1).. specials.cBracket
end

--- sets the a default data type values
local dataDefaults = { 	[ _STRINGTYPE ] = '', -- string defaults to ''
						[ _NUMTYPE ] = 0, -- number defaults to 0
						[ _TABLETYPE ] = { } -- table defaults to { }
					}

--- default type values, nil if not defined
-- @param obj the object making the call
-- @param dataType the data type to get the default value for
-- @return the data type default value or nil
-- @usage obj:defaultDataValue ( DataType )
-- @usage obj.defaultDataValue ( obj, DataType )
function utils.defaultDataValue ( obj, dataType )
	if dataDefaults [ dataType ] then
		return dataDefaults [ dataType ]
	else
		return nil
	end
end

--- removes metatables recursivley
--- default type values, nil if not defined
-- @param obj the object making the call
-- @param tab the table you want to do this for
-- @return No return value
-- @usage obj:getRidofMetaTables ( Table )
-- @usage obj.getRidofMetaTables ( obj, Table )
function utils.getRidofMetaTables ( obj, tab )
	if type (tab) == _TABLETYPE then
		setmetatable( tab, nil )
		local k, v
		local next = next
		for k, v in next, tab, nil do
			utils.getRidofMetaTables ( obj, v )
		end
	end
end

--- takes a string array and returns a k,v pair table with v == true or value, if table passed it returns the table as the value
-- @param obj the object making the call
-- @param str the list in keys you want as a table
-- @param value the value you want to set the keys to, defaults to true
-- @return A table
-- @usage obj:stringsToTable ( StringList [, DefaultValue ] )
-- @usage obj.stringsToTable ( obj, StringList [, DefaultValue ] )
function utils.stringsToTable ( obj, str, value )
	if not value then value = true end
	if type (str) == _STRINGTYPE then
		str = {str}
	end
	local tbl
	local x
	for x = 1, #str do
		local next_str = str [x]
		tbl = tbl or {}
		if  type (next_str) == _STRINGTYPE then
			tbl [next_str] = value
		else
			tbl  = next_str
		end
	end

	return tbl
end

--- dumps a table into a string
-- @param obj the object making the call
-- @param tbl the table you want as a string
-- @param tabs the tab indents for formating
-- @return the formated dump string or the empty string if error
-- @usage obj:dumpTable ( Table )
-- @usage obj.dumpTable ( obj, Table )
function utils.dumpTable ( obj, tbl, tabs )
	if tbl and type (tbl) == _TABLETYPE then
		local result = '\t'
		if not tabs then
			tabs = '\t'
		end
		local next = next
		local k, v
		for k, v in next, tbl, nil do
			if type (v) == _TABLETYPE then
				result = result .. utils.dumpTable ( obj, v, tabs .. '\t' )
			else
				result = result .. k .. '\t' .. tostring (v) .. '\n\t'
			end
		end
		return result
	end

	return ''
end

--- converts a number to number with english follow on eg 1st 2nd 3rd 4th etc
-- @param obj the object making the call
-- @param n the number
-- @return a string with the correct attachment
-- @usage obj:appendTextOnNumber ( Number )
-- @usage obj.appendTextOnNumber ( obj, Number )
function utils.appendTextOnNumber ( obj, n )
	n = tonumber (n)
    local p  = 10^0
	n = math.floor(n * p) / p
	local v = n
	if n ~= 0 then
		local values = {'st','nd','rd'}
		n = n - math.floor (n/100) * 100
		local teens = n > 10 and n < 20
		n = n - math.floor (n/10) * 10
		if n == 0 or n > #values or teens then
			return v  .. 'th'
		else
			return v  .. values [n]
		end
	else
		return v
	end
end

--- unpack, unpacks a table or if already not a table just returns paramter stream
-- @param obj the object making the call
-- @param ... the paramter list or a table to unpack
-- @return an unpack value
-- @usage obj:unpack ( ... )
-- @usage obj.unpack ( obj, ... )
function utils.unpack ( obj, ... )
	if arg ~= nil then -- arguments exist
		if arg.n == 1 and type ( arg [ 1 ] ) == _TABLETYPE then -- more than one argument and a table so a list, therefore unpack
			obj.myLogger:Log_Debug ( _TABLETYPE , ' sent, unpacking')
			if Utils:isVersionFivePointTwoOrAbove () then
				return table.unpack ( arg [ 1 ] )
			else
				return unpack ( arg [ 1 ] )
			end
		end
		obj.myLogger:Log_Debug ( 'args sent, not unpacking' )
		return ...
	end

	obj.myLogger:Log_Info ( 'sent no parameters to unpack' )
	return nil
end

--- returns a table corresponding to the items descovered between matchA, matchB; by default matchA = '(', matchB = ')'; iter is the string iterated across
-- @param obj the object making the call
-- @param iter the data under test, this gets called recursively
-- @param careAboutStrings true if we care about lookin if the match characters are bound in a string or not, if we care and we are we ignore them when in a string
-- @param matchCounter counts the number of opens vs closes to ensure we have a complete match
-- @param matchA the open match character
-- @param matchB the close match character
-- @param hasOccured turns true if a pair is found matchA .... matchB
-- @param matchAOcurred turns true if we have found a matchA only, lets us know to look for matchB
-- @param level how deep are we in the recursion
-- @param items a table of the items found
-- @param stringsActive the current state of strings, are they active i.e. we are in a string, or inactive i.e. we are not in a string
-- @return the items brocken appart in a table, c ( an internal counter ), the matchCounter ( should be 0, i.e. complete closure ), has occured true or false
-- @usage obj:breakAppart ( String, true, 0, '{', '}' ) -- breaks appart tables
-- @usage obj.breakAppart ( Obj, String, true, 0, '(', ')' ) -- breaks appart parenthesis
-- @see stringToTable
function utils.breakAppart ( obj, iter, careAboutStrings, matchCounter, matchA, matchB, hasOccured, matchAOcurred, level, items, stringsActive)
	if iter and type (iter) == _STRINGTYPE then
		matchCounter = matchCounter or 0
		hasOcuured = hasOccured or false -- marks if a pair was found:true
		matchAOcurred = matchAOcurred or false
		matchA = matchA or '(' 
		matchB = matchB or ')' 
		careAboutStrings = careAboutStrings or true
		stringsActive = stringsActive or false
		if not level then level = 0 else level = level + 1 end
	    items = items or {} 
	    local c = 1
	    while c <= iter:len() do
	    	local item = iter:sub (c,c)
	    	if careAboutStrings and (item == '"' or item == "'") then
	    		stringsActive = not stringsActive
	    	end
	    	if not stringsActive then
		    	if item == matchA and not stringsActive then
		    		matchAOcurred = true
		    		local result, newC
		    		matchCounter = matchCounter + 1
		    		result, newC, matchCounter, hasOccured, matchAOcurred = obj.breakAppart ( obj, iter:sub (c+1), careAboutStrings, matchCounter, matchA, matchB, hasOccured, matchAOcurred, level, items [#items + 1], stringsActive)
		    		if newC then
			    		c = c + newC
			    	else
			    		return nil -- failed, probably mismatch NO matchB to a matchA
			    	end
		    		items [#items + 1] = result
		    	elseif item == matchB and not stringsActive then
		    		if matchAOcurred then hasOccured = true end
		    		items.level = level
		    		return items, c, matchCounter - 1, hasOccured, matchAOcurred
		    	else
		    		items [#items +1] = item
		    	end
		    else
	    		items [#items +1] = item
	    	end
	    	c = c + 1
	    end
	    items.level = level
	    -- should only get here once if there are enough brackets, matchcounter should be 0
	end
    return items, c, matchCounter, hasOccured
end

--- rebuilds strings that are brocken into a table
-- @param obj the object making the call
-- @param tableOfResults the strings in component parts
-- @param resultsRebuilt the results as they are computed itreatively
-- @return resultsRebuilt the rebuilt strings
-- @usage obj:rebuildStrings ( TableOfStrings )
-- @usage obj.rebuildStrings ( obj, TableOfStrings )
function utils.rebuildStrings ( obj, tableOfResults, resultsRebuilt )
	if not resultsRebuilt then resultsRebuilt = {} end
	local x
	local r = ''
	for x = 1, #tableOfResults do
		local currentValue = tableOfResults [x]
		if type (currentValue) == _TABLETYPE then
			resultsRebuilt [#resultsRebuilt + 1] = utils.rebuildStrings ( obj, currentValue )
		else
			r = r .. currentValue
		end
	end
	resultsRebuilt [#resultsRebuilt + 1] = r

	return resultsRebuilt
end

--- convert from strings, converts bools, number, tables to there orgional data form
-- @param obj the object making the call
-- @param tbl the object we want to convert to native form
-- @param tblResult the results as they are computed itreatively
-- @return the native form of the data object
-- @usage obj:convertFromStrings ( Table )
-- @usage obj.convertFromStrings ( obj, ... )
function utils.convertFromStrings ( obj, tbl, tblResult )
	if type (tbl) == _TABLETYPE then
		tblResult = tblResult or {}
		local k, v
		local next = next
		for k, v in next, tbl, nil do
			local result = utils.convertFromStrings ( obj, v, tblResult )
			tblResult [k] = result
		end

		return tblResult
	else
		if tbl == 'true' then
			return true
		elseif tbl == 'false' then
			return false
		elseif tonumber( tbl ) then
			return tonumber ( tbl )
		else
			return tbl
		end
	end
end

--- attempt a table deep copy, there are senarios where this module fails
-- @param obj the object making the call
-- @param onObj the object we want to deep copy
-- @param seen a flag the routine uses
-- @return a copy of the table
-- @usage obj:deepCopy ( ObjectToCopy )
-- @usage obj.deepCopy ( obj, ObjectToCopy )
function utils.deepCopy( obj, onObj, seen)
  if type( onObj ) ~= _TABLETYPE  then return onObj end
  if seen and seen[ onObj ] then return seen[ onObj ] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable( onObj ))
  s[ onObj ] = res
  for k, v in pairs( onObj ) do 
     res[utils.deepCopy( obj, k, s )] = utils.deepCopy( obj, v, s) 
  end
  return res
end

-- tests if all passed paramters are of a specific type and returns true or false. First paramter must be a type in the global constants table.
-- @param obj the object making the call
-- @param lookFor the data type we need to match
-- @param ... the list of paramters to test against the type
-- @return true if all are of type otherwise false
-- @usage obj:testParameters ( TypeToLookFor, Item1 [, ... itemN ] )
-- @usage obj.testParameters ( obj, TypeToLookFor, Item1 [, ... itemN ] )
function utils.testParameters ( obj, lookFor, ... )
	local x
	for x = 1 , arg.n do
		if not ( type (arg[ x ] ) == lookFor) then
			return false, '"' .. tostring(arg[x]) .. '" is not of type "' .. lookFor .. '"'
		end
	end
	return true
end

--- returns test if a parameter is a number or not
-- @param obj the object making the call
-- @param testValue the data type we need to match
-- @return true if is number otherwise false
-- @usage obj:testForNumber ( TestItem )
-- @usage obj.testForNumber ( obj, TestItem )
function utils.testForNumber ( obj, testValue )
	local numberConvertion = tonumber( testValue )
	if numberConvertion then
		return true, numberConvertion
	else
		return false, testValue
	end
end

--- tests to see if a table is empty or not
-- @param obj the object making the call
-- @param value the data type we need to match
-- @return returns true if a table is empty otherwise false, nil if not a table
-- @usage obj:tableIsEmpty ( TableToTest )
-- @usage obj.tableIsEmpty ( obj, TableToTest )
function utils.tableIsEmpty ( obj, value )
	if type (value) ~= _TABLETYPE then
		obj.myLogger:Log_Warning ('Not a valid table for tableIsEmpty, "' , type (value), '", please send ', _TABLETYPE, ' type')
		return nil
	else
		local next = next
		return next (value) == nil
	end
end

--- merges ... arrays into one array with duplicate removal.
-- Arrays are actually key value pairs of 1, 2, 3 ... N for the key
-- @param obj the object making the call
-- @param ... the arrays to merge
-- @return the merged array
-- @usage obj:mergeArrays ( Array1 [, ... ArrayN ] )
-- @usage obj.mergeArrays ( obj, Array1 [, ... ArrayN ] )
function utils.mergeArrays ( obj, ... )
	local x
	local result, names = {}, {}
	local namesString = tostring (names) -- unique random string
	for x = 1, arg.n do
		local arrayToMerge = arg [x]
		local y
		if arrayToMerge then
			for y = 1, #arrayToMerge do
				if type ( arrayToMerge[y] ) == _NUMTYPE then
					if not names [tostring (arrayToMerge[y]) .. namesString] then 
						names [tostring (arrayToMerge[y]) .. namesString] = true
						result [#result + 1] = arrayToMerge[y]
					end
				else
					if not names [arrayToMerge[y]] then
						names [arrayToMerge] = true
						result [#result + 1] = arrayToMerge [y]
					end
				end
			end
		end
	end
	return result
end

--- merges ... tables into one table with duplicate removal.
-- Arrays are actually key value pairs of not 1, 2, 3 ... N for the key
-- @param obj the object making the call
-- @param ... the arrays to merge
-- @return the merged table
-- @usage obj:mergeTables ( Table1 [, ... TableN ] )
-- @usage obj.mergeTables ( obj, Table1 [, ... TableN ] )
function utils.mergeTables ( obj, ... )
	local x
	local result = {}
	for x = 1, #arg do
		local tableToMerge = arg [x]
		local k, v
		for k, v in next, tableToMerge, nil do
			if result [k] then -- exists already, so add numbers, concantonate tables, run functions after each other or merge tables
				if type (result [k]) == _NUMTYPE and type (v) == _NUMTYPE then
					result [k] = result [k] + v
				end
			else
				result [k] = v
			end
		end
	end
	return result
end

--- returns set in set and set not inset 
-- @param obj the object making the call
-- @param setA the first set
-- @param setB the second set
-- @return items in both sets as a set, those items unique to either setA or setB as a set
-- @usage obj:setInSet ( { setAMember1Key = valueA1 [, ... setAmMemberN = valueAN ] }, { setBMember1 = valueB1 [, ... setBmMemberN = valueBN ] } )
-- @usage obj.setInSet ( obj, { setAMember1Key = valueA1 [, ... setAmMemberN = valueAN ] }, { setBMember1 = valueB1 [, ... setBmMemberN = valueBN ] } )
function utils.setInSet ( obj, setA, setB )
	local k, v
	local both, unique = {}, {}
	local setCheck = {setA, setB}
	local x, first, second
	for x = 1, #setCheck do
		first = setCheck [x]
		second = setCheck [#setCheck - x + 1]
		for k, v in next, first, nil do
			if second[k] then
				if not both[k] then 
					both[k] = k
				end
			else
				unique[k] = k
			end
		end
	end
	return both, unique
end

--- removes values and returns keys
-- @param obj the object making the call
-- @param list a table 
-- @return a list of key only in an array
-- @usage obj:dropValues ( { key1 = value1 [, ... keyN = valueN ] } )
-- @usage obj.dropValues ( obj, { key1 = value1 [, ... keyN = valueN ] } )
function utils.dropValues ( obj, list )
	local r = {}
	local k, v
	for k, v in next, list, nil do
		r [#r+1] = k 
	end
	return r
end

--- returns the key for a value if value found in a list otherwise nil.
-- If two or more occurances then only first is reported.
-- @param obj the object making the call
-- @param value the value we are looking for
-- @param list the key value pair we are looking in
-- @return a list of key only in an array
-- @usage obj:isValueinList ( ForWhat, { key1 = value1 [, ... keyN = valueN ] } )
-- @usage obj.isValueinList ( obj, ForWhat, { key1 = value1 [, ... keyN = valueN ] } )
function utils.isValueinList ( obj, value, list )
	local k, v
	for k, v in pairs (list) do
		if v == value then return k end
	end
	return nil
end

--- returns nil if all values are in list otherwise any missing keys in comma seperated string
-- @param obj the object making the call
-- @param values the value we are looking for
-- @param list the key value pair we are looking in
-- @return returns nil if all values are in list otherwise any missing keys in comma seperated string
-- @usage obj:allValueinList ( { value1 [, ... valueN ] } , { key1 = value1 [, ... keyN = valueN ] } )
-- @usage obj.allValueinList ( obj,{ value1 [, ... valueN ] } , { key1 = value1 [, ... keyN = valueN ] } )
function utils.allValueinList ( obj, values, list )
	if not values then values = {} end
	if not list then list = {} end
	local k, r
	for k, _ in next, values, nil do
		if not list [k] then
		 if not r then r = {} end
		 r [#r + 1] = k
		end
	end
	if r then
		r = utils.appendListWithComma ( obj, r )
	end
	return r
end


--- returns the value for a key if key found in a list otherwise nil
-- @param obj the object making the call
-- @param key the key we are looking for
-- @param list the key value pair we are looking in
-- @return returns the value for a key if key found in a list otherwise nil
-- @usage obj:isKeyinList ( { key , { key1 = value1 [, ... keyN = valueN ] } )
-- @usage obj.isKeyinList ( obj, key , { key1 = value1 [, ... keyN = valueN ] } )
function utils.isKeyinList ( obj, key, list )
	local k, v
	for k, v in pairs (list) do
		if k == key then return v end
	end
	return nil
end

--- append with comma, appends item to string with comma separation
-- @param obj the object making the call
-- @param str the orgional string or nil
-- @param append item to append
-- @return returns the orgional string , append or if only one parameter the nappend only
-- @usage obj:appendWithComma ( 'string1', 'string2' ) -- outputs string1, string2
-- @usage obj.appendWithComma ( obj, 'string1', 'string2' ) -- outputs string1, string2
-- @usage obj:appendWithComma ( 'string2' ) -- outputs string2
-- @usage obj.appendWithComma ( obj, 'string2' ) -- outputs string2
function utils.appendWithComma ( obj, str, append )
	if not str then 
		str = append
	else
		str = str .. ', ' .. append
	end

	return str
end

--- append list with comma, creates a string with commas
-- @param obj the object making the call
-- @param list the list looking in
-- @return returns the list as comma separated
-- @usage obj:appendListWithComma ( { value1 [, ... valueN ] } )
-- @usage obj.appendListWithComma ( obj, { value1 [, ... valueN ] } )
function utils.appendListWithComma ( obj, list )
	local x
	local r = ''
	for x = 1, #list do
		if x == #list then
			r = r .. tostring (list[x])
		else
			r = r .. tostring (list[x]) .. ', '
		end
	end
	return r
end

--- append keys with comma, creates a string with commas based on key in a key1, ... keyN string
-- @param obj the object making the call
-- @param kvPair the list looking in
-- @return returns the list as comma separated string key1, ... keyN
-- @usage obj:appendKeysWithComma ( { key1 = value1 [, ... keyN = valueN ] } )
-- @usage obj.appendKeysWithComma ( obj, { key1 = value1 [, ... keyN = valueN ] } )
function utils.appendKeysWithComma ( obj, kvPair )
	local list = {}
	local k
	for k, _ in pairs (kvPair) do
		list [#list + 1] = k
	end
	return utils.appendListWithComma (list)
end

--- append values with comma, creates a string with commas based on key in a value1, ... valueN string
-- @param obj the object making the call
-- @param kvPair the list looking in
-- @return returns the list as comma separated string value1, ... valueN
-- @usage obj:appendValuesWithComma ( { key1 = value1 [, ... keyN = valueN ] } )
-- @usage obj.appendValuesWithComma ( obj, { key1 = value1 [, ... keyN = valueN ] } )
function utils.appendValuesWithComma ( obj, kvPair )
	local list = {}
	local v
	for _, v in pairs (kvPair) do
		list [#list + 1] = v
	end
	return utils.appendListWithComma ( obj, list )
end

--- prints k, v pairs to the logger as Info
-- @param obj the object making the call
-- @param table the k, v pairs you want to log
-- @return rNo return value
-- @usage obj:appendValuesWithComma ( { key1 = value1 [, ... keyN = valueN ] } )
-- @usage obj.appendValuesWithComma ( obj, { key1 = value1 [, ... keyN = valueN ] } )
function utils.printKeyValues ( obj, table )
	if table and type ( table ) == _TABLETYPE then
		local k, v
		for k, v in next, table, nil do
			obj.myLogger:Log_Info ( 'k = ', k, 'v = ', v )
		end
	end
end

--- splits a string into a table
-- @param obj the object making the call
-- @param str the string
-- @param pat the pattern that splits the string, this defaults to comma ,
-- @return a table with results of string:str split by character split, defaults to ','
-- @usage obj:splitString ( StringToSplit [, PatternThatSplits ] )
-- @usage obj.splitString ( obj, StringToSplit [, PatternThatSplits ] )
function utils.splitString ( obj, str, pat )
	if not pat then pat = ',' end
	local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(t,cap)
		end
		last_end = e+1
		s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
		cap = str:sub(last_end)
		table.insert(t, cap)
	end
	return t
end

--- splits strings but aslo removes all trailing an leading removeLeadTrailWS
-- @param obj the object making the call
-- @param str the string
-- @param pat the pattern that splits the string, this defaults to comma ,
-- @return a table with results of string:str split by character split, defaults to ','
-- @usage obj:splitStringWithClean ( StringToSplit [, PatternThatSplits ] )
-- @usage obj.splitStringWithClean ( obj, StringToSplit [, PatternThatSplits ] )
function utils.splitStringWithClean ( obj, str, pat )
	local t = utils.splitString (str, pat)
	local x
	for x = 1, #t do
		t[x] = t[x]:removeLeadTrailWS ()
	end
	return t
end

--- returns a table with results of string:str split by character split, but also checks for strings.
-- If pat is found inside astring it will not match.
-- @param obj the object making the call
-- @param str the string
-- @param pat the pattern that splits the string, this defaults to comma ,
-- @return a table with results of string:str split by character split, defaults to ','
-- @usage obj:splitStringAccountingForStrings ( StringToSplit [, PatternThatSplits ] )
-- @usage obj.splitStringAccountingForStrings ( obj, StringToSplit [, PatternThatSplits ] )
function utils.splitStringAccountingForStrings ( obj, str, pat )
	-- first break appart and rebuild
    local c = 1
    local stringTable
    local currentString = ''
    local stringsActive = false
    local justFinishedStrings = false
    while c <= str:len() do
    	local item = str:sub (c,c)
    	if item == '"' or item == "'" then
    		stringTable = stringTable or {}
    		stringsActive = not stringsActive
    		if stringsActive then
    			if not (currentString == '' and #stringTable == 0) then
	    			local resultTable = {str = currentString, search = true}
	    			stringTable [#stringTable + 1] = resultTable
	    			currentString = ''
	    		end
    		else
    			local resultTable = {str = currentString .. item, search = false}
    			stringTable [#stringTable + 1] = resultTable 
    			currentString = ''
    			--c = c + 1
    			item = ''
    		end
    	end
    	currentString = currentString .. item
    	c = c + 1
    end

    if stringTable then
	    stringTable [#stringTable + 1] = {str = currentString, search = not stringsActive}
	end


	-- now reconstruct or just call splitString if no strings detected
    if not stringTable then
		return utils.splitString ( obj, str, pat )
	else
		local appendFlag = false
		local lastWasEmpty = false
		local endsWithMatch = false
		local resultTable = {}
		local x
		for x = 1, #stringTable do
			-- if we need to search for the pattern
			if stringTable[x].search then
				-- note if the pattern is at start of the string
				local startsWithMatch = not (stringTable[x].str:find ('^' .. pat) == nil)

				--print ('starts = ', startsWithMatch, endsWithMatch)
				-- split the string based on the pattern
				local r = utils.splitString ( obj, stringTable[x].str, pat )
				-- if the result is not empty, empty means it was just a 'pat' in the string
				--print ('r:','\n'..inspect (r))
				if not utils.tableIsEmpty ( obj, r ) then
					local y
					-- start at first entry in r by default
					local c = 1
					--if endsWithMatch then print ('ewm',stringTable[x].str) end
					--print ('append', appendFlag, 'startsWithMatch', startsWithMatch)
					if appendFlag and not startsWithMatch then
						-- append to previoius result, except if we started with 'pat' 
						--print ('so appending', lastWasEmpty, endsWithMatch)
						if not lastWasEmpty and not endsWithMatch then
							-- append last entry
							resultTable [#resultTable] = resultTable [#resultTable] .. r [1]
							-- start from 2 onwards in r as we consumed 1
							c = 2
						else
							lastWasEmpty = false
						end
						appendFlag = false
					end

					for y = c, #r do
						resultTable[#resultTable + 1] = r[y]
					end
					lastWasEmpty = false
				-- it was empty so note it
				else
					lastWasEmpty = true
				end
				-- note if the pattern is at end of the string
				--endsWithMatch = not (stringTable[x].str:find ( pat .. '$') == nil)
				--print ('ewm = ', stringTable[x].str, endsWithMatch) 
			else
				--print ('no search')
				--if #resultTable == 0 then
				--	resultTable [#resultTable + 1] = '' -- incase starts with string
				--end
				if not endsWithMatch then
					if #resultTable == 0 then resultTable [#resultTable + 1] = '' end
					resultTable [#resultTable] = resultTable [#resultTable] .. stringTable[x].str
				else
					resultTable [#resultTable + 1] =  stringTable[x].str
				end
				appendFlag = true
			end
			-- note if the pattern is at end of the string
			endsWithMatch = not (stringTable[x].str:find ( pat .. '$') == nil)
			if endsWithMatch then
				appendFlag = false
			end
			--print ('endsWithMatch', stringTable[x].str, endsWithMatch)
		end
		return resultTable
	end
end

--- returns true / false based on object type and count
-- @param obj the object making the call
-- @param object the object under test
-- @param whatType the type you need to match
-- @param whatCount the count you need to match
-- @return true if type not equal or count not equal, false if type is equal and count is equal
-- @usage obj:typeCount ( TestItem, TypeToTest, CountToTest )
-- @usage obj.typeCount ( obj, TestItem, TypeToTest, CountToTest )
function utils.typeCount ( obj, object, whatType, whatCount )
	return type (object) ~= whatType or #object ~= whatCount
end


--- returns the names of arguments passed to a function func as a csv string.
-- Note if debug is off this does not operate and returns a message
-- @param obj the object making the call
-- @param func the function under test
-- @return debug information
-- @usage obj:getArgs ( TestFunction )
-- @usage obj.getArgs ( obj, TestFunction )
function utils.getArgs ( obj, func )
	if _G.debug then
		local args = {}
		local hook = debug.gethook()

		local argHook = function( ... )
		    local info = debug.getinfo (3)
		    if 'pcall' ~= info.name then return end

		    for i = 1, math.huge do
		        local name, value = debug.getlocal(2, i)
		        if '(*temporary)' == name then
		            debug.sethook(hook)
		            error('')
		            return
		        end
		        table.insert (args,name)
		    end
		end

		debug.sethook (argHook, "c")
		pcall (func)
		debug.sethook ()

		return utils.appendValuesWithComma (args)
	else
		return ('no debug active')
	end
end

--- returns an array form a key, handles single entry or array for keys
-- @param obj the object making the call
-- @param v the the value to test
-- @return value if value was an array otherwise value in an array
-- @usage obj:returnArray ( Value )
-- @usage obj.returnArray ( obj, Value )
function utils.returnArray ( obj, v )
	if type (v) == _TABLETYPE then
		if #v ~= 0 then
			return v -- already array or tables
		else
			return {v} -- convert to array of tables
		end
	elseif v then
		return {v} -- convert to array
	else
		return nil -- nil is nil
	end
end

--- converts a string% from 0 to 100 to a percentage 0 to 1
-- @param obj the object making the call
-- @param v the the value to convert
-- @return 0 to 1 conversion of a % in a string, also false = 0, true = 1, error is 0
-- @usage obj:getPercentage ( Value )
-- @usage obj.getPercentage ( obj, Value )
function utils.getPercentage ( obj, v )
	if v ~= nil then
		if tonumber( v ) then
			v = tonumber( v )
			if v < 0 then
				v = 0 
			elseif v > 1 then
				v = 1
			end
			return v
		elseif type (v) == _STRINGTYPE then
			v = v:stripAllWS ()
			if v == '' or v == '%' then
				return 0
			else
				if v:sub(v:len()) == '%' then
					v = v:sub(1, v:len() - 1)
					if tonumber( v ) then
						v = v / 100
						return utils.getPercentage ( obj, v )
					else
						return 0
					end
				else
					return 0
				end
			end
		elseif type (v) == _BOOLTYPE then
			if v then
				return 1
			else
				return 0
			end
		else
			return 0
		end
	else
		return 0
	end
end

-- tests to see if object is a display object, it returns the display object or false
function utils.isObjectDisplayObject ( obj, callingModule, object )
	if utils.isKnownModule ( obj, callingModule ) and object then
		if (object.group and object.group.alpha) then
			return object.group
		elseif (object.object and object.object.alpha) then -- probably a display object
			return object.object
		end
	end

	return false
end


Utils = classy:newClass(
            classy:attributes ( { pcallOn = Bool ( Private ), functionTable = Table ( PrivateImmutable ), myLogger = Logger ( Private ), logEntity = Table ( Private ) } ),
            classy:initMethod (
                   --- loads the utils into the functions table so they can be consumed by giveMeFunctions
                  -- @function initMethod
                  -- @param obj the calling object 
                  -- @param args optional arguments sent to create the file handler
                  -- @return No return value
                  -- @usage myUtil = Utils ()
                function ( obj, args )
                	-- classy:default values will load all the args into the object and any that are not passed over but in the default values table will be defaulted.
                	classy:setDefaultValues ( obj, args, { pcallOn = false, functionTable = { }, myLogger = _G.myLogger } )
                	-- check to see if the class is registerd by the logger, if not register it so we get the Log_ functions created
                	-- we also only do this with the base class, any inherted classes will not be seen as modules as they are not loaded via require
                	obj.logEntity = classy:getBaseClass ( getmetatable ( obj ) )
                	if not obj.myLogger:registerState ( obj.logEntity ) then
                		obj.myLogger:registerModule ( obj.logEntity )
                	end
                	-- load the functions into the function table
                	local next = next
                	local k, v
                	for k, v in next, utils, nil do
                		if type ( v ) == _FUNCTYPE then
                			obj.functionTable [ k ] = v
                		end
                	end
                end       
				),
            classy:addMethod ( CONSTANTS.METHODS.GIVEMEFUNCTIONS,
				--- returns a table that classy:assign can use, not if a function does not exist you just get a logger message
				-- @function giveMeFunctions
				-- @param obj the utils object
				-- @param ... a list of function names
				-- @return a table containing the functions and optional table containing the list of functions that were not found
				-- @usage local assignTable, errorM = myUtils:giveMeFunctions ( [ function1, .. functionN ] ) 
				function  ( obj, ... )
					local returnTable, missingTable 
					local x
					for x = 1, arg.n do
						local nextFunc = arg [ x ]
						if type ( nextFunc ) == _STRINGTYPE then
							if obj.functionTable [ nextFunc ] then
								returnTable = returnTable or { }
								returnTable [ nextFunc ] = obj.functionTable [ nextFunc ]
							else
								missingTable = missingTable or { }
								missingTable [ # missingTable + 1 ] = nextFunc
							end
						else
							obj.myLogger:Log_Warning ( 'requested a function: ', nextFunc, ', this is not a valid function name: handler:' , obj )
						end
					end
					local errorMessage
					if missingTable then
						errorMessage = 'the following functions are not available ' .. utils.appendListWithComma ( obj, missingTable )
					end
					return returnTable, errorMessage
				end
            	),
				classy:addMethod ( CONSTANTS.METHODS.ADDANOTHERFUNCTION,
				--- returns a table that classy:assign can use, not if a function does not exist you just get a logger message
				-- @function addAnotherFunction
				-- @param obj the utils object
				-- @param ... a list of function names
				-- @return No return value
				-- @usage myUtils:addAnotherFunction ( { name = FunctionName1, func = Function1 [, overload = true ] } [, ... { name = FunctionNameN, func = FunctionN [, overload = true ] } ] ) 
				function  ( obj, ... )
					local returnTable, missingTable 
					local x
					for x = 1, arg.n do
						local nextFunc = arg [ x ]
						if type ( nextFunc ) == _TABLETYPE then
							local key, value = nextFunc.name, nextFunc.func
							if type ( key ) ~= _STRINGTYPE then
								obj.myLogger:Log_Warning ( 'requested a function: ', nextFunc, ', this is not a valid function ->', key, '<- key = name, value = function: handler:' , obj )
								key = nil
							end
							if type ( value ) ~= _FUNCTYPE then
								obj.myLogger:Log_Warning ( 'requested a function: ', nextFunc, ', this is not a valid function key = name, ->', value, '<- = function: handler:' , obj )
								value = nil
							end
							if key and value then
								if obj.functionTable [ key ] then
									if nextFunc.overload == nil or type ( nextFunc.overload ) ~= _BOOLTYPE or ( type ( nextFunc.overload ) == _BOOLTYPE and not nextFunc.overload ) then
										obj.myLogger:Log_Warning ( 'requested a function: ', nextFunc, ', is overloading an existing function, you must set overload = true to force this: handler:' , obj )
									else
										obj.functionTable [ key ] = value
									end
								else
									obj.functionTable [ key ] = value
								end
							end
						else
							obj.myLogger:Log_Warning ( 'requested a function: ', nextFunc, ', this is not a valid function key = name, value = function: handler:' , obj )
						end
					end
				end
            	),
				classy:addNotes (utils._VERSION .. '\n\n' .. utils._DESCRIPTION .. '\n' .. utils._LICENSE, ... )            
			)

return Utils      