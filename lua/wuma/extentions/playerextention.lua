
local ENT = FindMetaTable("Player")
local self = ENT

ENT.Restrictions = ENT.Restrictions or {}
ENT.Limits = ENT.Limits or {}
ENT.Loadout = ENT.Loadout or nil
 
function ENT:CheckLimit(str, WUMA) 
	
	WUMADebug("Checklimit(%s,%s)",str or "_",WUMA or "_")
	
	if (game.SinglePlayer()) then return true end
	
	if WUMA then 
		WUMA = string.lower(WUMA)
		if (self:HasLimit(WUMA)) then
			return self:GetLimit(WUMA):Check()
		end

		local c = cvars.Number("sbox_max"..str, 0)
	
		if (c < 0) then return true end
		if (self:GetCount(str) > c-1) then self:LimitHit(str) return false end
		return true
	end
	
	return true

end

function ENT:AddCount(str, ent, WUMA)
 
	WUMADebug("AddCount(%s,%s,%s)",str or "_",tostring(ent) or "_",WUMA or "_")

	if (WUMA) then WUMA = string.lower(WUMA) end
	
	if (WUMA and self:HasLimit(WUMA)) then
		self:GetLimit(WUMA):Add(ent)
	else

		if (SERVER) then

			local key = self:UniqueID()
			g_SBoxObjects[ key ] = g_SBoxObjects[ key ] or {}
			g_SBoxObjects[ key ][ str ] = g_SBoxObjects[ key ][ str ] or {}
			
			local tab = g_SBoxObjects[ key ][ str ]
			
			table.insert(tab, ent)
			
			-- Update count (for client)
			self:GetCount(str)
			
			ent:CallOnRemove("GetCountUpdate", function (ent, ply, str) ply:GetCount(str, 1) end, self, str)
		
		end
	
	end
		
	
end

function ENT:GetCount(str, minus, WUMA)

	WUMADebug("GetCount(%s,%s,%s)",str or "_",tostring(minus) or "_",WUMA or "_")

	if (WUMA) then WUMA = string.lower(WUMA) end
	
	if (WUMA and self:HasLimit(WUMA)) then 
		local l = self:GetLimit(WUMA):GetCount()
		if (minus > 0) then self:GetLimit(WUMA):Subtract(minus) end
		return l
	else
		
		if (CLIENT) then
			return self:GetNetworkedInt("Count."..str, 0)
		end
		
		minus = minus or 0
		
		if (!self:IsValid()) then return end

		local key = self:UniqueID()
		local tab = g_SBoxObjects[ key ]
		
		if (!tab || !tab[ str ]) then 
		
			self:SetNetworkedInt("Count."..str, 0)
			return 0 
			
		end
		
		local c = 0

		for k, v in pairs(tab[ str ]) do
		
			if (v:IsValid()) then 
				c = c + 1
			else
				tab[ str ][ k ] = nil
			end
		
		end
		
		self:SetNetworkedInt("Count."..str, c - minus)

		return c
			
	end
	
end

function ENT:LimitHit(str)

	WUMADebug("LimitHit(%s)",str or "_")

	if not self:HasLimit(str) then
		Limit:GenerateHit(str,self)
	else
		self:GetLimit(str):Hit()
	end

end

function ENT:GetWUMAData()
	return {
		user = self,
		steamid = self:SteamID(),
		nick = self:Nick(),
		restrictions = self:GetRestrictions() or false,
		limits = self:GetLimits() or false,
		loadout = self:GetLoadout() or false
	}
end   

function ENT:HasWUMAData()
	if (self:GetRestrictions() or self:GetLimits() or self:GetLoadout()) then return true else return false end
end   
 
function ENT:CheckRestriction(type,str)
	WUMADebug("CheckRestriction(%s,%s)",type,str)
	
	local key = Restriction:GenerateID(type,str)
	 
	if not self.Restrictions[key] then return end

	return self.Restrictions[key](type,str)
end   
 
function ENT:AddRestriction(object) 
	local key = object:GetID() 
	 
	object:SetParent(self)
	
	if not self.Restrictions[key] or not object:IsPersonal() then
		self.Restrictions[key] = object
	else
		self.Restrictions[key]:SetOverride(object)
	end
end 

function ENT:AddRestrictions(tbl)
	for _,object in pairs(tbl) do
		self:AddRestriction(object)
	end
end

function ENT:RemoveRestriction(id,personal) 
	if not id then return end
	if not self.Restrictions[id] then return end
	
	if personal then
		if not self.Restrictions[id]:IsPersonal() and self.Restrictions[id]:GetOverride() then
			if (self.Restrictions[id]:GetOverride():GetID() == id) then
				self.Restrictions[id]:RemoveOverride()
				return
			end
		end
	end
	
	self.Restrictions[id] = nil
end

function ENT:GetRestrictions()
	return self.Restrictions
end
 
function ENT:GetRestriction(type,str)
	if not str then return end
	local key = Restriction:GenerateID(type,str)
	
	if (isstring(str) and type and isstring(type)) then 
		return self.Restrictions[key]
	end 
end

function ENT:AddLimit(limit)
	limit:SetParent(self)

	if not self.Limits[limit:GetID()] or not limit:IsPersonal() then
		self.Limits[limit:GetID()] = limit
	else
		self.Limits[limit:GetID()]:SetOverride(limit)
	end
end

function ENT:RemoveLimit(id,personal)

	if personal then
		if not self.Limits[id]:IsPersonal() and self.Limits[id]:GetOverride() then
			if (self.Limits[id]:GetOverride():GetID() == id) then
				self.Limits[id]:RemoveOverride()
				return
			end
		end
	end

	self.Limits[id] = nil
end

function ENT:GetLimits()
	return self.Limits
end 

function ENT:GetLimit(id)
	return self.Limits[id]
end

function ENT:HasLimit(str)
	if self.Limits[str] then return true end
	return false
end

function ENT:GiveLoadout()
	if self:HasLoadout() then
		self:GetLoadout():Give()
		return true
	end
end

function ENT:SetPrimaryWeapon(weapon)
	self:GetLoadout():SetPrimaryWeapon(weapon)
end

function ENT:SetLoadout(loadout)
	loadout:SetParent(self)
	if self:HasLoadout() and not self:GetLoadout():IsPersonal() then 
		loadout:SetAncestor(self:GetLoadout()) 
	end
	self.Loadout = loadout
end 
 
function ENT:ClearLoadout() 
	self.Loadout = nil
end

function ENT:HasLoadout()
	if self:GetLoadout() then return true else return false end
end

function ENT:GetLoadout()
	return self.Loadout
end