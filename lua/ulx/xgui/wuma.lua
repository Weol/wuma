
local wuma_tab = xlib.makepanel{ parent=xgui.null, x=-5, y=6, w=600, h=368 }
xgui.addModule("WUMA", wuma_tab, "icon16/keyboard.png","wuma gui")

local function OnWUMAInitialized(panel)
	panel:SetParent(wuma_tab)
	
	wuma_tab.PerformLayout = function()
		panel:SetPos(-8,7)
		panel:SetSize(wuma_tab:GetWide()+8+8,wuma_tab:GetTall()-3)
		panel.tabScroller:DockMargin( 3, 0, 3, 0 )
	end
	
	panel:SetVisible(true)
	
	wuma_tab:InvalidateLayout()
	panel:InvalidateLayout()
	
	concommand.Remove("wuma")
end
hook.Add("OnWUMAInitialized","ULXOverrideWUMAGUI",OnWUMAInitialized)


