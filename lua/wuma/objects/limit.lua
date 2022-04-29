Limit = {}

local object = {}
local static = {}

Limit._id = "WUMA_Limit"
object._id = "WUMA_Limit"

function Limit:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}

	local obj = setmetatable({}, mt)

	obj.m._uniqueid = WUMA.GenerateUniqueID()

	obj.string = tbl.string or nil
	obj.limit = tbl.limit or 0
	obj.usergroup = tbl.usergroup or nil
	obj.exclusive = tbl.exclusive or nil

	obj._id = Limit._id

	obj.m.origin = tbl.origin or nil
	obj.m.parent = tbl.parent or nil
	if isstring(obj.m.parent) then obj.m.parentid = obj.m.parent elseif obj.m.parent then obj.m.parentid = obj.m.parent:SteamID() end
	obj.m.count = tbl.count or 0
	obj.m.entities = tbl.entities or {}
	obj.m.callonempty = tbl.callonempty or {}

	--No numeric adv. limits
	if (tonumber(obj.string) ~= nil) then obj.string = ":" .. obj.string .. ":" end

	--Make sure limit and string cannot be the same
	if (obj.limit == obj.string) then obj.limit = obj.limit .. ":" end

	--Parse limit
	if (tonumber(obj.limit) ~= nil) then obj.limit = tonumber(obj.limit) end

	if tbl.scope then obj:SetScope(tbl.scope) else obj.m.scope = "Permanent" end

	return obj
end

function static:GetID()
	return Limit._id
end

function static:GenerateID(usergroup, str)
	if usergroup then
		return string.format("%s_%s", usergroup, str)
	else
		return str
	end
end

function static:GenerateHit(str, ply)
	ply:SendLua(string.format([[
		 WUMA.NotifyLimitHit("%s")
	]], str))
end

function object:__tostring()
	return string.format("Limit [%s][%s/%s]", self:GetString(), tostring(self:GetCount()), tostring(self:Get()))
end

function object:__call(ply)

end

function object:__eq(that)
	if istable(that) and that._id and that._id == self._id then
		return (self:Get() == that:Get())
	elseif not (tonumber(that) == nil) then
		return (self:Get() == that)
	end
	return false
end

function object:__lt(that)
	if istable(that) and that._id and that._id == self._id then
		return (self:Get() < that:Get())
	elseif not (tonumber(that) == nil) then
		return (self:Get() < that)
	end
	return false
end

function object:__le(that)
	if istable(that) and that._id and that._id == self._id then
		return (self:Get() <= that:Get())
	elseif not (tonumber(that) == nil) then
		return (self:Get() <= that)
	end
	return false
end

function object:Clone()
	local copy = table.Copy(self)
	local origin

	if self.origin then
		origin = self.origin
	else
		origin = self
	end

	copy.origin = origin
	local obj = Limit:new(copy)

	return obj
end

function object:GetUniqueID()
	return self.m._uniqueid or false
end

function object:Delete()
	--So that no entities point here
	for id, entity in pairs(self.m.entities) do
		entity:RemoveWUMAParent(entity)
	end

	if self.scope then
		self.scope:Delete()
	end
end

function object:Shred()
	if self:IsPersonal() then
		WUMA.RemoveUserLimit(nil, self:GetParentID(), self:GetString())
	else
		WUMA.RemoveLimit(nil, self:GetUserGroup(), self:GetString())
	end
end

function object:IsPersonal()
	if self.usergroup then return nil else return true end
end

function object:GetBarebones()
	local tbl = {}
	for k, v in pairs(self) do
		if v or (v == 0) then
			tbl[k] = v
		end
	end
	return tbl
end

function object:CallOnEmpty(id, f)
	if SERVER then
		self.m.callonempty[id] = f
	end
end

function object:NotifyEmpty()
	if SERVER then
		for _, f in pairs(self.m.callonempty) do f(self) end
	end
end

function object:Get()
	if self.m.limit then return self.m.limit end
	return self.limit
end

function object:Set(c)
	self.limit = c
end

function object:GetID(short)
	if (not self:GetUserGroup()) or short then
		return self.string
	else
		return string.format("%s_%s", self:GetUserGroup(), self:GetString())
	end
end

function object:GetStatic()
	return Limit
end

function object:GetCount()
	return self.m.count
end

function object:SetCount(c)
	if (c < 0) then c = 0 end

	if self:GetParent() and IsValid(self:GetParent()) then
		self:GetParent():SetNWInt("Count." .. self:GetString(), c)
	end

	self.m.count = c
end

function object:GetParent()
	return self.m.parent
end

function object:SetParent(user)
	self.m.parent = user
	if isstring(self.m.parent) then self.m.parentid = self.m.parent elseif self.m.parent then self.m.parentid = self.m.parent:SteamID() end
end

function object:GetUserGroup()
	return self.usergroup
end

function object:GetOrigin()
	return self.m.origin
end

function object:GetString()
	return self.string
end

function object:SetString(str)
	self.string = str
end

function object:IsExclusive()
	return self.exclusive
end

function object:SetExclusive(bool)
	self.exclusive = str
end

function object:GetParentID()
	return self.m.parentid
end

function object:GetScope()
	return self.scope
end

function object:SetScope(scope)
	if not self:GetOrigin() then
		self.scope = scope
		if not scope.m then self.scope = Scope:new(scope) end

		self.scope:SetParent(self)

		self.scope:AllowThink()
	end
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

function object:SetAncestor(ancestor)
	self.m.ancestor = ancestor
end

function object:GetAncestor()
	return self.m.ancestor
end

function object:InheritEntities(limit)
	self.m.entities = limit.m.entities
	self:SetCount(limit:GetCount())

	for id, entity in pairs(self.m.entities) do
		entity:AddWUMAParent(self)
	end
end

function object:Check(int)
	if self:IsDisabled() then return end

	local limit = int or self:Get()

	if istable(limit) then
		if not limit:IsExclusive() then
			return limit:Check()
		else
			return self:Check(limit:Get())
		end
	elseif isstring(limit) and self:GetParent():HasLimit(limit) then
		return self:Check(self:GetParent():GetLimit(limit))
	elseif isstring(limit) then
		return
	end

	if (limit < 0) then return true end
	if (limit <= self:GetCount()) then
		self:Hit()
		return false
	end

	return true
end

function object:Hit()
	local str = self.print or self.string

	self:GetParent():SendLua(string.format([[
			notification.AddLegacy("You've hit the %s limit!", NOTIFY_ERROR, 3)
		]], str))
	self:GetParent():SendLua([[surface.PlaySound("buttons/button10.wav")]])
end

function object:DeleteEntity(id)
	self.m.entities[id] = nil
	self:Subtract()
end

function object:Subtract(c)
	c = tonumber(c) or 1
	self:SetCount(self:GetCount() - c)
	if (self:GetCount() == 0) then self:NotifyEmpty() end
end

function object:Add(entity)
	if (self.m.entities[entity:GetCreationID()]) then return end

	self:SetCount(self:GetCount() + 1)

	local limit = self:Get()
	if isstring(limit) and self:GetParent():HasLimit(limit) then
		self:GetParent():GetLimit(limit):Add(entity)
	end

	entity:AddWUMAParent(self)
	self.m.entities[entity:GetCreationID()] = entity
end

object.__index = object
static.__index = static

setmetatable(Limit, static)
