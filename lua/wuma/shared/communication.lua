WUMA = WUMA or {}

if SERVER then

	function WUMA.SendTable(id,tbl)
		for _,ply in pairs(player.GetAll()) do
			WUMA.SendDataTable(ply,id,tbl)
		end
	end
	
	function WUMA.UpdateTable(id,tbl)
		for _,ply in pairs(player.GetAll()) do
			WUMA.SendDataUpdate(ply,id,tbl)
		end
	end
	
	WUMA.DataQueue = {}
	function WUMA.QueueUpdate(ply,tbl)
		WUMA.DataQueue[ply] = tbl
	end
	
	function WUMA.SendQueue()
		for ply,tbl in pairs(WUMA.DataQueue) do
			
		end		
	end
	
	util.AddNetworkString( "WUMADataUpdate" )
	function WUMA.SendDataUpdate(ply,id,tbl)
		net.Start( "WUMADataUpdate" )
			net.WriteString( id )
			net.WriteTable( tbl )
		net.Send(ply)	
	end
	
	util.AddNetworkString( "WUMASendData" )
	function WUMA.SendDataTable(ply,id,tbl)
		net.Start( "WUMASendData" )
			net.WriteString( id )
			net.WriteTable( tbl )
		net.Send(ply)	
	end
	
	util.AddNetworkString( "WUMACommandStream" )
	function WUMA.RecieveCommand(ply)
		local cmd, tbl = WUMA.ExtractValue(net.ReadTable())

	end
	net.Receive( "WUMACommandStream", WUMA.onRecieveTable )
		
else

	function WUMA.SendCommand(cmd,...)
		local tbl = {cmd, ...}
		net.Start( "WUMACommandStream" )
			net.WriteTable(tbl)
		net.SendToServer()
	end
	
	function WUMA.RecieveDataUpdate(lenght)
		local id = net.ReadString()
		local tbl = net.ReadTable()
		WUMA.DATA[id] = table.Merge(WUMA.DATA[id],tbl)
		WUMALog("Data update recieved (ID:%s)! (SIZE: %s bytes)",id,tostring(lenght))
	end
	net.Receive( "WUMADataUpdate", WUMA.RecieveDataUpdate )
	
	function WUMA.RecieveDataTable(lenght)
		local id = net.ReadString()
		local tbl = net.ReadTable()
		WUMA.DATA[id] = tbl
		WUMALog("Data table recieved (ID:%s)! (SIZE: %s bytes)",id,tostring(lenght))
	end
	net.Receive( "WUMASendData", WUMA.RecieveDataUpdate )
	
end