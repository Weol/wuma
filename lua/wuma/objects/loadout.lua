
Loadout = {}

local object = {}
local static = {}

Loadout._id = "WUMA_Loadout"
object._id = "WUMA_Loadout"

/////////////////////////////////////////////////////////
/////       		 Static functions				/////
/////////////////////////////////////////////////////////
function Loadout:new(tbl)
	tbl = tbl or {}
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)
	
	obj.m._uniqueid = WUMA.GenerateUniqueID()
	
	obj.usergroup = tbl.usergroup or nil
	obj.primary = tbl.primary or nil
	obj.inherit = tbl.inherit or nil
	obj.respect_restrictions = tbl.respect_restrictions or nil
	obj.weapons = {}
	
	if tbl.weapons then
		for class, wep in pairs(tbl.weapons) do
			wep.parent = obj
			obj.weapons[class] = Loadout_Weapon:new(wep)
		end
	end
	
	obj.m._id = Loadout._id
	
	obj.m.origin = tbl.origin or nil
	obj.m.parent = tbl.parent or nil
	if isstring(obj.m.parent) then obj.m.parentid = obj.m.parent elseif obj.m.parent then obj.m.parentid = obj.m.parent:SteamID() end
	obj.m.ancestor = tbl.ancestor or nil
	obj.m.child = tbl.child or nil

	return obj
end 

function static:GetID()
	return Loadout._id
end

/////////////////////////////////////////////////////////
/////       		 Object functions				/////
/////////////////////////////////////////////////////////
function object:__tostring()
	return string.format("Loadout [%s]",self:GetParent() or self.usergroup)
end

function object:__eq(v1,v2)
	if v1._id and v2._id then return (v1._id == v2._id) end
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
	local obj = Loadout:new(copy)

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

	if (self:DoesInherit() and self:GetAncestor()) then self:GetAncestor():Give() end
	
	for class,_ in pairs(self:GetWeapons()) do
		self:GiveWeapon(class)
	end
	
	if self:GetPrimary() then
		self:GetParent():SelectWeapon(self:GetPrimary())
	end
	
end

function object:GiveWeapon(class)

	if not self:HasWeapon(class) then return end
	if not self:GetParent() then return end

	local weapon = self:GetWeapon(class)
	
	if weapon:IsDisabled() then return end
	
	if not weapon:DoesRespectRestriction() then
		local restriction = self:GetParent():GetRestriction("pickup",class)
		if restriction then
			restriction:AddException(class)
		end
	end 
	
	self:GetParent():Give(class)
	
	local swep = self:GetParent():GetWeapon(class)
	if not IsValid(swep) then return end
	
	local primary_ammo = weapon:GetPrimaryAmmo()
	if (primary_ammo < 0) then primary_ammo = swep:GetMaxClip1() * 4 end
	if (primary_ammo < 0) then primary_ammo = 3 end
	
	local secondary_ammo = weapon:GetSecondaryAmmo()
	if (secondary_ammo < 0) then secondary_ammo = swep:GetMaxClip2() * 4 end
	if (secondary_ammo < 0) then secondary_ammo = 3 end
	
	swep:SetClip1(0)
	swep:SetClip2(0)
		
	if (swep:GetMaxClip1() <= 0) then
		self:GetParent():SetAmmo(primary_ammo,swep:GetPrimaryAmmoType())
	elseif (swep:GetMaxClip1() > primary_ammo) then
		swep:SetClip1(primary_ammo)
		self:GetParent():SetAmmo(0,swep:GetPrimaryAmmoType())
	else
		self:GetParent():SetAmmo(primary_ammo-swep:GetMaxClip1(),swep:GetPrimaryAmmoType())
		swep:SetClip1(swep:GetMaxClip1())
	end
	
	if (swep:GetMaxClip2() <= 0) then
		self:GetParent():SetAmmo(secondary_ammo,swep:GetSecondaryAmmoType())
	elseif (swep:GetMaxClip2() > secondary_ammo) then
		swep:SetClip2(secondary_ammo)
		self:GetParent():SetAmmo(0,swep:GetSecondaryAmmoType())
	else
		self:GetParent():SetAmmo(secondary_ammo-swep:GetMaxClip2(),swep:GetSecondaryAmmoType())
		swep:SetClip2(swep:GetMaxClip2())
	end
	
end

function object:TakeWeapon(class)
	if not self:GetParent() then return end
	if not self:HasWeapon(class) then return end

	if self:GetParent() and (class == self:GetParent():GetActiveWeapon()) then
		if self:GetPrimary() then
			self:GetParent():SelectWeapon(self:GetPrimary())
		else
			for _, weapon in pairs(self:GetWeapons()) do
				self:GetParent():SelectWeapon(weapon)
				break
			end
		end
	end
	
	self:GetParent():StripWeapon(class)
end

function object:HasWeapon(weapon)
	weapon = self:ParseWeapon(weapon)
	if self:GetWeapon(weapon) then return true end
	if self:GetAncestor() and self:GetAncestor():GetWeapon(weapon) then return true end
end

function object:IsPersonal()
	if self.usergroup then return nil else return true end
end

function object:ParseWeapon(weapon)
	if (string.lower(type(weapon)) == "string") then
		return weapon
	elseif (string.lower(type(weapon)) == "entity") then
		return weapon:GetClass()
	end
	return weapon
end

function object:AddWeapon(weapon,primary,secondary,respect,scope)
	weapon = Loadout_Weapon:new{class=self:ParseWeapon(weapon),primary=primary,secondary=secondary,respect_restrictions=respect,scope=scope,parent=self}
	
	self:SetWeapon(weapon:GetClass(),weapon)
	
	if self:GetParent() and isentity(self:GetParent()) then 
		self:Give(weapon:GetClass())
		if (self:GetChild() and self:GetChild():DoesInherit() and not(self:GetChild():HasWeapon(weapon))) then
			self:Give(weapon:GetClass())
		end
	end
end

function object:RemoveWeapon(weapon)
	weapon = self:ParseWeapon(weapon)
	
	if (self:GetPrimary() == weapon) then self:SetPrimary(nil) end
	
	if (self:GetParent() and isentity(self:GetParent())) then
		if (self:HasWeapon(weapon)) then
			if not(self:DoesInherit() and self:GetAncestor() and self:GetAncestor():HasWeapon(weapon)) then
				self:TakeWeapon(weapon)
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
	self.m.parent = parent
	if isstring(self.m.parent) then self.m.parentid = self.m.parent elseif self.m.parent then self.m.parentid = self.m.parent:SteamID() end
end

function object:GetParent()
	return self.m.parent
end

function object:GetOrigin()
	return self.m.origin
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

function object:GetUserGroup()
	return self.usergroup
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

function object:SetAncestor(ancestor)
	if not ancestor or not ancestor._id or ancestor._id != self._id then WUMAError("Tried to set a non-loadout object as child."); return end
	
	if (ancestor:GetAncestor()) then
		ancestor.ancestor = nil
	end
	
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

function object:GetPrimary()
	return self.primary
end

object.__index = object
static.__index = static

setmetatable(Loadout,static) 

