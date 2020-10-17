
local wuma_tab = xlib.makepanel{parent=xgui.null, x=-5, y=6, w=600, h=368}
xgui.addModule("WUMA", wuma_tab, "icon16/keyboard.png", "wuma gui")

local tabNameMap = {
	WUMA_Settings = "Settings",
	WUMA_Restrictions = "Restrictions",
	WUMA_Limits = "Limits",
	WUMA_Loadouts = "Loadouts",
	WUMA_Users = "Users",
}

local function onWUMAInitialized(panel)
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
				local className = WUMA.GUI.PropertySheet:GetActiveTab().m_pPanel.ClassName

				WUMA.OnTabChange(tabNameMap[className] or "Settings")
			end
		end)

		old_SetActiveTab(unpack(tbl))
	end
end
hook.Add("OnWUMAInitialized", "ULXOverrideWUMAGUI", onWUMAInitialized)