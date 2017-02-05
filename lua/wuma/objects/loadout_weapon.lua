
Loadout_Weapon = {}

local object = {}
local static = {}

Loadout_Weapon._id = "WUMA_Loadout_Weapon"
object._id = "WUMA_Loadout_Weapon"

/////////////////////////////////////////////////////////////////////////////////
function Loadout_Weapon:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)
	
	obj.m._uniqueid = WUMA.GenerateUniqueID()
	
	obj.m.parent = tbl.parent or false
	obj.class = tbl.class or false
	obj.primary = tbl.primary or 0
	obj.secondary = tbl.secondary or 0
	obj.respect_restrictions = tbl.respect_restrictions or false
	
	if tbl.scope then obj:SetScope(tbl.scope) else obj.m.scope = "Permenant" end
	
	obj.m._id = Loadout_Weapon._id

	return obj
end 

function static:GetID()
	return Loadout_Weapon._id
end

--																					Object functions
function object:__tostring()
	return string.format("Loadout_Weapon [%s]",self.class)
end

function object:__eq(v1,v2)
	if v1._id and v2._id then return (v1._id == v2._id) end
	return false
end

function object:Clone()
	local obj = Loadout_Weapon:new(table.Copy(self))

	if self.origin then
		obj.m.origin = self.origin
	else
		obj.m.orign = self
	end

	return obj
end

function object:Delete()
	self = nil
end

function object:GetBarebones()
	local tbl = {}
	for k,v in pairs(self) do
		if v then
			tbl[k] = v
		end
	end
	return tbl
end

function object:GetUniqueID()
	return obj.m._uniqueid or false
end

function object:GetID()
	return string.lower(string.format("loadout_weapon_%s",self.class))
end

function object:GetStatic()
	return Loadout_Weapon
end

function object:SetClass(parent)
	self.class = class
end

function object:GetClass()
	return self.class
end

function object:SetPrimaryAmmo(num)
	self.primary = num
end

function object:GetPrimaryAmmo()
	return self.primary
end

function object:SetSecondaryAmmo(num)
	self.secondary = num
end

function object:GetSecondaryAmmo()
	return self.secondary
end

function object:GetParent()
	return self.m.parent
end

function object:SetParent(parent)
	self.m.parent = parent
end

function object:GetOrigin()
	return self.origin
end

function object:SetScope(scope)	
	if not (scope.m) then
		self.scope = Scope:new(scope)
	else
		self.scope = scope
	end
	
	self.scope:SetParent(self)
	
	self.scope:AllowThink()
end

function object:Disable()
	self.m.disabled = true
end

function object:Enable()
	self.m.disabled = false
end

function object:Shred()
	PrintTable(self:GetParent())
	if (self:GetParent():IsPersonal()) then
		WUMA.RemoveUserLoadoutWeapon(_,self:GetParent():GetParentID(),self:GetClass())
	else
		WUMA.RemoveLoadoutWeapon(_,self:GetParent():GetUserGroup(),self:GetClass())
	end
end

function object:IsDisabled() 
	if self.m and self.m.disabled then return true end
	return false
end

function object:SetRespectRestrictions(boolean)
	self.respect_restrictions = boolean
end

function object:DoesRespectRestriction()
	return self.respect_restrictions
end

object.__index = object
static.__index = static

setmetatable(Loadout_Weapon,static) 

