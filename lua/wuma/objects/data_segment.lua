
WUMA_DATASEGMENT = {}

local object = {}
local static = {}

WUMA_DATASEGMENT._id = "WUMA_DATA_SEGMENT"

--																								Static functions
function WUMA_DATASEGMENT:new(tbl)
	local obj = setmetatable({},object)

	obj.ui = tbl.ui or false
	obj.ui_update 
	obj.data = tbl.data or false
  
	return obj
end 

function static:__eq(v1, v2)
	if v1._id and v2._id then 
		return (v1._id == v2.__id) 
	else 
		return false
	end
end

--																								Object functions
function object:__call(type,str)

end

function object:__eq(obj1,obj2)

end

function object:__tostring()
	return string.format("%s [%s]",self._id,)
end

function object:Clone()
	return WUMA_DATASEGMENT:new(self)
end

function object:UpdateData(data)
	self.data = data
	self:UpdateUI(data)
end

function object:UpdateUI(data)
	self.ui_update(data)
end

object.__index = object
static.__index = static

setmetatable(WUMA_DATASEGMENT,static)

