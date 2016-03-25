urm = urm or {}
if not urm.loaded then 
	urm.load_list = urm.load_list or {}
	table.insert(urm.load_list,"xgui_limits.lua")
	return
end

if not ConVarExists( "urm_limits_advanced" ) then CreateClientConVar( "urm_limits_advanced", "0", true, false ) end
--GetConVar( "urm_limits_advanced" ):GetInt()
urm.limits = {}
urm.limits.adv = {}
urm.limits.sim = {}
urm.limits.panel = xlib.makepanel{ parent=xgui.null }
urm.limits.simplepanel = xlib.makepanel{ parent=urm.limits.panel,x=440, y=0, w=140, h=335}

--Simple panel
urm.limits.addbutton = xlib.makebutton{ parent=urm.limits.simplepanel, x=5, y=241, w=130, h=25, label="Add", disabled=false }
urm.limits.deletebutton = xlib.makebutton{ parent=urm.limits.simplepanel, x=5, y=271, w=130, h=25, label="Delete", disabled=false }
urm.limits.editbutton = xlib.makebutton{ parent=urm.limits.simplepanel, x=5, y=300, w=100, h=25, label="Edit", disabled=false }
urm.limits.custombutton = xlib.makebutton{ parent=urm.limits.simplepanel, x=110, y=300, w=25, h=25, disabled=false }

urm.limits.search = xlib.maketextbox{x=5, y=5, w=130, h=25, text="Search...", parent=urm.limits.simplepanel, selectall=true, disabled=false,enableinput=true }
urm.setDefaultTextboxText(urm.limits.search,"Search...")

urm.limits.custombox = xlib.maketextbox{x=5, y=210, w=130, h=25, text="Model...", parent=urm.limits.simplepanel, visible=false, selectall=true, disabled=false,enableinput=true }
urm.setDefaultTextboxText(urm.limits.custombox,"Model or Adv. Limit")

urm.limits.customcombo = vgui.Create( "DComboBox", urm.limits.simplepanel )
urm.limits.customcombo:SetPos( 5, 45 )
urm.limits.customcombo:SetSize( 100, 25 )
urm.limits.customcombo:SetVisible(false)

urm.limits.suggestionlist = xlib.makelistview{ parent=urm.limits.simplepanel, x=5, y=35, w=130, h=200, multiselect=true }

--Other
urm.limits.limitlabel = xlib.makelabel{ x=18, y=5,w = 100, label="Limit", decimal = 0, default = 200, font = "DermaDefaultBold", parent=urm.limits.panel }
urm.limits.limitslider = xlib.makeslider{ x=5, y=20, w=100, min=0, max=1001, parent=urm.limits.panel }

urm.limits.grouplist = xlib.makelistview{ parent=urm.limits.panel, x=5, y=45, w=100, h=280, multiselect=true }

urm.limits.advtext = xlib.maketextbox{x=5, y=45, w=100, h=25, text="Adv. Limit", parent=urm.limits.panel, selectall=true, disabled=false,enableinput=true, visible=false }
urm.setDefaultTextboxText(urm.limits.advtext,"Adv. Limit")
urm.limits.advtext:SetVisible(false)

urm.limits.itemlist = xlib.makelistview{ parent=urm.limits.panel, x=110, y=5, w=330, h=320, multiselect=true }

urm.limits.custom = false

function urm.limits.Initialize()
	urm.limits.PopulateMenus()
end
  
function urm.limits.PopulateMenus()

	--Populating the groups type list
	urm.limits.grouplist:AddColumn("Usergroup")
	for k, v in pairs(xgui.data.groups) do
		urm.limits.grouplist:AddLine( v ) 
	end
	urm.limits.grouplist:SelectFirstItem()
	urm.limits.grouplist:SetSortable(false)
	
	urm.limits.suggestionlist:AddColumn("Types")
	for k,v in pairs(urm.cleanup) do
		urm.limits.suggestionlist:AddLine(v)
	end
	
	urm.limits.search:SetEditable(true)
	
	urm.limits.limitslider:SetValue(0)
	
	urm.limits.custombutton:SetImage("icon16/cog.png")
	
	--Populating item list
	urm.limits.itemlist:AddColumn("Usergroup")
	urm.limits.itemlist:AddColumn("Item")
	urm.limits.itemlist:AddColumn("Limit")
	urm.limits.itemlist:SetSortable(false)
	
end

function urm.limits.reloadcombo()
	if not urm.limits.grouplist:GetSelected()[1] then return end
	
	urm.limits.customcombo:Clear()
	
	local limits = xgui.data.URMLimits
	
	for k,usergroup in pairs(urm.limits.grouplist:GetSelected()) do
		for k,value in pairs(usergroup) do
			if (string.lower(type(value)) == "table") then
			
			end
		end
	end
end

function urm.limits.reloadsuggestions()
	if urm.limits.custom then
		urm.limits.suggestionlist:Clear()
		for k,v in pairs(urm.all) do
			urm.limits.suggestionlist:AddLine(v)
		end
	else
		urm.limits.suggestionlist:Clear()
		for k,v in pairs(urm.cleanup) do
			urm.limits.suggestionlist:AddLine(v)
		end
	end
end

function urm.limits.reloaditems()
	if not urm.limits.grouplist:GetSelected()[1] then return end
	urm.limits.itemlist:Clear()
	for k,usergroup in pairs(urm.limits.grouplist:GetSelected()) do 
		usergroup = usergroup:GetValue(1)
		local usergroup_table = xgui.data.URMLimits[usergroup]
		if usergroup_table then  
			for item,state in pairs(usergroup_table) do
				urm.limits.itemlist:AddLine( usergroup,item,state ) 
				urm.limits.itemlist:SelectFirstItem()
			end 
		end
	end
end

function urm.limits.haslimit(usergroup,str)
	if xgui.data.URMLimits then
		if xgui.data.URMLimits[usergroup] then
			if xgui.data.URMLimits[usergroup][str] then
				return true
			end
		end
	end
	return false
end

urm.limits.editbutton.disabledtbl = {}
function urm.limits.editbutton.addDisabledEntry(id,value)
	urm.limits.editbutton.disabledtbl[id] = value
	for k,v in pairs(urm.limits.editbutton.disabledtbl) do
		if v then
			urm.limits.editbutton:SetDisabled(true)
			return
		end
	end
	urm.limits.editbutton:SetDisabled(false)
end

urm.limits.search.OnTextChanged = function()
	urm.limits.reloadsuggestions()
	for k, v in pairs(urm.limits.suggestionlist:GetLines()) do
		local text = urm.limits.search:GetValue()
		local item = v:GetValue(1)
		if not string.match(item,text) then
			urm.limits.suggestionlist:RemoveLine(k)
		end
	end
end

urm.limits.customboxinput = false
urm.limits.custombox.OnTextChanged = function()
	if (string.len(urm.limits.custombox:GetValue()) > 0 and urm.limits.custombox:GetValue() !=  urm.getDefaultTextboxText(urm.limits.custombox)) then
		urm.limits.customboxinput = true
		urm.limits.suggestionlist:SetDisabled(true)
		urm.limits.search:SetDisabled(true)
	else	
		urm.limits.customboxinput = false
		urm.limits.suggestionlist:SetDisabled(false)
		urm.limits.search:SetDisabled(false)
	end
end

urm.limits.advtextinput = false
urm.limits.advtext.OnTextChanged = function()
	if (string.len(urm.limits.advtext:GetValue()) > 0 and urm.limits.advtext:GetValue() !=  urm.getDefaultTextboxText(urm.limits.advtext)) then
		urm.limits.advtextinput = true
		urm.limits.limitslider:SetDisabled(true)
	else	
		urm.limits.advtextinput = false
		urm.limits.limitslider:SetDisabled(false)
	end
end

urm.limits.itemlist.OnRowSelected = function( self, lineid, line )
	if (#urm.limits.itemlist:GetSelected() > 1) then
		urm.limits.editbutton.addDisabledEntry("itemlist",true)
	else
		urm.limits.editbutton.addDisabledEntry("itemlist",false)
	end
end

urm.limits.grouplist.OnRowSelected = function( self, lineid, line )
	urm.limits.reloaditems()
end

urm.limits.suggestionlist.OnRowSelected = function( self, lineid, line )
	if (#urm.limits.suggestionlist:GetSelected() > 1) then
		urm.limits.editbutton.addDisabledEntry("suggestionlist",true)
		if (urm.limits.search:GetValue() == "Model / Class") then
			urm.limits.search:SetValue("Search...")
		end
	else
		urm.limits.editbutton.addDisabledEntry("suggestionlist",false)
		if (urm.limits.suggestionlist:GetSelected()[1]:GetValue(1) == "CUSTOM") then
			urm.limits.search:SetValue("Model / Class")
		else
			if (urm.limits.search:GetValue() == "Model / Class") then
				urm.limits.search:SetValue("Search...")
			end
		end
	end
	
end

urm.limits.custom = false
urm.limits.custombutton.DoClick = function()
	urm.limits.custom = not urm.limits.custom
	if urm.limits.custom then
		urm.limits.advtext:SetVisible(true)
		urm.limits.grouplist:SetPos(5,75)
		urm.limits.grouplist:SetTall(250)
		urm.limits.custombox:SetVisible(true)
		urm.limits.suggestionlist:SetTall(urm.limits.suggestionlist:GetTall()-30)
		urm.limits.suggestionlist.VBar:AnimateTo( 0, 0.1, 0, 1 )
	else
		urm.limits.custombox:Clear()
		urm.limits.advtext:Clear()
		urm.limits.advtext:SetVisible(false)
		urm.limits.grouplist:SetTall(280)
		urm.limits.grouplist:SetPos(5,45)
		urm.limits.custombox:SetVisible(false)
		urm.limits.suggestionlist:SetTall(urm.limits.suggestionlist:GetTall()+30)
		urm.limits.custombox:Clear()
		urm.limits.search.OnTextChanged()
		urm.limits.suggestionlist.VBar:AnimateTo( 0, 0.1, 0, 1 )
	end
	urm.limits.suggestionlist:SetSelected(1)
	urm.limits.reloadsuggestions()
end

urm.limits.addbutton.DoClick = function()
	local usergroups = {}
	local strings = {}

	local limit
	if not urm.limits.advtextinput then limit = urm.limits.limitslider:GetValue() else limit = urm.limits.advtext:GetValue() end
	
	for k,usergroup in pairs(urm.limits.grouplist:GetSelected()) do
		usergroup = usergroup:GetValue(1)
		table.insert(usergroups,usergroup)
		if not urm.limits.customboxinput then
			for k,v in pairs(urm.limits.suggestionlist:GetSelected()) do
				str = v:GetValue(1)
				if not urm.limits.haslimit(usergroup,str) then
					if not table.HasValue(strings,str) then
						table.insert(strings,str)
					end
				else
					ULib.tsayError( LocalPlayer(), string.format("\"%s\" already has a \"%s\"  limit.", usergroup, str), true )
				end
			end
		else
			str = urm.limits.custombox:GetValue()
			if not urm.limits.haslimit(usergroup,str) then
				if not table.HasValue(strings,str) then
					table.insert(strings,str)
				end
			else
				ULib.tsayError( LocalPlayer(), string.format("\"%s\" already has a \"%s\"  limit.", usergroup, str), true )
			end
		end
	end
	if (#usergroups > 0) and (#strings > 0) then
		URM.SendCommand("ulx setlimit",string.Implode(",",usergroups),string.Implode(",",strings),limit)
	end
end

urm.limits.deletebutton.DoClick = function()
	local usergroups = {}
	local strings = {}
	for k,v in pairs(urm.limits.itemlist:GetSelected()) do
		local usergroup = v:GetValue(1)
		if not table.HasValue(usergroups,usergroup) then
			table.insert(usergroups,usergroup)
		end
		local str = v:GetValue(2)
		if urm.limits.haslimit(usergroup,str) then
			if not table.HasValue(strings,str) then
				table.insert(strings,str)
			end
		else
			ULib.tsayError( LocalPlayer(), string.format("\"%s\" does not have a \"%s\" limit.", usergroup, str ), true )
		end
	end
	if (#usergroups > 0) and (#strings > 0) then
		URM.SendCommand("ulx removelimit",string.Implode(",",usergroups),string.Implode(",",strings))
	end
end

urm.limits.editbutton.DoClick = function()
	local usergroup = urm.limits.itemlist:GetSelected()[1]:GetValue(1)
	local str = urm.limits.itemlist:GetSelected()[1]:GetValue(2)
	local limit
	if not urm.limits.advtextinput then limit = urm.limits.limitslider:GetValue() else limit = urm.limits.advtext:GetValue() end
	LocalPlayer():ConCommand(string.format("ulx setlimit \"%s\" \"%s\" \"%i\" \"%s\"",usergroup,str,limit,"1"))
end

function urm.limits.process( t )
	urm.limits.reloaditems()
end
xgui.hookEvent( "URMLimits", "process", urm.limits.process )
urm.limits.Initialize()

xgui.addSettingModule( "Limits", urm.limits.panel, "icon16/table.png" ) 