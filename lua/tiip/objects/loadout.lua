
Loadout = {}

local object = {}
local static = {}

Loadout._id = "TIIP_Loadout"
object._id = "TIIP_Loadout"

--																								Static functions
function Loadout:new(tbl)
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)
	
	obj.parent = tbl.parent or false
	obj.primary = tbl.primary or false
	obj.weapons = tbl.weapons or {}

	return obj
end 

//																						Object functions
function object:__tostring()
	return "lel"
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

function object:Clone()
	return Loadout:new(self)
end

function object:ParseWeapon(weapon)
	if (isstring(weapon)= == "string") then
		return weapon
	elseif (isentity(weapon)) == "entity") then
		return weapon:GetClass()
	elseif (istable(weapon) and weapon._id and weapon._id == Loadout_Weapon._id) then
		return weapon.weapon, weapon:GetPrimaryAmmo(), weapon:GetSecondaryAmmo()
	end
	return "PARSING_ERROR"
end


function object:AddWeapon(weapon,primary,secondary)
	if not primary and not secondary then
		weapon,primary,secondary = self:ParseWeapon(weapon)
	else
		weapon = self:ParseWeapon(weapon)
	end
	
	primary = primary or 0
	secondary = secondary or 0
	
	self.weapons[weapon] = Loadout_Weapon:new({parent=self,weapon=weapon,primary=primary,secondary=secondary})
end

function object:RemoveWeapon(weapon)
	weapon = self:ParseWeapon(weapon)
	
	self.weapons[weapon] = nil
end

function object:HasWeapon(weapon)
	weapon = self:ParseWeapon(weapon)
	if self.weapons[weapon] then return true else return false end
end

function object:GetWeapon(weapon)
	weapon = self:ParseWeapon(weapon)
	return self.weapons[weapon]
end

function object:SetPrimary(weapon)
	weapon = self:ParseWeapon(weapon)
	self.primary = weapon
end

object.__index = object
static.__index = static

setmetatable(Loadout,static) 

