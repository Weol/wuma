WUMA = WUMA or {}

if SERVER then
	include("wuma/init.lua")
else
	include("wuma/client/init.lua")
end
