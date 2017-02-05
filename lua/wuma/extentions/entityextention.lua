
local ENT = FindMetaTable("Entity")
local self = ENT

function ENT:AddWUMAParent(limit)
	self.WUMAParents = self.WUMAParents or {}
	table.insert(self.WUMAParents,limit)
	self:CallOnRemove("NotifyWUMAParents", function(ent) ent:NotifyWUMAParents() end)
end

function ENT:GetWUMAParents()
	return self.WUMAParents
end

function ENT:NotifyWUMAParents() 
	for _,parent in pairs(self:GetWUMAParents()) do 
		parent:Subtract()
	end
end