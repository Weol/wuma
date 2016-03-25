
urm = urm or {}
if not urm.loaded then 
	urm.load_list = urm.load_list or {}
	table.insert(urm.load_list,"xgui_restrictions.lua")
	return
end

urm.restrictions = {}
urm.restrictions.panel = xlib.makepanel{ parent=xgui.null }
urm.restrictions.addbutton = xlib.makebutton{ parent=urm.restrictions.panel, x=445, y=241, w=130, h=25, label="Add", disabled=false }
urm.restrictions.deletebutton = xlib.makebutton{ parent=urm.restrictions.panel, x=445, y=271, w=130, h=25, label="Delete", disabled=false }
urm.restrictions.editbutton = xlib.makebutton{ parent=urm.restrictions.panel, x=445, y=300, w=130, h=25, label="Edit", disabled=false }

urm.restrictions.search = xlib.maketextbox{x=445, y=5, w=130, h=25, text="Search...", parent=urm.restrictions.panel, selectall=true, disabled=false }
urm.setDefaultTextboxText(urm.restrictions.search,"Search...")

urm.restrictions.suggestionlist = xlib.makelistview{ parent=urm.restrictions.panel, x=445, y=35, w=130, h=201, multiselect=true }
urm.restrictions.typelist = xlib.makelistview{ parent=urm.restrictions.panel, x=5, y=5, w=100, h=174 }
urm.restrictions.grouplist = xlib.makelistview{ parent=urm.restrictions.panel, x=5, y=184, w=100, h=141, multiselect=true }

urm.restrictions.itemlist = xlib.makelistview{ parent=urm.restrictions.panel, x=110, y=5, w=330, h=320, multiselect=true }

urm.restrictions.RestrictTypes = {Entities = "entity",Props = "prop",NPCs = "npc",Vehicles = "vehicle", SWEP = "swep", Pickup = "pickup", Effects = "effect",Tools = "tool",Ragdolls = "ragdoll"}

urm.restrictions.type_search_defaults = {
	entity = "Search...",
	prop = "Model...",
	npc = "Search...",
	vehicle = "Search...",
	swep = "Search...",
	pickup = "Search...",
	effect = "Model...",
	tool = "Search...",
	ragdoll = "Model...", 
} 

urm.restrictions.type_suggestions = {
	entity = urm.entities,
	prop = false,
	npc = urm.npcs,
	vehicle = urm.vehicles,
	swep = urm.weapons,
	pickup = urm.weapons,
	effect = false,
	tool = urm.tools,
	ragdoll = false, 
} 
 
function urm.restrictions.Initialize()
	urm.restrictions.PopulateMenus()
end
  
function urm.restrictions.PopulateMenus()
	--Populating the restriction type list
	urm.restrictions.typelist:AddColumn("Types")
	for k, v in pairs(urm.restrictions.RestrictTypes) do
		urm.restrictions.typelist:AddLine( k ) 
	end
	urm.restrictions.typelist:SelectFirstItem()
	urm.restrictions.typelist:SortByColumn(1)

	--Populating the groups type list
	urm.restrictions.grouplist:AddColumn("Usergroup")
	for k, v in pairs(xgui.data.groups) do
		urm.restrictions.grouplist:AddLine( v ) 
	end
	urm.restrictions.grouplist:SelectFirstItem()
	urm.restrictions.grouplist:SetSortable(false)
	
	urm.restrictions.suggestionlist:AddColumn("Items") 

	urm.restrictions.search:SetEditable(true)
	
	--Populating item list
	urm.restrictions.itemlist:AddColumn("Usergroup")
	urm.restrictions.itemlist:AddColumn("Item")
	urm.restrictions.itemlist:AddColumn("Restrictions")
	urm.restrictions.itemlist:SetSortable(false)
	
end

function urm.restrictions.reloadsuggestions()
	urm.setDefaultTextboxText(urm.restrictions.search,urm.restrictions.type_search_defaults[urm.restrictions.RestrictTypes[urm.restrictions.typelist:GetSelected()[1]:GetValue(1)]])
	urm.restrictions.suggestionlist:SelectFirstItem( )
	urm.restrictions.suggestionlist:Clear()
	if urm.restrictions.type_suggestions[urm.restrictions.RestrictTypes[urm.restrictions.typelist:GetSelected()[1]:GetValue(1)]] then
		urm.restrictions.suggestionlist:SetVisible(true)
		for k, v in pairs(urm.restrictions.type_suggestions[urm.restrictions.RestrictTypes[urm.restrictions.typelist:GetSelected()[1]:GetValue(1)]]) do
			urm.restrictions.suggestionlist:AddLine( v ) 
		end
	else
		urm.restrictions.suggestionlist:SetVisible(false)
	end
	urm.restrictions.suggestionlist:SortByColumn(1)
	urm.restrictions.suggestionlist.VBar:AnimateTo( 0, 0.1, 0, 1 )
end

function urm.restrictions.reloaditems()
	if not urm.restrictions.grouplist:GetSelected()[1] then return end
	if not urm.restrictions.typelist:GetSelected()[1] then return end
	urm.restrictions.itemlist:Clear()
	local usergroup = ""
	for k,_ in pairs(urm.restrictions.grouplist:GetSelected()) do 
		usergroup = urm.restrictions.grouplist:GetSelected()[(#urm.restrictions.grouplist:GetSelected()+1)-k]
		usergroup = usergroup:GetValue(1)
		local usergroup_table = xgui.data.URMRestrictions[usergroup]
		if usergroup_table then  
			if usergroup then
				local type = urm.restrictions.RestrictTypes[urm.restrictions.typelist:GetSelected()[1]:GetValue(1)]
				if type then 
					if usergroup_table[type] then
						for item,state in pairs(usergroup_table[type]) do
							urm.restrictions.itemlist:AddLine( usergroup,item,state ) 
							urm.restrictions.itemlist:SelectFirstItem()
						end 
					end
				end
			end
		end
	end
end

function urm.restrictions.isrestricted(usergroup,type,str)
	if xgui.data.URMRestrictions then
		if xgui.data.URMRestrictions[usergroup] then
			if xgui.data.URMRestrictions[usergroup][type] then
				if xgui.data.URMRestrictions[usergroup][type][str] then
					return true
				end
			end
		end
	end
	return false
end

urm.restrictions.editbutton.disabledtbl = {}
function urm.restrictions.editbutton.addDisabledEntry(id,value)
	urm.restrictions.editbutton.disabledtbl[id] = value
	for k,v in pairs(urm.restrictions.editbutton.disabledtbl) do
		if v then
			urm.restrictions.editbutton:SetDisabled(true)
			return
		end
	end
	urm.restrictions.editbutton:SetDisabled(false)
end

urm.restrictions.search.OnTextChanged = function() 
	urm.restrictions.reloadsuggestions()
	for k, v in pairs(urm.restrictions.suggestionlist:GetLines()) do
		local text = urm.restrictions.search:GetValue()
		local item = v:GetValue(1)
		if not string.match(item,text) then
			urm.restrictions.suggestionlist:RemoveLine(k)
		end
	end
end

urm.restrictions.itemlist.OnRowSelected = function( self, lineid, line )
	if (#urm.restrictions.itemlist:GetSelected() > 1) then
		urm.restrictions.editbutton.addDisabledEntry("itemlist",true)
	else
		urm.restrictions.editbutton.addDisabledEntry("itemlist",false)
	end
end


urm.restrictions.typelist.OnRowSelected = function( self, lineid, line )
	urm.restrictions.search:Clear()
	urm.restrictions.reloaditems()
	urm.restrictions.reloadsuggestions()
end

urm.restrictions.grouplist.OnRowSelected = function( self, lineid, line )
	urm.restrictions.reloaditems()
end

urm.restrictions.suggestionlist.OnRowSelected = function( self, lineid, line )
	if (#urm.restrictions.suggestionlist:GetSelected() > 1) then
		urm.restrictions.editbutton.addDisabledEntry("suggestionlist",true)
	else
		urm.restrictions.editbutton.addDisabledEntry("suggestionlist",false)
	end
end

urm.restrictions.addbutton.DoClick = function()
	local usergroups = {}
	local strings = {}
	local type = ""
	for k,usergroup in pairs(urm.restrictions.grouplist:GetSelected()) do
		usergroup = usergroup:GetValue(1)
		table.insert(usergroups,usergroup)
		type = urm.restrictions.RestrictTypes[urm.restrictions.typelist:GetSelected()[1]:GetValue(1)]
		if not urm.restrictions.type_suggestions[type] then
			str = urm.restrictions.search:GetValue()
			local isvalid = true
			if (type == "prop" or type == "effect") then
				isvalid = util.IsValidProp( str )
			elseif (type == "ragdoll") then
				isvalid = util.IsValidProp( str )
			end
			if isvalid then
				if not urm.restrictions.isrestricted(usergroup,type,str) then
					if not table.HasValue(strings,str) then
						table.insert(strings,str)
					end
				else
					ULib.tsayError( LocalPlayer(), string.format("\"%s\" of type \"%s\" is already restricted.", str, type), true  )
				end
			else
				ULib.tsayError( LocalPlayer(), string.format("Invalid string \"%s\" specified for type \"%s\"", str, type), true )
			end
		else
			for k,v in pairs(urm.restrictions.suggestionlist:GetSelected()) do
				str = v:GetValue(1)
				if not urm.restrictions.isrestricted(usergroup,type,str) then
					if not table.HasValue(strings,str) then
						table.insert(strings,str)
					end
				else
					ULib.tsayError( LocalPlayer(), string.format("\"%s\" of type \"%s\" is already restricted.", str, type), true )
				end
			end
		end
	end
	if (#usergroups > 0) and (#strings > 0) then
		local cmd = string.format([[ulx restrict "%s" "%s" "%s"]],string.Implode(",",usergroups),type,string.Implode(",",strings))
		URM.SendCommand("ulx restrict",string.Implode(",",usergroups),type,string.Implode(",",strings))
	end
end

urm.restrictions.deletebutton.DoClick = function()
	local usergroups = {}
	local strings = {}
	local type = ""
	for k,v in pairs(urm.restrictions.itemlist:GetSelected()) do
		local usergroup = v:GetValue(1)
		if not table.HasValue(usergroups,usergroup) then
			table.insert(usergroups,usergroup)
		end
		type = urm.restrictions.RestrictTypes[urm.restrictions.typelist:GetSelected()[1]:GetValue(1)]
		local str = v:GetValue(2)
		if urm.restrictions.isrestricted(usergroup,type,str) then
			if not table.HasValue(strings,str) then
				table.insert(strings,str)
			end
		else
			ULib.tsayError( LocalPlayer(), string.format("\"%s\" is not restricted from \"%s\" group", str, type), true )
		end
	end
	if (#usergroups > 0) and (#strings > 0) then
		URM.SendCommand("ulx unrestrict",string.Implode(",",usergroups),type,string.Implode(",",strings))
	end
end

urm.restrictions.editbutton.DoClick = function()
	local usergroups = {}
	local strings = {}
	local type = ""
	for k,usergroup in pairs(urm.restrictions.grouplist:GetSelected()) do
		usergroup = urm.restrictions.itemlist:GetSelected()[1]:GetValue(1)
		type = urm.restrictions.RestrictTypes[urm.restrictions.typelist:GetSelected()[1]:GetValue(1)]
		if not urm.restrictions.type_suggestions[type] then
			str = urm.restrictions.search:GetValue()
			local isvalid = true
			if (type == "prop" or type == "effect") then
				isvalid = not util.IsValidProp( str )
			elseif (type == "ragdoll") then
				isvalid = not util.IsValidRagdoll( str )
			end
			if isvalid then
				if not urm.restrictions.isrestricted(usergroup,type,str) then
					str2 = urm.restrictions.itemlist:GetSelected()[1]:GetValue(2)
					LocalPlayer():ConCommand(string.format("ulx unrestrict \"%s\" \"%s\" \"%s\" \"%s\"",usergroup,type,str2,"1"))
					LocalPlayer():ConCommand(string.format("ulx restrict \"%s\" \"%s\" \"%s\" \"%s\"",usergroup,type,str,"1"))
				else
					ULib.tsayError( LocalPlayer(), string.format("\"%s\" of type \"%s\" is already restricted.", str, type), true  )
				end
			else
				ULib.tsayError( LocalPlayer(), string.format("Invalid string \"%s\" specified for type \"%s\"", str, type), true )
			end
		else
			str = urm.restrictions.suggestionlist:GetSelected()[1]:GetValue(1)
			str2 = urm.restrictions.itemlist:GetSelected()[1]:GetValue(2)
			if not urm.restrictions.isrestricted(usergroup,type,str) then
				LocalPlayer():ConCommand(string.format("ulx unrestrict \"%s\" \"%s\" \"%s\" \"%s\"",usergroup,type,str2,"1"))
				LocalPlayer():ConCommand(string.format("ulx restrict \"%s\" \"%s\" \"%s\" \"%s\"",usergroup,type,str,"1"))
			else
				ULib.tsayError( LocalPlayer(), string.format("\"%s\" of type \"%s\" is already restricted.", str, type), true )
			end
		end
	end
end

function urm.restrictions.process( t )
	urm.restrictions.reloaditems()
end
xgui.hookEvent( "URMRestrictions", "process", urm.restrictions.process )
urm.restrictions.Initialize()

xgui.addSettingModule( "Restrictions", urm.restrictions.panel, "icon16/shield.png" ) 