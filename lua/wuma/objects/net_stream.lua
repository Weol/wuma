
WUMA_NET_STREAM = {}

local object = {}
local static = {}

WUMA_NET_STREAM._id = "WUMA_NET_STREAM"
object._id = "WUMA_NET_STREAM"

--																								Static functions
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
	if not self.send or not self.server then return WUMADebug("NET_STREAM Object has no server or send function! (ID: %s)",self:GetID()) end
	local arguments = self.server(user,data)
	if arguments then
		self.send(unpack(arguments))
	end
end

function object:AutoUpdate(...)
	local args = {...}
	
	if not isentity(args[1]) then return WUMADebug("NET_STREAM Auto Update does not have user argument! (ENUM: %s)",tostring(self:GetID())) end
	
	if self.auto_update and self.send then
		for _, user in pairs(player.GetAll()) do
			if self:IsAuthorized(user) then
				self.send(self.server(...))
			end
		end 
	end
end 

function object:IsAuthorized(user)
	if not self.auth then 
		WUMAError("WARNING! A NET_STREAM OBJECT HAS NO AUTHORIZATION FUNCTION! THIS CAN CAUSE FATAL SECURITY ISSUES!")
		return false 
	else
		return self.auth(user)
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

function object:AddHook(...)
	local h = {...}
	if (table.Count(h) < 2) then
		h = h[1]
	else
		for _, v in pairs(h) do
			self:AddHook(v)
		end
		return
	end
	
	self.hooks = self.hooks or {}
	hook.Add( "WUMANETSTREAMHook"..table.Count(self.hooks) , self.AutoUpdate )
	table.insert(self.hooks, h)
end

function object:SetUpdateTimer(time)
	if (timer.Exists("WUMANETSTREAMObjectTimer"..self:GetUniqueID())) then
		timer.Adjust( "WUMANETSTREAMObjectTimer"..self:GetUniqueID(), time, 0, self.AutoUpdate )
	else
		timer.Create( "WUMANETSTREAMObjectTimer"..self:GetUniqueID(), time, 0, self.AutoUpdate )
	end
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