
local ENT = FindMetaTable("Entity")
local self = ENT

ENT.WUMAParents = {}

function ENT:AddWUMAParent(user)
	table.insert(self.WUMAParents,entity)
end

function ENT:GetWUMAParents()
	return self.WUMAParents
end
