urm = urm or {}
if not urm.loaded then 
	urm.load_list = urm.load_list or {}
	table.insert(urm.load_list,"xgui_loadouts.lua")
	return
end

urm.loadouts = {}

urm.loadouts.panel = xlib.makepanel{ parent=xgui.null }
urm.loadouts.addbutton = xlib.makebutton{ parent=urm.loadouts.panel, x=445, y=241, w=62, h=25, label="Add", disabled=false }
urm.loadouts.deletebutton = xlib.makebutton{ parent=urm.loadouts.panel, x=513, y=241, w=62, h=25, label="Delete", disabled=false }
urm.loadouts.editbutton = xlib.makebutton{ parent=urm.loadouts.panel, x=445, y=271, w=130, h=25, label="Edit", disabled=false }
urm.loadouts.primarybutton = xlib.makebutton{ parent=urm.loadouts.panel, x=445, y=300, w=130, h=25, label="Set Primary", disabled=false }

urm.loadouts.search = xlib.maketextbox{x=445, y=5, w=130, h=25, text="Search...", parent=urm.loadouts.panel, selectall=true, disabled=false,enableinput=true }
urm.setDefaultTextboxText(urm.loadouts.search,"Search...")

urm.loadouts.primarylabel = xlib.makelabel{ x=5, y=5,w = 100, label="Primary Ammo", decimal = 0, default = 200, font = "DermaDefaultBold", parent=urm.loadouts.panel }
urm.loadouts.primaryslider = xlib.makeslider{ x=5, y=20, w=100, min=0, max=1000, parent=urm.loadouts.panel }

urm.loadouts.secondarylabel = xlib.makelabel{ x=5, y=45,w = 100, label="Secondary Ammo", decimal = 0, default = 200, font = "DermaDefaultBold", parent=urm.loadouts.panel }
urm.loadouts.secondaryslider = xlib.makeslider{ x=5, y=60, w=100, min=0, max=1000, parent=urm.loadouts.panel }

urm.loadouts.suggestionlist = xlib.makelistview{ parent=urm.loadouts.panel, x=445, y=35, w=130, h=201, multiselect=true }
urm.loadouts.grouplist = xlib.makelistview{ parent=urm.loadouts.panel, x=5, y=85, w=100, h=210, multiselect=true }

urm.loadouts.setloadoutbutton = xlib.makebutton{ parent=urm.loadouts.panel, x=5, y=300, w=100, h=25, label="Set to...", disabled=false }

urm.loadouts.itemlist = xlib.makelistview{ parent=urm.loadouts.panel, x=110, y=5, w=330, h=320, multiselect=true }

function urm.loadouts.Initialize()
	urm.loadouts.PopulateMenus()
end
  
function urm.loadouts.PopulateMenus()

	--Populating the groups type list
	urm.loadouts.grouplist:AddColumn("Usergroup")
	for k, v in pairs(xgui.data.groups) do
		urm.loadouts.grouplist:AddLine( v ) 
	end
	urm.loadouts.grouplist:SelectFirstItem()
	urm.loadouts.grouplist:SetSortable(false)
	
	urm.loadouts.suggestionlist:AddColumn("Weapons")
	for k,v in pairs(urm.weapons) do
		urm.loadouts.suggestionlist:AddLine(v)
	end

	urm.loadouts.search:SetEditable(true)
	
	urm.loadouts.primaryslider:SetValue(200)
	urm.loadouts.secondaryslider:SetValue(10)
	
	--Populating item list
	urm.loadouts.itemlist:AddColumn("Usergroup")
	urm.loadouts.itemlist:AddColumn("Item")
	urm.loadouts.itemlist:AddColumn("Primary")
	urm.loadouts.itemlist:AddColumn("Secondary")
	urm.loadouts.itemlist:SetSortable(false)
	
end

function urm.loadouts.reloadsuggestions()
	urm.loadouts.suggestionlist:Clear()
	for k,v in pairs(urm.weapons) do
		urm.loadouts.suggestionlist:AddLine(v)
	end
	urm.loadouts.suggestionlist.VBar:AnimateTo( 0, 0.1, 0, 1 )
end

function urm.loadouts.reloaditems()
	if not urm.loadouts.grouplist:GetSelected()[1] then return end
	urm.loadouts.itemlist:Clear()
	for k,usergroup in pairs(urm.loadouts.grouplist:GetSelected()) do 
		usergroup = usergroup:GetValue(1)
		local usergroup_table = xgui.data.URMLoadouts[usergroup]
		if usergroup_table then  
			for item,state in pairs(usergroup_table) do
				local line = urm.loadouts.itemlist:AddLine( usergroup,item,state.primary,state.secondary ) 
				if state.spawn then
					local old_paint = line.Paint
					line.Paint = function(...)
						old_paint(unpack({...}))
						surface.SetDrawColor( 0, 255, 0, 100)
						surface.DrawRect(0 , 0, line:GetWide(),line:GetTall() )
					end
				end
			end 
		end
	end
	urm.loadouts.itemlist.OnRowSelected()
end

function urm.loadouts.contains(usergroup,str)
	if xgui.data.URMLoadouts then
		if xgui.data.URMLoadouts[usergroup] then
			if xgui.data.URMLoadouts[usergroup][str] then
				return true
			end
		end
	end
	return false
end

urm.loadouts.editbutton.disabledtbl = {}
function urm.loadouts.editbutton.addDisabledEntry(id,value)
	urm.loadouts.editbutton.disabledtbl[id] = value
	for k,v in pairs(urm.loadouts.editbutton.disabledtbl) do
		if v then
			urm.loadouts.editbutton:SetDisabled(true)
			return
		end
	end
	urm.loadouts.editbutton:SetDisabled(false)
end

urm.loadouts.search.OnTextChanged = function()
	urm.loadouts.reloadsuggestions()
	for k, v in pairs(urm.loadouts.suggestionlist:GetLines()) do
		local text = urm.loadouts.search:GetValue()
		local item = v:GetValue(1)
		if not string.match(item,text) then
			urm.loadouts.suggestionlist:RemoveLine(k)
		end
	end
end

urm.loadouts.itemlist.OnRowSelected = function( self, lineid, line )
	if (#urm.loadouts.itemlist:GetSelected() > 1) then
		urm.loadouts.editbutton.addDisabledEntry("itemlist",true)
	else
		urm.loadouts.editbutton.addDisabledEntry("itemlist",false)
	end
	
	if not (#urm.loadouts.itemlist:GetSelected() == 1) then
		urm.loadouts.primarybutton:SetDisabled(true)
	else
		urm.loadouts.primarybutton:SetDisabled(false)
	end
end

urm.loadouts.grouplist.OnRowSelected = function( self, lineid, line )
	urm.loadouts.reloaditems()
end

urm.loadouts.suggestionlist.OnRowSelected = function( self, lineid, line )
	if (#urm.loadouts.suggestionlist:GetSelected() > 1) then
		urm.loadouts.editbutton.addDisabledEntry("suggestionlist",true)
	else
		urm.loadouts.editbutton.addDisabledEntry("suggestionlist",false)
	end
end

function urm.loadouts.add(usergroups,strings,primary,secondary,silent)
	primary = primary or 200
	secondary = secondary or 200
	silent = silent or 0
	
	if (string.lower(type(usergroups)) == "string") then usergroups = {groups} end
	if (string.lower(type(strings)) == "string") then strings = {strings} end
	
	if (#usergroups > 0) and (#strings > 0) then
		URM.SendCommand("ulx addloadout",string.Implode(",",usergroups),string.Implode(",",strings),primary,secondary,silent)
	end
end

urm.loadouts.addbutton.DoClick = function()
	local usergroups = {}
	local strings = {}
	local primary = urm.loadouts.primaryslider:GetValue()
	local secondary = urm.loadouts.secondaryslider:GetValue()
	for k,usergroup in pairs(urm.loadouts.grouplist:GetSelected()) do
		usergroup = usergroup:GetValue(1)
		table.insert(usergroups,usergroup)
		for k,v in pairs(urm.loadouts.suggestionlist:GetSelected()) do
			str = v:GetValue(1)
			if not urm.loadouts.contains(usergroup,str) then
				if not table.HasValue(strings,str) then
					table.insert(strings,str)
				end
			else
				ULib.tsayError( LocalPlayer(), string.format("\"%s\" already has a \"%s\"  limit.", usergroup, str), true )
			end
		end
	end

	urm.loadouts.add(usergroups,strings,primary,secondary)
end

function urm.loadouts.delete(usergroups,strings,silent)
	silent = silent or 0
	
	if (string.lower(type(usergroups)) == "string") then usergroups = {usergroups} end
	if (string.lower(type(strings)) == "string") then strings = {strings} end
	
	if (#usergroups > 0) and (#strings > 0) then
		URM.SendCommand("ulx removeloadout",string.Implode(",",usergroups),string.Implode(",",strings),silent)
	end
end

urm.loadouts.deletebutton.DoClick = function()
	local usergroups = {}
	local strings = {}
	for k,v in pairs(urm.loadouts.itemlist:GetSelected()) do
		local usergroup = v:GetValue(1)
		if not table.HasValue(usergroups,usergroup) then
			table.insert(usergroups,usergroup)
		end
		local str = v:GetValue(2)
		if urm.loadouts.contains(usergroup,str) then
			if not table.HasValue(strings,str) then
				table.insert(strings,str)
			end
		else
			ULib.tsayError( LocalPlayer(), string.format("\"%s\" does not have a \"%s\" limit.", usergroup, str ), true )
		end
	end
	
	urm.loadouts.delete(usergroups,strings)
end

urm.loadouts.editbutton.DoClick = function()
	if not urm.loadouts.itemlist:GetSelected()[1] then
		ULib.tsayError( LocalPlayer(), "Please select an item to edit", true )
		return
	end
	local usergroup = urm.loadouts.itemlist:GetSelected()[1]:GetValue(1)
	local str = urm.loadouts.itemlist:GetSelected()[1]:GetValue(2)
	local primary = urm.loadouts.primaryslider:GetValue()
	local secondary = urm.loadouts.secondaryslider:GetValue()
	LocalPlayer():ConCommand(string.format("ulx addloadout \"%s\" \"%s\" \"%i\" \"%i\" \"%s\"",usergroup,str,primary, secondary,"1"))
end

urm.loadouts.primarybutton.DoClick = function()
	if not urm.loadouts.itemlist:GetSelected() then return end
	if (table.Count(urm.loadouts.itemlist:GetSelected()) != 1) then return end
	if not urm.loadouts.itemlist:GetSelected()[1] then return end
	
	local usergroups = {}
	for k, v in pairs(urm.loadouts.grouplist:GetSelected()) do
		table.insert(usergroups,v:GetValue(1))
	end
	
	URM.SendCommand("ulx setprimary",string.Implode(",",usergroups),urm.loadouts.itemlist:GetSelected()[1]:GetValue(2),1)
end

urm.loadouts.setloadoutbutton.DoClick = function()
	local frame = vgui.Create("DFrame")
	frame:SetSize(300,200)
	frame:SetPos(ScrW()/2-frame:GetWide()/2,ScrH()/2-frame:GetTall()/2)
	frame:SetTitle("Set to...")
	frame:SetDeleteOnClose(true)
	local paint = frame.Paint
	frame.Paint = function()
		paint(frame,frame:GetSize())
		
		surface.SetFont("DermaDefault")
		surface.SetTextColor( 0, 0, 0, 255 )
		
		local line1, line2, line3 = "This will remove current loadout for the selected group(s)","and replace it with the selected player's","loadout on this menu."
		
		local w,h = surface.GetTextSize(line1)
		surface.SetTextPos(frame:GetWide()/2-w/2, 25)
		surface.DrawText( line1 )
		
		local w,h = surface.GetTextSize(line2)
		surface.SetTextPos(frame:GetWide()/2-w/2, 25+h+3)
		surface.DrawText( line2 )
		
		local w,h = surface.GetTextSize(line3)
		surface.SetTextPos(frame:GetWide()/2-w/2, 25+h*2+3*2)
		surface.DrawText( line3 )
		
	end
	
	local textbox = vgui.Create("DTextEntry",frame)
	textbox:SetSize(130,25)
	textbox:SetPos(5,frame:GetTall()-textbox:GetTall()-5)
	urm.setDefaultTextboxText(textbox,"Search...")
	
	local listview = vgui.Create("DListView", frame)
	listview:SetPos(5,75)
	listview:SetSize(frame:GetWide()-10,(frame:GetTall()-textbox:GetTall()-5)-75-5)
	listview:SetMultiSelect(false)
	listview:AddColumn("Player")
	listview:AddColumn("Usergroup")
	local function populatePlayerList()
	
		listview:Clear()
	
		local hierchy = {}
		local function hierchyLoop(t)
			for k, v in pairs(t) do
				table.insert(hierchy,1,k)
				if (string.lower(type(v)) == "table") then
					hierchyLoop(v)
				end
			end
		end
		hierchyLoop(ULib.ucl.getInheritanceTree())	
		
		listview.players = player.GetAll()
		table.sort(listview.players, function (a,b)
								return table.KeyFromValue(hierchy,a:GetUserGroup()) > table.KeyFromValue(hierchy,a:GetUserGroup())
							end)
		
		for k,v in pairs(listview.players) do		
			local entry = listview:AddLine(v:Nick(),v:GetUserGroup())
		end
		
	end
	populatePlayerList()
	
	local button = vgui.Create("DButton", frame)
	button:SetSize(100,25) 
	button:SetPos(frame:GetWide()-button:GetWide()-5,frame:GetTall()-textbox:GetTall()-5)
	button:SetText("Set")
	
	textbox.OnTextChanged = function()
		populatePlayerList()
		for k, v in pairs(listview:GetLines()) do
			local text = textbox:GetValue()
			local item = v:GetValue(1)
			if not string.match(item,text) then
				listview:RemoveLine(k)
			end
		end
	end
	
	button.DoClick = function()
		if not listview:GetSelectedLine() then return end
		if not listview.players[listview:GetSelectedLine()]:GetWeapons() then return end
		
		local usergroups = {}
		for k,v in pairs (urm.loadouts.grouplist:GetSelected()) do
			table.insert(usergroups,v:GetValue(1))
		end
		
		--Delete old loadout
		local entries = {}
		for k,v in pairs(urm.loadouts.itemlist:GetLines()) do
			table.insert(entries,v:GetValue(2))
		end

		for k,v in pairs(usergroups) do
			if (table.Count(entries) > 0) then
				urm.loadouts.delete(v,entries,1)
			end
		end	
		
		--Add new loadout
		if not listview then return end
		if not listview.players then return end
		if not listview.players[listview:GetSelectedLine()] then return end
		local ply = listview.players[listview:GetSelectedLine()]
		local weps = ply:GetWeapons()
		local active_wep = ply:GetActiveWeapon()
		for k,v in pairs(weps) do
			urm.loadouts.add(usergroups,v:GetClass(),ply:GetAmmoCount(v:GetPrimaryAmmoType()),ply:GetAmmoCount(v:GetSecondaryAmmoType()),1)
		end 
		URM.SendCommand("ulx setprimary",string.Implode(",",usergroups),active_wep:GetClass(),1)
		
	end
	
	frame:SizeToContentsY()
	frame:SetVisible(true)
	frame:MakePopup()
	
end

function urm.loadouts.process( t )
	urm.loadouts.reloaditems()
end
xgui.hookEvent( "URMLoadouts", "process", urm.loadouts.process )
urm.loadouts.Initialize()

function urm.process( len )
	local tbl = net.ReadTable()
	for k,str in pairs(tbl) do
		RunString(str)
		urm.restrictions.process()
		urm.limits.process() 
		urm.loadouts.process()
	end
end
net.Receive( "URMUpdateStream", urm.process )

xgui.addSettingModule( "Loadouts", urm.loadouts.panel, "icon16/briefcase.png" )
 