WUMA = WUMA or {}

--Restriction types
WUMA.RestrictionTypes = {
	"entity",
	"prop",
	"npc",
	"vehicle",
	"swep",
	"pickup",
	"effect",
	"tool",
	"ragdoll",
	"use"
} 

--Set up weapon list
WUMA.Weapons = {
	"weapon_357",
	"weapon_slam",
	"weapon_ar2",
	"weapon_bugbait",
	"weapon_crossbow",
	"weapon_crowbar",
	"weapon_frag",
	"weapon_physcannon",
	"weapon_physgun",
	"weapon_pistol",
	"weapon_rpg",
	"weapon_shotgun",
	"weapon_smg1",
	"weapon_stunstick",
	"gmod_tool",
	"gmod_camera"
}
for k,v in pairs (weapons.GetList()) do
	table.insert(WUMA.Weapons,v.ClassName)
end


local CATEGORY_NAME = "WUMA"

--Restrict
	function ulx.restrict(calling_ply, usergroup, type, item)
		usergroup = string.lower(usergroup)
		type = string.lower(type)
		item = string.lower(item)
		
		WUMA.AddRestriction(usergroup,type,item)
	end
	local restrict = ulx.command(CATEGORY_NAME, "ulx restrict", ulx.restrict, "!restrict")
	restrict:addParam{ type=ULib.cmds.StringArg, completes=ulx.group_names_no_user, hint="group", error="invalid group \"%s\" specified", ULib.cmds.restrictToCompletes }
	restrict:addParam{ type=ULib.cmds.StringArg, completes=WUMA.RestrictionTypes, hint="type", error="invalid type \"%s\" specified", ULib.cmds.restrictToCompletes }
	restrict:addParam{ type=ULib.cmds.StringArg, hint="Class / Model" }
	restrict:defaultAccess(ULib.ACCESS_SUPERADMIN)
	restrict:help("Restrict something from a usergroup")

--Restrict user
	function ulx.restrictuser(calling_ply, target_ply, type, item)
		type = string.lower(type)
		item = string.lower(item)
	
		WUMA.AddUserRestriction(target_ply,type,item)
	end
	local restrictuser = ulx.command(CATEGORY_NAME, "ulx restrictuser", ulx.restrictuser, "!restrictuser")
	restrictuser:addParam{ type=ULib.cmds.PlayersArg }
	restrictuser:addParam{ type=ULib.cmds.StringArg, completes=WUMA.RestrictionTypes, hint="type", error="invalid type \"%s\" specified", ULib.cmds.restrictToCompletes }
	restrictuser:addParam{ type=ULib.cmds.StringArg, hint="Class / Model" }
	restrictuser:defaultAccess(ULib.ACCESS_SUPERADMIN)
	restrictuser:help("Restrict something from a player")

--Unrestrict
	function ulx.unrestrict(calling_ply, usergroup, type, item)
		usergroup = string.lower(usergroup)
		type = string.lower(type)
		item = string.lower(item)
	
		WUMA.RemoveRestriction(usergroup,type,item)
	end
	local unrestrict = ulx.command(CATEGORY_NAME, "ulx unrestrict", ulx.unrestrict, "!unrestrict")
	unrestrict:addParam{ type=ULib.cmds.StringArg, completes=ulx.group_names_no_user, hint="group", error="invalid group \"%s\" specified", ULib.cmds.restrictToCompletes }
	unrestrict:addParam{ type=ULib.cmds.StringArg, completes=WUMA.RestrictionTypes, hint="type", error="invalid type \"%s\" specified", ULib.cmds.restrictToCompletes }
	unrestrict:addParam{ type=ULib.cmds.StringArg, hint="Class / Model" }
	unrestrict:defaultAccess(ULib.ACCESS_SUPERADMIN)
	unrestrict:help("Unrestrict something from a usergroup")

--Unrestrict user
	function ulx.unrestrictuser(calling_ply, target_ply, type, item)
		type = string.lower(type)
		item = string.lower(item)
	
		WUMA.RemoveUserRestriction(target_ply,type,item)
	end
	local unrestrictuser = ulx.command(CATEGORY_NAME, "ulx unrestrictuser", ulx.unrestrictuser, "!unrestrictuser")
	unrestrictuser:addParam{ type=ULib.cmds.PlayersArg }
	unrestrictuser:addParam{ type=ULib.cmds.StringArg, completes=WUMA.RestrictionTypes, hint="type", error="invalid type \"%s\" specified", ULib.cmds.restrictToCompletes }
	unrestrictuser:addParam{ type=ULib.cmds.StringArg, hint="Class / Model" }
	unrestrictuser:defaultAccess(ULib.ACCESS_SUPERADMIN)
	unrestrictuser:help("Unrestrict something from a player")

--Set limit
	function ulx.setlimit(calling_ply, usergroup, item, limit)
		usergroup = string.lower(usergroup)
		limit = string.lower(limit)
		item = string.lower(item)
	
		WUMA.AddLimit(usergroup, item, limit)
	end
	local setlimit = ulx.command(CATEGORY_NAME, "ulx setlimit", ulx.setlimit, "!setlimit")
	setlimit:addParam{ type=ULib.cmds.StringArg, completes=ulx.group_names_no_user, hint="group", error="invalid group \"%s\" specified", ULib.cmds.restrictToCompletes }
	setlimit:addParam{ type=ULib.cmds.StringArg, hint="Item" }
	setlimit:addParam{ type=ULib.cmds.StringArg, hint="Limit" }
	setlimit:defaultAccess(ULib.ACCESS_SUPERADMIN)
	setlimit:help("Set somethings limit.")

--Set user limit
	function ulx.setuserlimit(calling_ply, target_ply, item, limit)
		limit = string.lower(limit)
		item = string.lower(item)
	
		WUMA.AddUserLimit(target_ply, item, limit)
	end
	local setuserlimit = ulx.command(CATEGORY_NAME, "ulx setuserlimit", ulx.setuserlimit, "!setuserlimit")
	setuserlimit:addParam{ type=ULib.cmds.PlayersArg }
	setuserlimit:addParam{ type=ULib.cmds.StringArg, hint="Item" }
	setuserlimit:addParam{ type=ULib.cmds.StringArg, hint="Limit" }
	setuserlimit:defaultAccess(ULib.ACCESS_SUPERADMIN)
	setuserlimit:help("Set the limit something for a player")

--Unset limit
	function ulx.unsetlimit(calling_ply, usergroup, item)
		usergroup = string.lower(usergroup)
		item = string.lower(item)
	
		WUMA.RemoveLimit(usergroup, item)
	end
	local unsetlimit = ulx.command(CATEGORY_NAME, "ulx unsetlimit", ulx.unsetlimit, "!unsetlimit")
	unsetlimit:addParam{ type=ULib.cmds.StringArg, completes=ulx.group_names_no_user, hint="group", error="invalid group \"%s\" specified", ULib.cmds.restrictToCompletes }
	unsetlimit:addParam{ type=ULib.cmds.StringArg, hint="Item" }
	unsetlimit:defaultAccess(ULib.ACCESS_SUPERADMIN)
	unsetlimit:help("Unset somethings limit.")

--Unset user limit
	function ulx.unsetuserlimit(calling_ply, target_ply, item)
		item = string.lower(item)
	
		WUMA.AddUserLimit(target_ply, item)
	end
	local unsetuserlimit = ulx.command(CATEGORY_NAME, "ulx unsetuserlimit", ulx.unsetuserlimit, "!unsetuserlimit")
	unsetuserlimit:addParam{ type=ULib.cmds.PlayersArg }
	unsetuserlimit:addParam{ type=ULib.cmds.StringArg, hint="Item" }
	unsetuserlimit:defaultAccess(ULib.ACCESS_SUPERADMIN)
	unsetuserlimit:help("Unset the limit something for a player")

--Add group loadout
	function ulx.addloadout(calling_ply, usergroup, item, primary, secondary)
		usergroup = string.lower(usergroup)
		item = string.lower(item)

		WUMA.AddLoadoutWeapon(usergroup, item, primary, secondary)
	end
	local addloadout = ulx.command(CATEGORY_NAME, "ulx addloadout", ulx.addloadout, "!addloadout")
	addloadout:addParam{ type=ULib.cmds.StringArg, completes=ulx.group_names_no_user, hint="group", error="invalid group \"%s\" specified", ULib.cmds.restrictToCompletes }
	addloadout:addParam{ type=ULib.cmds.StringArg, completes=WUMA.Weapons, hint="weapon", error="invalid weapon \"%s\" specified", ULib.cmds.restrictToCompletes }
	addloadout:addParam{ type=ULib.cmds.NumArg, ULib.cmds.round,ULib.cmds.optional, min=0,default=200, hint="Primary ammo" }
	addloadout:addParam{ type=ULib.cmds.NumArg, ULib.cmds.round,ULib.cmds.optional, min=0,default=10, hint="Secondary ammo" }
	addloadout:defaultAccess(ULib.ACCESS_SUPERADMIN)
	addloadout:help("Add a weapon to a usergroups loadout.")

--Add user loadout
	function ulx.adduserloadout(calling_ply, target_plys, item, primary, secondary)
		item = string.lower(item)
	
		WUMA.AddUserLoadoutWeapon(target_plys, item, primary, secondary)
	end
	local adduserloadout = ulx.command(CATEGORY_NAME, "ulx adduserloadout", ulx.adduserloadout, "!adduserloadout")
	adduserloadout:addParam{ type=ULib.cmds.PlayersArg }
	adduserloadout:addParam{ type=ULib.cmds.StringArg, completes=WUMA.Weapons, hint="weapon", error="invalid weapon \"%s\" specified", ULib.cmds.restrictToCompletes }
	adduserloadout:addParam{ type=ULib.cmds.NumArg, ULib.cmds.round,ULib.cmds.optional, min=0,default=200, hint="Primary ammo" }
	adduserloadout:addParam{ type=ULib.cmds.NumArg, ULib.cmds.round,ULib.cmds.optional, min=0,default=10, hint="Secondary ammo" }
	adduserloadout:defaultAccess(ULib.ACCESS_SUPERADMIN)
	adduserloadout:help("Add a weapon to a users loadout.")

--Delete group loadout
	function ulx.removeloadout(calling_ply, usergroup, item)
		usergroup = string.lower(usergroup)
		item = string.lower(item)
	
		WUMA.RemoveLoadoutWeapon(usergroup, item)
	end
	local removeloadout = ulx.command(CATEGORY_NAME, "ulx removeloadout", ulx.removeloadout, "!removeloadout")
	removeloadout:addParam{ type=ULib.cmds.StringArg, completes=ulx.group_names_no_user, hint="group", error="invalid group \"%s\" specified", ULib.cmds.restrictToCompletes }
	removeloadout:addParam{ type=ULib.cmds.StringArg, completes=WUMA.Weapons, hint="weapon", error="invalid weapon \"%s\" specified", ULib.cmds.restrictToCompletes }
	removeloadout:defaultAccess(ULib.ACCESS_SUPERADMIN)
	removeloadout:help("Remove a weapon from a usergroups loadout.")

--Delete user loadout
	function ulx.removeuserloadout(calling_ply, target_plys, item)
		item = string.lower(item)
	
		WUMA.RemoveUserLoadoutWeapon(target_plys, item)
	end
	local removeuserloadout = ulx.command(CATEGORY_NAME, "ulx removeuserloadout", ulx.removeuserloadout, "!removeuserloadout")
	removeuserloadout:addParam{ type=ULib.cmds.PlayersArg }
	removeuserloadout:addParam{ type=ULib.cmds.StringArg, completes=WUMA.Weapons, hint="weapon", error="invalid weapon \"%s\" specified", ULib.cmds.restrictToCompletes }
	removeuserloadout:defaultAccess(ULib.ACCESS_SUPERADMIN)
	removeuserloadout:help("Remove a weapon from a users loadout.")

--Clear group loadout
	function ulx.clearloadout(calling_ply, usergroup)
		usergroup = string.lower(usergroup)
	
		WUMA.ClearLoadout(usergroup)
	end
	local clearloadout = ulx.command(CATEGORY_NAME, "ulx clearloadout", ulx.clearloadout, "!clearloadout")
	clearloadout:addParam{ type=ULib.cmds.StringArg, completes=ulx.group_names_no_user, hint="group", error="invalid group \"%s\" specified", ULib.cmds.restrictToCompletes }
	clearloadout:defaultAccess(ULib.ACCESS_SUPERADMIN)
	clearloadout:help("Clear a usergroups loadout.")
	
--Clear user loadout
	function ulx.clearuserloadout(calling_ply, target_plys)
		WUMA.ClearUserLoadout(target_plys)
	end
	local clearuserloadout = ulx.command(CATEGORY_NAME, "ulx clearuserloadout", ulx.clearuserloadout, "!clearuserloadout")
	clearuserloadout:addParam{ type=ULib.cmds.PlayersArg }
	clearuserloadout:defaultAccess(ULib.ACCESS_SUPERADMIN)
	clearuserloadout:help("Clear a user loadout.")
	
--Set group primary weapon
	function ulx.setprimaryweapon(calling_ply, usergroup, item	)
		usergroup = string.lower(usergroup)
	
		WUMA.SetLoadoutPrimaryWeapon(usergroup,item)
	end
	local setprimaryweapon = ulx.command(CATEGORY_NAME, "ulx setprimaryweapon", ulx.setprimaryweapon, "!setprimaryweapon")
	setprimaryweapon:addParam{ type=ULib.cmds.StringArg, completes=ulx.group_names_no_user, hint="group", error="invalid group \"%s\" specified", ULib.cmds.restrictToCompletes }
	setprimaryweapon:addParam{ type=ULib.cmds.StringArg, completes=WUMA.Weapons, hint="weapon", error="invalid weapon \"%s\" specified", ULib.cmds.restrictToCompletes }
	setprimaryweapon:defaultAccess(ULib.ACCESS_SUPERADMIN) 
	setprimaryweapon:help("Set a groups primary weapon.")

--Set user primary weapon
	function ulx.setuserprimaryweapon(calling_ply, users, item	)
		WUMA.SetUserLoadoutPrimaryWeapon(users,string.lower(item))
	end
	local setuserprimaryweapon = ulx.command(CATEGORY_NAME, "ulx setuserprimaryweapon", ulx.setuserprimaryweapon, "!setuserprimaryweapon")
	setuserprimaryweapon:addParam{ type=ULib.cmds.PlayersArg }
	setuserprimaryweapon:addParam{ type=ULib.cmds.StringArg, completes=WUMA.Weapons, hint="weapon", error="invalid weapon \"%s\" specified", ULib.cmds.restrictToCompletes }
	setuserprimaryweapon:defaultAccess(ULib.ACCESS_SUPERADMIN)
	setuserprimaryweapon:help("Set a users primary weapon.")


