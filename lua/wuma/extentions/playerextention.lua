
local ENT = FindMetaTable("Player")

local exclude_limits = WUMA.ExcludeLimits

local ignore = {
	vehicles = 1,
	sents = 1,
	ragdolls = 1,
	npcs = 1,
	effects = 1,
	props = 1
}

ENT.old_CheckLimit = ENT.old_CheckLimit or ENT.CheckLimit
function ENT:CheckLimit(str, id)
	--Fall back to whichever system we overrode
	return self.old_CheckLimit(self, str)
end

ENT.old_AddCount = ENT.old_AddCount or ENT.AddCount
function ENT:AddCount(str, ent, id)
	if (id and self:HasLimit(id)) then
		self:GetLimit(id):Add(ent, str)

		local steamid = self:SteamID()
		WUMA.ChangeTotalLimits(steamid, str, 1)
		ent:CallOnRemove("WUMATotalLimitChange", function(ent, steamid, str) WUMA.ChangeTotalLimits(steamid, str, -1) end, steamid, str)
	elseif (self:HasLimit(str)) then
		self:GetLimit(str):Add(ent, str)
	elseif not id and str then
		self.old_AddCount(self, str, ent)
	end
end

ENT.old_GetCount = ENT.old_GetCount or ENT.GetCount
function ENT:GetCount(str, minus, id)
	minus = minus or 0

	--Lets not do anything if we are running at client, let the sandbox function handle that
	if CLIENT then return self.old_GetCount(self, str, minus) end

	if not self:IsValid() then
		return
	end

	local totalLimit = WUMA.GetTotalLimits(self:SteamID(), str)
	if (id and self:HasLimit(id)) then
		local l = self:GetLimit(id):GetCount()
		if (minus > 0) then self:GetLimit(id):Subtract(minus) end
		return l
	elseif self:HasLimit(str) then
		local l = self:GetLimit(str):GetCount() - totalLimit
		if (minus > 0) then self:GetLimit(str):Subtract(minus) end
		return l
	else
		return self.old_GetCount(self, str, minus) - totalLimit
	end

end

function ENT:LimitHit(string)
	if self:HasLimit(string) then
		self:GetLimit(string):Hit()
	else
		self:SendLua(string.format([[WUMA.NotifyLimitHit("%s")]], string))
	end
end

function ENT:CheckRestriction(type, str)
	WUMADebug("Checking %s %s for %s (%s)", type, str, self:Nick(), self:SteamID())
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