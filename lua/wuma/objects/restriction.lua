
local object, static = WUMA.ClassFactory.Builder("Restriction")

object:AddProperty("parent", "Parent")
object:AddProperty("type", "Type")
object:AddProperty("item", "Item")
object:AddProperty("is_anti", "IsAnti")

object:AddMetaData("exceptions", "Exceptions", {})

function object:Check(player)
	if self:GetIsDisabled() then return end

	local exceptions = self:GetExceptions()
	if exceptions[player:SteamID()] then
		exceptions[player:SteamID()] = nil
		return
	end

	if not self:GetIsAnti() then
		local type = self:GetType()

		if (type ~= "pickup") then
			self:GetParent():SendLua(string.format([[WUMA.NotifyRestriction("%s", "%s")]], self:GetType(), self:GetItem()))
			self:GetParent():SendLua([[surface.PlaySound("buttons/button10.wav")]])
		end

		return false
	end
end

function object:__tostring()
	return string.format("Restriction [%s] [%s]", self:GetType(), self:GetItem())
end

Restriction = WUMA.ClassFactory.Create(object)

local object, static = WUMA.ClassFactory.Builder("RestrictionType")

object:AddProperty("name", "Name")
object:AddProperty("print", "Print")
object:AddProperty("print2", "Print2")
object:AddProperty("search", "Search")
object:AddProperty("items", "Items")
object:AddProperty("preprocessor", "PreProcessor")

function object:GetItems()
	return self.items and self.items() or {}
end

RestrictionType = WUMA.ClassFactory.Create(object)