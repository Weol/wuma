
local wuma_tab = xlib.makepanel{ parent=xgui.null, x=-5, y=6, w=600, h=368 }
xgui.addModule("WUMA", wuma_tab, "icon16/keyboard.png", "wuma gui")

local function OnWUMAInitialized(panel)
	panel:SetParent(wuma_tab)

	wuma_tab.PerformLayout = function()
		panel:SetPos(-8, 7)
		panel:SetSize(wuma_tab:GetWide()+8+8, wuma_tab:GetTall()-3)
		panel.tabScroller:DockMargin(3, 0, 3, 0)
	end

	panel:SetShowExitButton(false)

	panel:SetVisible(true)

	wuma_tab:InvalidateLayout()
	panel:InvalidateLayout()

	local old_SetActiveTab = xgui.base.SetActiveTab
	xgui.base.SetActiveTab = function(...)
		local tbl = {...}

		pcall(function()
			if (tbl[2]:GetValue() == "WUMA") then
				WUMA.OnTabChange(WUMA.GUI.ActiveTab or WUMA.GUI.Tabs.Settings.TabName)
			end
		end)

		old_SetActiveTab(unpack(tbl))
	end
end
if WUMA and WUMA.GUI and WUMA.GUI.Base then
	OnWUMAInitialized(WUMA.GUI.PropertySheet)
else
	hook.Add("OnWUMAInitialized", "ULXOverrideWUMAGUI", OnWUMAInitialized)
end
