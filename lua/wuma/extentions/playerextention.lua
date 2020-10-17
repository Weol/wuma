
local ENT = FindMetaTable("Player")

if CLIENT then
	local exclude_limits = CreateConVar("wuma_exclude_limits", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Exclude wuma limits from normal gamemode limits")

	function ENT:GetCount(str)
		if exclude_limits:GetBool() then
			return self:GetNWInt("Count." .. str, 0) - self:GetNWInt("Count.TotalLimits." .. str, 0)
		else
			return self:GetNWInt("Count." .. str, 0)
		end
	end
	return
end

local function shouldIgnore(str, id)
	if not id then
		if (str == "props") or (str == "vehicles") or (str == "sents") or (str == "ragdolls") or (str == "npcs") or (str == "effects") then
			return true
		end
	end
	return false
end

function ENT:FindLimit(str, id)
	local id_limit = WUMA.Limits[self:SteamID()] and WUMA.Limits[self:SteamID()][id]
	local str_limit = WUMA.Limits[self:SteamID()] and WUMA.Limits[self:SteamID()][str]

	local usergroup = self:GetUserGroup()
	while usergroup do
		WUMA.Limits[usergroup] = WUMA.Limits[usergroup] or WUMA.ReadLimits(usergroup) or {}

		id_limit = id_limit or WUMA.Limits[usergroup][id]
		str_limit = str_limit or WUMA.Limits[usergroup][str]

		usergroup = WUMA.GetInheritsLimitsFrom(usergroup)
	end

	local next = id_limit or str_limit
	local last_non_exclusive = next
	while next and isstring(next:GetLimit()) do
		next = self:FindLimit(next:GetLimit())

		if next and not next:GetIsExclusive() then
			last_non_exclusive = next
		end
	end

	return id_limit or str_limit, last_non_exclusive, next
end

ENT.old_CheckLimit = ENT.old_CheckLimit or ENT.CheckLimit
function ENT:CheckLimit(str, id)
	if shouldIgnore(str, id) then return true end

	local limit, last_non_exclusive, last_exclusive = self:FindLimit(str, id)

	if limit and not last_non_exclusive:Check(self, last_exclusive:GetLimit()) then
		return false
	end

	return self:old_CheckLimit(str, id)
end

ENT.old_AddCount = ENT.old_AddCount or ENT.AddCount
function ENT:AddCount(str, ent, id)
	if shouldIgnore(str, id) then return end

	WUMADebug("AddCount(%s, %s, %s)", tostring(str) or "nil", tostring(ent) or "nil", tostring(id) or "nil")

	local limit, last_non_exclusive = self:FindLimit(str, id)

	if limit then
		if (last_non_exclusive:GetItem() ~= str) then
			local steamid = self:SteamID()
			WUMA.ChangeTotalLimits(steamid, str, 1)
			ent:CallOnRemove("WUMATotalLimitChange", function(_, steamid, str) WUMA.ChangeTotalLimits(steamid, str, -1) end, steamid, str)
		end

		last_non_exclusive:AddEntity(self, ent)
	end

	return self:old_AddCount(str, ent, id)
end

ENT.old_GetCount = ENT.old_GetCount or ENT.GetCount
function ENT:GetCount(str, minus, id)
	minus = minus or 0

	if not self:IsValid() then
		return
	end

	local totalLimit = WUMA.GetTotalLimits(self:SteamID(), str)

	local limit, last_non_exclusive = self:FindLimit(id or str)
	if id and limit and (limit:GetItem() == id) then
		return last_non_exclusive:GetCount(self)
	elseif limit and (limit:GetItem() == str) then
		return last_non_exclusive:GetCount(self) - totalLimit
	else
		return self:old_GetCount(str, minus) - totalLimit
	end
end

function ENT:LimitHit(string)
	self:SendLua(string.format([[WUMA.NotifyLimitHit("%s")]], string))
end

function ENT:CheckRestriction(type, item)
	local usergroup = self:GetUserGroup()
	local steamid = self:SteamID()

	local key = type .. "_" .. item

	local user_type_restricted = WUMA.Settings[steamid]["restrict_type_" .. type]


	local restriction = WUMA.Restrictions[steamid][key]

	local current = usergroup
	while not restriction do
		restriction = WUMA.Restrictions[current][key]
		current = WUMA.Inheritance["restrictions"][current]
	end
end

local old_Loadout = ENT.Loudout
function ENT:Loadout()
	local steamid = self:SteamID()
	local usergroup = self:GetUserGroup()

	local user_enforce = WUMA.Settings[steamid]["loadout_enforce"]
	local group_enforce = WUMA.Settings[usergroup]["loadout_enforce"]

	local user_primary_weapon = WUMA.Settings[steamid]["loadout_primary_weapon"]
	local group_primary_weapon = WUMA.Settings[usergroup]["loadout_primary_weapon"]

	self:ConCommand("cl_defaultweapon " .. user_primary_weapon or group_primary_weapon)

	self:StripWeaopns()
	self:RemoveAllAmmo()

	if not user_enforce and not group_enforce then
		old_Loadout(self)
	end

	if WUMA.Loadouts[steamid] then
		for class, weapon in pairs(WUMA.Loadouts[usergroup]) do
			WUMA.GiveWeapon(player, weapon)
		end
		if user_enforce then return end
	end

	if WUMA.Loadouts[usergroup] then
		for class, weapon in pairs(WUMA.Loadouts[usergroup]) do
			WUMA.GiveWeapon(player, weapon)
		end
		if group_enforce then return end
	end

	self:SwitchToDefaultWeapon()
end