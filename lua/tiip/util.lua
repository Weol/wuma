TIIP = TIIP or {}
TIIP.Util = TIIP.Util or {}
TIIP.Util.Cache = TIIP.Util.Cache or {}

local cache = {}

local function Cache(f)
	local var = cache[f]
	if not var then
		cache[f] = f()
	end
	
	return var
end
TIIPCache = Cache
