
local ENT = FindMetaTable("Player")
  
function ENT:CheckLimit(str, WUMA) 

	if (game.SinglePlayer()) then return true end
	
	if (WUMA and self:HasLimit(WUMA)) then
		return self:GetLimit(WUMA):Check()
	elseif (self:HasLimit(str)) then
		return self:GetLimit(str):Check()
	end

	local c = cvars.Number("sbox_max"..str, 0)

	if (c < 0) then return true end
	if (self:GetCount(str) > c-1) then self:LimitHit(str) return false end
	return true

end 
  
function ENT:AddCount(str, ent, WUMA)

	if (WUMA and self:HasLimit(WUMA)) then 
		self:GetLimit(WUMA):Add(ent)
	elseif (self:HasLimit(str)) then
		self:GetLimit(str):Add(ent)
	elseif str then

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

	if (WUMA and self:HasLimit(WUMA)) then 
		local l = self:GetLimit(WUMA):GetCount()
		if (minus > 0) then self:GetLimit(WUMA):Subtract(minus) end
		return l
	elseif self:HasLimit(str) then
		local l = self:GetLimit(str):GetCount()
		if (minus > 0) then self:GetLimit(str):Subtract(minus) end
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

	if self:HasLimit(str) then
		self:GetLimit(str):Hit()
	else
		Limit:GenerateHit(str,self)
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
 
function ENT:CheckRestriction(type,str)

	local key = Restriction:GenerateID(type,_,str)
	
	if self:GetRestrictions()[key] then 
		return self:GetRestrictions()[key](type,str)
	end
end   
 
function ENT:AddRestriction(restriction) 
	if not self.Restrictions then self.Restrictions = {} end

	local key = restriction:GetID(true) 
	restriction:SetParent(self)
	
	if not self:GetRestrictions()[key] then
		self:GetRestrictions()[key] = restriction
	elseif self:GetRestrictions()[key]:IsPersonal() and not restriction:IsPersonal() then
		restriction:SetOverride(self:GetRestrictions()[key])
		self:GetRestrictions()[key] = restriction 
	elseif not self:GetRestrictions()[key]:IsPersonal() and not restriction:IsPersonal() then
		self:GetRestrictions()[key] = limit
	elseif self:GetRestrictions()[key]:IsPersonal() and restriction:IsPersonal() then
		self:GetRestrictions()[key] = limit
	else
		self:GetRestrictions()[key]:SetOverride(restriction)
	end
end 

function ENT:AddRestrictions(tbl)
	for _,object in pairs(tbl) do
		self:AddRestriction(object)
	end
end

function ENT:RemoveRestriction(id,personal) 
	if not id then return end
	
	local restriction = self:GetRestrictions()[id]
	if not restriction then return end
	
	if personal then
		if restriction:IsPersonal() then
			self:GetRestrictions()[id] = nil
		elseif restriction:GetOverride() then
			restriction:RemoveOverride()
		end
	else
		if restriction:GetOverride() then
			local override = self:GetRestrictions()[id]:GetOverride()
			self:GetRestrictions()[id] = override
		else
			self:GetRestrictions()[id] = nil
		end
	end
end

function ENT:GetRestrictions()
	return self.Restrictions or {} 
end
 
function ENT:GetRestriction(type,str)
	if not str then return end
	if (isstring(str) and type and isstring(type)) then 
		local key = Restriction:GenerateID(type,_,str)
		return self:GetRestrictions()[key]
	end  
end 

function ENT:AddLimit(limit)
	if not self.Limits then self.Limits = {} end

	local key = limit:GetID(true)
	limit:SetParent(self)

	if not self:GetLimits()[key] then
		self:GetLimits()[key] = limit
	elseif self:GetLimits()[key]:IsPersonal() and not limit:IsPersonal() then
		limit:SetCount(self:GetLimits()[key]:GetCount())
		
		limit:SetOverride(self:GetLimits()[key])
		self:GetLimits()[key] = limit
	elseif not self:GetLimits()[key]:IsPersonal() and not limit:IsPersonal() then
		self:GetLimits()[key] = limit
	elseif self:GetLimits()[key]:IsPersonal() and limit:IsPersonal() then
		self:GetLimits()[key] = limit
	else
		limit:SetCount(self:GetLimits()[key]:GetCount())
		self:GetLimits()[key]:SetOverride(limit)
	end
end
 
function ENT:RemoveLimit(id,personal)
	local limit = self:GetLimits()[id]
	if not limit then return end
	
	if personal then
		if limit:IsPersonal() then
			self:GetLimits()[id] = nil
		elseif limit:GetOverride() then
			self:GetLimits()[id]:RemoveOverride()
		end
	else
		local override = limit:GetOverride()
		if override then
			self:GetLimits()[id] = override
		else
			self:GetLimits()[id] = nil
		end
	end
end

function ENT:GetLimits()
	return self.Limits or {}
end 

function ENT:GetLimit(str)
	local id = Limit:GenerateID(_,str)
	return self:GetLimits()[id]
end

function ENT:HasLimit(str)
	local id = Limit:GenerateID(_,str)
	if self:GetLimits()[id] then return true end
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
	self:GetLoadout():Give()
end 
 
function ENT:ClearLoadout() 
	if (self.Loadout and self.Loadout:IsPersonal()) then
		if (self.Loadout:GetAncestor()) then
			local ancestor = self.Loadout:GetAncestor()
			
			self.Loadout = ancestor
			
			self.Loadout:Give()
		else
			self.Loadout:Delete()
			self.Loadout = nil
			
			WUMA.GiveDefaultLoadout(self)
		end
	elseif self.Loadout then
		self.Loadout:Delete()
		self.Loadout = nil 
		
		WUMA.GiveDefaultLoadout(self)
	end
end

function ENT:HasLoadout()
	if self:GetLoadout() then return true else return false end
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