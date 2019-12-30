------------
-- creates a stack class.
-- designed for use with the classy object creator
-- @usage Stack = require ( 'stack' )
-- @author David Porter
-- @module stack
-- @release 1.0.2
-- @license MIT
-- @copyright (c) 2019 David Porter

local stack = {
	 _VERSION = ... .. '.lua 1.0.2',
     _URL = '',
     _DESCRIPTION = [[
      ============================================================================
      stack class built on constants class, built on classy OOP
   
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
      
      _LOGGING = false,
      _TABLETYPE = type ( {} ),
      _DEPENDANCIES = 'classy',
}

-- a refernce to the various LUA types, generate them by code just incase it ever did change in the future
local _STRINGTYPE, _NUMTYPE, _TABLETYPE, _BOOLTYPE , _FUNCTYPE = type ( '' ), type ( 9 ), type ( {} ), type ( true ), type ( function () end )

--- a constants used by the module
local CONSTANTS = {
  METHODS = { POP = 'pop', PUSH = 'push', DRAIN = 'drain', PEEK = 'peek', ISEMPTY = 'isEmpty', MEMBERS = 'members'} -- the default methods
}

-- @local require dependancies if any, this method will be removed after run creation of the module
local function getDependancies ()
  local dependancies = stack._DEPENDANCIES

  if dependancies then
    if type ( dependancies ) == _TABLETYPE then
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

end

-- @local generate any dependancie
getDependancies ()
-- @local remove this method it is no longer required
getDependancies = nil

--- gets next item from stack
-- @param obj the stack object iteself
-- @param dontRemove optional flag that says don't remove the item from the stack but still return it
-- @return the next item or nil
local function popFromStack ( obj, dontRemove )
  if obj.stackCount ~= 0 then
    local result = obj.stack [ #obj.stack ]
    if not dontRemove then
      obj.stack [ #obj.stack ] = nil
      obj.stackCount = obj.stackCount - 1
    end
    -- obj.myLogger:logFromModule_Info ( stack._MODULENAME, 'popped item from stack "', result, '" stackID:', obj ) -- alternative way to call, infact this is what the next line calls
    obj.myLogger:Log_Info ( 'popped item from stack "', result, '" stackID:', obj )
    return result
  else
    -- obj.myLogger:logFromModule_Info ( stack._MODULENAME, 'no item to pop from stack', ' stackID:', obj  ) -- alternative way to call, infact this is what the next line calls
    obj.myLogger:Log_Info ( 'no item to pop from stack', ' stackID:', obj  )
    return nil
  end
end

--- pushes an item to a stack
-- @param obj the stack object itself
-- @param item the item being pushed
-- @return No return value
local function pushToStack ( obj, item )
  obj.stack [ #obj.stack + 1 ] = item
  if item ~= nil then
    -- obj.myLogger:logFromModule_Info ( stack._MODULENAME, 'pushed item to stack "', item, '" stackID:', obj  ) -- alternative way to call, infact this is what the next line calls
    obj.myLogger:Log_Info ( 'pushed item to stack "', item, '" stackID:', obj  )
    obj.stackCount = obj.stackCount + 1
  end
end

--- calls the various gets from the stack. This is abstracted away from the user as we want dontRemove unexposed.
-- @param obj the stack object itself
-- @param howMany how many items you want off the stack
-- @param dontRemove optional flag if set to true stops items from being removed from the stack
-- @return either a single item. If howMany is set then that number, if available, is returned in a table. With a paramter n = the number of entries
local function stackGet ( obj, howMany, dontRemove )
  if howMany == nil then howMany = 1 end
  if type ( howMany ) == _NUMTYPE then
    local result
    if howmany == 1 then
      return popFromStack ( obj )
    end

    local allResult = {}
    local x

    for x = 1, howMany do
      local result = popFromStack ( obj, dontRemove )
      if result == nil then
        break
      end
      allResult [ #allResult + 1 ] = result
    end

    allResult.n = #allResult
    
    return allResult
  else
    -- obj.myLogger:logFromModule_Error  ( obj, 'attempt to pull a non numerical number of items value from stackID:', obj  ) -- alternative way to call, infact this is what the next line calls
    obj.myLogger:Log_Error  ( 'attempt to pull a non numerical number of items value from stackID:', obj  )
  end
end

return classy:newClass(
              classy:attributes ( { stack = Table ( Private ), stackCount = Number ( Private ), myLogger = Logger ( Private ), logEntity = Table ( Private ) } ),
              classy:initMethod (
                   --- adds the default log levels Error, Warning, Info and Debug and sets their associated default values ON (true), ON (true), OFF (false), OFF (false).
                  -- also sets the logger to the default output.
                  -- @function initMethod
                  -- @param obj the calling object 
                  -- @param args optional arguments sent to create the stack
                  -- @return No return value
                  -- @usage myStack = Stack ()
                  -- @usage myStack = Stack ( { stack = { item1, ...., itemN } } )
                  function ( obj, args )
                    -- classy:default values will load all the args into the object and any that are not passed over but in the default values table will be defaulted.
                    classy:setDefaultValues ( obj, args, { stack = {}, myLogger = _G.myLogger } )
                    obj.stackCount = #obj.stack -- you may have prepopulated the stack
                    -- check to see if the class is registerd by the logger, if not register it so we get the Log_ functions created
                    obj.logEntity = getmetatable ( obj )

                    if not obj.myLogger:registerState ( obj.logEntity ) then
                      obj.myLogger:registerModule ( obj.logEntity )
                    end
                  end       
                  ),       
              classy:addMethod ( CONSTANTS.METHODS.POP, 
              --- pops an items off a stack. 
              -- howMany allows more than one item to be popped.
              -- @function pop
              -- @param obj the stack object
              -- @param howMany how many items you want off the stack
              -- @return either a single item. If howMany is set then that number, if available, is returned in a table. With a paramter n = the number of entries
              function ( obj, howMany )
                    return stackGet ( obj, howMany )
                  end
                  ),
              classy:addMethod ( CONSTANTS.METHODS.PEEK, 
              --- pops an items off a stack. 
              -- howMany allows more than one item to be popped.
              -- @function peek
              -- @param obj the stack object
              -- @param howMany how many items you want off the stack
              -- @return either a single item. If howMany is set then that number, if available, is returned in a table. With a paramter n = the number of entries
              function ( obj, howMany )
                    return stackGet ( obj, howMany, true )
                  end
                  ),              
              classy:addMethod ( CONSTANTS.METHODS.PUSH, 
              --- pushes one or more items onto a stack
              -- @function push
              -- @param obj the stack object
              -- @param ... the list of objects to push
              function ( obj, ... )
                    local x
                    for x = 1, arg.n do
                      pushToStack ( obj, arg [ x ] )
                    end
                  end
                  ),
              classy:addMethod ( CONSTANTS.METHODS.DRAIN,
                --- drains all item from the stack and returns them
                -- @function drain
                -- @param obj the stack object
                -- @return All items from the stack
                function ( obj )
                  return obj [ CONSTANTS.METHODS.POP ] ( obj, obj.stackCount ) 
                end
                ),
                classy:addMethod ( CONSTANTS.METHODS.ISEMPTY,
                --- tests to see if a stack is empty
                -- @function isEmpty
                -- @param obj the stack object
                -- @return true if empty otherwise false
                function ( obj )
                  return obj.stackCount == 0 
                end
                ),
                classy:addMethod ( CONSTANTS.METHODS.MEMBERS,
                --- returns number of members in stack
                -- @function isEmpty
                -- @param obj the stack object
                -- @return number of members in stack
                function ( obj )
                  return obj.stackCount
                end
                ),
                classy:overload ( '+', 
                --- overloads + for stacks, adds two stacks together in one stack and drains the other stacks.
                -- can also do + just to add new object to stack, in this case obj2 is not a stack object
                -- @function '+' overloaded
                -- @param obj1 the first stack object
                -- @param obj2 the second stack object, or another object type
                function ( obj1, obj2 )
                  -- get a copy of each stack
                  local copy1 = obj1 [ CONSTANTS.METHODS.DRAIN ] ( obj1 )
                  local copy2 = obj2
                  -- check if obj2 is a stack type or not ?
                  if type ( obj2.is_a ) == _FUNCTYPE and  obj2:is_a ( getmetatable ( obj1 ) ) then
                    copy2 = obj2 [ CONSTANTS.METHODS.DRAIN ] ( obj2 )
                  end
                  -- get a new stack object, the object class is where the object constructor is and that is always the metatable of the object
                  local newStack = getmetatable ( obj1 ) ()
                  local next = next
                  local nextStack
                  for _, nextStack in next, { copy1, copy2 }, nil do    
                    local x
                    if nextStack.n then -- many items
                      for x = nextStack.n, 1, -1 do
                        newStack [ CONSTANTS.METHODS.PUSH ] ( newStack, nextStack [ x ] )
                      end
                    else
                      newStack [ CONSTANTS.METHODS.PUSH ] ( newStack, nextStack )
                    end
                  end
                  return newStack
                end
                ),
              classy:addNotes (stack._VERSION .. '\n\n' .. stack._DESCRIPTION .. '\n' .. stack._LICENSE, ... )
        )