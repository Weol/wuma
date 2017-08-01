
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

WUMA.Inheritance = {}

function WUMA.SetUsergroupInheritance(enum, target, usergroup)
	WUMA.Inheritance[enum] = WUMA.Inheritance[enum] or {}
	
	WUMA.Inheritance[enum][target] = usergroup
end

function WUMA.UnsetUsergroupInheritance(enum, target, usergroup)
	if not WUMA.Inheritance[enum] then return end
	
	WUMA.Inheritance[enum][target] = nil
end

function WUMA.GetUsergroupInheritance(enum, target)
	if not WUMA.Inheritance[enum] then return end
	return WUMA.Inheritance[enum][target]
end