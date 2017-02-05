
WUMA_NET_STREAM = {}

local object = {}
local static = {}

WUMA_NET_STREAM._id = "WUMA_NET_STREAM"
object._id = "WUMA_NET_STREAM"

/////////////////////////////////////////////////////////////////////////////////
function WUMA_NET_STREAM:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)
	
	obj.m._uniqueid = WUMA.GenerateUniqueID()

	obj.hooks = tbl.hooks or {}
	obj.auto_update = tbl.auto_update or false
	obj.send = tbl.send or false
	obj.server = tbl.server or false
	obj.client = tbl.client or false
	obj.auth = tbl.auth or false
	obj.id = tbl.id or false
	
	obj._id = WUMA_NET_STREAM._id
	
	return obj
end 

--																								Object functions
function object:__tostring()
	return string.format("NET STREAM [%s]",tostring(self:GetID()))
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
	return WUMA_NET_STREAM
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
		WUMAError("WARNING! A NET_STREAM OBJECT HAS NO AUTHORIZATION FUNCTION!!")
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

function object:SetAutoUpdate(auto_update)
	self.auto_update = auto_update
end

function object:AddInto(tbl)
	self.id = table.Count(tbl)+1
	tbl[table.Count(tbl)+1] = self
end

function object:Clone()
	local obj = WUMA_NET_STREAM:new(table.Copy(self))

	if self.origin then
		obj.m.origin = self.origin
	else
		obj.m.orign = self
	end

	return obj
end

function object:GetID()
	return self.id
end

function object:GetOrigin()
	return self.origin
end

object.__index = object
static.__index = static

setmetatable(WUMA_NET_STREAM,static) 