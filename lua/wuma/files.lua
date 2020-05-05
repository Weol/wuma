
WUMA = WUMA or {}

local WUMADebug = WUMADebug
local WUMALog = WUMALog
WUMA.Files = WUMA.Files or {}

function WUMA.Files.Initialize()

	--Create Data folder
	WUMA.Files.CreateDir("wuma/")

	--Create userfiles folder
	WUMA.Files.CreateDir("wuma/users/")

end

function WUMA.Files.CreateDir(dir)
	dir = string.lower(dir)
	if not file.IsDir(dir, "DATA") then
		file.CreateDir(dir)
	end
end

function WUMA.Files.Append(path, text)
	path = string.lower(path)
	local f = file.Exists("wuma/"..path, "DATA")
	if (not f) then
		Files.Write("wuma/"..path, text)
		return
	end
	file.Append(path, text)
end

function WUMA.Files.Exists(path)
	path = string.lower(path)
	return file.Exists(path, "DATA")
end

function WUMA.Files.Delete(path)
	path = string.lower(path)
	file.Delete(path)
end

function WUMA.Files.Write(path, text)
	path = string.lower(path)
	file.Write(path, text)
	file.asd()
end

function WUMA.Files.Read(path)
	path = string.lower(path)
	local f = file.Open(path, "r", "DATA")
	if not f then return "" end
	local str = f:Read(f:Size())
	f:Close()
	return str or ""
end
