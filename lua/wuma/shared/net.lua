
WUMA = WUMA or {}

local WUMADebug = WUMADebug
local WUMALog = WUMALog

if SERVER then
	util.AddNetworkString("WUMARPC")
	function WUMA.RPC(ply, fn, ...)
		net.Start("WCSRPC")
			net.WriteString(fn)
			net.WriteTable({...})
		net.Send(ply)
	end
	WUMARPC = WUMA.RPC
else
	local function getGlobalFunction(str, tbl)
		tbl = tbl or _G

		local dot = string.find(str, "%.")
		if dot then
			return getGlobalFunction(string.sub(str, dot + 1), tbl[string.sub(str, 1, dot - 1)])
		end

		return tbl[str]
	end

	local function recieveRPC(length, ply)
		local fname = net.ReadString()
		local data = net.ReadTable()

		local fn = getGlobalFunction(fname)
		if fn then
			fn(unpack(data))
		else
			WUMADebug(string.format("RPC Failed! Could not find function (%s)", fname))
		end
	end
	net.Receive("WUMARPC", recieveRPC)
end