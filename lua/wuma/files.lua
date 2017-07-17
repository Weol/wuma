
WUMA = WUMA or {}
local WUMADebug = WUMADebug
local WUMALog = WUMALog

local Files = {}
local cache = {}

function Files.Initialize()

	--Create Data folder
	Files.CreateDir(WUMA.DataDirectory)
	
	--Create userfiles folder
	Files.CreateDir(WUMA.DataDirectory..WUMA.UserDataDirectory)

end
	
function Files.CreateDir(dir)
	if not file.IsDir(dir, "DATA") then
		file.CreateDir(dir)
	end
end

function Files.Append(path,text)
	local f = file.Exists(WUMA.DataDirectory..path, "DATA")
	if (not f) then
		Files.Write(WUMA.DataDirectory..path, text)
		return 
	end
	file.Append(path, text)
end

function Files.Exists(path)
	return file.Exists(path, "DATA")
end

function Files.Delete(path) 
	file.Delete(path)
end

function Files.Write(path,text)
	file.Write(path, text)
end

function Files.Read(path)
	Msg("Reading file at "..path.."\n")
	
	local f = file.Open(path, "r", "DATA")
	if (!f) then return "" end
	local str = f:Read(f:Size())
	f:Close()
	return str or ""
end

WUMA.Files = Files