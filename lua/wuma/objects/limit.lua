
local object, static = WUMA.ClassFactory.Builder("Limit")

object:AddProperty("parent", "Parent")
object:AddProperty("item", "Item")
object:AddProperty("limit", "Limit")
object:AddProperty("is_exclusive", "IsExclusive")

object:AddMetaData("entities", "Entities", {})
object:AddMetaData("counts", "Counts", {})

function object:__construct(args)
	if (tonumber(args.item) ~= nil) then error("item cannot be numeric") end

	if (args.limit == args.item) then error("limit and item cannot be the same") end

	if not isnumber(args.limit) then
		local limit = string.Replace(args.limit, "'", "")
		if (tonumber(limit) ~= nil) then
			self:SetLimit(tonumber(limit))
		end
	end
end

function object:__tostring()
	return string.format("Limit [%s]", self:GetItem())
end

function object:Check(player, int)
	if self:IsDisabled() then return end

	local limit = int or self:GetLimit()

	if istable(limit) then
		if not limit:IsExclusive() then
			return limit:Check(player)
		else
			return self:Check(player, limit:Get())
		end
	elseif isstring(limit) and self:GetParent():HasLimit(limit) then
		return self:Check(self:GetParent():GetLimit(limit))
	elseif isstring(limit) then
		return
	end

	local count = self:GetCounts()[player:SteamID()]
	if (limit < 0) then return true end
	if (limit <= count) then
		player:SendLua(string.format([[WUMA.NotifyLimitHit("%s")]], self:GetItem()))
		return false
	end

	return true
end

function object:Purge()
	for id, entry in pairs(self:GetEntities()) do
		local _, entity = unpack(entry)
		entity:RemoveWUMAParent(entity)
	end

	self:SetCounts({})
	self:SetEntities({})
end

function object:DeleteEntity(entity)
	local player, _ = unpack(entity:GetEntities()[entity:GetCreationID()])

	local counts = self:GetCounts()
	counts[player:SteamID()] = (counts[player:SteamID()] or 0) - 1

	if (counts[player:SteamID()] <= 0) then
		counts[player:SteamID()] = nil
	end
end

function object:AddEntity(player, entity)
	local entities = entity:GetEntities()
	if (entities[entity:GetCreationID()]) then return end

	local counts = self:GetCounts()
	counts[player:SteamID()] = (counts[player:SteamID()] or 0) + 1

	local limit = self:GetLimit()
	if istable(limit) then
		limit:AddEntity(player, entity)
	end

	entity:AddWUMAParent(self)
	entities[entity:GetCreationID()] = {player,  entity}
end

Limit = WUMA.ClassFactory.Create(object)