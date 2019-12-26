-- Example Use of logger

Logger = require ( 'logger' )

myLogger = Logger ()

-- an empty message
Log_Error (  )
-- an error message
Log_Error ( 'this is a message 1' )
-- nothing now as Info off by default
Log_Info ( 'this is a message 2' )
-- true turns on one state Info
myLogger:setLogState ( true, 'Info' )
Log_Info ( 'this time it did 3' )
-- false turns off all levels
myLogger:setLogState ( false )
Log_Error ( 'no message appears 4' )
Log_Warning ( 'no message appears 5' )
Log_Info ( 'no message appears 6' )
Log_Debug ( 'no message appears 7' )
-- true turns on all levels
myLogger:setLogState ( true )
Log_Error ( 'message appears 8' )
Log_Warning ( 'message appears 9' )
Log_Info ( 'message appears 10' )
Log_Debug ( 'message appears 11' )
-- we can be module specific too, if we register the module
myLogger:registerModule ( Logger )
myLogger.Log_Info ('specific to module 12')
-- we can also use the module name
myLogger:registerModule ( 'classy' )
classy.Log_Info ( 'specific to classy 14' )
-- we can set a personal logger if we want
myLogger:setMyOutput ( 
			function ( text )
				print ('look its me:' , text )
			end
	)
myLogger.Log_Info ('specific to module 15')
classy.Log_Info ( 'specific to classy 16' )
-- we can also send this data to the orgional logger
myLogger:setMyOutput (
			function ( text )
				print ( 'im going first:', text ) 
			end,
			true
	)
myLogger.Log_Info ('specific to module 17')
classy.Log_Info ( 'specific to classy 18' )
-- and back to normal
myLogger:setMyOutput ()
myLogger.Log_Info ('specific to module 19')
classy.Log_Info ( 'specific to classy 20' )
-- add a new logLevel
print ( myLogger:addLogLevel ( 'Gibbon' ) )
Log_Gibbon ( 'hi' )
myLogger.Log_Gibbon ('specific to module 22')
classy.Log_Gibbon ( 'specific to classy 23' )
-- add a new logLevel off by default
print ( myLogger:addLogLevel ( 'Monkey', false ) )
Log_Monkey ( 'hi' )
myLogger.Log_Monkey ('specific to module 24')
classy.Log_Monkey ( 'specific to classy 25' )
-- so turn it on
myLogger:setLogState ( true, 'Monkey' )
Log_Monkey ( 'hi' )
-- note as it was false when added registered modules ned to be told as well
myLogger.Log_Monkey ('specific to module 26')
classy.Log_Monkey ( 'specific to classy 27' )
myLogger:setModuleLogState ( classy, true, 'Monkey' )
myLogger:setModuleLogState ( 'logger', true, 'Monkey' )
myLogger.Log_Monkey ('specific to module 28')
classy.Log_Monkey ( 'specific to classy 29' )
-- alternative ways to call
myLogger:logFromModule ( classy, 'Monkey', 30, ' ', 1, 3, 4 )
myLogger:logFromModule ( '_G', 'Monkey', 31, ' ', 3, 4 )
---

