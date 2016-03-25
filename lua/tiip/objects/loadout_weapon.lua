
Loadout_Weapon = {}

local object = {}
local static = {}

Loadout._id = "TIIP_Loadout_Weapon"
object._id = "TIIP_Loadout_Weapon"

--																								Static functions
function Loadout_Weapon:new(tbl)
	local mt = table.Copy(object)
	mt.m = {}
	
	local obj = setmetatable({},mt)
	
	obj.parent = tbl.parent or false
	obj.weapon = tbl.weapon or false
	obj.print = tbl.print or false
	obj.primary = tbl.primary or false
	obj.secondary = tbl.secondary or false

	return obj
end 

//																						Object functions
function object:__tostring()
	return string.format("Loadout_Weapon [%s]",)
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
	return Loadout_Weapon:new(self)
end

function object:SetPrimaryAmmo(ammo)
	self.primary = ammo
end

function object:GetPrimaryAmmo()
	return self.primary
end

function object:SetSecondaryAmmo(ammo)
	self.secondary = ammo
end

function object:GetSecondaryAmmo()
	return self.secondary
end


object.__index = object
static.__index = static

setmetatable(Loadout_Weapon,static) 

