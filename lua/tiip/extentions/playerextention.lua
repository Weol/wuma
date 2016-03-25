
local ENT = FindMetaTable("Player")
local self = ENT

ENT.Restrictions = {}
ENT.Limits = {}

function ENT:CheckLimit( str, tiip ) 
	
	TIIPDebug("Checklimit(%s,%s)",str or "_",tiip or "_")
	
	if (game.SinglePlayer()) then return true end
	
	if tiip then 
		if (self:HasLimit(tiip)) then
			return self:GetLimit(tiip):Check()
		end

		local c = cvars.Number( "sbox_max"..str, 0 )
	
		if ( c < 0 ) then return true end
		if ( self:GetCount( str ) > c-1 ) then self:LimitHit( str ) return false end
		return true
	end
	
	return true

end

function ENT:AddCount( str, ent, tiip )
 
	TIIPDebug("AddCount(%s,%s,%s)",str or "_",tostring(ent) or "_",tiip or "_")

	if (tiip and self:HasLimit(tiip)) then
		self:GetLimit(tiip):Add(ent)
	else

		if ( SERVER ) then

			local key = self:UniqueID()
			g_SBoxObjects[ key ] = g_SBoxObjects[ key ] or {}
			g_SBoxObjects[ key ][ str ] = g_SBoxObjects[ key ][ str ] or {}
			
			local tab = g_SBoxObjects[ key ][ str ]
			
			table.insert( tab, ent )
			
			-- Update count (for client)
			self:GetCount( str )
			
			ent:CallOnRemove( "GetCountUpdate", function( ent, ply, str ) ply:GetCount(str, 1) end, self, str )
		
		end
	
	end
		
	
end

function ENT:GetCount( str, minus, tiip )

	TIIPDebug("GetCount(%s,%s,%s)",str or "_",tostring(minus) or "_",tiip or "_")

	if (tiip and self:HasLimit(tiip)) then 
		local l = self:GetLimit(tiip):GetCount()
		if (minus > 0) then self:GetLimit(tiip):Subtract(minus) end
		return l
	else
		
		if ( CLIENT ) then
			return self:GetNetworkedInt( "Count."..str, 0 )
		end
		
		minus = minus or 0
		
		if ( !self:IsValid() ) then return end

		local key = self:UniqueID()
		local tab = g_SBoxObjects[ key ]
		
		if ( !tab || !tab[ str ] ) then 
		
			self:SetNetworkedInt( "Count."..str, 0 )
			return 0 
			
		end
		
		local c = 0

		for k, v in pairs ( tab[ str ] ) do
		
			if ( v:IsValid() ) then 
				c = c + 1
			else
				tab[ str ][ k ] = nil
			end
		
		end
		
		self:SetNetworkedInt( "Count."..str, c - minus )

		return c
			
	end
	
end

function ENT:LimitHit( str )

	TIIPDebug("LimitHit(%s)",str or "_")

	if not self:HasLimit(str) then
		Limit:GenerateHit(str,self)
	else
		self:GetLimit(str):Hit()
	end

end

function ENT:Check(type,str) 
	if (self:CheckRestriction(type,str) == false) then 
		return false 
	elseif (self:CheckLimit(st) == false) then
		return false
	end
	return
end
 
function ENT:CheckRestriction(type,str)
	local key = Restriction:GenerateID(type,str)
	 
	if not self.Restrictions[key] then return end
	
	return self.Restrictions[key](type,str)
end 
 
function ENT:AddRestriction(object) 
	local key = object:GetID() 
	
	object:SetParent(self)
	
	self.Restrictions[key] = object
end

function ENT:AddRestrictions(tbl)
	for _,object in pairs(tbl) do
		self:AddRestriction(object)
	end
end

function ENT:RemoveRestriction(id) 
	if not id then return end

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

function ENT:RefreshGroupRestrictions()
	for k,v in pairs(self:GetRestrictions()) do
		if v:GetUsergroup() then
			self:RemoveRestriction(v:GetID())
	 	end
	end
	
	TIIP.AssignRestrictions(self)
end

function ENT:AddLimit(limit)
	limit:SetParent(self)
	self.Limits[limit:GetID()] = limit
end

function ENT:RemoveLimit(id)
	self.Limits[id] = nil
end

function ENT:GetLimits()
	return self.Limits
end 

function ENT:GetLimit(id)
	return self.Limits[id]
end

function ENT:HasLimit(str)
	Msg("HasLimit("..str..")\n")
	if self.Limits[str] then return true end
	Msg("HasLimit("..str..") false\n")
	return false
end

function ENT:SetLoadout(loadout)

end

function ENT:DeleteLoadout()

end

function ENT:GetLoadout()

end