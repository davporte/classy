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

| Name | Called using _G* | Called from module | Called Directly |
|------------------|--------------|---------|----------|
|**Debug (off/fasle)** | Log_Debug ( ... ) | module.Log_Debug ( ... ) | myLogger:log ( 'Debug', ... ) |
|**Info (off/false)**| Log_Info ( ... ) | module.Log_Info ( ... ) | myLogger:log ( 'Info', ... ) |
|**Warning (on/true)** | Log_Warning ( ... ) | module.Log_Warning ( ... ) | myLogger:log ( 'Warning', ... ) |
|**Error (on/true)**| Log_Error ( ... ) | module.Log__Error ( ... ) | myLogger:log ( 'Error', ... ) |

\* \- This can be slow

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
