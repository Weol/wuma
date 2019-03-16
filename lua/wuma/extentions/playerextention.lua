 
local ENT = FindMetaTable("Player")
 
ENT.old_CheckLimit = ENT.old_CheckLimit or ENT.CheckLimit
function ENT:CheckLimit(str, WUMA)
	if (WUMA and self:HasLimit(WUMA)) then
		local limithit = self:GetLimit(WUMA):Check() 
		if (limithit ~= nil) then return limithit end
	end	
	 
	if (self:HasLimit(str)) then
		local limithit = self:GetLimit(str):Check()
		if (limithit ~= nil) then return limithit end
	end

	--Fall back to whichever system we overrode
	return self.old_CheckLimit(self, str)	
end 
 
ENT.old_AddCount = ENT.old_AddCount or ENT.AddCount
function ENT:AddCount(str, ent, WUMA)

	if (WUMA and self:HasLimit(WUMA)) then 
		self:GetLimit(WUMA):Add(ent)
	elseif (self:HasLimit(str)) then
		self:GetLimit(str):Add(ent)
	elseif not WUMA and str then
		self.old_AddCount(self, str, ent)
	end 
	
end 

ENT.old_GetCount = ENT.old_GetCount or ENT.GetCount
function ENT:GetCount(str, minus, WUMA)
	
	minus = minus or 0 

	--Lets not do anything if we are running at client, let the sandbox function handle that
	if CLIENT then return self.old_GetCount(self, str, minus) end
	
	if (WUMA and self:HasLimit(WUMA)) then 
		local l = self:GetLimit(WUMA):GetCount()
		if (minus > 0) then self:GetLimit(WUMA):Subtract(minus) end
		return l
	elseif self:HasLimit(str) then
		local l = self:GetLimit(str):GetCount()
		if (minus > 0) then self:GetLimit(str):Subtract(minus) end
		return l
	else
		return self.old_GetCount(self, str, minus)	
	end
	
end

function ENT:LimitHit(str)
	if self:HasLimit(str) then
		self:GetLimit(str):Hit()
	else
		Limit:GenerateHit(str, self)
	end
end

function ENT:GetWUMAData()
	return {
		restrictions = self:GetRestrictions() or false,
		limits = self:GetLimits() or false,
		loadout = self:GetLoadout() or false
	}
end

function ENT:HasWUMAData()
	if (self:GetRestrictions() or self:GetLimits() or self:GetLoadout()) then return true else return false end
end
 
function ENT:CheckRestriction(type, str)
	WUMADebug("Checking %s %s for %s (%s)", type, str, self:Nick(), self:SteamID())

	local restriction = self:GetRestriction(type, str)
	
	if restriction then 
		return restriction(type, str)
	end
end

function ENT:SetRestrictions(restrictions)
	self.Restrictions = restrictions
end

function ENT:AddRestriction(restriction) 
	if not self:GetRestrictions() then self.Restrictions = {} end

	local id = restriction:GetID(true)
	restriction:SetParent(self)
	
	local old = self:GetRestriction(id)
	local new = restriction

	if (not old) or (new:IsPersonal() == old:IsPersonal()) then
		self:GetRestrictions()[id] = new
	elseif new:IsPersonal() then
		new:SetAncestor(old)
		self:GetRestrictions()[id] = new
	elseif old:IsPersonal() then
		old:SetAncestor(new)
	else
		self:GetRestrictions()[id] = new
	end
	
	hook.Call(WUMA.USERRESTRICTIONADDED, _, self, restriction)
end 

function ENT:AddRestrictions(tbl)
	for _, object in pairs(tbl) do
		self:AddRestriction(object)
	end
end

function ENT:RemoveRestriction(id, personal) 
	local restriction = self:GetRestriction(id)
	if not restriction then return end
	
	if (restriction:IsPersonal() == personal) then
		local ancestor = restriction:GetAncestor()
		self:GetRestrictions()[id] = ancestor
	elseif (restriction:IsPersonal()) then
		restriction:SetAncestor(nil)
	elseif (personal) then
		local ancestor = restriction:GetAncestor()
		self:GetRestrictions()[id] = ancestor
	end
	
	if (table.Count(self:GetRestrictions()) < 1) then self.Restrictions = nil end
	
	hook.Call(WUMA.USERRESTRICTIONREMOVED, _, self, restriction)
end

function ENT:GetRestrictions()
	return self.Restrictions 
end
 
function ENT:GetRestriction(type, str)
	if not self:GetRestrictions() then return nil end
	if str then
		local key = Restriction:GenerateID(type, _, str)
		if self:GetRestrictions()[key] then
			return self:GetRestrictions()[key]
		end
	
		return self:GetRestrictions()[type]
	else
		return self:GetRestrictions()[type]
	end
end 

function ENT:SetLimits(limits) 
	self.Limits = limits
end

function ENT:AddLimit(limit)
	if not self:GetLimits() then self.Limits = {} end

	local id = limit:GetID(true)
	limit:SetParent(self)
	
	local old = self:GetLimit(id)
	local new = limit
	
	local cache = self.LimitsCache
	if (cache) then
		if (cache[id]) then
			new:InheritEntities(cache[id])
			cache[id] = nil
		end
	end
	
	if (not old) or (new:IsPersonal() == old:IsPersonal()) then
		self:GetLimits()[id] = new
		if old then new:InheritEntities(old) end
	elseif new:IsPersonal() then
		new:SetAncestor(old)
		new:InheritEntities(old)
		
		self:GetLimits()[id] = new
	elseif old:IsPersonal() then
		old:SetAncestor(new)
	else
		self:GetLimits()[id] = new
	end
end
 
function ENT:RemoveLimit(id, personal)
	local limit = self:GetLimit(id)
	if not limit then return end

	if (limit:GetCount() > 0) and not limit:GetAncestor() then
		if not self.LimitsCache then self.LimitsCache = {} end
		self.LimitsCache[id] = limit
	end
	
	if (limit:IsPersonal() == personal) then
		local ancestor = limit:GetAncestor()
		if ancestor then ancestor:InheritEntities(limit) end
		
		self:GetLimits()[id] = ancestor
	elseif (limit:IsPersonal()) then
		limit:SetAncestor(nil) 
	elseif (personal) then
		local ancestor = limit:GetAncestor()
		if ancestor then ancestor:InheritEntities(limit) end
		
		self:GetLimits()[id] = ancestor
	end

	if (table.Count(self:GetLimits()) < 1) then self.Limits = nil end
end

function ENT:GetLimits()
	return self.Limits
end 

function ENT:GetLimit(str)
	if not self:GetLimits() then return false end
	local id = Limit:GenerateID(_, str)
	return self:GetLimits()[id]
end

function ENT:HasLimit(str)
	if not self:GetLimits() then return false end
	local id = Limit:GenerateID(_, str)
	if self:GetLimits()[id] then return true end
	return false
end

function ENT:SetLimitCache(cache)
	self.LimitsCache = cache
end

function ENT:CacheLimits()
	local cache = self.LimitsCache or {}
	for id, limit in pairs(self:GetLimits() or {}) do
		if (limit:GetCount() > 0) then
			cache[limit:GetID(true)] = limit
			limit:CallOnEmpty("WUMADeleteCache", function(limit) 
				cache[limit:GetID(true)] = nil
			end)
		end
	end
	self:SetLimitCache(cache)
end

function ENT:GiveLoadout()
	if self:HasLoadout() then
		self:GetLoadout():Give()

		if self:GetLoadout():GetEnforce() then
			return true
		elseif self:GetLoadout():GetAncestor() and self:GetLoadout():GetAncestor():GetEnforce() then 
			return true 
		else
			if (self:GetLoadout():GetPrimary()) then
				self:ConCommand(string.format("cl_defaultweapon %s"), self:GetLoadout():GetPrimary())
			end
		end
	end
end

function ENT:SetPrimaryWeapon(weapon)
	if self:HasLoadout() then
		self:GetLoadout():SetPrimaryWeapon(weapon)
	end
end

function ENT:SetLoadout(loadout)
	loadout:SetParent(self)
	if self:HasLoadout() and not self:GetLoadout():IsPersonal() then 
		loadout:SetAncestor(self:GetLoadout()) 
	end
	self.Loadout = loadout

	if self:Alive() then
		self:GiveLoadout()
	end
end 
 
function ENT:ClearLoadout() 
	if (self.Loadout and self.Loadout:IsPersonal()) then
		if (self.Loadout:GetAncestor()) then
			local ancestor = self.Loadout:GetAncestor()
			
			self.Loadout = ancestor
			ancestor.child = nil
			
			self.Loadout:Give()
		else
			self.Loadout:Delete()
			self.Loadout = nil
			
			WUMA.GiveLoadout(self)
		end
	elseif self.Loadout then
		self.Loadout:Delete()
		self.Loadout = nil 
		
		WUMA.GiveLoadout(self)
	end
end

function ENT:HasLoadout()
	if self:GetLoadout() then
		if self:GetLoadout():IsDisabled() then
			return false
		end
		return true
	end
	return false
end

function ENT:GetLoadout()
	return self.Loadout
end

ENT.DisregardTable = {}
function ENT:DisregardNextPickup(class)
	self.DisregardTable[class] = true
end

function ENT:ShouldDisregardPickup(class)
	if self.DisregardTable[class] then 
		self.DisregardTable[class] = nil
		return true 
	else
		return false
	end
end