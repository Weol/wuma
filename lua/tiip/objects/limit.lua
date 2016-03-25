
Limit = {}

local object = {}
local static = {}

Limit._id = "TIIP_Limit"
object._id = "TIIP_Limit"

--																								Static functions
function Limit:new(tbl)
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)

	obj.string = tbl.string or false
	obj.limit = tbl.limit or false
	obj.parent = tbl.parent or false
	obj.usergroup = tbl.usergroup or false
	obj.scope = tbl.scope or false
	obj.count = tbl.count or 0
	
	--Parse limit
	if (tonumber(obj.limit) != nil) then obj.limit = tonumber(obj.limit) end
  
	return obj
end 
 
function static:GenerateID(str)
	return string.lower(str)
end

function static:GenerateHit(str,ply)
	ply:SendLua(string.format([[
			notification.AddLegacy("You've hit the %s limit!",NOTIFY_ERROR,3)
		]],str))
	ply:SendLua( [[surface.PlaySound( "buttons/button10.wav" )]] )
end

--																								Object functions
function object:__tostring()
	return string.format("Limit [%s][%s/%s]",self:GetString(),tostring(self:GetCount()),tostring(self:Get()))
end
 
function object:__call(ply)
	
end

function object:__eq(that)
	if istable(that) and that._id and that._id == self._id then
		return (self:Get() == that:Get())
	elseif not(tonumber(that) == nil) then
		return (self:Get() == that)
	end
	return false
end

function object:__lt(that)
	if istable(that) and that._id and that._id == self._id then
		return (self:Get() < that:Get())
	elseif not(tonumber(that) == nil) then
		return (self:Get() < that)
	end
	return false
end

function object:__le(that)
	if istable(that) and that._id and that._id == self._id then
		return (self:Get() <= that:GetLimit())
	elseif not(tonumber(that) == nil) then
		return (self:Get() <= that)
	end
	return false
end

function object:Clone()
	return Limit:new(self)
end

function object:Get()
	if self.m.limit then return self.m.limit end
	return self.limit 
end
 
function object:Set(c)
	self.limit = c
end

function object:GetID()
	return string.lower(self.string)
end

function object:GetCount()
	return self.count
end

function object:SetCount(c)
	self.count = c
end

function object:GetParent()
	return self.parent
end

function object:SetParent(user)
	self.parent = user
end


function object:GetString()
	return self.string
end

function object:SetString(str)
	self.string = str
end

function object:Check(int)
	local limit = int or self:Get()
	
	if istable(limit) then return self:Check(limit:Get()) end

	if (limit < 0) then return true end
	if (limit <= self.count) then
		self:Hit()
		return false
	end
	return true
end

function object:Hit()
	local str = self.print or self.string
	
	self.parent:SendLua(string.format([[
			notification.AddLegacy("You've hit the %s limit!",NOTIFY_ERROR,3)
		]],str))
	self.parent:SendLua( [[surface.PlaySound( "buttons/button10.wav" )]] )
end

function object:Subtract(c)
	c = tonumber(c) or 1
	self:SetCount(self:GetCount() - c)
end 

function object:Add(entity)
	self:SetCount(self:GetCount() + 1)
	entity.TIIPParent = self
	entity:CallOnRemove( "TIIPCountUpdate", function( ent ) ent.TIIPParent:Subtract(ent) end )
end

object.__index = object
static.__index = static

setmetatable(Limit,static) 