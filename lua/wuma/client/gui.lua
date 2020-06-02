
WUMA.GUI = {}
WUMA.GUI.Tabs = {}

if not WUMA.HasCreatedFonts then
	surface.CreateFont("WUMATextSmall", {
		font = "Arial",
		size = 10,
		weight = 700,
		blursize = 0,
		scanlines = 0,
		antialias = true
	})
end
WUMA.HasCreatedFonts = true

WUMA.Subscriptions = {}
WUMA.Subscriptions.user = {}
WUMA.Subscriptions.timers = {}

function WUMA.GUI.Initialize()

	--Create EditablePanel
	WUMA.GUI.Base = vgui.Create("EditablePanel")
	WUMA.GUI.Base:SetSize(ScrW()*0.40, ScrH()*0.44)
	WUMA.GUI.Base:SetPos(ScrW()/2-WUMA.GUI.Base:GetWide()/2, ScrH()/2-WUMA.GUI.Base:GetTall()/2)
	WUMA.GUI.Base:SetVisible(false)

	--Create propertysheet
	WUMA.GUI.PropertySheet = vgui.Create("WPropertySheet", WUMA.GUI.Base)
	WUMA.GUI.PropertySheet:SetSize(WUMA.GUI.Base:GetSize())
	WUMA.GUI.PropertySheet:SetPos(0, 0)
	WUMA.GUI.PropertySheet:SetShowExitButton(true)

	--Request panels
	WUMA.GUI.SettingsTabs = vgui.Create("WUMA_Settings", WUMA.GUI.PropertySheet) --Settings
	WUMA.GUI.RestrictionsTabs = vgui.Create("WUMA_Restrictions", WUMA.GUI.PropertySheet) --Restriction
	WUMA.GUI.LimitsTabs = vgui.Create("WUMA_Limits", WUMA.GUI.PropertySheet) --Limit
	WUMA.GUI.LoadoutsTabs = vgui.Create("WUMA_Loadouts", WUMA.GUI.PropertySheet) --Loadouts
	WUMA.GUI.UsersTabs = vgui.Create("WUMA_Users", WUMA.GUI.PropertySheet) --Users

	WUMA.GUI.PropertySheet.OnTabChange = WUMA.OnTabChange

	--Adding panels to PropertySheet
	WUMA.GUI.PropertySheet:AddSheet("Settings", WUMA.GUI.SettingsTabs, "icon16/shield.png") --Settings
	WUMA.GUI.PropertySheet:AddSheet("Restrictions", WUMA.GUI.RestrictionsTabs, WUMA.GUI.RestrictionsTabs.TabIcon) --Restriction
	WUMA.GUI.PropertySheet:AddSheet("Limits", WUMA.GUI.LimitsTabs, WUMA.GUI.LimitsTabs.TabIcon) --Limit
	WUMA.GUI.PropertySheet:AddSheet("Loadouts", WUMA.GUI.LoadoutsTabs, WUMA.GUI.LoadoutsTabs.TabIcon) --Loadout
	WUMA.GUI.PropertySheet:AddSheet("Users", WUMA.GUI.UsersTabs, WUMA.GUI.UsersTabs.TabIcon) --Player

	--Setting datatables
	WUMA.GUI.RestrictionsTabs:GetDataView():SetDataSource(function() return WUMA.Restrictions end)
	WUMA.GUI.LimitsTabs:GetDataView():SetDataSource(function() return WUMA.Limits end)
	WUMA.GUI.LoadoutsTabs:GetDataView():SetDataSource(function() return WUMA.LoadoutWeapons end)
	WUMA.GUI.UsersTabs:GetDataView():SetDataSource(function() return WUMA.LookupUsers end)

	--Adding data update hooks
	hook.Add(WUMA.RESTRICTIONUPDATE, "WUMARestrictionDataUpdate", function(update) WUMA.GUI.RestrictionsTabs:GetDataView():UpdateDataTable(update) end) --Restriction
	hook.Add(WUMA.LIMITUPDATE, "WUMALimitDataUpdate", function(update) WUMA.GUI.LimitsTabs:GetDataView():UpdateDataTable(update) end) --Limits
	hook.Add(WUMA.LOADOUTUPDATE, "WUMALoadoutDataUpdate", function(update) WUMA.GUI.LoadoutsTabs:GetDataView():UpdateDataTable(update) end) --Loadouts

	WUMA.GUI.UsersTabs.OnExtraChange = WUMA.OnUserTabChange

	hook.Call("OnWUMAInitialized", _, WUMA.GUI.PropertySheet)

end
hook.Add("InitPostEntity", "WUMAGuiInitialize", function() timer.Simple(2, WUMA.GUI.Initialize) end)

function WUMA.GUI.Show()
	if not table.IsEmpty(WUMA.GUI.Base:GetChildren()) then
		WUMA.OnTabChange(WUMA.GUI.ActiveTab or WUMA.GUI.SettingsTabs.TabName)

		WUMA.GUI.Base:SetVisible(true)
		WUMA.GUI.Base:MakePopup()
	end
end

function WUMA.GUI.Hide()
	if not table.IsEmpty(WUMA.GUI.Base:GetChildren()) then
		WUMA.GUI.Base:SetVisible(false)
	end
end

function WUMA.GUI.Toggle()
	if WUMA.GUI.Base:IsVisible() then
		WUMA.GUI.Hide()
	else
		WUMA.GUI.Show()
	end
end

function WUMA.OnTabChange(_, tabname)

	if not WUMA.Subscriptions.info then
		WUMA.RequestFromServer("settings")
		WUMA.RequestFromServer("inheritance")
		WUMA.RequestFromServer("groups")
		WUMA.RequestFromServer("users")
		WUMA.RequestFromServer("maps")

		WUMA.Subscriptions.info = true
	end

	if (tabname == WUMA.GUI.RestrictionsTabs.TabName and not WUMA.Subscriptions.restrictions) then
		WUMA.FetchData(Restriction:GetID())
	elseif (tabname == WUMA.GUI.LimitsTabs.TabName and not WUMA.Subscriptions.limits) then
		WUMA.FetchData(Limit:GetID())
	elseif (tabname == WUMA.GUI.LoadoutsTabs.TabName and not WUMA.Subscriptions.loadouts) then
		WUMA.FetchData(Loadout:GetID())
	elseif (tabname == WUMA.GUI.UsersTabs.TabName and not WUMA.Subscriptions.users) then
		WUMA.RequestFromServer("lookup", 50)

		WUMA.Subscriptions.users = true
	end

	WUMA.GUI.ActiveTab = tabname

end

function WUMA.OnUserTabChange(_, typ, steamid)
	if (typ ~= "default") and not WUMA.Subscriptions.user[steamid] then
		WUMA.Subscriptions.user[steamid] = {}
	end

	if (typ == "default") then
		local timeout = GetConVar("wuma_autounsubscribe_user"):GetInt()

		if timeout and (timeout >= 0) and WUMA.Subscriptions.user[steamid] then
			for k, _ in pairs(WUMA.Subscriptions.user[steamid]) do
				timer.Create(k..":::"..steamid, timeout, 1, function() WUMA.FlushUserData(steamid, k) end)
			end
		end
	else
		WUMA.FetchUserData(typ, steamid)
	end
end

WUMA.GUI.HookIDs = 1
function WUMA.GUI.AddHook(h, name, func)
	hook.Add(h, name..WUMA.GUI.HookIDs, func)
	WUMA.GUI.HookIDs = WUMA.GUI.HookIDs + 1
end

function WUMA.GUI.CreateLoadoutSelector()
	local frame = vgui.Create("DFrame")
	frame:SetSize(ScrW()*0.40, ScrH()*0.44)
	frame:SetPos(ScrW()/2-frame:GetWide()/2, ScrH()/2-frame:GetTall()/2)
	frame:SetTitle("Select your loadout")

	frame.OnClose = function()
		WUMA.Unsubscribe("restrictions", LocalPlayer():SteamID())
		WUMA.Unsubscribe("loadouts", LocalPlayer():SteamID())
	end

	frame.Paint = function()
		draw.RoundedBox(5, 0, 0, frame:GetWide(), frame:GetTall(), Color(59, 59, 59, 255))
		draw.RoundedBox(5, 1, 1, frame:GetWide() - 2, frame:GetTall() - 2, Color(226, 226, 226, 255))

		draw.RoundedBox(5, 1, 1, frame:GetWide()-2, 25-1, Color(163, 165, 169, 255))
		surface.SetDrawColor(Color(163, 165, 169, 255))
		surface.DrawRect(1, 10, frame:GetWide()- 2, 15)
	end

	local loadout = vgui.Create("WUMA_PersonalLoadout", frame)
	loadout:Dock(TOP)
	loadout:SetWide(frame:GetWide())
	loadout:SetTall(frame:GetTall()-35)

	WUMA.Subscribe("loadouts", LocalPlayer():SteamID(), function(updated, deleted)
		loadout:GetDataView():UpdateData(updated)
		loadout:GetDataView():DeleteData(deleted)
	end)

	WUMA.Subscribe("restrictions", LocalPlayer():SteamID(), function(updated, deleted)
		loadout:GetDataView():UpdateData(updated)
		loadout:GetDataView():DeleteData(deleted)
	end)

	hook.Add(WUMA.PERSONALLOADOUTRESTRICTIONSUPDATE, "WUMAPersonalLoadoutRestrictionsUpdate", function(user, update)
		local weapons = WUMA.GetWeapons()

		for key, class in pairs(weapons) do
			if (WUMA.PersonalRestrictions["swep_" .. class]) then weapons[key] = nil end
		end

		loadout.weapons = weapons
		loadout:ReloadSuggestions()
	end)

	loadout:GetDataView():Show(LocalPlayer():SteamID())

	frame:MakePopup()
	frame:SetVisible(true)

	WUMA.kek = loadout
end
