# Examples

## Logger
Example logger class

This creates a classy logger class. 

[Full Documentation for Logger](http://htmlpreview.github.com/?https://github.com/davporte/classy/blob/master/sample/doc/logger.html) can be found here.

[Example Use of Logger](https://github.com/davporte/classy/blob/master/sample/loggeruseexamples.lua) can be found here.

Usage:

``` Lua
local Logger = require ( 'logger' )
myLogger = Logger ()
```

The default log levels, and their default states are; 

| Name | Called using _G* | Called from module A | Called from Module B | Called Directly |
|------------------|--------------|---------|------------|----------|
|**Debug (off/fasle)** | Log_Debug ( ... ) | myLogger:Log_Debug ( ... ) | myLogger:Log_Debug_moduleName ( ... ) | myLogger:log ( 'Debug', ... ) |
|**Info (off/false)**| Log_Info ( ... ) | myLogger:Log_Info ( ... ) | myLogger:Log_Info_moduleName ( ... ) | myLogger:log ( 'Debug', ... ) |
|**Warning (on/true)** | Log_Warning ( ... ) | myLogger:Log_Warning ( ... ) | myLogger:Log_Warning_moduleName ( moduleName, ... ) | myLogger:log ( 'Warning', ... ) |
|**Error (on/true)**| Log_Error ( ... ) | myLogger:Log__Error ( ... ) | myLogger:Log_Error_moduleName ( ... ) | myLogger:log ( 'Error', ... ) |

\* \- Log_XXX -> calls log directly, Log_XXX_moduleName -> calls Log_XXX first

## Stack
Example stack class. This example also shows logger being passed as a parameter. It also demonstates the overloading of the + operator.

[Full Documentation for Stack](http://htmlpreview.github.com/?https://github.com/davporte/classy/blob/master/sample/doc/stack.html)

Usage:

``` Lua
Logger = require ( 'sample.logger' )
_G.myLogger = Logger () -- stack objects looks for _G.myLogger as their default logger
myLogger:setLogState ( true )
Stack = require ( 'sample.stack' )

-- empty stack
myStack = Stack ()

-- prepopulated stack
mySecondStack = Stack ( { stack = { 'cat', 'dog', 'bird'}  } )
-- gives myThirdStack another instance of myLogger and prepopulates
-- note that module logging and _G logging rules are attached to the _G.myLogger, the first logger created
myThirdStack = Stack ( { stack = { 'fish', 'shark' }, myLogger = Logger () } ) 
-- creates a fourth stack that contains mySecondStack followed by myThirdStack - Also drains mySecondStack, myThirdStack
-- it also adds 'monster' into the stack
myFourthStack =  mySecondStack + myThirdStack  + 'monster'
```
## FileHandler
Example file handler class. Also demonstrates use of calling a super init method. The usage example also demonstrates overloading a method in the base class.

[Full Documentation for FileHandler](http://htmlpreview.github.com/?https://github.com/davporte/classy/blob/master/sample/doc/fileHandler.html)

``` Lua
Logger = require ('sample.logger')

-- this is the default logger
_G.myLogger = Logger ()

-- load up the default file handler
FileHandler = require ( 'sample.FileHandler' )

NewFileHandler = classy:newClass( FileHandler,
         classy:initMethod (
          -- example call of the super init method to construct this object
          function ( obj, args )
            classy:callSuperMethod ( obj, obj.super.init, args )
          end       
          ),       
          -- example overloading of a method in the origional class
         classy:addPrivateMethod ( 'fileNameBuilder',
            function  ( obj, fileDetails )
              if type ( fileDetails ) == 'table' then
                local fileName, path = fileDetails.fileName, fileDetails.path
                if not path then path = system.TemporaryDirectory end
                fileDetails = system.pathForFile ( fileName, path )
              end
              return fileDetails
         end
         )
       )
```
