-- Another simple example of classy


local classy = require ('classy')
 
 
-- A base Animal class that contains the name and the voice
 
local Animal = classy:newClass( 
  classy:attributes  ( { name = String ( Public ), voice = String ( Public ) } ),
  classy:addMethod  ('speak',
      function ( obj, animal_type )
        print ( 'I am a ' .. animal_type .. ' breed ' .. ( obj.name or 'Unnamed') .. ',
                  and I say ' .. ( obj.voice or 'Silence') )
        end
   )
)
 
-- Dog inherits from Animal  
 
local Dog = classy:newClass( Animal,
  classy:addMethod  ('speak',
    function ( obj )
      classy:callSuperMethod ( obj, obj.super.speak, 'dog' )
    end
  )
)
 
-- Cat inherits from Animal  
 
local Cat = classy:newClass( Animal,
  classy:addMethod  ('speak',
    function ( obj )
      classy:callSuperMethod ( obj, obj.super.speak, 'cat' )
    end
  )
)
 
 
local rover = Dog ( { name = 'Rover', voice = 'woof' } )
local rufus = Dog ( { name = 'Rufus', voice = 'bark' } )
local pebbles = Cat ( { name = 'Pebbles', voice = 'meow' } )
 
 
rover:speak ()
rufus:speak ()
pebbles:speak ()
