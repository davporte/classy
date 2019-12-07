------------
-- creates Object-oriented programming environment for LUA
-- supports objects with :removeSelf ( ) methods
-- such as Corona SDK
-- @author David Porter
-- @module classy
-- @release 1.0.0
-- @license MIT
-- @copyright (c) 2019 David Porter

local classy = {

   --- version details
   _VERSION = ... .. '.lua 1.0.0',
   _URL = '',
   --- the current module description
   _DESCRIPTION = [[
      ============================================================================
      -- creates Object-oriented programming environment for LUA
      -- supports objects with :removeSelf ( ) methods
      -- such as Corona SDK
      ============================================================================
      ]],
      --- current licence for the module
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
      _MODULENAME = ... .. '.lua',
      --- the master logging flag
      -- @usage classy._LOGGING = true | false
      -- @see describeLogging
      -- @see changeLoggingState
      _LOGGING = true,
      --- currently supported logging values
      -- @usage classy:changeLoggingState ( { argTable } )
      -- @see describeLogging
      -- @see changeLoggingState
      _SUBLOGGING = {   _ATTRIBUTESERASE = true, -- the erasing of attributes
                        _ATTRIBUTESSET = true,  -- the setting of attributes
                        _ATTRIBUTESGET = true, -- the getting of attributes
                        _BUILDING = true, -- the building of a class
                        _RUNNING = true  -- the running of class methods
                     },
      --- a function you can set to do something with logs,
      -- if not set then the default logger is called.
      -- If myLogger returns true then the default logger will also be called, if false/nil it will not be.
      -- If myLogger returns any other value then the default logger is called to display that value.
      -- Note that myLogger still obays _LOGGING, _SUBLOGGING settings
      -- @usage classy.myLogger = function ( log ) 
      -- -DO SOME STUFF WITH log 
      -- end
      -- This does not trigger the standard logger to also log
      -- @usage classy.myLogger = function ( log ) 
      -- DO SOME STUFF WITH log 
      -- return true 
      -- end
      -- This does trigger the standard logger to log
      myLogger = nil
}

--- Internal Only
-- @section  EXTERNAL_FACING_CALLS
--

-- @local local copies for table manipulation
local next = next
local k, v

-- @local values we create for _G need to be protected
local protectedValuesin_G = {}

-- @local Name of the super attribute, internalID String, the logging flag name, and the text that starts a classy log message
local SUPERNAME, INTERNALIDSTR, LOGGINGNAME, CLASSYDESCRIBER = 'super', ' Internal ID: ', '_LOGGING', ... .. ': '

-- @local errorLayer is used to track how deep we are in functions inside classy.lua so we through errors back to correct place in the users code
local errorLayer = 2

-- @local local store of _SUBLOGGING so user can't change, we want to ensure sublogging table always exits
local subLogging = { _MODULEDESCRIBER = ... .. ':' }
for k, v in next, classy._SUBLOGGING do
   subLogging [ k ] = { active = v, name = k }
   protectedValuesin_G [ k ] = k
end

-- @local removes these references, no longer required they have been copies to a private store
classy._SUBLOGGING = nil

-- @local stores the current class we are inside running. This allows us to detect if a varable that is private is being accessed outside of a class method
local currentRunningClass

-- @local stores classTypes, in a table. The classtypes only appear in the table once contructed.
-- @local If under contruction they will not appear in the table and init will not run, this table also notes creation order
local classTypes

-- @local stores class building blocks initmethod, methods etc
local classBuildingBlocks
-- @local reference to type names
local types = {func =type (function () end), table = type ({}), init = 'init', methods = 'methods', special = 'special', number = type (9), string = type (''), bool = type (true), attributeStore = '_attributeStore', typeDescriber = '_typeDescriber'}

--- operators that a class can be overload, > and >= supported using not > and not >=
-- @within Global Attributes (Protected)
local overloadOperators = 
{
   '+', -- add
   '-', -- subtract
   '*', -- multiply
   '/', -- divide
   '%', -- mod 
   ':-', -- unary minus, note colon on front of -
   '..',-- concat  
   '=', -- equals
   '<', -- less than 
   '<=' -- less than or equals to
}

-- @local doing it this way for the ldoc documentation generator
local overloadFunctions = 
{
   '__add', 
   '__sub', 
   '__mul', 
   '__div', 
   '__mod', 
   '__unm', 
   '__concat', 
   '__eq', 
   '__lt', 
   '__le'
}

-- @local we are doing this way to make sure the document generator ldoc works
local count
local newOverloadOperators = {}
for count = 1, #overloadFunctions do
   newOverloadOperators [ count ] = { v = overloadOperators [ count ], r = overloadFunctions [ count ] }
end

overloadOperators = newOverloadOperators

--@local this function is called to throw an exception back to the caller at errorLayer in the stack
-- @param  errorMsg that will be created
-- @param  layer how many layers up
local function myError ( errorMsg,  layer )
   currentRunningClass = nil -- this is needed in case classy is called with pcall, when exception occurs we need to clear curretRunningClass
   error ( errorMsg,  errorLayer )
end

-- @local adds a protected meta table to table tbl. testTbl contains where (protected) objects will be tested
-- mt can be passed to set a custom protection metatable
-- @param  tbl the table you want to protect
-- @param  testTbl where the protected variables are stored
-- @param  errorMsg is what is returned by error if you violate protection
-- @param  protectionMsg is the _metatable message
-- @param  mt optional mt if you don't want the standard mt
local function addProtectionTo ( tbl, testTbl, errorMsg, protectionMsg, mt)
   if ( tbl and testTbl ) or ( tbl and mt ) then
      mt = mt or {  
                     -- @local check the tetst table for the protected value, if it is there then return it, otherwise nil as key k is not in table t
                     __index =   function (t, k)
                                    if testTbl [k] then
                                       return testTbl [k]
                                    else
                                       return nil
                                    end
                                 end,
                     -- @local if key k is already in your testTble we are attempting an overwrite and this should throw an exception
                     -- if the key is not in the testTbl it is not a protected key so set it in the table t
                     __newindex =   function ( t, k, v )
                                       if testTbl [k] then
                                          errorLayer = errorLayer + 1
                                          myError ( errorMsg .. ':' .. k)
                                       else
                                          rawset ( t, k, v)
                                       end
                                    end
                  }

      --@local we don't want the user messing with the metatable, so protect the metatable
      mt.__metatable = protectionMsg

      setmetatable ( tbl, mt )
   end
end


-- @local returns true if a table is empty, true if not empty table, nil if not a table 
-- @param tbl the table we want to check
-- @return true if empty false if not, nil if not a table
local function tableIsEmpty ( tbl )
   if type (tbl) ~= types.table then
      return nil
   else
      local next = next
      return next ( tbl ) == nil
   end
end

-- @local are the internal bit masks used to mark attributes as Private or Immutable
-- LUA does not support bitwise operations natively
-- LSB bit 1 is private, bit 2 is mutable/immutable
local PRIVATEBIT, IMMUTABLEBIT, MAXBITSSUPPORTED = 1, 2, 2 -- if we add more then bit goes 4, 8, 16 .... and MAXBITSSUPPORTED goes 3, 4, 5 ...

-- @local returns the internal ID of a class c
-- @param c the class we want the id for 
-- @return getInternalID array [ a decription string for the class ID or None, true if it existed false if it did not, the class itself or nil]
local function getInternalID ( c )
   local returnValue = INTERNALIDSTR
   if c and classTypes and classTypes [ tostring ( c ) ] then
      return { returnValue .. classTypes [ tostring ( c ) ], true,  classTypes [ tostring ( c ) ]}
   else
      return { returnValue .. 'None', false, nil }
   end
end

-- return values of getInternalID array, we reference these as constants
local GETINTERNALID_TXT, GETINTERNALID_RSLT, GETINTERNALID_VALUE = 1, 2, 3

-- @local this is the class logger function. If logging is true it constructs the message, if false it does not
-- ... paramter list are converted to strings and constructed p1 ... pN
-- prints the error out to stderr or if classy.myLogger also exists sends it to that
-- if classy.mylogger returns true (or any value other than false/nil/0) then the standard logger will also log after classy.mylogger
-- @return No return value
local function classLogger ( ... )
   if classy._LOGGING then
      local args = { ... }
      local message = subLogging._MODULEDESCRIBER 
      local x
      for x = 1, #args do
         message = message .. tostring ( args [x] )
      end
      -- by default print is used, you can change this to what ever you want by creating myLogger
      if classy.myLogger and type ( classy.myLogger ) == types.func then
         local loggerResult = classy.myLogger ( message )
         if loggerResult then
            if type ( loggerResult ) == types.bool and loggerResult then
               print ( message )
            else
               print ( CLASSYDESCRIBER .. tostring ( loggerResult ) )
            end
         end
      else
         print ( message )
      end
   end
end

-- @local this is the sublogger call, it calls classLogger for items that support sublogging
-- @param logType expects first paramter to be a valid subclass
-- @param ... the paramters passed fot logging
-- @return No return value
local function subclassLogger ( logType, ... )
   if logType.active then
      classLogger (logType.name ,':',  ... )
   end
end

-- @local track the state of currentRunningClass(s), we may have nested action e.g. obj = obj or ( classType () ), this would be nested x  2: one for ClassType () one for obj =
-- @param classThatMadeCall is the class identifier
-- @param stateChange is true for +1 or flase/nil for -1
local function classRunTracker ( classThatMadeCall, stateChange )
   currentRunningClass = currentRunningClass or { }
   local classThatCalledAsString = tostring ( classThatMadeCall )
   local thisClassInstanceRunState = currentRunningClass [ classThatCalledAsString ] or { }
   subclassLogger ( subLogging._RUNNING, 'testing class ', classThatMadeCall )
   local classCount = thisClassInstanceRunState.count or 0
   stateChange = stateChange or false

   if stateChange then
      subclassLogger ( subLogging._RUNNING, 'class run state of + 1' )
      thisClassInstanceRunState.count = classCount + 1
      currentRunningClass [ classThatCalledAsString ] = thisClassInstanceRunState
   else
      subclassLogger ( subLogging._RUNNING, 'class run state of - 1' )
      if classCount == 0 then
         myError ('this class has returned an unexpected run result')
      end
      classCount = classCount - 1
      if classCount == 0 then
         subclassLogger ( subLogging._RUNNING, 'class run state released for class ', classThatMadeCall )
         currentRunningClass [ classThatCalledAsString ] = nil
         if tableIsEmpty ( currentRunningClass ) then
            subclassLogger ( subLogging._RUNNING, 'class run state empty so released' )
            currentRunningClass = nil
         end
      else
         thisClassInstanceRunState.count = classCount 
         currentRunningClass [ classThatCalledAsString ] = thisClassInstanceRunState
      end
   end
end

-- @local test to see if the curent running class is inside a currentRunningclass state or not, true if ok, false if not
-- @param classThatWantsToKnow is the classthat is wanting to know if it is inside a class method
local function amIInsideaClassMethod ( classThatWantsToKnow )
   if currentRunningClass and currentRunningClass [ tostring ( classThatWantsToKnow ) ] then
      return true
   else
      return false
   end
end

-- @local the bitwise operator as LUA does not support natively. We limit to 2 bits 2^MAXBITSSUPPORTED as this is all we care about for now
-- @param vala a number
-- @param valb a number
-- @param oper the operator, one of the bitOperators
-- @return the bitwise operation
local function bitOperation (vala, valb, oper)
   local r, mask, s = 0, 2^MAXBITSSUPPORTED 
   repeat
      s, vala, valb = vala + valb + mask, vala%mask, valb%mask
      r,mask = r + mask * oper % (s-vala-valb), mask/2
   until mask < 1
   return r
end

-- @local These set up the operators used in bitOperation
local bitOperators = {
   OR = 1, -- or
   XOR = 3, -- xor
   AND = 4 -- and
}

-- @local this function returns all the attributes klass or nil
-- @param klass a class
-- @return a table of attributes in a comma separated string
local function getAllAttributes ( klass )
   local internalID = getInternalID ( klass )
   local listOfAttributes
   if internalID [ GETINTERNALID_RSLT ] then
      local attributes = klass._attributes
      local next = next
      local k, v
      for k, v in next, attributes, nil do
         listOfAttributes = (listOfAttributes or '') .. k ..' ,'
      end      
      listOfAttributes = listOfAttributes:sub (1, listOfAttributes:len () - 2)
   end

   return listOfAttributes
end

-- @local describes a class c in text
-- @param c a class
-- @return a text string containing the description
local function describeClass ( c )
   local description = CLASSYDESCRIBER
   if c then 
      local internalID = getInternalID ( c )
      -- if it is an object the class is its meta table
      if not internalID [ GETINTERNALID_RSLT ] then
         internalID = getInternalID ( getmetatable ( c ) )
         desciption = 'object: '
      end
      description = desciption .. tostring ( c ) .. internalID [GETINTERNALID_TXT]  .. '\n'
      local methods = c._methods
      if c.init then
         description = description .. '\tInit Method Avaialble\n'
      else
         description = description .. '\tNo Init Method Avaialble\n'
      end
      if methods then
         description = description .. '\tMethods:\n'
         local next = next
         local k, v
         for k, v in next, methods, nil do
            description = description .. '\t\t' .. k .. ', Private: ' .. tostring ( v.private ) .. '\n'
         end
      end
      local attributes = c._attributes
      if attributes then
         description = description .. '\tAttributes:\n'
         local next = next
         local k, v
         for k, v in next, attributes, nil do
            local internalID = getInternalID ( v.whatType )
            local typeDescriber, isClass = internalID [GETINTERNALID_TXT], internalID [GETINTERNALID_RSLT]
            if not isClass then
               typeDescriber = tostring ( v.whatType )
               if typeDescriber ~= types.string then -- it is super
                  typeDescriber = types.table
               end
            end
            description = description .. '\t\t' .. k .. ', Private: ' .. tostring ( v.private ) .. ', Immutable: ' .. tostring ( v.immutable )  .. ', Type: ' .. typeDescriber .. '\n'
         end
      end
      if c._notes then
         description = description .. '\tNotes:\n' .. c._notes
      end

      if c._inheritanceStructure then
         description = description .. '\nInherets from ' .. describeClass ( c._inheritanceStructure [1] )
      end
   end

   return description
end

-- @local these are the reserved functions all classes and object have. You cannot overload them
local reservedClassFunctions = {
   --- a protected function to test class or object type, you CANNOT overload this
   -- @within  External Calls (Protected)
   -- @param self the object or class you are testing
   -- @param klass the class you want to test against, can be a class or a class ID
   -- @return true if self is of type klass, false if not
   -- @usage obj:is_a ( internalID | ClassType )
   -- @usage class:is_a ( internalID | ClassType )
   is_a = function ( self, klass )
               klass = klassClean ( klass )
               local m = getmetatable( self )
               while m do 
                  if m == klass then return true end
                  m = m._base
               end
               return false
            end,
   --- a protected function to dump a class or object type, you CANNOT overload this
   -- @within  External Calls (Protected)
   -- @param self the object or class you are testing
   -- @return a string containing the inspect details
   -- @usage obj:inspect (  )
   -- @usage class:inspect(  )
   inspect = function ( self )
                  if inspect then 
                     return (inspect (self))
                  else
                     return '>inspect not loaded<' 
                  end
               end,
   --- a protected function to describe a class or object type, you CANNOT overload this
   -- @within  External Calls (Protected)
   -- @param self the object or class you are testing
   -- @return a string containing the describe details
   -- @usage obj:describeClass (  )
   -- @usage class:describeClass(  )
   describeClass = function ( self ) return describeClass ( self ) end,
   --- a protected function to remove a class or object type, you CANNOT overload this
   -- if the type is a class then ALL objects of that class will be deleted, this could have some unexpected consequences
   -- you must explicitly set objects to nil to remove them after
   -- @within  External Calls (Protected)
   -- @param caller the object or class you are testing
   -- @usage obj:removeSelf (  ) obj = nil
   -- @usage class:removeSelf(  )
   -- @return No return value
   removeSelf = function ( caller ) 
                        local klass = caller
                        local internalID = getInternalID ( klass )
                        local iAmAnObject = not internalID [ GETINTERNALID_RSLT ]

                        -- if we are a class we don't need to get the class metatable as class objects are with us already, but for an object we do
                        if iAmAnObject then
                           subclassLogger (subLogging._ATTRIBUTESERASE, 'scrubbing: object an object ', caller )
                           klass = getmetatable ( caller )
                           internalID = getInternalID ( klass )
                        else
                           subclassLogger (subLogging._ATTRIBUTESERASE, 'scrubbing: object of class', internalID [GETINTERNALID_TXT] )
                        end

                        -- get the class attributes store
                        local attributeTables = rawget ( klass, types.attributeStore )

                        -- if it has one check for the object in that store
                        if attributeTables then

                           subclassLogger (subLogging._ATTRIBUTESERASE, 'scrubbing: the attributes table' )

                           -- if it is there then clean it out
                           local attributes 

                           local selfAsString = tostring ( caller )

                           -- if we are consuming an entire class attributes holds all the attribute details already
                           if not iAmAnObject then
                              attributes = attributeTables
                           else
                              attributes = rawget ( attributeTables, selfAsString )
                           end

                           -- clean all known atributes rom the tables
                           if attributes then

                              subclassLogger (subLogging._ATTRIBUTESERASE, 'scrubbing: the individual attributes' )

                              local next = next
                              local k, v
                              for k, v in next, attributes, nil do
                                 if type ( v ) == types.table then
                                    local mt = getmetatable ( v )
                                    if getInternalID ( mt ) [GETINTERNALID_RSLT] then -- its a class object
                                       v:removeSelf ( )
                                    else -- its a table, that may contain class variables, we don't want orphans !!!
                                       local tableScrubber
                                       tableScrubber =   function ( tbl, keyChain )
                                                            -- if we have aremoveSelf method then use that to destroy the object, this also helps with displayObjects
                                                            if tbl.removeSelf then
                                                               subclassLogger (subLogging._ATTRIBUTESERASE, 'running removeSelf: on ', keyChain)
                                                               tbl:removeSelf ( )
                                                            else
                                                               subclassLogger (subLogging._ATTRIBUTESERASE, 'scrubbing: ', keyChain)
                                                               local next = next
                                                               local k, v
                                                               for k, v in next, tbl, nil do
                                                                  if type ( v ) == types.table then
                                                                     tableScrubber ( v, keyChain .. '.' .. k )
                                                                  end
                                                               end
                                                            end
                                                         end

                                       tableScrubber ( v, k )
                                    end   
                                 end
                                 rawset (attributes, k, nil)
                                 subclassLogger (subLogging._ATTRIBUTESERASE, 'erased attribute: ', k)
                              end
                           end
                           if tableIsEmpty ( attributes ) then
                              rawset ( attributeTables, selfAsString, nil)
                              subclassLogger (subLogging._ATTRIBUTESERASE, 'erased object: ', selfAsString)
                           else
                              subclassLogger (subLogging._ATTRIBUTESERASE, 'unable to fully erase object: ', selfAsString)
                           end
                        end

                        if tableIsEmpty ( attributeTables ) then
                           rawset ( klass, types.attributeStore, nil )
                           subclassLogger (subLogging._ATTRIBUTESERASE, 'erased attributeTables for class: ', internalID [GETINTERNALID_TXT] )
                        else
                           subclassLogger (subLogging._ATTRIBUTESERASE, 'erased all objects from class: ', internalID [GETINTERNALID_TXT] )
                        end

                     end
}

-- @local A function that calls a method bound with the currentRunningClass
-- This is used to detect access to private attributes outside of a class 
-- @param method_name the method name running
-- @param methodClassIDOwner the method name running
-- @param obj the calling object
-- @param method the method name running
-- @param obj the calling objects class
-- @param ... the paramters passed for the method
-- @return the execution of the method
local function executeMethodBound (method_name, methodClassIDOwner, obj,  method, c, ...)
   -- doing it this way to avoid wasting time if logging is off
   if obj == c then
      subclassLogger ( subLogging._RUNNING, 'excuting method: ', method_name, ' on object ', obj, ' of class', INTERNALIDSTR, methodClassIDOwner ) 
   else
      subclassLogger ( subLogging._RUNNING, 'excuting method: ', method_name, ' on class ', obj, ' of class', INTERNALIDSTR, methodClassIDOwner ) 
   end
   -- set the current running class
   classRunTracker ( c, true )
   local returnValue = method ( ... )
   -- clear the current running class
   classRunTracker ( c, false )
   return returnValue
end

-- @local A function that checks if you already have used global values and generates a comma separated string
-- @param tbl a list of key value pairs to test the key against _G
-- @return the list as a string
-- @raise your code has already uses a global variable called "variablename", please DO NOT use: specific values are protected
local function valuesInUse ( tbl )
   errorLayer = errorLayer + 1
   local listOfValues = ''
   local next = next
   local k, v, x
   for k, v in next, tbl, nil do
      if _G [k] then
         myError ( 'your code has already uses a global variable called "' .. k .. '", please DO NOT use' )
      else
         protectedValuesin_G [k] = v
         listOfValues = listOfValues .. k .. ', '
      end
   end

   errorLayer = errorLayer - 1

   return listOfValues:sub (1, listOfValues:len () - 2)
end

-- @local doing it this way for the autodocumentation generator, validAttributeDescribers

--- These values are used to describe Private / Immutable state of an attribute
-- Immutable attrubutes CANNOT change,
-- Private attributes CANNOT be refered to outside the class object methods
-- @within Global Attributes (Protected)
local validAttributeDescribers = {
   Immutable = true, -- Immutable, Public: same as PublicImmutable
   Public = true, -- Mutable, Public: same as PublicMutable
   PublicMutable = true, -- Mutable, Public: same as Public
   PublicImmutable = true, -- Immutable, Public: same as Immutable
   Private = true, -- Mutable, Private: same as PrivateMutable
   PrivateMutable = true, -- Mutable, Private: same as Private
   PrivateImmutable = true -- Immutable, Private:
}

-- @local we use this format so we can build an error message with the values in them
local contentForValidAttributeDescribers = {
   Immutable = { value = IMMUTABLEBIT, _describer = true },
   Public = { value = 0, _describer = true }, -- the default value is Public , Mutable
   PublicMutable = { value = 0, _describer = true }, -- the default value is Public , Mutable
   PublicImmutable = { value = IMMUTABLEBIT, _describer = true },
   Private = { value = PRIVATEBIT, _describer = true },
   PrivateMutable = { value = PRIVATEBIT, _describer = true },
   PrivateImmutable = { value = bitOperation (IMMUTABLEBIT, PRIVATEBIT, bitOperators.OR), _describer = true }
}

-- @local doing it this way for the autodocumentation generator, validAttributeDescribers
for k, v in next, contentForValidAttributeDescribers, nil do
   validAttributeDescribers [k] = v
end

for k, v in next, validAttributeDescribers, nil do 
   local next = next
   local K, V
   -- move all attributes into the secured table
   local secured = {}
   for K, V in next, validAttributeDescribers [k], nil do
      secured [K] = V
   end

   validAttributeDescribers [k] = {}

   secured.__index =    function ( t, k ) return secured [ k ] end
   secured.__newindex =  function ( t, key, v )    
                           errorLayer = errorLayer + 1
                           if secured [ key ] then
                              myError ( k .. ': attempt to alter a protected value: ' .. key ) 
                           else
                              myError ( k .. ': attempt to add a new value: ' .. key .. ', not permited' ) 
                           end
                        end 

   addProtectionTo ( validAttributeDescribers [ k ], nil, nil,  'this is protected by ' .. classy._MODULENAME, secured )
end

-- copy validAttributeDescribers into _G
local describerString = valuesInUse ( validAttributeDescribers )

-- @local converts a number to number with english follow on eg 1st 2nd 3rd 4th etc
-- @param n a number
-- @return a string containing the correct english
local function appendTextOnNumber (n)
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

--- this function gets an attribute/method from the appropriate location
-- @param t the calling table
-- @param k the specific key
-- @param c the class the attribute belongs to
-- @return the value in the table
local function getAttribute (t, k, c)
   subclassLogger (subLogging._ATTRIBUTESGET, 'getting ', k, ' from object ', t, ' class ', c, getInternalID ( c ) [GETINTERNALID_TXT] )
   -- get the attribute or method
   local v = rawget ( c, k )
   -- if it's an internal class store i.e. begins with a _ or a method then return it 
   if k:sub(1, 1) == '_' then
      subclassLogger (subLogging._ATTRIBUTESGET, 'this is an internal attribute')
      return v
   elseif type ( v ) == types.func then
      subclassLogger (subLogging._ATTRIBUTESGET, 'this is a method')
      return v
   end
   local attributeGetter
   --- deals with finding an inherited attribute, called from within getAttribute
   -- @param t the calling table
   -- @param k the specific key
   -- @param c the class the attribute belongs to
   -- @return the attributes stored value
   -- @raise attribute ATTRIBUTENAME is private and can only be read from within its class
   attributeGetter = function (t, k, c)
                              errorLayer = errorLayer + 1

                              local v = rawget (c, types.attributeStore)

                              if v then
                                 v = rawget (v, tostring ( t ))
                                 if v then
                                    --if private it can only be accessed from withing a class
                                    if c._attributes and c._attributes [k] and c._attributes [k].private and not amIInsideaClassMethod ( c ) then
                                       myError ( 'attribute ' .. k .. ' is private and can only be read from within its class' )
                                    end
                                    v = rawget (v, k)
                                 end
                              end

                              -- drop down the inheratance tree if you can to find the value
                              if not v then
                                 subclassLogger (subLogging._ATTRIBUTESGET, k, ' not found')
                                 if c._base then
                                    subclassLogger (subLogging._ATTRIBUTESGET, 'checking parent for ', k)
                                    v = attributeGetter (t, k, c._base)
                                 end
                              else
                                 subclassLogger (subLogging._ATTRIBUTESGET, k, ' found')
                              end
                              
                              errorLayer = errorLayer - 1

                              return v
                           end

   v = attributeGetter (t, k, c)

   if v ~= nil then
      subclassLogger (subLogging._ATTRIBUTESGET, 'value for ' .. k .. ' = ', v)
   else
      subclassLogger (subLogging._ATTRIBUTESGET, 'value for ' .. k .. ' is nil')
   end
   
   return v
end

--- this function stores an attribute in the appropriate location, used by newAttributeSet
-- @param t the calling table
-- @param k the specific key
-- @param c the class the attribute belongs to
-- @param v the value to set
-- @return No return value
local function storeAttribute (t, k, c, v)
   local attributes = rawget (c, types.attributeStore)
   attributes = attributes or {}
   local forWhatObj = attributes [ tostring ( t ) ] or {}

   -- may already have a value, if it does we need to detroy the current class attribute v (no orphans), this also helps remove display objects
   if v == nil and t [k] and t [k].removeSelf then
      print (subLogging._ATTRIBUTESSET, ' attribute ' .. k .. ' needs removeSelf( )')
      t [k]:removeSelf ( )
   end

   rawset (forWhatObj, k ,v)
   rawset (attributes, tostring ( t ), forWhatObj)
   rawset (c, types.attributeStore, attributes)
end

--- this function is called when an object attempts to set a new value
--- the function performs type checking of the value v and raises exception if this is not correct
-- @param t the calling table
-- @param k the specific key, attribute name
-- @param c the class the attribute belongs to
-- @param v the value to set
-- @return No return value
-- @raise attribute ATTRIBUTENAME - is immutable, is private and can only be set from within its class, incorrect base type, incorrect class type, no such attribute for class
local function newAttributeSet (t, k, c, v)

   errorLayer = errorLayer + 1

   -- first test to see if class c hass _attributees and also the attribute with key name k
   subclassLogger (subLogging._ATTRIBUTESSET, 'setting new attribute: ', k, ' for object ', t, ' of class ', c, getInternalID ( c ) [GETINTERNALID_TXT])
   if c._attributes and c._attributes [k] then
      subclassLogger (subLogging._ATTRIBUTESSET, 'attribute: ', k, ' mutable state is ', c._attributes [k].immutable )
      -- fail if the attribute is immutable and already has a value
      if c._attributes [k].immutable and getAttribute (t, k, c) then
         myError ( 'attribute ' .. k .. ' is immutable' )
      end

      subclassLogger (subLogging._ATTRIBUTESSET, 'attribute: ', k, ' private state is ', c._attributes [k].private )
      --if private it can only be accessed from withing a class
      if c._attributes [k].private and not amIInsideaClassMethod ( c ) then
         myError ( 'attribute ' .. k .. ' is private and can only be set from within its class' )
      end

      -- do a type check
      local myExpectedTypeDescription = c._attributes [k].whatType

      if type ( myExpectedTypeDescription ) == types.string then
         if myExpectedTypeDescription == types.table and getInternalID ( getmetatable ( v ) ) [ GETINTERNALID_RSLT ] then -- we have an expection it is a table, but it is a class type
            myError ( 'attribute ' .. k .. ' incorrect base type, expected a raw ' .. myExpectedTypeDescription .. ', not a class ' .. getInternalID ( getmetatable ( v ) ) [ GETINTERNALID_TXT ] )
         end

         if v == nil or type ( v ) == myExpectedTypeDescription then
            storeAttribute ( t, k, c, v )
         else
            myError ( 'attribute ' .. k .. ' incorrect base type, expected ' .. myExpectedTypeDescription .. ' not ' .. type ( v ) )
         end
      else
         if v ~= nil and myExpectedTypeDescription ~= getmetatable ( v ) then
            myError ( 'attribute ' .. k .. ' incorrect class type, expect a class with ' .. getInternalID ( myExpectedTypeDescription ) [GETINTERNALID_TXT] )
         end
         storeAttribute (t, k, c, v)
      end

      subclassLogger (subLogging._ATTRIBUTESSET, 'succesfully added ', k)
   else
      -- lets go doewn the inheratance of the object to find the attribute, if we get to the end then c._base == nil and we failed to find the object
      if not c._base then
         local listOfValidAttributes = getAllAttributes ( c )
         local errorMsg = 'attempt to set attribute ' .. k .. ', no such attribute for class it has the following: ' .. ( listOfValidAttributes or  'NO ATTRIBUTES' )
         myError ( errorMsg )
      else
         subclassLogger (subLogging._ATTRIBUTESSET, 'attempting to store in parent')
         newAttributeSet (t, k, c._base, v)
      end
   end

   errorLayer = errorLayer - 1

end

--- tests that a paramter is a method and store it in classBuildingBlocks
-- @param where what store ( currently init or methods )
-- @param func the function to store
-- @param name the function name
-- @param private is the function to be private or not
-- @raise duplicate method, invalid method name, additional init method, this method is reserved, this is not a function, empty method
local function buildingBlockBuilder (where, func, name, private)

   errorLayer = errorLayer + 1

   private = private or false
   -- base error messages
   local baseError = 'attempt to build class with '
   -- test to see if func is a function
   if func then
      if type (func) == types.func then
         if not reservedClassFunctions [ tostring ( name ) ] then
            classBuildingBlocks = classBuildingBlocks or {}
            -- only one init declaration permited per class construct
            if where == types.init and not classBuildingBlocks [types.init] then
               classBuildingBlocks [types.init] = func
               subclassLogger (subLogging._BUILDING, 'successfully found init method for class')
            elseif where == types.methods or where == types.special then
               classBuildingBlocks [where] = classBuildingBlocks [where] or {}
               -- test to see func name exists and is a string
               if name == tostring ( name ) then
                  local methods = classBuildingBlocks [where]
                  if not methods [name] then
                     -- succesfully addedd a new method
                     methods [name] = {method = func, private = private}
                     subclassLogger (subLogging._BUILDING, 'successfully found ', name, ' method for class')
                  else
                     -- you've duplcated a method name
                     myError ( baseError .. 'duplicate ' .. name .. ' method' )
                  end
               else
                  -- the method name is not a valid string
                  myError ( baseError .. 'method, but method name ' .. tostring (name) .. ' is not valid' )
               end
            else
               -- added a second call to initMethod
               myError ( baseError .. 'additional init method' )
            end
         else
            myError ( baseError .. name .. ' method failed, this method name is reserved' )
         end
      else
         -- func was not a valid function
         myError ( baseError ..  type (func) .. ' "' .. func .. '"; this is not a ' .. types.func )
      end
   else
      -- no method passed
      myError ( baseError ..  'empty ' .. where ..' method' )
   end

   errorLayer = errorLayer - 1

end


-- @local sets the attributes, 
-- by default whe add an attribute called super, which is the super of the objects class, it is immutable and private
-- @param argTable expects a table of this format
--
-- - 'arg': argument name
--
-- - 'argType': validBaseTypeDescribers ( validAttributeDescribers)
--
--
-- @param superState super if set ignores the fact attributes exists and call allows additions, used to add super
-- @see validAttributeDescribers
local function attributesSetter ( argTable, superState )

   errorLayer = errorLayer + 1

   subclassLogger (subLogging._ATTRIBUTESSET, 'attempt to add attributes to class')
   superState = superState or false
   local errorMessage, validatedAttributes
   -- note we may have attributes set because we are making a second call to set super, so check for this
   if classBuildingBlocks and classBuildingBlocks.attributes then
      validatedAttributes = classBuildingBlocks.attributes
   end
   if not superState and  ( classBuildingBlocks and classBuildingBlocks.attributes ) then
      errorMessage = 'attributtes for class already defined'
   else
      if argTable ~= nil then 
         if not superState and argTable [ SUPERNAME ] then 
            errorMessage = SUPERNAME .. ' is a reserved name, you cannot use this as an attribute'
         else
            local next = next
            local k, v
            for k, v in next, argTable, nil do
               errorMessage = 'argument ' .. k .. ' is not a known type: format must be argument = argType()'
               if type ( v ) == types.table then
                  if v._isABaseType ~= nil then -- it is a type
                     errorMessage = nil
                     validatedAttributes = validatedAttributes or {}
                     -- if we have an immutable value check it is of a valid type
                     local checkImmutableValue, whatTypeValue
                     if v._isABaseType then
                        checkImmutableValue = v.typeDescriber.value -- it was passed over in a base type function call
                        whatTypeValue = v.bT -- its a base type
                        subclassLogger (subLogging._ATTRIBUTESSET, 'adding attribute ', k, ' a ', whatTypeValue)
                     else
                        checkImmutableValue = v [types.typeDescriber]  -- it passed passed over in the class contruction
                        whatTypeValue = getmetatable ( v ) -- its a complex type
                        subclassLogger (subLogging._ATTRIBUTESSET, 'adding attribute ', k, ' a class with',  getInternalID (whatTypeValue) [GETINTERNALID_TXT] )
                     end
                     -- if super then we hard code these values as no paramter was passed
                     if k == SUPERNAME then
                        validatedAttributes [k] = { whatType = whatTypeValue, immutable = true, private = true  }     
                     else
                        -- it is another key so calculate its immutable and private values
                        if not checkImmutableValue or (checkImmutableValue and (type ( checkImmutableValue ) ~= types.number or checkImmutableValue > 2^MAXBITSSUPPORTED - 1)) then
                           errorMessage = 'argument ' .. k .. ' has invalid describer value ' .. tostring ( checkImmutableValue ) .. ', should be a supported value; ' .. describerString
                           break
                        end
                        validatedAttributes [k] = { whatType = whatTypeValue, immutable = bitOperation (checkImmutableValue, IMMUTABLEBIT, bitOperators.AND) ~= 0, 
                              private = bitOperation (checkImmutableValue, PRIVATEBIT, bitOperators.AND) ~= 0  }
                     end 

                     subclassLogger (subLogging._ATTRIBUTESSET, 'setting ', k, ' immutable:', validatedAttributes [k].immutable, ' private:', validatedAttributes [k].private, ' type:', whatTypeValue )    

                  else
                     break
                  end
               else
                  break
               end
               subclassLogger (subLogging._ATTRIBUTESGET, 'success')
            end
         end
      else
         errorMessage = 'invalid argument table supplied: format must be { arg1 = argType(), ..., argN = argNType () }'
      end
   end

   if errorMessage then
      myError ( errorMessage )
   else
      classBuildingBlocks = classBuildingBlocks or {}
      classBuildingBlocks.attributes = validatedAttributes
   end

   errorLayer = errorLayer - 1

   subclassLogger (subLogging._ATTRIBUTESSET, 'end attempt to add attributes to class')

end

--- called when an object of class class_tbl is created
-- @param class_tbl the class the object belongs to
-- @param argValue will either be a validAttributeDescribers, if we are defining or a table for building an object
--
-- attribute building attribute, value key pair attribute = value
--
-- - attribute: attribute name
--
-- - value: an object or value of the expected attribute type
--
-- @return the object
-- @see validAttributeDescribers
local function getNewObject (class_tbl, argValue, ...)

   local internalID = getInternalID ( class_tbl )

   subclassLogger (subLogging._ATTRIBUTESGET, 'get new object of class:',  internalID [GETINTERNALID_TXT] )
   local obj = {}

   -- set the current running class
   classRunTracker ( class_tbl, true )

   -- set the objects metatable to the class table, wher methods will be found
   setmetatable (obj, class_tbl)

   -- sort out methods for object
   local methods

   -- construct methods
   local methodBuilder = function (klass, class_tbl, privateCheck)
                  
                           errorLayer = errorLayer + 1

                           -- if privateCheck is set then only non private methods will be added
                           privateCheck = privateCheck or false
                           if klass._methods then
                              local next = next
                              local k, v
                              for k, v in next, klass._methods, nil do
                                 if not obj [k] then -- if method does not exist
                                    if not (privateCheck and v.private) then -- and sublass has it and its not private
                                       rawset (obj, k, function ( ... ) return executeMethodBound (k, internalID [ GETINTERNALID_VALUE ], obj, v.method, class_tbl, ...) end)
                                       --obj [k] = v.method -- it is my valid method
                                    end
                                 elseif not v.private and obj._methods [k].private then -- it already exists and a subclass already had it public, you can't now make it private
                                    myError ( 'attempt make method ' .. k .. ' private, when in a parent class this method is public' )
                                 end
                              end
                           end

                           errorLayer = errorLayer - 1

                        end

   -- 

   -- get your own methods first, they may be overloading other methods
   methodBuilder (class_tbl, class_tbl)

   -- look for inits, methods in parent classes
   if class_tbl._inheritanceStructure then
      local x
      for x = 1, #class_tbl._inheritanceStructure do
         -- add the paretn methods next, if the method already exists you keep yours. If private you do not take the method.
         methodBuilder (class_tbl._inheritanceStructure [x], class_tbl, true)
      end
   end

   -- object may have a super, note super can only be accessed inside class methods
   if class_tbl._base then 
      obj [ SUPERNAME ] = class_tbl._base
   end

   -- defining does not run the init method as object class being defined
   -- building does as we are building an object we want to keep
   local definingOrBuilding = false
   if argValue and type ( argValue ) == types.table then
      if argValue._describer then
         definingOrBuilding = true
      end
   end

   local initValue 
   if not definingOrBuilding then
      subclassLogger (subLogging._BUILDING, 'building new object')
      -- if we have an argValue apply the defaults to the object
      if argValue and type ( argValue ) == types.table then
         local next = next
         local k, v
         for k, v in next, argValue, nil do

            errorLayer = errorLayer + 2

            obj [k] = v

            errorLayer = errorLayer - 2
         end
         -- only send ... to init method
         if class_tbl.init then
            subclassLogger (subLogging._RUNNING, 'excuting method: ', types.init, ' on object ', obj, ' of class', internalID [GETINTERNALID_TXT])
            initValue = class_tbl.init ( obj, ... )
         end
      else
         -- argValue is a start up parameter so send it to init
         if class_tbl.init then
            subclassLogger (subLogging._RUNNING, 'excuting method: ', types.init, ' on object ', obj, ' of class', internalID [GETINTERNALID_TXT])
            initValue = class_tbl.init ( obj, argValue, ... )
         end
      end
   else
      subclassLogger (subLogging._BUILDING, 'defined new object')
      -- set the descriptorType for the object
      rawset ( obj, types.typeDescriber, argValue.value )
   end

   -- clear the current running class
   classRunTracker ( class_tbl, false )

   subclassLogger (subLogging._ATTRIBUTESGET, 'get new object success')

   return obj, initValue
end

-- @local returns a klass value from klass or if klass is a number the corresponding classtype
-- @param klass the class or a class ID number
-- @return the corresponding class, or klass 
local function klassClean ( klass )
   if type ( klass ) == types.number then
      klass = classTypes [ tostring ( klass ) ]
   end


   return klass
end

--
-- @local External Facing Calls Protected
--

--- adds key in ... to the protected _G table
-- @within External Call (Protected)
-- @param ... a list of key value pairs that will be protected
function classy:addProtectionTo ( ... )
   local count
   for count = 1, arg.n do
      local nextItem = tostring ( arg [ count ] )
   end
end


--- change logging, changes a logging value, if vlaue no existant it ignores it
-- @within  External Calls (Protected)
-- @param argTable a mandatory key value pair table that list what logging states ( key ) = ( value ), value must be true or false. Invalid key or  invalid value are ignored
-- @return No return value
-- @see _SUBLOGGING
-- @see _LOGGING
-- @usage classy:changeLoggingState ( { _SUBLOGGING_VALUE_1 = true | false, 
-- ..., _SUBLOGGING_VALUE_N = true | false } )
function classy:changeLoggingState ( argTable )
   if type ( argTable ) == types.table then
      local next = next
      local k, v
      for k, v in next, argTable, nil do
         if type ( v ) == types.bool then
            if k == LOGGINGNAME then
               classy [ LOGGINGNAME ] = v
            elseif subLogging [ k ] then
               subLogging [ k ].active = v
            end
         end
      end
   end
end

--- allows the logging states to be reported
-- @within  External Calls (Protected)
-- @param testWho optional log value to test
-- @return if testWho is set then false is testWho not valid, otherwise value of testWho. If testWho is empty, it returns full description of the logging state as a string
-- @see _SUBLOGGING
-- @see _LOGGING
-- @usage classy:describeLogging ( _SUBLOGGING Value ) 
-- @usage classy:describeLogging ( _LOGGING ) 
-- @usage classy:describeLogging ( ) 
function classy:describeLogging ( testWho )
   -- if testWho is provided use that
   if testWho then
      -- make sure it is a string
      testWho = tostring ( testWho )
      -- if it is the standard login name use that
      if testWho == LOGGINGNAME then 
         return classy [ LOGGINGNAME ]
      -- otherwise check for a sub log value
      elseif subLogging [ testWho ] then
         return subLogging [ testWho ].active 
      else
         -- nothing valid so return false
         return false
      end
   end

   local description = subLogging._MODULEDESCRIBER .. ' logging: '
   if classy._LOGGING then
      description = description .. ' on\n'
   else
      description = description .. ' off\n'
   end
   local next = next
   local k, v
   for k, v in next, subLogging, nil do
      if type ( v ) == types.table then
         description = description .. '\t' .. k
         if v.active then
            description = description .. ': on\n'
         else
            description = description .. ': off\n'
         end
      end
   end

   if classy.myLogger == type ( types.func ) then
      desciption = description .. '\tCustomer Logger active: ' .. classy.myLogger
   else
      description = description .. '\tDefault logger active'
   end

   return description .. '\n'

end

--- allows a class description using internal ID
-- If internalID is not a valid number or internalID does not exist, 'internalID does not exist ' is returned. 
-- If internalID it does exist then a description of that class and its inheratance is returned.
-- @within  External Calls (Protected)
-- @param internalID the internal ID of the class you are after, a number
-- @return a string description
-- @usage classy:describerClass ( internalID ) 
function classy:describeClass ( internalID )
   if type ( internalID ) == types.number and classTypes and classTypes.index [ internalID ] then
      return classTypes.index [ internalID ]:describeClass ()
   else
      return tostring ( internalID ) .. ' does not exist'
   end
end

--- adds attributes to a class, must be called inside a class constructor: classy:newClass
-- @within  External Calls (Protected)
-- @param argTable an attribute = DESCRIPTOR pair table of the arguments
-- @return No return value
-- @see newClass
-- @usage classy:attributes ( { a = Number ( ), b = Table ( Private )} ) 
function classy:attributes ( argTable )
   errorLayer = errorLayer + 1
   attributesSetter ( argTable )
   errorLayer = errorLayer - 1
end

--- gets the base class of a class type klass or internalID
-- @within  External Calls (Protected)
-- @param klass a table value: a current class value, or a number that is a valid class internalID
-- @return the root class at the bottom of the inhertance tree, this may be itself. If klass is not a class type it returns nil
-- @usage classy:getBaseClass ( classType | internalID )
function classy:getBaseClass ( klass )
  klass = klassClean ( klass )
   -- test for a valid klass
   if getInternalID ( klass ) [GETINTERNALID_RSLT] then
      if klass._base then 
         return classy:getBaseClass (klass._base)
      else
         return klass
      end
   end
end

--- gets the parent class of a class type klass   
-- @within  External Calls (Protected)
-- @param klass a table value: a current class value, or a number that is a valid class internalID
-- @return the parent class. If klass is not a class type it returns nil
-- @usage classy:getParentClass ( classType | internalID )
function classy:getParentClass ( klass )
  klass = klassClean ( klass )
   if getInternalID ( klass ) [GETINTERNALID_RSLT] then
      return klass._base
   end
end

--- sets the init method for a class, can only be called once per class creation.   
-- Note that the init function may return an optional return value,
-- this return value can be obtained at object creation time
-- obj, value = CLASS_NAME ()
-- @within  External Calls (Protected)
-- @param func a function that will run when an object of that class is created
-- @usage classy:initMethod ( function ( obj ) [DO STUFF WITH obj] end ) 
-- @usage classy:initMethod ( function ( obj ) [DO STUFF WITH obj] return RETURN_VALUE end ) 
-- @return No return value
-- @see newClass
function classy:initMethod ( func )
   subclassLogger (subLogging._BUILDING, 'attempt to add init method')
   buildingBlockBuilder (types.init, func)
end

--- sets a method by name into a class. All decendants of that class can call it.
-- @within  External Calls (Protected)
-- @param name the functions name
-- @param func a function that will run when an object of that class or its children call the method
-- @usage classy:addMethod ( function ( obj ) [DO STUFF WITH obj] end ) 
-- @usage classy:addMethod ( function ( obj ) [DO STUFF WITH obj] return RETURN_VALUE end ) 
-- @return No return value
-- @see newClass
function classy:addMethod (name, func)
   subclassLogger (subLogging._BUILDING, 'attempt to add method ', name)
   buildingBlockBuilder (types.methods, func, name)
end

--- sets a method by name into a class. Method is private so can only be called by an object of that class.
-- @within  External Calls (Protected)
-- @param name the functions name
-- @param func a function that will run when an object of that class calls the method
-- @usage classy:addPrivateMethod ( function ( obj ) [DO STUFF WITH obj] end ) 
-- @usage classy:addPrivateMethod ( function ( obj ) [DO STUFF WITH obj] return RETURN_VALUE end ) 
-- @return No return value
-- @see newClass
function classy:addPrivateMethod (name, func)
   classLogger ('attempt to add private method ', name)
   buildingBlockBuilder (types.methods, func, name, true)
end

--- this function adds notes to the class describer
-- it can be called multiple times, but the first version of notes will stick
-- @within  External Calls (Protected)
-- @param notes the notes you want to add
-- @usage classy:addNotes ( notes ) 
-- @return No return value
-- @see newClass
function classy:addNotes ( notes )
   subclassLogger (subLogging._BUILDING, 'attempt to add notes to class')
   classBuildingBlocks = classBuildingBlocks or {}
   classBuildingBlocks.notes = classBuildingBlocks.notes or notes
end

--- allows an operator to be overloaded by a class
-- @within  External Calls (Protected)
-- @param name the operator you want to overload
-- @param func a function that will run when an that overload operator runs
-- @usage classy:overload ( 'operator', function ( objA, objB ) [DO STUFF WITH objA/objB] return RETURN_VALUE end ) 
-- @return No return value
-- @see newClass
function classy:overload (name, func)

   errorLayer = errorLayer + 1

   if name and type (name) == types.string then
      local x
      local overloaded = false
      for x = 1, #overloadOperators do
         local test = overloadOperators [x]
         if test.v == name then
            subclassLogger (subLogging._BUILDING, 'attempt to overload operator ', name)
            buildingBlockBuilder (types.special, func, test.r, true)
            overloaded = true
            break
         end
      end
      if not overloaded then
         myError ( 'attempt to overload unknown operator ' .. name )
      end
   else
      myError ( 'attempt to overload with no value' )
   end

   errorLayer = errorLayer - 1

end

--- creates a new class type
-- @within  External Calls (Protected)
-- @return a new class type
-- @see initMethod
-- @see attributes
-- @see addMethod
-- @see addPrivateMethod
-- @see overload
-- @see addNotes
-- @param base the base class this class inherits from
-- @usage classType = classy:newClass ( [ base ], 
-- [ classy:initMethod ( func ) ], [ classy:attributes ( ... ) ], 
-- [[ classy:addMethod ( name, func ) ] ... [ classy:addPrivateMethod ( name, func ) ]], 
-- [ classy:overload (operator, func) ... [ classy:overload (operator, func) ]  ], 
-- [ classy:addNotes ( notes ) ] )
function classy:newClass ( base )
   subclassLogger (subLogging._BUILDING, 'attempt to create new class - begin')

   local c = {}
   -- test to see if base class exists then note your base class
   if base then
      if classTypes [ tostring ( base ) ] then
         c._base = base
      else
         errorLayer = errorLayer + 1
         myError ( 'base type is not a valid class' )
      end
   end

   -- mark as a complex type
   c._isABaseType = false

   -- the class will be the metatable for all its objects, it also stores attributes for class objects
   c.__index = function (t, k) return getAttribute (t, k, c) end

   -- get the inheretence structure for the class
   local inheritanceStructure
   local parent = classy:getParentClass (c)

   while parent do
      inheritanceStructure = inheritanceStructure or {}
      inheritanceStructure [#inheritanceStructure + 1] = parent
      -- check for attributes i may inheret
      if parent._attributes then
         local next = next
         local k, v
         for k, v in next, parent._attributes, nil do
            classBuildingBlocks = classBuildingBlocks or {}
            classBuildingBlocks.attributes = classBuildingBlocks.attributes or {}
            -- if the attribute has been inheretred previously take the child as the parameter
            if not classBuildingBlocks.attributes [k] then
               classBuildingBlocks.attributes [k] = v
            else
            end
         end
      end

      parent = classy:getParentClass ( parent )
   end
   -- store any inheritance structure for the class
   c._inheritanceStructure = inheritanceStructure

   -- when a new value in a source object t is to be set
   c.__newindex = function (t, k, v)
                     errorLayer = errorLayer + 1
                     newAttributeSet (t, k , c, v)
                     errorLayer = errorLayer - 1
                  end

   -- a constructor which can be called by className( arguments )
   local mt = {}

   -- @local the object constructor getNewObject is called for an object under construction
   -- @param class_tbl the objects class
   -- @param ... the paramters passed in the constructor
   mt.__call = function (class_tbl, ...)  return getNewObject (class_tbl, ...)  end
   
   -- set up super
   if base then
      local tblToSet = {}
      tblToSet [ SUPERNAME ] = base
      attributesSetter ( tblToSet, true)
   end

   -- load the methods/attributes
   if classBuildingBlocks then
      c.init = classBuildingBlocks [types.init]
      if classBuildingBlocks [types.methods] then
         local next = next
         local k, v
         local classIDToAllocate = 1
         if classTypes then
            classIDToAllocate = classTypes.nextOrder
         end
         c._methods = {}
         for k, v in next, classBuildingBlocks [types.methods], nil do
            c._methods [k] = v
            c [k] = function ( ... ) return  executeMethodBound (k, classIDToAllocate, c, v.method, c, ...) end --c._methods [k].method
         end
      end
      if classBuildingBlocks [types.special] then
         local next = next
         local k, v
         for k, v in next, classBuildingBlocks [types.special], nil do
            rawset (c, k, v.method)
         end
      end
      if classBuildingBlocks.attributes then
         c._attributes = classBuildingBlocks.attributes
      end
      if classBuildingBlocks.notes then
         c._notes = classBuildingBlocks.notes
      end
   end

   -- adds the reserved functions to the class
   local next = next
   local k, v
   for k, v in next, reservedClassFunctions, nil do
      c [k] = v
   end

   setmetatable(c, mt)

   -- se the classBuildingBlocks up for next class
   classBuildingBlocks = nil

   -- mark the class as constructed, and its creation order number
   classTypes = classTypes or { nextOrder = 1, index = { } }
   classTypes [ tostring ( c ) ] = classTypes.nextOrder
   classTypes.index [ classTypes.nextOrder ] = c

   subclassLogger (subLogging._BUILDING, 'attempt to create new class - success: allocated ID ',  classTypes.nextOrder, ', details are ', c )

   classTypes.nextOrder = classTypes.nextOrder + 1

   return c

end

-- @local doing it this way for the autodocumentation generator, validBaseTypeDescribers

--- the valid base classes that attributes can be, these are stored in the global table _G and are protected,
-- excluding ClassType (custom) - these are held in classy
-- @see validAttributeDescribers
-- @usage attribute = validBaseTypeDescribers (  validAttributeDescribers ) -- attribute defining
-- @usage object = validBaseTypeDescribers ( [{ attribute = value ... attribute = value }] ) -- object creation
-- @within Global Attributes (Protected)
local validBaseTypeDescribers = {
   String = true, -- a string type
   Number = true, -- a number type
   Table = true, -- a raw table, note this is not valid for a class
   Bool = true, -- a boolean type
   Function = true, -- a function type  
   ClassType = nil -- a custom class, created by calling newClass
}

-- @local base classe function, these return a true for a value _isABaseType then bT is the LUA type
local validBaseTypeFunctions = {
   --- String base class constructor
   -- @param description a validAttributeDescribers, if nil defaults to Public
   -- @usage attribute = String ( [ validAttributeDescribers ] )
   -- @return a protected string construction table
   -- @see validAttributeDescribers
   -- @within  External Calls (Protected)
   String = function ( description )
                  return {_isABaseType = true, bT = types.string, typeDescriber = description or _G.Public}
               end,
   --- Number base class constructor
   -- @param description a validAttributeDescribers, if nil defaults to Public
   -- @usage attribute = Number ( [ validAttributeDescribers ] )
   -- @return a protected number construction table
   -- @see validAttributeDescribers
   -- @within  External Calls (Protected)
   Number = function ( description )
                  return {_isABaseType = true, bT = types.number, typeDescriber = description or _G.Public}
               end, 
   --- Table base class constructor
   -- @param description a validAttributeDescribers, if nil defaults to Public
   -- @usage attribute = Table ( [ validAttributeDescribers ] )
   -- @return a protected table construction table
   -- @see validAttributeDescribers
   -- @within  External Calls (Protected)
   Table = function ( description )
                  return {_isABaseType = true, bT = types.table, typeDescriber = description or _G.Public}
               end,
   --- Bool base class constructor
   -- @param description a validAttributeDescribers, if nil defaults to Public
   -- @usage attribute = Bool ( [ validAttributeDescribers ] )
   -- @return a protected bool construction table
   -- @see validAttributeDescribers
   -- @within  External Calls (Protected)
   Bool = function ( description )
                  return {_isABaseType = true, bT = types.bool, typeDescriber = description or _G.Public}
               end, 
   --- Function base class constructor
   -- @param description a validAttributeDescribers, if nil defaults to Public
   -- @usage attribute = Function ( [ validAttributeDescribers ] )
   -- @return a protected function construction table
   -- @see validAttributeDescribers
   -- @within  External Calls (Protected)
   Function = function ( description )
                     return {_isABaseType = true, bT = types.func, typeDescriber = description or _G.Public} 
               end,
   --- custom class base constructor
   -- @param description a validAttributeDescribers, this is MANDATORY for a custom class
   -- @usage attribute = Function ( validAttributeDescribers )  
   -- @return a protected classType construction table
   -- @see validAttributeDescribers
   -- @within  External Calls (Protected)
   ClassType = function ( description )
               end -- this is a dummy that is here to genrate documentation, at run time it nils   
}

-- @local build the table correctly now documentation is fine
for k, _ in next, validBaseTypeDescribers, nil do
   validBaseTypeDescribers [ k ] = validBaseTypeFunctions [ k ]
end

valuesInUse ( validBaseTypeDescribers )
   
-- we use _G to store some important values and we dont want to break them
-- we need to lock the user down from playing with them

if getmetatable ( _G ) == nil then
   addProtectionTo ( _G, protectedValuesin_G, '_G: attempt to alter protected value ', '_G metatable is protected by ' .. classy._MODULENAME )
else
   myError ( 'unable to set _G metatable ' .. classy._MODULENAME .. ' can\'t be loaded' )
end

-- protect class functions from changes
local myProtectedFunctions = {}

for k, v in next, classy, nil do
   if type ( v ) == types.func then
      myProtectedFunctions [k] = v
      classy [k] = nil
   end
end

addProtectionTo ( classy, myProtectedFunctions, ... .. ': attempt to alter protected function ', ... .. ' metatable is protected by ' .. classy._MODULENAME )

-- end of protecting class functions

-- tests how deep errorLayer goes for specified functions and

-- remove locals we will not use from memory
k, v, addProtectionTo, validAttributeDescribers, validBaseTypeDescribers, valuesInUse, newOverloadOperators, count, overloadFunctions, validBaseTypeFunctions = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil

return classy