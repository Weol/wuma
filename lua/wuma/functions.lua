
WUMA = WUMA or {}

WUMA.AccessRegister = {}
function WUMA.RegisterAccess(tbl)
	WUMA.AccessRegister[tbl.name] = WUMAAccess:new(tbl)
	return WUMA.AccessRegister[tbl.name]
end

function WUMA.ProcessAccess(cmd,data)
	
	local access = WUMA.AccessRegister[cmd]

	if access then
		local arguments = {}
		local tables = {}
		local static = {}

		for i = 1,table.Count(access:GetArguments()) do
			if data[i] then
				if istable(data[i]) then
					tables[i] = {}
					for _, v in pairs(data[i]) do
						table.insert(tables[i], access:GetArguments()[i][1](v))
					end
				else
					static[i] = access:GetArguments()[i][1](data[i])
				end
			else
				static[i] = nil
			end
		end 
		
		if (table.Count(tables) > 0) then
			local function recursive(i)
				if not ans then ans = {} end
				local tbl = tables[table.GetKeys(tables)[i]]
				local key = table.GetKeys(tables)[i]
				for k, v in pairs(tbl) do 
					if (tables[table.GetKeys(tables)[i+1]]) then
						ans[key] = v
						recursive(i+1)
					else
						ans[key] = v
						table.insert(arguments,table.Merge(table.Copy(ans),table.Copy(static)))
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

///////////////////////////////////////////////
/////			Access definitions	      /////
///////////////////////////////////////////////
local Restrict = WUMA.RegisterAccess{name="restrict",help="Restrict something from a usergroup."}
Restrict:SetFunction(function(caller, usergroup, typ, item, anti, scope)
	if not usergroup or not typ or not item then return WUMADebug("Invalid access arguments (restrict)!") end

	usergroup = string.lower(usergroup)
	typ = string.lower(typ)
	item = string.lower(item)
	if (anti == 1) then anti = true else anti = false end
	
	WUMA.AddRestriction(caller,usergroup,typ,item,anti,scope)
end)
Restrict:AddArgument(WUMAAccess.PLAYER)
Restrict:AddArgument(WUMAAccess.USERGROUP)
Restrict:AddArgument(WUMAAccess.STRING)
Restrict:AddArgument(WUMAAccess.STRING)
Restrict:AddArgument(WUMAAccess.NUMBER,true)
Restrict:AddArgument(WUMAAccess.SCOPE,true)
Restrict:SetAccess("superadmin")

local RestrictUser = WUMA.RegisterAccess{name="restrictuser",help="Restrict something from a player"}
RestrictUser:SetFunction(function(caller, target, typ, item, anti, scope)
	if not target or not typ or not item then return WUMADebug("Invalid access arguments (restrictuser)!") end

	typ = string.lower(typ)
	item = string.lower(item)

	WUMA.AddUserRestriction(caller,target,typ,item,anti,scope)
end)
RestrictUser:AddArgument(WUMAAccess.PLAYER)
RestrictUser:AddArgument(WUMAAccess.PLAYERS)
RestrictUser:AddArgument(WUMAAccess.STRING)
RestrictUser:AddArgument(WUMAAccess.STRING)
RestrictUser:AddArgument(WUMAAccess.NUMBER,true)
RestrictUser:AddArgument(WUMAAccess.SCOPE,true)
RestrictUser:SetAccess("superadmin")

--Unrestrict
local Unrestrict = WUMA.RegisterAccess{name="unrestrict",help="Unrestrict something from a usergroup"}
Unrestrict:SetFunction(function(caller, usergroup, typ, item)
	if not usergroup or not typ or not item then return WUMADebug("Invalid access arguments (unrestrict)!") end

	usergroup = string.lower(usergroup)
	typ = string.lower(typ)
	item = string.lower(item)
	
	WUMA.RemoveRestriction(caller,usergroup,typ,item)
end)
Unrestrict:AddArgument(WUMAAccess.PLAYER)
Unrestrict:AddArgument(WUMAAccess.USERGROUP)
Unrestrict:AddArgument(WUMAAccess.STRING)
Unrestrict:AddArgument(WUMAAccess.STRING)
Unrestrict:SetAccess("superadmin")

--Unrestrict user
local UnrestrictUser = WUMA.RegisterAccess{name="unrestrictuser",help="Unrestrict something from a player"}
UnrestrictUser:SetFunction(function(caller, target, typ, item)
	if not target or not typ or not item then return WUMADebug("Invalid access arguments (unrestrictuser)!") end

	typ = string.lower(typ)
	item = string.lower(item)

	WUMA.RemoveUserRestriction(caller,target,typ,item)
end)
UnrestrictUser:AddArgument(WUMAAccess.PLAYER)
UnrestrictUser:AddArgument(WUMAAccess.PLAYERS)
UnrestrictUser:AddArgument(WUMAAccess.STRING)
UnrestrictUser:AddArgument(WUMAAccess.STRING)
UnrestrictUser:SetAccess("superadmin")

--Set limit
local SetLimit = WUMA.RegisterAccess{name="setlimit",help="Set somethings limit."}
SetLimit:SetFunction(function(caller, usergroup, item, limit, scope)
	if not usergroup or not item or not limit then return WUMADebug("Invalid access arguments (setlimit)!") end

	usergroup = string.lower(usergroup)
	limit = string.lower(limit)
	item = string.lower(item)

	WUMA.AddLimit(caller,usergroup, item, limit, scope)
end)
SetLimit:AddArgument(WUMAAccess.PLAYER)
SetLimit:AddArgument(WUMAAccess.USERGROUP)
SetLimit:AddArgument(WUMAAccess.STRING)
SetLimit:AddArgument(WUMAAccess.NUMBER)
SetLimit:AddArgument(WUMAAccess.SCOPE,true)
SetLimit:SetAccess("superadmin")

--Set user limit
local SetUserLimit = WUMA.RegisterAccess{name="setuserlimit",help="Set the limit something for a player"}
SetUserLimit:SetFunction(function(caller, target, item, limit, scope)
	if not target or not item or not limit then return WUMADebug("Invalid access arguments (setuserlimit)!") end

	limit = string.lower(limit)
	item = string.lower(item)

	WUMA.AddUserLimit(caller,target, item, limit, scope)
end)
SetUserLimit:AddArgument(WUMAAccess.PLAYER)
SetUserLimit:AddArgument(WUMAAccess.PLAYERS)
SetUserLimit:AddArgument(WUMAAccess.STRING)
SetUserLimit:AddArgument(WUMAAccess.NUMBER)
SetUserLimit:AddArgument(WUMAAccess.SCOPE,true)
SetUserLimit:SetAccess("superadmin")

--Unset limit
local UnsetLimit = WUMA.RegisterAccess{name="unsetlimit",help="Unset somethings limit."}
UnsetLimit:SetFunction(function(caller, usergroup, item)
	if not usergroup or not item then return WUMADebug("Invalid access arguments (unsetlimit)!") end

	usergroup = string.lower(usergroup)
	item = string.lower(item)

	WUMA.RemoveLimit(caller,usergroup, item)
end)
UnsetLimit:AddArgument(WUMAAccess.PLAYER)
UnsetLimit:AddArgument(WUMAAccess.USERGROUP)
UnsetLimit:AddArgument(WUMAAccess.STRING)
UnsetLimit:SetAccess("superadmin")

--Unset user limit
local UnsetUserLimit = WUMA.RegisterAccess{name="unsetuserlimit",help="Unset the limit something for a player"}
UnsetUserLimit:SetFunction(function(caller, target, item)
	if not target or not item then return WUMADebug("Invalid access arguments (unsetuserlimit)!") end

	item = string.lower(item)

	WUMA.AddUserLimit(caller,target, item)
end)
UnsetUserLimit:AddArgument(WUMAAccess.PLAYER)
UnsetUserLimit:AddArgument(WUMAAccess.PLAYERS)
UnsetUserLimit:AddArgument(WUMAAccess.STRING)
UnsetUserLimit:SetAccess("superadmin")

--Add group loadout
local AddLoadout = WUMA.RegisterAccess{name="addloadout",help="Add a weapon to a usergroups loadout."}
AddLoadout:SetFunction(function(caller, usergroup, item, primary, secondary, scope)
	if not usergroup or not item or not primary or not secondary then return WUMADebug("Invalid access arguments (addloadout)!") end

	usergroup = string.lower(usergroup)
	item = string.lower(item)

	WUMA.AddLoadoutWeapon(caller,usergroup, item, primary, secondary, scope)
end)
AddLoadout:AddArgument(WUMAAccess.PLAYER)
AddLoadout:AddArgument(WUMAAccess.USERGROUP)
AddLoadout:AddArgument(WUMAAccess.STRING)
AddLoadout:AddArgument(WUMAAccess.NUMBER)
AddLoadout:AddArgument(WUMAAccess.NUMBER)
AddLoadout:AddArgument(WUMAAccess.SCOPE,true)
AddLoadout:SetAccess("superadmin")

--Add user loadout
local AddUserLoadout = WUMA.RegisterAccess{name="adduserloadout",help="Add a weapon to a users loadout."}
AddUserLoadout:SetFunction(function(caller, target, item, primary, secondary, scope)
	if not target or not item or not primary or not secondary then return WUMADebug("Invalid access arguments (adduserloadout)!") end

	item = string.lower(item)

	WUMA.AddUserLoadoutWeapon(caller,target, item, primary, secondary, scope)
end)
AddUserLoadout:AddArgument(WUMAAccess.PLAYER)
AddUserLoadout:AddArgument(WUMAAccess.PLAYERS)
AddUserLoadout:AddArgument(WUMAAccess.STRING)
AddUserLoadout:AddArgument(WUMAAccess.NUMBER)
AddUserLoadout:AddArgument(WUMAAccess.NUMBER)
AddUserLoadout:AddArgument(WUMAAccess.SCOPE,true)
AddUserLoadout:SetAccess("superadmin")

--Delete group loadout
local RemoveLoadout = WUMA.RegisterAccess{name="removeloadout",help="Remove a weapon from a usergroups loadout."}
RemoveLoadout:SetFunction(function(caller, usergroup, item)
	if not usergroup or not item then return WUMADebug("Invalid access arguments (removeloadout)!") end

	usergroup = string.lower(usergroup)
	item = string.lower(item)

	WUMA.RemoveLoadoutWeapon(caller,usergroup, item)
end)
RemoveLoadout:AddArgument(WUMAAccess.PLAYER)
RemoveLoadout:AddArgument(WUMAAccess.USERGROUP)
RemoveLoadout:AddArgument(WUMAAccess.STRING)
RemoveLoadout:SetAccess("superadmin")

--Delete user loadout
local RemoveUserLoadout = WUMA.RegisterAccess{name="removeuserloadout",help="Restrict something from a usergroup."}
RemoveUserLoadout:SetFunction(function(caller, target, item)
	if not target or not item then return WUMADebug("Invalid access arguments (removeuserloadout)!") end

	item = string.lower(item)

	WUMA.RemoveUserLoadoutWeapon(caller, target, item)
end)
RemoveUserLoadout:AddArgument(WUMAAccess.PLAYER)
RemoveUserLoadout:AddArgument(WUMAAccess.PLAYERS)
RemoveUserLoadout:AddArgument(WUMAAccess.STRING)
RemoveUserLoadout:SetAccess("superadmin")

--Clear group loadout
local ClearLoadout = WUMA.RegisterAccess{name="clearloadout",help="Clear a usergroups loadout."}
ClearLoadout:SetFunction(function(caller, usergroup)
	if not usergroup then return WUMADebug("Invalid access arguments (clearloadout)!") end

	usergroup = string.lower(usergroup)

	WUMA.ClearLoadout(caller,usergroup)
end)
ClearLoadout:AddArgument(WUMAAccess.PLAYER)
ClearLoadout:AddArgument(WUMAAccess.USERGROUP)
ClearLoadout:SetAccess("superadmin")

--Clear user loadout
local ClearUserLoadout = WUMA.RegisterAccess{name="clearuserloadout",help="Clear a user loadout."}
ClearUserLoadout:SetFunction(function(caller, target)
	if not target then return WUMADebug("Invalid access arguments (clearuserloadout)!") end

	WUMA.ClearUserLoadout(caller,target)
end)
ClearUserLoadout:AddArgument(WUMAAccess.PLAYER)
ClearUserLoadout:AddArgument(WUMAAccess.PLAYERS)
ClearUserLoadout:SetAccess("superadmin")

--Set group primary weapon
local SetPrimaryWeapon = WUMA.RegisterAccess{name="setprimaryweapon",help="Set a groups primary weapon."}
SetPrimaryWeapon:SetFunction(function(caller, usergroup, item, scope)
	if not usergroup or not item then return WUMADebug("Invalid access arguments (setprimaryweapon)!") end

	usergroup = string.lower(usergroup)

	WUMA.SetLoadoutPrimaryWeapon(caller,usergroup,item, scope)
end)
SetPrimaryWeapon:AddArgument(WUMAAccess.PLAYER)
SetPrimaryWeapon:AddArgument(WUMAAccess.USERGROUP)
SetPrimaryWeapon:AddArgument(WUMAAccess.STRING)
SetPrimaryWeapon:AddArgument(WUMAAccess.SCOPE,true)
SetPrimaryWeapon:SetAccess("superadmin")

--Set user primary weapon
local SetUserPrimaryWeapon = WUMA.RegisterAccess{name="setuserprimaryweapon",help="Set a users primary weapon."}
SetUserPrimaryWeapon:SetFunction(function(caller, users, item, scope)
	if not users or not item then return WUMADebug("Invalid access arguments (setuserprimaryweapon)!") end

	item = string.lower(item)
	
	WUMA.SetUserLoadoutPrimaryWeapon(caller, users, item, scope)
end)
SetUserPrimaryWeapon:AddArgument(WUMAAccess.PLAYER)
SetUserPrimaryWeapon:AddArgument(WUMAAccess.PLAYERS)
SetUserPrimaryWeapon:AddArgument(WUMAAccess.STRING)
SetUserPrimaryWeapon:AddArgument(WUMAAccess.SCOPE,true)
SetUserPrimaryWeapon:SetAccess("superadmin")
