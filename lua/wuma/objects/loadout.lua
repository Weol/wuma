
Loadout = {}

local object = {}
local static = {}

Loadout._id = "WUMA_Loadout"
object._id = "WUMA_Loadout"

--																								Static functions
function Loadout:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)
	
	obj.m._uniqueid = WUMA.GenerateUniqueID()
	
	obj.parent = tbl.parent or false
	obj.usergroup = tbl.usergroup or false
	obj.primary = tbl.primary or false
	obj.weapons = tbl.weapons or {}
	obj.inherit = tbl.inherit or false
	obj.remove_ammo = tbl.remove_ammo or true
	obj.respect_restrictions = tbl.respect_restrictions or false
	
	if tbl.scope then obj:SetScope(tbl.scope) else obj.m.scope = "Normal" end
	
	obj._id = Loadout._id
	
	obj.m.ancestor = tbl.ancestor or false
	obj.m.child = tbl.child or false

	return obj
end 

function static:GetID()
	return Loadout._id
end

--																					Object functions
function object:__tostring()
	return string.format("Loadout [%s]",self.parent or self.usergroup)
end

function object:__eq(v1,v2)
	if v1._id and v2._id then return (v1._id == v2._id) end
	return false
end

function object:Clone()
	local obj = Loadout:new(table.Copy(self))

	if self.origin then
		obj.m.origin = self.origin
	else
		obj.m.orign = self
	end

	return obj
end

function object:Delete()
	if self:GetParent() then
		self:GetParent():ClearLoadout() 
	end
	
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
	return string.lower(string.format("loadout_%s",self.usergroup or "user"))
end

function object:GetStatic()
	return Loadout
end

function object:Give(weapon)

	if not self:GetParent() then return end

	if weapon then
		self:GiveWeapon(weapon)
		return 
	end

	self:GetParent():StripWeapons()
	if self:DoesRemoveAmmo() then self:GetParent():RemoveAllAmmo() end
	
	if (self:DoesInherit() and self:GetAncestor()) then self:GetAncestor():Give() end
	
	for class,_ in pairs(self:GetWeapons()) do
		self:GiveWeapon(class)
	end
	
end

function object:GiveWeapon(class)

	if not self:HasWeapon(class) then return end
	ammo = self:GetWeapon(class)

	if not self:DoesRespectRestriction() then
		local restriction = self:GetParent():GetRestriction("pickup",class)
		if restriction then
			restriction:AddException(class)
		end
	end 
	
	self:GetParent():Give(class)
	
	local weapon = self:GetParent():GetWeapon(class)
	if not IsValid(weapon) then return end
	
	weapon:SetClip1(0)
	weapon:SetClip2(0)
		
	if (weapon:GetMaxClip1() <= 0) then
		self:GetParent():SetAmmo(ammo.primary,weapon:GetPrimaryAmmoType())
	elseif (weapon:GetMaxClip1() > ammo.primary) then
		weapon:SetClip1(ammo.primary)
		self:GetParent():SetAmmo(0,weapon:GetPrimaryAmmoType())
	else
		self:GetParent():SetAmmo(ammo.primary-weapon:GetMaxClip1(),weapon:GetPrimaryAmmoType())
		weapon:SetClip1(weapon:GetMaxClip1())
	end
	
	if (weapon:GetMaxClip2() <= 0) then
		self:GetParent():SetAmmo(ammo.secondary,weapon:GetSecondaryAmmoType())
	elseif (weapon:GetMaxClip2() > ammo.secondary) then
		weapon:SetClip2(ammo.secondary)
		self:GetParent():SetAmmo(0,weapon:GetSecondaryAmmoType())
	else
		self:GetParent():SetAmmo(ammo.secondary-weapon:GetMaxClip2(),weapon:GetSecondaryAmmoType())
		weapon:SetClip2(weapon:GetMaxClip2())
	end
	
	if (self.primary == class) then 
		self:GetParent():SelectWeapon(class)
	end
	
end

function object:TakeWeapon(class)

	if not self:HasWeapon(class) then return end
	ammo = self:GetWeapon(class)

	self:GetParent():StripwWeapon(class)
	
end

function object:HasWeapon(weapon)
	weapon = self:ParseWeapon(weapon)
	if self:GetWeapon(weapon) then return true end
	if self:GetAncestor() and self:GetAncestor():GetWeapon(weapon) then return true end
end

function object:IsPersonal()
	if self.usergroup then return false else return true end
end

function object:ParseWeapon(weapon)
	if (string.lower(type(weapon)) == "string") then
		return weapon
	elseif (string.lower(type(weapon)) == "entity") then
		return weapon:GetClass()
	end
	return "PARSING_ERROR"
end

function object:AddWeapon(weapon,primary,secondary)
	weapon = self:ParseWeapon(weapon)
	primary = primary or 0
	secondary = secondary or 0
	
	self:SetWeapon(weapon,{primary=primary,secondary=secondary})
	
	if self:GetParent() then 
		self:Give(weapon)
		if (self:GetChild() and self:GetChild():DoesInherit() and not(self:GetChild():HasWeapon(weapon))) then
			self:Give(weapon)
		end
	end
end

function object:RemoveWeapon(weapon)
	weapon = self:ParseWeapon(weapon)
	
	if (self:GetParent()) then
		if (self:HasWeapon(weapon)) then
			if not(self:DoesInherit() and self:GetAncestor() and self:GetAncestor():HasWeapon(weapon)) then
				self:GetParent():StripWeapon(weapon)
			end
		end
	end
	
	self:SetWeapon(weapon,nil)
end 

function object:GetWeaponCount()
	return table.Count(self:GetWeapons())
end


function object:SetWeapon(weapon,value)
	self.weapons[weapon] = value
end

function object:GetWeapon(weapon)
	weapon = self:ParseWeapon(weapon)
	return self:GetWeapons()[weapon] or false
end

function object:SetWeapons(weapons)
	self.weapons = weapons
end

function object:GetWeapons()
	return self.weapons
end

function object:SetParent(parent)
	self.parent = parent
end

function object:GetParent()
	return self.parent
end

function object:GetOrigin()
	return self.origin
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


function object:SetInherit(boolean)
	self.inherit = boolean
end

function object:GetInherit()
	return self.inherit
end

function object:SetInherit(boolean)
	self.inherit = boolean
end

function object:DoesInherit()
	return self.inherit
end

function object:SetRespectRestrictions(boolean)
	self.respect_restrictions = boolean
end

function object:DoesRespectRestriction()
	return self.respect_restrictions
end

function object:SetRemoveAmmo(boolean)
	self.remove_ammo = boolean
end

function object:DoesRemoveAmmo()
	return self.remove_ammo
end

function object:SetAncestor(ancestor)
	if not ancestor or not ancestor._id or ancestor._id != self._id then WUMAError("Tried to set a non-loadout object as child."); return end
	
	if (ancestor:GetAncestor()) then
		ancestor.ancestor = nil
	end
	
	ancestor.child = self
	self.ancestor = ancestor
end

function object:PurgeAncestor()
	if not self:GetAncestor() then return end
	for weapon,_ in pairs (self:GetAncestor()) do
		if not self:HasWeapon(weapon) then
			self:TakeWeapon(class)
		end
	end
	self.ancestor = nil
end

function object:GetAncestor()
	return self.ancestor
end

function object:SetChild(child)
	if not ancestor or not ancestor._id or ancestor._id != self._id then WUMAError("Tried to set a non-loadout object as child."); return end
	
	child.ancestor = self
	self.child = child
end

function object:GetChild()
	return self.child
end


function object:SetPrimary(weapon)
	weapon = self:ParseWeapon(weapon)
	if not self:GetWeapons(weapon) then return end
	self.primary = weapon
end

function object:GetPrimary(weapon)
	return self.primary
end

object.__index = object
static.__index = static

setmetatable(Loadout,static) 

