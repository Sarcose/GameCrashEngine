local mesh = require 'test.jsfproto.mesh'
local s = {}
function s:add(...)
    local args = {...}
    for _,obj in ipairs(args) do
        print('adding',tostring(_),tostring(obj))
        obj.cat = "wire"
        gcore.container.assignType(obj,"Mesh",obj.name)
        self[obj.name] = obj
        table.insert(self,obj)
        _c_debug(obj)
    end
end


--here we can see, that draws.lua or d:addShape() should actually be something more like
--d:addObject() and then we have
--a mesh component
--a text component -- problem! how do we render THIS Y-depth rotation!? We might need to do some weird mesh baking or batching?
_c_todo{"05/08/2025","common bodyparts in text should just be objects that are rendered according to shared logic, and referenced, perhaps with scaling or fonts and offsets for differentiation."}
s:add(
    {
        name = "jsfjumper",
        parts = {
            mesh = {
                {"body","rectangle",w=5,h=10},
                {"left_weg","triangle",1,x=3},
                {"right_weg","triangle",1,x=6},
            },
            text = {
                {"eye",{"o","x","?","0"},x="center",y=3},  --later, adding an animation option
                {"mouth",{"━━","o","┎━","-",".","_","<","━",x="center",y=6}}
            }  
        }
    },
    {
        name = "b0cks",
        parts = {
            mesh = {
                {"body","rectangle",w=10,h=10}
            },
            text = {
                {"eyes",}
            }
        }
    },
    {
        name = "trit33",
        parts = {
            mesh = {

            },
            text = {

            }
        }
    },
    {
        name = "virach",
        parts = {
            mesh = {

            },
            text = {

            }
        }
    }
)



return s