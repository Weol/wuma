
WUMA = WUMA or {}

--All functions must return the type stated after each hook 
WUMA.GETALLUSERGROUPS = "WUMA_GETALLUSERGROUPS" --Table
WUMA.GETUSERGROUP = "WUMA_GETUSERGROUP" --String
WUMA.INITIALSPAWN = "WUMA_INITIALSPAWN" --String (hook)
WUMA.LOG = "WUMA_LOG" --Function(str)
WUMA.ALERT = "WUMA_ALERT" --Function(ply,str)
WUMA.ACCESS = "WUMA_ACCESS"	--Function(ply,access_string), return boolean
WUMA.COMMAND = "WUMA_COMMAND" --Function(cmd)

WUMA.Overrides = {}

function WUMA.GetOverride(enum)
	if WUMA.Overrides[enum] then return WUMA.Overrides[enum].func end
	return nil
end

function WUMA.SetOverride(enum,func,finally)
	local override = WUMA.Overrides[enum]
	if override then
		if override.finally then finally() end
		WUMA.Overrides[enum] = {fuinc=func,finally=finally or false}
	else
		WUMA.Overrides[enum] = {fuinc=func,finally=finally or false}
	end
end