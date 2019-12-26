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

* - This can be slow
