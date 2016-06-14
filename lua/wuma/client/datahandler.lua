
WUMA = WUMA or {}
WUMA.ServerGroups = {}
WUMA.ServerUsers = {}
WUMA.LookupUsers = setmetatable({}, {__newindex = function (t, key, value)
  t[key] = value
  WUMA.OnLookupUsersUpdate(key,value)
end})
WUMA.UserData = {} wd
WUMA.Restrictions = {}
WUMA.Limits = {}
WUMA.Loadouts = {}

--Data updateW
function WUMA.ProcessDataUpdate(data)
	WUMADebug("Process Data Update:")
	
	WUMA.MakeDataSegments(data) 
	
	if data.restrictions then
		WUMA.GUI.Restrictions:UpdateDataTable(data.restrictions)
	end
		
	if data.limits then
		WUMA.GUI.Limits:UpdateDataTable(data.limits)
	end
		
	if data.loadouts then
		WUMA.GUI.Loadouts:UpdateDataTable(data.loadouts)
	end
	
end

function WUMA.MakeDataSegments(tbl) 
	for k,v in pairs(tbl) do 
		if not istable(v) or not v._id then
			v = WUMA_DATASEGMENT:new(v)
		elseif istable(v) and not v._id then
			WUMA.MakeDataSegments(v) 
		elseif (v == WUMA_DATASEGMENT) then
			v:UpdateData(v)
		end
	end
end

--Information update
function WUMA.ProcessInformationUpdate(enum,data)
	WUMADebug("Process Information Update:")
	
	WUMA.NET.ENUMS[enum](data)
end

function WUMA.SetData(tbl)
	
end