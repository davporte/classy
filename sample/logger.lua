------------
-- creates a logger class.
-- this class does not throw exceptions directly, note return values and error messages need to be dealt with in your own code.
-- designed for use with the classy object creator
-- @usage Logger = require ( 'logger ' )
-- @author David Porter
-- @module logger
-- @release 1.0.0
-- @license MIT
-- @copyright (c) 2019 David Porter

local logger = {
   --- version details
   _VERSION = ... .. '.lua 1.0.0',
     --- Git Hub Location of the master branch
     _URL = '',
      --- the current module description
     _DESCRIPTION = [[
      ============================================================================
      a logger class that can be attached any object type
   
      ============================================================================
      ]],
      --- the current licence
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
      -- any depandancies
      _DEPENDANCIES = 'classy',
}

-- a local reference to a the module name
local moduleName = ...

-- a refernce to the various LUA types, generate them by code just incase it ever did change in the future
local _STRINGTYPE, _NUMTYPE, _TABLETYPE, _BOOLTYPE , _FUNCTYPE = type ( '' ), type ( 9 ), type ( {} ), type ( true ), type ( function () end )

--- a constants used by the module
local CONSTANTS = {
  LOGLEVELS = { ERROR = 'Error', WARNING = 'Warning', INFO = 'Info', DEBUG = 'Debug'}, -- the default log levels 
  METHODS = { ADDLOGLEVEL = 'addLogLevel', LOG = 'log' , SETLOGSTATE = 'setLogState', SETMYOUTPUT = 'setMyOutput', REMOVELOGLEVEL = 'removeLogLevel', REGISTERMODULE = 'registerModule',
              LOGFROMMODULE = 'logFromModule', DEREGISTERMODULE = 'deregisterModule', DESCRIBE = 'describe', SETMODULELOGSTATE = 'setModuleLogState' }, -- the default methods
  LOGPREFIX = 'Log_', -- a value placed in _G so the user can call the logger directly Log_LOGLEVEL ( ... )
  GLOBALID = '_G' -- a value to mark a function pusged to _G that it is global and not module local
}

-- @section  internal functions

--- this is the defualt output method for logging
-- the user can override this with a call to logger:setMyOutput
-- @param output the text to be outputed
-- @param userFunction the user defined function
-- @return always returns true to say it logged, or a prorietry user value if the user function runs
local function defaultOutput ( output, userFunction )
  local myReturnValue = true 
  if userFunction then
    myReturnValue = userFunction ( output )
  end
  print ( output )

  return myReturnValue
end

-- @local require dependancies if any, this method will be removed after run creation of the module
local function getDependancies ()
  local dependancies = logger._DEPENDANCIES

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

-- @local returns true if a table is empty, true if not empty table, nil if not a table 
-- @param tbl the table we want to check
-- @return true if empty false if not, nil if not a table
local function tableIsEmpty ( tbl )
   if type (tbl) ~= _TABLETYPE then
      return nil
   else
      local next = next
      return next ( tbl ) == nil
   end
end

--- resolves the module name
-- @param moduleName either a table or not a table. If table we look in package to find the moduel name
-- @return the module name or the orgional attribute
local function resolveModuleName ( moduleName )
  if type ( moduleName ) == _TABLETYPE then -- get the module name
    local next = next
    local k, v
    for k, v in next, package.loaded, nil do
      if v == moduleName then
        moduleName = k
        break
      end
    end
  end

  return moduleName
end

--- builds the log message if required
-- @param obj the object making the call
-- @param whatModule the module making the log call
-- @param logLevel the level being logged
-- @param ... the paramters that build the log message
-- @return No return value
local function log ( obj, whatModule, logLevel, ... )
  local knownLogLevels = obj.currentLogLevels
  -- test if the log level exists, if it does then test the master switch is on, otherwise stop all further log processing
  if knownLogLevels and knownLogLevels [ logLevel ] and knownLogLevels [ logLevel ].masterLogState then
    -- check if the particular object type is also willing to log, oterhwise stop all further log processing
    if not knownLogLevels [ logLevel ].objectSpecificOverRides or not knownLogLevels [ logLevel ].objectSpecificOverRides [ whatModule ] or knownLogLevels [ logLevel ].objectSpecificOverRides [ whatModule ].masterLogState then
      local x
      local output = moduleName .. ':' .. logLevel .. ':'
      -- prepend module name if not a global call
      if type ( whatModule ) == _TABLETYPE then
        whatModule = resolveModuleName ( whatModule )
      end
      if whatModule ~= CONSTANTS.GLOBALID then
        output = whatModule ..':' .. output
      end
      for x = 1, arg.n do
        output = output .. tostring ( arg [ x ] )
      end

      obj.callLogOutput ( output )
    end
  end
end

--- the self logger is called to see if we need to log internal issues somewhere
-- @param obj the object making the call
-- @param ... the paramters that build the log message
-- @return the same as you sent me
local function selfLogger ( obj,  ... )
  if obj.myOwnLogState then
    log ( obj, 'self', CONSTANTS.LOGLEVELS.WARNING, ... )
  end

  return ...
end

--- changes a specific loglevels state to true (ON) or false (OFF)
-- @param obj the object making the call
-- @param level the level being changed
-- @param state what state value
-- @return true if succes, false and an error message if failed
local function changeLogState ( obj, level, state )
  local knownLogLevels = obj.currentLogLevels
  if knownLogLevels and knownLogLevels [ level ] then
    knownLogLevels [ level ].masterLogState = state
    obj.currentLogLevels = knownLogLevels

    return true
  else
    return false, selfLogger ( obj, 'unkown log level ' .. level .. ', ignored' )
  end
end

--- changes a specific loglevels state to true (ON) or false (OFF) for a module moduleName
-- @param obj the object making the call
-- @param moduleName the moduleName we are doing this for, either a string or the module table itself
-- @param level the level being changed
-- @param state what state value
-- @return true if succes, false and an error message if failed
local function changeModuleLogState ( obj, moduleName, level, state )
  local knownLogLevels = obj.currentLogLevels
  if knownLogLevels and knownLogLevels [ level ] then
    moduleName = resolveModuleName ( moduleName )
    if obj.registestedModules and obj.registestedModules [ moduleName ] then
      local modulesSpecifics = knownLogLevels [ level ].objectSpecificOverRides or {}
      local particularModule = modulesSpecifics [ moduleName ] or {}
      particularModule.masterLogState = state
      modulesSpecifics [ moduleName ] = particularModule
      knownLogLevels [ level ].objectSpecificOverRides = modulesSpecifics
      obj.currentLogLevels = knownLogLevels
      return true
    else
      return false, selfLogger ( obj, 'module ' .. moduleName .. ' is unregistered for log level ' .. level )
    end
  else
    return false, selfLogger ( obj, 'unkown log level ' .. level .. ', ignored' )
  end
end

--- allows both the . and : form of a function to be called to log
-- @param obj the object making the call
-- @param moduleName the module that made the call
-- @param logClass the specific log name this call is for
-- @param ... the log paramters
-- @return the values generated by the call to logFromModule
local function argsCleaner ( obj, moduleName, logClass, ... )
  local args = { ... }
  if #args ~= 0 and args [ 1 ] == obj then
    return obj [ CONSTANTS.METHODS.LOGFROMMODULE ] ( obj, moduleName, logClass, unpack ( args, 2, #args ) )  
  else
    return obj [ CONSTANTS.METHODS.LOGFROMMODULE ] ( obj, moduleName, logClass, ... ) 
  end 
end

--- installs or removes a set of log types onto/from a module.
-- if the default sate is not set then the module assumes the state of the local masterLogState.
-- @param obj the logger object iteself
-- @param moduleName the module you wish to install onto
-- @param install true for install, false for uninstall
-- @param defaultState by default is it true or false
-- @param ... optional list of log levels to perform this action on or default is ALL currently known
-- @return No return value
local function installOrRemoveLoggingOnModule ( obj, moduleName, install, defaultState, ... )
  -- default is all known
  local knownLogLevels = obj.currentLogLevels or {}
  -- if we passed over an argument list then use that instead of the default
  if arg.n ~= 0 then
    local count
    local newKnownLogLevels = {}
    for count = 1, arg.n do
      -- its a know level so add it
      if knownLogLevels [ arg [ count ] ] then
        newKnownLogLevels [ arg [ count ] ] = knownLogLevels [ arg [ count ] ]
      end
    end
    knownLogLevels = newKnownLogLevels
  end

  -- lets attach/detach these log levels to the module
  local next = next
  local k, v

  local moduleLocation = package.loaded [ moduleName ]
  -- keep a copy as they k, v loop needs to look at all log levels
  local orgionalDefaultState = defaultState
  for k, v in next, knownLogLevels, nil do
    local objectSpecificOverRides = v.objectSpecificOverRides or { }
    local specificModuleOverRide = objectSpecificOverRides [ moduleName ] or {}
    if install then
      -- if default state is not set make it the same as the current master value
      if defaultState == nil then
        defaultState = v.masterLogState
      end
      specificModuleOverRide.masterLogState = defaultState
      -- add the logger function to that module specifically, so it can be called using moduleName.Log_LOGLEVEL ( ... )
      -- we do a test to see how the user made the call, we expect .Log_Level, however if you called with :Log_Level we fix it up
      moduleLocation [ CONSTANTS.LOGPREFIX .. k ] = function ( ... )
                                                      return argsCleaner ( obj, moduleName, k, ... )
                                                    end
    else
      specificModuleOverRide.masterLogState = nil
      -- remove the logger from that module
      moduleLocation [ CONSTANTS.LOGPREFIX .. k ] = nil
    end

    if tableIsEmpty ( specificModuleOverRide ) then
      specificModuleOverRide = nil
    end
    objectSpecificOverRides [ moduleName ] = specificModuleOverRide

    if tableIsEmpty ( objectSpecificOverRides ) then
      objectSpecificOverRides = nil
    end

    v.objectSpecificOverRides = objectSpecificOverRides
    defaultState = orgionalDefaultState

  end

  obj.currentLogLevels = knownLogLevels

end

--- registers/deregisters a module and adds loggers to that module
-- @param obj is the logger itself
-- @param moduleName is the module doing the register or deregister, can be a string or the module table
-- @param register is true to register or false to deregister
-- @return true if succes, false and an error message if failed
local function registerDeregisterModule ( obj, moduleName, register )
    moduleName = resolveModuleName ( moduleName )

  if type ( moduleName ) == _STRINGTYPE  then
    local registestedModules = obj.registestedModules or {}
    if register and registestedModules [ moduleName ] then
      return false, selfLogger ( obj, 'module ' .. moduleName .. ' already registered' )
    else
      local loadedAlready = package.loaded [ moduleName ]
      if not loadedAlready and register then
        return false, selfLogger ( obj, 'unable to register module ' .. moduleName .. ', as not loaded' )
      elseif register then
        -- installs local moduleName.Log_MODULE functions into the modules and sets the master logging records
        installOrRemoveLoggingOnModule ( obj, moduleName, true )
        registestedModules [ moduleName ] = loadedAlready
      elseif loadedAlready then
        installOrRemoveLoggingOnModule ( obj, moduleName, false )
        registestedModules [ moduleName ] = nil
      else
        return false, selfLogger ( obj, 'unable to deregister module ' .. moduleName .. ', as not loaded' )
      end

      obj.registestedModules = registestedModules
      return true
    end
  else
    return false, selfLogger ( obj, 'unable to register module, module name required' )
  end
end

--- adds/removes a log level to the known log levels.
-- This will also add/rremove a call into _G named Log_LOGLEVEL ( ... ) that allows the log to be called without needin to call logger:log directly
-- @param obj what object wanted this log level to exist
-- @param level what was the name of the level
-- @param addOrRemove add is true remove is false
-- @param defaultState is the log 
-- @usage local state, Msg = addLogLevel ( object, 'NAME', defaultState )
-- @return bool true or false if it worked or not
-- @return errorMsg if failed an error message will also be returned
local function addOrRemoveLogLevel ( obj, level, addOrRemove, defaultState )
  -- level must be a string
  if type ( level ) == _STRINGTYPE then
    local knownLogLevels = obj.currentLogLevels or {}
    -- check if it already exists
    if addOrRemove and knownLogLevels [ level ] then
      return false, selfLogger ( obj, 'attempt to add log level ' .. level .. ' failed, this log level already exists' )
    elseif not addOrRemove and not knownLogLevels [ level ] then
      return false, selfLogger ( obj, 'attempt to remove log level ' .. level .. ' failed, this log level does not exists' )
    else
      if addOrRemove then
        knownLogLevels [ level ] = { masterLogState = defaultState, objectSpecificOverRides = nil }
        -- protect this name in _G so user can do a call to Log_LOGLEVEL, note if you do lots of logging you may want a local reference to this in that area
        classy:addToProtectionIn_G ( CONSTANTS.LOGPREFIX .. level, function ( ... ) return obj [ CONSTANTS.METHODS.LOG ] ( obj, level, ... ) end )
      else
        knownLogLevels [ level ] = nil
        classy:removeFromProtectionIn_G ( CONSTANTS.LOGPREFIX .. level )
      end

      -- give state change to the registered modules to
      if obj.registestedModules then
        local k, v
        local next = next
        for k, v in next, obj.registestedModules, nil do
          installOrRemoveLoggingOnModule ( obj, k, addOrRemove, defaultState, level )
        end
      end

      obj.currentLogLevels = knownLogLevels

      return true
    end
  end

  return false, selfLogger ( obj, 'log level name must be a ' .. _STRINGTYPE )

end

--- checks the log state settings are ok
-- @param obj the object itself
-- @param logState the stae you wish to set
-- @param ... the list of log states you wish to change
-- @return the logstates we should process or false and an error message
local function getLogStateSettings ( obj, logState, ... )
  local args = { ... }
  if type ( logState ) ~= _BOOLTYPE then
    return false, selfLogger ( obj, 'log state must be a ' .. _BOOLTYPE )
  else
    -- if no ... then we are applying to all known log states
    if tableIsEmpty ( args ) then
      local next = next 
      local k
      if obj.currentLogLevels then
        for k, _ in next, obj.currentLogLevels, nil do
          args [ #args + 1 ] = k
        end
      end
    end

    return args
  end
end

-- @section class calls

return classy:newClass( 
              classy:attributes ( { currentLogLevels = Table ( Private ), masterLogState = Bool ( Private ), callLogOutput = Function ( Private ), registestedModules = Table ( Private ), myOwnLogState = Bool ( Public ) } ),
              classy:initMethod (
                  --- adds the default log levels Error, Warning, Info and Debug and sets their associated default values ON (true), ON (true), OFF (false), OFF (false).
                  -- also sets the logger to the default output.
                  -- @function initMethod
                  -- @param obj the calling object 
                  -- @return No return value
                  -- @usage myLogger = Logger ()
                  -- @usage myLogger = Logger ( { [ callLogOutput = YOUR_OWN_LOG_FUNCTION, 
                  --                        masterLogState = true | false, 
                  --                        myOwnLogState = true | false ]
                  --                    })
                  -- @see setMyOutput
                  function ( obj, args )
                    obj:addLogLevel ( CONSTANTS.LOGLEVELS.DEBUG, false )
                    obj:addLogLevel ( CONSTANTS.LOGLEVELS.INFO, false )
                    obj:addLogLevel ( CONSTANTS.LOGLEVELS.WARNING )
                    obj:addLogLevel ( CONSTANTS.LOGLEVELS.ERROR )
                    -- classy:default values will load all the args into the object and any that are not passed over but in the default values table will be defaulted.
                    classy:setDefaultValues ( obj, args, { callLogOutput = defaultOutput, masterLogState = true, myOwnLogState = true } )
                  end
                ),
              classy:addMethod ( CONSTANTS.METHODS.ADDLOGLEVEL,
                    --- addLogLevel, adds a log level completly from the logger.
                    -- All registered modules will also recive this log level
                    -- @function addLogLevel
                    -- @param obj the calling object OR class itself
                    -- @param logLevel the level you want to add
                    -- @return true if success, false if failed - Failed also returns an error message
                    -- @usage logger:addLogLevel ( 'LOG_LEVEL_NAME' [, true | false ] )
                  function ( obj, logLevel, defaultState )
                    if defaultState == nil then defaultState = true end
                    return addOrRemoveLogLevel ( obj, logLevel, true, defaultState )
                  end
                ),
              classy:addMethod ( CONSTANTS.METHODS.REMOVELOGLEVEL,
                    --- removeLogLevel, removes a log level completly from the logger.
                    -- All registerd modules will loose this log level
                    -- @function removeLogLevel
                    -- @param obj the calling object OR class itself
                    -- @param logLevel the level you want to remove
                    -- @return true if success, false if failed - Failed also returns an error message
                    -- @usage logger:removeLogLevel ( 'LOG_LEVEL_NAME' )
                  function ( obj, logLevel )
                    return addOrRemoveLogLevel ( obj, logLevel, false )
                  end
                ),
              classy:addMethod ( CONSTANTS.METHODS.REGISTERMODULE,
                    --- registerModule, registers a module from the logger.
                    -- This adds the calls to module.Log_LOGLEVEL from the module
                    -- @function registerModule
                    -- @param obj the calling object OR class itself
                    -- @param moduleName the module name you want to deregister
                    -- @return true if success, false if failed - Failed also returns an error message
                    -- @usage logger:registerModule ( 'MODULE_NAME' | module )
                  function ( obj, moduleName )
                    return registerDeregisterModule ( obj, moduleName, true )
                  end
                ),
              classy:addMethod ( CONSTANTS.METHODS.DEREGISTERMODULE,
                    --- deregisterModule, deregisters a module from the logger.
                    -- This removes the calls to module.Log_LOGLEVEL from the module
                    -- @function deregisterModule
                    -- @param obj the calling object OR class itself
                    -- @param moduleName the module name you want to deregister
                    -- @return true if success, false if failed - Failed also returns an error message
                    -- @usage logger:deregisterModule ( 'MODULE_NAME' | module )
                  function ( obj, moduleName )
                    return registerDeregisterModule ( obj, moduleName, false )
                  end
                ),
              classy:addMethod ( CONSTANTS.METHODS.LOG,
                    --- log, test the master state and if OFF (false) stop all further log processing
                    -- the default use of log calls at the Global level, i.e. no module name provided
                    -- @function log
                    -- @param obj the calling object OR class itself
                    -- @param logLevel the log level
                    -- @param ... the items to log
                    -- @return true if success, false if failed - Failed also returns an error message, note that if called with no values it always returns the name of the logLevel called
                    -- @usage logger:log ( 'LOG_LEVEL_NAME' | logLevel, [ ... Items you want to log in a list ] )
                    -- @usage Log_LOG_LEVEL_NAME ( [ ... Items you want to log in a list ] ) -- note this calls up to _G scope
                  function (obj, logLevel, ... )
                    if obj.masterLogState then
                        return log ( obj, CONSTANTS.GLOBALID, logLevel, ... )
                    end
                    return logLevel
                  end
                ),
              classy:addMethod ( CONSTANTS.METHODS.LOGFROMMODULE,
                    --- logFromModule, test the master state and if OFF (false) stop all further log processing
                    -- the default use of log calls at the Global level, i.e. no module name provided
                    -- @function logFromModule
                    -- @param the calling object OR class itself
                    -- @param moduleName the module name you want the log to come from
                    -- @param logLevel the log level
                    -- @param ... the items to log
                    -- @return true if success, false if failed - Failed also returns an error message
                    -- @usage logger:logFromModule ( module, 'LOG_LEVEL_NAME' | logLevel, [ ... Items you want to log in a list ] )
                    -- @usage module.Log_LOG_LEVEL_NAME ( [ ... Items you want to log in a list ] ) -- note this calls up to the module scope
                  function (obj, moduleName, logLevel, ... )
                    if obj.masterLogState then
                      return log ( obj, moduleName, logLevel, ... )
                    end
                  end
                ),              
              classy:addMethod ( CONSTANTS.METHODS.SETLOGSTATE,
                  --- setLogState, sets a specific log value to true (on) or false (off)
                  -- if called by an object then that state ONLY applies to that object,
                  -- if called by the class itself then it applies to ALL objects, except those that have a specific state
                  -- note if master is off ( false ) then even objects that have their own log level of true WILL NOT LOG.
                  -- to log the global master MUST be ON, the local master log level must be ON and your object specific value must be ON
                  -- @function setLogState
                  -- @param the calling object OR class itself
                  -- @param logState the specific state you want true or false (must be a bool)
                  -- @param ... the various levels you wish to change
                  -- @return true if success, false if failed - Failed also returns an error message
                  -- @usage logger:setLogState ( true | false [, LIST OF LOG LEVELS TO APPLY TO ] )
                  function ( obj, logState, ... )
                    local args, Error = getLogStateSettings ( obj, logState, ... )

                    if Error then
                      return false, selfLogger ( obj, Error )
                    else
                      local x
                      for x = 1, #args do
                        changeLogState ( obj, args [ x ], logState )
                      end

                      return true
                    end
                  end
              ),
              classy:addMethod ( CONSTANTS.METHODS.SETMODULELOGSTATE,
                  --- setModuleLogState, sets a specific log value for a module to true (on) or false (off)
                  -- if called by an object then that state ONLY applies to that object,
                  -- note if master is off ( false ) then even objects that have their own log level of true WILL NOT LOG.
                  -- to log the global master MUST be ON, the local master log level must be ON and your object specific value must be ON
                  -- @function setModuleLogState
                  -- @param obj the calling object OR class itself
                  -- @param moduleName the calling object OR class itself
                  -- @param logState the specific state you want true or false (must be a bool)
                  -- @param ... the various levels you wish to change
                  -- @return true if success, false if failed - Failed also returns an error message
                  -- @usage logger:setModuleLogState ( module, true | false [, LIST OF LOG LEVELS TO APPLY TO ] )
                  function ( obj, moduleName, logState, ... )
                    local args, Error = getLogStateSettings ( obj, logState, ... )

                    if Error then
                      return false, selfLogger ( obj, Error )
                    else
                      local x
                      for x = 1, #args do
                        changeModuleLogState ( obj, moduleName, args [ x ], logState )
                      end

                      return true
                    end

                  end
              ),

              classy:addMethod ( CONSTANTS.METHODS.SETMYOUTPUT,
                  --- setMyOutput, allows the user to control where logs are sent
                  -- @function setMyOutput
                  -- @param obj the calling object
                  -- @param outputFunc either a function the user wished to use of if a boolean and true it emplies use the default function only
                  -- @param defaultToFollow if set and true then after  the user function the default logger will also run
                  -- @return No return value
                  -- @usage logger:setMyOutput ( function ( logData ) [ return ] DO_STUFF_WITH logData end [, true ] )
                  -- @usage logger:setMyOutput ( true )
                  -- @usage logger:setMyOutput ( )
                  function ( obj, outputFunc, defaultToFollow)
                      if defaultToFollow and type ( defaultToFollow ) == _BOOLTYPE then
                        obj.callLogOutput = function ( text ) return defaultOutput ( text, outputFunc ) end
                      elseif outputFunc and type ( outputFunc ) == _FUNCTYPE then
                        obj.callLogOutput = outputFunc
                      elseif ( outputFunc and type ( outputFunc ) == _BOOLTYPE and outputFunc == true ) or outputFunc == nil then
                        obj.callLogOutput = defaultOutput
                      end
                  end
                ),
              classy:addMethod ( CONSTANTS.METHODS.DESCRIBE,
                  --- describes the current logger in a text string
                  -- @function describe
                  -- @param obj the calling object
                  -- @return a string description of the current logger
                  -- @usage logger:describe ()
                  function ( obj )
                    local onoff

                    onoff = function ( test )
                              if test then return ' On  ' else return ' Off ' end
                            end
                    local description = moduleName .. ':\n\tMaster Logging is:' .. onoff ( obj.masterLogState ) .. '\n\tSelf Logging is:' .. onoff ( obj.myOwnLogState )

                    local next = next
                    local k
                    if obj.registestedModules then
                      description = description .. '\n\tRegistered Modules:'
                      for k, _ in next, obj.registestedModules, nil do
                        description = description .. '\n\t\t' .. k .. ':'
                        if obj.currentLogLevels then
                          local key, value
                          local next = next
                          for key, value in next, obj.currentLogLevels, nil do
                            description = description .. '\n\t\t\t' .. key .. '\tMaster Set:' .. onoff ( value.masterLogState )
                            if value.objectSpecificOverRides and value.objectSpecificOverRides [ k ] then
                              description = description .. '\tModule Set:' .. onoff ( value.objectSpecificOverRides [ k ].masterLogState )
                            end
                          end
                        end
                      end
                    else
                      -- no registered modules so just print out the log levels
                      if obj.currentLogLevels then
                          local key, value
                          local next = next
                          for key, value in next, obj.currentLogLevels, nil do
                            description = description .. '\n\t\t' .. key .. '\tMaster Set:' .. onoff ( value.masterLogState )
                          end
                        end
                    end

                    return description
                  end
                ),

              classy:addNotes (logger._VERSION .. '\n\n' .. logger._DESCRIPTION .. '\n' .. logger._LICENSE)

        )