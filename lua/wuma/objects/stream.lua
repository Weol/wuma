
WUMAStream = {}

local object = {}
local static = {}

WUMAStream._id = "WUMAStream"
object._id = "WUMAStream"

function WUMAStream:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({}, mt)
	
	obj.m._uniqueid = WUMA.GenerateUniqueID()

	obj.name = tbl.name or false
	obj.send = tbl.send or false
	obj.server = tbl.server or false
	obj.client = tbl.client or false
	obj.auth = tbl.auth or false
	obj.id = tbl.id or false
	
	obj._id = WUMAStream._id
	
	return obj
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

function object:GetStatic()
	return WUMAStream
end

function object:Send(user, data)
	if not self.server then return false end
	local arguments = self.server(user, data)
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

function object:GetUniqueID()
	return obj.m._uniqueid or false
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

function object:Clone()
	local obj = WUMAStream:new(table.Copy(self))

	if self.origin then
		obj.m.origin = self.origin
	else
		obj.m.origin = self
	end

	return obj
end

function object:SetName(name)
	self.name = name
end

function object:GetName()
	return self.name
end

function object:GetOrigin()
	return self.origin
end

object.__index = object
static.__index = static

setmetatable(WUMAStream, static) 