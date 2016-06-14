
WUMA_NET_STREAM = {}

local object = {}
local static = {}

WUMA_NET_STREAM._id = "WUMA_NET_STREAM"
object._id = "WUMA_NET_STREAM"

static.id_counter = 1

--																								Static functions
function WUMA_NET_STREAM:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)

	obj.send = tbl.send or false
	obj.server = tbl.server or false
	obj.client = tbl.client or false
	obj.auth = tbl.auth or false
	
	obj.id = WUMA_NET_STREAM:GenerateID()
	
	return obj
end 

function static:GenerateID()
	local id = self.id_counter
	self.id_counter = self.id_counter + 1
	return id
end

--																								Object functions
function object:__tostring()
	return string.format("NET STREAM [%s]",tostring(self:GetID()))
end
 
function object:__call(user,data)
	if SERVER then
		send(user,self.server(data),self:GetID())
	else
		self.client(data)
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

function object:IsAuthorized(user)
	if not self.auth then 
		WUMAError("WARNING! A NET_STREAM OBJECT HAS NO AUTHORIZATION FUNCTION! THIS CAN CAUSE FATAL SECURITY ISSUES!")
		return false 
	else
		return self.auth(user)
	end
end

function object:SetServerFunction(func)
	self.sever = func
end

function object:SetClientFunction(func)
	self.client = func
end

function object:SetAuthenticationFunction(func)
	self.auth = func
end

function object:AddInto(tbl)
	tbl[self:GetID()] = self
end

function object:Clone()
	return WUMA_NET_STREAM:new(self)
end

function object:GetID()
	return self.id
end

object.__index = object
static.__index = static

setmetatable(WUMA_NET_STREAM,static) 