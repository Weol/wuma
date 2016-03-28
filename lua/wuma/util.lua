WUMA = WUMA or {}
WUMA.Util = WUMA.Util or {}
WUMA.Util.Cache = WUMA.Util.Cache or {}

local cache = {}

local function Cache(f)
	local var = cache[f]
	if not var then
		cache[f] = f()
	end
	
	return var
end
WUMACache = Cache
