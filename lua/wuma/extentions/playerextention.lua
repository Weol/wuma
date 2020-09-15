
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
		if (str == "vehicles") or (str == "sents") or (str == "ragdolls") or (str == "npcs") or (str == "effects") or (str == "props") then
			return true
		end
	end
	return false
end

function ENT:FindLimit(item)
	local limit = WUMA.Limits[self:SteamID()] and WUMA.Limits[self:SteamID()][item]

	local usergroup = self:GetUserGroup()
	while usergroup and not limit do
		WUMA.Limits[usergroup] = WUMA.Limits[usergroup] or WUMA.ReadLimits(usergroup) or {}

		limit = WUMA.Limits[usergroup][item]

		usergroup = WUMA.GetInheritsLimitsFrom(usergroup)
	end

	local next = limit
	local last_non_exclusive = limit
	while next and isstring(next:GetLimit()) do
		next = self:FindLimit(next:GetLimit())

		if next and not next:GetIsExclusive() then
			last_non_exclusive = next
		end
	end

	return limit, last_non_exclusive, next
end

ENT.old_CheckLimit = ENT.old_CheckLimit or ENT.CheckLimit
function ENT:CheckLimit(str, id)
	if shouldIgnore(str, id) then return true end

	local limit, last_non_exclusive, last_exclusive = self:FindLimit(id or str)
	if limit and not last_non_exclusive:Check(self, last_exclusive:GetLimit()) then
		return false
	end

	return self:old_CheckLimit(str, id)
end

ENT.old_AddCount = ENT.old_AddCount or ENT.AddCount
function ENT:AddCount(str, ent, id)
	if shouldIgnore(str, id) then return end

	local limit, last_non_exclusive = self:FindLimit(id or str)

	if limit and id then
		last_non_exclusive:AddEntity(self, ent)

		local steamid = self:SteamID()
		WUMA.ChangeTotalLimits(steamid, str, 1)
		ent:CallOnRemove("WUMATotalLimitChange", function(_, steamid, str) WUMA.ChangeTotalLimits(steamid, str, -1) end, steamid, str)
	elseif limit then
		last_non_exclusive:AddEntity(self, ent)
	end

	return self:old_AddCount(str, ent, id)
end

ENT.old_GetCount = ENT.old_GetCount or ENT.GetCount
function ENT:GetCount(str, minus, id)
	--WUMADebug("ENT:GetCount(%s, %s, %s)", tostring(str) or "nil", tostring(minus) or "nil", tostring(id) or "nil")
	return self:old_GetCount(str, minus, id)
end

function ENT:LimitHit(string)
	self:SendLua(string.format([[WUMA.NotifyLimitHit("%s")]], string))
end

function ENT:CheckRestriction(type, str)
	--WUMADebug("Checking %s %s for %s (%s)", type, str, self:Nick(), self:SteamID())
end

function ENT:SetRestrictions(restrictions)
	self.Restrictions = restrictions
end

local old_Loadout = ENT.Loudout
function ENT:Loadout()
	local steamid = self:SteamID()
	local usergroup = self:GetUserGroup()

	local user_enforce = WUMA.GetSetting(steamid, "loadout_enforce")
	local group_enforce = WUMA.GetSetting(usergroup, "loadout_enforce")

	local user_primary_weapon = WUMA.GetSetting(steamid, "loadout_primary_weapon")
	local group_primary_weapon = WUMA.GetSetting(usergroup, "loadout_primary_weapon")

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