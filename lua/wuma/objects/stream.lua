
local object = {}
local static = {}

object._id = "WUMAStream"
static._id = "WUMAStream"

/////////////////////////////////////////////////////////
/////       		 Static functions				/////
/////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////
/////       		 Object functions				/////
/////////////////////////////////////////////////////////
function object:Construct(tbl)
	self.name = tbl.name or false
	self.send = tbl.send or false
	self.server = tbl.server or false
	self.client = tbl.client or false
	self.auth = tbl.auth or false
	self.id = tbl.id or false
end 

function object:__tostring()
	return self.name
end
 
function object:__call(...)
	if SERVER then
		return self.server({...})
	else
		return self.client({...})
	end
end

function object:__eq(that)
	if istable(that) and that._id and that._id == self._id then
		return (self:Get() == that:Get())
	elseif not(tonumber(that) == nil) then
		return (self:Get() == that)
	end
	return false
end

function object:Send(user,data)
	if not self.server then return false end
	local arguments = self.server(user,data)
	if not self.send then return false end
	if arguments then
		self.send(unpack(arguments))
	end
end

function object:IsAuthorized(user, callback)
	if not self.auth then 
		WUMAError("FATAL SECURITY RISK! A NET_STREAM OBJECT HAS NO AUTHORIZATION FUNCTION!")
		callback(false)
	else
		self.auth(user, callback)
	end
end

function object:SetServerFunction(func)
	self.server = func
end

function object:SetClientFunction(func)
	self.client = func
end

function object:SetAuthenticationFunction(func)
	self.auth = func
end

function object:SetName(name)
	self.name = name
end

function object:GetName()
	return self.name
end

WUMAStream = WUMAObject:Inherit(static, object)