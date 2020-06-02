
local object, static = WUMA.ClassFactory.Builder("Weapon")

object:AddProperty("parent", "Parent")
object:AddProperty("class", "Class")
object:AddProperty("primary_ammo", "PrimaryAmmo")
object:AddProperty("secondary_ammo", "SecondaryAmmo")
object:AddProperty("ignore_restrictions", "IsIgnoreRestrictions")

object:AddMetaData("disabled", "IsDisabled", false)

function static:GenerateID(parent, class)
	return string.format("%s_%s", parent, class)
end

function object:__tostring()
	return string.format("Loadout Weapon [%s]", self:GetClass())
end

function object:GetID()
	return string.format("%s_%s", self:GetParent(), self:GetClass())
end

LoadoutWeapon = WUMA.ClassFactory.Create(object)