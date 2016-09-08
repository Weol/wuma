
Limit = {}

local object = {}
local static = {}

Limit._id = "WUMA_Limit"
object._id = "WUMA_Limit"

--																								Static functions
function Limit:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)

	obj.m._uniqueid = WUMA.GenerateUniqueID()
	
	obj.string = tbl.string or false
	obj.limit = tbl.limit or 0
	obj.parent = tbl.parent or false
	obj.usergroup = tbl.usergroup or false
	obj.count = tbl.count or 0
	
	if tbl.scope then obj:SetScope(tbl.scope) else obj.m.scope = "Normal" end
	
	obj._id = Limit._id
	
	obj.m.override = tbl.overrive or false
	
	--Parse limit
	if (tonumber(obj.limit) != nil) then obj.limit = tonumber(obj.limit) end
  
	return obj
end 
 
function static:GetID()
	return Limit._id
end
 
function static:GenerateID(usergroup,str)
	return string.lower(string.format("%s%s",usergroup.."_",str))
end

function static:GenerateHit(str,ply)
	ply:SendLua(string.format([[
			notification.AddLegacy("You've hit the %s limit!",NOTIFY_ERROR,3)
		]],str))
	ply:SendLua([[surface.PlaySound("buttons/button10.wav")]])
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
	local obj = Limit:new(table.Copy(self))

	if self.origin then
		obj.m.origin = self.origin
	else
		obj.m.orign = self
	end

	return obj
end

function object:GetUniqueID()
	return obj.m._uniqueid or false
end

function object:Delete()
	if self:GetParent() then
		self:GetParent():RemoveLimit(self:GetID(),self:IsPersonal()) 
	end
	
	self = nil
end

function object:IsPersonal()
	if self.usergroup then return false else return true end
end
	
function object:GetBarebones()
	local tbl = {}
	for k,v in pairs(self) do
		if v or (v == 0) then
			tbl[k] = v
		end
	end
	return tbl
end
	
function object:Get()
	if self.m.limit then return self.m.limit end
	return self.limit 
end
 
function object:Set(c)
	self.limit = c
end

function object:GetID()
	return string.lower(string.format("%s%s",self.usergroup.."_",self.string))
end

function object:GetStatic()
	return Limit
end

function object:SetOverride(limit)
	self:RemoveOverride(limit)
	self.override = limit
end

function object:GetOverride()
	return self.override 
end

function object:RemoveOverride()
	self.override = nil
end

function object:GetCount()
	return self.count
end

function object:SetCount(c)
	if (c < 0) then c = 0 end
	self.count = c
end

function object:GetParent()
	return self.parent
end

function object:SetParent(user)
	self.parent = user
end

function object:GetUsegroup()
	return self.usergroup
end

function object:GetOrigin()
	return self.origin
end

function object:GetString()
	return self.string
end

function object:SetString(str)
	self.string = str
end

function object:GetScope()
	return self.scope
end

function object:SetScope(scope)	
	if (scope.m) then
		self.scope = scope
	else
		self.scope = Scope:new(scope)
	end
	
	self:GetScope():SetParent(self)
	
	self:GetScope():AllowThink()
end

function object:DeleteScope()
	self.scope:Delete()
	self.scope = nil
end

function object:Disable()
	self.m.disabled = true
end

function object:Enable()
	self.m.disabled = false
end

function object:IsDisabled() 
	if self.m and self.m.disabled then return true end
	return false
end

function object:Check(int)
	if self.override then 
		return self:GetOverride():Check(int)
	else
		local limit = int or self:Get()
		
		if istable(limit) then return self:Check(limit:Get()) end

		if (limit < 0) then return end
		if (limit <= self.count) then
			self:Hit()
			return false
		end
	end
	return true
end

function object:Hit()
	if self:GetOverride() then self:GetOverride():Hit(); return end
	local str = self.print or self.string
	
	self.parent:SendLua(string.format([[
			notification.AddLegacy("You've hit the %s limit!",NOTIFY_ERROR,3)
		]],str))
	self.parent:SendLua([[surface.PlaySound("buttons/button10.wav")]])
end

function object:Subtract(c)
	c = tonumber(c) or 1
	self:SetCount(self:GetCount() - c)
end 

function object:Add(entity)
	self:SetCount(self:GetCount() + 1)
	if self:GetOverride() then self:GetOverride():SetCount(self:GetOverride():GetCount() + 1) end
	
	entity:AddWUMAParent(self) 
	if self:GetOverride() then entity:AddWUMAParent(self:GetOverride()) end
end

object.__index = object
static.__index = static

setmetatable(Limit,static) 