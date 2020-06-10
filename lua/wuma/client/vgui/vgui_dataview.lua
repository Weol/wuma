
local PANEL = {}

AccessorFunc(PANEL, "ClassifyFunction", "ClassifyFunction")

function PANEL:Init()
	self.Keys = {}
	self.Groups = {}
	self.DataRegistry = {}
	self.DataSources = {}
end

function PANEL:GetSelectedItems()
	local selected = self:GetSelected()

	local tbl = {}
	for _, v in pairs(selected) do
		table.insert(tbl, v.value)
	end

	return tbl
end

function PANEL:AddViewLine(key)
	if self.Keys[key] then
		local item = self.Keys[key]

		local line = self:AddLine(unpack(item.display))
		line.key = key
		line.group = item.group
		line.value = item.value

		if item.highlight then
			line.mark = true
			if not line.old_paint then
				line.old_paint = line.Paint
				line.Paint = function(panel, w, h)
					line.old_paint(panel, w, h)
					if panel.mark then
						surface.SetDrawColor(item.highlight)
						surface.DrawRect(0, 0, w, h)
					end
				end
			end
		else
			line.mark = nil
		end

		if item.sort then line.Data = item.sort end

		self.DataRegistry[item.group] = self.DataRegistry[item.group] or {}
		self.DataRegistry[item.group][key] = line

		self:OnViewChanged()
	end
end

function PANEL:RemoveViewLine(key)
	if not self.Keys[key] then return end

	local group = self.Keys[key].group

	local line = self.DataRegistry[group] and self.DataRegistry[group][key]

	if line then
		self:RemoveLine(line:GetID())
		self.DataRegistry[group][key] = nil

		self:OnViewChanged()
	end
end

function PANEL:OnViewChanged()

end

function PANEL:OnDataUpdate()

end

function PANEL:Show(key)
	if not istable(key) then key = {key} end

	for group, lines in pairs(self.DataRegistry) do
		if not table.HasValue(key, group) then
			for key, _ in pairs(lines) do
				self:RemoveViewLine(key)
			end
			self.DataRegistry[group]  = nil
		end
	end

	for _, group in pairs(key) do
		if not self.DataRegistry[group] then
			self.DataRegistry[group] = {}
			for key, _ in pairs(self.Groups[group] or {}) do
				self:AddViewLine(key)
			end
		end
	end
end

function PANEL:Sort(key, value)
	local group, display, sort, highlight = self.ClassifyFunction(value)

	self.Groups[group] = self.Groups[group] or {}
	self.Groups[group][key] = true

	self.Keys[key] = {
		value = value,
		group = group,
		display = display,
		sort = sort,
		highlight = highlight,
	}

	return group, display, sort
end

function PANEL:SortAll()
	self.Groups = {}
	self.Keys = {}

	for id, source in pairs(self:GetDataSources()) do
		for k, v in pairs(source) do
			self:Sort(id .. "_" .. k, v)
		end
	end
end

function PANEL:AddDataSource(id, source)
	if self.DataSources[id] ~= source then
		local keys = table.GetKeys(source)

		self.DataSources[id] = source

		self:UpdateDataSource(id, source, keys)
	end
end

function PANEL:GetDataSources()
	return self.DataSources
end

function PANEL:UpdateDataSource(id, updated, deleted)
	for key, value in pairs(updated) do
		key = id .. "_" .. key

		local group, display, sort = self:Sort(key, value)

		if self.DataRegistry[group] and self.DataRegistry[group][key] then
			local line = self.DataRegistry[group][key]

			for k, v in pairs(display) do
				line:SetColumnText(k, v)
			end
			line.Data = sort or {}

			self:InvalidateLayout()
		elseif self.DataRegistry[group] then
			self:AddViewLine(key)
		end
	end

	for _, key in pairs(deleted) do
		key = id .. "_" .. key

		if self.Keys[key] and self.DataRegistry[self.Keys[key].group] and self.DataRegistry[self.Keys[key].group][key] then
			self:RemoveViewLine(key)
		end
	end

	self:OnDataUpdate()
end

vgui.Register("WListView", PANEL, 'DListView');