
Scope = {}

local object = {}
local static = {}

Scope._id = "TIIP_Scope"

--																								Static functions
function Scope:new(tbl)
	local obj = setmetatable({},object)

  
	return obj
end 

function static:__eq(v1, v2)
	if v1._id and v2._id then return (v1._id == v2.__id) end
end

--																								Object functions
function object:__call(type,str)

end

function object:__eq(obj1,obj2)

end

function object:__tostring()

end

function object:Clone()
	
end

object.__index = object
static.__index = static

setmetatable(Scope,static)

