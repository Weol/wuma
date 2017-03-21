
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

WUMA.EchoChanges = WUMA.CreateConVar("wuma_echo_changes", "2", FCVAR_ARCHIVE, "0=Nobody, 1=Access, 2=Everybody, 3=Relevant")
WUMA.EchoToChat = WUMA.CreateConVar("wuma_echo_to_chat", "1", FCVAR_ARCHIVE, "Enable / disable echo in chat.")

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
	CAMI.PlayerHasAccess(user, "wuma "..WUMA.AccessRegister["selfloadout"]:GetName(), callback)
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
local Restrict = WUMA.RegisterAccess{name="restrict",help="Restrict something from a usergroup."}
Restrict:SetFunction(function(caller, usergroup, typ, item, anti, scope)
	if not usergroup or not typ or not item then return WUMADebug("Invalid access arguments (restrict)!") end

	usergroup = string.lower(usergroup)
	typ = string.lower(typ)
	item = string.lower(item)
	if (anti == 1) then anti = true else anti = false end
	
	local sucess = WUMA.AddRestriction(caller,usergroup,typ,item,anti,scope)

	if not (sucess == false) then
		local prefix = " %s"
		local scope_str = ""
		if scope then 
			scope_str = string.lower(scope:GetPrint2())
			prefix = " "..scope:GetScopeType().log_prefix.." %s"
		end
		
		if anti then
			return {"%s derestricted %s %s from %s"..prefix,typ,item,usergroup,scope_str}, sucess, caller
		else
			return {"%s restricted %s %s from %s"..prefix,typ,item,usergroup,scope_str}, sucess, caller 
		end
	end
end)
Restrict:AddArgument(WUMAAccess.PLAYER)
Restrict:AddArgument(WUMAAccess.USERGROUP)
Restrict:AddArgument(WUMAAccess.STRING,_,table.GetKeys(Restriction:GetTypes()))
Restrict:AddArgument(WUMAAccess.STRING)
Restrict:AddArgument(WUMAAccess.NUMBER,true)
Restrict:AddArgument(WUMAAccess.SCOPE,true)
Restrict:SetLogFunction(WUMA.EchoFunction)
Restrict:SetAccessFunction(WUMA.CheckAccess)
Restrict:SetAccess("superadmin")

local RestrictUser = WUMA.RegisterAccess{name="restrictuser",help="Restrict something from a player"}
RestrictUser:SetFunction(function(caller, target, typ, item, anti, scope)
	if not target or not typ or not item then return WUMADebug("Invalid access arguments (restrictuser)!") end

	typ = string.lower(typ)
	item = string.lower(item)
	
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
		
		if anti then
			return {"%s derestricted %s %s from %s"..prefix,typ,item,nick,scope_str}, sucess, caller
		else
			return {"%s restricted %s %s from %s"..prefix,typ,item,nick,scope_str}, sucess, caller
		end
	end
end)
RestrictUser:AddArgument(WUMAAccess.PLAYER)
RestrictUser:AddArgument(WUMAAccess.PLAYER)
RestrictUser:AddArgument(WUMAAccess.STRING,_,table.GetKeys(Restriction:GetTypes()))
RestrictUser:AddArgument(WUMAAccess.STRING)
RestrictUser:AddArgument(WUMAAccess.NUMBER,true)
RestrictUser:AddArgument(WUMAAccess.SCOPE,true)
RestrictUser:SetLogFunction(WUMA.EchoFunction)
RestrictUser:SetAccessFunction(WUMA.CheckAccess)
RestrictUser:SetAccess("superadmin")

--Unrestrict
local Unrestrict = WUMA.RegisterAccess{name="unrestrict",help="Unrestrict something from a usergroup"}
Unrestrict:SetFunction(function(caller, usergroup, typ, item)
	if not usergroup or not typ or not item then return WUMADebug("Invalid access arguments (unrestrict)!") end

	usergroup = string.lower(usergroup)
	typ = string.lower(typ)
	item = string.lower(item)
	
	local sucess = WUMA.RemoveRestriction(caller,usergroup,typ,item)
	
	if not (sucess == false) then
		return {"%s unrestricted %s %s from %s",typ,item,usergroup}, sucess, caller
	end
end)
Unrestrict:AddArgument(WUMAAccess.PLAYER)
Unrestrict:AddArgument(WUMAAccess.USERGROUP)
Unrestrict:AddArgument(WUMAAccess.STRING,_,table.GetKeys(Restriction:GetTypes()))
Unrestrict:AddArgument(WUMAAccess.STRING)
Unrestrict:SetLogFunction(WUMA.EchoFunction)
Unrestrict:SetAccessFunction(WUMA.CheckAccess)
Unrestrict:SetAccess("superadmin")

--Unrestrict user
local UnrestrictUser = WUMA.RegisterAccess{name="unrestrictuser",help="Unrestrict something from a player"}
UnrestrictUser:SetFunction(function(caller, target, typ, item)
	if not target or not typ or not item then return WUMADebug("Invalid access arguments (unrestrictuser)!") end

	typ = string.lower(typ)
	item = string.lower(item)

	local sucess = WUMA.RemoveUserRestriction(caller,target,typ,item)
	
	if not (sucess == false) then
		if isentity(target) then nick = target:Nick() else nick = target end
		return {"%s unrestricted %s %s from %s",typ,item,nick}, sucess, caller
	end
end)
UnrestrictUser:AddArgument(WUMAAccess.PLAYER)
UnrestrictUser:AddArgument(WUMAAccess.PLAYER)
UnrestrictUser:AddArgument(WUMAAccess.STRING,_,table.GetKeys(Restriction:GetTypes()))
UnrestrictUser:AddArgument(WUMAAccess.STRING)
UnrestrictUser:SetLogFunction(WUMA.EchoFunction)
UnrestrictUser:SetAccessFunction(WUMA.CheckAccess)
UnrestrictUser:SetAccess("superadmin")

--Set limit
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
		WUMADebug(limit)
		if ((tonumber(limit) or 0) < 0) then limit = "∞" end
		
		return {"%s set %s limit to %s for %s"..prefix,item,limit,usergroup,scope_str}, sucess, caller
	end
end)
SetLimit:AddArgument(WUMAAccess.PLAYER)
SetLimit:AddArgument(WUMAAccess.USERGROUP)
SetLimit:AddArgument(WUMAAccess.STRING)
SetLimit:AddArgument(WUMAAccess.NUMBER)
SetLimit:AddArgument(WUMAAccess.NUMBER,true)
SetLimit:AddArgument(WUMAAccess.SCOPE,true)
SetLimit:SetLogFunction(WUMA.EchoFunction)
SetLimit:SetAccessFunction(WUMA.CheckAccess)
SetLimit:SetAccess("superadmin")

--Set user limit
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
SetUserLimit:AddArgument(WUMAAccess.NUMBER)
SetUserLimit:AddArgument(WUMAAccess.NUMBER,true)
SetUserLimit:AddArgument(WUMAAccess.SCOPE,true)
SetUserLimit:SetLogFunction(WUMA.EchoFunction)
SetUserLimit:SetAccessFunction(WUMA.CheckAccess)
SetUserLimit:SetAccess("superadmin")

--Unset limit
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

--Unset user limit
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

--Add group loadout
local AddLoadout = WUMA.RegisterAccess{name="addloadout",help="Add a weapon to a usergroups loadout."}
AddLoadout:SetFunction(function(caller, usergroup, item, primary, secondary, respect, scope)
	if not usergroup or not item or not primary or not secondary then return WUMADebug("Invalid access arguments (addloadout)!") end

	usergroup = string.lower(usergroup)
	item = string.lower(item)
	
	if (primary < 0) then primary = 0 end
	if (secondary < 0) then secondary = 0 end
	
	if (respect == 1) then respect = true else respect = false end

	local sucess = WUMA.AddLoadoutWeapon(caller,usergroup, item, primary, secondary, respect, scope)
	
	if not (sucess == false) then
		local prefix = " %s"
		local scope_str = ""
		if scope then 
			scope_str = string.lower(scope:GetPrint2())
			prefix = " "..scope:GetScopeType().log_prefix.." %s"
		end
		
		return {"%s added %s to %s loadout"..prefix,item,usergroup,scope_str}, sucess, caller
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

--Add user loadout
local AddUserLoadout = WUMA.RegisterAccess{name="adduserloadout",help="Add a weapon to a users loadout."}
AddUserLoadout:SetFunction(function(caller, target, item, primary, secondary, respect, scope)
	if not target or not item or not primary or not secondary then return WUMADebug("Invalid access arguments (adduserloadout)!") end

	item = string.lower(item)
	
	if (primary < 0) then primary = 0 end
	if (secondary < 0) then secondary = 0 end
	
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
		
		return {"%s added %s to %s loadout"..prefix,item,nick,scope_str}, sucess, caller
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

--Delete group loadout
local RemoveLoadout = WUMA.RegisterAccess{name="removeloadout",help="Remove a weapon from a usergroups loadout."}
RemoveLoadout:SetFunction(function(caller, usergroup, item)
	if not usergroup or not item then return WUMADebug("Invalid access arguments (removeloadout)!") end

	usergroup = string.lower(usergroup)
	item = string.lower(item)

	local sucess = WUMA.RemoveLoadoutWeapon(caller, usergroup, item)
	
	if not (sucess == false) then
		return {"%s removed %s from %s loadout",item,usergroup}, sucess, caller
	end
end)
RemoveLoadout:AddArgument(WUMAAccess.PLAYER)
RemoveLoadout:AddArgument(WUMAAccess.USERGROUP)
RemoveLoadout:AddArgument(WUMAAccess.STRING)
RemoveLoadout:SetLogFunction(WUMA.EchoFunction)
RemoveLoadout:SetAccessFunction(WUMA.CheckAccess)
RemoveLoadout:SetAccess("superadmin")

--Delete user loadout
local RemoveUserLoadout = WUMA.RegisterAccess{name="removeuserloadout",help="Restrict something from a usergroup."}
RemoveUserLoadout:SetFunction(function(caller, target, item)
	if not target or not item then return WUMADebug("Invalid access arguments (removeuserloadout)!") end

	item = string.lower(item)

	local sucess = WUMA.RemoveUserLoadoutWeapon(caller, target, item)
	
	if not (sucess == false) then
		if isentity(target) then nick = target:Nick() else nick = target end
		return {"%s removed %s from %s loadout",item,nick}, sucess, caller
	end
end)
RemoveUserLoadout:AddArgument(WUMAAccess.PLAYER)
RemoveUserLoadout:AddArgument(WUMAAccess.PLAYER)
RemoveUserLoadout:AddArgument(WUMAAccess.STRING)
RemoveUserLoadout:SetLogFunction(WUMA.EchoFunction)
RemoveUserLoadout:SetAccessFunction(WUMA.CheckAccess)
RemoveUserLoadout:SetAccess("superadmin")

--Clear group loadout
local ClearLoadout = WUMA.RegisterAccess{name="clearloadout",help="Clear a usergroups loadout."}
ClearLoadout:SetFunction(function(caller, usergroup)
	if not usergroup then return WUMADebug("Invalid access arguments (clearloadout)!") end

	usergroup = string.lower(usergroup)

	local sucess = WUMA.ClearLoadout(caller,usergroup)
	
	if not (sucess == false) then
		return {"%s cleared %s loadout",usergroup}, sucess, caller
	end
end)
ClearLoadout:AddArgument(WUMAAccess.PLAYER)
ClearLoadout:AddArgument(WUMAAccess.USERGROUP)
ClearLoadout:SetLogFunction(WUMA.EchoFunction)
ClearLoadout:SetAccessFunction(WUMA.CheckAccess)
ClearLoadout:SetAccess("superadmin")

--Clear user loadout
local ClearUserLoadout = WUMA.RegisterAccess{name="clearuserloadout",help="Clear a user loadout."}
ClearUserLoadout:SetFunction(function(caller, target)
	if not target then return WUMADebug("Invalid access arguments (clearuserloadout)!") end

	local sucess = WUMA.ClearUserLoadout(caller,target)
	
	if not (sucess == false) then
		if isentity(target) then nick = target:Nick() else nick = target end
		return {"%s cleared %s loadout",nick}, sucess, caller
	end
end)
ClearUserLoadout:AddArgument(WUMAAccess.PLAYER)
ClearUserLoadout:AddArgument(WUMAAccess.PLAYER)
ClearUserLoadout:SetLogFunction(WUMA.EchoFunction)
ClearUserLoadout:SetAccessFunction(WUMA.CheckAccess)
ClearUserLoadout:SetAccess("superadmin")

--Set group primary weapon
local SetPrimaryWeapon = WUMA.RegisterAccess{name="setprimaryweapon",help="Set a groups primary weapon."}
SetPrimaryWeapon:SetFunction(function(caller, usergroup, item)
	if not usergroup or not item then return WUMADebug("Invalid access arguments (setprimaryweapon)!") end

	usergroup = string.lower(usergroup)

	local sucess = WUMA.SetLoadoutPrimaryWeapon(caller,usergroup,item, scope)
	
	if not (sucess == false) then
		return {"%s set %s as %s primary weapons",usergroup,item}, sucess, caller
	end
end)
SetPrimaryWeapon:AddArgument(WUMAAccess.PLAYER)
SetPrimaryWeapon:AddArgument(WUMAAccess.USERGROUP)
SetPrimaryWeapon:AddArgument(WUMAAccess.STRING)
SetPrimaryWeapon:SetLogFunction(WUMA.EchoFunction)
SetPrimaryWeapon:SetAccessFunction(WUMA.CheckAccess)
SetPrimaryWeapon:SetAccess("superadmin")

--Set user primary weapon
local SetUserPrimaryWeapon = WUMA.RegisterAccess{name="setuserprimaryweapon",help="Set a users primary weapon."}
SetUserPrimaryWeapon:SetFunction(function(caller, users, item)
	if not users or not item then return WUMADebug("Invalid access arguments (setuserprimaryweapon)!") end

	item = string.lower(item)
	
	local sucess = WUMA.SetUserLoadoutPrimaryWeapon(caller, users, item, scope)
	
	if not (sucess == false) then
		if isentity(target) then nick = target:Nick() else nick = target end
		return {"%s set %s as %s primary weapons",nick,item}, sucess, caller
	end
end)
SetUserPrimaryWeapon:AddArgument(WUMAAccess.PLAYER)
SetUserPrimaryWeapon:AddArgument(WUMAAccess.PLAYER)
SetUserPrimaryWeapon:AddArgument(WUMAAccess.STRING)
SetUserPrimaryWeapon:SetLogFunction(WUMA.EchoFunction)
SetUserPrimaryWeapon:SetAccessFunction(WUMA.CheckAccess)
SetUserPrimaryWeapon:SetAccess("superadmin")

local ChangeSettings = WUMA.RegisterAccess{name="changesettings",help="Change WUMA settings"}
ChangeSettings:SetFunction(function(caller, setting, value)
	if not setting or not value then return WUMADebug("Invalid access arguments (changesettings)!") end

	local actual_value = util.JSONToTable(value)[1]

	if isstring(actual_value) then
		GetConVar("wuma_"..setting):SetString(actual_value)
	elseif isnumber(actual_value) and (math.floor(actual_value) == actual_value) then
		GetConVar("wuma_"..setting):SetInt(actual_value)
	elseif isnumber(actual_value) and (math.floor(actual_value) != actual_value) then
		GetConVar("wuma_"..setting):SetFloat(actual_value)
	elseif isbool(actual_value) then
		if actual_value then actual_value = 1 else actual_value = 0 end
		GetConVar("wuma_"..setting):SetInt(actual_value)
	end 
	
end)
ChangeSettings:AddArgument(WUMAAccess.PLAYER)
ChangeSettings:AddArgument(WUMAAccess.STRING)
ChangeSettings:AddArgument(WUMAAccess.STRING)
ChangeSettings:SetAccessFunction(WUMA.CheckAccess)
ChangeSettings:SetAccess("superadmin")

--Add self loadout
local AddSelfLoadout = WUMA.RegisterAccess{name="addselfloadout",help="Adds a weapon to a users self loadout.",strict=true}
AddSelfLoadout:SetFunction(function(caller, item, primary, secondary)
	if not item or not primary or not secondary then return WUMADebug("Invalid access arguments (addselfloadout)!") end

	item = string.lower(item)
	
	if (primary < 0) then primary = 0 end
	if (secondary < 0) then secondary = 0 end

	WUMA.AddUserLoadoutWeapon(caller, caller, item, primary, secondary)
end)
AddSelfLoadout:AddArgument(WUMAAccess.PLAYER)
AddSelfLoadout:AddArgument(WUMAAccess.STRING)
AddSelfLoadout:AddArgument(WUMAAccess.NUMBER)
AddSelfLoadout:AddArgument(WUMAAccess.NUMBER)
AddSelfLoadout:SetAccessFunction(WUMA.CheckSelfAccess)
AddSelfLoadout:SetAccess("superadmin")

--Delete self loadout
local RemoveSelfLoadout = WUMA.RegisterAccess{name="removeselfloadout",help="Removes a weapon from users own loadout.",strict=true}
RemoveSelfLoadout:SetFunction(function(caller, item)
	if not item then return WUMADebug("Invalid access arguments (removeselfloadout)!") end

	item = string.lower(item)

	WUMA.RemoveUserLoadoutWeapon(caller, caller, item)
end)
RemoveSelfLoadout:AddArgument(WUMAAccess.PLAYER)
RemoveSelfLoadout:AddArgument(WUMAAccess.STRING)
RemoveSelfLoadout:SetAccessFunction(WUMA.CheckSelfAccess)
RemoveSelfLoadout:SetAccess("superadmin")

--Set user primary weapon
local SetSelfPrimaryWeapon = WUMA.RegisterAccess{name="setselfprimaryweapon",help="Sets a users own primary weapon.",strict=true}
SetSelfPrimaryWeapon:SetFunction(function(caller, item)
	if not item then return WUMADebug("Invalid access arguments (setselfprimaryweapon)!") end

	item = string.lower(item)
	
	WUMA.SetUserLoadoutPrimaryWeapon(caller, caller, item)
end)
SetSelfPrimaryWeapon:AddArgument(WUMAAccess.PLAYER)
SetSelfPrimaryWeapon:AddArgument(WUMAAccess.STRING)
SetSelfPrimaryWeapon:SetAccessFunction(WUMA.CheckSelfAccess)
SetSelfPrimaryWeapon:SetAccess("superadmin")

--Self loadout access
local SelfLoadout = WUMA.RegisterAccess{name="selfloadout",help="Allows users to set their own loadout."}
SelfLoadout:SetFunction(function() end)
SelfLoadout:SetAccessFunction(WUMA.CheckAccess)
SelfLoadout:SetAccess("superadmin")

--Register CAMI privliges after all accesses are done
WUMA.RegisterCAMIAccessPriviliges()