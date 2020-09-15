
local PANEL = {}

AccessorFunc(PANEL, "ClassifyFunction", "ClassifyFunction")
AccessorFunc(PANEL, "SortGroupingFunction", "SortGroupingFunction")
AccessorFunc(PANEL, "FilterFunction", "FilterFunction")
AccessorFunc(PANEL, "Footer", "Footer")
AccessorFunc(PANEL, "Groups", "Groups")
AccessorFunc(PANEL, "Keys", "Keys")

function PANEL:Init()
	self.Keys = {}
	self.Groups = {}
	self.DataRegistry = {}
	self.DataSources = {}

	self.Headers = {}

	local parent = self
	while (parent:GetParent():GetClassName() ~= "CGModBase") do
		parent = parent:GetParent()
	end

	self.hover_panel = vgui.Create("DPanel", parent)
	self.hover_panel:SetVisible(false)

	self.hover_label = vgui.Create("DLabel", self.hover_panel)
	self.hover_label:SetTextColor(Color(0, 0, 0))
	self.hover_label:SetZPos(32767)

	function self.hover_panel:Paint(w, h)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(0, 0, 0, 255)
		surface.DrawOutlinedRect(0, 0, w, h)
	end

	local padding = 5
	local label = self.hover_label
	function self.hover_panel:PerformLayout(_, _)
		label:SizeToContents()

		self:SetSize(label:GetWide() + padding * 2, label:GetTall() + padding * 2)

		label:SetPos(padding, padding)
	end

	self.pnlCanvas.Paint = function(_, w, _)
		for _, header in pairs(self.Headers) do
			local start_y, end_y, title = unpack(header)

			surface.SetDrawColor(82, 82, 82, 255)

			if (start_y > 0) then
				surface.DrawLine(0, start_y, w, start_y)
			end

			surface.DrawLine(0, end_y - 1, w, end_y - 1)

			surface.SetFont("WUMAText")
			surface.SetTextColor(0, 0, 0, 255)

			local text_W, text_h = surface.GetTextSize(title)

			surface.SetTextPos(w / 2 - text_W / 2, start_y + (end_y - start_y) / 2 - text_h / 2)
			surface.DrawText(title)
		end
	end
end

local material_cache = {}
function PANEL:AddViewLine(key)
	local item = self.Keys[key]

	if self.Keys[key] and self:Filter(item.value) then
		local line = self:AddLine(unpack(item.display))
		line.key = key
		line.group = item.group
		line.value = item.value

		line.old_Paint = line.old_Paint or line.Paint or function() end
		line.Paint = function(_, w, h)
			line:old_Paint(w, h)
			if self.Keys[key].highlight then
				surface.SetDrawColor(self.Keys[key].highlight)
				surface.DrawRect(0, 0, w, h)
			end

			local icon = self.Keys[key].icon
			if icon then
				if not material_cache[icon[1]] then
					material_cache[icon[1]] = Material(icon[1], "noclamp smooth" )
				end
				local material = material_cache[icon[1]]

				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetMaterial(material)

				local size = h - 3
				surface.DrawTexturedRect(w - size - (h - size) / 2, h / 2 - size / 2, size, size)
			end
		end

		line.old_PerformLayout = line.old_PerformLayout or line.PerformLayout or function() end
		line.PerformLayout = function(_, w, h)
			line:old_PerformLayout(w, h)
			if self.Keys[key].icon then
				local col = line.Columns[#line.Columns]

				local size = h - 3
				local actual = line:GetListView().Columns[#line:GetListView().Columns]:GetWide()
				col:SetWide(actual - size - 3)
			else
				local col = line.Columns[#line.Columns]

				local actual = line:GetListView().Columns[#line:GetListView().Columns]:GetWide()
				col:SetWide(actual)
			end
		end

		line.old_OnCursorMoved = line.old_OnCursorMoved or line.OnCursorMoved or function() end
		line.OnCursorMoved = function(_, x, y)
			line:old_OnCursorMoved(x, y)

			local size = line:GetTall() - 3
			local icon = self.Keys[key].icon

			if icon and (x > line:GetWide() - size - 3) then
				self.hover_label:SetText(icon[2])

				local g_x, g_y = line:LocalToScreen(x, y)
				local a_x, a_y = self.hover_panel:GetParent():ScreenToLocal(g_x - self.hover_panel:GetWide() / 2, g_y - self.hover_panel:GetTall() - 2)

				a_x = math.Clamp(a_x, 2, self.hover_panel:GetParent():GetWide() - self.hover_panel:GetWide() - 2)
				a_y = math.Clamp(a_y, 2, self.hover_panel:GetParent():GetTall() - self.hover_panel:GetTall() - 2)

				self.hover_panel:SetPos(a_x, a_y)
				self.hover_panel:SetVisible(true)

				self.hover_panel.target = line
			elseif (self.hover_panel:IsVisible() and self.hover_panel.target == line) then
				self.hover_panel:SetVisible(false)
				self.hover_panel.target = nil
			end
		end

		line.old_OnCursorExited = line.old_OnCursorExited or line.OnCursorExited or function() end
		line.OnCursorExited = function()
			line:old_OnCursorExited()

			if (self.hover_panel:IsVisible() and self.hover_panel.target == line) then
				self.hover_panel:SetVisible(false)
				self.hover_panel.target = nil
			end
		end

		if item.sort then line.Data = item.sort end

		self.DataRegistry[item.group] = self.DataRegistry[item.group] or {}
		self.DataRegistry[item.group][key] = line

		if item.post_process then item.post_process(line) end

		self:OnViewChanged()
	end
end

function PANEL:SetFilterFunction(f)
	self.FilterFunction = f

	for group, lines in pairs(self.DataRegistry) do
		for key, line in pairs(lines) do
			if not self:Filter(line.value) then
				self:RemoveViewLine(key)
			end
		end
	end
end

function PANEL:Filter(item)
	if self.FilterFunction then
		return self.FilterFunction(item)
	end
	return true
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

function PANEL:SortByColumn(column_id, desc)
	local grouper = self:GetSortGroupingFunction()

	table.Copy(self.Sorted, self.Lines)

	table.sort(self.Sorted, function(a, b)
		if grouper then
			local a_index, a_title = grouper(a.value)
			local b_index, b_title = grouper(b.value)

			a.sort_index = a_index
			a.sort_title = a_title

			b.sort_index = b_index
			b.sort_title = b_title

			if a_index ~= b_index then
				return a_index < b_index
			end
		end

		local a_val = a:GetSortValue(column_id) or a:GetColumnText(column_id)
		local b_val = b:GetSortValue(column_id) or b:GetColumnText(column_id)

		if (desc) then
			a_val, b_val = b_val, a_val
		end

		return a_val < b_val
	end)

	self:SetDirty(true)
	self:InvalidateLayout()
end

function PANEL:SetFooter(panel)
	panel:SetParent(self.pnlCanvas)
	self.Footer = panel
end

function PANEL:DataLayout()
	local y = 0
	local h = self.m_iDataHeight

	self.Headers = {}

	local last_index
	for k, line in ipairs(self.Sorted) do
		line:SetSize(self:GetWide() - 2, h)

		if (line.sort_index ~= last_index) and line.sort_title then
			table.insert(self.Headers, {y, y + line:GetTall() + 4, line.sort_title})

			y = y + line:GetTall() + 4
		end

		line:SetPos(1, y)
		line:DataLayout( self )

		line:SetAltLine(k % 2 == 1)

		y = y + line:GetTall()

		last_index = line.sort_index
	end

	local footer = self:GetFooter()
	if footer then
		footer:SetPos(1, y)
		footer:SetSize(self:GetWide() - 2)
		footer:SizeToContentsY()

		y = y + footer:GetTall() + 1
	end

	return y
end

function PANEL:GetSelectedItems()
	local selected = self:GetSelected()

	local tbl = {}
	for _, v in pairs(selected) do
		table.insert(tbl, v.value)
	end

	return tbl
end

function PANEL:OnRowSelected(_, line)
	self:OnItemSelected(line.value)
end

--luacheck: push no unused args
function PANEL:OnItemSelected(item)
	--For override
end
--luacheck: pop

function PANEL:OnViewChanged()
	--For override
end

function PANEL:OnDataUpdate()
	--For override
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
	self:DataLayout()
end

function PANEL:Sort(key, value)
	local group, display, sort, highlight, icon = self.ClassifyFunction(value)

	self.Groups[group] = self.Groups[group] or {}
	self.Groups[group][key] = true

	self.Keys[key] = {
		value = value,
		group = group,
		display = display,
		sort = sort,
		highlight = highlight,
		icon = icon
	}

	return group, display, sort, highlight
end

function PANEL:FilterAll()
	self:SetFilterFunction(self:GetFilterFunction())
end

function PANEL:ReSort(id, k)
	local key = id .. "_" .. k

	if self.Keys[key] then
		self:Sort(id .. "_" .. k, self.Keys[key].value)
	end
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
		self.DataSources[id] = source

		self:UpdateDataSource(id, source, {})
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
			if not self:Filter(value) then
				self:RemoveViewLine(key)
			else
				local line = self.DataRegistry[group][key]

				for k, v in pairs(display) do
					line:SetColumnText(k, v)
				end
				line.Data = sort or {}

				line:InvalidateLayout()
			end
		elseif self.DataRegistry[group] then
			self:AddViewLine(key)
		end
	end

	for _, key in pairs(deleted) do
		key = id .. "_" .. key

		if self.Keys[key] and self.DataRegistry[self.Keys[key].group] and self.DataRegistry[self.Keys[key].group][key] then
			self:RemoveViewLine(key)

			local group = self.Keys[key].group

			self.Keys[key] = nil
			if self.Groups[group] then self.Groups[group][key] = nil end
		end
	end

	self:InvalidateLayout()
	self:OnDataUpdate()
end

vgui.Register("WListView", PANEL, 'DListView');