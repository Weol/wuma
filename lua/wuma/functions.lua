
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

WUMA.EchoChanges = WUMA.CreateConVar("wuma_echo_changes", "2", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "0=Nobody, 1=Access, 2=Everybody, 3=Relevant")
WUMA.EchoToChat = WUMA.CreateConVar("wuma_echo_to_chat", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable / disable echo in chat.")

WUMA.AccessRegister = {}
function WUMA.RegisterAccess(tbl)
	WUMA.AccessRegister[tbl.name] = WUMAAccess:new(tbl)
	return WUMA.AccessRegister[tbl.name]
end

function WUMA.RegisterCAMIAccessPriviliges()
	for name, access in pairs(WUMA.AccessRegister) do
		if not access:IsStrict() then
			CAMI.RegisterPrivilege{Name="wuma "..access:GetName(),MinAccess=access:GetAccess(),Description=access:GetHelp()}
		end
	end
end
 
function WUMA.ProcessAccess(cmd,data)
	
	local access = WUMA.AccessRegister[cmd]

	if access then
		local arguments = {}
		local tables = {}
		local static = {}
		local insert = table.insert
		local getkeys = table.GetKeys
		local copy = table.Copy
		local merge = table.Merge
		local count = table.Count
		local unpack = unpack

		for i = 1,count(access:GetArguments()) do
			if data[i] then
				if istable(data[i]) then
					tables[i] = {}
					for _, v in pairs(data[i]) do
						insert(tables[i], access:GetArguments()[i][1](v))
					end
				else
					static[i] = access:GetArguments()[i][1](data[i])
				end
			else
				static[i] = nil
			end
		end 
		
		if (count(tables) > 0) then
			local function recursive(i)
				if not ans then ans = {} end
				local tbl = tables[getkeys(tables)[i]]
				local key = getkeys(tables)[i]
				for k, v in pairs(tbl) do 
					if (tables[getkeys(tables)[i+1]]) then
						ans[key] = v
						recursive(i+1)
					else
						ans[key] = v
						insert(arguments,merge(copy(ans),copy(static)))
					end
				end
			end
			recursive(1)
			
			for _, args in pairs(arguments) do
				access(unpack(args))
			end
		else
			access(unpack(static))
		end

	else
		WUMADebug("Could not find access! (%s)",cmd)
	end
end

function WUMA.CheckAccess(access, user, callback)
	CAMI.PlayerHasAccess(user, "wuma "..access:GetName(), callback)
end

function WUMA.CheckSelfAccess(access, user, callback)
	CAMI.PlayerHasAccess(user, "wuma "..WUMA.AccessRegister["personalloadout"]:GetName(), callback)
end
 
function WUMA.EchoFunction(args, affected, caller)
	
	if not args then return end
	
	local msg = args[1]
	table.remove(args,1)
	
	local str = string.format(msg,caller:Nick(),unpack(args))
	
	if WUMA.EchoChanges then
		if (WUMA.EchoChanges:GetInt() == 1) then
			WUMA.GetAuthorizedUsers(function(users) 
				for _, user in pairs(users) do
					if WUMA.EchoToChat:GetBool() then
						user:ChatPrint(str)
					else
						user:PrintMessage(HUD_PRINTCONSOLE, str)
					end
				end
			end)
		elseif (WUMA.EchoChanges:GetInt() == 2) then
			for _, user in pairs(player.GetAll()) do
				if WUMA.EchoToChat:GetBool() then
					user:ChatPrint(str)
				else
					user:PrintMessage(HUD_PRINTCONSOLE, str)
				end
			end 
		elseif (WUMA.EchoChanges:GetInt() == 3) then
			if affected and istable(affected) then 
				for _, user in pairs(affected) do
					if WUMA.EchoToChat:GetBool() then
						user:ChatPrint(str)
					else
						user:PrintMessage(HUD_PRINTCONSOLE, str)
					end
				end
			end
		end
	end
	
	WUMALog(str)
end

///////////////////////////////////////////////
/////		  Access declerations  	      /////
///////////////////////////////////////////////

/////////////////////////////////////////////////////////
/////	Restict | Restricts items from usergroups	/////
/////////////////////////////////////////////////////////
local Restrict = WUMA.RegisterAccess{name="restrict",help="Restrict something from a usergroup."}
Restrict:SetFunction(function(caller, usergroup, typ, item, anti, scope)
	if not usergroup or not typ then return WUMADebug("Invalid access arguments (restrict)!") end

	usergroup = string.lower(usergroup)
	typ = string.lower(typ)
	if isstring(item) then item  = string.lower(item) else item = nil end
	if (anti == 1) then anti = true else anti = false end
	
	local sucess = WUMA.AddRestriction(caller,usergroup,typ,item,anti,scope)

	if not (sucess == false) then
		local prefix = " %s"
		local scope_str = ""
		if scope then 
			scope_str = string.lower(scope:GetPrint2())
			prefix = " "..scope:GetScopeType().log_prefix.." %s"
		end
		
		if item then 
			item = " " .. item
			typ = string.lower(Restriction:GetTypes()[typ].print)
		else 
			item = "" 
			typ = string.lower(Restriction:GetTypes()[typ].print2)
		end
		
		if anti then
			return {"%s derestricted %s%s from %s"..prefix,typ,item or "",usergroup,scope_str}, sucess, caller
		else
			return {"%s restricted %s%s from %s"..prefix,typ,item  or "",usergroup,scope_str}, sucess, caller 
		end
	end
end)
Restrict:AddArgument(WUMAAccess.PLAYER)
Restrict:AddArgument(WUMAAccess.USERGROUP)
Restrict:AddArgument(WUMAAccess.STRING,_,table.GetKeys(Restriction:GetTypes()))
Restrict:AddArgument(WUMAAccess.STRING, true)
Restrict:AddArgument(WUMAAccess.NUMBER,true)
Restrict:AddArgument(WUMAAccess.SCOPE,true)
Restrict:SetLogFunction(WUMA.EchoFunction)
Restrict:SetAccessFunction(WUMA.CheckAccess)
Restrict:SetAccess("superadmin")

/////////////////////////////////////////////////////
/////	Restict | Restricts items from users	/////
/////////////////////////////////////////////////////
local RestrictUser = WUMA.RegisterAccess{name="restrictuser",help="Restrict something from a player"}
RestrictUser:SetFunction(function(caller, target, typ, item, anti, scope)
	if not target or not typ then return WUMADebug("Invalid access arguments (restrictuser)!") end

	typ = string.lower(typ)
	if isstring(item) then item  = string.lower(item) else item = nil end
	
	if (anti == 1) then anti = true else anti = false end

	local sucess = WUMA.AddUserRestriction(caller,target,typ,item,anti,scope)
	
	if not (sucess == false) then
		if isentity(target) then nick = target:Nick() else nick = target end
		
		local prefix = " %s"
		local scope_str = ""
		if scope then 
			scope_str = string.lower(scope:GetPrint2())
			prefix = " "..scope:GetScopeType().log_prefix.." %s"
		end
		
		if item then 
			item = " " .. item
			typ = string.lower(Restriction:GetTypes()[typ].print)
		else 
			item = "" 
			typ = string.lower(Restriction:GetTypes()[typ].print2)
		end
		
		if anti then
			return {"%s derestricted %s%s from %s"..prefix,typ,item or "",nick,scope_str}, sucess, caller
		else
			return {"%s restricted %s%s from %s"..prefix,typ,item or "",nick,scope_str}, sucess, caller
		end
	end
end)
RestrictUser:AddArgument(WUMAAccess.PLAYER)
RestrictUser:AddArgument(WUMAAccess.PLAYER)
RestrictUser:AddArgument(WUMAAccess.STRING,_,table.GetKeys(Restriction:GetTypes()))
RestrictUser:AddArgument(WUMAAccess.STRING, true)
RestrictUser:AddArgument(WUMAAccess.NUMBER,true)
RestrictUser:AddArgument(WUMAAccess.SCOPE,true)
RestrictUser:SetLogFunction(WUMA.EchoFunction)
RestrictUser:SetAccessFunction(WUMA.CheckAccess)
RestrictUser:SetAccess("superadmin")

/////////////////////////////////////////////////////////////
/////	Unrestict | Unrestricts items from usergroups	/////
/////////////////////////////////////////////////////////////
local Unrestrict = WUMA.RegisterAccess{name="unrestrict",help="Unrestrict something from a usergroup"}
Unrestrict:SetFunction(function(caller, usergroup, typ, item)
	if not usergroup or not typ then return WUMADebug("Invalid access arguments (unrestrict)!") end

	usergroup = string.lower(usergroup)
	typ = string.lower(typ)
	if isstring(item) then item  = string.lower(item) else item = nil end
	
	local sucess = WUMA.RemoveRestriction(caller,usergroup,typ,item)
	
	if not (sucess == false) then
		if item then 
			item = " " .. item
			typ = string.lower(Restriction:GetTypes()[typ].print)
		else 
			item = "" 
			typ = string.lower(Restriction:GetTypes()[typ].print2)
		end
		
		return {"%s unrestricted %s%s from %s",typ,item or "",usergroup}, sucess, caller
	end
end)
Unrestrict:AddArgument(WUMAAccess.PLAYER)
Unrestrict:AddArgument(WUMAAccess.USERGROUP)
Unrestrict:AddArgument(WUMAAccess.STRING,_,table.GetKeys(Restriction:GetTypes()))
Unrestrict:AddArgument(WUMAAccess.STRING, true)
Unrestrict:SetLogFunction(WUMA.EchoFunction)
Unrestrict:SetAccessFunction(WUMA.CheckAccess)
Unrestrict:SetAccess("superadmin")

/////////////////////////////////////////////////////////
/////	Unrestict | Unrestricts items from users	/////
/////////////////////////////////////////////////////////
local UnrestrictUser = WUMA.RegisterAccess{name="unrestrictuser",help="Unrestrict something from a player"}
UnrestrictUser:SetFunction(function(caller, target, typ, item)
	if not target or not typ then return WUMADebug("Invalid access arguments (unrestrictuser)!") end

	typ = string.lower(typ)
	if isstring(item) then item  = string.lower(item) else item = nil end

	local sucess = WUMA.RemoveUserRestriction(caller,target,typ,item)
	
	if not (sucess == false) then
		if isentity(target) then nick = target:Nick() else nick = target end
		
		if item then 
			item = " " .. item
			typ = string.lower(Restriction:GetTypes()[typ].print)
		else 
			item = "" 
			typ = string.lower(Restriction:GetTypes()[typ].print2)
		end
		
		return {"%s unrestricted %s%s from %s",typ,item or "",nick}, sucess, caller
	end
end)
UnrestrictUser:AddArgument(WUMAAccess.PLAYER)
UnrestrictUser:AddArgument(WUMAAccess.PLAYER)
UnrestrictUser:AddArgument(WUMAAccess.STRING,_,table.GetKeys(Restriction:GetTypes()))
UnrestrictUser:AddArgument(WUMAAccess.STRING, true)
UnrestrictUser:SetLogFunction(WUMA.EchoFunction)
UnrestrictUser:SetAccessFunction(WUMA.CheckAccess)
UnrestrictUser:SetAccess("superadmin")

/////////////////////////////////////////////////////////////
/////	SetLimit | Sets a items limit for usergroups	/////
/////////////////////////////////////////////////////////////
local SetLimit = WUMA.RegisterAccess{name="setlimit",help="Set somethings limit."}
SetLimit:SetFunction(function(caller, usergroup, item, limit, exclusive, scope)
	if not usergroup or not item or not limit then return WUMADebug("Invalid access arguments (setlimit)!") end
	
	usergroup = string.lower(usergroup)
	item = string.lower(item)
	
	if (exclusive == 1) then exclusive = true else exclusive = false end

	local sucess = WUMA.AddLimit(caller, usergroup, item, limit, exclusive, scope)
	
	if not (sucess == false) then
		local prefix = " %s"
		local scope_str = ""
		if scope then 
			scope_str = string.lower(scope:GetPrint2())
			prefix = " "..scope:GetScopeType().log_prefix.." %s"
		end

		if ((tonumber(limit) or 0) < 0) then limit = "∞" end
		
		return {"%s set %s limit to %s for %s"..prefix,item,limit,usergroup,scope_str}, sucess, caller
	end
end)
SetLimit:AddArgument(WUMAAccess.PLAYER)
SetLimit:AddArgument(WUMAAccess.USERGROUP)
SetLimit:AddArgument(WUMAAccess.STRING)
SetLimit:AddArgument(WUMAAccess.STRING)
SetLimit:AddArgument(WUMAAccess.NUMBER,true)
SetLimit:AddArgument(WUMAAccess.SCOPE,true)
SetLimit:SetLogFunction(WUMA.EchoFunction)
SetLimit:SetAccessFunction(WUMA.CheckAccess)
SetLimit:SetAccess("superadmin")

/////////////////////////////////////////////////////////
/////	SetUserLimit | Sets a items limit for users	/////
/////////////////////////////////////////////////////////
local SetUserLimit = WUMA.RegisterAccess{name="setuserlimit",help="Set the limit something for a player"}
SetUserLimit:SetFunction(function(caller, target, item, limit, exclusive, scope)
	if not target or not item or not limit then return WUMADebug("Invalid access arguments (setuserlimit)!") end

	limit = string.lower(limit)
	item = string.lower(item)
	
	if (exclusive == 1) then exclusive = true else exclusive = false end

	local sucess = WUMA.AddUserLimit(caller,target, item, limit, exclusive, scope)
	
	if not (sucess == false) then
		if isentity(target) then nick = target:Nick() else nick = target end
		
		local prefix = " %s"
		local scope_str = ""
		if scope then 
			scope_str = string.lower(scope:GetPrint2())
			prefix = " "..scope:GetScopeType().log_prefix.." %s"
		end
		if ((tonumber(limit) or 0) < 0) then limit = "∞" end
		
		return {"%s set %s limit to %s for %s"..prefix,item,limit,nick,scope_str}, sucess, caller
	end
end)
SetUserLimit:AddArgument(WUMAAccess.PLAYER)
SetUserLimit:AddArgument(WUMAAccess.PLAYER)
SetUserLimit:AddArgument(WUMAAccess.STRING)
SetUserLimit:AddArgument(WUMAAccess.STRING)
SetUserLimit:AddArgument(WUMAAccess.NUMBER,true)
SetUserLimit:AddArgument(WUMAAccess.SCOPE,true)
SetUserLimit:SetLogFunction(WUMA.EchoFunction)
SetUserLimit:SetAccessFunction(WUMA.CheckAccess)
SetUserLimit:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////
/////	UnsetLimit | Unsets a items limit for usergroups	/////
/////////////////////////////////////////////////////////////////
local UnsetLimit = WUMA.RegisterAccess{name="unsetlimit",help="Unset somethings limit."}
UnsetLimit:SetFunction(function(caller, usergroup, item)
	if not usergroup or not item then return WUMADebug("Invalid access arguments (unsetlimit)!") end

	usergroup = string.lower(usergroup)
	item = string.lower(item)

	local sucess = WUMA.RemoveLimit(caller,usergroup, item)
	
	if not (sucess == false) then
		return {"%s unset %s limit for %s",item,usergroup}, sucess, caller
	end
end)
UnsetLimit:AddArgument(WUMAAccess.PLAYER)
UnsetLimit:AddArgument(WUMAAccess.USERGROUP)
UnsetLimit:AddArgument(WUMAAccess.STRING)
UnsetLimit:SetLogFunction(WUMA.EchoFunction)
UnsetLimit:SetAccessFunction(WUMA.CheckAccess)
UnsetLimit:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////
/////	 UnsetUserLimit | Unsets a items limit for users	/////
/////////////////////////////////////////////////////////////////
local UnsetUserLimit = WUMA.RegisterAccess{name="unsetuserlimit",help="Unset the limit something for a player"}
UnsetUserLimit:SetFunction(function(caller, target, item)
	if not target or not item then return WUMADebug("Invalid access arguments (unsetuserlimit)!") end

	item = string.lower(item)

	local sucess = WUMA.RemoveUserLimit(caller,target, item)
	
	if not (sucess == false) then
		if isentity(target) then nick = target:Nick() else nick = target end
		return {"%s unset %s limit for %s",item,nick}, sucess, caller
	end
end)
UnsetUserLimit:AddArgument(WUMAAccess.PLAYER)
UnsetUserLimit:AddArgument(WUMAAccess.PLAYER)
UnsetUserLimit:AddArgument(WUMAAccess.STRING)
UnsetUserLimit:SetLogFunction(WUMA.EchoFunction)
UnsetUserLimit:SetAccessFunction(WUMA.CheckAccess)
UnsetUserLimit:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////
/////	 AddLoadout | Adds weapons to usergroups loadout	/////
/////////////////////////////////////////////////////////////////
local AddLoadout = WUMA.RegisterAccess{name="addloadout",help="Add a weapon to a usergroups loadout."}
AddLoadout:SetFunction(function(caller, usergroup, item, primary, secondary, respect, scope)
	if not usergroup or not item or not primary or not secondary then return WUMADebug("Invalid access arguments (addloadout)!") end

	usergroup = string.lower(usergroup)
	item = string.lower(item)
	
	if (respect == 1) then respect = true else respect = false end

	local sucess = WUMA.AddLoadoutWeapon(caller,usergroup, item, primary, secondary, respect, scope)
	
	if not (sucess == false) then
		local prefix = " %s"
		local scope_str = ""
		if scope then 
			scope_str = string.lower(scope:GetPrint2())
			prefix = " "..scope:GetScopeType().log_prefix.." %s"
		end
		
		return {"%s added %s to %ss loadout"..prefix,item,usergroup,scope_str}, sucess, caller
	end
end)
AddLoadout:AddArgument(WUMAAccess.PLAYER)
AddLoadout:AddArgument(WUMAAccess.USERGROUP)
AddLoadout:AddArgument(WUMAAccess.STRING)
AddLoadout:AddArgument(WUMAAccess.NUMBER)
AddLoadout:AddArgument(WUMAAccess.NUMBER)
AddLoadout:AddArgument(WUMAAccess.NUMBER)
AddLoadout:AddArgument(WUMAAccess.SCOPE,true)
AddLoadout:SetLogFunction(WUMA.EchoFunction)
AddLoadout:SetAccessFunction(WUMA.CheckAccess)
AddLoadout:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////
/////	  AddUserLoadout | Adds weapons to users loadout	/////
/////////////////////////////////////////////////////////////////
local AddUserLoadout = WUMA.RegisterAccess{name="adduserloadout",help="Add a weapon to a users loadout."}
AddUserLoadout:SetFunction(function(caller, target, item, primary, secondary, respect, scope)
	if not target or not item or not primary or not secondary then return WUMADebug("Invalid access arguments (adduserloadout)!") end

	item = string.lower(item)
	
	if (respect == 1) then respect = true else respect = false end

	local sucess = WUMA.AddUserLoadoutWeapon(caller,target, item, primary, secondary, respect, scope)
	
	if not (sucess == false) then
		if isentity(target) then nick = target:Nick() else nick = target end
		
		local prefix = " %s"
		local scope_str = ""
		if scope then 
			scope_str = string.lower(scope:GetPrint2())
			prefix = " "..scope:GetScopeType().log_prefix.." %s"
		end
		
		return {"%s added %s to %ss loadout"..prefix,item,nick,scope_str}, sucess, caller
	end
end)
AddUserLoadout:AddArgument(WUMAAccess.PLAYER)
AddUserLoadout:AddArgument(WUMAAccess.PLAYER)
AddUserLoadout:AddArgument(WUMAAccess.STRING)
AddUserLoadout:AddArgument(WUMAAccess.NUMBER)
AddUserLoadout:AddArgument(WUMAAccess.NUMBER)
AddUserLoadout:AddArgument(WUMAAccess.NUMBER)
AddUserLoadout:AddArgument(WUMAAccess.SCOPE,true)
AddUserLoadout:SetLogFunction(WUMA.EchoFunction)
AddUserLoadout:SetAccessFunction(WUMA.CheckAccess)
AddUserLoadout:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////////////
/////	 RemoveLoadout | Removes weapons from usergroups loadout	/////
/////////////////////////////////////////////////////////////////////////
local RemoveLoadout = WUMA.RegisterAccess{name="removeloadout",help="Remove a weapon from a usergroups loadout."}
RemoveLoadout:SetFunction(function(caller, usergroup, item)
	if not usergroup or not item then return WUMADebug("Invalid access arguments (removeloadout)!") end

	usergroup = string.lower(usergroup)
	item = string.lower(item)

	local sucess = WUMA.RemoveLoadoutWeapon(caller, usergroup, item)
	
	if not (sucess == false) then
		return {"%s removed %s from %ss loadout",item,usergroup}, sucess, caller
	end
end)
RemoveLoadout:AddArgument(WUMAAccess.PLAYER)
RemoveLoadout:AddArgument(WUMAAccess.USERGROUP)
RemoveLoadout:AddArgument(WUMAAccess.STRING)
RemoveLoadout:SetLogFunction(WUMA.EchoFunction)
RemoveLoadout:SetAccessFunction(WUMA.CheckAccess)
RemoveLoadout:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////////////
/////	 RemoveUserLoadout | Removes weapons from users loadout 	/////
/////////////////////////////////////////////////////////////////////////
local RemoveUserLoadout = WUMA.RegisterAccess{name="removeuserloadout",help="Restrict something from a usergroup."}
RemoveUserLoadout:SetFunction(function(caller, target, item)
	if not target or not item then return WUMADebug("Invalid access arguments (removeuserloadout)!") end

	item = string.lower(item)

	local sucess = WUMA.RemoveUserLoadoutWeapon(caller, target, item)
	
	if not (sucess == false) then
		if isentity(target) then nick = target:Nick() else nick = target end
		return {"%s removed %s from %ss loadout",item,nick}, sucess, caller
	end
end)
RemoveUserLoadout:AddArgument(WUMAAccess.PLAYER)
RemoveUserLoadout:AddArgument(WUMAAccess.PLAYER)
RemoveUserLoadout:AddArgument(WUMAAccess.STRING)
RemoveUserLoadout:SetLogFunction(WUMA.EchoFunction)
RemoveUserLoadout:SetAccessFunction(WUMA.CheckAccess)
RemoveUserLoadout:SetAccess("superadmin")

/////////////////////////////////////////////////////////
/////	ClearLoadout | Clears a usergroups weapon	/////
/////////////////////////////////////////////////////////
local ClearLoadout = WUMA.RegisterAccess{name="clearloadout",help="Clear a usergroups loadout."}
ClearLoadout:SetFunction(function(caller, usergroup)
	if not usergroup then return WUMADebug("Invalid access arguments (clearloadout)!") end

	usergroup = string.lower(usergroup)

	local sucess = WUMA.ClearLoadout(caller,usergroup)
	
	if not (sucess == false) then
		return {"%s cleared %ss loadout",usergroup}, sucess, caller
	end
end)
ClearLoadout:AddArgument(WUMAAccess.PLAYER)
ClearLoadout:AddArgument(WUMAAccess.USERGROUP)
ClearLoadout:SetLogFunction(WUMA.EchoFunction)
ClearLoadout:SetAccessFunction(WUMA.CheckAccess)
ClearLoadout:SetAccess("superadmin")

/////////////////////////////////////////////////////////////
/////	ClearUserLoadout | Clears a usergroups weapon	/////
/////////////////////////////////////////////////////////////
local ClearUserLoadout = WUMA.RegisterAccess{name="clearuserloadout",help="Clear a user loadout."}
ClearUserLoadout:SetFunction(function(caller, target)
	if not target then return WUMADebug("Invalid access arguments (clearuserloadout)!") end

	local sucess = WUMA.ClearUserLoadout(caller,target)
	
	if not (sucess == false) then
		if isentity(target) then nick = target:Nick() else nick = target end
		return {"%s cleared %ss loadout",nick}, sucess, caller
	end
end)
ClearUserLoadout:AddArgument(WUMAAccess.PLAYER)
ClearUserLoadout:AddArgument(WUMAAccess.PLAYER)
ClearUserLoadout:SetLogFunction(WUMA.EchoFunction)
ClearUserLoadout:SetAccessFunction(WUMA.CheckAccess)
ClearUserLoadout:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////////
/////	SetPrimaryWeapon | Sets a usergroups primary weapons	/////
/////////////////////////////////////////////////////////////////////
local SetPrimaryWeapon = WUMA.RegisterAccess{name="setprimaryweapon",help="Set a groups primary weapon."}
SetPrimaryWeapon:SetFunction(function(caller, usergroup, item)
	if not usergroup or not item then return WUMADebug("Invalid access arguments (setprimaryweapon)!") end

	usergroup = string.lower(usergroup)

	local sucess, set = WUMA.SetLoadoutPrimaryWeapon(caller,usergroup,item, scope)
	
	if not (sucess == false) then
		if not set then
			return {"%s unset primary weapon for %s", usergroup}, sucess, caller
		else
			return {"%s set %s as primary weapon for %s", item, usergroup}, sucess, caller
		end
	end
end)
SetPrimaryWeapon:AddArgument(WUMAAccess.PLAYER)
SetPrimaryWeapon:AddArgument(WUMAAccess.USERGROUP)
SetPrimaryWeapon:AddArgument(WUMAAccess.STRING)
SetPrimaryWeapon:SetLogFunction(WUMA.EchoFunction)
SetPrimaryWeapon:SetAccessFunction(WUMA.CheckAccess)
SetPrimaryWeapon:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////////////
/////	SetUserPrimaryWeapon | Sets a usergroups primary weapons	/////
/////////////////////////////////////////////////////////////////////////
local SetUserPrimaryWeapon = WUMA.RegisterAccess{name="setuserprimaryweapon",help="Set a users primary weapon."}
SetUserPrimaryWeapon:SetFunction(function(caller, target, item)
	if not target or not item then return WUMADebug("Invalid access arguments (setuserprimaryweapon)!") end

	item = string.lower(item)
	
	local sucess, set = WUMA.SetUserLoadoutPrimaryWeapon(caller, target, item, scope)
	
	if not (sucess == false) then
		if isentity(target) then nick = target:Nick() else nick = target end
		if not set then
			return {"%s unset primary weapon for %s", nick}, sucess, caller
		else
			return {"%s set %s as primary weapon for %s", item, nick}, sucess, caller
		end
	end
end)
SetUserPrimaryWeapon:AddArgument(WUMAAccess.PLAYER)
SetUserPrimaryWeapon:AddArgument(WUMAAccess.PLAYER)
SetUserPrimaryWeapon:AddArgument(WUMAAccess.STRING)
SetUserPrimaryWeapon:SetLogFunction(WUMA.EchoFunction)
SetUserPrimaryWeapon:SetAccessFunction(WUMA.CheckAccess)
SetUserPrimaryWeapon:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////////////////////////////////
/////	 SetEnforceLoadout | Actives or deactivates loadout enforcing for usergroups	/////
/////////////////////////////////////////////////////////////////////////////////////////////
local SetEnforceLoadout = WUMA.RegisterAccess{name="setenforceloadout",help="Set a groups primary weapon."}
SetEnforceLoadout:SetFunction(function(caller, usergroup, enable)
	if not usergroup or not enable then return WUMADebug("Invalid access arguments (setenforceloadout)!") end

	if (enable == 1) then enable = true else enable = false end
	usergroup = string.lower(usergroup)
	
	WUMA.SetEnforceLoadout(caller,usergroup,enable)
end)
SetEnforceLoadout:AddArgument(WUMAAccess.PLAYER)
SetEnforceLoadout:AddArgument(WUMAAccess.USERGROUP)
SetEnforceLoadout:AddArgument(WUMAAccess.STRING)
SetEnforceLoadout:SetLogFunction(WUMA.EchoFunction)
SetEnforceLoadout:SetAccessFunction(WUMA.CheckAccess)
SetEnforceLoadout:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////////////////////////////////
/////	  SetUserEnforceLoadout | Actives or deactivates loadout enforcing for users	/////
/////////////////////////////////////////////////////////////////////////////////////////////
local SetUserEnforceLoadout = WUMA.RegisterAccess{name="setuserenforceloadout",help="Set a users primary weapon."}
SetUserEnforceLoadout:SetFunction(function(caller, target, enable)
	if not target or not enable then return WUMADebug("Invalid access arguments (setuserenforceloadout)!") end

	if (enable == 1) then enable = true else enable = false end

	WUMA.SetUserEnforceLoadout(caller,target,enable)
end)
SetUserEnforceLoadout:AddArgument(WUMAAccess.PLAYER)
SetUserEnforceLoadout:AddArgument(WUMAAccess.PLAYER)
SetUserEnforceLoadout:AddArgument(WUMAAccess.NUMBER)
SetUserEnforceLoadout:SetLogFunction(WUMA.EchoFunction)
SetUserEnforceLoadout:SetAccessFunction(WUMA.CheckAccess)
SetUserEnforceLoadout:SetAccess("superadmin")

/////////////////////////////////////////////////////////
/////	  ChangeSettings | Changes WUMA settings	/////
/////////////////////////////////////////////////////////
local ChangeSettings = WUMA.RegisterAccess{name="changesettings",help="Change WUMA settings"}
ChangeSettings:SetFunction(function(caller, setting, value)
	if not setting or not value then return WUMADebug("Invalid access arguments (changesettings)!") end

	local actual_value = util.JSONToTable(value)[1]
	local convar = GetConVar("wuma_"..setting)
	
	if isstring(actual_value) then
		convar:SetString(actual_value)
	elseif isnumber(actual_value) and (math.floor(actual_value) == actual_value) then
		convar:SetInt(actual_value)
	elseif isnumber(actual_value) and (math.floor(actual_value) != actual_value) then
		convar:SetFloat(actual_value)
	elseif isbool(actual_value) then
		if actual_value then actual_value = 1 else actual_value = 0 end
		convar:SetInt(actual_value)
	end 
	
end)
ChangeSettings:AddArgument(WUMAAccess.PLAYER)
ChangeSettings:AddArgument(WUMAAccess.STRING)
ChangeSettings:AddArgument(WUMAAccess.STRING)
ChangeSettings:SetAccessFunction(WUMA.CheckAccess)
ChangeSettings:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////////////
/////	 ChangeInheritance | Changes inheritance for a usergroup	/////
/////////////////////////////////////////////////////////////////////////
local ChangeInheritance = WUMA.RegisterAccess{name="changeinheritance",help="Change WUMA settings"}
ChangeInheritance:SetFunction(function(caller, enum, target, usergroup)
	if not enum or not target then return WUMADebug("Invalid access arguments (changeinheritance)!") end

	if (usergroup) then
		WUMA.SetUsergroupInheritance(enum, string.lower(target), string.lower(usergroup))
	else
		WUMA.UnsetUsergroupInheritance(enum, string.lower(target))
	end
end)
ChangeInheritance:AddArgument(WUMAAccess.PLAYER)
ChangeInheritance:AddArgument(WUMAAccess.STRING)
ChangeInheritance:AddArgument(WUMAAccess.STRING)
ChangeInheritance:AddArgument(WUMAAccess.STRING, true)
ChangeInheritance:SetAccessFunction(WUMA.CheckAccess)
ChangeInheritance:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////////////////
/////	 AddPersonalLoadout | Adds a weapon to calling users loadout	/////
/////////////////////////////////////////////////////////////////////////////
local AddPersonalLoadout = WUMA.RegisterAccess{name="addpersonalloadout",help="Adds a weapon to a users personal loadout.",strict=true}
AddPersonalLoadout:SetFunction(function(caller, item, primary, secondary)
	if not item or not primary or not secondary then return WUMADebug("Invalid access arguments (addpersonalloadout)!") end

	item = string.lower(item)
	
	primary = -1
	secondary = -1

	WUMA.AddUserLoadoutWeapon(caller, caller, item, primary, secondary, true)
end)
AddPersonalLoadout:AddArgument(WUMAAccess.PLAYER)
AddPersonalLoadout:AddArgument(WUMAAccess.STRING)
AddPersonalLoadout:AddArgument(WUMAAccess.NUMBER)
AddPersonalLoadout:AddArgument(WUMAAccess.NUMBER)
AddPersonalLoadout:SetAccessFunction(WUMA.CheckSelfAccess)
AddPersonalLoadout:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////////////////////////
/////	 RemovePersonalLoadout | Removes a weapon from calling users loadout	/////
/////////////////////////////////////////////////////////////////////////////////////
local RemovePersonalLoadout = WUMA.RegisterAccess{name="removepersonalloadout",help="Removes a weapon from users personal loadout.",strict=true}
RemovePersonalLoadout:SetFunction(function(caller, item)
	if not item then return WUMADebug("Invalid access arguments (removepersonalloadout)!") end

	item = string.lower(item)

	WUMA.RemoveUserLoadoutWeapon(caller, caller, item)
end)
RemovePersonalLoadout:AddArgument(WUMAAccess.PLAYER)
RemovePersonalLoadout:AddArgument(WUMAAccess.STRING)
RemovePersonalLoadout:SetAccessFunction(WUMA.CheckSelfAccess)
RemovePersonalLoadout:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////////
/////	 ClearPersonalLoadout | Clears calling users loadout	/////
/////////////////////////////////////////////////////////////////////
local ClearPersonalLoadout = WUMA.RegisterAccess{name="clearpersonalloadout",help="Clear personal loadout."}
ClearPersonalLoadout:SetFunction(function(caller)

	WUMA.ClearUserLoadout(caller,caller)

end)
ClearPersonalLoadout:AddArgument(WUMAAccess.PLAYER)
ClearPersonalLoadout:AddArgument(WUMAAccess.PLAYER)
ClearPersonalLoadout:SetLogFunction(WUMA.EchoFunction)
ClearPersonalLoadout:SetAccessFunction(WUMA.CheckSelfAccess)
ClearPersonalLoadout:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////////////////
/////	SetPersonalPrimaryWeapon | Sets calling users primary weapon	/////
/////////////////////////////////////////////////////////////////////////////
local SetPersonalPrimaryWeapon = WUMA.RegisterAccess{name="setpersonalprimaryweapon",help="Sets a users own primary weapon.",strict=true}
SetPersonalPrimaryWeapon:SetFunction(function(caller, item)
	if not item then return WUMADebug("Invalid access arguments (setpersonalprimaryweapon)!") end

	item = string.lower(item)
	
	WUMA.SetUserLoadoutPrimaryWeapon(caller, caller, item)
end)
SetPersonalPrimaryWeapon:AddArgument(WUMAAccess.PLAYER)
SetPersonalPrimaryWeapon:AddArgument(WUMAAccess.STRING)
SetPersonalPrimaryWeapon:SetAccessFunction(WUMA.CheckSelfAccess)
SetPersonalPrimaryWeapon:SetAccess("superadmin")

/////////////////////////////////////////////////////////////////////////////////
/////	PersonalLoadout | Access proxy for all personal loadout commands	/////
/////////////////////////////////////////////////////////////////////////////////
local PersonalLoadout = WUMA.RegisterAccess{name="personalloadout",help="Allows users to set their own loadout."}
PersonalLoadout:SetFunction(function() end)
PersonalLoadout:SetAccessFunction(WUMA.CheckAccess)
PersonalLoadout:SetAccess("superadmin")

--Register all accesses with CAMI
WUMA.RegisterCAMIAccessPriviliges()