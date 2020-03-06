-- Another simple example of classy

-- as this file is one diretory below wher eclassy is stored add classy to path
package.path = package.path .. ";../classy.lua"

local classy = require ('classy')
 
-- A base Animal class that contains the name and the voice
 
 
local Animal = classy:newClass( 
  classy:attributes  ( { name = String ( Public ), voice = String ( Public ) } ),
  classy:addMethod  ('speak',
      function ( obj, animal_type )
        print ( 'I am a ' .. animal_type .. ' breed ' .. ( obj.name or 'Unnamed') .. ', and I say ' .. ( obj.voice or 'Silence') )
        end
   )
)
 
-- Dog inherits from Animal  
-- note this has to be declared this was as Dog calls a super method, we need to know the value of Dog 
local Dog 
Dog = classy:newClass( Animal,
  classy:addMethod  ('speak',
    function ( obj )
      Dog:callSuperMethod ( obj, 'speak', 'Dog' )
    end
  )
)
 
-- Cat inherits from Animal  
-- note this has to be declared this was as Cat calls a super method, we need to know the value of Dog  
local Cat 
Cat = classy:newClass( Animal,
  classy:addMethod  ('speak',
    function ( obj )
      Cat:callSuperMethod ( obj, 'speak', 'Cat' )
    end
  )
)
 
 
local rover = Dog ( { name = 'Rover', voice = 'woof' } )
local rufus = Dog ( { name = 'Rufus', voice = 'bark' } )
local pebbles = Cat ( { name = 'Pebbles', voice = 'meow' } )
 
 
rover:speak ()
rufus:speak ()
pebbles:speak ()
