
local object = {}
local static = {}

object._id = "UserObject"
static._id = "UserObject"

/////////////////////////////////////////////////////////
/////       		 Object functions				/////
/////////////////////////////////////////////////////////


function object:GetOrigin()
	return self.origin
end

UserObject = WUMAObject:Inherit(static, object)