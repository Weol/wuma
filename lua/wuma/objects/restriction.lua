
Restriction = {}

local object = {}
local static = {}

Restriction._id = "WUMA_Restriction"
object._id = "WUMA_Restriction"

Restriction.types = {
	entity = {print="Entity", print2="Entities", search="Search..", items=function() return WUMA.GetEntities() end},
	prop = {print="Prop", print2="Props", search="Model"},
	npc = {print="NPC", print2="NPCs", search="Search..", items=function() return WUMA.GetNPCs() end},
	vehicle = {print="Vehicle", print2="Vehicles", search="Search..", items=function() return WUMA.GetVehicles() end},
	swep = {print="Weapon", print2="Weapons", search="Search..", items=function() return WUMA.GetWeapons() end},
	pickup = {print="Pickup", print2="Pickups", search="Search..", items=function() return WUMA.GetWeapons() end},
	effect = {print="Effect", print2="Effects", search="Model"},
	tool = {print="Tool", print2="Tools", search="Search..", items=function() return WUMA.GetTools() end},
	ragdoll = {print="Ragdoll", print2="Ragdolls", search="Model"},
	property = {print="Property", print2="Properties", search="Property"},
	use = {print="Use", print2="Uses", search="Search..", items=function()
		local tbl = {}
		table.Add(table.Add(table.Add(tbl, WUMA.GetEntities()), WUMA.GetVehicles()), WUMA.GetNPCs())
		return tbl
	end}
}

function Restriction:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}

	local obj = setmetatable({}, mt)

	obj.m._uniqueid = WUMA.GenerateUniqueID()

	obj.usergroup = tbl.usergroup or nil
	obj.type = tbl.type or nil
	obj.string = tbl.string or nil
	obj.print = tbl.print or tbl.string
	obj.allow = tbl.allow or nil

	obj.m._id = Restriction._id

	obj.m.origin = tbl.origin or nil
	obj.m.parent = tbl.parent or nil
	if isstring(obj.m.parent) then obj.m.parentid = obj.m.parent elseif obj.m.parent then obj.m.parentid = obj.m.parent:SteamID() end
	obj.m.exceptions = {}

	if tbl.scope then obj:SetScope(tbl.scope) else obj.m.scope = "Permanent" end

	return obj
end

function Restriction:GenerateID(type, usergroup, str)
	if usergroup then
		if str then
			return type.."_"..usergroup.."_"..str
		else
			return type.."_"..usergroup
		end
	else
		if str then
			return type.."_"..str
		else
			return type
		end
	end
end

function static:GetID()
	return Restriction._id
end

function static:GetTypes(field)
	if field then
		local tbl = {}

		for _, type in pairs(Restriction.types) do
			for key, value in pairs(type) do
				if (key == field) then
					table.insert(tbl, value)
				end
			end
		end

		return tbl
	end

	return Restriction.types
end

function static:GetAllResitrictableItems()
	local tbl = {}

	for k, v in pairs(self:GetTypes()) do
		if v.items then
			table.Add(tbl, v.items())
		end
	end

end

function object:__eq(v1, v2)
	return ((v1.usergroup == v2.usergroup) and (v1.type == v2.type) and (v1.string == v2.string) and (v1.allow == v2.allow))
end

function object:__call(type, str)

	if self:IsDisabled() then return end

	if (self:HasException(str)) then
		self:RemoveException(str)
		return
	end

	if not self.allow then
		self:Hit()
		return false
	end
end

function object:__tostring()
	return string.format("Restriction [%s][%s]", self:GetType(), self:GetString())
end

function object:GetStatic()
	return Restriction
end

function object:Delete()
	if self.scope then
		self.scope:Delete()
	end
end

function object:Shred()
	if self:IsPersonal() then
		WUMA.RemoveUserRestriction(_, self:GetParentID(), self:GetType(), self:GetString())
	else
		WUMA.RemoveRestriction(_, self:GetUserGroup(), self:GetType(), self:GetString())
	end
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

function object:Hit()
	if (self.type == "pickup") then return end

	if (self.type == "use") then
		if self.m.lasthit and not (os.time() - self.m.lasthit > 1) then self.m.lasthit = os.time(); return end
	end

	self.m.lasthit = os.time()

	local str = self.print or self.string

	if not IsValid(self:GetParent()) then return end
	if (self:IsGeneral()) then
		str = Restriction:GetTypes()[self:GetType()].print2

		self:GetParent():SendLua(string.format([[
			WUMA.NotifyTypeRestriction("%s")
		]], str))
	else
		self:GetParent():SendLua(string.format([[
			WUMA.NotifyRestriction("%s", "%s")
		]], Restriction:GetTypes()[self:GetType()].print, str))
	end
	self:GetParent():SendLua([[surface.PlaySound("buttons/button10.wav")]])
end

function object:GetUniqueID()
	return self.m._uniqueid or false
end

function object:IsPersonal()
	if self.usergroup then return nil else return true end
end

function object:IsGeneral()
	if self.string then return nil else return true end
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
	local obj = Restriction:new(copy)

	return obj
end
function object:GetBarebones()
	local tbl = {}
	for k, v in pairs(self) do
		if v then
			tbl[k] = v
		end
	end
	return tbl
end

function object:AddException(str)
	self.m.exceptions[str] = true
end

function object:RemoveException(str)
	self.m.exceptions[str] = nil
end

function object:HasException(str)
	if self.m.exceptions[str] then return true end
	return false
end

function object:GetUserGroup()
	return self.usergroup
end

function object:SetUsergroup(str)
	self.usergroup = str
end

function object:GetType()
	return self.type
end

function object:SetType(str)
	self.type = str
end

function object:GetPrint()
	return self.print
end

function object:SetPrint(str)
	self.print = str
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

function object:GetString()
	return self.string
end

function object:SetString(string)
	self.string = string
end

function object:SetParent(ply)
	self.m.parent = ply
	if isstring(self.m.parent) then self.m.parentid = self.m.parent elseif self.m.parent then self.m.parentid = self.m.parent:SteamID() end
end

function object:GetParent()
	return self.m.parent
end

function object:GetParentID()
	return self.m.parentid
end

function object:GetOrigin()
	return self.m.origin
end

function object:SetAncestor(ancestor)
	self.m.ancestor = ancestor
end

function object:GetAncestor()
	return self.m.ancestor
end

function object:SetAllow(boolean)
	self.allow = boolean
end

function object:GetAllow()
	return self.allow
end

function object:GetID(short)
	if (not self:GetUserGroup()) or short then
		if self:GetString() then
			return string.format("%s_%s", self.type, self.string)
		else
			return self.type
		end
	else
		if self:GetString() then
			return string.format("%s_%s_%s", self.type, self.usergroup, self.string)
		else
			return string.format("%s_%s", self.type, self.usergroup)
		end
	end
end

object.__index = object
static.__index = static

setmetatable(Restriction, static)
