-----------
-- creates a math builder class.
-- designed for use with the classy object creator
-- @usage Parser = require ( 'mathParser' )
-- @author David Porter
-- @module mathParser
-- @release 1.0.1
-- @license MIT
-- @copyright (c) 2019 David Porter

local mathParser = {
	 _VERSION = ... .. '.lua 1.0.1',
     _URL = '',
     _DESCRIPTION = [[
      ============================================================================
      creates a class that can take strings and convert them into tables that can be
      consumed to provide an executable result.

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
      _DEPENDANCIES = { classy = 'classy', Stack = 'stack', utils = 'utils', inspect = 'inspect', Logger = 'logger' }
}

-- a refernce to the various LUA types, generate them by code just incase it ever did change in the future
local _STRINGTYPE, _NUMTYPE, _TABLETYPE, _BOOLTYPE , _FUNCTYPE = type ( '' ), type ( 9 ), type ( {} ), type ( true ), type ( function () end )

--- constants used by the module
local CONSTANTS = { 
  METHODS = { SETACTIVEPARAMETERS = 'setParameters', -- the set default read behavour method name
	  ADDFUNCTION = 'addFunction', -- the open file  method name
	  GETACTIVEPARAMETERS = 'getParameters', -- the close file  method name
	  RUNFUNCTION = 'runFunction', -- the read file method name
	  ISFUNCTION = 'isFunction', -- the file exists method name
	  EXECUTECODE = 'execute', -- the code execute function
	  COMPILE = 'compile', -- the compile function
	  COMPILEANDEXECUTE = 'compileAndExecute' -- compiles and executes in one operation
	  },
  PARAMLOGLEVEL = 'Param', -- a log level created by mathBuilder
  TOASSIGNTOOBJECT = { -- a group of methods that this class uses and will need assigned to any object
	'getPercentage',
	'tableToString',
	'tableCopier',
	'appendTextOnNumber',
	'tableIsEmpty',
	'breakAppart',
	'splitStringAccountingForStrings',
	'appendListWithComma',
	'mergeArrays',
	'testParameters',
	'defaultDataValue',
	'mergeTables'
  }
} -- the default methods names

local PARAMLOGLEVEL_NAME -- place holder for a constant set in init, for a custom logger

-- @local defines how formulas look, passed to the tableToString utility
local FORMULAFORMAT = {quote = '', comma = '', oBracket = '(', cBracket = ')', keys = false, oSBracket = '[', cSBracket = ']', oCBracket = '{', cCBracket = '}' }

-- @local require dependancies if any, this method will be removed after run creation of the module
local function getDependancies ()
  local dependancies = mathParser._DEPENDANCIES

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
-- @local remove this method it is no longer required
getDependancies = nil

--- convertParameter converts parameter name to value as stored in .parameters. 
-- Note it strips white space. If 2nd paramter is true you sent the routine a number already.
-- bounded by " ... " is a string so return the origional value with all WS
-- @param obj the mathParser object
-- @param name the item under test
-- @param parametersConsumed a table that lists all the parameters consumed
-- @param logParameters if true we bother logging, if false we do not
-- @return strippedname, is a number true or false, is a string true or false
function convertParameter ( obj, name, parametersConsumed, logParameters ) 
	logParameters = logParameters or true -- default to logging
	local isStringSent = name:match('^.*"') or name:match("^.*'")
	name = name:stripAllWS () -- remove whitespaces
	if obj.mathBuilderParameters then 
		if tonumber (name) then -- it is a number
			return tonumber (name), true, false
		elseif isStringSent then
			return isStringSent, true, true
		elseif name == tostring (true) or name == tostring (false) then -- bool sent
			return result , true, false
		else
			local parsedValue = obj.mathBuilderParameters [name]
			if not parametersConsumed then -- do the shorter version if we are not logging the consumed parameters
				if parsedValue then
					return parsedValue, false, false
				else
					return name, false, false
				end
			else
				if parsedValue then -- do the longer version as we are logging consumed parameters
					if parametersConsumed.known [name] then
						parametersConsumed.known [name] = parametersConsumed.known [name] + 1
					else
						parametersConsumed.known [name] = 1
					end
					return parsedValue, false, false
				else
					if name ~= '' and obj:getPercentage (name) == 0 then -- nan to log it as unknown paramter
						parametersConsumed.unknown [#parametersConsumed.unknown + 1] = name
					end
					return name, false, false 
				end
			end
		end
	else
		obj.myLogger:Log_Warning_mathParser ( 'no parameters set, please call setParamters first' )
		return nil, nil, nil
	end
end

--- the internal implementation that executes an actual compile table
-- @see compile
-- @see execute
-- @param obj the mathParser object
-- @param expr the current evaluated expression
-- @param executionDetails the compiled execution details
-- @param parameters the manditory parameters as a key value pair, values are the values in the calculation. OptionalParameters	values can be set here also.
-- @param allParams all known parameters
-- @param optional the optional parameters as a key value pair, values is ignored (just has to exist), this lets the executor know if it can't find this key then use a default value for that datatype.
-- @param resultTable we store results in this table	
-- @return a list of values from the calculations
-- @usage local result [, ... resultN ] = myParser:execute ( codeBlock, { parameter1 key = value1 [ ... , parameterN key = valueN ] } [ , { optional parameter1 = true  [, ... optional parameterN = true ]} ] )	
local function executeCode ( obj, expr, executionDetails, parameters, allParams, optional, resultTable )
	-- calculate as execution requested
	resultTable = resultTable or {}
	optional = optional or {}
	parameters = parameters or {}
	allParams = allParams or {}
	obj.myLogger:Log_Debug_mathParser ('executing: "' , expr , '"')
	if executionDetails then
		local e = 'failed to resolve expression "' .. expr -- a common error message
		local executionSize = #executionDetails
		obj.myLogger:Log_Debug_mathParser ('this expression has ' , executionSize , ' items to executute')
		for x = 1, executionSize do -- note items at this point will not contain any other items subtables, only func, text or a calculation
			local inspectionValue = executionDetails[x]
			obj.myLogger:Log_Debug_mathParser ('table is:' , inspectionValue)
			if inspectionValue.f then -- function
				local f = obj.supportedFunctions [inspectionValue.f] 
				if f then 
					resultTable [#resultTable + 1] = {f = f}
				else
					obj.myLogger:Log_Error_mathParser (e , '" as function "' , inspectionValue.f , '" is undefined')
					return nil, false
				end
				obj.myLogger:Log_Debug_mathParser ('resolved function to:' .. f.name)
			elseif inspectionValue.p ~= nil then -- parameter
				-- check p is a number,table or a parameter
				local p
				local paramterExpectedType = inspectionValue.pt
				if tonumber (inspectionValue.p) then -- number so set it
					p = inspectionValue.p
				elseif inspectionValue.pt == _BOOLTYPE then
					p = inspectionValue.p
				else -- paramter so extract it but type check first
					p = parameters [inspectionValue.p]
				end

				if p ~= nil then -- not nil so put in result table
					resultTable [#resultTable + 1] = {v = p}
				else -- it's nil so generate error
					if not optional [inspectionValue.p] then -- parameter was not optional
						 obj.myLogger:Log_Error_mathParser (e , '" as parameter "' , inspectionValue.p , '" is undefined')
						return nil, false
					else -- parameter was optional
						local resolvedValue = obj:defaultDataValue ( inspectionValue.pt ) -- get the default resolve value
						obj.myLogger [ PARAMLOGLEVEL_NAME ] ( obj.myLogger, e , '" as optional parameter "' , inspectionValue.p , '" is undefined, parameter "' , inspectionValue.p ,'" will default to ' , resolvedValue )
						if resolvedValue then
							resultTable [#resultTable + 1] = {v = resolvedValue}
							p = resolvedValue
						else
							return nil, true
						end
					end						
				end

				if paramterExpectedType and paramterExpectedType ~= type (p) then
					obj.myLogger:Log_Error_mathParser ( e , '" as parameter "' , inspectionValue.pn , '" is of type "' , type ( p ) , '", when "' , paramterExpectedType , '" was expected - Value is "' , p , '"')
					return nil, false
				end
				obj.myLogger:Log_Debug_mathParser ('resolved parameter "' , inspectionValue.pn, '" to: ' , p)
			elseif inspectionValue.t then -- table so iterate into that table
				local partResult, valid = obj:executeCode (inspectionValue.expr, inspectionValue.t, parameters, optional, {})
				if valid then
					resultTable [#resultTable + 1] = {v = partResult}
				else
					return nil, false
				end
			elseif inspectionValue.s then -- it is a string result
				resultTable [#resultTable + 1] = {v = inspectionValue.s}
				obj.myLogger:Log_Debug_mathParser ('string ' , inspectionValue.pn , ' detected')
			elseif inspectionValue.b then -- it is a [ ... ] ... [ ... ]
				local bracketResolver = {}
				local c
				for c = 1, #inspectionValue.b do
					local partResult, valid = executeCode ( obj, inspectionValue.expr, inspectionValue.b [c], parameters, optional, {})
					if valid then
						bracketResolver [#bracketResolver + 1] = partResult
					else
						obj.myLogger:Log_Error_mathParser ('failed to resolve execution in expression "' , expr , '", at the ' , obj:appendTextOnNumber (c), ' bracket')
						return nil, false
					end
				end
				if parameters [inspectionValue.pn] then
					local c
					local currentLocation = parameters [inspectionValue.pn]
					for c = 1, #bracketResolver do
						local currentSubEntry = bracketResolver [c]
						local isString = type (currentSubEntry) == _STRINGTYPE
						local nextLocationExists = false
						if type (currentLocation) == _TABLETYPE then
							if isString then
								nextLocationExists = currentLocation [currentSubEntry] ~= nil
							elseif currentSubEntry <= #currentLocation and currentSubEntry > 0 then
								nextLocationExists = true
							end
							if nextLocationExists then
								currentLocation = currentLocation [currentSubEntry]
							else
								if isString then
									obj.myLogger:Log_Error_mathParser ('failed to resolve execution in expression "' , expr , '", as parameter "' , inspectionValue.pn , '" has an unkonwn key "' , currentSubEntry, '" at ' , obj:appendTextOnNumber (c) , ' level')
								else
									obj.myLogger:Log_Error_mathParser ('failed to resolve execution in expression "' , expr , '", as parameter "' , inspectionValue.pn , '" is evaluating out of scope at the ', obj:appendTextOnNumber (c) ,' level' , ', value is ' , currentSubEntry , ' and scope is ', #currentLocation )
								end
								return nil, false
							end
						else
							local extraMessage
							if isString then
								extraMessage = 'key "' .. currentSubEntry .. '"'
							else
								extraMessage = 'value ' .. currentSubEntry
							end
							obj.myLogger:Log_Error_mathParser ('failed to resolve execution in expression "', expr , '", as parameter "' , inspectionValue.pn, '" is not a ' , _TABLETYPE , ' at it\'s ' , obj:appendTextOnNumber (c) , ' level, for ', extraMessage)
							return nil, false
						end
					end
					resultTable [#resultTable + 1] = {v = currentLocation}
				else
					obj.myLogger:Log_Error_mathParser ('failed to resolve execution in expression "' , expr , '", as parameter "', inspectionValue.pn, '" does not exist')
					return nil, false
				end
			else
				obj.myLogger:Log_Error_mathParser ('failed to resolve execution "' , inspect (inspectionValue), '" in expression "' , expr , '"')
				return nil, false
			end
		end

		-- now execute and return result
		local _calculations
		_calculations = function (resultTable)
			if #resultTable == 0 then
				return nil, false
			elseif #resultTable == 1 then
				return resultTable [1].v, true
			else
				local result = 0
				x = 1
				-- if starts with number set result to that number and skip forward 1
				if resultTable [x].v ~= nil then
					result = resultTable [x].v
					x = x + 1
				end
				repeat
					local nextResult = resultTable [x]
					if nextResult.f then -- it is a function
						local func = nextResult.f
						local nextItem = resultTable [x +1]
						if nextItem.v ~= nil then 
							local testCase, e = true
							if not func.multiType then -- multiType allows more than just numbers but needs code in the function to cope with the case
								testCase, e = obj:testParameters ( _NUMTYPE, result, nextItem.v )
							end
							if testCase then
								if not func.warnings or not func.warnings (result, nextItem.v) then
									--mathBuilder.local_Debug (func.name .. ' called with ' .. result .. ', ' .. resultTable [x + 1].v)
									result = func.code(result, nextItem.v)
								else
									obj.myLogger:Log_Warning_mathParser ('failed to resolve expression "' , expr , '" as warning triggered on "', func.name , '", ' , func.error)
									return nil, false
								end
								x = x + 1
							else
								obj.myLogger:Log_Error_mathParser ('failed to compute execution "' , func.name , '" in expression "' , expr , '", as ' , e)
								return nil, false
							end
						else
							obj.myLogger:Log_Error_mathParser ('failed to compute execution as functions can only follow functions if inside parenthesis "' , func.name , nextItem.f.name , '" in expression "' , expr, '"')
							return nil, false
						end
					elseif nextResult.t then -- it is a table result
						local x
						local tableResult = {}
						for x = 1, #nextResult.t do
							local subResult, subState = _calculations ({nextResult.t [x]})	
							if not subState then
								return nil, false
							else
								tableResult [#tableResult + 1] = subResult
							end
						end
						return tableResult, true
					end
					x = x + 1
				until x > #resultTable

				return result, true
			end
		end
		obj.myLogger:Log_Debug_mathParser ('completed execution: "' , expr, '"')
		return _calculations (resultTable)
	else
		obj.myLogger:Log_Error_mathParser ('expression "' , expr , '" called with no execution details')
		return nil, false
	end
end

--- iterated through code blocks calling math parser to build a result
-- @param obj the mathParser object
-- @param codeBlock a sub codeBlock that needs compiled
-- @param parameter the manditory parameters
-- @param allParams all known parameter
-- @param optional the optional parameter
-- @return a sub section of a code table
local function resolveCode ( obj, codeBlock, parameter, allParams, optional )
	local resultTable = {}
	local x
	for x = 1, #codeBlock  do
		local nextExecution = codeBlock  [ x ]
		if nextExecution.compiledExpr then
			local codeResult, codeState = executeCode ( obj, nextExecution.expr, nextExecution.compiledExpr, parameter, allParams, optional, {})
			if codeState then
				resultTable [#resultTable + 1] = codeResult
			else
				obj.myLogger:Log_Error_mathParser ('failed to resolve expression, "', nextExecution.expr , '"')
				return nil
			end
		else
			resultTable [ #resultTable + 1 ] = resolveCode ( obj, nextExecution, parameter, allParams, optional ) 
		end
	end

	return resultTable
end

--- the local implementation of the compiler that generates the execution tables
-- @param obj the mathParser object
-- @param tableOfResults the string brocken down accounting for tables so that it can be evaluated bit by bit
-- @return the individual code tables
local function examineExpression ( obj, tableOfResults)
	obj.myLogger:Log_Debug_mathParser ( 'expression:', tableOfResults )
	local _stageOne
	-- _stageOne traverses  the results and builds in runOrder the calculations holding in tables
	_stageOne = function ( obj, tableOfResults, scanOrder, tables, level )
		if not scanOrder then scanOrder = { tables={} } tables = scanOrder.tables end
		if not level then level = 1 else level = level + 1 end
		local x
		local currentResult = {}
		local currentScan = '' 
		for x = 1, #tableOfResults do
			if type ( tableOfResults [x] ) == _TABLETYPE then
				if currentScan:stripAllWS() ~= '' then
					currentResult [#currentResult + 1] = currentScan:removeLeadTrailWS ()
				end
				currentScan = ''
				_stageOne ( obj, tableOfResults [x], scanOrder, tables, level)
				currentResult [#currentResult + 1] = tables [  tableOfResults [x] ]
			else
				currentScan = currentScan .. tableOfResults [x]
			end
		end
		if currentScan:stripAllWS() ~= '' then -- don't log empty at end of a line
			currentResult [#currentResult + 1] = currentScan:removeLeadTrailWS ()
		end
		-- log the most approriate execution order and mark all items as non evaluated
		scanOrder [#scanOrder + 1] = {scan = currentResult, evaluated = false, level = level}
		tables [  tableOfResults ] = scanOrder [#scanOrder]
		return currentScan, scanOrder
	end

	_, tableOfResults = _stageOne ( obj, tableOfResults )

	-- helper builds the evalaution for an expresion, this expression only contains paramters, math functions
	local _helper
	_helper = function ( obj, expr, tableOfResults, executeCode, parametersConsumed, functionsConsumed )
		    			local codeStore = {runOrder = {}} -- stores the execution order
			    		if not parametersConsumed then parametersConsumed = {known = {}, unknown = {}, all = {}} end -- stores the known and unknown 
			    		if not functionsConsumed then functionsConsumed = {consumed = {}} end -- stores a log of functions conumed in order
			    		if not executeCode then executeCode = codeStore.runOrder end -- builds an executable that can be used to run this again, as it is validated we know should always run
			    		local x
			    		local items = {}
			    		local result = ''

			    		local _paramBuilder
			    		_paramBuilder = function ( obj, result, n, executeCode, stringState )
											local paramName = result:stripAllWS ()
				    						local paramType
				    						if obj.mathBuilderParameters then
				    							paramType = obj.mathBuilderParameters [ paramName ] -- will not be nil as another check will hit before this does for parameter existance
				    						end
				    						if stringState then -- it is a string
				    							local modifiedResult = result:removeLeadTrailWS()
												executeCode [#executeCode + 1] = {s = modifiedResult:sub(2,modifiedResult:len()-1), pt = _STRINGTYPE , pn = modifiedResult} -- pt stores the orgional parmater type expected
											elseif n then -- it's a number or bool
												if result == tostring (true) or result == tostring (false) then
													if result == tostring (true) then
														result = true
													else
														result = false
													end

													executeCode [#executeCode + 1] = {p = result, pt = type (result), pn = paramName} 
												else
													executeCode [#executeCode + 1] = {p = tonumber( paramName ), pt = paramType, pn = paramName} -- pt stores the orgional parmater type expected
												end
											else -- it's possibly a paramter or %
												local percentage = obj:getPercentage (result)
												if percentage ~= 0 then -- percentage
													executeCode [#executeCode + 1] = {p = percentage, pt = _NUMTYPE, pn = paramName}
												else
													executeCode [#executeCode + 1] = {p = paramName, pt = paramType, pn = paramName} 
												end
											end	
			    						end


			    		local stringsActive = false -- used to flag we're in a string as we do not want to match on functions

			    		local currentLevelOfTableBrackets = 0 -- counterthat notes current bracket level
			    		local currentBracketCount = 1 -- counter that gives each bracket pair a unqique ID
			    		local bracketHistory, bracketStack, multiBracketStack -- stores history of brackets, stack for logging who is the next to close, multiBrackStack used for [][][][] resolutions
			    		local lastSeenItem -- stores the last seen item
			    		local justClosedABracket = false -- used to detect ] ... [] for mult layer brackets

			    		for x = 1, #tableOfResults do
						--for x = 1, #tableOfResults do
			    			local item = tableOfResults[x]
			    			-- if table recall the code to resolve
			    			if type ( item ) == _TABLETYPE then
			    				justClosedABracket = false
			    				local subExecuteCode = {}
			    				local subExpr = obj:tableToString ( item, FORMULAFORMAT )
			    				local r = _helper ( obj, subExpr , item, subExecuteCode, parametersConsumed, functionsConsumed )
			    				-- log the result in codestore
			    				executeCode [#executeCode + 1] = { t = subExecuteCode, expr = subExpr }
			    				-- log the item
			    				if r then 
				    				items [#items+ 1] = r
				    			else
				    				return nil
				    			end
			    			else
			    				if item == '"' or item == "'" then
			    					stringsActive = not stringsActive
			    				end
			    				-- if function test and run function
			    				--print ('test:', item)
			    				if not stringsActive then
				    				if obj:isFunction ( item ) then 
				    					if justClosedABracket then -- ok, we have an entire bracket history we need to put infron of the current code run
							    			local anyPreviousBrackets = bracketHistory:pop () 
											if anyPreviousBrackets then
							    				obj:tableCopier ( executeCode, anyPreviousBrackets )
							    				executeCode = anyPreviousBrackets
							    			end			
						    			end				    			
				    					justClosedABracket = false
				    					obj.myLogger:Log_Debug_mathParser ( 'function "' .. item .. '" detected' )
				    					local r, n, stringState = convertParameter ( obj, result, parametersConsumed )
				    					if r ~= '' then
				    						items [#items + 1] = r
				    						_paramBuilder ( obj, result, n, executeCode, stringState)
										end
				    					items [#items + 1] = obj.supportedFunctions [ item ]
				    					result = ''
				    					-- store function in codestore
				    					executeCode [#executeCode + 1] = {f = item}
				    				elseif item == FORMULAFORMAT.oSBracket then
				    					bracketStack = bracketStack or Stack ( { myStackName =  mathParser._MODULENAME .. ':bracketStack' } )
							    		local resolvedValue, n, stringState = convertParameter ( obj, result, parametersConsumed )
							    		if resolvedValue == _TABLETYPE then -- expect the paramter passed in result to be a table
							    			local tblDetails = result:removeLeadTrailWS ()
							    			executeCode [#executeCode + 1] = { pn = tblDetails }
							    			bracketStack:push ( {result = result, leadingCode = executeCode, startBracketLevel = currentBracketCount + 1, stringCount = x} )
							    			-- reset the result to move on
							    			result = ''
							    			executeCode = {}
							    		else
							    			if justClosedABracket then
								    			local lastPopped = bracketHistory:pop ()
								    			multiBracketStack = multiBracketStack or Stack ( { myStackName = mathParser._MODULENAME .. ':multiBracketStack' } )
												multiBracketStack:push ( lastPopped )
	    									else
	    										return {}, parametersConsumed, functionsConsumed -- return an empty compiled entry so unknown paramaters can trigger
	    									end
							    		end
				    					currentLevelOfTableBrackets = currentLevelOfTableBrackets + 1
				    					currentBracketCount = currentBracketCount + 1
				    					justClosedABracket = false
				    				elseif item == FORMULAFORMAT.cSBracket then
				    					justClosedABracket = true
							    		local resolvedValue, n, stringState = convertParameter ( obj, result, parametersConsumed )
				    					if r ~= '' then
				    						if result:removeLeadTrailWS():len() ~= 0 then
					    						items [#items + 1] = r
					    						_paramBuilder ( obj, result, n, executeCode, stringState)
					    					end
					    					if multiBracketStack and #multiBracketStack ~= 0 then -- special close
								    			local lastPopped = multiBracketStack:pop ()
								    			local addOneHere = lastPopped [#lastPopped]
								    			addOneHere.expr = addOneHere.expr .. FORMULAFORMAT.oSBracket .. result .. FORMULAFORMAT.cSBracket
								    			addOneHere.b [#addOneHere.b + 1] = executeCode
					    						bracketHistory:push ( lastPopped )
					    					else -- normal close
						    					local poppedBracket = bracketStack:pop ()
						    					if poppedBracket.startBracketLevel == currentBracketCount then -- single [ ... ] wth no more inside, so resolvable
						    						local adjustedCode = poppedBracket.leadingCode
							    					bracketHistory = bracketHistory or Stack ( { myStackName = mathParser._MODULENAME .. ':bracketHistory' } )
							    					if #bracketHistory == 0 then
							    						adjustedCode [#adjustedCode].b = {executeCode}
							    						bracketHistory:push ( adjustedCode )
							    					else -- everything in this stack is in a code build
							    							local poppedStackValue = bracketHistory:pop ()
							    							adjustedCode [#adjustedCode].b = poppedStackValue
															bracketHistory:push ( adjustedCode )
							    					end
							    					-- store the string
							    					local str = poppedBracket.result .. expr:sub (poppedBracket.stringCount, x + 1)
							    					adjustedCode [#adjustedCode].expr = str:removeLeadTrailWS() 
						    						currentBracketCount = currentBracketCount - 1
						    					end
						    				end
				    						currentLevelOfTableBrackets = currentLevelOfTableBrackets - 1
							    			executeCode = {}
							    			result = ''
							    		else
    										obj.myLogger:Log_Error_mathParser (obj:appendTextOnNumber (currentLevelOfTableBrackets) .. ' set of brackets contain no resolution in expression, "' .. expr .. '"' )
    										return {}, parametersConsumed, functionsConsumed -- return an empty compiled entry so unknown paramaters can trigger
							    		end
				    				else
			    						if not item:isWhiteSpaceOnly () then
			    							justClosedABracket = false
			    						end
				    					result = result .. item
				    				end
			    				else
				    				result = result .. item
				    			end
			    			end

			    			lastSeenItem = item
			    		end

			    		local resolvedValue, n, stringState = convertParameter ( obj, result, parametersConsumed )
						items [#items + 1] = resolvedValue

						if result:stripAllWS () ~= '' then -- only save if not empty
    						_paramBuilder ( obj, result, n, executeCode, stringState)
						end

						if currentLevelOfTableBrackets ~= 0 then -- we have to close all [ ... ] pairs or an error at this stage
							obj.myLogger:Log_Error_mathParser ('[ ... ] mismatch in expression, "' .. expr .. '"')
							return nil
						end

						-- if brackets were detected we modify all the code based on those brackets
						if bracketHistory then
							local modifiedCode = bracketHistory:pop ()
							-- add any trailing code
							if not obj:tableIsEmpty (executeCode) then
								obj:tableCopier (executeCode, modifiedCode)
							end
							executeCode = modifiedCode
						end


						return executeCode, parametersConsumed, functionsConsumed
		    	end

	-- stageTwo goes through and evaluates stagwOne tables via , and attempts an evaluation of the parameters
	_stage = function ( obj, tableOfResults )
		local allParametersConsumed, allFunctionsConsumed = {}, {}
		local x
		for x = 1, #tableOfResults do
			local currentTable = tableOfResults [x]
			local scanOrder = currentTable.scan
			local compilations = {}
			local y
			-- go through list in order
			for y = 1, #scanOrder do
				local currentScan = scanOrder [y]

				local level = tableOfResults [x].level
				local levelMessage = 'table level '.. level .. '.' .. y 
				if type (currentScan) ==_TABLETYPE then
					if not currentScan.evaluated then -- this should never occur just a catch all
				    	obj.myLogger:Log_Error_mathParser ('unexpected evaluation at' .. levelMessage)
				    	return nil
					else
						-- this is already referencing something that has already been compiled
						compilations [#compilations + 1] = currentScan.compilations
					end
				else
					-- deal with commas at start or end of string
					if currentScan:sub(-1) == ',' then -- comma at end
						if y == #scanOrder then -- comma with stuff after is syntax error
							obj.myLogger:Log_Error_mathParser ('empty expression detected at end of "' .. currentScan .. '"')
							return nil
						else -- comma gets removed as table following on
							currentScan = currentScan:sub(1,currentScan:len()-1)
						end
					end
					if currentScan:sub(1,1) == ',' then -- comma at end
						if y == 1 or currentScan:len () == 1 then -- comma with stuff before is syntax error
							obj.myLogger:Log_Error_mathParser ('empty expression detected at begining of "' .. currentScan .. '"')
							return nil
						else -- comma gets removed as table following on
							currentScan = currentScan:sub(2,currentScan:len())
						end
					end
					-- finished dealing with , at beginning and end
					local splitStrings = obj:splitStringAccountingForStrings (currentScan, ',')

					local z
					for z = 1, #splitStrings do
					    -- first break each character up and set in table relative to parenthasis
					    local expr = splitStrings [z]
					    if expr:stripAllWS() ~= '' then
					    	expr = expr:removeLeadTrailWS()
						    local nextTableOfResults, _, totalCount = obj:breakAppart ( expr )
						    if totalCount and totalCount ~= 0 then
						    	obj.myLogger:Log_Error_mathParser ('attempt to parse with mismatch parenthasis count for expression "' .. expr .. '"')
						    	return nil
						    else
						    	obj.myLogger:Log_Debug_mathParser ('expression "' .. expr .. '", evaluating at '.. levelMessage .. '.' .. z)
						    	-- get the evaluation
						    	local compiledEntry, parametersConsumed, functionsConsumed = _helper ( obj, expr, nextTableOfResults)
						    	if compiledEntry then
							    	if #parametersConsumed.unknown ~= 0 then
				    					local e = obj:appendListWithComma (parametersConsumed.unknown)
				    					if  not paramErrorFlag then
					    					obj.myLogger:Log_Error_mathParser ('unknown parameters detected in expression "' .. expr .. '"; ' .. e)
					    				end
				    					return nil
							    	end
							    	if not obj:tableIsEmpty (compiledEntry) then
								    	allParametersConsumed = obj:mergeArrays ( allParametersConsumed, parametersConsumed.unknown )
								    	compilations [#compilations + 1] = {compiledExpr = compiledEntry, expr = expr:removeLeadTrailWS ()} -- store compilations and the expression with trailing leading spaces removed
								    else -- had a paramter is not a table from _helper
								    	return nil
								    end
							    else
							    	return nil
							    end
						    end
						end
					end
				end
			end
			-- mark the entry as evaluated, as we don't want to repeat this
			currentTable.evaluated = true
			-- remove scan we don't want this clogging up memory
			currentTable.scan = nil
			-- store the compilations
			currentTable.compilations = compilations
			-- find primary execution point
			if currentTable.level == 1 then
				if tableOfResults.primaryExecutionPoint then
					obj.myLogger:Log_Error_mathParser ('primary execution point can\'t be reasigned, internal compiler error')
					return nil
				end
				tableOfResults.primaryExecutionPoint = currentTable.compilations
			end
			-- all paramters consumed, check this
			tableOfResults.parametersConsumed = allParametersConsumed
		end

		-- remove tables no longer needed so free memory
		--tableOfResults.tables = nil

		return tableOfResults
	end

	local stageTwoResult = _stage ( obj, tableOfResults)

	--print (inspect (stageTwoResult))
	return stageTwoResult
end

return classy:newClass(
            classy:attributes ( { mathBuilderParameters = Table ( Private ), supportedFunctions = Table ( Private ), mathParserParameters = Table ( Private ), myLogger = Logger ( Private ), logEntity = Table ( Private ) } ),
            classy:initMethod (
                   --- sets the default read behavour flags
                  -- @function initMethod
                  -- @param obj the calling object 
                  -- @param args optional arguments sent to create the file handler
                  -- @return No return value
                  -- @usage myParser = mathParser ()
                function ( obj, args )
                	-- classy:default values will load all the args into the object and any that are not passed over but in the default values table will be defaulted.
                	classy:setDefaultValues ( obj, { supportedFunctions = { }, myLogger = _G.myLogger, mathParserParameters = { } } )
                	-- check to see if the class is registerd by the logger, if not register it so we get the Log_ functions created
                	-- we also only do this with the base class, any inherted classes will not be seen as modules as they are not loaded via require
                	obj.logEntity = classy:getBaseClass ( getmetatable ( obj ) )
                	if not obj.myLogger:registerState ( obj.logEntity ) then
                		obj.myLogger:registerModule ( obj.logEntity )
                		obj.myLogger:addLogLevel ( CONSTANTS.PARAMLOGLEVEL )
                		PARAMLOGLEVEL_NAME = obj.myLogger:getLogPrefix () .. CONSTANTS.PARAMLOGLEVEL .. '_' .. mathParser._MODULENAME
                	end
                	-- give the object the utility functions it needs
                	classy:assign ( obj, _G.myUtils:giveMeFunctions (  unpack ( CONSTANTS.TOASSIGNTOOBJECT ) ) )

                	-- add the default functions this parser need to know about
					obj:addFunction ({name = '+', code = function ( a, b ) 
																		if type (a) ~= type (b) or type (a) ~= _NUMTYPE then
																			return tostring( a ) .. tostring( b )
																		else
																			return a + b
																		end 
																	end
												, multiType = true,-- warning = function (a, b) return type (a) == _TABLETYPE or type (b) == _TABLETYPE  end, 
												--errorMessage = 'tables can\'t be added'
												}) -- multiType allows other types than number, we don't add tables so add a warning
					obj:addFunction ({name = '-', code = function ( a, b ) return a - b end} )
					obj:addFunction ({name = '*', code = function ( a, b ) return a * b end} )
					obj:addFunction ({name = '/', code = function ( a, b ) return a / b end, warning = function (a, b) return b == 0 end, errorMessage =  'divide by zero'} )
					obj:addFunction ({name = '#', code = function ( a, b ) 
																	if type (b) == _TABLETYPE then
																		-- tables return the array length, plus 1 for every key
																		return a + #b 
																	elseif type (b) == _STRINGTYPE then
																		-- strings return the string length
																		return a + b:len()
																	else
																		-- others get ignored
																		return a
																	end
																end
											, multiType = true} )



                end       
				),
            classy:addMethod ( CONSTANTS.METHODS.COMPILE,
				--- calls the compiler, can send a list of strings or single string
	            --- Creates a list of tables table that can then be executed upon
	            -- @function compile
	            -- @param obj the mathParser object
	            -- @param ... the tables you want compiled
	            -- @return from one to many compile table results in a table or nil if error, also returns the key's used by the expressions
	            -- @see execute
	            -- @usage myParser:compile ( 'math string 1 ' [, ..., 'math string N'] )
				function  ( obj, ... )
					local allParametersConsumed
					local x
					local answer -- set to nil not {} on purpose so nil returned on error
					for x = 1, arg.n do
						local parse = arg [ x ]
						if type (parse) ~= _STRINGTYPE then
							parse = inspect (parse) -- must be a string
						end
						obj.myLogger:Log_Debug_mathParser ('parsing: ' , parse )
						-- if its a string we parse, an actual object just returns the object
							-- look for tables first { ... }
							local tableOfResults, _, totalCount = obj:breakAppart ( parse, true, 0, FORMULAFORMAT.oCBracket, FORMULAFORMAT.cCBracket )
							if totalCount and totalCount ~= 0 then
								obj.myLogger:Log_Error_mathParser ('you have a table { ... } mismatch in expression "' .. parse .. '"')
								break
							else
								-- this will be an array of characters/tables if '{' '}' pairs
								if tableOfResults then
									answer = answer or {}
									local compileResult = examineExpression ( obj, tableOfResults)
									if compileResult then
										answer [#answer + 1] = compileResult
										if allParametersConsumed then
											allParametersConsumed = obj:mergeArrays (allParametersConsumed, answer[#answer].parametersConsumed)
										else
											allParametersConsumed = answer[#answer].parametersConsumed	
										end		
										answer [#answer].parametersConsumed = nil
									else
										answer = nil
										break
									end
								end
							end
					end

					if answer and #answer == 1 then 
						answer = answer[1]
					end

					return answer, allParametersConsumed
				end
			),
            classy:addMethod ( CONSTANTS.METHODS.ADDFUNCTION,
					--- adds a function to the parser, functions are single character, warnings are optional and will be tested prior to execiting the code
					-- @function addFunction
					-- @param obj the parser object
					-- @param parameters a table containing the following code = Your Code, warnings = A warning Function (returns true to trigger warning), errorMessage = Your error if warning is triggered, mutiType if parameters to your code can be of different types ( default is must be same type ), name = 'Function Name' ( currently limited to single char)
					-- @return No return value, however your code must return your result and warnings must return true or false
					-- @usage myParser:addFunction ( { code = CODE, name = NAME [, warnings = CODE, errorMessage = STRING ] } )
					function  ( obj, parameters )
						local name, code, warnings, error, multiType = parameters.name, parameters.code, parameters.warning, parameters.errorMessage, parameters.multiType or false
						if name:len () == 1 then
							if not obj.supportedFunctions [name] then
								obj.supportedFunctions [ name ] = { code = code, warnings = warnings, name = name, error = error, multiType = multiType }
							else
								obj.myLogger:Log_Warning_mathParser ( 'trying to define function "' .. name .. '", it already exists' )
							end
						else
							obj.myLogger:Log_Error_mathParser ( 'only supports single character functions "' .. name .. '" has ' .. name:len () )
						end
					end
            	),
            classy:addMethod ( CONSTANTS.METHODS.SETACTIVEPARAMETERS,
		            --- sets a list of paramters to the parser, its a key value pair table with key = typeOf ( key )
		            -- @function setActiveParameters
		            -- @param obj the mathParser object
		            -- @param ... the tables you want the key value pairs from
		            -- @return No return value
		            -- @usage myParser:setActiveParameters ( { Mandatory Parameters } [ , { Optional Parameters } ] )
					function ( obj, ... )
						local allParams = obj:mergeTables ( ... )
						local next = next
						local k, v
						local paramTypes = {}
						for k, v in next, allParams, nil do
							paramTypes [ k ] = type ( v )
						end
						obj.mathBuilderParameters = paramTypes
					end
				),
	        classy:addMethod ( CONSTANTS.METHODS.GETACTIVEPARAMETERS,
					--- gets a list of paramters to the parser, its a key value pair table
					-- @function getActiveParameters
					-- @param obj the mathParser object
					-- @return key value pairs of known parameters
					-- @usage local names = myParser:getActiveParameters ()
					function  ( obj )
						return obj.mathBuilderParameters
					end
				),
	        classy:addMethod ( CONSTANTS.METHODS.RUNFUNCTION,
					--- runs a specific parser function. Allows you to test your functions inside mathParser
					-- @function runFunction
					-- @param obj the mathParser object
					-- @param name the mathParser function
					-- @param ... the parameters for that function
					-- @return nil if error or the result of the execution of that function
					-- @usage local result = myParser:runFunction ( FUNCTIONNAME [, ParamA, .. ParamN ] )
					function ( obj, name, ...)
						if obj.supportedFunctions [ name ] then
							return obj.supportedFunctions [ name ] ( ... )
						else
							obj.myLogger:Log_Warning_mathParser ( 'trying to execute "' .. name .. '", but it does not exist' )
							return nil
						end
					end
				),
	        classy:addMethod ( CONSTANTS.METHODS.ISFUNCTION,
					--- returns true/false if it is/is not a known function name
					-- @function isFunction
					-- @param obj the mathParser object
					-- @param name the mathParser function
					-- @return true if function exists or false if not
					-- @usage local doesExist = myParser:isFunction ( FUNCTIONNAME )
					function  ( obj, name )
						return obj.supportedFunctions [ name ] ~= nil
					end
				),
			classy:addMethod ( CONSTANTS.METHODS.EXECUTECODE,
					--- executes an actual compile table(s)
					-- @function execute
					-- @see compile
					-- @param obj the mathParser object
					-- @param codeBlock table created by compile
					-- @param parameters the manditory parameters as a key value pair, values are the values in the calculation. OptionalParameters	values can be set here also.
					-- @param optionalParameters the optional parameters as a key value pair, values is ignored (just has to exist), this lets the executor know if it can't find this key then use a default value for that datatype.	
					-- @return a list of values from the calculations
					-- @usage local result [, ... resultN ] = myParser:execute ( codeBlock, { parameter1 key = value1 [ ... , parameterN key = valueN ] } [ , { optional parameter1 = true  [, ... optional parameterN = true ]} ] )					
					function ( obj, codeBlock, parameters, optionalParameters )
						parameters = parameters or {}
						optionalParameters = optionalParameters or {}
						local allParams = obj:mergeTables ( parameters, optionalParameters )
						local x
						local result 
						if codeBlock then
							if not codeBlock.primaryExecutionPoint then -- assume its one layer down, you sent a table of executions
								local y
								for y = 1, #codeBlock do
									local resultGroup =  { obj [ CONSTANTS.METHODS.EXECUTECODE ] ( obj, codeBlock [ y ] , parameters, optionalParameters ) }	
									result = result or {}
									local z
									for z = 1, #resultGroup do
										result [ #result + 1 ] = resultGroup [ z ]
									end
								end
							else
								result = resolveCode ( obj, codeBlock.primaryExecutionPoint, parameters, allParams, optionalParameters, {} )
							end
							if result then 
								if obj:isVersionFivePointTwoOrAbove () then
									return table.unpack ( result )
								else
									return unpack ( result )
								end
							end
						else
							obj.myLogger:Log_Warning_mathParser ( 'trying to execute, but no code provided' )
						end

						return nil
					end
				),	 
			classy:addMethod ( CONSTANTS.METHODS.COMPILEANDEXECUTE,
					--- compiles then executes an actual compile table(s)
					-- @function compileAndExecute
					-- @see compile
					-- @see execute
					-- @param obj the mathParser object
					-- @param ... list of expressions to resolved followed by the paramters and optional parameter tables
					-- @return a list of values from the calculations
					-- @usage local result [, ... resultN ] = myParser:compileAndExecute ( expression1 [, ... expressionN] [, { parameter1 key = value1 [ ... , parameterN key = valueN ] } [ , { optional parameter1 = true  [, ... optional parameterN = true ]} ] ] )	
				function ( obj, ... )
					local parameters, optionalParameters

					-- if we have at least 2 arguments then test them to see if they are parameters
					if arg.n >= 2 then
						if type ( arg [ arg.n - 1 ] ) == _TABLETYPE then
							parameters = arg [ arg.n  - 1 ]
							if type ( arg [ arg.n ] ) == _TABLETYPE then
								optionalParameters = arg [ arg.n ]
							end
							-- even if you put an expression after the parameters we will ignore it
							arg [ arg.n ] = nil
							arg [ arg.n - 1 ] = nil
						elseif type ( arg [ arg.n ] ) == _TABLETYPE then
							parameters = arg [ arg.n ]
							arg [ arg.n ] = nil
						end
					elseif arg.n == 1 then
						if type ( arg [ arg.n ] ) == _TABLETYPE then
							parameters = arg [ arg.n ]
							arg [ arg.n ] = nil
						end
					end

					arg.n = nil

					obj:setParameters ( parameters, optionalParameters )

					local ctables
					if obj:isVersionFivePointTwoOrAbove () then
						ctables = obj [ CONSTANTS.METHODS.COMPILE ] ( obj, table.unpack ( arg ) )
					else
						ctables = obj [ CONSTANTS.METHODS.COMPILE ] ( obj, unpack ( arg ) )
					end

					return obj [ CONSTANTS.METHODS.EXECUTECODE ] ( obj, ctables, parameters, optionalParameters )
				end
				),       
            classy:addNotes ( mathParser._VERSION .. '\n\n' .. mathParser._DESCRIPTION .. '\n' .. mathParser._LICENSE, ... )
		)

