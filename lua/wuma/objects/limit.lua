
local object, static = WUMA.ClassFactory.Builder("Limit")

local function toNumberIfNumber(limit)
	if isnumber(limit) then return limit end

	if not isstring(limit) then error("limit must be number or string (was " .. type(limit) ..")") end

	local limit = string.Replace(limit, "'", "")

	local converted = tonumber(limit)
	return converted or limit
end

object:AddProperty("parent", "Parent")
object:AddProperty("item", "Item")
object:AddProperty("limit", "Limit", nil, toNumberIfNumber)
object:AddProperty("is_exclusive", "IsExclusive")

object:AddMetaData("entities", "Entities", {})
object:AddMetaData("counts", "Counts", {})

function object:__construct(args)
	if (tonumber(args.item) ~= nil) then error("item cannot be numeric") end

	if (args.limit == args.item) then error("limit and item cannot be the same") end

	self:SetLimit(args.limit)
end

function object:__tostring()
	return string.format("Limit [%s]", self:GetItem())
end

function object:Check(player, int)
	local limit = int or self:GetLimit()

	if not isnumber(limit) then error("limit is not number") end

	local count = self:GetCounts()[player:SteamID()] or 0
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

function object:Purge()
	for id, entry in pairs(self:GetEntities()) do
		local _, entity = unpack(entry)
		entity:RemoveWUMAParent(self)
	end

	self:SetCounts({})
	self:SetEntities({})
end

function object:Recover(limit)
	for id, entry in pairs(limit:GetEntities()) do
		self:AddEntity(unpack(entry))
	end

	limit:Purge()
end

function object:DeleteEntity(entity)
	local player, _ = unpack(self:GetEntities()[entity:GetCreationID()])

	local counts = self:GetCounts()
	counts[player:SteamID()] = (counts[player:SteamID()] or 1) - 1

	self:GetEntities()[entity:GetCreationID()] = nil

	if (counts[player:SteamID()] <= 0) then
		counts[player:SteamID()] = nil
	end
end

function object:AddEntity(player, entity)
	local entities = self:GetEntities()
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