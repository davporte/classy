------------
-- creates a file handler class.
-- designed for use with the classy object creator
-- @usage FileHandler = require ( 'fileHandler' )
-- @author David Porter
-- @module fileHandler
-- @release 1.0.0
-- @license MIT
-- @copyright (c) 2019 David Porter

local filer = {
	 _VERSION = ... .. '.lua 1.0.0',
     _URL = '',
     _DESCRIPTION = [[
      ============================================================================
      file handler class built on constants class, built on classy OOP
      this is also build for use with the corona sdk
      if you are not using the corona sdk then overload fileNameBuilder, copyToDocumentsDirectory
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

--- constants used by the module
local CONSTANTS = { 
  METHODS = { SETDEFAULTREADBEHAVOUR = 'setDefaultReadBehavour', -- the set default read behavour method name
  OPENFILE = 'openFile', -- the open file  method name
  CLOSEFILE = 'closeFile', -- the close file  method name
  READ = 'readFrom', -- the read file method name
  FILEEXISTS = 'fileExists', -- the file exists method name
  COPYFILE = 'copyFile', -- the copy file  method name
  FILEISEMPTY = 'fileIsEmpty', -- the file IsEmpty method name
  WRITE = 'writeTo', -- the write file method
  FILENAMEBUILDER = 'fileNameBuilder' -- the filename builder (overload this if not using corona SDK in your own class object)
  }
} -- the default methods names

-- @local require dependancies if any, this method will be removed after run creation of the module
local function getDependancies ()
  local dependancies = filer._DEPENDANCIES

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

--- opens a file with mode "r" by default or mode defined by "mode"
-- "r" — Read mode (the default); the file pointer is placed at the beginning of the file.
--"w" — Write-only mode; overwrites the file if the file exists. If the file does not exist, creates a new file for writing.
-- "a" — Append mode (write only); the file pointer is at the end of the file if the file exists (the file is in the append mode). If the file does not exist, it creates a new file for writing.
-- "r+" — Update mode (read/write); all previous data is preserved. The file pointer will be at the beginning of the file. If the file exists, it will only be overwritten if you explicitly write to it.
--"w+" — Update mode (read/write); all previous data is erased. Overwrites the existing file if the file exists. If the file does not exist, creates a new file for reading and writing.
--"a+" — Append update mode (read/write); previous data is preserved and writing is only allowed at the end of file. The file pointer is at the end of the file if the file exists (the file opens in the append mode). If the file does not exist, it creates a new file for reading and writing.
-- @param obj the file handler object
-- @param fileDetails is an actual path or a table containing filename/path
-- @param mode is the mode you want the file to open in, if not specified then this is the defaultReadBehavour "r"
-- @see openFile
-- @return a file handler or nil
local function openFileLocal ( obj, fileDetails, mode )
  fileDetails = obj [ CONSTANTS.METHODS.FILENAMEBUILDER ] ( obj, fileDetails )
  obj.myLogger:Log_Info ( 'file open request ', fileDetails, ' mode:', mode, ' handler:', obj )
  if fileDetails ~= nil then
    local fileDetailResult, errorString = io.open( fileDetails, mode )
    if fileDetailResult then
      obj.myLogger:Log_Info ( 'succesfully opened "' , fileDetails , '" handler:', obj )
      return fileDetailResult
    else
      obj.myLogger:Log_Error ( 'io error:' .. errorString, ' handler:', obj )
    end
  else
    obj.myLogger:Log_Warning ( 'no file details provided handler:', obj )
  end 

  return nil
end

--- checks a file "fhd" to see if real or already closed
-- @param fhd the file handler you want to check
-- @return nil if all OK otherwise an error message
local function fileState ( fhd )
  local fileType = io.type ( fhd )
  if fileType then
    if fileType == 'closed file' then
      return 'already closed file'
    else
      return nil
    end
  else
    return 'unknown file ' .. tostring ( fhd )
  end
end

--- attempts to close a file "fhd"
-- @param obj the file handler object
-- @param fhd the file you wish to close
-- @see closeFile
-- @return true if success false if failed
local function closeFileLocal ( obj, fhd )
  local warningMessage = fileState ( fhd )
  if not warningMessage then
    io.close ( fhd )
    obj.myLogger:Log_Info ( 'succesfully closed file ', fhd, ' handler:', obj ) 
    return true  
  end
  obj.myLogger:Log_Warning ( 'io:trying to close ', fhd, ', but encountered an ', warningMessage, ' handler:', obj )
  return false
end

--- attempts a read on a file "fhd"
-- @param obj the file handler object
-- @param fhd the file you wish to read from
-- @param ... optional mode settings
-- @see readFrom
-- @return readData if success nil if failed
local function readFileLocal ( obj, fhd, ... )
  local warningMessage = fileState ( fhd )
  if not warningMessage then
    local readData 
    if ... == nil and obj.defaultReadBehavour.adjusted ~= nil then
      readData =  fhd:read ( obj.defaultReadBehavour.adjusted )
    else
      readData =  fhd:read ( ... )
    end
    if obj.defaultReadBehavour.closeAfterRead then
      closeFileLocal ( fhd )
    end
    return readData
  else
    obj.myLogger:Log_Warning ( 'io:trying to read an ', fhd, ', but encountered an ', warningMessage, ' handler:', obj )
  end
end

--- attempts a write on a file "fhd"
-- @param obj the file handler object
-- @param fhd the file you wish to read from
-- @param ... optional items you are putting into the file
-- @see writeTo
-- @return No return value
local function writeFileLocal ( obj, fhd, ... )
  local warningMessage = fileState ( fhd )
  if not warningMessage then
    fhd:write ( ... )
  else
    obj.myLogger:Log_Warning ( 'io:trying to read an ', fhd, ', but encountered an ', warningMessage, ' handler:', obj )
  end
end

--- tests if a file exists or not
-- @param obj the file handler object
-- @param fileName the file name
-- @see fileExists
-- @return true if file exists, false if it does not
local function fileExistsLocal ( obj, fileName )
  local fhd = openFileLocal ( fileName , 'r')
  if fhd then
    closeFileLocal ( obj, fhd )
    return true
  else
    return false
  end
end

-- copies a file
-- @param obj the file handler object
-- @param fromFile the file to copy from
-- @param toFile the file to copy to
-- @return returns true on success or false on error
local function copyFileLocal ( obj, fromFile, toFile )
  local result = false
  toFile = obj [ CONSTANTS.METHODS.FILENAMEBUILDER ] ( obj, toFile )
  fromFile = obj [ CONSTANTS.METHODS.FILENAMEBUILDER ] ( obj, fromFile )
  if fromFile and toFile then
    if fromFile ~= toFile then
      local fromFh = openFileLocal ( obj, fromFile )
      if fromFh then
        local toFh = openFileLocal ( obj, toFile, 'w' )
        if toFh then
          local data = fromFh:read( '*a' )
          toFh:write( data )
          closeFileLocal ( obj, toFh )
          obj.myLogger:Log_Info ( 'file succesfully copied handler:', obj )
          result = true
        end
        closeFileLocal ( obj, fromFh )
      end
    else
      obj.myLogger:Log_Warning ( 'can not copy file to itself handler:', obj )
    end
  else
    if not toFile then
      obj.myLogger:Log_Info ( 'no copy to file specified handler:', obj )
    else
      obj.myLogger:Log_Info ( 'no copy from and to file specified handler:', obj )
    end
  end

  return result
end

---copies the Resources to the DocumentsDirectory - system.DocumentsDirectory
-- @param obj the file handler object
-- @param overWrite forces an overwrite if the file exists
-- @param ... the files you want to copy
-- @return returns true on success or false on error
local function copyToDocumentsDirectory ( obj, overWrite, ... )
  local args = { ... }
  local x
  for x = 1, #args do
    local fileName = args [ x ]
    local copyFrom = { fileName = fileName, path = system.ResourceDirectory }
    local copyTo = { fileName = fileName, path = system.DocumentsDirectory }
    if overWrite or not fileExistsLocal ( copyTo ) then
      return copyFile ( obj, copyFrom, copyTo )
    end
  end
end

return classy:newClass(
              classy:attributes ( { defaultReadBehavour = Table ( Private ), myLogger = Logger ( Private ), logEntity = Table ( Private ) } ),
              classy:initMethod (
                   --- sets the default read behavour flags
                  -- @function initMethod
                  -- @param obj the calling object 
                  -- @param args optional arguments sent to create the file handler
                  -- @return No return value
                  -- @usage myFileHandler = FileHandler ()
                  function ( obj, args )
                    -- classy:default values will load all the args into the object and any that are not passed over but in the default values table will be defaulted.
                    classy:setDefaultValues ( obj, args, { defaultReadBehavour = { adjusted = nil, closeAfterRead = false }, myLogger = _G.myLogger } )
                    -- check to see if the class is registerd by the logger, if not register it so we get the Log_ functions created
                    -- we also only do this with the base class, any inherted classes will not be seen as modules as they are not loaded via require
                    obj.logEntity = classy:getBaseClass ( getmetatable ( obj ) )
                    if not obj.myLogger:registerState ( obj.logEntity ) then
                      obj.myLogger:registerModule ( obj.logEntity )
                    end
                  end       
                  ),       
              classy:addMethod ( CONSTANTS.METHODS.SETDEFAULTREADBEHAVOUR, 
                --- setDefaultReadBehavour can adjust the default corona behavour of one line at a time for a read, it can also force a file close at the end
                -- takes to paramters param1, param2, they are not manditory but if there one must be boolean the other a string
                -- the boolean sets the closeAfterRead and the string the adjusted file default read method.
                -- @function setDefaultReadBehavour
                -- @param obj the file hander object
                -- @param param1 the first parameter to check
                -- @param param2 the second parameter to check
                -- @return No return value
                -- @usage fileHandler:setDefaultReadBehavour ( param1 [, param 2 ] )
                function  ( obj, param1, param2 )
                  local param1Type, param2Type = type ( param1 ), type ( param2 )
                  if param1 or param2 then
                    if param1Type == _BOOLTYPE and ( param2Type == _STRINGTYPE or param2 == nil ) then
                      obj.defaultReadBehavour.closeAfterRead = param1
                      if param2 then
                        obj.defaultReadBehavour.adjusted = param2
                      end
                    elseif param1Type == _STRINGTYPE and ( param2Type == _BOOLTYPE or param2 == nil ) then
                      obj.defaultReadBehavour.adjusted = param1
                      if param2 then
                        obj.defaultReadBehavour.closeAfterRead = param2
                      end     
                    elseif param2Type == _BOOLTYPE and param1Type == _STRINGTYPE then
                      obj.defaultReadBehavour = { adjusted = param2, closeAfterRead = param1}
                    else
                      obj.myLogger:Log_Warning ( 'tried to adjust default read behavour with wrong parameters handler:', obj )
                    end
                  else
                    obj.myLogger:Log_Warning ( 'tried to adjust default read behavour with no parameters handler:', obj )
                  end   
                end 
                ),
              classy:addMethod ( CONSTANTS.METHODS.OPENFILE,
                --- opens a file
                -- @function openFile
                -- @see openFileLocal
                -- @param obj the file handler object
                -- @param fileDetails is an actual path or a table containing filename/path
                -- @param mode is the mode you want the file to open in, if not specified then this is the defaultReadBehavour "r"
                -- @return a file handler or nil
                -- @usage local fhd = fileHandler:openFile ( { fileName = fileName [, path = pathToFile ] } [, mode ])
                function ( obj, fileDetails, mode ) 
                  return openFileLocal ( obj, fileDetails, mode ) 
                end
                ),
                classy:addMethod ( CONSTANTS.METHODS.CLOSEFILE,
                --- closes a file
                -- @function closeFile
                -- @see closeFileLocal
                -- @param obj the file handler object
                -- @param fhd the file you wish to close
                -- @return true if success false if failed
                -- @usage local success = fileHandler:close ()
                function ( obj, fhd ) 
                  return closeFileLocal ( obj, fhd ) 
                end  
                ),
                classy:addMethod ( CONSTANTS.METHODS.READ,
                --- reads from a file
                -- @function readFrom
                -- @param obj the file handler object
                -- @param fhd the file you wish to read from
                -- @param ... optional mode settings
                -- @see readFileLocal
                -- @return readData if success nil if failed
                -- @usage local data = fileHandler:readFrom ( fileId [ , ... ] )
                function ( obj, fhd, ... )
                  return readFileLocal ( obj, fhd, ... )
                end
                ),
                classy:addMethod ( CONSTANTS.METHODS.WRITE,
                --- writes to a file
                -- @function writeTo
                -- @param obj the file handler object
                -- @param fhd the file you wish to write from
                -- @param ... optional data being writen
                -- @see writeFileLocal
                -- @return No return value
                -- @usage fileHandler:writeTo ( fileId [ , ... ] )
                function ( obj, fhd, ... )
                  return writeFileLocal ( obj, fhd, ... )
                end
                ),
                classy:addMethod ( CONSTANTS.METHODS.FILEEXISTS,
                --- tests if a file exists or not
                -- @function fileExists
                -- @param obj the file handler object
                -- @param fileName the file name
                -- @see fileExistsLocal
                -- @return true if file exists, false if it does not
                -- @usage local result = fileHandler:fileExists ( { fileName = fileName [, path = pathToFile ] } )
                function  ( obj, fileName )
                  return fileExistsLocal ( obj, fileName )
                end
                ),
                classy:addMethod ( CONSTANTS.METHODS.COPYFILE,
                --- copies a file
                -- @function copyFile
                -- @param obj the file handler object
                -- @param fromFile the file to copy from
                -- @param toFile the file to copy to
                -- @return returns true on success or false on error
                -- @usage local result = fileHandler:copyFile ( fromFileId, toFileId )                
                function  ( obj, fromFile, toFile )
                  return copyFileLocal ( obj, fromFile, toFile )
                end
                ),                
                classy:addMethod ( CONSTANTS.METHODS.FILEISEMPTY,
                --- tests to see if a file is empty
                -- @function fileIsEmpty
                -- @param obj the file handler object
                -- @param fileName the file name
                -- @return returns true if empty or false if file does not exist or is not empty
                -- @usage local result = fileHandler:fileIsEmpty ( { fileName = fileName [, path = pathToFile ] } )
                function  ( obj, fileName )
                  local fhd = openFileLocal ( fileName , 'r' )
                  if fhd then
                    if fhd:read ( '*a' ) == '' then
                      fhd:close ()
                      return true
                    end
                  end
                  return false
                end
                ),   
                classy:addPrivateMethod ( CONSTANTS.METHODS.FILENAMEBUILDER,
                --- builds file name if path table otherwise returns orgional value.
                -- You may have to overload this with your own method if not using Corona SDK
                -- @function fileNameBuilder
                -- @param obj the file handler object
                -- @param fileDetails either a path table or a fileName as a string
                -- @return a filename format for Corona SDK
                function  ( obj, fileDetails )
                  if type ( fileDetails ) == _TABLETYPE then
                    local fileName, path = fileDetails.fileName, fileDetails.path
                    if not path then path = system.TemporaryDirectory end
                    fileDetails = system.pathForFile ( fileName, path )
                  end
                  return fileDetails
                end
                ),
              classy:addNotes (filer._VERSION .. '\n\n' .. filer._DESCRIPTION .. '\n' .. filer._LICENSE, ... )
        )
