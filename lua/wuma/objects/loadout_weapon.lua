
local object, static = WUMA.ClassFactory.Builder("Weapon")

object:AddProperty("parent", "Parent")
object:AddProperty("class", "Class")
object:AddProperty("primary_ammo", "PrimaryAmmo")
object:AddProperty("secondary_ammo", "SecondaryAmmo")

function object:__tostring()
	return string.format("Loadout Weapon [%s]", self:GetClass())
end

LoadoutWeapon = WUMA.ClassFactory.Create(object)